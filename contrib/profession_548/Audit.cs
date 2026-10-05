using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;

public static class ProfessionAudit
{
    static VisualAuditDbc Read(string dir,string name) { return new VisualAuditDbc(Path.Combine(dir,name+".dbc")); }
    public static void Run(string dbc,string output)
    {
        var spells=Read(dbc,"Spell"); var effects=Read(dbc,"SpellEffect");
        var skills=Read(dbc,"SkillLineAbility"); var enchants=Read(dbc,"SpellItemEnchantment");
        var items=File.ReadLines(Path.Combine(output,"items.tsv")).Skip(1).Select(x=>x.Split('\t')).ToDictionary(x=>uint.Parse(x[0]));
        var skillIds=new HashSet<uint>{164,165,171,182,186,197,202,333,393,755,773,129,185,356,794};
        var roots=new HashSet<uint>(); var enchantIds=new HashSet<uint>();
        var perks=new List<string>();
        foreach(var a in skills.Rows.Values.Where(x=>skillIds.Contains(x[1])))
        {
            roots.Add(a[2]); uint[] s;
            if(spells.Rows.TryGetValue(a[2],out s) && a[7]==1)
                perks.Add(a[1]+"\t"+a[5]+"\t"+a[2]+"\t"+spells.Text(s[1]));
        }
        foreach(var e in enchants.Rows.Values)
        {
            string[] item;
            if(skillIds.Contains(e[16]) || (items.TryGetValue(e[14],out item) && skillIds.Contains(uint.Parse(item[1])))) enchantIds.Add(e[0]);
        }
        // Custom-script selected effects have no DBC trigger link from their driver.
        foreach(uint id in new uint[]{96228,96229,96230,120032,104423,104509,104510,104993,116631,142530,142535}) roots.Add(id);
        bool changed=true;
        while(changed)
        {
            changed=false;
            foreach(var e in effects.Rows.Values.Where(x=>roots.Contains(x[27])))
            {
                if(e[23]!=0 && spells.Rows.ContainsKey(e[23]) && roots.Add(e[23])) changed=true;
                if(e[2]==53 || e[2]==54 || e[2]==92 || e[2]==156)
                    if(enchants.Rows.ContainsKey(e[13]) && enchantIds.Add(e[13])) changed=true;
                string[] item;
                if(e[11]!=0 && items.TryGetValue(e[11],out item))
                    foreach(string field in item.Skip(2))
                    {
                        int id=int.Parse(field);
                        if(id>0 && spells.Rows.ContainsKey((uint)id) && roots.Add((uint)id)) changed=true;
                    }
            }
            foreach(uint id in enchantIds)
            {
                uint[] e=enchants.Rows[id];
                for(int i=0;i<3;++i)
                    if((e[2+i]==1 || e[2+i]==3 || e[2+i]==7) && e[8+i]!=0 && spells.Rows.ContainsKey(e[8+i]) && roots.Add(e[8+i])) changed=true;
            }
        }
        File.WriteAllLines(Path.Combine(output,"spell-roots.txt"),roots.OrderBy(x=>x).Select(x=>x.ToString()));
        File.WriteAllLines(Path.Combine(output,"automatic-skill-spells.tsv"),new[]{"skill\trequiredRank\tspell\tname"}.Concat(perks));
        var rows=new List<string>();
        foreach(uint id in enchantIds.OrderBy(x=>x))
        {
            var e=enchants.Rows[id];
            rows.Add(id+"\t"+enchants.Text(e[11])+"\t"+e[16]+"\t"+e[17]+"\t"+e[18]+"\t"+e[12]+"\t"+string.Join(",",e.Skip(2).Take(3))+"\t"+string.Join(",",e.Skip(5).Take(3))+"\t"+string.Join(",",e.Skip(8).Take(3)));
        }
        File.WriteAllLines(Path.Combine(output,"enchants.tsv"),new[]{"enchant\tname\tskill\trank\tlevel\tvisual\ttypes\tamounts\tspells"}.Concat(rows));
        var itemVisuals=Read(dbc,"ItemVisuals");var itemEffects=Read(dbc,"ItemVisualEffects");
        var models=new HashSet<string>();var missing=new List<string>();
        foreach(uint id in enchantIds)
        {
            var e=enchants.Rows[id];uint[] visual;
            if(e[12]==0) continue;
            if(!itemVisuals.Rows.TryGetValue(e[12],out visual)){missing.Add("enchant "+id+" visual "+e[12]);continue;}
            foreach(uint effect in visual.Skip(1).Where(x=>x!=0))
            {
                uint[] v;if(!itemEffects.Rows.TryGetValue(effect,out v)){missing.Add("visual "+e[12]+" effect "+effect);continue;}
                string model=itemEffects.Text(v[1]);
                if(model.EndsWith(".mdx",StringComparison.OrdinalIgnoreCase)) model=model.Substring(0,model.Length-4)+".m2";
                models.Add(model);
            }
        }
        File.WriteAllLines(Path.Combine(output,"item-visual-issues.txt"),missing);
        File.WriteAllLines(Path.Combine(output,"item-models.txt"),models.OrderBy(x=>x));
        Console.WriteLine("Profession roots and children: "+roots.Count+"; enchantments: "+enchantIds.Count+"; auto-learn skill rows: "+perks.Count);
    }
}
