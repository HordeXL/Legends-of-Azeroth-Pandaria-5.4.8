-- =====================================================================
-- 2026_09_27_00_world_consolidated_updates.sql
-- 2026-09-27 全部修复的合并版（幂等，可整体重复导入）
--
-- 合并来源：
--   PART 1 = 2026_09_27_01_world_zhcn_fill_page_text.sql   （page_text_locale 缺失 zhCN 补齐 371 条）
--   PART 2 = 2026_09_27_02_world_fix_page_text_mixed.sql   （page_text/zhCN/zhTW 中英混合垃圾修复）
--   PART 3 = 2026_09_27_03_world_fix_cooking_chain.sql     （烹饪引导任务链 31279/31486/31281 修复）
--   PART 4 = 04+09+10+11 号合并（任务 29907 陈和丽丽 最终状态）
--
-- 已废弃（被后续版本覆盖，未并入）：
--   05 / 06 / 07 / 08 号（护送脚本迭代过程，最终态见 PART 4）
-- =====================================================================

-- =====================================================================
-- PART 1：page_text_locale 缺失 zhCN 补齐（原 01 号）
-- =====================================================================
--
-- 2026_09_27_01_world_zhcn_fill_page_text.sql
-- 补全 page_text_locale 缺失的全部 zhCN 翻译（371 条）
-- 来源：繁体中文(174 条)转简体 + 英文/法文(197 条)人工翻译
--

SET NAMES 'utf8mb4';

