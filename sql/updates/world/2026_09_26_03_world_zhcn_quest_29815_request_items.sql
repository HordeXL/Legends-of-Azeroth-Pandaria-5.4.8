-- 任务 29815「法医学」（Forensic Science）交任务文本缺失 zhCN 本地化，
-- 玩家交任务时显示英文原文：
--   "I hope you were successful. Our survival here may depend on it."
-- quest_request_items 表中该任务只有英文 CompletionText，
-- quest_request_items_locale 无任何 29815 记录，补充 zhCN 行。
-- 幂等：REPLACE 写入，可重复执行。

REPLACE INTO `quest_request_items_locale` (`ID`, `locale`, `CompletionText`, `VerifiedBuild`)
VALUES (29815, 'zhCN', '希望你已经得手了。我们能不能在这里生存下去，可就全靠它了。', 0);
