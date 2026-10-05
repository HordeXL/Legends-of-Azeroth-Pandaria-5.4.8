using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;

// Read-only analysis of the extracted 5.4.8 client tables and world SQL exports.
public static class InstanceRewardsAudit
{
    static VisualAuditDbc Read(string dir, string name) { return new VisualAuditDbc(Path.Combine(dir, name + ".dbc")); }
    static IEnumerable<string[]> Tsv(string dir, string file) { return File.ReadLines(Path.Combine(dir, file + ".tsv")).Skip(1).Select(x => x.Split('\t')); }
    sealed class Drop { public int Entry, Item, Mask, Group, Ref; public string Chance; }
    static Dictionary<int,List<Drop>> Drops(string dir, string file)
    {
        return Tsv(dir,file).Select(x => new Drop { Entry=int.Parse(x[0]), Item=int.Parse(x[1]), Chance=x[2], Mask=int.Parse(x[3]), Group=int.Parse(x[4]), Ref=int.Parse(x[5]) }).GroupBy(x=>x.Entry).ToDictionary(x=>x.Key,x=>x.ToList());
    }
    // Three-valued projection: 1=false, 2=true, 3=depends on non-difficulty state.
    static int ModeGate(VisualAuditDbc modifiers, uint id, uint difficulty, HashSet<uint> visiting)
    {
        if(id==0) return 2;
        uint[] r; if(!modifiers.Rows.TryGetValue(id,out r) || !visiting.Add(id)) return 3;
        int value=3;
        if(r[4]==4 || r[4]==8)
        {
            value=r[4]==4 ? 2:1;
            foreach(var child in modifiers.Rows.Values.Where(x=>x[6]==id))
            {
                int c=ModeGate(modifiers,child[0],difficulty,visiting), next=0;
                foreach(int a in new[]{1,2}) foreach(int b in new[]{1,2})
                    if((value&a)!=0 && (c&b)!=0) next|=(r[4]==4 ? a==2 && b==2 : a==2 || b==2) ? 2:1;
                value=next;
            }
        }
        else
        {
            if(r[1]==0) value=2;
            if(r[1]==68) value=difficulty==r[2] ? 2:1;
            if(r[1]==20) value=(r[2]==0 && (difficulty==1 || difficulty==3) || r[2]==1 && (difficulty==2 || difficulty==4) || r[2]==2 && difficulty==5 || r[2]==3 && difficulty==6) ? 2:1;
            if(r[1]==73) value=ModeGate(modifiers,r[2],difficulty,visiting);
            if(r[4]==3) value=((value&1)<<1)|((value&2)>>1);
        }
        visiting.Remove(id); return value;
    }
    static IEnumerable<Tuple<Drop,string>> Expand(Dictionary<int,List<Drop>> loot, Dictionary<int,List<Drop>> refs, int entry, int mask, int group, string path, HashSet<int> seen)
    {
        List<Drop> rows;
        if (!loot.TryGetValue(entry,out rows)) yield break;
        foreach(var r in rows)
        {
            if (r.Mask!=0 && (r.Mask&mask)==0 || group!=0 && r.Group!=group) continue;
            if(r.Ref<0)
            {
                if (!seen.Add(-r.Ref)) continue;
                foreach(var child in Expand(refs,refs,-r.Ref,mask,r.Group,path+">ref:"+(-r.Ref),seen)) yield return child;
                seen.Remove(-r.Ref);
            }
            else yield return Tuple.Create(r,path);
        }
    }
    public static void Run(string dbc, string dir)
    {
        var maps=Read(dbc,"Map"); var modes=Read(dbc,"MapDifficulty"); var achievements=Read(dbc,"Achievement");
        var trees=Read(dbc,"CriteriaTree"); var criteria=Read(dbc,"Criteria"); var modifiers=Read(dbc,"ModifierTree");
        var encounters=Read(dbc,"DungeonEncounter"); var journal=Read(dbc,"JournalEncounter"); var instances=Read(dbc,"JournalInstance"); var items=Read(dbc,"JournalEncounterItem");
        var loot=Drops(dir,"loot"); var refs=Drops(dir,"references");
        var spawns=Tsv(dir,"spawns").ToDictionary(x=>x[0]+":"+x[1],x=>int.Parse(x[2]));
        var sources=Tsv(dir,"sources").Select(x=>new { Map=uint.Parse(x[0]), Entry=int.Parse(x[1]), Loot=int.Parse(x[2]), Name=x[3], Mask=spawns[x[0]+":"+x[1]] }).ToList();
        var templates=Tsv(dir,"creatures").ToDictionary(x=>int.Parse(x[0]));
        foreach(var e in Tsv(dir,"encounters"))
        {
            uint[] er; string[] cr; int entry=int.Parse(e[3]);
            if(e[2]!="0" || !encounters.Rows.TryGetValue(uint.Parse(e[0]),out er) || !templates.TryGetValue(entry,out cr)) continue;
            if(!sources.Any(x=>x.Map==er[1] && x.Entry==entry)) sources.Add(new { Map=er[1],Entry=entry,Loot=int.Parse(cr[1]),Name=cr[2], Mask=32767 });
        }
        // Summoned bosses need not have a creature spawn or a kill-credit row.
        foreach(var e in journal.Rows.Values)
        {
            uint[] j; if(!instances.Rows.TryGetValue(e[6],out j)) continue;
            foreach(var c in templates.Values.Where(x=>(x[2]==journal.Text(e[9]) || journal.Text(e[9]).EndsWith(": "+x[2])) && x[3].StartsWith("boss_")))
            {
                int entry=int.Parse(c[0]);
                if(!sources.Any(x=>x.Map==j[1] && x.Entry==entry && x.Mask!=0)) sources.Add(new { Map=j[1],Entry=entry,Loot=int.Parse(c[1]),Name=c[2],Mask=32767 });
            }
        }
        var mapModes=modes.Rows.Values.GroupBy(x=>x[1]).ToDictionary(x=>x.Key,x=>x.Select(v=>v[2]).Distinct().ToArray());
        // MapDifficulty retains unused normal records for heroic-only Cataclysm
        // dungeons. LFGDungeons describes the selectable dungeon difficulties.
        foreach(var g in Read(dbc,"LFGDungeons").Rows.Values.Where(x=>x[10]==1).GroupBy(x=>x[7]))
        {
            uint[] map;
            if(maps.Rows.TryGetValue(g.Key,out map) && map[2]==1)
                mapModes[g.Key]=g.Select(x=>x[8]).Distinct().ToArray();
        }
        var expected=new Dictionary<string,int>();
        foreach(var i in items.Rows.Values)
        {
            uint[] e,j;
            if(!journal.Rows.TryGetValue(i[1],out e) || !instances.Rows.TryGetValue(e[6],out j)) continue;
            string key=j[1]+":"+i[2];
            // Journal difficulty bits use normal/heroic and raid-size categories,
            // not the server Difficulty enum. Dungeon bits 0/1 are unambiguous.
            uint[] map; if(!maps.Rows.TryGetValue(j[1],out map)) continue;
            int m=map[2]==2 ? ((int)(i[3]&15)<<3) | ((i[3]&16)!=0 ? 128:0) | ((i[3]&32)!=0 ? 16384:0) : (int)(i[3]&3)<<1;
            if(!expected.ContainsKey(key)) expected[key]=0;
            expected[key]|=m;
        }
        var coverage=new HashSet<string>(); var wrong=new List<string>(); var raidWrong=new List<string>();
        var corrections=new List<string>();
        foreach(var s in sources)
        {
            uint[] map; uint[] ds;
            if(!maps.Rows.TryGetValue(s.Map,out map) || (map[2]!=1 && map[2]!=2) || !mapModes.TryGetValue(s.Map,out ds)) continue;
            List<Drop> direct;
            if(s.Loot>0 && loot.TryGetValue(s.Loot,out direct))
                foreach(var r in direct.Where(x=>x.Ref>=0))
                {
                    int exp; if(!expected.TryGetValue(s.Map+":"+r.Item,out exp) || exp==0) continue;
                    int supported=ds.Aggregate(0,(mask,d)=>mask|(1<<(int)d));
                    int actual=r.Mask==0 ? supported:r.Mask;
                    if((actual & ~exp & supported)==0 && (actual&exp)!=0) continue;
                    int target=r.Mask==0 ? exp:r.Mask&exp;
                    if(target==0) target=exp;
                    corrections.Add(s.Map+"\t"+s.Name+"\t"+r.Entry+"\t"+r.Item+"\t"+r.Mask+"\t"+target);
                }
            foreach(uint d in ds)
            {
                if(d!=1 && d!=2 && d!=3 && d!=4 && d!=5 && d!=6 && d!=7 && d!=14) continue;
                if((s.Mask&(1<<(int)d))==0) continue;
                foreach(var drop in Expand(loot,refs,s.Loot,1<<(int)d,0,"source:"+s.Loot,new HashSet<int>()))
                {
                    string key=s.Map+":"+drop.Item1.Item; int exp;
                    coverage.Add(key+":"+d);
                    if(expected.TryGetValue(key,out exp) && exp!=0 && (exp&(1<<(int)d))==0)
                        (map[2]==1 ? wrong : raidWrong).Add(s.Map+"\t"+maps.Text(map[5])+"\t"+s.Entry+"\t"+s.Name+"\t"+d+"\t"+drop.Item1.Item+"\t"+exp+"\t"+drop.Item1.Mask+"\t"+drop.Item2+"\t"+drop.Item1.Entry);
                }
            }
        }
        File.WriteAllLines(Path.Combine(dir,"wrong-dungeon-mode.tsv"),new[]{"map\tname\tsource\tsourceName\tdifficulty\titem\texpectedMask\trowMask\tpath\trowEntry"}.Concat(wrong.Distinct()));
        File.WriteAllLines(Path.Combine(dir,"wrong-raid-mode.tsv"),new[]{"map\tname\tsource\tsourceName\tdifficulty\titem\texpectedMask\trowMask\tpath\trowEntry"}.Concat(raidWrong.Distinct()));
        File.WriteAllLines(Path.Combine(dir,"creature-mode-candidates.tsv"),new[]{"map\tname\tentry\titem\toldMask\tnewMask"}.Concat(corrections.Distinct()));
        var missing=new List<string>();
        foreach(var i in items.Rows.Values)
        {
            uint[] e,j,map,ds;
            if(!journal.Rows.TryGetValue(i[1],out e) || !instances.Rows.TryGetValue(e[6],out j) || !maps.Rows.TryGetValue(j[1],out map) || map[2]!=1 || !mapModes.TryGetValue(j[1],out ds)) continue;
            foreach(uint d in ds.Where(x=>x==1 || x==2))
                if((i[3]&(1<<(int)(d-1)))!=0 && !coverage.Contains(j[1]+":"+i[2]+":"+d))
                    missing.Add(j[1]+"\t"+maps.Text(map[5])+"\t"+journal.Text(e[9])+"\t"+d+"\t"+i[2]);
        }
        File.WriteAllLines(Path.Combine(dir,"missing-journal-loot.tsv"),new[]{"map\tname\tencounter\tdifficulty\titem"}.Concat(missing.Distinct()));
        var achRows=new List<string>(); var inventory=new List<string>(); var gates=new List<string>();
        var broken=new List<string>();
        foreach(var map in maps.Rows.Values.Where(x=>x[2]==1 || x[2]==2))
        {
            uint[] ds; if(!mapModes.TryGetValue(map[0],out ds)) continue;
            var aa=achievements.Rows.Values.Where(x=>x[2]==map[0]).ToArray();
            inventory.Add(map[0]+"\t"+maps.Text(map[5])+"\t"+map[2]+"\t"+string.Join(",",ds)+"\t"+aa.Length+"\t"+sources.Count(x=>x.Map==map[0]));
            foreach(var a in aa)
            {
                var descendants=new HashSet<uint>{a[14]}; bool more=true;
                while(more) { more=false; foreach(var t in trees.Rows.Values) if(descendants.Contains(t[5]) && descendants.Add(t[0])) more=true; }
                var cs=trees.Rows.Values.Where(x=>descendants.Contains(x[0]) && x[1]!=0).Select(x=>x[1]).Distinct();
                foreach(var id in cs)
                {
                    uint[] c; if(!criteria.Rows.TryGetValue(id,out c)) { achRows.Add(a[0]+"\t"+achievements.Text(a[4])+"\t"+map[0]+"\tMISSING:"+id); continue; }
                    achRows.Add(a[0]+"\t"+achievements.Text(a[4])+"\t"+map[0]+"\t"+id+"\t"+c[1]+"\t"+c[2]+"\t"+c[8]);
                    if(c[8]!=0 && !modifiers.Rows.ContainsKey(c[8])) broken.Add("modifier\t"+a[0]+"\t"+id+"\t"+c[8]);
                    if(achievements.Text(a[4]).StartsWith("Heroic:"))
                        gates.Add(a[0]+"\t"+achievements.Text(a[4])+"\t"+map[0]+"\t"+id+"\t"+ModeGate(modifiers,c[8],map[2]==2?3u:1u,new HashSet<uint>())+"\t"+ModeGate(modifiers,c[8],map[2]==2?5u:2u,new HashSet<uint>())+"\t"+ModeGate(modifiers,c[8],map[2]==2?4u:1u,new HashSet<uint>()));
                }
            }
        }
        File.WriteAllLines(Path.Combine(dir,"instances.tsv"),new[]{"map\tname\ttype\tdifficulties\tmapAchievements\tlootSources"}.Concat(inventory));
        File.WriteAllLines(Path.Combine(dir,"achievement-criteria.tsv"),new[]{"achievement\tname\tmap\tcriteria\ttype\tasset\tmodifier"}.Concat(achRows));
        File.WriteAllLines(Path.Combine(dir,"heroic-achievement-gates.tsv"),new[]{"achievement\tname\tmap\tcriteria\tnormalPossibilities\theroicPossibilities\tnormal25Possibilities"}.Concat(gates));
        File.WriteAllLines(Path.Combine(dir,"broken-achievement-links.tsv"),new[]{"kind\tachievement\tcriteria\tmissing"}.Concat(broken));
        Console.WriteLine("Instance maps: "+inventory.Count+"; achievement criteria: "+achRows.Count+"; wrong dungeon mode paths: "+wrong.Distinct().Count()+"; missing journal loot candidates: "+missing.Distinct().Count());
    }
}