DELETE FROM `page_text_locale` WHERE `ID`=0 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (0,'zhCN','至尊至贵的战神贾拉克：$B$B那些恐角龙又顶死了一个正在受训的驯兽师。那蠢货被一只嗜血龙咬了一口，失了神。他正在组装的巫偶整个散了架，恐角龙当场把他撕成了碎片。$B$B我们操之过急了。我们的驯兽师需要长年的训练。我知道我们需要更庞大的军队，可要是野兽反过来残杀我们自己人，那对咱们也没什么好处。$B$B我们愿意效劳，但您比谁都清楚，咱们不能让小娃娃去干巨魔的差事。',1);
DELETE FROM `page_text_locale` WHERE `ID`=1 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (1,'zhCN','这里是一罐灰烬。这是我理智的灰烬，我热情的灰烬，我抱负的灰烬。它们都已被彻底摧毁，灰飞烟灭。愿所有看到这片荒芜之地的人，都记住这个倒下的苦工。他为了联盟流血，又为了部落牺牲，最后却被那些吞噬了他最珍视之物、邪恶而无魂的家伙逼疯了。当他们享用他的劳动果实时，愿他们承受他的怒火。也许不在这个世界，但在此后的每一个世界。这是我的宣言，我庄严的誓言，我永恒的承诺。我将为我的苦难复仇。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=2 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2,'zhCN','自你离开永望林以来，我一直在研读《渡鸦之书》，并且发现了一些能助你击败渡鸦之神的情报。$B解放那些灵魂之后，它们便与你结下了羁绊，我相信它们会心甘情愿地在对抗渡鸦之神的战斗中助你一臂之力。$B你第一次释放这些灵魂时，它们会处于休眠状态——几个世纪以来它们一直如此。使用你的持续治疗法术为它们注入能量，就能唤醒它们，让它们在战斗中协助你。当魔法消退时，它们会重新沉睡。$B以下是我为每只鸟灵所做的笔记：',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3,'zhCN','猎鹰之灵$B猎鹰之灵被赋予了惊人的速度与敏捷，在鸦人当中因其高超的狩猎技巧而备受尊崇。只要你用持续治疗法术为猎鹰之灵注入能量，它就会在施法和近战战斗中为你增添一份速度。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=4 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4,'zhCN','雄鹰之灵$B鸦人传统认为，雄鹰之灵虽不如它的猎鹰兄弟飞得快，却拥有最精湛的狩猎本领。只要你用持续治疗法术将它从沉睡中唤醒，雄鹰之灵就会用它的本领对付你的敌人。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=5 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (5,'zhCN','战鹰之灵$B$B石板上对战鹰赞赏有加，仿佛它曾与渡鸦结盟。战鹰之灵是鸦人古老的复仇象征，常被蒙受冤屈之人祈求。使用持续治疗法术唤醒战鹰之灵，你就能共享它的力量，反伤那些伤害你的人。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=149 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (149,'zhCN','现在你就去找齐我召唤伟大的旋风所需的材料。祝你好运。\n\n——观风者巴兹拉\n\n',12340);
DELETE FROM `page_text_locale` WHERE `ID`=264 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (264,'zhCN','矿工奥维尔$B欠款，碧玉矿坑送来下批矿石时偿还。$B$B矿工菲格拉德$B欠款，碧玉矿坑送来下批矿石时偿还。$B$B平民奈杉德$B债务已还清。$B$B平民梅恩$B债务已还清。$B$B工头邦德斯$B欠款，碧玉矿坑送来下批矿石时偿还。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=384 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (384,'zhCN','另外，这位信差不仅协助我们完成了任务，而且帮助我们击败了邪恶的伊瓦、营救了埃兰德，并且负责递送了这份报告。$B$B我们对$g他:她;充满感激之情，希望上层能对其卓越表现给予相应的嘉奖。$B$B- 亡灵哨兵兰妮·尤瑞克$B行动负责人',12340);
DELETE FROM `page_text_locale` WHERE `ID`=912 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (912,'zhCN','取来一支充能荆棘。要得到它，你需要从阿拉希高地的枯木巨魔身上收集10根枯木图腾杖。把这些杖带到外绑之环——就在同一片高地上的一个石圈。把杖放在石圈中央的石头上，等待闪电击中它。当闪电降临时，充能荆棘便会成形。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=2711 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2711,'zhCN','完成仪式$B$B你可在法阵边缘查看魔法符文。当九个符文全部出现时，仪式便结束了，你将看见巨大的能量从新生的法阵中涌出。$B$B你可以在那里使用克索诺斯雕纹，由此打开通往克索诺斯的传送门，引出一匹恐惧战马。$B$B打败恐惧战马，释放它的灵魂。奴役这个灵魂，你就可以随心所欲地召唤恐惧战马了。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=2823 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2823,'zhCN','数千年前，被放逐的上层精灵在洛丹伦的海岸登陆，建立了魔法王国奎尔萨拉斯。这些自称为高等精灵的族人，在国土的中心创造了一个蕴含巨大魔力的源泉——太阳之井。久而久之，他们对太阳之井不稳定的能量产生了依赖，全然不顾远古时代血淋淋的教训。',0);
DELETE FROM `page_text_locale` WHERE `ID`=2824 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2824,'zhCN','第三次战争期间，邪恶的阿尔萨斯王子入侵奎尔萨拉斯，将这个一度强盛的王国化为废墟与灰烬。他的亡灵军团几乎屠戮了高等精灵九成的人口。此外，他还利用太阳之井的能量复活了克尔苏加德——一个强大的亡灵巫妖——从而玷污了太阳之井的魔法之水。幸存的少数精灵意识到自己已被切断与奥术力量之源的联系，变得愈发躁动而绝望。',0);
DELETE FROM `page_text_locale` WHERE `ID`=2825 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2825,'zhCN','就在精灵们最黑暗的时刻，凯尔萨斯·逐日者——奎尔萨拉斯王室最后的血脉——登场了。人们通常称他为凯尔。他深知，若没有曾经赋予他们力量的滋养性魔法，残存的族人将难以长久存续。为了纪念逝去的同胞，他将族人更名为血精灵，并教他们汲取周围环境中的神秘能量——甚至恶魔能量——以平息他们对魔法可怕的渴求。',0);
DELETE FROM `page_text_locale` WHERE `ID`=2826 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2826,'zhCN','为了替族人——如今在精灵语中被称为''辛多雷''——寻找新的命运，凯尔萨斯远赴遥远的外域世界，在那里遇见了堕落的暗夜精灵伊利丹。在伊利丹的教导下，凯尔和他的血精灵重获了往日的大部分力量。',0);
DELETE FROM `page_text_locale` WHERE `ID`=2827 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2827,'zhCN','不幸的是，血精灵吸纳恶魔能量的做法使他们遭到昔日联盟同伴的唾弃。于是，留在艾泽拉斯的残余血精灵只能绝望地寄望于部落，希望部落能助他们前往外域，与凯尔萨斯重聚，实现他许诺给他们的黄金命运。',0);
DELETE FROM `page_text_locale` WHERE `ID`=2904 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2904,'zhCN','第1项，共1项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=2915 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2915,'zhCN','第3项，共4项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=2922 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (2922,'zhCN','又及——我们的大魔导师已收到外域方面对萨尔之问的回音。答案是肯定的，确凿无疑。\n\n<这封信件上还盖有女伯爵希尔瓦娜斯·风行者的附加印章>',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3058 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3058,'zhCN','ct,t',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3063 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3063,'zhCN','随着克尔苏加德在洛丹伦取得成功，巫妖王开始为进攻人类文明做最后的准备。耐奥祖将瘟疫之力注入数件名为''瘟疫釜''的便携神器中，命令克尔苏加德将它们运往洛丹伦，藏匿于各个受邪教控制的村庄。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3064 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3064,'zhCN','这些由忠诚的邪教徒守护的大釜将充当瘟疫发生器，让瘟疫悄然蔓延到洛丹伦北部毫无防备的农田与城市。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3080 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3080,'zhCN','<HTML>$B<BODY>$B$B$B<P>那个声音低语，“到我这儿来……”从一开始我就知道那是圣光在我的梦中对我说话。终于!在我这些年的祈祷与善行，清除那些在艾泽拉斯地面上的不死生物与瘟疫。在所有的失败与复苏之后。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3081 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3081,'zhCN','<HTML>$B<BODY>$B$B$B<P>又再此发生了。“到我这儿来……”圣光命令我。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3082 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3082,'zhCN','<HTML>$B<BODY>$B$B$B<P>这一次我醒了!充满活力，但过了大约一分钟之后，在这温暖阳光普照的日子里，我吐出的气息化成白雾而冰冷。有一个牧师注意到，开始屈膝祈祷。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3084 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3084,'zhCN','<HTML>$B<BODY>$B$B$B<P>指挥官和主教都接受了。他们并非全无选择。史曲特主教显得尤其热心。他提到一个全新的十字军，并且发誓要把我们之中的信仰不坚全赶出去。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3085 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3085,'zhCN','<HTML>$B<BODY>$B$B$B<P>我把多数的十字军留在这里继续处理我们后院的不死生物。我想像著一旦他们完成了我们起头的事情，他们就能解甲归田，回到家乡平静度日。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3086 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3086,'zhCN','<HTML>$B<BODY>$B$B$B<P>人们开始谈论即将到来的一天，将会改变血色十字军的每一件事。史曲特主教替它取了个名字，叫做赤红黎明。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3087 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3087,'zhCN','<HTML>$B<BODY>$B$B$B<P>圣光又迫切地对再次对我说话了。我带着不耐的情绪从睡梦中醒来。我不会让圣光失望的。绝不能再拖延了。我们一定得尽快上路!',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3088 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3088,'zhCN','<HTML>$B<BODY>$B$B$B<P>现在我知道为什么圣光挑选我来进行。有一天夜里一个天谴亡域飞过我们头上的空中，并且释放出地狱的爪牙!',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3089 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3089,'zhCN','<HTML>$B<BODY>$B$B$B<P>有人通知我壁炉谷和附近的地区已经开始在集结了。高阶指挥官嘉尔瓦·波尔伯勒自己打算离开他们来拯救我们。他的努力是无用的。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3090 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3090,'zhCN','<HTML>$B<BODY>$B<P>今天早上没有从我的信差收到任何消息。显然他们都没能活着抵达壁炉谷。我们已经失去瘟疫之地了。波尔伯勒会带着他的部队往这里来，然后在开阔处遭到歼灭。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3091 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3091,'zhCN','他们告诉我，这趟旅程要花上两个月。其他的船不像''愚者号''那样为速度而造。它们载着我们大部分的兵力和装备，不过是些单桅货船，但能平安抵达。\n\n我并不期待这次航行，但为了圣光，我会忍住晕船的折磨。我绝不能让别人看出来。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3127 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3127,'zhCN','我怀着忐忑的心情眺望新阿瓦隆，隐隐觉得这将是我最后一眼。我们事业的命运系于诺森德。不知为何，我心中充满了不祥的预感。眼前的任务应该能驱散这些忧虑。我会把它们抛诸脑后。\n\n赤红黎明已然降临。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3312 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3312,'zhCN','第1项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3313 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3313,'zhCN','第2项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3314 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3314,'zhCN','第1项，共1项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3315 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3315,'zhCN','第1项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3316 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3316,'zhCN','第2项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3317 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3317,'zhCN','第3项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3318 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3318,'zhCN','第1项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3320 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3320,'zhCN','第3项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3321 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3321,'zhCN','第1项，共1项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3322 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3322,'zhCN','第1项，共1项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3328 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3328,'zhCN','第1项，共1项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3331 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3331,'zhCN','第2项，共3项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3333 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3333,'zhCN','第1项，共6项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3336 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3336,'zhCN','第4项，共6项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3337 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3337,'zhCN','第5项，共6项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3338 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3338,'zhCN','第6项，共6项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3339 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3339,'zhCN','第1项，共1项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3345 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3345,'zhCN','第1项，共5项。',12340);
DELETE FROM `page_text_locale` WHERE `ID`=3560 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3560,'zhCN','缺少WDB数据。',0);
DELETE FROM `page_text_locale` WHERE `ID`=3606 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3606,'zhCN','我们好不容易才从凯赞逃出生天!火山夺走了所有事物…我的房子、我的车子、我的宠物猪、宠物猪的小屋、宠物猪的小车车...$B$B不过，至少我们活着上船啦!我们将会直接航向杜洛塔，在我们再次踏上干爽地面之后，去骗几个兽人，然后一周内我们就能在一大笔钱上面打滚啦!',1);
DELETE FROM `page_text_locale` WHERE `ID`=3615 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3615,'zhCN','暴风城的居民们，留心占据我们街道的末日预言者们。不要被他们的疯狂和谎言所惑。他们只是想要削弱我们的力量，使我们无力面对真正的敌人:部落!',1);
DELETE FROM `page_text_locale` WHERE `ID`=3616 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3616,'zhCN','对于那些习惯秘法或是魔化能量的人来说，元素的力量拥有独特的复杂能量，常对经验不足的施法者造成伤害…有时甚至是致命的。$B$B那些想要探索元素引导这门科学的人们必须谨记，就算已经脱离负责将他们自己活化和塑形的秘法能量，元素自身还是拥有极高的危险性。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3617 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3617,'zhCN','当我们将注意力放在这本秘典的实验体身上时，我口中反复复诵著注意事项，神秘能量的引导加上短暂生命的物质，我将其命名为“恋父情节残忍行径”。$B$B这个奇妙、无味的物质是从风元素的旋转气流中产生的，估计要在血液或黏液这种类似的同质相似物质中效果更好。目前已知，雷云会释放这种物质，就像是你我会排放大量液体一样。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3618 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3618,'zhCN','你可能认为恋父情节残忍行径这个东西算是一种废物，对我们来说没有用处。我的实验可以证明根本不是这样!就在我的舌头第一次触碰到充满电力的电容罐电极时，我坐倒在地上，仅能以“就像是上天眷怜、降下其恩宠之吻”来形容这种感觉。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3619 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3619,'zhCN','一旦存放到适合的容器中，雷电质就会产生庞大的建构性潜在能量。我的实验显示它可以消灭小猫咪和兔宝宝。$B$B一个阵列的电容罐可以用来维持通往元素界域的传送门，让召唤者可以自由地前往别处办事。我最近在海加尔山顶架设了一个这样的装置，以方便输送大量的人群和货物往返火源之界。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3620 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3620,'zhCN','恋父情节残忍行径这本书就像是杯浓烈的果汁，老是企图采取最短、最湿、最硬的那条路径回归地面上。$B$B千万不要饮下这杯果汁。$B$B它的味道就像是烧焦的血肉，加速分解你心中的怜悯心。随时保护好自己，披上一层厚厚的柔软皮毛，抱持不轻易相信的态度，用高姿态和愚蠢的方式去对应。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3621 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3621,'zhCN','精通恋父情节残忍行径能让我们更进一步地接近我们的目标，让我们更能对元素做出全局掌控，将我们的主人和主宰召唤到现世，让我们的脸庞因祂们无穷无尽的知识而洋溢着活力。$B$B光来!沐浴在这光下，苦痛、灼热、最后麻木，然后提醒我们在世界创生的时刻，饮下支配大权这杯浓烈果汁的人将会是信者们!',1);
DELETE FROM `page_text_locale` WHERE `ID`=3622 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3622,'zhCN','她扭着尾巴、摆着腰肢，曲线玲珑的身影款步穿过湖面，朝岸边歇息的男人走去；男人见她走近，霍然起身，显然为她的到来喜形于色。蓝色的手臂搭上他的肩头，光滑的尾巴妖娆地缠上他的腰际。''人家为什么非得跑这么远的路，来见你这样的人类？''她的嗓音带着浓重而诱人的口音。$B$B他咧嘴狂笑，轻轻推开她，毫不掩饰地盯着火光映照下她的容颜。$B$B''眼睛往上看！''她佯怒道。$B$B他无奈地耸耸肩，伸手从行囊里掏出一个小袋子。''我可爱的苏拉，我给你带了点东西。''他的话语自信满满，如钢铁般笃定。',0);
DELETE FROM `page_text_locale` WHERE `ID`=3626 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3626,'zhCN','<HTML>$B<BODY>$B$B$B<H1 align="center">艾萨拉女王',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3627 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3627,'zhCN','<HTML>$B<BODY>$B$B$B<H1 align="center">高等游侠维拉里安',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3628 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3628,'zhCN','<HTML>$B<BODY>$B$B$B<H1 align="center">蕾丝萨莉雅·瓦许',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3629 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3629,'zhCN','<HTML>$B<BODY>$B$B$B<H1 align="center">高阶祭司希拉莲',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3630 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3630,'zhCN','卡辛，$b$b他回来了。$b$b    - 看守者马哈尔巴',1);
DELETE FROM `page_text_locale` WHERE `ID`=3631 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3631,'zhCN','致读此信者:$b$b圣匣守护者的高阶人员，同时亦为蔽日旅团领导者之洛汉·蔽日，正寻求具有能力的冒险者在诅咒之地南部的考古学研究中助他一臂之力。参与者将会获得相对应的补偿。$b$b蔽日旅团正致力于腐化之森地区一切魔法文物的发掘、编目以及保存工作上。该地区先前为人所知的名称为腐化之痕，近来因狼人德鲁伊之故得以改观，因此林木遍布。若想得知更多资讯，请与洛汉·蔽日或是克拉雅·蔽日联系。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3632 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3632,'zhCN','<几个的地方的墨水已被冲掉，导致这封信缺了好几行字。>$B$B...每种型态的社...都是奠基于...压迫者与被压迫者的对立...$B$B...别无所失，失去的只有你的枷锁...$B$B...过去不能被遗忘...$B$B...不能被原谅...$B$B...将再度掘起!',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3633 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3633,'zhCN','仆从们，我们的首领下达了指令。你们必须洗劫哨兵岭并救出上将。你们所抢的一切都归你们自己所有。$B$B- 赫利克斯',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3634 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3634,'zhCN','当一个人被赐予一件外袍，他将发誓效忠于赐予者。这些人现在是政府的傀儡，他们不会在乎你经历过什么。他们身穿着主人赐予他们的制服，只在乎他们主人所在乎的事物。$B$B-范克里夫',1);
DELETE FROM `page_text_locale` WHERE `ID`=3635 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3635,'zhCN','<HTML>$B<body>$B<h1>一群无家可归的老百姓在法布隆农场后方惨遭杀害$B',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3636 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3636,'zhCN','这让人无法置信。我们已经承受这种折磨四年了，但很快就会结束。兄弟会将会重生，我们会扫荡这片大地净化所有一切的腐败和肮葬物。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3637 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3637,'zhCN','各位兄弟姊妹们，我们获得救赎的时刻越来越近了!就在今晚，我们将会脱胎换骨，以英雄之姿重获新生!$B$B-范克里夫',1);
DELETE FROM `page_text_locale` WHERE `ID`=3638 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3638,'zhCN','第一天$B$B''德鲁伊的天赋，便是自由地拥抱与探索自然的方方面面。''$B$B玛法里奥常常把这句话挂在嘴边，我曾经天真地以为他是真心践行此道的。然而，就在我的导师高谈这份自由的同时，他却禁用了我们的形态，令我和狼群德鲁伊的同门蒙羞。至今我仍能清晰地想起，每当他发现我们偷偷练习时那愤怒的咆哮。$B$B''狼群形态无法被控制。它会吞噬你，殃及我们所有人。''$B$B玛法里奥对我们的妄断令人愤慨。他难道没有意识到，古老的狼神戈德林是自然之恩赐，就存在于我和我的狼群兄弟体内吗？不是我们选择了它，而是它选择了我们。排斥它，就是背弃自然本身。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3639 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3639,'zhCN','最让我痛心的是，在我们族人面临邪恶萨特战争威胁的当下，玛法里奥却排斥我们——而这些德鲁伊本可以扭转战局。$B$B如今这些都无关紧要了。今天，我和兄弟们将永远告别暗夜精灵社会，在荒野中开始新生。我们要证明导师的信念是错的，证明戈德林之灵其实可以掌控。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3640 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3640,'zhCN','第七天$B$B自从我们在森林深处建立新家以来，六个夜晚已经过去。狼群首领伦塞尔接管了族群，在他睿智的领导下，我终于找到了真正的自由。$B$B每晚我们都在一棵倒下的老树根旁修炼形态，戈德林的獠牙就供奉在那里。它美得令人惊叹……仅仅待在它身边，我就仿佛充满了力量。有时我不禁想，狼神是否故意在这世上留下自己的一缕残躯，作为赠予追求其形态者的礼物。$B$B这些夜间的修炼让我重新充满信心，相信我能驾驭戈德林之灵。尽管玛法里奥总说它有多危险，但就连现在，我们也在证明他是错的。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3641 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3641,'zhCN','第十二天$B$B今晚发生了争执。一位名叫萨尔德鲁斯的老练德鲁伊向伦塞尔争夺狼群的领导权，两位德鲁伊以狼群形态一决胜负。他们绕着彼此兜圈，口沫横飞、獠牙毕露，仿佛过了一辈子那么久，最后萨尔德鲁斯猛扑向伦塞尔，将他扑倒在地。$B$B伦塞尔体面地接受了自己的失败，毫无怨言地交出了领导权。要是玛法里奥能亲眼见证这个夜晚萨尔德鲁斯与伦塞尔的风度就好了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3642 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3642,'zhCN','第二十三天$B$B近来有些怪事。兄弟们白天以狼群形态度过的时间越来越长。许多人声称这是精通此形态的必要过程，可我觉得原因不止于此。$B$B一股原始的冲动在我体内滋长。那是一种唯有化为狼群形态才能满足的渴望。我担心其他人也感受到了它。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3643 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3643,'zhCN','第二十八天$B$B今夜，我们顶着两轮明月，以狼群形态穿行荒野，猎杀了三头雄鹿。我和兄弟们饿得发慌，径直撕开猎物，一边进食一边互相撕咬。当我把牙齿咬进雄鹿生肉的那一刻，极乐涌遍全身。哪怕毫无食欲，饕餮这头猎物也会让我心满意足。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3644 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3644,'zhCN','第三十八天$B$B七个夜晚以来头一回变回人形。像其他人一样像狼一样活着，夜复一夜。狼群首领萨尔德鲁斯说暗夜精灵的躯体是弱者。所有人信任他。所有人追随他。若他见到如今的我，他会杀了我。$B$B戈德林之灵正在吞噬我们。抗拒它，和屈从它一样错误。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3645 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3645,'zhCN','第四十二天$B$B嘴里仍有萨尔德鲁斯的血腥味。$B$B细节已无法回想。只记得萨尔德鲁斯从倒树那里取走了戈德林的獠牙。我撞见他把獠牙拖进自己的巢穴，然后——$B$B<此页被血渍浸染，无法辨认>$B$B萨尔德鲁斯过了两夜才出来。我们一直在等他。獠牙与利爪，还有狂怒。我们把他撕成了碎片。遍地毛皮血肉。事后只剩啃剩的骨头。$B$B现在没有首领了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3646 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3646,'zhCN','第五十二天\n\n\n$B$B近来发生了很多事，我觉得自己终于恢复了些许神智。五个夜晚以前，我离开巢穴，发现狼群的成员围聚在某样东西周围——很快我便发现，是某个人。一名暗夜精灵，从他身上的气味我认出是拉莱尔·翼火，玛法里奥一派的德鲁伊。$B$B我们一拥而上将他包围，但这名入侵者寸步不让。尽管他保持着暗夜精灵的形态，我在他身上却嗅不到一丝恐惧。他的傲慢令人恼火。$B$B三名狂怒的兄弟扑向拉莱尔，而这个新来者化作狼群形态，毫不费力地击败了挑战者……却没有杀死他们。$B那一刻，我意识到了他与我们的不同。我们已沦为蛮兽……遍体鳞伤、瘦骨嶙峋、蓬头垢面。而拉莱尔却威风凛凛、气度堂堂，周身仍充盈着戈德林的精粹。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3647 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3647,'zhCN','当再无人敢向他挑战时，拉莱尔恢复了暗夜精灵的形态，开口说话。他训斥我们沦为无知的野兽，挥霍了戈德林精粹的纯净——那滔滔不绝的做派让我想起了玛法里奥。但与我昔日的导师不同，拉莱尔还承诺教我们驾驭狼神之灵的真正法门。我在他的话语中察觉到巨大的怒火，却又被一种自制力调和着——那种自制力，正是我近几周来不知不觉失去的东西。$B$B我们一个接一个地退出了狼群形态。我只能猜测，我的兄弟们和我一样，对这位新来者感到一种奇异的亲近，仿佛他就是戈德林派来的信使。$B$B从那以后，拉莱尔开始履行诺言教导我们，尽管他不再回应自己的本名。$B$B如今，他只以''始祖阿尔法''自称。$B——狼群德鲁伊盖德林·月牙',1);
DELETE FROM `page_text_locale` WHERE `ID`=3648 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3648,'zhCN','步骤1:杀$B步骤4:睡?$B步骤2:吃$B步骤1:拉屎',1);
DELETE FROM `page_text_locale` WHERE `ID`=3649 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3649,'zhCN','你们从那边发动攻击!$B我们从这边进攻!$B在人类城镇中间碰头。$B$B-犹勒，犹勒之子',1);
DELETE FROM `page_text_locale` WHERE `ID`=3650 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3650,'zhCN','<这张文件是空白的。>$B$B<更正。这张文件最近被人当卫生纸给用了。>',1);
DELETE FROM `page_text_locale` WHERE `ID`=3651 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3651,'zhCN','<整页内容都是以兽人文字写成的，你完全看不懂上面在写什么。>',1);
DELETE FROM `page_text_locale` WHERE `ID`=3652 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3652,'zhCN','影皮豺狼人和黑石兽人正在布署大量部队准备进攻暴风城。',13329);
DELETE FROM `page_text_locale` WHERE `ID`=3653 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3653,'zhCN','血帆命令$B$B亲爱的水手们，请仔细看好这篇命令中的内容，这将是我们在藏宝海湾干下的最后一票。$B$B上次‘漂亮男孩’邓肯的表现令我失望。替代人选已在北方，他将会从陆路率领人马穿过那该死的隧道入侵。$B$B尼哈鲁船长和他的斩浪号会从西南方以抱火轰击海角尖端。他会需要人力、火药粉以及很多很多绳索。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3654 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3654,'zhCN','少女的好运号将会直接开进港口开战。此船的船长下令不留活口:不分男人、女人、或是小孩，一经发现与藏宝海湾的黑水强盗有关系，一律直接丢入海中，让其成为奈普图隆的收藏。$B$B我将会在赤红之雾号上面率领大家从后方进攻。我们会用抱火支援，不让那些跑来防御他们重要藏宝海湾的家伙造成干扰。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3655 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3655,'zhCN','我们可没有打算离开喔，小伙子们。一旦抵达藏宝海湾，我们要让这座城镇陷入火海，然后就换我们来统治啦，不然就只好等死。把这件事情谨记在心。$B$B--舰队指挥官菲尔拉伦',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3656 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3656,'zhCN','基沙恩，如果你读到这份记事本，那就表示我已经死了。我的处境似乎很危险。$B$B兽人对他们的俘虏作出难以言喻的残暴行为。是的没错，我说的是俘虏，基沙恩。他们有着塞满战俘的监牢。如果你要炸掉这座山谷，你必须先释放这些俘虏。$B$B告诉我的妻子我爱她，然后除掉这些该死的垃圾。$B$B-布鲁贝克$B$B注－他们有黑龙。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3657 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3657,'zhCN','致尊敬的克雷利安校长，$B$B我以前的主人，我写这封信是为了让您了解到您的学生最近都做了些什么。我听从您的建议离开了我深爱的暴风城，在世界各地到处游历，以此来历练我的知识与智慧。我去过许多地方，最后决定在月溪镇这个可爱的小镇定居。随著收获季节的到来，西部荒野的农田景色是如此的美丽。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3658 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3658,'zhCN','刚到这里没几天，我就开始为附近农场中的孩子们上课了。我的课程进行得很顺利，镇长便委任我设立了一所学校，而且现在已经开始动工修建一所全新的校舍了!我从银松森林到暴风城，现在又来到月溪镇─谁能想到我会在艾泽拉斯经历那么多的事情!$B$B向您致意，$B$B斯塔文·密斯特曼托',1);
DELETE FROM `page_text_locale` WHERE `ID`=3659 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3659,'zhCN','尊贵的大人，$B$B我听说您需要为您的孩子找个老师。现在我暂时住在闪金镇的狮王之傲旅店里，由于目前月溪镇糟糕的状况，我被迫放弃了学校校长一职。我愿做您孩子的老师，希望您能接受我的申请。如果有必要，克雷利安校长可以向您证明我的能力。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3660 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3660,'zhCN','当冬天的雨季过后，道路适合旅行的时候，我会亲自前去找您。$B$B届时再见，$B$B银松的斯塔文·密斯特曼托',1);
DELETE FROM `page_text_locale` WHERE `ID`=3661 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3661,'zhCN','……那个叫基尔斯的男孩似乎很难管教，对我来说也许是个挑战。他的姐姐蒂罗亚则是个非常聪明的孩子，她的美貌也格外引人注目，蒂罗亚浑身都散发著女人独有的气质，而他们家可能已经安排她在明年结婚了。我有点离题了。这个星期我会陪他们一家人到他们那座艾尔文森林东谷伐木场附近的夏季别墅去度假，那里离赤脊山很近。我希望能在那儿再给您写信。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3662 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3662,'zhCN','...极其陌生而难以自拔的感觉。今天我感受到了这种以往未曾有过的感觉。在我辅导基尔斯学习历史的时候，蒂罗亚正在外面照料着她的花园。过了一会，她走了进来，把鲜红的秋海棠放在我的手心上，对我嫣然一笑，我感到自己的心在胸口里猛烈地跳动...',1);
DELETE FROM `page_text_locale` WHERE `ID`=3663 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3663,'zhCN','致尊敬的克雷利安校长，$B$B我以前的主人，我写这封信是为了让您了解到您的学生最近都做了些什么。我听从您的建议离开了我深爱的暴风城，在世界各地到处游历，以此来历练我的知识与智慧。我去过许多地方，最后决定在月溪镇这个可爱的小镇定居。随著收获季节的到来，西部荒野的农田景色是如此的美丽。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3664 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3664,'zhCN','刚到这里没几天，我就开始为附近农场中的孩子们上课了。我的课程进行得很顺利，镇长便委任我设立了一所学校，而且现在已经开始动工修建一所全新的校舍了!我从银松森林到暴风城，现在又来到月溪镇─谁能想到我会在艾泽拉斯经历那么多的事情!$B$B向您致意，$B$B斯塔文·密斯特曼托',1);
DELETE FROM `page_text_locale` WHERE `ID`=3665 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3665,'zhCN','尊贵的大人，$B$B我听说您需要为您的孩子找个老师。现在我暂时住在闪金镇的狮王之傲旅店里，由于目前月溪镇糟糕的状况，我被迫放弃了学校校长一职。我愿做您孩子的老师，希望您能接受我的申请。如果有必要，克雷利安校长可以向您证明我的能力。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3666 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3666,'zhCN','当冬天的雨季过后，道路适合旅行的时候，我会亲自前去找您。$B$B届时再见，$B$B银松的斯塔文·密斯特曼托',1);
DELETE FROM `page_text_locale` WHERE `ID`=3667 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3667,'zhCN','...那个叫基尔斯的男孩似乎很难管教，对我来说也许是个挑战。他的姐姐蒂罗亚则是个非常聪明的孩子，她的美貌也格外引人注目，蒂罗亚浑身都散发著女人独有的气质，而他们家可能已经安排她在明年结婚了。我有点离题了。这个星期我会陪他们一家人到他们那座艾尔文森林东谷伐木场附近的夏季别墅去度假，那里离赤脊山很近。我希望能在那儿再给您写信。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3668 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3668,'zhCN','...极其陌生而难以自拔的感觉。今天我感受到了这种以往未曾有过的感觉。在我辅导基尔斯学习历史的时候，蒂罗亚正在外面照料着她的花园。过了一会，她走了进来，把鲜红的秋海棠放在我的手心上，对我嫣然一笑，我感到自己的心在胸口里猛烈地跳动...',1);
DELETE FROM `page_text_locale` WHERE `ID`=3669 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3669,'zhCN','...我敢肯定，她和我有着相同的感觉。今天早晨，她甚至把手放在了我的手掌中。当她微笑的时候，她的眼眸像钻石一样闪亮。我们进行着无言的交流，我能够在我悸动的心里、在我火热的血管中感觉到她。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3670 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3670,'zhCN','...我从未想像我竟然会气成这样!她怎么敢这样对我!我教基尔斯数学的时候，蒂罗拉来了，还带着她的一个求婚者，他们竟公然手拉着手!真是个没教养的年轻人。蒂罗亚也没怎么介绍我，只是轻描淡写地说了句，“哦，这是我的家庭教师，斯塔文叔叔。他是个不错的老人家。”老人家!一听到这个词，我的脸就涨得通红。我不过比她大了几岁而已，而她竟背叛了...',1);
DELETE FROM `page_text_locale` WHERE `ID`=3671 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3671,'zhCN','...我的心仿佛随著绝望而跌入了无底的深渊。她欺骗了我的感情，现在竟然还订了婚。这个可恶的骗子，她假装自己陷入了爱河，其实她一直以来只是想要伤害我而已。我的心里只有黑压压的一片，每过一分钟，这种感觉就更加强烈一分。我要让她付出血的代价，但是与我流过的眼泪相比，那根本不算什么...',1);
DELETE FROM `page_text_locale` WHERE `ID`=3672 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3672,'zhCN','库尔森的囚犯档案$B$B别散播出去',1);
DELETE FROM `page_text_locale` WHERE `ID`=3673 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3673,'zhCN','柏尔林·燃羽$B$B罪名:抗命、不服从指挥$B$B判处:监禁50年',1);
DELETE FROM `page_text_locale` WHERE `ID`=3674 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3674,'zhCN','艾玫琳·裘妮丝$B$B罪名:由库尔森上校亲自下令惩处$B$B判处:监禁75年',1);
DELETE FROM `page_text_locale` WHERE `ID`=3675 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3675,'zhCN','奥斯伯·奥布诺提斯$B$B罪名:神经错乱$B$B判处:监禁130年',1);
DELETE FROM `page_text_locale` WHERE `ID`=3676 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3676,'zhCN','伯克斯通·赫洛德$B$B罪行:与叛军勾结$B$B判处:绞刑',1);
DELETE FROM `page_text_locale` WHERE `ID`=3677 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3677,'zhCN','康拉德·库尔森上校$B$B罪行:软弱$B$B判处:由高塔上抛向地面',1);
DELETE FROM `page_text_locale` WHERE `ID`=3678 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3678,'zhCN','库尔森的军官档案$B$B别散播出去',1);
DELETE FROM `page_text_locale` WHERE `ID`=3679 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3679,'zhCN','安德斯队长$B$B率领特种兵及丛林战士。负责维护营地部队秩序，以及避免营地资源在反抗军攻击之中毁灭。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3680 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3680,'zhCN','高卢斯队长$B$B率领咒医及头颅皱缩者。负责医疗行动及维护营地与附近血顶部族、劈颅部族之间的和平。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3681 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3681,'zhCN','米兰达队长$B$B库尔森暗影计划的领导者。负责维持和管理蓝石的贮藏所，并进一步研究它的功用。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3682 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3682,'zhCN','埃斯奎维尔队长$B$B库尔森上校死亡后的临时代理人。负责监督库尔森远征队的各项运作。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3683 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3683,'zhCN','月亮照耀着山谷',1);
DELETE FROM `page_text_locale` WHERE `ID`=3684 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3684,'zhCN','月亮照耀着山谷$B月光洒满了丛林$B骄傲的战士响应号召$B保卫我们的国家和神圣的大地$B$B月亮照耀山谷$B远离战争的哭泣$B这里流淌著$B敌人和我们的鲜血。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3685 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3685,'zhCN','当我们的同胞永远离去$B走进未知的土地$B在山谷的深处$B灵魂与精神变得坚强。$B当我们的同胞永远离去$B来到山上的圣殿$B我们将保卫他们永恒的精神$B将它镶入神圣的蓝水晶。$B当我们的同胞永远离去$B月亮照耀着山谷。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3686 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3686,'zhCN','漫游者格里雷克',1);
DELETE FROM `page_text_locale` WHERE `ID`=3687 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3687,'zhCN','漫游者格里雷克的故事$B$B[...碑文的头几行已经被磨损得无法看清了，不过最后几行还可以辨识...]$B$B格里雷克跺著脚穿越丛林。因为愤怒，他的双眼冒着火，嘴里发出低沉的声音。$B$B他高举左手朝天怒吼著。经过长期的狩猎，他的左臂显得异常强壮。$B$B格里雷克很久之前就永远地失去了他的右臂。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3688 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3688,'zhCN','于是他到处游荡、寻找。而他还是没有找回那只手臂。于是他一边走一边咒骂怒号著。$B$B但是格里雷克已经很久没有听从神灵的教诲，他们因此而愤怒，不再理会他的咒骂。$B$B格里雷克的命运就是这样，命运让他不断游荡，让他缺少一只手臂。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3689 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3689,'zhCN','古拉巴什的毁灭',1);
DELETE FROM `page_text_locale` WHERE `ID`=3690 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3690,'zhCN','一座海水之塔从海中升起，海神奈普图隆派出巨神海怪消灭伊拉莱。它们的体型是如此的巨大，触手舞动著宛如丛林般巨伟的海草，无数的巨神海蛇在它们的身体上游走。$B$B其中体型最为巨硕的一只海怪高高举起它的触手拍打水面，激起了漫天巨浪，乘着海神之怒冲向伊拉莱。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3691 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3691,'zhCN','巨神海怪咆哮著，发出了雷霆般的响声:$B$B“我们来了。”$B$B米洛斯毫不动摇地矗立着，施展他的魔法力量。袭向伊拉莱的海浪旋即一分为二，淹没了四周的丛林。米洛斯命令他的手下开始施展束缚法术，在无数食人妖的齐声吟唱中突然爆出一声巨响。$B$B此时一声怒吼压倒了众人的声音。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3692 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3692,'zhCN','米洛斯吼叫着，祂的魔法将徒众的法术能量聚合为一，然后射向逼近的海怪。$B$B海水分离，米洛斯的法术急速飞向奈普图隆的仆从。闪电撕裂天空，法术打在海怪身上，万千雷光降诸其身，海水为之蒸发，在地面凿出坑坑洞洞。$B$B米洛斯发出胜利的呼喊，祂知道自己的法术会让这些巨兽们一一倒下。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3693 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3693,'zhCN','但是海怪经历了相当长久的岁月。它们还记得当这片土地最初从海洋中诞生的情景。$B$B它们还记得当上古之神统治著世界，当旅者呼唤祂们的样子。它们还记得魔法初创之时。$B$B它们经历了相当相当悠久的岁月，知道许多许多秘密。尽管圣蛇米洛斯的法术强大无比，但食人妖仍只是终将一死的凡人。$B$B所以，失败了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3694 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3694,'zhCN','法术未能制服海怪，反而激怒了它们。千万年来，没有任何凡人能够带给它们痛苦，而食人妖的法术却令它们尝到了痛苦的滋味。$B$B于是它们摆脱了米洛斯的法术束缚，咆哮著展开了复仇。$B$B海底传来隆隆的巨响，滔天巨浪从海底卷起，涌向大地。当它们到达伊拉莱时，阴影笼罩了整座城市。$B$B在它们摧毁伊拉莱之前，一切突然静止了下来。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3695 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3695,'zhCN','食人妖的巫医们颤抖著，充满恐惧地呼唤他们的主人。米洛斯凝视着重重的滔天巨浪，虽知无力回天，却毫不退缩。他转向身旁最得力的助手，默默嘱咐数语，他们就将他最后的话语蚀刻成石。米洛斯接着转身面对来袭的海怪。$B$B他的脸上露出扭曲的表情，奋力掷出他的法杖，这是他的最后一击。$B$B海怪将它们的愤怒都倾泻在米洛斯身上，接着整个大海都向伊拉莱扑了过去。$B$B一切都结束了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3696 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3696,'zhCN','水淹没了丛林，冲走了所有的东西。食人妖和野兽尖叫着被大水冲过、淹没。$B$B许多古拉巴什的居民还没搞清楚大海为什么吞没他们，就已经葬身海底了。$B$B最终海水冲到山前停了下来，然后撤回到它们原本所在的地方，留下的只有死一般的寂静。$B$B海水退去了，但是它们依然在伊拉莱四周涌动，时刻准备著将它永远淹没。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3697 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3697,'zhCN','瓦加祖尔安全地躲在山后的祖尔格拉布，当他走入丛林时，他发现自己的人民已经全部被海浪卷走了。$B$B他绝望了，因为他征服的梦想已经破碎。$B$B从此之后，也没有人再看见过圣蛇米洛斯。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3698 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3698,'zhCN','帝王之墓',1);
DELETE FROM `page_text_locale` WHERE `ID`=3699 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3699,'zhCN','月光和火光，$B肉体和骨头，$B在鲜血中书写，$B在石头上雕刻。$B$B要么远离这片土地$B要么遭遇厄运$B死亡守卫著$B国王的陵墓。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3700 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3700,'zhCN','我希望这个法印成功到达了你的手中，$N。大法师通知了我说你即将到来，我马上就将讯息发送出去了。$B$B过去发生了那么多的事件，秘法法术终于回到我们一族的手上了。你可能必须面对一些试炼和困难，我的存在就是帮助你度过这些难关。当你准备好后就到奥达希尔里面找我，在二楼。$B$B- 莱安达，法师训练师',1);
DELETE FROM `page_text_locale` WHERE `ID`=3706 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3706,'zhCN','北郡山谷是个非常危险的地方，非常适合拥有生存技巧的猎人。不用说，我对于你为这个山谷的防御所付出的贡献感到印象深刻，并且很期待能见到你。请到修道院的入口来找我。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3707 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3707,'zhCN','崇高的陛下:丘加利指引了我们前进的方向:我们将让您的教堂就此在地图上消失。当暴风城的精神支柱化为城市中心一个坑洞时，恐惧会就此蔓延，而醒悟过来的民众则会涌向我们真神的怀抱。炸药已经在路上了。以神锤之名!以死亡之翼之名!为了即将到来的荣耀崭新世界!    -山缪森',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3708 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3708,'zhCN','札恩，$B$B你的首要目标是拿下吉尔尼斯城的大教堂区。我要你和克罗雷领主手下的狼人里应外合侵入敌人的领土之中。处理掉附近的吉尔尼斯哨站，切断他们的联系。$B$B乌瑞恩王向我保证，一整支由军舰组成的舰队已经在路上了，随时可能抵达。等到舰队全数抵达，我们将会对被遗忘者前线指挥营地发动全面突袭，把那些没有生存价值的蛆虫赶回银松森林。$B$B一旦确定联盟控制住吉尔尼斯，我们就会着手准备要取回罗德隆。$B$B一切都是为了联盟的荣耀!$B$B-高阶指挥官海弗德·龙祸$B$B注:当我们准备好要对被遗忘者前线指挥营地发动攻击时会发射信号弹。让你的士兵们维持在高度警戒状态。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3709 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3709,'zhCN','卡尔力斯，欧玛桑，$B$B也该是进行我们先前提过那个仪式的时候了。我将会离开斯坦索姆前往病木林中央的那座屠杀场，到那边处理一下囚犯的事情。要确保安全无虞。万一失败，你们俩的项上人头就不保了。成功了，那将会有一名矮人兄弟加入你们的行列。$B$B- 安娜丝塔丽',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3710 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3710,'zhCN','我发现一个难以置信的挖掘地点!$b$b这整片区域满是古代建筑。$b$b如果不是因为今天天色已晚，我一定会立刻着手调查!$b$b今晚我应该会兴奋地辗转难眠...',1);
DELETE FROM `page_text_locale` WHERE `ID`=3711 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3711,'zhCN','今天是收获最丰富的一天!$b$b这个房间的确是远古之源，拥有不可思议的机关结构，但看起来已经荒废已久。$b$b我明天会多做些调查。$b$b这项发现一定可以强迫舒诺兹重视我!$b$b他没理由在我发现了这个后还不让我升职吧?',1);
DELETE FROM `page_text_locale` WHERE `ID`=3712 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3712,'zhCN','我花了整天的时间在破解这些象形文字的密码:$b$b$b 透过蔚蓝之瞳可看见$b星光。$b$b  要十个裂片和一根棒子，然后迷雾$b   就会消失。$b$b$b忘了舒诺兹和他那虚假的承诺!$b$b如果我能解开这个谜团，它深藏的秘密就属于我的了!',1);
DELETE FROM `page_text_locale` WHERE `ID`=3713 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3713,'zhCN','我成功了!$b$b我利用房间装饰的蓝宝石制作出一副护目镜。有了这副护目镜，我就能看到先前看不见的东西了。$b$b真神奇!$b$b幸运的话，我下次进来的时候已经变成一个有钱新贵了!',1);
DELETE FROM `page_text_locale` WHERE `ID`=3715 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3715,'zhCN','蒂芬·艾蕾瑞安·乌瑞恩$B暴风之后$B处事公正，思绪运转的速度就跟她的笑容一样快。$B愿圣光承继您的温暖，因为失去了您，我们的世界将会变得冰冷。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3716 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3716,'zhCN','葛雷维斯，$B$B从今天开始，你的工作量将会加倍。我们的计划所包括的范围已经成长了数倍。你的考古和地理生态研究不急。$B$B你之后将必须以最快的效率往下挖，越快越好。熔渣之池的组员会在其他方位工作来将他们的隧道与你的所连接起来。格拉毕斯，黑铁矮人的地底帝国正在极速成长，而我们便是在最前线的那群人。',13329);
DELETE FROM `page_text_locale` WHERE `ID`=3717 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3717,'zhCN','成功完成这项任务你就可以获得奖励。你应该知道，这些命令不是我说的，而是由监督者玛托留斯和大公他们所下达的。$B$B挖得深的挖掘老大喧须',13329);
DELETE FROM `page_text_locale` WHERE `ID`=3718 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3718,'zhCN','希尔斯布莱德丘陵日常报告$B$B南海镇遭受攻击 - 狼人活动日益遽增$B$B根据南边的狼人活动报告，显示其活动频率渐转频繁，尤其是在南海镇周边那一带最多。我方斥候指出，近期攻击我方居民的恐怖份子为一群以伊瓦·血牙为首的叛节者。$B$B建议:派遣具有能力的英雄前往探查。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3719 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3719,'zhCN','淤泥农场的问题$B$B这个地区先前被称为希尔斯布莱德农场:如今被人称为淤泥农场，座落于希尔斯布莱德丘陵的西南方。最近在这里发生了点“意外”。根据管理员斯蒂沃特的报告指出，有可能产生传染疾病爆发蔓延的危险。$B$B建议:派遣具有能力的英雄前往该地调查。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3720 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3720,'zhCN','碧玉蜘蛛农场生产力事件$B$B我们在希尔斯布莱德西南地区的碧玉矿坑区域附近进行蜘蛛驯化行动，目前成效极度不彰。蜘蛛管理员萨鲁斯和吉顿队长要求支援。$B$B建议:派遣具有能力的英雄前往探查。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3722 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3722,'zhCN','书记官霍瑞斯·怀特斯蒂德的日记$B$B希尔斯布莱德之战',1);
DELETE FROM `page_text_locale` WHERE `ID`=3723 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3723,'zhCN','第12天$B$B我们收到消息，南海镇已经沦陷。被遗忘者的战争机器威力过于强大。我们无法抵抗他们的化学武器。$B$B虽然没啥意义，不过我会试著继续更新这本日志。我必须为了后人将这些暴行记录下来。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3724 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3724,'zhCN','第16天$B$B许多希尔斯布莱德的农夫和居民皆已逃离。有些人企图冒险东行转入阿拉希高地。他们不会成功的。还没抵达索拉丁之墙，就会全数被杀光。$B$B有许多人往北前往银松森林寻求庇护。他们就这样直接踏入敌人领地的心脏地带!真是疯了，我知道这实在是疯了，不过他们宣称狼人现在是站在我们这边。$B$B我最后听到的，是他们成功抵达芬里斯岛。在那之后，我们就和他们失去联络了。$B$B狼人?这是真的吗...',1);
DELETE FROM `page_text_locale` WHERE `ID`=3725 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3725,'zhCN','第19天$B$B我知道我们时间有限。我们尽可能撤离每一个人，不过伯恩赛德说他要和希尔斯布莱德共存亡。我们全都同意留下来和他同一阵线。$B$B留下的人有伯恩塞德镇长、居民维尔克斯、铁匠维林坦、农夫盖兹、农夫卡拉巴以及农夫雷恩，另外还有少数雇农。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3726 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3726,'zhCN','第20天$B$B希尔斯布莱德农场已不复存在。没逃的那些人都被捉起来了。被遗忘者说我们是战俘，我们会成为他们新殖民地的苦力。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3727 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3727,'zhCN','第25天$B$B他们逼我们看着自己的农田化为灰烬。明天将会开始重建。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3728 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3728,'zhCN','第40天$B$B殖民地建设几近完工。这地方看起来一点也不像是我曾见过的任何一处农田或是殖民地。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3729 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3729,'zhCN','第41天$B$B管理员斯蒂沃特今天抵达殖民地。他让我们一字排开并对我们进行药物实验。没人知道接下来会发生什么事情。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3730 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3730,'zhCN','第45天$B$B淤泥农场的苦力劳役已经开始运作。他们在恶臭水池和腐臭淤泥中种植毒菇。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3731 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3731,'zhCN','第50天$B$B管理员的宅第中传出尖叫声。开始有人失踪。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3732 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3732,'zhCN','第52天$B$B我无意中听到一些守卫在讨论农夫盖兹、农夫卡拉巴以及农夫雷恩。我相当肯定，在他们身上发生了某种恐怖的变化。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3733 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3733,'zhCN','第60天$B$B还活着的人为了我们自己的性命担心受怕。有些农夫声称他们在晚上看见食尸鬼发狂般地在外面乱跑。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3734 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3734,'zhCN','第61天$B$B事情在今天有奇怪的转变:从塔伦米尔来了一位药剂大师，从我所获得的少量情报指出，他来此是为了监督指导此地的运作。喔他叫做林度恩。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3735 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3735,'zhCN','第62天$B$B药剂大师林度恩被斯蒂沃特的卫兵拖走了。他一面尖叫一面大喊著，说什么黑暗女王会为此摘下斯蒂沃特的项上人头。我真好奇，这到底是什么意思呢?',1);
DELETE FROM `page_text_locale` WHERE `ID`=3736 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3736,'zhCN','第63天$B$B昨晚，我看到他们带走伯恩赛德和维林坦。我想我将会是下一个。$B$B<日志剩下的部分全是一些语无伦次的涂鸦字迹。>',1);
DELETE FROM `page_text_locale` WHERE `ID`=3737 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3737,'zhCN','我始终小心翼翼，不敢触碰样本，以免造成污染。这份谨慎得到了回报——初步鉴定让我相信，此物源自上古之神。任何与这件神器的接触都可能给我的生命安全带来巨大的风险。<br /><br />但愿我没有已经被污染。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3738 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3738,'zhCN','它与萨隆邪铁极为相似，却缺少几个关键特征。而且这里的地理环境完全不符。难道东部王国底下也沉睡着一个上古之神？以往的探险从未有过这样的迹象，不过话说回来，死亡之翼回归引发的灾变确实暴露出了不少隐藏的遗物。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3739 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3739,'zhCN','我正把样本送往银月城。他们有更好的设施，能保护研究者免受这类遗物散发的有害影响。<br /><br />另外，我要把这本日记藏到没人找得到的地方。要是让探险者协会拿到这些资料，后果不堪设想！',1);
DELETE FROM `page_text_locale` WHERE `ID`=3740 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3740,'zhCN','太不可思议了！这是一块上古之神的碎片！这正是我被派到这儿来的原因！我们的假设是对的！<br /><br />该喝杯啤酒庆祝庆祝。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3741 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3741,'zhCN','开始觉得头晕。有些不对劲。也许是啤酒的问题？查查看。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3742 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3742,'zhCN','不是啤酒，是那件神器。我早该想到的。我正把神器送往铁炉堡做进一步分析。<br /><br />那个圣物搜索队的加莉·光骑最近一直盯着我……我怀疑她察觉了什么。我要把这本日记藏到她绝对找不到的地方。<br /><br />现在，继续喝啤酒。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3743 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3743,'zhCN','此处长眠着 $N',13329);
DELETE FROM `page_text_locale` WHERE `ID`=3744 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3744,'zhCN','收割者原型机操作指南，第1.28.92版$B$B1. 要启动收割者原型机，仅需进入载具之中，然后按下红色按钮旁的控制解锁机制钮。不管在什么状况，千万千万别按红色按钮。$B$B2.  收割者原型机在设计上能承受数个热渣罐的热度。如要将热渣罐取下请务必以收割者进行此项工作!$B$B3.  收割者原型机主要气阀会在正常执行过程中产生蒸气动力。蒸气动力可用来启动液压电动机迅速提升速度，或是启动压力帮浦举起重物。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3745 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3745,'zhCN','赛佛路斯，奥拉基尔的手下$B$B出没于军营废墟之中。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3746 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3746,'zhCN','泰拉古拉，瑟拉赞恩的仆从$B$B走动于旧兵营外的路上。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3747 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3747,'zhCN','血毒，奈普图隆的爪牙$B$B禁锢于牢房的西侧。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3748 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3748,'zhCN','因弗努斯，拉格纳罗斯的爪牙$B$B囚禁于牢房东侧。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3749 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3749,'zhCN','D-1000$B$B在旧竞技场恭候大驾。',15595);
DELETE FROM `page_text_locale` WHERE `ID`=3750 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3750,'zhCN','这名难缠的小哥布林带著决心走向工程学商店，在接近店主时望着几样商品扬起眉毛。$B $B“最近过得怎样呀，杰克?”她那因为吸入太多摩托车废气变得低沉的迷人声音搔动著杰克那对尖耳。$B$B叫做杰克的这名哥布林抬头看了看，然后露齿微笑。“李维!比你上次来的时候好多了。”杰克把手上的弧光扳手放在桌上。“你需要什么?”',1);
DELETE FROM `page_text_locale` WHERE `ID`=3751 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3751,'zhCN','李维以一只手托住手肘，然后轻轻地拍打着自己的脸颊。“我不太清楚，你这有什么特别的玩意儿?”$B $B“你在开玩笑吧?不管在哪我都能提供最棒的商品!”杰克热心地回应道。“今天早上才刚拿到这些玩意儿，看看，各种颜色都有。小型红色烟花，当然也有蓝色和绿色的。”李维失望的神情当然逃不过这名经验老到商人的眼睛，他很快地决定提高赌注。杰克把某物放在桌上时，发出沉重的声响，“这叫做大炸弹，”他说道。“只有哥布林才做得出来，在市面上很难找到。”$B $B“好，很好，”李维以一种带著怀疑的音调说道。她的眼神略带闪烁。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3752 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3752,'zhCN','“好吧，没关系。我看得出来你这个哥布林品味极高。”杰克贼头贼脑地环顾四周，然后小心翼翼摆出一样物品，桌子因变形而发出不详的嘎吱声响。“这玩意儿叫做...”杰克停顿了一下，想要制造一种戏剧性效果，“特大炸弹!”$B $B李维因惊讶而双眼圆睁。“这...这东西...是真的吗?”$B$B感觉到自己处于上风，杰克让自己稍微放松一会儿。他把双手放在脑袋后面，背靠在椅子上，以慵懒微闭的眼神回应这个问题，“百分之百纯哥布林零件，不含其他添加物，宝贝。天然ㄟ熊赞。”$B$B犹豫了好一会儿，李维伸出双手，谨慎地抚摸著那黄色的平滑表面。“我要两个!”$B $B“很好!既然你喜欢这玩意儿那我顺便告诉你，你应该顺便带几根特坚钢管回去，这样效果更好。”$B$B李维兴奋地点著头，注视著杰克身后那面墙上的某物。“咦?那是什么?”',1);
DELETE FROM `page_text_locale` WHERE `ID`=3753 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3753,'zhCN','杰克仔细查看了下他的肩头。“喔，那些是用来复活死人用的。”$B$B这让李维感到好奇。“能用在活人身上吗?”$B$B杰克可是从来不会错过任何一桩买卖，他立刻接口答道，“喔，当然可以!你猜怎么著，如果你把这玩意儿全部买下，那这副暴行投影护目镜算你半价就好!”$B $B李维掏出一整袋金币，杰克望着那袋金币流口水。“有何不可?今年的摩托车卖得不错。”$B$B在杰克动作迅速地计算金额时，他问上一句，“是要进行什么困难的团队活动，还是怎么回事呀?”$B$B李维耸耸肩，“才不是呢，今晚有人安排我和一个叫做马库斯的家伙约会。”',1);
DELETE FROM `page_text_locale` WHERE `ID`=3754 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3754,'zhCN','杰克点点头。“要和你约会的那个摩托车俱乐部小伙子怎么了?”$B $B这名皮包骨的哥布林将她的袋子一把抓起，然后张开另一只手托住。“他从来没向人求过婚。女孩心中自有优先顺序。”$B$B杰克笑笑，在看着她走出店门时摇摇头。$B $B<没有秘密哥布林解码器无法阅读剩下的部分。>',1);
DELETE FROM `page_text_locale` WHERE `ID`=3755 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3755,'zhCN','恭喜您购买了污水专利盒中空军基地!(TM)$B$B新的空军基地设有“长气球飞艇”，最长可运作十年之久。只要设置在任何稳定的平面上即可。$B$B朋友，地平线就在您眼前:伸出双手，将蓝蓝的云朵抓在手中，张开嘴巴咬咬这片蓝天吧。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3756 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3756,'zhCN','警告:盒中空军基地并不适合于山巅顶峰布署展开。',1);
DELETE FROM `page_text_locale` WHERE `ID`=3773 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3773,'zhCN','对族人来说，牧师之道是一门新道，但它汲取了我们先知们的古老传统。在课堂上，你将学习圣光所昭示的大地母亲的智慧。到纳拉其营地中央的圆圈来见我，我们将开始你的课程。$B$B鸦羽先知',1);
DELETE FROM `page_text_locale` WHERE `ID`=3774 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (3774,'zhCN','我一直在等你到来，日行者。鹰风酋长亲自向我提起你对我们教团的兴趣，我也同意开始对你的教导。当你准备开始受训时，请到纳拉其营地中央的圆圈来见我。$B$B日行者赫拉库',1);
DELETE FROM `page_text_locale` WHERE `ID`=4330 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4330,'zhCN','<密信的大部分内容已被火焰焚毁。>$B$B……他的召唤……$B     ……法赫拉德宗师之意，吾等于明日黎明行动。召唤者焦躁不安……        刻不容缓    ……$B  ……不可放弃突袭之利……万一有变，务必引开对目标的注意……$B……但万般幸运皆归于暮光之锤……$B$B              ……行动结束之后，两队人马于拉文霍德庄园重新集结。愿你们步履如飞，利刃无声。$B$B阅后即焚。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4381 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4381,'zhCN','手记一\n\n十年来，我头一次觉得自己有了一条真正的线索。有一份以陌生语言写就的古老卷轴，提到了青春之池。它似乎比艾萨拉的统治还要古老。\n\n奇怪的是，那种语言既不属于精灵也不属于巨魔。这条惊人的消息意味着，在艾泽拉斯上曾存在过比我们自己的文明更古老的族群。\n\n据我所能解读的内容，青春之池实际上属于一个古老的王朝。构成这个王朝的种族至今仍是个谜。\n\n然而，这个''多贾尼王朝''的文字透着一股邪气。文中还提到了一处帝座和一片金花绽放的山谷。\n\n最重要的消息是，其中记载了他们王国''力量之心''的坐标。如果我能说服泰兰德批准此次任务，就应该能让我们的新奥术法师为我们开启传送门。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4382 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4382,'zhCN','手记二\n\n泰兰德是个固执任性的人！我本不该在背后议论我的大祭司，但她就是个莽夫，连最小的风险都不肯冒。\n\n我把研究拿给她看！我把如何找到青春之池和这个古老帝国遗产的方法展示给她。她做了什么？认定此行''风险太大''。\n\n我们族人的凡俗之命，怎么能被一句''风险太大''打发？哦，她还坚称，当年为了拯救艾泽拉斯而放弃不朽，是正确的选择。但我认为那是个可以弥补的问题。\n\n永生之路，从来不止一条！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4383 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4383,'zhCN','回收令$B$B奉至高尊主之命，回收者须前往多贾恩遗迹，回收一切可用于武装族人的古物。$B$B我们寻找守护者雕像、羊皮纸卷，以及一切有助于我们重拾昔日荣耀的奥术装置。$B$B优先目标是位于多贾恩北部的青春之池。池中之水对维系帝国的力量至关重要。$B$B——布罗贾伊·碎石$B$B回收领主',1);
DELETE FROM `page_text_locale` WHERE `ID`=4384 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4384,'zhCN','手记四\n\n我想我的女儿对自己被派来保护我的安全颇为恼火。莱雅莉亚是个可爱的姑娘，但她从不欣赏我的研究。\n\n可惜她这么固执。大概是随她母亲。我试着向她解释，如果我成功了，我们将拥有永恒的时光来共处。\n\n她终究还是个孩子，出生不过最近一个世纪。她似乎对我无暇顾及她而颇为委屈。可相比往后千万年的畅谈与经历，区区二十年的研究又算得了什么？',1);
DELETE FROM `page_text_locale` WHERE `ID`=4385 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4385,'zhCN','手记五\n\n奥术地牢。是谁会造出如此邪恶的装置？\n\n据我估算，这台机关已有近一万两千年的历史，却仍有足够的能量被触发。\n\n显然，一旦触发，它便开始从困于其中的一切生灵身上汲取能量，以它们的生命力驱动装置运转，就像术士吸取受害者的生命一样。\n\n大多数文明城市只用结界来阻止不受欢迎的传送门。\n而这个东西，黑暗至极。看来制造它的文明对汲取和分配生命毫无顾忌。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4415 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4415,'zhCN','——由守史者维尔德里恩译出——\n\n是至高皇帝多贾恩·火冠将军团带进了卡桑琅丛林，粉碎了那里的抵抗，将其并入帝国版图。\n\n卡桑琅是最后一个自由邦，一个盗匪与叛党藏身的丛林毒窝，妄图躲避尊驾的雷霆之怒。\n\n而真正的至宝，是传说中的青春之池。火冠年事已高，梦想着将这样的水池握于掌中便能获得的力量。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4416 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4416,'zhCN','凭借这场征服，火冠驱使新得的奴工建造了多贾恩地牢。它很快成为已知世界中最令人闻风丧胆、最负盛名的地牢。无数陷阱与兵器层层设防，向帝国昭示：火冠绝不容忍叛乱的侮辱。\n\n为确保威名，帝国魔导师们打造了大量结界与奥术地牢。任何胆敢用魔法传送门进犯帝国核心的人，都会发现自己被直接转移到某座奥术地牢中，甚至更糟。\n\n久而久之，这一地区唯一成功的传送魔法，仅限于附近的科尔贾港口。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4455 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4455,'zhCN','猢狲的语言充满着神秘色彩。尽管大多数猢狲都会说通用语，可在它们的言语间却总是夹杂着各种其它发音和“词汇”，尚未被其它种族破解。$b$b大部分锦鱼人学者认为，这些附加词汇的本义都带有暴力和攻击性，但关于这个话题的讨论还远未结束。$b$b大圣人乌克乌克曾经说过，“世事无绝对，总结需谨慎。”$b$b在我们看来，这句话真是睿智啊。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4456 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4456,'zhCN','猢狲是个短命的种族。它们当中的长者通常也不会超过二十岁。因此，相较于其它会讲话的种族，猢狲的成熟度显得不值一提。$b$b与稳重优雅的锦鱼人相反，猢狲总是充满激情，敢爱敢恨，快意人生，直抒胸臆。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4457 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4457,'zhCN','昆莱山上的猢狲异常好斗，即使以猢狲的标准来看也是如此。在这片严酷的地形中，食物和补给常常匮乏。时世艰难之际，猢狲头目们可能会对附近的定居点宣布''劫掠''。\n\n劫掠期间，每只走得了路的猢狲都会加入对附近村庄的大规模蜂拥袭击。这样一来，他们要么获得足够过冬的食物，要么损失掉足够多的弱者，以确保现有的补给够用。\n\n多年来，影踪派和牦牛人一直与猢狲维持着不安定的和平，以换取食物贡品。对影踪派的恐惧使当地部落有所收敛……通常如此。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4459 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4459,'zhCN','读吧，学生。我是朱贝卡·暗影破除者，我有责任与有能力读懂这份文件的诸位分享我们教团的部分智慧。\n\n死亡之翼陨落之后，显而易见，与艾泽拉斯面对的威胁相比，术士的法术已经大不如前。于是我们的六人术士议会齐聚一堂，商讨如何最有效地研究这些威胁所展现的新魔法。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4460 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4460,'zhCN','起初，我们六人谁也不肯配合，互相指责吵闹，就像随手甩出的暗影箭和诅咒一样。几个夜晚之后，人类卡内萨终于开口了：\n\n''大灾变之后，部落与联盟之间日益紧张的局势驱使着艾泽拉斯最伟大的英雄们厉兵秣马。战士们备好了战旗，阿彻鲁斯的死亡骑士学会了掌控亡灵，据说法师们甚至正在研究逆转时间的方法。''\n\n''笼罩艾泽拉斯的无尽黑暗已被击退。古加尔死了，暮光之锤教派的残党四散奔逃。拉格纳罗斯被打败，他的军队被赶回了火焰之地。死亡之翼粉身碎骨，他的暮光龙也灰飞烟灭。然而，他们曾经掌控的力量并未被轻易遗忘……那些力量尚待开发，唾手可得。''',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4461 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4461,'zhCN','''事实上，我们当中就有几个人曾亲身领教过它们的力量，''他一边说，一边指向房间那头一个兜帽人影。兜帽中传出一声阴沉险恶的大笑，随即兜帽燃起火焰，烧尽之后露出了兽人附魔师里茨辛。\n\n''没错，粉皮佬，火焰领主覆灭时我就在场。他那烈焰的炽烈程度，超乎你们的想象。''里茨辛眼中燃烧的火光在他烧伤的脸庞和獠牙咧开的狞笑上投下诡异的阴影。\n\n''胡说，''一声尖利的女性嗓音啐道。希菲尔，一个缀满尖利暮光源质棱刺的血精灵，狠狠瞪着桌子对面，''除非你曾在自己的头脑中做过囚徒，否则你根本不懂什么叫恐怖。''希菲尔的血液在与古加尔的战斗中被腐化，双臂至今遍布那些从皮肤下迸发的腐化留下的黑色纹路。这段经历只会让她扭曲的施虐欲愈发强烈。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4462 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4462,'zhCN','希菲尔继续说道：''就连火焰领主的烈焰，也逊于毁灭者释放的那股原始混沌。''她停顿了一下，瞥向那个始终诡异沉默的狼人。死亡之翼被消解时齐宁就在现场，而从那以后他再没说过一个字。齐宁眯起眼睛，随即冲里茨辛咆哮。\n\n卡内萨从桌边站起身，深吸一口气。''这正是我们聚在这里的原因。我不喜欢你们任何人，但我们每个人都亲眼见证过更伟大力量的一角。想一想——如果我们将火焰之地的熔火之怒与死亡之翼那不可阻挡的混沌融为一体，就算是燃烧军团的力量也无法与我们的烈焰相提并论！''',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4463 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4463,'zhCN','里茨辛把靴子翘上桌子，窃笑着：''那谁来干这事儿？你吗？''他啐道，''我看不行。自黑庙围攻战之后，就没人见过你上战场了。要不是你跟议会分享了伊利丹变形的秘密，单凭你敢召唤我这份狂妄，我就该杀了你。''\n\n卡内萨抿了抿嘴唇，随即放松下来，继续说道：''不。这项任务的规模，远非在座任何一人所能独力承担。我提议议会两两分组。里茨辛和齐宁率队进入萨弗拉斯。同样，希菲尔和泽尔法克斯去追查暮光之锤教派的残余成员，并……说服他们分享所学。''',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4464 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4464,'zhCN','满脸麻子的侏儒欣喜地鼓起掌来。\n\n卡内萨继续说：''然后我们回来……一年之后，带着各自探险的成果返回自己的派系，比单打独斗时强大得多。''\n\n里茨辛皱起眉头，他看到这个人类话语中流露的贪婪在议会众人脸上翩然起舞。''那等大功告成之后，又有什么能拦住我们在睡梦中干掉自己的搭档？''\n\n卡内萨眉头紧锁，低吼道：''所以我们要立誓：若议会中任何一人违背契约，未能返回或独自返回，其余人等必须将其击杀，永远放逐其灵魂。我们要么同生，要么独死。''',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4465 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4465,'zhCN','里茨辛是个强大的术士，单打独斗或许能击败卡内萨。但对抗我们五个？我们都看到了他的犹豫。我们都让手缓缓移向自己的卷轴和武器。\n\n''好吧，''里茨辛勉强同意，''我可以陪你玩玩这趟傻子差事，但首先我得知道，你和那个可怜的被遗忘者朱贝卡要去哪儿？''\n\n''我？''卡内萨露出一丝邪恶的狞笑，''我要回去的地方是……外域。''',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4479 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4479,'zhCN','当远方升起重重凶兆\n当战争的阴云蔽日遮天\n我们自安宁的海岸启航\n迟早必将驶向深海怒涛。$B$B昔年伟大英雄的锋利匕首\n届时将纷纷出鞘现锋芒\n而当君王陨落、晨曦垂暮之时\n火翼也将自金匣之中再度展翔。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4480 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4480,'zhCN','精魂与始祖的咒语\n曾许下多少黄金般的诺言\n它们缚结万物\n又点燃那火，将昔日的恐惧永远抹消$B$B参透这神圣的配方\n谨循我笔下的篇章\n以先祖之血结出果实\n你便能令战争的恐惧永世噤声。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4499 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4499,'zhCN','蜥蜴人原本是为魔古帝国培育的战士奴隶种族，历来残暴凶蛮。大清洗之后的数个世纪里，他们或藏匿于卡桑琅荒野的边陲，或在蛇背梁以外的危险沼泽中游荡。$B$B近几代人以来，蜥蜴人愈发胆大妄为，竟敢袭击潘达利亚沿岸的城镇，随后带着赃物遁入大海。$B$B如果你在野外遇到蜥蜴人，切勿以为他是孤身一人，应立即采取行动自保。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4500 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4500,'zhCN','蜥蜴人原本被派往魔古帝国的边远地带维持当地的秩序。在其魔古主子自我意识的推动下，蜥蜴人那唯我独尊与憎恨弱小的天性显得更加变本加厉。$B$B很快，蜥蜴人守卫便开始对那些他们本该监管的民众下手，大肆掠夺。他们变得越来越悖逆狂傲，每当懒于应付累人的战事时，就明目张胆地违抗自己的魔古指挥官。$B$B皇帝都阳用魔古族的传统方式作出了回应——将锦绣谷里所有活着的蜥蜴人灵魂剥离，此外，他还对仍在战场上作战的军团下达了同样的命令。于是大净化便开始了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4501 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4501,'zhCN','当魔古族宣布净化蜥蜴人时，一些军团士兵仍在战场上作战。主人的邪恶计划传到了这些蜥蜴人耳中，于是他们在螳螂妖的地盘上临阵倒戈，消失在了敌方战线之后。许多魔古族军团和奴隶被派去追击和消灭这些叛徒。但却都是有去无回。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4502 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4502,'zhCN','不可一世的蜥蜴人在卡桑琅的沼泽中坚守阵地，对抗魔古族。他们正是在这里觅到了一线战机，将帝国军队引到了这片陌生的疆域。$b$b叛徒们在水里下毒，破坏建筑，害得魔古族死亡人数迅速攀升。$b$b怒不可遏的皇帝都阳继续将军队、奴隶和大量武器输送到卡桑琅，不除掉蜥蜴人残余力量誓不罢休。$b$b可他们从没成功过。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4503 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4503,'zhCN','亡者在魔古族眼中只不过是肢块脏器的整合体。魔古族将亡者的灵魂束缚进石头里，以作它用；将血肉重铸，以为那些效忠皇帝的忠臣良民延长生命。能以全尸下葬，是无上权力与尊荣的象征。$b$b这里是皇帝谷，历代在这片土地上叱咤风云的军阀、国王和皇帝都长眠于此。$b$b若敢盗墓，后果自负！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4504 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4504,'zhCN','即便是按照魔古族的标准看来，皇帝都阳二世也仍然显得十分矮小凶残。他对父亲未竟事业的疯狂追逐，对完成蜥蜴人叛军大净化的执着追求，令他踏上了御驾亲征的不归路，任由自己的统治变得风雨飘摇。$b$b当他站在高耸的悬崖边俯视卡桑琅荒原时，他看见了轮廓鲜明的丛林，业已建成的都阳地下城，还有渐渐覆亡的蜥蜴人。$b$b但令他始料未及的是，蜥蜴人第五和第七军团的残余兵力竟在夜深人静之时从四风谷出发，包围了悬崖，伏击了他的御用帐篷，逼得他纵身跳下了悬崖。没人找到过他的尸体，内廷混乱致使帝国在接下来两年多的时间里变得乌烟瘴气，而蜥蜴人则退回野外，消失得杳无踪迹……',1);
DELETE FROM `page_text_locale` WHERE `ID`=4505 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4505,'zhCN','多年以来，魔古族都将血肉当成武器——任由他们依照自己的邪恶意志扭曲驾驭。可在蜥蜴人这个败笔出现之后，魔古族便试图创造其它武器……这一次，必须要绝对的服从。$b$b他们从古代研究成果中找到了将血肉变成石头，并将其还原的方法。如果能将自愿（或非自愿）的灵魂囚于其中，那么毫无生命力的石头就能焕发生气。$b$b这些黑暗的仪式催生了石生人——通过黑暗魔法将受害者的元神铸入玉石而形成的士兵。这些造物无比强大，外形骇人，且最为重要的是，对自己的魔古主子绝对忠诚。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4506 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4506,'zhCN','据书中记载，当伟大的雷神第一次将视线投向螳螂妖的土地时，他并没有感到恐惧，反而是受到了鼓舞。$b$b他开始将自己的民众集结在一面战旗之下，奋起征服潘达利亚的其它种族，他知道，螳螂妖永远不会臣服于他的霸权。潘达利亚的住民们说着他的语言——力量的语言。他指挥奴隶建造了蟠龙脊——一道将他整个帝国都围守在内的宏伟长城。$b$b这需要无数代人的努力才能建成，但雷神知道该如何激励自己的臣民。恐惧。对螳螂妖的恐惧足以让他们搬移高山，集结军队，戍卫帝国，建造长城。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4507 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4507,'zhCN','与熊猫人和魔古族的火锻和热锻技术不同，锦鱼人掌握着水锻的独门绝技。他们凭借水压与水流的冲击力，改变石头与金属的形状。$b$b他们最初在河里寻找圆滑的石头和其它材料，后来则具备了独到的眼光，能找到出产最优质原料与坚石的处所。$b$b随着时间的推移，他们已经学会用法术操纵流水，用石料建造出无与伦比的高楼大厦。他们的武器与护甲，与任何火锻钢铁相比都毫不逊色，他们的墙体则通常都是无缝建造而成。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4508 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4508,'zhCN','相传在大分裂以前，江河百川都汇聚到潘达利亚。没人能比聪明的锦鱼人更清楚这一点了。随着时间的推移，锦鱼人中最为睿智的长者学会了与河水交流，聆听未来和它所要传达的消息。这些长者深受大多数种族尊敬，为自己赢得了“水语者”的头衔。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4509 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4509,'zhCN','这个早期的锦鱼人圣坛也许能让我们对这个种族的起源有所了解。上面绘有各种蜷曲的水生原始生物。它们环绕着金色田野上的一汪汪水池——也许代表的是锦绣谷。$b$b有个原始生物在水边高举法杖，可刻在他脑袋周围的符号用的是一种比魔古王朝更古老的未知语言。$b$b这些早期水生生物与锦绣谷之间的确切关系至今尚不得而知。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4510 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4510,'zhCN','锦鱼人奉行严酷的社会等级制度，从这个刻满名字的石板上就可见一斑。当锦鱼人还是鱼卵时，就要根据社会需要而分阶列位。$b$b许多锦鱼人被安排当工人，勤恳地建造堤坝或其它建筑。还有一些锦鱼人会成为工匠，并在孵化期就要接受严格的学徒训练。$b$b只有战士和祭司才能得到最多的食物，住进最好的居所，而只有最成功的祭司才能晋升到长者或水语者的身份。锦鱼人禁止不同身份阶层的人相互结交混居。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4514 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4514,'zhCN','双料偏淡与醇黑两种麦酒的鼻祖，''平衡醉意之道''的开创者。$B$B为了在不减损啤酒美德的前提下减轻其负面影响，郭拳头开创了一套两部分饮酒法，旨在达到平衡醉意的状态。若按照适当的比例分别饮用''精神淡啤''与''心智黑啤''，二者便会在饮者胃中结合，带来启迪与善意，又不至于像寻常豪饮那样失去判断力与自制力。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4515 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4515,'zhCN','虽然部分较为温驯的森林猢狲已选择融入熊猫人文化，但究其本性，他们仍是一个受激情驱使的淳朴种族。他们热爱打猎与捕鱼，常常袭击踏入其狩猎场的人和一切东西。这种局面令人头疼，因为猢狲的狩猎场少有固定的边界或标识。所幸，大多数猢狲通常都会被熊猫人武僧看管约束。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4516 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4516,'zhCN','每隔一百年，螳螂妖便会大量孵化幼虫。虫群大军照例向东推进，吞噬沿途见到的一切，直到抵达蟠龙脊。在那里，会有成千上万只螳螂妖被熊猫人杀死，就如同它们当年被修建长城的魔古族大肆屠杀一样。$b$b熊猫人学者试着破解这一轮回，可至今仍然意见不一。螳螂妖为什么会眼睁睁地看着自己如此多的幼子惨遭屠戮，一代又一代地往复不绝？答案只有螳螂妖知道。$b$b由于这个轮回太好预测，所以长城的守卫者们每个世纪都会做好准备。影踪派，还有此前的魔古族，都知道虫群到来的时间，据此制定相应的防守计划。只要长城屹立不倒，潘达利亚就有希望对抗那看似无穷无尽的螳螂妖大军。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4517 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4517,'zhCN','亲身经历螳螂妖对蟠龙脊的攻击，是极为可怕的体验。对守兵和螳螂妖来说皆是如此。只有最聪明、最强壮或者最机敏的螳螂妖才能活过这一劫，熊猫人守卫也同样会死伤无数。$b$b螳螂妖幸存者通常会带着战利品回到大树上。在那里，螳螂妖社会将热烈欢迎它们的回归，这些凯旋者会根据功绩在族人中占得自己的席位。$b$b这个仪式的意图我们不得而知，但那些想要翻越长城的旅行者都会事先得到警告——你在长城另一侧遇见的螳螂妖都是久经考验的老兵，要心怀畏惧，切莫轻敌。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4518 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4518,'zhCN','琥珀是螳螂妖社会的基石。他们将这种材料用于建筑、艺术和科技。\n\n螳螂妖是声音的大师，很久以前便找到了利用琥珀扩展音波施法范围的方法。如此一来，他们便能进行远距离交流。没有任何军队能在螳螂妖的土地上不被察觉地行进，就连孤身的旅者也被劝诫小心行事——因为他们一旦踏出城墙，动向必然处于监视之下。\n\n女皇与她的卡拉克西议会守护着螳螂琥珀唯一的来源——螳螂高原上的巨树''卡帕里树''。传说卡帕里树曾在城墙以东繁茂生长，但在魔古与螳螂虫群无休止的战争中，被魔古尽数砍伐。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4519 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4519,'zhCN','螳螂妖女皇在潘达利亚各地都是令人闻风丧胆的狠角色。近乎无穷的螳螂妖宿体都是自她而生。$b$b尽管螳螂妖女皇都很长寿，可也并非永生不灭。卡拉克西是由螳螂妖长者组成的著名议会，负责确保王权交接的有序进行。交接的确切性质极其隐秘，但似乎涉及战斗对决。上一任女皇的遗骸会被喂给继任者。基于这个原因，一条从未中断的权力线贯穿了螳螂妖文化的整个历史。$b$b虽然人数不多，可卡拉克西显然在塑造和保护螳螂妖文化方面起着关键作用。但不知他们是否有权直接撤销女皇的旨意。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4520 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4520,'zhCN','在魔古王朝统治的黑暗时期，熊猫人奴隶不得持有任何武器。在进行秘密训练时，熊猫人武僧常常用农具或简单的竹杖来加以练习。同时强化徒手攻击。$b$b相反，深受魔古族青睐的武器多是威慑力大于实用性——硕大笨重，难于挥持。熊猫人武僧反倒占得先机，练就了快速出击和在战场上疾行移动的轻盈身手。体型庞大、动作缓慢的魔古族总是会在野外战斗中被熊猫人武僧的速度搞得晕头转向。$b$b多年以来，熊猫人的作战风格发生了翻天覆地的变化，融合了各类技能、武器、招式等等。但其战斗技法的核心基础从未被动摇——当情势所迫时，赤裸双爪击败体型无论多么巨大的对手。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4521 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4521,'zhCN','即便是按照魔古族的标准来看，皇帝牢非都是个不折不扣的怪物。他惩治熊猫人奴隶的拿手好戏便是拆散家庭。那些冒犯他的奴隶，他们的孩子会被牢非送往蟠龙脊，成为供螳螂妖虫群折磨和享用的美餐。$b$b一位名叫康的熊猫人武僧也遭受了同样的厄运。康因痛失幼子而悲伤不已，身穿一袭黑衣来表达心中哀苦。但在某个瞬间，他突然清醒的认识到，魔古族的君主只不过是外强中干的纸老虎罢了。尽管他们掌握着黑暗魔法和可怖的武器，但他们的帝国却是完全依赖奴隶的劳作而存在的。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4522 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4522,'zhCN','仆役们在魔古族的统治下不得携带任何武器，于是康决定把熊猫人自身打造成武器。就这样，熊猫人武僧开始学习武术功夫，康则赢得了曙光之拳的称号。$b$b在历史书中并没有提及康和他的儿子后来是否重逢了，但正是这位父亲的爱子之情令奴隶们揭竿而起，永远地改变了潘达利亚的格局。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4524 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4524,'zhCN','在魔古王朝的统治期间，奴隶是帝国的命脉。熊猫人、猢狲和锦鱼人终日辛勤地为主人耕地、挖矿、建造强大的堡垒。$b$b为了对抗疲劳、鼓舞士气，也为了能让伤者尽快回到工作岗位上来，魔古族允许某个熊猫人奴隶阶级专攻药剂的研制。他们原本只会制作简单的茶饮和药膏，随着时间的推移，这些专家渐渐成为了治疗者、团队领袖和酿造大师。$b$b一种高尚的传统诞生了，而这些早期的“武僧”在熊猫人当中变成了希望与荣耀的象征。$b$b正是这些英雄们，最先学会了如何赤手空拳抗敌作战。武僧们暗地里向其他奴隶传授武功秘法。当叛乱爆发时，武僧们身先士卒加入战斗，引得那些恭顺的农夫、铁匠和泥瓦匠纷纷效仿……',1);
DELETE FROM `page_text_locale` WHERE `ID`=4526 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4526,'zhCN','魔古帝国的实力不在于人数众多，而在于以恐惧慑人。他们利用恐惧控制着广大奴隶城市，将旧帝国牢牢控制在自己的股掌之中。$b$b尽管最先是熊猫人起身反抗魔古族的，但他们并非孤军奋战。猢狲的凶残、锦鱼人的智慧很快就令反叛者如虎添翼，而土地精也充当起了传递消息的信使，多方齐力隔断了魔古族奴隶主运送粮食和传送消息的渠道。$b$b皇家军队饥饿不堪，重大消息也无法传递，整个帝国的根基都已分崩离析。魔古族根本不懂该如何种植粮食和为军队输送物资。整个军队都呆坐在兵营里，对反叛军改朝换代的行动闭目塞听，直到一切已成定局。$b$b从本质上说，奋起反抗的正是缔造帝国实力的本源力量。潘达利亚的各个种族是为了同一个目标而团结在一起的，他们发现，原来自己才是强者。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4528 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4528,'zhCN','从熊猫人末代皇帝当政时期开始，野牛人就被迫生活在螳螂高原的荒芜地带，并相应调整了自己的应对策略。$b$b这是个居无定所的种族，在自然资源（尤其是油和猎物）丰富的地带建起临时的“火营”，一段时间过后再继续前进。至于在哪里扎营、停留多久以及何时离开，都由酋长全权决定。$b$b在战斗中，野牛人下手又快又狠，侧重于派遣骑兵从两翼滋扰敌人，同时命精锐善战的步兵突袭敌方阵线的薄弱环节，再用火系法术和烈焰攻城武器在后方支援。$b$b野牛人撤退和出击的速度一样快，总能洞察敌人心中所想，只在有必胜的把握时才会全军压上。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4530 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4530,'zhCN','只有最为强壮、勇敢和坚韧的野牛人才能成为部族的首领。这些是野牛人社会中最受推崇的优秀品质，也是所有野牛人领袖都应该具备的。$b$b然而，随着螳螂妖在南方屡屡发难，野牛人不愿因内部权力斗争而折损任何一名战士。$b$b在这种情况下，一种文明得出奇的解决方式应运而生了。当在两个野牛人之间爆发冲突时，会在他们当中竖起一面战旗。然后让他们使用钝器对决，直到一方认输或昏倒为止。$b$b类似的，新领袖也是通过仪式战斗选出——希望继承酋长之位的野牛人，必须将他家族的战旗插在地上，与任何挑战他权威的人一决胜负。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4532 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4532,'zhCN','燃油是野牛人的主要作战手段。在精英战士叱咤战场的辉煌时期，这种武器甚至比魔法更具有致命的杀伤力。这种熊熊燃烧的物质会令敌人遍体鳞伤，大地焦痕斑斑，将敌人用作掩护之用的树木焚毁殆尽，就连可怕的螳螂妖入侵都能化解。$b$b野牛人还有个惯用伎俩，就是在夜晚点起比实际人数更多的篝火，以此混淆视听，让隐匿在黑暗中的敌方探子误以为野牛人大军压境，而他们的真实位置与人数则无人知晓。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4535 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4535,'zhCN','野牛人的起源并不明确。关于这一种族的最早历史记载，可追溯到无情战王齐昂的统治时期。他的学者将这个游牧部族描述为“有智慧的牛科猎手”，在“帝国西部以外的广阔区域”游荡狩猎。$b$b人们认为，有几个部族是在大分裂发生时，被困在了潘达利亚，与主大陆隔绝开来。$b$b身处危险的螳螂高原，坚强的野牛人只得努力适应，把当地盛产的火油做成武器，创造出了自己特有的攻击方式。$b$b几乎没有哪个种族能够跟螳螂妖在开阔地带近距离对决。单凭这个理由，野牛人幸存者就足以令人畏惧敬重。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4537 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4537,'zhCN','早在一万年前，潘达利亚的末代皇帝少昊正是在这里，击败了疑之煞，将其囚禁在这片土地上。$b$b在《少昊的七罪责》的第五章中写道：$b$b“少昊冥思苦想了三天三夜，可青龙的忠告还是令他一头雾水。一个人要如何荡除心中所有的怀疑？”$b$b“少昊的旅行同伴美猴王等得实在无聊，就拿竹子刻出了一个诡异的鬼脸面具。他让皇帝把这个疑之面具戴在脸上……”$b$b虽然美猴王的本意只是恶作剧，但面具却生效了——少昊把面具拽下来，他的怀疑化成了实体。他们大战了七个小时，直到疑之煞被彻底掩埋。$b$b从那天起，末代皇帝心中再无怀疑，他相信自己一定能将潘达利亚从大分裂中拯救出来。他变成了信念的化身。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4542 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4542,'zhCN','单一感官酒品与四德酒之父。$b$b盲眼酒中仙云壬由于双目失明，其它感器变得尤为敏锐，已经对熊猫人酿制的中庸酒品苦苦忍受多年了。$b$b经过长年的游历与试验，他终于研制出了能令他的四种感官分别感到满意的酒品，尽管他将这几种酒品酿造得尽善尽美，但还是不知该如何将它们混制成为一种完美佳酿。$b$b他穷尽余生继续游历，最后终于找到了将这几种美酒融为一体的顶级秘方，制成了四德酒。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4543 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4543,'zhCN','早在一万年前，潘达利亚的末代皇帝少昊正是在这里寻求青龙的教诲。$b$b在《少昊的七罪责》的第三章中写道：$b$b“茫然无措、杳无希望的末代皇帝，沿着陡峭的山坡爬上了不息山。刺骨严寒穿透了他的丝质长袍，凛凛冷风在他耳边讥笑嘲讽。”$b$b“惟有在山顶上，皇帝才寻获了安宁与慰藉，他在这里与智慧之灵青龙交谈。”$b$b青龙劝少昊卸下负累，净化灵魂，与大地化为一体。$b$b皇帝不解其意，可继续留在这苦寒的山顶也不会找到更多答案。皇帝少昊心灰意冷的缓步下山，打算与同伴美猴王商量下一步行动。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4546 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4546,'zhCN','早在一万年前，潘达利亚的末代皇帝少昊正是在这里，用这些圣水的力量帮助潘达利亚在灭世的大分裂中幸免于难。$b$b在《少昊的七罪责》的结语中写道：$b$b“最终一日，黄昏时分，天空中绿焰滚滚，大地恐惧震颤。但皇帝没有畏惧。在他心中毫无怀疑和绝望。当天空崩裂时，他大快朵颐，高声歌唱。”$b$b“皇帝少昊在自己臣民的眼中看到了恐惧与怀疑，于是他发出了宣言——人生苦短，每一日都该开怀活在当下，每一晚都该忘忧舒心安眠。”',1);
DELETE FROM `page_text_locale` WHERE `ID`=4547 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4547,'zhCN','传说中，他登上了永春台，想要将潘达利亚与世界其余部分分离。但他竭尽全力，却未能成功——大地颤抖，却纹丝未动。很快，他开始怀疑，疑之煞开始在东方浮现。他开始恐惧，惧之煞也开始在西边挣脱束缚。绝望之下，他向玉珑求助。\n\n玉珑环绕皇帝谷盘旋，对陷入困境的皇帝说道：''潘达利亚不仅仅是熊猫人帝国，少昊。西边的敌人也是这片土地的一部分，正如墙后你帝国的疆土一样。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4548 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4548,'zhCN','当少昊领悟到万物相连、浑然一体，他挚爱的土地并不仅仅是熊猫人帝国时，他终于明白了。他的法杖当啷落地，灵魂与大地融为一体。当世界分崩离析之时，潘达利亚悄然漂入大海。随着皇帝的袍服飘然坠地，这片土地被不可穿越的迷雾笼罩，从世界其余部分中隐去。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4549 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4549,'zhCN','早在一万年前，潘达利亚的末代皇帝少昊正是在这里，击败了惧之煞，将其囚禁在这片土地上。$b$b在《少昊的七罪责》的第十四章中写道：$b$b“虽已荡除内心的怀疑与绝望，但在皇帝少昊心中仍有挥之不去的恐惧。他向勇敢刚毅之灵——玄牛寻求帮助，玄牛居住在长城另一侧的荒原之上。”$b$b“玄牛、朱鹤、皇帝和美猴王长篇大论地探讨了恐惧的本质，最后美猴王终于受到启发，作出了行动。他制成了恐惧面具，外形可怕至极。皇帝用颤抖的双手戴上面具，将自己的恐惧逐出……”$b$b对抗惧之煞的战斗持续了一个星期零一天，相传，在那期间就连太阳都未曾升起。煞魔最后终于落败，被囚禁于大地之中，皇帝少昊也不再是从前的自己，因为在他心中已经没有恐惧。他变成了勇气的化身。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4552 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4552,'zhCN','早在一万年前，就在少昊登基成为潘达利亚皇帝的那一天，他遵照历代先皇的传统，去找伟大的锦鱼人水语者寻求指引。年轻的皇帝兴致冲冲地来到先知面前，猜想等待他的一定是好消息。$b$b水语者倾听着伟大河流奔涌的旋律，但他突然惊恐地睁大了双眼。$b$b在《少昊的七罪责》的第一章中写道：$b$b“水语者看见了一群巫师围在一口巨井周围，从井里召唤成群的恶魔。绿色的烈焰从天而降，世界所有的大陆板块都悉数分崩解体。”$b$b皇帝少昊被这可怕的景象吓坏了，意识到自己这一生注定无法安享荣华。以晨芳园这个小镇为起点，他踏上了拯救潘达利亚的旅程。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4556 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4556,'zhCN','早在一万年前，潘达利亚的末代皇帝少昊正是在这里，击败了惘之煞，将其囚禁在这片土地里。$b$b在《少昊的七罪责》的第九章中写道：$b$b“在翡翠林中取得成功之后，皇帝少昊周身充满勇气，但他仍对不可预知的未来担忧不已。他深入卡桑琅丛林，寻求希望之灵朱鹤的教诲。”$b$b“朱鹤告诉皇帝，只要审视内心深处，每个人心中都存着希望。于是，美猴王给了皇帝少昊一个绝望面具——刻有骇人悲伤的绝望面容。皇帝戴上了面具，将自己心中的绝望赶了出来……”$b$b与疑之煞的战斗在瓢泼大雨中持续了四天五夜，可在朱鹤与美猴王的帮助下，少昊所有的绝望都被消除了。$B$B从那天起，皇帝终于明白，前途充满光明。他成了希望的化身。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4557 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4557,'zhCN','早在一万年前，潘达利亚的末代皇帝少昊正是在这里，击败了怒之煞、恨之煞和狂之煞。$b$b在《少昊的七罪责》的第十九章中写道：$b$b“自信又无惧的皇帝少昊以为没什么能够阻止他。但在朱鹤的要求下，他还是前去寻求力量之灵——白虎的忠告。”$b$b“白虎在少昊身上发现了无畏者常有的弱点——鲁莽。他将潘达利亚最伟大的战士集结起来，想试试这位皇帝。”$b$b“白虎给了皇帝少昊一根十英尺长的的棍子，只要他能击中任何一名战士就算赢。尽管大战了好几个小时，可从未受过训练的皇帝在战士们快速敏捷的身手面前却只能望洋兴叹。他变得怒不可遏，暴跳咒骂，最后把长棍摔在膝盖上折成了两段。“',1);
DELETE FROM `page_text_locale` WHERE `ID`=4558 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4558,'zhCN','锐气尽失的皇帝向白虎请教如何才能变得更强，明白原来是被自己的冲动拖住了后腿。为了拯救潘达利亚，少昊必须击败心中的愤怒、仇恨与暴力。$b$B美猴王立即动手，刻出了三张面具。皇帝轮流将它们戴在脸上，在一众好友与潘达利亚最伟大战士们的帮助下，终于打败了怒之煞、恨之煞和狂之煞，将其深埋于地下。$b$b皇帝再也不是从前的自己了，他踏上了最后一段旅程，成为了坚忍、爱心与平静的化身。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4559 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4559,'zhCN','影踪派是在一万年前，由潘达利亚的末代皇帝少昊亲自下令立派的。$b$b皇帝少昊深知，如果任由邪煞——诸如怒、惧、恨、疑等负面情绪的实体在地下恣意滋长其黑暗能量，必会对熊猫人造成巨大威胁。他要求潘达利亚最伟大的战士们勇挑重担，负责约束和控制邪煞。$b$b正是在这个地方，仅在皇帝少昊击败自身的愤怒、仇恨和暴力的数小时之后，影踪派的第一代弟子屈膝向皇帝立下了誓言。在过去的一万年间，同样的言辞在每一代影踪派新兵间口口相传。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4560 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4560,'zhCN','大名鼎鼎的熊猫人探险家刘浪就是在这里——石犁村的一个小农场上出生长大的。$b$b尽管他应该帮忙照看家里的农田，刘浪却总喜欢爬到南边的悬崖上，眺望那一望无际的海面。“我想看看外面的世界。”当面对同伴的嘲笑时（人们普遍以为世界已经在大分裂中遭到了毁灭），他说出了这句名言。$b$b刘浪四处打听购船的事，可当地的垂钓翁却告诉他，没有任何船只能在迷雾里安然返航。$b$b过了没多久，他便宣布，自己将骑在一只海龟的背上探索世界，因为海龟总能返回出生的海滩。$b$b后来，当地人开始怀疑，刘浪也许是吃了太多变质芜菁，把脑袋给吃坏了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4561 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4561,'zhCN','在多个世代以前，神真的杂货店就开在这里，他是深受当地农夫喜爱的杂货商。有一天，首位熊猫人探险家刘浪拿着一张不同寻常的购物清单走了进来，上面的文字流传至今：$b$b     一个灯笼$b     三升灯油$b     四包干果$b     两袋干豌豆$b     四条咸肉$b     十二升饮用水$b     一罐压缩饼干$b     一个罗盘$b     一个望远镜$b$b刘浪宣布了自己探索世界的计划。神真为了让顾客遂心如愿，就建议刘浪应该随身带上伞，还慷慨地免费赠送了一把。$b$b刘浪欣喜地向神真道谢：“我将用你的名字命名我的海龟！”他开心地将杂货打包装好，吹着口哨向岸边走去，身后跟着无数好奇的围观者。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4562 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4562,'zhCN','在多个世代以前，探险家刘浪每隔五年就会骑在海龟的背上返回潘达利亚，每次回来都会带走越来越多的探险者。当地人给海龟起名叫做“迷踪岛”，因为这只海龟长得无比巨大，甚至在龟背上建起了一座小镇和一间庙宇。$b$b有一年，当地的寡妇梅布·风暴烈酒因丈夫在踩葡萄时意外丧命而悲伤不已。她宣布自己对潘达利亚已无半点留恋，于是带着幼子廖·风暴烈酒登上了龟背，成为第一个上岛的酒仙。$b$b迷踪岛已经有很久没有返回潘达利亚了。也许是海龟神真子在痛失挚友刘浪之后，便不再返回大陆。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4563 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4563,'zhCN','在多个世代以前，年轻的熊猫人探险家刘浪就是在这里，几乎只带了一把伞和满满一包食物，骑着海龟踏上了探索世界的旅途。$b$b当时人们普遍认为，世界已经在大分裂中遭到了毁灭。那些所谓明眼人还说刘浪是……脑袋“出了问题”。$b$b当刘浪于五年后安然返回，滔滔不绝地描述大洋彼岸的神秘疆域时，所有人都不禁大跌眼镜。他在余生中每隔五年就会返回潘达利亚一次，每次回来，海龟都变得越来越大，后来竟大到足以容下整个村镇。$b$b那些憧憬探险的熊猫人总是望眼欲穿地等待着他的归返。直到今天，当有人出于某种原因凝视海平线时，仍会有人问他们是否在“等待海龟”。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4564 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4564,'zhCN','鉴于蜥蜴人军团已经成为了不服管教的失败作品，魔古族便开始想其它办法来创造“完美”的战斗部队。通过使用来历不明的黑暗魔法，他们将生者的灵魂囚禁在石人里。$b$b经过数代更迭，一支由“陶俑战士”组成的浩荡军队终于建成，被封存在昆莱山深处的庞大地宫之内。$b$b熊猫人武僧深知这种秘密武器会给自己招致灾难，于是便在起义开始后立即开始了夺取地宫的行动。他们迅速出击，从晴日峰上垂索而降，打得魔古族猝不及防。地宫之战持续了整整四天，最后一场暴风雪迫使魔古族撤离了山区。$b$b奋起反抗的奴隶们夺取了秘密武器，逼得魔古族只得用更为常规的手段应对战事。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4565 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4565,'zhCN','''心潮佳酿''之父。$B$B心潮佳酿能为饮者周身注入深沉的暖意与幸福感。据说辛沃银如此钟爱自己酿出的琼浆，以至于每有一桶酒离开他的酿酒坊，他都要洒下悲痛的泪水。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4574 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4574,'zhCN','这部法典以第一帝国的统一语言写成，被精心镌刻在石板上。法典之首的命令便是：凡叛乱、谋反与暴动者，一律处以公开剖腹之刑。$b$b此展品由尊贵的 $c，$n 捐赠。',0);
DELETE FROM `page_text_locale` WHERE `ID`=4581 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4581,'zhCN','熊猫人有着悠久的茶文化。人们对泡茶之道讲究备至，而正确品茶的秘诀同样历来受到重视。这套简朴的茶具制成于魔古统治时期，在痛苦与暴政肆虐的年代为它的主人带来了慰藉与安宁。虽然它已斑驳破碎，却提醒着我们要从生活的简朴乐趣中汲取慰藉。$b$b此展品由尊贵的 $c，$n 捐赠。',0);
DELETE FROM `page_text_locale` WHERE `ID`=4582 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4582,'zhCN','熊猫人热爱游戏。自熊猫人第一代皇帝的时代起，这种棋戏便一直深受喜爱。这是一套保存完好的古代棋具。$b$b此展品由尊贵的 $c，$n 捐赠。',0);
DELETE FROM `page_text_locale` WHERE `ID`=4583 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4583,'zhCN','一套乌木与翡翠制成的对杯。酿酒宗师郭拳头，人称''双拳''，试图通过创造完美的双酒组合来减轻烈酒的副作用。当按照适当的比例一同饮下时，''精神淡啤''与''心智黑啤''便会在饮者胃中结合，带来启迪与善意，而不像较为粗劣的酿品那样令人失去判断力与自制力。可惜酿酒宗师的秘方已经失传，但这套精工细作的对杯将成为他精湛技艺的永久见证。$b$b此展品由尊贵的 $c，$n 捐赠。',0);
DELETE FROM `page_text_locale` WHERE `ID`=4587 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4587,'zhCN','此类雕像在人挚爱之人去世时委托制作，帮助生者走出失去亲人的悲痛。这座雕像描绘了一位名叫林的美貌年轻熊猫人游学者。铭文显示，在猢狲皇帝里克提克短暂的统治期间，她死于一场席卷四风谷的可怕热病。$b$b此展品由尊贵的 $c，$n 捐赠。',0);
DELETE FROM `page_text_locale` WHERE `ID`=4588 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4588,'zhCN','一整套黄铜药剂罐，贴着整洁的刻字标签，用于存放种类繁多、药力强劲的草药。尽管大多数草药的确切用途至今仍是谜团，但收纳罐子的盒子上有一块铭牌，注明医者名为姚坚掌——凭借辉煌的医学生涯，这个名字至今仍与健康安康联系在一起。姚终生未娶——传说是因为他的心早已破碎。$b$b此展品由尊贵的 $c，$n 捐赠。',0);
DELETE FROM `page_text_locale` WHERE `ID`=4601 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4601,'zhCN','相传刘浪曾经骑在一只巨龟背上，去探索潘达利亚之外的广阔海域。他每隔几年会回来一次，并邀请新的探险家与他同行。直到今天，每当有熊猫人做白日梦或者呆望天空的时候，我们便会问他们是不是在“等待海龟”。$b$b大部分熊猫人并不爱冒险。他们喜欢温暖舒适的居家生活。但我们中仍然有一些梦想家……今晚我们将聚集在南部海岸的海龟沙滩眺望大海，纪念刘浪的冒险精神。$b$b这就是“云游节”。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4602 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4602,'zhCN','''晚安，神真。不要悲伤，老朋友。我睡去了，而当我醒来之时，下一段伟大的旅程就将开始。''——刘浪$B$B     此处是刘浪——第一位熊猫人探险家的长眠之所。一生游历令他疲惫不堪，他在自己信赖的竹伞下歇息，悄然沉入彼岸的梦乡。$B$B     传说，此处生长的这棵奇树正是从那把伞中发芽，而他的灵魂已与神真背上的大地融为一体。$B$B     在之后的世代里，岛上的许多长者步其后尘，各自把手杖插进土里，形成了这片''杖林''。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4603 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4603,'zhCN','以素来嗜血的魔古王朝的标准来看，皇帝曹的统治时间短暂且乏善可陈，主要因行政重组而留名。\n\n然而，他确实给熊猫人留下了一份持久的遗产。通过皇帝敕令，熊猫人奴隶获准读书、写字并建立自己的学校。\n\n革命之后，许多魔古纪念碑被拆除，但皇帝曹的雕像仍屹立于海岸，每天清晨迎接朝阳，守望他曾帮助拯救的子民。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4604 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4604,'zhCN','许多代人以前，一位影踪派将军站在蟠龙脊上，等待螳螂虫群的到来。一只年轻的牦牛人前来交付最后一批补给，问将军是否认为此战会顺利。\n\n''若幸运眷顾，我们必能取胜。''将军一边回答，一边扫视地平线。\n\n他说起了牦牛人最熟悉不过的话题。''幸运是个善变的东西！您怎么知道它会眷顾您？''牦牛人问道。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4605 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4605,'zhCN','''纪律并非一场可获胜的战争。它是一场永不停歇的战斗。''——冯大师。\n\n土水之道是一种恪守原则的生活之道。其信奉者坚信世间存在明确的道德准绳：一条路是正道，另一条是邪途。\n\n这些价值观亘古不变，必须坚守，哪怕代价是自我牺牲，或在追求理想的过程中承受痛苦的损失。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4606 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4606,'zhCN','从前，一个年轻的农场雇工不幸与一位老僧人同住客栈一间客房。老僧人从暮色四合一直谈到晨光初现，喋喋不休地大谈哲学与科学。雇工听腻了这场单方面的谈话，老僧人很快便提出要比试智慧。\n\n无论室友把赌注抬到多高，雇工都无意与僧人比试头脑。最后，僧人开出了优厚的赔率：''你每问倒我一个问题，我给你50枚金币；而你每答不上我一个问题，就给我5枚金币。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4607 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4607,'zhCN','牦牛人被将军的自信与好运打动了。''您可是在拿麾下将士的士气作赌注啊！''他说，''您怎么能这么肯定？''\n\n将军微微一笑，从口袋里掏出那枚金币，递给牦牛人查看。两面都是正面。''依我的经验，运气都是自己挣来的。''他答道。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4608 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4608,'zhCN','听到这里，雇工答应了。\n\n''好极了！''僧人喊道。他急切地想出一个难度足以挑战雇工、又足够简单以保持趣味的问题。''要如何测量一个不规则物体的体积？''他两眼放光地问道。\n\n雇工连想都懒得想，直接递给僧人5枚金币。\n\n僧人颇为失望，但做好了迎接雇工挑战的准备。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4609 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4609,'zhCN','轮到雇工了。他皱着眉头苦思冥想，终于开口：''什么东西有老虎的心、雄鹰的智慧，还有公牛的力气？''\n\n这个谜题让僧人喜出望外，他一跃而起，开始在房间里踱步。整整六个小时，他都在沉思雇工的难题，谢天谢地总算安静了。很快，他变得烦躁起来。最终，他满脸愠怒与不屑，颓然垂首。''罢了！罢了！我认输了！''他挥舞着手臂喊道，不情愿地掏出一袋金币，数出五十枚珍贵的金币付给雇工。庄稼汉欣然收下了自己的赢利。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4610 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4610,'zhCN','''永远保持怀疑。质疑一切。在追求善的道路上，不作为是唯一的真恶。''——祖容大师。\n\n火金之道以果决的行动为标志。其信奉者认为道德与理想并非绝对，而应因时因势而变。\n\n因此，火金派的宗师必须保持思想的灵活，时时自问：善在何方。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4611 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4611,'zhCN','从前，有个横行霸道的魔古军阀在掌权后威胁到了翡翠林的安危。$b$b“我要重振魔古帝国的雄风！”他站在青龙寺的门前放出话来，“你们这些人会再次沦为奴隶。”$b$b从墙垛上传来一位武僧的声音：“你带了多少魔古族来挑战我们？”$b$b“在我麾下有一百名魔古战士组成的大军！”军阀骄傲地叫嚣。$b$b“但在这高墙背后，我们有五百人。”武僧信心满满地回答。$b$b魔古兵团方寸大乱，开始质疑自己的领袖。他们心中充满了怀疑，大军竟然不战自溃。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4612 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4612,'zhCN','军阀怒不可遏！他离开了寺院，四处寻找他的魔古同伴。经过不厌其烦地软硬兼施，终于又集结起一支魔古军队。$b$b在青龙寺的大门前，魔古军阀喊道：“我带来了六百名魔古战士，看我如何将你们那区区五百名守兵打得溃不成军。”$b$b从墙垛上传来一位武僧的声音：“忘了告诉你，我们每位武僧都养着一条成年大蛇，能把魔古族一口吃进肚子里去！这些大蛇可都已经饿坏了。”$b$b此话一出，魔古战士们又变得军心涣散，悔不该来，慌忙逃往内陆深处。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4613 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4613,'zhCN','军阀再次震怒！他只得重新集结军队，多年之后才得以返回。这一次，他带回了由魔古和魁麟组成的强大军团，还有从古代皇帝的墓穴里盗取的武器。$b$b“下跪吧，你们这群可怜虫！”军阀叫道，“一千名魔古和五百名魁麟将要破门而入。魔法和黑暗武器也尽在我手。”$b$b从墙垛上传来一位武僧的声音：“那你找到我们的密探没有？他可真是足智多谋。”',1);
DELETE FROM `page_text_locale` WHERE `ID`=4614 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4614,'zhCN','此话一出，在魔古军团里立即爆发了严重的内乱。人人都怀疑对方是叛徒或间谍。在魔古族之间原本就毫无信任可言，一切都用实力说话。$b$b寺院门前爆发了激烈的战争，魔古族自相残杀，恣意释放心中的怀疑、愤怒、恐惧、仇恨、暴力和绝望。$b$b当硝烟散尽时，就只剩下军阀一人孤零零地站在门前。他亲手杀死了许多故人，再也没有知交好友能帮他夺取王权。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4615 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4615,'zhCN','这时有位熊猫人武僧从寺院里走了出来，环顾四周，准备打扫战场。$b$b“你的军队在哪呢？”军阀问道。$b$b“就是你带来的那些啊，”武僧笑着回答，“朋友，如果你先自乱阵脚，那你就已经输了。”',1);
DELETE FROM `page_text_locale` WHERE `ID`=4616 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4616,'zhCN','从前，一名锦鱼人坐在河边思忖种种，这时来了一只蜥蜴人。锦鱼人起初紧张兮兮，准备纵身跃入河中逃走。\n\n但蜥蜴人举起双手说：''我只想过河，可我不会游泳。你是游泳好手。也许我可以骑在你背上到对岸去。''\n\n锦鱼人答道：''可你会捅我、咬我，或者想吃掉我的脑袋。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4617 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4617,'zhCN','和平宛如一条河。有时水面平静，一路平稳流淌很远；有时它不得不与大地的形状抗争，在激流中翻腾，凿穿岩石，方能抵达终点。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4618 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4618,'zhCN','小心锦鱼人\n\n他们是一帮臭泥蛋\n\n照着脑袋咬一嘴。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4619 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4619,'zhCN','手里一只滑溜溜\n\n胜过坑里两只臭\n\n意意大王如是说！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4620 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4620,'zhCN','叩叩闻手指\n\n一股子屎臭味\n\n再也不闻了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4621 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4621,'zhCN','香蕉图腾\n\n世上顶顶好的宝贝\n\n吓翻所有威克特！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4622 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4622,'zhCN','猢狲功夫的奥义：\n\n抓一把，捅一刀，狠狠咬一口。\n\n重复，直到打赢。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4623 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4623,'zhCN','铭记火海之原。\n\n铭记我们挥舞的力量。\n\n铭记我们效力的勇士。\n\n铭记我们焚毁的王国。\n\n''野牛人！野牛人！野牛人！''他们高喊，\n\n直到声嘶力竭。\n\n''野牛人！野牛人！野牛人！''他们呐喊，\n\n在恐惧、烈火与死亡之中。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4624 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4624,'zhCN','很久很久以前，在山丘之下住着一种叫石腭怪的生物。它在山洞与隧道里游荡，东嗅西探，自得其乐。直到有一天，它遇到了一个魔古。\n\n''你的手臂多么强壮啊，''魔古对石腭怪说，''我要用我的魔法让它们更强壮，好去碾碎我的敌人。''\n\n''你的鼻子多么灵敏啊，''魔古对石腭怪说，''我要用我的魔法让它更灵敏，好去嗅出我的敌人。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4625 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4625,'zhCN','''你的方向感多么出色啊，''魔古对石腭怪说，''我要用我的魔法让你永远不会忘记任何足迹，好让你摸清我敌人的路径。''\n\n魔古用锦绣谷之水，把这种生物塑造成了武器。\n\n烟消尘散之后，魔古看到了什么？一只牦牛人喜滋滋地站在那里。\n\n''有了强壮的手臂、灵敏的鼻子和不忘路径的头脑，''魔古对牦牛人说，''把这批粮食从东边的农田运到西边的长城去。找出沿途的每一条小路，再告诉我你看到的敌人。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4626 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4626,'zhCN','于是牦牛人上路了，带着强壮的手臂、灵巧的鼻子和过目不忘的头脑，去寻找魔古口中的''敌人''。他确实送到了粮食，也找出了条条小路，却连一个敌人的影子都没见着。\n\n''我的敌人有什么消息？''魔古问牦牛人。''他们藏在高山的隘口里？藏在河边洞穴里？还是藏在远处的农田里？''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4627 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4627,'zhCN','牦牛人眨眨眼，想了又想，终于开口：''我用鼻子嗅、用眼睛看，却没瞅见你的什么敌人。在山里，我看见猢狲在挖他们的小隧道；在河边的洞穴里，我看见锦鱼人在跟水说话；在农田里，我看见熊猫人在跳一种滑稽的舞蹈。''\n\n魔古思忖片刻，放宽了心。\n\n牦牛人一次次出发，每次归来，魔古都问同样的问题。而牦牛人的回答也总是同样。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4628 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4628,'zhCN','魔古没有意识到的是，猢狲挖掘的隧道，将绕到魔古防线的背后；锦鱼人聆听水声，是要占卜叛乱爆发时魔古会先从何处应对；而熊猫人也并非在跳舞，而是在操练徒手搏斗。\n\n叛乱爆发之时，魔古被这突如其来的变故激怒了。\n\n''你说没找到我的敌人！''魔古对牦牛人吼道。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4629 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4629,'zhCN','牦牛人咧嘴一笑，对魔古说：''我看见了自己想看见的东西。你听见了自己想听见的话。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4631 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4631,'zhCN','熊猫人帝国初立不久，赞达拉战争期间，一个名叫蒋的少女正在育林宝地里散步，忽然听见一阵响动。一条幼小的云端翔龙躺在地上，身负重伤，奄奄一息。蒋以母亲般的温柔将这个小家伙抱进怀里悉心照料。她给它取名''洛''，两人结成了莫逆之交。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4632 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4632,'zhCN','平民百姓对此扼腕叹息。要知道，翔龙被视为怪物和野兽，既狡猾又危险。镇民们疏远蒋，恳求她在洛长大伤人之前把它处理掉。\n\n一天，赞达拉军队一路南下，直逼翡翠林。这些来自大海彼岸的巨魔向潘达利亚发动进攻。蒋响应征召，在海滩上保卫她的族人。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4633 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4633,'zhCN','在一场战斗中，蒋险些丧命于一柄巨魔长矛之下。就在矛尖离她心口仅数寸之遥时，洛赶来救了她。\n\n这条才长了一半的翔龙俯冲而下，将那个巨魔生撕活剥。随后他抱起受伤的蒋，飞离战场，把她送到了安全的地方。\n\n待她痊愈之后，蒋去拜见潘达利亚防务的首领。他们是捍卫这片土地、抵御巨魔和其他威胁的伟大武僧。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4634 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4634,'zhCN','她试图向他们解释翔龙能如何助战，洛如何救了她的命，她如何知道怎样扭转战局。\n\n但她的言语如泥牛入海。武僧们囿于自身的智慧，选择继续以他们认为合适的方式防御。\n\n但蒋没有放弃。这次拒绝反而更坚定了她的决心。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4635 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4635,'zhCN','在成为部族之前，在成为对手之前，在成为父亲、母亲或孩子之前，我们首先是野牛人。\n\n野牛人是力量！\n\n野牛人是勇气！\n\n野牛人是坚韧！\n\n我们站在艾泽拉斯最强大敌人的阴影之下，却蓬勃发展。我们共同繁荣。\n\n不许任何野牛人向另一个野牛人宣战。不许任何部族与其他部族开战。为此，我们必须保持勇敢。\n\n让那些想互相争斗的人孤身去斗吧。让想称王的人自个儿插旗，自个儿守去吧。如此我们才能保持强大。如此我们才能保持团结。如此我们才永远是野牛人！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4636 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4636,'zhCN','致相关人士：\n\n这张便条的粘性是我过去一年研制的一种特殊毒素。如果你们是螳螂妖，而且正接触着这张纸，那么你只剩两分钟可活了。永别了。\n\n至于其他人，我叫林，我快死了。请务必把这些情报送到影踪派手中。我收集了关于螳螂妖及其文化的情报，对更新我们对这个敌人的认识至关重要。\n\n此时此刻，我眼看着我日记的书页随风飘散在恐惧废土上。我很想追上去，但我流了太多血。\n\n螳螂妖比我们想象中古老得多。而且极有组织。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4637 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4637,'zhCN','几天后，赞达拉军队从海岸长驱直入。在晨息村附近的大桥上，熊猫人的勇士们坚守阵地。他们奋力抵挡巨魔，却渐渐不支。赞达拉兵力众多，他们的蝙蝠骑士的战法令熊猫人束手无策。胜利的希望开始破灭。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4638 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4638,'zhCN','我们一直知道螳螂妖与他们的树之间存在联系。我们原以为这种联系纯属本能，就像蜜蜂与花的关系。\n\n然而它的意义远不止于此。对螳螂妖而言，他们的树是神圣的。那是浸透螳螂文化的活生生的神龛，是螳螂妖社会的基石。\n\n每棵树都有螳螂妖赐予的名字。生活在那棵树上的螳螂妖——无论栖身于根部、枝头还是犄角旮旯——都与那棵树共享一个名字。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4639 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4639,'zhCN','而在旁观者眼中出现了什么？阿姬骑在她的朋友洛的背上！\n\n这对朋友俯冲而入，从桥上抓起赞达拉人摔下去，还击落了他们的蝙蝠骑士。无人能挡住这对朋友的怒火。\n\n战争还需要好几个月才能获胜，但这就是转折点。很快，阿姬开始训练其他熊猫人像她一样骑乘其他翔龙。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4645 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4645,'zhCN','战王古尔坦，百兽之主、万人的征服者，在此等候。\n\n他等着大地匍匐在他面前，如同百兽曾经那样。\n\n他等着太阳跪拜在他脚下，如同人类曾经那样。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4660 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4660,'zhCN','兄弟姐妹们：\n\n我们必须把目光投向海岸之外。迷雾已经落下。我们影踪派就是下一道、也是最后一道防线。\n\n首先到来的，正如你们所知，是部落和联盟。虽然他们尚未显露敌意，我们仍将保持警惕，继续监视。\n\n接下来到来的并非乘空而来，而是从海底涌来。龙虾人在我们海岸的活动日益频繁，这预示着未来可能发动进攻。我将重点标出几个需要留意的高优先级目标。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4661 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4661,'zhCN','阿卡洛\n众所周知，这只雌性龙虾人在饥饿时会袭击斯里拉村的渔民。关于她是仅是麻烦还是彻头彻尾的威胁，报告众说纷纭。最后一次出现在翡翠林迎风岛西南方的礁石上。\n\n阿卡拉\n阿卡拉以其厚重的甲壳在同族中闻名。他大胆袭击翡翠林锦鱼人的行径，显示出他的傲慢或力量——或许两者兼备。最后一次出现在翡翠林南端，珠鳍村以南。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4662 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4662,'zhCN','达姆拉克\n奥妮亚学者认为龙虾人具备一定的魔法能力。见过达姆拉克的人都知道这是事实。这只阴影般的生物游荡在卡桑琅荒野中赤精摇篮与纳耶里潟湖之间的岛屿和海底。\n\n基沙克\n来自北方冰冷海水的凶猛战士。最后一次出现在昆莱山顶佐春村以西的岩质海岸上巡逻。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4663 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4663,'zhCN','巨壳斯多克\n这只来自长城之外的绝对蛮兽以惊人的力量著称。就连螳螂妖也对它敬而远之。最后一次出现在赞维斯西北海岸。\n\n奥德尼罗克\n奥德尼罗克不像其他龙虾人那样用爪子作战。相反，他拥有粗陋的萨满之力，能驱使水流本身作战。最后一次出现在螳螂高原希克维斯悬崖以南的海岸。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4664 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4664,'zhCN','爪王克里曼达\n说到龙虾人，我不能不提克里曼达——人称爪王，或南海恐怖。\n\n克里曼达已有多年未见。我们在南方长城沿线的瞭望哨检查过他位于赤精摇篮以西远处的岛屿，没有发现他归来的任何迹象。\n\n保持警惕。\n\n——猎鹰统领努荣',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4665 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4665,'zhCN','迷踪步道蜿蜒如蛇，一侧是四风谷的丰饶低地，一侧是昆莱山的起伏草原，堪称熊猫人的奇观。\n\n它是魔古第三王朝时期熊猫人奴隶们徒手开凿的。据我们所知，这意味着这些台阶已有超过一万两千年的历史！\n\n牦牛人认为，旅人在登阶时数一数台阶会带来好运。这也许是真的；但从没有人能数出一个公认的准确数目。\n\n你数到了几级？',1);
DELETE FROM `page_text_locale` WHERE `ID`=4666 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4666,'zhCN','第十二天$B$B尊敬的大酋长：$B$B克鲁格在与联盟旗舰的战斗中阵亡后，我接管了舰队。他死得极为荣耀，直到得知联盟战败才咽下最后一口气。$B$B战斗使舰队损失惨重，但我们四散的船只正一艘接一艘胜利抵达这片陌生土地的海岸。它不在我们的任何一张海图上。$B$B我已命令苦工们修建一座安全港口，以便修理船只。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4667 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4667,'zhCN','第十三天$B$B一种肥胖的熊形生物把这片土地称作家园。他们叫''熊猫人''。达尔甘告诉我，奥格瑞玛建立时就有一名熊猫人在场，但他总是满肚子酒话和谎话。$B$B这些熊猫人似乎不构成威胁，但他们拥有对我们的战役大有用处的物资：粮食、木材、石料……如果这能代表这片新大陆的富饶，那它将成为部落的一件上等战利品。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4668 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4668,'zhCN','第十四天$B$B斥候发现了一处无人认领的古代遗迹，背靠着俯瞰海湾的群山。那是理想的要塞。我不指望奥格瑞玛的援军能在几周内赶到。因此我翻开了古老的典籍，命令我们的术士开始召唤恶魔力量来扩充军备。这种武力展示无疑能震慑熊猫人，让他们为我们效力。$B$B一个营的被遗忘者部队在深夜泅渡上岸，他们是海战的幸存者。看来他们是不可能被淹死的。恶臭令人难以忍受，但他们或许还有用处。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4669 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4669,'zhCN','第十五天$B$B此刻，我们海上大捷与发现新大陆的消息想必已传到奥格瑞玛。援军无疑正在路上。我们的瞭望哨发现联盟侦察船在标记海战位置的残骸区附近鬼鬼祟祟——他们多半是来找自己人的。我们会做好准备的。$B$B事实证明，熊猫人对我们的事业毫无用处。他们对我们用来交易的货物不感兴趣：连最强大的邪能神器都让他们嗤之以鼻。我的部队需要粮食，我们不能像那些恶心的亡灵一样去吃溺亡水手的尸体。熊猫人的傲慢令我怒火中烧。我似乎无法摆脱这股狂怒。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4670 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4670,'zhCN','第十七天$B$B联盟要来了。我能感觉到。我不知道为什么——一股压倒性的不安与恐惧笼罩着我。这片土地的某种东西正在侵蚀我。我已命令术士召唤一个恶魔监视者来监视海岸。他们坚称我们无法控制它。我在危难时刻竟被懦夫包围。我为什么会感到怀疑？我发誓我的皮肤正在褪色。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4673 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4673,'zhCN','登陆成功！\n\n整个夜里，我们与一支兵力数倍于己的部落舰队断断续续地交战。我们的损失惨重，但战果更加丰硕。我们利用浓雾掩护行动；毫无疑问，他们以为我们的兵力远比实际庞大，因此在晨光中朝东南方向逃遁。\n\n雾气散去时，我们惊讶地发现了一面巨大的峭壁。陆地！它不在我们的任何一张海图上。我已致信''求索号''，请求安排空中支援。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4674 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4674,'zhCN','第二天\n\n''求索号''已经抵达并派出了它的旋翼机。这绝非一座无名的孤岛——我们发现了一整块大陆！我将立即开始把人员和物资通过峭壁向上运送。从这片高地，我们将能俯瞰附近的海洋。\n\n舰队之间的通讯断断续续，令人困惑。部落似乎无处不在；我们已经与泰勒上将的旗舰失去联系，它很可能同我们几天前重创的那支部落舰队交上了火。圣光保佑他；他们已经杀红了眼。\n\n在没有暴风城消息的情况下，我将主动出击，夺取这片土地。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4675 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4675,'zhCN','第五天\n\n''求索号''留下一整个中队的旋翼机协助我们修建基地。我的人马占据了一系列废弃的遗迹作为要塞。遗迹和周围的丛林对空中交通来说太过危险，我们一直把南边的一些空地当作临时机场。\n\n今天上午我们第一次接触了当地人。他们是熊猫人！我原以为他们只是传说。这里难道就是传说中的熊猫人家园？',1);
DELETE FROM `page_text_locale` WHERE `ID`=4676 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4676,'zhCN','第七天\n\n熊猫人们问题一大堆，却帮不上什么忙。我承认我感到极度不安，却说不清为什么。我的所有疑虑在这里似乎都被放大了。部落会卷土重来；我确信这一点。他们会来多少？从海上来还是从空中来？我必须做好准备！\n\n伙计们吃着半份口粮干着双倍的活。熊猫人提出用粮食交换，却对暴风城的期票不感兴趣，还嘲笑我们的钢材质量。不知为何，这让我怒不可遏。他们知不知道自己马上就要身处战场中央了？',1);
DELETE FROM `page_text_locale` WHERE `ID`=4677 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4677,'zhCN','第九天\n\n''求索号''报告说今天上午在一次海上交战中抓捕了部落俘虏，随后突然陷入沉默。我怕是凶多吉少。\n\n实际上，我怕的东西太多了。我们孤悬于此。暴风城的援军远在数周之外。泰勒的旗舰失踪了，如今''求索号''也杳无音讯。我们在海战中输了吗？疑虑在我心中翻腾。我无法冷静思考。我发誓我的皮肤正在褪色。我到底怎么了？',1);
DELETE FROM `page_text_locale` WHERE `ID`=4678 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4678,'zhCN','第十二天\n\n我每天都在地平线上搜寻部落的飞艇。我们还没有准备好。我们的机场一片狼藉，塔楼只建了一半。一些熊猫人提出帮忙，我便征用了他们。\n\n多年前，库尔森上校在荆棘谷陷入疯狂时，我曾追捕过他。直到现在我才明白他是如何一步步堕入黑暗的。我孤独一人。夜里，我在闷热中辗转难眠，发誓我听见影子在低语着我的死期。必须把机场建完。必要时我会给熊猫人戴上镣铐。部落……部落……',1);
DELETE FROM `page_text_locale` WHERE `ID`=4679 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4679,'zhCN','第十四天\n\n一觉醒来，听说海岸外升起了一枚信号弹。雾中有个影子在移动。是部落的炮舰？\n\n我已派出信使去召集旋翼机。他们也许来不及赶到了。命令所有人进入炮位。就是现在了。\n\n我被愤怒与恐惧淹没了。我不像我自己。也许胜利能让我找到慰藉？\n\n如果那真只是一艘部落飞艇，他们毫无胜算。我们会把他们杀个精光。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4711 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4711,'zhCN','地精和血精灵。这些生物是自私傲慢与自恋的化身。没有一个小时过去，我不在质疑加尔鲁什接受他们在这次进攻中的援助是否明智。$B$B不错，破法者对我们的防御战略而言价值连城。而加里维克斯的部队也确实成了对付侏儒发明的奇兵——那些发明日复一日地砸在我们的城墙上。但我不信任他们。尽管他们为部落出生入死，他们却没给我什么信任他们的理由。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4712 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4712,'zhCN','前几天我抓到一个血精灵在破译一件魔古神器。他跟我分享情报了吗？没有。尽管我确信洛瑟玛对这些远古文字有一本完整的账。魔古留下的可不是锅碗瓢盆，他们留下的是武器和远古的力量。$B$B还有那些地精！每次我一转身，就会撞见一两个在鼓捣新型炸弹的家伙。我们到现在还没被炸上天，对我来说简直是奇迹。加里维克斯不断给我们提供有助于战争的新化学配方，但我知道他学到的东西远比他表露的多。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4713 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4713,'zhCN','我绝不容忍队伍里的离心离德。如果这些活动继续下去，我可能不得不开始''清理''几个关键的罪魁祸首。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4714 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4714,'zhCN','受约人（以下简称''你''）同意执行大酋长或其军官下达的一切命令。这些命令必须不折不扣地执行，但有以下保留条款：不得妨碍贸易亲王加里维克斯（以下简称''我''）的任何利润。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4715 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4715,'zhCN','由我或我的军官发布的任何命令，其优先级高于部落的其他一切命令。拒不服从将导致诉讼及拒付。阅读本条款即表示你同意以你的性命及其中的一切财产作为本合约的抵押。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4716 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4716,'zhCN','附加例外条款包括可能导致部落财政基础设施崩溃的部落命令。别让部落在这场战争中破产！我拥有所有联盟战争机器的打捞权，而且我打算行使。任何导致加尔鲁什及其部队破产的行为（哪怕是他亲自下达的命令，而他很可能会这么做），都将导致大酋长的债务立即转移给你，以及你认识的所有可能帮忙偿还这笔债务的人。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4717 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4717,'zhCN','这张羊皮纸上的墨水具有法律约束力，你现在须遵守所有法律和……嗯，实话实说吧。你要是敢毁约，我的打手会比血精灵扑向邪能电源还快地扑到你身上。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4718 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4718,'zhCN','加里维克斯的合同太宽松了。像盯恶狼一样盯紧他的地精。可以用他们，但要明白他们多半在某种程度上听命于贸易亲王。我必须知道他最终想要什么。替我查清楚。为了部落！',0);
DELETE FROM `page_text_locale` WHERE `ID`=4719 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4719,'zhCN','血柄，我给你派去一支血精灵分队。洛瑟玛终于决定履行他对部落的承诺。我不信任他的动机，但与其把我们的兽人浪费在对付联盟施法者这种小事上，不如用他们。$b$b他们交由你调遣。愿地狱咆哮注视着你！',0);
DELETE FROM `page_text_locale` WHERE `ID`=4720 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4720,'zhCN','人一生中既能服从命令又能报仇雪恨的机会可不多。我认为自己很幸运。$B$B部落派来了血柄战领。我在南方贫瘠之地征战时，就是那个败类在主管荒弃堡。正是他的指挥害死了我的儿子，在贝尔莫丹屠戮了我们的人民。$B$B如今，至高王本人授予我暴风城、铁炉堡和诺莫瑞根的全部力量，来把这些害虫从这个新大陆上碾碎。这换不回我的孩子，但也许我能让某个熊猫人免于尝到白发人送黑发人的痛苦。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4729 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4729,'zhCN','一个深秋的夜晚，两个好朋友坐在''懒萝卜''客栈后面的露台上。脚下是沉睡的安静农庄——半丘镇。午夜的空气沁凉入骨。薄雾开始为山谷中起伏的绿色丘陵披上露水，皇家粮仓的塔尖在头顶璀璨的星空映衬下显出一道黑影。$B$B一顿美食和数小时的本地草药让两位朋友进入了沉思。$B$B智——两人中更年轻、也更容易钻牛角尖的那个——突然问了一个十分尖锐的问题：''如果这一切都不是真的呢？''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4730 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4730,'zhCN','他的老朋友理原本一直仰靠着，草帽盖着眼睛，此刻掀起帽檐望着朋友。''一个严肃的问题？''他说，棕色的眼睛目光炯炯。$B$B智抬手一挥，指向整片山谷。''如果我们只是别人画里描出的影像呢？''他问道。他摸了摸自己的脸，倒吸一口气。''如果我们是一本书里的角色呢！？''$B$B老理双手抱腹，发出一声深沉而富于哲思的大笑。他从朋友智手里拿过烟斗，放到一边。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4731 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4731,'zhCN','''眼眸之后，栖息着一个人的灵魂，''老理终于答道，''那是他们的本真：思考、爱恋、情感的核心。我的灵魂让我真实，你也一样。''$B$B此时老理起身站到朋友身旁。他搂住智的肩膀，把他的注意力引向脚下的山谷。''看到我们右下方了吗？那个农贸市场？''在清冷的秋夜中，半丘集市宛如黑暗起伏的丘陵间一座温暖的黄色光岛。彩旗在寒风中猎猎作响，人影在摊位间穿梭，购买补给，或用劳动的果实讨价还价。他们的声音和笑声难以分辨彼此，却分明生机勃勃，一直传到客栈里。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4732 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4732,'zhCN','''那些来来往往的身影，每个人都有灵魂，''老理继续说道，''而我们共享这片天地。千百万个灵魂，共享同一个地方。我们的地方！只要你我还在这里共同享受它，半丘就是真实的。''心满意足的老理回到座位上，示意店家再来一杯。$B$B智在露台边上流连，把身体的重量靠在粗粝的木柱上。他呼吸着清凉的空气，看着萤火虫在下方田野星光摇曳的草丛间飞舞。''理，''他终于说道，''无论是画也好，不是也好……如果我们的灵魂注定要共享一个地方，除了你，我谁也不愿共享。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4733 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4733,'zhCN','老理把草帽推回眼睛上方，低沉而温暖地应了一声。$B$B蟋蟀的鸣叫与下方集市的热闹喧嚣交织在一起，让两位朋友重新沉入幸福安宁的寂静。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4747 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4747,'zhCN','古拉王将风暴之力操控于指尖。只需一句话，他便能让噼啪作响的电流席卷大地。落入他风暴中的人，都死于可怕的灼烧。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4748 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4748,'zhCN','''看啊，这就是皇家内侍。愿他永远屹立，守卫陛下浩瀚而神圣的宝藏。只要这座雕像不倒，除皇帝本人之外，无人可以染指皇家宝库。''',19116);
DELETE FROM `page_text_locale` WHERE `ID`=4749 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4749,'zhCN','至尊至贵的战神贾拉克：$b$b那些恐角龙又顶死了一个正在受训的驯兽师。那蠢货被一只嗜血龙咬了一口，失了神。他正在组装的巫偶整个散了架，恐角龙当场把他撕成了碎片。$b$b我们操之过急了。我们的驯兽师需要长年的训练。我知道我们需要更庞大的军队，可要是野兽反过来残杀我们自己人，那对咱们也没什么好处。$b$b我们愿意效劳，但您比谁都清楚，咱们不能让小娃娃去干巨魔的差事。',0);
DELETE FROM `page_text_locale` WHERE `ID`=4750 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4750,'zhCN','魔暴龙可不是随便谁都听的。它们是猎手。是杀手。你吓唬不了魔暴龙。你也别指望用鞭子就能让魔暴龙像奴隶一样听命。$B$B要驯服魔暴龙，你得取它的魂。取过来！绑起来！与你的巫偶熔为一体。这是古老的方法。血与权的方法。你要的不是野兽的尊敬！而是它的屈服。把它打服，让它屈从于你的意志。$B$B只有最伟大的驯兽师才知道该怎么做。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4751 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4751,'zhCN','自我们种族的黎明起，我们便与迅猛龙并肩狩猎。这些野兽聪明、致命而忠诚。巨魔和他的迅猛龙之间不只是友谊。那是血的羁绊。你们彼此需要。$b$b通常你们有许多年去与自己的迅猛龙磨合。但眼下时间紧迫，赞达拉需要猛龙参战。我们已唤醒了古老的方法。取迅猛龙之血，把它们的精粹绑进巫偶。自然磨合已经来不及了。$b$b时代如此。',19116);
DELETE FROM `page_text_locale` WHERE `ID`=4752 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4752,'zhCN','很久以前，赞达拉曾败于熊猫人之手。他们训练翔龙猎杀我们的蝙蝠骑士，改变了战争的形态。我们毫无还手之力。$B$B但那已是久远的往事了。我们观察、学习，终于找到了克制之法。天空的猛兽！翼手龙来了，它们撕碎苍穹，把毁灭倾泻在敌人头上。熊猫人的翔龙虽然灵巧，但我们的翼手龙更快、更凶。$B$B很快我们就要让这些小鸟接受实战检验了。做好准备，刻苦训练，绝不留情！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4753 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4753,'zhCN','在雷神掌权之前的岁月里，魔古与潘达利亚的其他种族连年交战。魔古与锦鱼人帝国打了一场持续四十天四十夜的战役。$B$B在战线后方，锦鱼人的水语者召唤水柱，将魔古军队淹没。他们变出水泡把魔古托上天空，再让他们坠地身亡。$B$B最后，就在魔古军队几乎溃败之际，一名无名的步兵挺身而出，迎战这些鱼人。他抓起一篮锦鱼人的长渔叉，以致命的准头掷过战场。$B$B鱼叉刺穿了水语者的水盾，终结了抵抗。这一仗就此获胜。$B$B战后，雷神将一百杆由魔古锻造大师打造的精品金矛授予哈金。他成为雷神麾下最伟大的将领之一。他死后，那些金矛被殉葬在他身边。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4754 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4754,'zhCN','雷神统治的鼎盛时期，伟大的雷霆熔炉日夜轰鸣，锤声与钢铁交相回响。$B$B匠人铁匠、锻造大师邓亲自督造熔炉，并亲手锻造了数千件武器。在锻造大师的妙手之下，寻常金属化作非凡的利刃——功能与形态的完美统一。$B$B在临终之前，锻造大师完成了他最杰出的作品——一杆长矛、一柄战斧和一顶头盔，专门献给雷神本人。$B$B在邓正式下葬的仪式上，雷神说出了这样一句话：''今日，一颗星辰离开大地，升入苍穹。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4755 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4755,'zhCN','驭雷者武担任雷神最信任的顾问。$B$B两人出身同族，情同手足。孩提时代，他们一同玩耍、争吵、互相较劲。据说，正是这段早期的较量磨砺出了雷神对权力的渴望。而武也奋力相助，助雷神赢得潘达利亚的王座。$B$B雷神声名鹊起后不久，驭雷者被敌方刺客掳去，惨遭割舌。坊间盛传这起阴谋的背后主使正是雷神本人——这是一场政治手段，为了让唯一知晓他最深秘密的魔古永远沉默。$B$B两人的兄弟情谊也是诸多揣测与杜撰的源泉。平民大众热衷于编写故事，其中就包括一部关于两人争夺一名女子的著名史诗。$B$B尽管流言纷纷，历史表明驭雷者武从未动摇过对皇帝的忠诚；他毕生忠心耿耿地辅佐着自己的朋友与兄弟。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4757 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4757,'zhCN','嗜血龙是一祸害。它们啃我们的粮食，往我们的水里下毒，猎食我们的孩子，吞食我们的伤员。它们连下水道的老鼠都不如。$B$B但这些老鼠是可以训练的。我们赞达拉视这些嗜血龙为祸患。可我们的敌人不知道。他们没跟这些小东西和它们的毒一起长大。是时候把这些害虫变成武器了。$B$B抓它们！训练它们！放去咬我们的敌人，看看他们怎么扭来扭去。让这些嗜血龙吃他们的粮食，往他们的水里下毒，猎食他们的孩子，吞食他们的伤员。证明就连赞达拉的害虫也是我们军械库里的武器！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4758 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4758,'zhCN','赞达拉没有弱者的容身之地。力量、凶猛、耐力、强权：这些是衡量成功的标尺。到了青春期，那些没有被选为祭司或学者的赞达拉男性，必须向议会、国王和诸神证明自己的力量。$B$B任何形式的力量展示皆可。孩子们成年之时，比武大会和竞技赛随之举行。少年们以经年的训练、与神灵的交融、以及在皮肤上纹上力量符印来备战。一个常见的仪式，是前往首都附近某座由凶兽统治的蛮荒岛屿，盗取或驯服一只野兽。$B$B较小的巨魔部族也有他们较简朴的版本。但驾驭狂暴龙或迅猛龙，与召唤魔暴龙或恐角龙所需的力量不可同日而语。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4759 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4759,'zhCN','数千年来，赞达拉社会始终是一成不变的等级制度。$B$B 勤劳的农夫、渔夫和工匠构成平民阶层，是帝国的基础。赞达拉长者告诉他们收割什么、何时播种、如何行事。违逆长者就是违逆神明，此罪可处以流放或死刑。$B$B 赞达拉战士阶层位于平民之上，是国王的臂膀和议会的力量。赞达拉战士并不崇尚灵巧：以古老魔法加持的蛮力，才是他们偏爱的战斗风格。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4760 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4760,'zhCN','主宰赞达拉社会方方面面直至最细微之处的，是学者和祭司阶层。他们是魔法与神灵沟通的大师，这些受人尊敬的知识殿堂积淀着整整一万五千年的学识。其中最显赫者在赞丘利议会中拥有一席，他们既为国王献策，又确保国王的每道命令都得以执行。每次开战或重大决策之前，都必须咨询议会。$B$B而在黄金王座之上、统御全体赞达拉者的，是伟大的拉斯塔哈大王。$B$B他受赞达拉诸神亲自授权，作为诸神的喉舌，统治已逾两百年。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4761 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4761,'zhCN','赞达拉人崇拜''洛阿''——那些在世界诞生之初便已存在、连泰坦都要退居其后的强大神灵。洛阿不可计数，大多弱小，但也有极为强大者。大多数无形无相，另一些则化形为动物或生物。$B$B 赞达拉家族往往供奉自家的家系洛阿，城市通常有自己的守护神，而最伟大的洛阿则受举国膜拜。强大而开悟的赞达拉死后可以成为洛阿——至少人们如此相信。$B$B 这些神灵是赞达拉世界观的中心：洛阿怎么说，赞达拉就怎么做。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4762 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4762,'zhCN','在赞枢利议会中，有许多祭司和法师拥有不可思议的力量以及禁忌的知识。其中最受尊敬的一位名叫祖尔。即便在他还是个孩子的时候，他所看到的黑暗又可怕的预示都一个个准确无误地变为现实。他控制着恐惧，被尊认为黑暗预言师之一，即能够在大灾难发生之前预见到它的先知。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4763 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4763,'zhCN','在大灾变发生前的几个月里，祖尔噩梦连连，看到的全是世界被撕裂的可怕预示。他解读了所有的预兆并确信，赞达拉一族的家园将在这场末日大灾难中毁灭。他向议会以及国王献策，建议联合其它巨魔部族，共同撤离难逃一劫的家园。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4764 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4764,'zhCN','不顾祖尔的警世危言，议会拒绝相信即将发生的灾难程度。很多人认为祖尔只不过是夸大其词，捞取自己的权利和地位资本而已，很多人对他嗤之以鼻。他的追随者们开始集结起一支战斗舰队并联络其他低等级的巨魔族。$b$B然而祖尔的预示就是真相的预示。死亡之翼引起的大灾变动摇了赞达拉大地的整个根基。强大而又神秘的巨魔帝国无情地滑入了大洋之中，赞达拉农民以及武士阶层各类人群涌向祖尔，寻求面对未来的指引。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4765 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4765,'zhCN','魔古传说讲述了一个金光普照的时代，秩序被带给混沌的世界。据说魔古以大地之躯行走于泰坦之间。他们数量如军团，唯一的意志便是主人的意志。$B$B根据这个时代的传说，潘达利亚的崇山峻岭正是魔古之手雕琢而成。每一条河流、每一片湖泊、每一座山峰，都依照神圣的规划塑成。$B$B魔古称他们的泰坦主人为''风暴''。他是他们的守护者。他们是他意志的延伸：秩序的使者，恭顺而强大，锻造着一个新世界。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4766 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4766,'zhCN','在魔古的艺术与文学中，有一个传说被反复传颂、添油加醋。它就是影、风暴与岩石的传说。以下是已知最早抄本的粗略译文：',1);
DELETE FROM `page_text_locale` WHERE `ID`=4768 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4768,'zhCN','许多个纪元以来，魔古守护着泰坦的伟大造物。他们始终聆听主人。始终恭顺服从。怀着磐石般的决心，他们亘古伫立，永恒守望。$B$B哪怕他们的主人已陷入沉默。$B$B魔古之石化为血肉的年代没有留下任何文字。对魔古来说，呼吸、流血、死去，该是多么可怖。$B$B他们向主人寻求指引，但主人依旧沉默。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4769 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4769,'zhCN','血肉带来了凡俗的其他诅咒：骄傲与贪婪，恐惧与愤怒。魔古不再同心同德，开始自相残杀。$B$B强大的魔古军阀纠集追随者，彼此征战。他们的战火烧焦了大地，令其他凡俗种族惶恐不安。$B$B而他们的主人依然一言不发。',18414);
DELETE FROM `page_text_locale` WHERE `ID`=4770 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4770,'zhCN','泰坦陨落后的漫长岁月里，魔古化为血肉、互相攻伐，大地陷入混乱。魔古军阀们为领土和权力大打出手。那是百王之世。$B$B这便是雷神的时代。年轻的他傲气十足，眼见先辈的辉煌成就散落在满目疮痍的大地上。他深深感到，他的族人没有活出他们的使命与潜能。$B$B泰坦不再开口。雷神便决定替他们发声。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4771 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4771,'zhCN','年轻的雷神出生于可怕的百王之世，是一名军阀之子。与他的兄弟们一样，他臂力过人，精于战道。但与同辈不同的是，他谈论的不只是征服。先辈的传说铭刻在他的心中。$B$B待雷神成年、统领自己的军团之后，他宣布要唤醒诸神。只有他最忠诚的追随者随他踏上了魔古从未敢涉足之地：雷霆之山的正中心——魔古奉为主人的那位存在的神圣居所。$B$B雷神下到了山中。$B$B但归来的，是雷王。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4772 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4772,'zhCN','在雷神建立古帝国之前，那里矗立着一座永沐风暴的高原。它被称为''雷霆之山''，是魔古奉为''主人''的那位存在世代相传的居所。$B$B历史没有记载雷神登上山巅、深入其殿堂后看到了什么。但当他归来时，他掌握了千风暴之力，宣布此山为他的权力宝座。他在山巅建起了一座雄伟而禁绝凡人踏足的城市。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4773 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4773,'zhCN','据说雷神死后，此山不再听命于任何人，风暴无休止地鞭挞着它。后来的皇帝将帝国权力中枢迁往锦绣谷。$B$B 即便到了末代熊猫人皇帝少昊的时代，人们仰望雷霆之山时仍满怀敬畏与恐惧。撕裂世界的大分裂几乎把这座山沉入海底，但也许末代皇帝认为它值得拯救。又或者他太过惧怕山中藏着的秘密，想把它藏起来。与潘达利亚其他地方一样，这座山顶城市——如今已成孤岛——被藏进了迷雾之中。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4774 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4774,'zhCN','手握风暴之力的雷王召集追随者，开始系统性地征服其他魔古军阀。大多数人不肯臣服：幸运者被闪电化为焦土，或被日益壮大的军团踏成齑粉。其余的则被锁链拖走，直到他认定他们已被''驯服''。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4775 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4775,'zhCN','但也有许多魔古在雷神身上看到了自主人沉默以来便已缺失的同心同德。他们聚拢在雷王的旗帜之下。在他奴役其他种族时，他们甘愿效犬马之劳，并像雷神一样相信：''低等''种族就该服务于魔古，正如魔古曾经服务于他们的主人。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4776 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4776,'zhCN','雷神统一了语言，建立单一货币，统一度量衡，缔造了一个帝国。$B$B大地的种族第一次联合起来。雷王认为他们的苦难只是微不足道的代价……不过是血肉的软弱罢了。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4777 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4777,'zhCN','即便在古帝国之前的年代，也有证据表明熊猫人对学问的热爱创造了史诗、农业和医学。$B$B 雷王看到了熊猫人身上的巨大潜力，正因如此，他不信任他们。$B$B征服大地之后，熊猫人被禁止读书识字。他们的领袖和哲人被处决。所有熊猫人的艺术和文学都被付之一炬。任何被抓到说魔古语以外语言的人，都被视为阴谋者，此罪往往以死论处。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4778 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4778,'zhCN','最早一批熊猫人艺术家和作家的心血之作，已永远失传。$B$B 许多年之后，又一代伟大的熊猫人学者诞生了……但他们所说的语言，却不再是真正属于他们自己的语言。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4779 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4779,'zhCN','我的魔古都怎么了？看看你们自己。你们与我们曾经用来建造城市的野蛮人几乎无异。$B$B身为魔古，即为统治。这正是我们被创造的原因。我们的话语充满力量！凡不屈从于我们意志者，必被我们的力量击垮。$B$B没有团结就没有力量。没有服从就没有团结。服从你的皇帝，并要求你的臣民服从，这就是自然法则。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4780 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4780,'zhCN','当你们自相残杀时，你们是在对抗自己的本性。这个世界自有其秩序，一股力量从你们皇帝的身上流淌而下，直抵大地最深处的岩石。莫要忘记这一点。$B$B我们的声音合而为一，将如风暴前的雷霆炸响，回荡在大地之上。你们就是那场风暴！$B$B起来吧，魔古！夺回你们作为这片大地合法统治者的生来权利！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4781 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4781,'zhCN','听好了，这是雷王的敕令！$B$B随着我的复活，赞达拉人偿清了一笔古老的欠债。我们的命运永远交织在一起。他们的帝国衰落之时，正是我们帝国复兴之日。他们为我们的伟业献上了船只、士兵和猛兽。待我们收复故土，他们将在北部海岸获得丰厚的封地。$B$B我们的盟友虽然弱小，但不要小看他们的力量和奥术造诣。他们与''部落''和''联盟''这些入侵者交手的经验，将对我们大有用处。$B$B巨魔与魔古联手，将获得凌驾于低等生物之上的无可估量的力量。我们将重建这个世界，让它如曾经那般，也如它命中注定那般！',1);
DELETE FROM `page_text_locale` WHERE `ID`=4783 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4783,'zhCN','很久以前，雷神的大军进军昆莱山。居住在那里的自由民众拼死抵抗，坚强不屈直至最后。他们绝不会为了这个雷王放弃自己的土地。$B$B但雷神图的不是土地，他图的是人民。他的帝国正在扩张，建造城市和堡垒都需要奴隶。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4784 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4784,'zhCN','于是雷神没有强攻山顶，而是以洪钟般的声音宣告：''在你们中间选出最伟大的战士，让他与我单打独斗。若我获胜，你们的子民须臣服于我的统治。若他获胜，我将和平离开这片土地。''$B$B''接受挑战！''一个声音在群山间回荡，几乎与雷神雷霆般的威势不相上下。$B$B从群山中走下来的，是白虎雪怒。这位至尊天神目睹了自由民众的苦难，再也无法坐视。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4785 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4785,'zhCN','一场传奇对决就此展开。闪电自天而降，大地在两位斗士的怒火中震颤。魔法对阵速度，仇恨对阵力量。$B$B据说这场对决持续了三十天三十夜，对决中激荡的情绪唤醒了大批煞魔。$B$B但最终，雪怒倒下了，被雷神超凡的伟力碾碎。$B$B''你那农夫的法术，岂能与我魔古的奥术相提并论，蠢虎，''雷神咆哮道，''我赞赏你的顽强，但你的顽抗必须受到惩罚。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4786 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4786,'zhCN','雷王向昆莱的民众宣告：''都给我记住，凡胆敢违抗我者，必将见识我怒火的全部威力！此兽不得享有死亡的仁慈。我们要在这些群山中为它建一座监狱，让它永世立于其巅。从这个顶点，它将眼睁睁看着自己的失败，而你们和你们的子子孙孙，将作为奴隶侍奉我的帝国。''',1);
DELETE FROM `page_text_locale` WHERE `ID`=4787 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4787,'zhCN','于是雪怒被置于昆莱山之巅，被迫目睹熊猫人和猢狲沦为奴隶。但这头猛虎从未屈服于雷神的折磨。在囚禁中，他愈发强大。他的失败成了一课，他的傲气得以收敛，他等待着那一天——一个年轻的熊猫人奴隶敢于挑战魔古皇帝威权之日。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4818 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4818,'zhCN','南海的祸害——恐怖船长热内斯特长眠于此。',1);
DELETE FROM `page_text_locale` WHERE `ID`=4819 AND `locale`='zhCN';
INSERT INTO `page_text_locale` (`ID`,`locale`,`Text`,`VerifiedBuild`) VALUES (4819,'zhCN','- 游者节 -$B$B欢迎大家参加游者节，向我们当中的梦想家致敬！每周日日落之后，在龟背滩集合。欲知详情，请在活动当天寻找游荡的传令官。',18414);

-- =====================================================================
-- PART 2：page_text 中英混合垃圾修复（原 02 号）
-- =====================================================================
--
-- 2026_09_27_02_world_fix_page_text_mixed.sql
-- 修复 page_text / page_text_locale 中 SQL 导入残留垃圾导致的中英混合文本
-- 污染条目：主表 111；zhCN 111/112/119/263；zhTW 111
--

SET NAMES 'utf8mb4';

-- 1) 主表 111：截断 "***..." 起的导入垃圾
UPDATE `page_text`
SET `text` = SUBSTRING_INDEX(`text`, '***************************', 1)
WHERE `entry` = 111 AND `text` LIKE '%***************************%';

-- 2) zhCN / zhTW 111、zhCN 119：同样截断
UPDATE `page_text_locale`
SET `Text` = SUBSTRING_INDEX(`Text`, '***************************', 1)
WHERE `ID` IN (111, 119)
  AND `locale` IN ('zhCN', 'zhTW')
  AND `Text` LIKE '%***************************%';

-- 3) zhCN 112：内容是 111 的污染重复，用主表 112 的干净简体文本替换
UPDATE `page_text_locale` l
JOIN `page_text` p ON p.`entry` = l.`ID`
SET l.`Text` = p.`text`
WHERE l.`ID` = 112 AND l.`locale` = 'zhCN';

-- 4) zhCN 263：尾部混入 264 的重复名单片段，用主表 263 替换
UPDATE `page_text_locale` l
JOIN `page_text` p ON p.`entry` = l.`ID`
SET l.`Text` = p.`text`
WHERE l.`ID` = 263 AND l.`locale` = 'zhCN';

-- =====================================================================
-- PART 3：烹饪引导任务链修复（原 03 号）
-- =====================================================================
-- 2026_09_27_03_world_fix_cooking_chain.sql
-- 修复烹饪引导链（对照 5.4.8 官方数据核查任务 31486）
-- 参考: quest 31486/31279/31281 audit vs wowhead/mop-shoot official data

-- 1) 31486 与 31279 是同一信件任务的两个变体，官方互斥（完成一个关闭另一个）
UPDATE `quest_template_addon` SET `ExclusiveGroup` = 31279 WHERE `ID` IN (31279, 31486);

-- 2) 31281《这么说，你想当厨师……》官方须完成信件任务后解锁；
--    负值 PrevQuestID = 完成 31279 或其互斥组内任意任务(即 31486)均可
--    注意：31281 原本在 quest_template_addon 中没有行，需插入
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (31281, -31279)
ON DUPLICATE KEY UPDATE `PrevQuestID` = -31279;

-- 3) 清理 31281 目标描述中的西班牙语残留（物品目标默认显示物品名，无需描述）
UPDATE `quest_objective` SET `description` = '' WHERE `id` = 268484;

-- =====================================================================
-- =====================================================================
-- PART 4：任务 29907《陈和丽丽》护送演出（最终状态）
-- 合并自 04 + 09 + 10 + 11 号文件（05-08 为废弃迭代，已剔除）
-- 内容：任务链前置 + 陈(56343)护送路径/对话演出 + 丽丽(56344)召唤与跟随
-- 时序（到达 WP5 起累计）：5s 陈转身+打招呼 → 13s 庞回(+8s) → 19s 陈谢(+6s) → 24s 动身(+5s)
-- 路径：起步(召唤点) → WP1(527.75,-696.16,247.28) → WP2(532.19,-684.70,249.54)
--       → WP3(533.25,-657.58,255.73) → WP4(532.45,-616.41,258.77) → WP5(544.22,-607.24,263.36 计分)
--       → WP6(536.33,-612.04,258.61) → WP7(535.13,-602.81,258.38) → WP8(534.08,-603.97,258.39 坐下常驻)
-- 常驻：依赖 DBC 补丁（法术 105835/105836 时长改永久，contrib/dbc_patches）。
-- 安全模式：到达 WP5 时一次性批量创建全部 5 个延时事件(205-209)（LINK 链 10→15）；
--           各延时事件触发后只执行动作、不再创建存储事件——
--           避免 SmartAI 遍历 mStoredEvents(vector) 中 push_back 导致迭代器悬挂
--           （C0000420 urand(1,0) 断言崩溃的根因）。
-- =====================================================================

-- 29877《缺乏常识》官方前置为 29907《陈和丽丽》(Requires: Chen and Li Li)
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (29877, 29907)
ON DUPLICATE KEY UPDATE `PrevQuestID` = 29907;

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (56343, 56344);

-- 对话文本
DELETE FROM `creature_text` WHERE `CreatureID` IN (56343, 56204);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Comment`) VALUES
(56343, 0, 0, '我们能在你的农舍落脚吗？我们身上没有多少值钱的东西，但我很乐意和你分享我自酿的啤酒，很有名的哦。', 12, 0, 100, 0, 'Chen - Arrive At Farm'),
(56343, 1, 0, '谢谢！我们不会待得太久。', 12, 0, 100, 0, 'Chen - Reply To Pang'),
(56204, 0, 0, '你们好，陈，丽丽。欢迎你们，但我不需要你的啤酒。', 12, 0, 100, 0, 'Pang - Reply To Chen');

DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (56343, 56344);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
-- ===== 陈（56343）第一段：召唤 → 沿路走到庞家农场（延时事件均由移动事件触发，安全上下文） =====
(56343, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 59, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Just Summoned - Set Walk'),
(56343, 0, 1, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 69, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 527.75, -696.16, 247.28, 0, 'Chen - Just Summoned - Move To WP1'),
(56343, 0, 2, 0, 34, 0, 100, 0, 0, 1, 0, 0, 0, 67, 2, 250, 250, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP1 - Timed Event 2'),
(56343, 0, 3, 0, 59, 0, 100, 0, 2, 0, 0, 0, 0, 69, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 532.19, -684.70, 249.54, 0, 'Chen - Timed 2 - Move To WP2'),
(56343, 0, 4, 0, 34, 0, 100, 0, 0, 2, 0, 0, 0, 67, 3, 250, 250, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP2 - Timed Event 3'),
(56343, 0, 5, 0, 59, 0, 100, 0, 3, 0, 0, 0, 0, 69, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 533.25, -657.58, 255.73, 0, 'Chen - Timed 3 - Move To WP3'),
(56343, 0, 6, 0, 34, 0, 100, 0, 0, 3, 0, 0, 0, 67, 4, 250, 250, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP3 - Timed Event 4'),
(56343, 0, 7, 0, 59, 0, 100, 0, 4, 0, 0, 0, 0, 69, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 532.45, -616.41, 258.77, 0, 'Chen - Timed 4 - Move To WP4'),
(56343, 0, 8, 0, 34, 0, 100, 0, 0, 4, 0, 0, 0, 67, 5, 250, 250, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP4 - Timed Event 5'),
(56343, 0, 9, 0, 59, 0, 100, 0, 5, 0, 0, 0, 0, 69, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 544.22, -607.24, 263.36, 0, 'Chen - Timed 5 - Move To WP5 Pang''s Farm'),
-- ===== 到达 WP5：任务计分 + LINK 链 10→11→12→13→14→15 一次性批量创建 5 个对话延时事件（安全上下文） =====
(56343, 0, 10, 11, 34, 0, 100, 0, 0, 5, 0, 0, 0, 33, 56343, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP5 - Quest Credit 56343 To Invoker'),
(56343, 0, 11, 12, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 205, 5000, 5000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Arrived - Create Timed 205 (Face Pang @5s)'),
(56343, 0, 12, 13, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 206, 5000, 5000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Create Timed 206 (Say Greeting @5s)'),
(56343, 0, 13, 14, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 207, 13000, 13000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Create Timed 207 (Pang Reply @13s)'),
(56343, 0, 14, 15, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 208, 19000, 19000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Create Timed 208 (Say Thanks @19s)'),
(56343, 0, 15, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 209, 24000, 24000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Create Timed 209 (Depart @24s)'),
-- ===== 对话触发（触发后只执行动作，不再创建存储事件 —— 修复崩溃点） =====
(56343, 0, 16, 0, 59, 0, 100, 0, 205, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 19, 56204, 50, 0, 0, 0, 0, 0, 0, 'Chen - Timed 205 - Turn To Face Pang (Dialogue Starts @5s)'),
(56343, 0, 17, 0, 59, 0, 100, 0, 206, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Timed 206 - Say Greeting (@5s)'),
(56343, 0, 18, 0, 59, 0, 100, 0, 207, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 56204, 50, 0, 0, 0, 0, 0, 0, 'Chen - Timed 207 - Pang Talks Back (@13s)'),
(56343, 0, 19, 0, 59, 0, 100, 0, 208, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Timed 208 - Say Thanks (@19s)'),
(56343, 0, 20, 0, 59, 0, 100, 0, 209, 0, 0, 0, 0, 69, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 536.33, -612.04, 258.61, 0, 'Chen - Timed 209 - Move To Farmhouse WP6 (@24s)'),
-- ===== 陈（56343）第二段：走向农舍并坐下常驻（移动事件触发，安全上下文） =====
(56343, 0, 21, 0, 34, 0, 100, 0, 0, 11, 0, 0, 0, 67, 105, 250, 250, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP6 - Timed Event 105'),
(56343, 0, 22, 0, 59, 0, 100, 0, 105, 0, 0, 0, 0, 69, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 535.13, -602.81, 258.38, 0, 'Chen - Timed 105 - Move To Farmhouse WP7'),
(56343, 0, 23, 0, 34, 0, 100, 0, 0, 12, 0, 0, 0, 67, 106, 250, 250, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP7 - Timed Event 106'),
(56343, 0, 24, 0, 59, 0, 100, 0, 106, 0, 0, 0, 0, 69, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 534.08, -603.97, 258.39, 0, 'Chen - Timed 106 - Move To Farmhouse WP8'),
(56343, 0, 25, 0, 34, 0, 100, 0, 0, 13, 0, 0, 0, 17, 13, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Reached WP8 - Sit Down (EMOTE_STATE_SIT), No Despawn'),
-- ===== 丽丽（56344）：延迟 500ms 后跟随陈（dist 2、angle 3 拖在身后），全程不消失 =====
(56344, 0, 0, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 67, 1, 500, 500, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Li Li - Just Summoned - Create Timed 1 (@500ms)'),
(56344, 0, 1, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 29, 2, 3, 0, 0, 0, 0, 19, 56343, 50, 0, 0, 0, 0, 0, 0, 'Li Li - Timed 1 - Follow Chen (dist 2, angle 3 behind)');

-- 丽丽召唤修复：法术 105835（接任务施放，效果0召唤陈、效果2触发 105836 召唤丽丽）。
-- 105836 效果0（召唤 56344）TargetA=46 TARGET_DEST_NEARBY_ENTRY 需要
-- 隐式目标条件（附近有陈 56343）才能定位召唤点；无此行则召唤目标为空、效果被静默跳过，
-- 丽丽永远不会出现。105836 RangeIndex=13（最大射程 50000 码），搜索范围充足。
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1 AND `SourceEntry` = 105836 AND `SourceId` = 0 AND `ElseGroup` = 0;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(13, 1, 105836, 0, 0, 31, 0, 3, 56343, 0, 0, 0, 0, '', 'Summon Li Li (105836) - dest near Chen Stormstout 56343');
