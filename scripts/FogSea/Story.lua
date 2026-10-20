-- 雾海号剧本数据；台词与选项以 docs/剧本全文.txt 第七节「完整剧本初稿」为准
-- （docs/给AI的制作说明.md 第 0 节指定的权威版本；第 6 节直接引用的台词与之一致）。
-- 结局沿用 6+1 共 7 条；按制作说明第 11 节，不设第八个隐藏结局，4-3-008 已移除。
-- 共 106 个节点；空单元格保留为空字符串。
-- effect / condition 仅保存原文，不在数据模块中执行或修正规则。

---@class FogSeaStoryNode
---@field speaker string
---@field text string
---@field option string
---@field persona string
---@field note string
---@field effect string
---@field parent string
---@field condition string
---@field ["goto"] string

---@type table<string, FogSeaStoryNode>
local nodes = {
    ["0-1-001"] = { speaker = "程默独白", text = "六点整。汽笛又响了。今天是大海上的第三天。", option = "", persona = "all", note = "开场", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-1-002"] = { speaker = "程默独白", text = "……我好像忘了什么。是昨晚的梦？", option = "", persona = "all", note = "开场", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-2-001"] = { speaker = "程默独白", text = "被窝是暖的。枕边压着半封信。", option = "", persona = "all", note = "热区·床铺", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-2-002"] = { speaker = "程默独白", text = '"快想起来。"没有寄件人。字迹是我自己的。', option = "", persona = "all", note = "热区·信，线索：半封信", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-2-003"] = { speaker = "程默独白", text = '稿纸摊着。最后一页写到一半——"雾海号永远不会靠岸。"（我自己写的？）', option = "", persona = "all", note = "热区·书桌", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-2-004"] = { speaker = "程默独白", text = "合影。我、妈妈、还有……第三个人的脸，是糊的。", option = "", persona = "all", note = "热区·照片墙，露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-3-001"] = { speaker = "程默独白", text = "门锁着。我摸遍口袋——钥匙不见了。", option = "", persona = "all", note = "热区·门", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-3-002"] = { speaker = "程默独白", text = "我昨晚把它放在哪了……", option = "", persona = "all", note = "热区·门", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-3-003"] = { speaker = "程默独白", text = '旧照片。背面有字："窗台的花盆下。"', option = "", persona = "all", note = "热区·抽屉", effect = "线索：旧照片（背面提示）", parent = "", condition = "", ["goto"] = "" },
    ["0-3-004"] = { speaker = "程默独白", text = "钥匙。上面沾着土。……我什么时候把钥匙埋在花盆里了？", option = "", persona = "all", note = "可移动物·花盆", effect = "拾取：客舱钥匙", parent = "", condition = "", ["goto"] = "" },
    ["0-3-005"] = { speaker = "程默独白", text = "咔哒。门开了。甲板的风灌进来。", option = "", persona = "all", note = "使用钥匙·门", effect = "开门→区域1", parent = "", condition = "", ["goto"] = "" },
    ["0-3-006"] = { speaker = "程默独白", text = "我好像把它放在了……窗台那边。", option = "", persona = "all", note = "卡 60 秒提示", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-4-001"] = { speaker = "系统", text = "触碰合照 → 世界翻面（病房）", option = "", persona = "all", note = "锚点切换", effect = "世界切换：客舱→病房；清醒度-8", parent = "", condition = "", ["goto"] = "" },
    ["0-4-002"] = { speaker = "船长影", text = "你又想逃出去了。", option = "", persona = "all", note = "首次畸变演出", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-4-003"] = { speaker = "玩家", text = "", option = "我是不是忘了什么？", persona = "all", note = "共情·关键句", effect = "共情倾向 +2", parent = "0-4-002", condition = "", ["goto"] = "0-4-004" },
    ["0-4-004"] = { speaker = "船长影", text = "你在躲。快想起来。", option = "", persona = "all", note = "共情回应", effect = "", parent = "0-4-003", condition = "", ["goto"] = "" },
    ["0-4-005"] = { speaker = "玩家", text = "", option = "你是谁？为什么装成我妈？", persona = "all", note = "质问·关键句", effect = "质问倾向 +2", parent = "0-4-002", condition = "", ["goto"] = "0-4-006" },
    ["0-4-006"] = { speaker = "船长影", text = "我是……接你回家的人。", option = "", persona = "all", note = "质问回应", effect = "", parent = "0-4-005", condition = "", ["goto"] = "" },
    ["0-4-007"] = { speaker = "玩家", text = "", option = "别怕。我不会走的。", persona = "all", note = "安抚", effect = "安抚倾向 +2", parent = "0-4-002", condition = "", ["goto"] = "0-4-008" },
    ["0-4-008"] = { speaker = "船长影", text = "那就好。那就好。", option = "", persona = "all", note = "安抚回应", effect = "", parent = "0-4-007", condition = "", ["goto"] = "" },
    ["0-5-001"] = { speaker = "程默独白", text = '糖罐。和客舱那罐一模一样……上面刻着"第 7 疗养院"。', option = "", persona = "all", note = "热区·床头柜，露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-5-002"] = { speaker = "系统", text = "触碰糖罐 → 世界翻回客舱", option = "", persona = "all", note = "返回锚点激活", effect = "世界切换：病房→客舱", parent = "", condition = "", ["goto"] = "" },
    ["0-6-001"] = { speaker = "程默独白", text = "手稿的最后一行是空的。程默要写下一章了。", option = "", persona = "all", note = "写作界面", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["0-6-002"] = { speaker = "写作", text = "他决定相信，海会带他回家。", option = "", persona = "all", note = "第一章·三选一", effect = "共情 +2", parent = "", condition = "", ["goto"] = "" },
    ["0-6-003"] = { speaker = "写作", text = "他决定把罗盘砸了，自己掌舵。", option = "", persona = "all", note = "第一章·三选一", effect = "反抗 +2", parent = "", condition = "", ["goto"] = "" },
    ["0-6-004"] = { speaker = "写作", text = "他决定在甲板上看海，什么都不做。", option = "", persona = "all", note = "第一章·三选一", effect = "旁观 +2", parent = "", condition = "", ["goto"] = "" },
    ["1-1-001"] = { speaker = "程默独白", text = "缆绳死死缠着门把手。得找剪钳。", option = "", persona = "all", note = "热区·甲板门", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["1-1-002"] = { speaker = "程默独白", text = "工具箱。剪钳在……锁着的柜子里。", option = "", persona = "all", note = "热区·船员室", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["1-1-003"] = { speaker = "程默独白", text = "钥匙。腥味。我不记得我把剪钳锁起来了。", option = "", persona = "all", note = "热区·桶", effect = "拾取：工具箱钥匙", parent = "", condition = "", ["goto"] = "" },
    ["1-1-004"] = { speaker = "系统", text = "使用剪钳 → 剪断缆绳 → 门开", option = "", persona = "all", note = "使用剪钳·门", effect = "开门→甲板", parent = "", condition = "", ["goto"] = "" },
    ["1-1-005"] = { speaker = "程默独白", text = "剪钳在船员室，我记得。", option = "", persona = "all", note = "卡 60 秒提示", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["1-2-001"] = { speaker = "程默独白", text = '"救救我。我们靠不了岸。"笔迹……又像我自己。', option = "", persona = "all", note = "热区·漂来的信", effect = "线索：求救信", parent = "", condition = "", ["goto"] = "" },
    ["1-2-002"] = { speaker = "玩家", text = "", option = "把信收好，交还给船长影。", persona = "all", note = "解法·共情", effect = "共情倾向 +2；产出：合照碎片", parent = "1-2-001", condition = "", ["goto"] = "1-2-003" },
    ["1-2-003"] = { speaker = "船长影", text = "……这是你写给你的信。", option = "", persona = "all", note = "共情回应", effect = "解锁线索：主治医生的脸", parent = "1-2-002", condition = "", ["goto"] = "" },
    ["1-2-004"] = { speaker = "玩家", text = "", option = "把信撕碎，抛进海。", persona = "all", note = "解法·反抗，播放心跳声", effect = "反抗倾向 +2；产出：海面浮起钥匙", parent = "1-2-001", condition = "", ["goto"] = "1-2-005" },
    ["1-2-005"] = { speaker = "程默独白", text = "海面浮起一把钥匙。", option = "", persona = "all", note = "反抗产出·储物箱钥匙", effect = "解锁线索：入院单据", parent = "1-2-004", condition = "", ["goto"] = "" },
    ["1-2-006"] = { speaker = "玩家", text = "", option = "烧掉信。", persona = "all", note = "解法·旁观，需火柴", effect = "旁观倾向 +2；产出：航迹坐标", parent = "1-2-001", condition = "", ["goto"] = "1-2-007" },
    ["1-2-007"] = { speaker = "程默独白", text = "灰烬落成一条航迹的坐标。", option = "", persona = "all", note = "旁观产出", effect = "解锁线索：海域循环", parent = "1-2-006", condition = "", ["goto"] = "" },
    ["1-3-001"] = { speaker = "船长影", text = "你又在收集证据了。像上次一样。", option = "", persona = "all", note = "对话组根", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["1-3-002"] = { speaker = "服务员影", text = "该吃药了。该吃药了。该吃药了。", option = "", persona = "all", note = "重复台词=露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["1-3-003"] = { speaker = "玩家", text = "", option = "你们也困在这条船上吗？", persona = "all", note = "三选一", effect = "共情倾向 +1~2", parent = "1-3-002", condition = "", ["goto"] = "" },
    ["1-3-004"] = { speaker = "玩家", text = "", option = "你们根本不是乘客。", persona = "all", note = "三选一", effect = "质问倾向 +1~2", parent = "1-3-002", condition = "", ["goto"] = "" },
    ["1-3-005"] = { speaker = "玩家", text = "", option = "我不怕你们。你们也不怕我，对吧。", persona = "all", note = "三选一", effect = "安抚倾向 +1~2", parent = "1-3-002", condition = "", ["goto"] = "" },
    ["1-4-001"] = { speaker = "程默独白", text = '船长帽。帽檐内侧绣着"第 7 疗养院"。', option = "", persona = "all", note = "热区·走廊衣架，露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["1-4-002"] = { speaker = "系统", text = "触碰船长帽 → 返回甲板", option = "", persona = "all", note = "返回锚点激活", effect = "世界切换：走廊→甲板", parent = "", condition = "", ["goto"] = "" },
    ["1-5-001"] = { speaker = "写作", text = "他替落水的人披上外套。", option = "", persona = "all", note = "第二章·三选一", effect = "共情 +2", parent = "", condition = "", ["goto"] = "" },
    ["1-5-002"] = { speaker = "写作", text = "他剪断最后一根缆绳。", option = "", persona = "all", note = "第二章·三选一", effect = "反抗 +2", parent = "", condition = "", ["goto"] = "" },
    ["1-5-003"] = { speaker = "写作", text = "他数着海鸟，一只，两只，没有第三只。", option = "", persona = "all", note = "第二章·三选一", effect = "旁观 +2", parent = "", condition = "", ["goto"] = "" },
    ["2-1-001"] = { speaker = "程默独白", text = "香槟塔堵着门。直接推会全碎……得先拿走桌布。", option = "", persona = "all", note = "热区·宴会厅门", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["2-1-002"] = { speaker = "系统", text = "取桌布 → 抽桌布 → 塔倒，门开", option = "", persona = "all", note = "使用桌布", effect = "开门→宴会厅", parent = "", condition = "", ["goto"] = "" },
    ["2-1-003"] = { speaker = "程默独白", text = "桌布。把桌布抽掉。", option = "", persona = "all", note = "卡 60 秒提示", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["2-2-001"] = { speaker = "程默独白", text = "药瓶。贴着餐牌，装着药。", option = "", persona = "all", note = "热区·餐车", effect = "线索：药瓶", parent = "", condition = "", ["goto"] = "" },
    ["2-2-002"] = { speaker = "玩家", text = "", option = "帮服务员影整理药架。", persona = "all", note = "解法·共情", effect = "共情倾向 +2；产出：零钱与便签", parent = "2-2-001", condition = "", ["goto"] = "2-2-003" },
    ["2-2-003"] = { speaker = "服务员影", text = "谢谢你……", option = "", persona = "all", note = "共情回应", effect = "解锁线索：护士的立场（便签背字）", parent = "2-2-002", condition = "", ["goto"] = "" },
    ["2-2-004"] = { speaker = "玩家", text = "", option = "掀翻药架。", persona = "all", note = "解法·反抗，播散落声", effect = "反抗倾向 +2；产出：针头", parent = "2-2-001", condition = "", ["goto"] = "2-2-005" },
    ["2-2-005"] = { speaker = "程默独白", text = "混在瓶里的注射器针头滚出来。", option = "", persona = "all", note = "反抗产出", effect = "解锁线索：治疗手段", parent = "2-2-004", condition = "", ["goto"] = "" },
    ["2-2-006"] = { speaker = "玩家", text = "", option = "只拿需要的药瓶，看服务员影反应。", persona = "all", note = "解法·旁观", effect = "旁观倾向 +2；产出：每日发药单", parent = "2-2-001", condition = "", ["goto"] = "2-2-007" },
    ["2-2-007"] = { speaker = "服务员影", text = "你……不一样。", option = "", persona = "all", note = "旁观回应", effect = "解锁线索：剂量与暗示", parent = "2-2-006", condition = "", ["goto"] = "" },
    ["2-3-001"] = { speaker = "船客影", text = "这条船真漂亮。你说，它为什么不停下来？", option = "", persona = "all", note = "对话组根", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["2-3-002"] = { speaker = "服务员影", text = "宴会开始了。宴会开始了。", option = "", persona = "all", note = "重复台词=露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["2-3-003"] = { speaker = "玩家", text = "", option = "因为有人不想让船停下来。", persona = "all", note = "三选一", effect = "共情倾向 +1~2", parent = "2-3-002", condition = "", ["goto"] = "" },
    ["2-3-004"] = { speaker = "玩家", text = "", option = "你看清楚过外面的海吗？", persona = "all", note = "三选一", effect = "质问倾向 +1~2", parent = "2-3-002", condition = "", ["goto"] = "" },
    ["2-3-005"] = { speaker = "玩家", text = "", option = "船会停的。总会的。", persona = "all", note = "三选一", effect = "安抚倾向 +1~2", parent = "2-3-002", condition = "", ["goto"] = "" },
    ["2-4-001"] = { speaker = "程默独白", text = '香槟杯。杯底刻着药名："氯氮平。"', option = "", persona = "all", note = "热区·药台，露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["2-4-002"] = { speaker = "系统", text = "触碰香槟杯 → 返回宴会厅", option = "", persona = "all", note = "返回锚点激活", effect = "世界切换：治疗区→宴会厅", parent = "", condition = "", ["goto"] = "" },
    ["2-5-001"] = { speaker = "写作", text = "他给同桌的人斟满真正的酒。", option = "", persona = "all", note = "第三章·三选一", effect = "共情 +2", parent = "", condition = "", ["goto"] = "" },
    ["2-5-002"] = { speaker = "写作", text = "他掀翻整张长桌。", option = "", persona = "all", note = "第三章·三选一", effect = "反抗 +2", parent = "", condition = "", ["goto"] = "" },
    ["2-5-003"] = { speaker = "写作", text = "他坐在角落里，看所有人举杯。", option = "", persona = "all", note = "第三章·三选一", effect = "旁观 +2", parent = "", condition = "", ["goto"] = "" },
    ["3-1-001"] = { speaker = "程默独白", text = "密码锁。四位数字。我好像在哪见过……", option = "", persona = "all", note = "热区·驾驶台门", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["3-1-002"] = { speaker = "程默独白", text = "2317。", option = "", persona = "all", note = "线索册", effect = "线索：药瓶标签（密码 2317）", parent = "", condition = "", ["goto"] = "" },
    ["3-1-003"] = { speaker = "系统", text = "输入 2317 → 门开", option = "", persona = "all", note = "密码盘", effect = "开门→驾驶台", parent = "", condition = "", ["goto"] = "" },
    ["3-1-004"] = { speaker = "船长影（低语）", text = "门后传来很轻的一声低语：'……你又来了。'", option = "", persona = "all", note = "失败反馈", effect = "密码错误3次触发，清醒度-2（不致命）", parent = "", condition = "", ["goto"] = "" },
    ["3-1-005"] = { speaker = "程默独白", text = "药瓶上……我见过那串数字。", option = "", persona = "all", note = "卡 60 秒提示", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["3-2-001"] = { speaker = "系统", text = "锁定人格 → 立绘/语音切换", option = "", persona = "all", note = "按解谜顺序+答案+写法+回应综合判定", effect = "人格锁定（此后差分生效）", parent = "", condition = "", ["goto"] = "" },
    ["3-2-002"] = { speaker = "船长影", text = "心软的那位。我们，该靠岸了。", option = "", persona = "信者", note = "差分：称呼“心软的那位”", effect = "", parent = "3-2-001", condition = "", ["goto"] = "" },
    ["3-2-003"] = { speaker = "船长影", text = "掀桌的那位。这船，从现在起听你的。", option = "", persona = "叛者", note = "差分：称呼“掀桌的那位”", effect = "", parent = "3-2-001", condition = "", ["goto"] = "" },
    ["3-2-004"] = { speaker = "船长影", text = "看戏的那位。你还要，看到什么时候。", option = "", persona = "观者", note = "差分：称呼“看戏的那位”", effect = "", parent = "3-2-001", condition = "", ["goto"] = "" },
    ["3-3-001"] = { speaker = "程默独白", text = '"患者程默，入院一年。主诉：妄想、解离。拟长期留观。"', option = "", persona = "信者", note = "差分动作：钥匙开档案柜取日志", effect = "信者倾向 +2；清醒度-6；解锁核心线索：我是病人", parent = "", condition = "", ["goto"] = "" },
    ["3-3-002"] = { speaker = "程默独白", text = "玻璃、铁、纸片。碎了一地。假的！全是假的！", option = "", persona = "叛者", note = "差分动作：砸碎罗盘与日志柜", effect = "叛者倾向 +2；清醒度-6；解锁核心线索：我的病", parent = "", condition = "", ["goto"] = "" },
    ["3-3-003"] = { speaker = "程默独白", text = "倒影里，文字一行行浮现。我看完，没有碰任何东西。", option = "", persona = "观者", note = "差分动作：玻璃倒影读取", effect = "观者倾向 +2；清醒度-6；解锁核心线索：我是病人", parent = "", condition = "", ["goto"] = "" },
    ["3-4-001"] = { speaker = "自己的镜像", text = "你以为你是乘客。你从来不是。", option = "", persona = "all", note = "对话组根", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["3-4-002"] = { speaker = "自己的镜像", text = "你写的那艘船，是雾海号；你写的那个人，是你自己。", option = "", persona = "all", note = "露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["3-4-003"] = { speaker = "玩家", text = "", option = "那我还能回去吗？", persona = "all", note = "三选一", effect = "共情倾向 +1~2", parent = "3-4-002", condition = "", ["goto"] = "3-4-004" },
    ["3-4-004"] = { speaker = "自己的镜像", text = "回不去。只能醒来。", option = "", persona = "all", note = "共情回应", effect = "", parent = "3-4-003", condition = "", ["goto"] = "" },
    ["3-4-005"] = { speaker = "玩家", text = "", option = "你有什么资格说我是病人？", persona = "all", note = "三选一", effect = "质问倾向 +1~2", parent = "3-4-002", condition = "", ["goto"] = "3-4-006" },
    ["3-4-006"] = { speaker = "自己的镜像", text = "因为我是你。", option = "", persona = "all", note = "质问回应", effect = "", parent = "3-4-005", condition = "", ["goto"] = "" },
    ["3-4-007"] = { speaker = "玩家", text = "", option = "那就先陪我看看海。", persona = "all", note = "三选一", effect = "安抚倾向 +1~2", parent = "3-4-002", condition = "", ["goto"] = "3-4-008" },
    ["3-4-008"] = { speaker = "自己的镜像", text = "……好。", option = "", persona = "all", note = "安抚回应", effect = "", parent = "3-4-007", condition = "", ["goto"] = "" },
    ["3-5-001"] = { speaker = "程默独白", text = "一张船票。乘客名：程默。出发港：第 7 疗养院。", option = "", persona = "all", note = "热区·抽屉，露馅点", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["3-5-002"] = { speaker = "系统", text = "触碰船票 → 返回驾驶台", option = "", persona = "all", note = "返回锚点激活", effect = "世界切换：档案室→驾驶台", parent = "", condition = "", ["goto"] = "" },
    ["4-1-001"] = { speaker = "程默独白", text = "门锁着。需要救生艇的钥匙。", option = "", persona = "all", note = "热区·出口门", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["4-1-002"] = { speaker = "程默独白", text = "上锁的日记。夹层里……是钥匙。", option = "", persona = "all", note = "热区·船长室抽屉", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["4-1-003"] = { speaker = "程默独白", text = "（读完日记）……夹层里，是钥匙。", option = "", persona = "信者", note = "差分动作：读日记取钥匙", effect = "拾取：救生艇钥匙", parent = "", condition = "", ["goto"] = "" },
    ["4-1-004"] = { speaker = "程默独白", text = "（隔着玻璃读完日记）……夹层里，是钥匙。", option = "", persona = "观者", note = "差分动作：读日记取钥匙", effect = "拾取：救生艇钥匙", parent = "", condition = "", ["goto"] = "" },
    ["4-1-005"] = { speaker = "程默独白", text = "（砸开抽屉）钥匙。归我了。", option = "", persona = "叛者", note = "差分动作：砸开抽屉取钥匙", effect = "拾取：救生艇钥匙", parent = "", condition = "", ["goto"] = "" },
    ["4-1-006"] = { speaker = "系统", text = "拾取救生艇钥匙 → 门可用（需证据≥70%）", option = "", persona = "all", note = "终局门判定", effect = "条件：证据≥11/15 后出口门亮灯", parent = "", condition = "", ["goto"] = "" },
    ["4-2-001"] = { speaker = "程默独白", text = "雾散了。岸在门后。", option = "", persona = "all", note = "终局演出", effect = "", parent = "", condition = "", ["goto"] = "" },
    ["4-2-002"] = { speaker = "玩家", text = "", option = "靠岸（推门）", persona = "all", note = "终局选择", effect = "→ 结局：醒来/不甘/清醒地醒来", parent = "4-2-001", condition = "persona=信者", ["goto"] = "" },
    ["4-2-003"] = { speaker = "玩家", text = "", option = "留下（转身）", persona = "all", note = "终局选择", effect = "→ 结局：循环/永眠/消散", parent = "4-2-001", condition = "persona=叛者/观者", ["goto"] = "" },
    ["4-3-001"] = { speaker = "旁白", text = '门开了。白色的天花板，消毒水的味道。"程默，你醒了。"我攥着那半封信，点了点头。我是病人。但我在好起来。', option = "", persona = "信者", note = "发现·接纳", effect = "", parent = "", condition = "人格=信者 × 靠岸", ["goto"] = "" },
    ["4-3-002"] = { speaker = "旁白", text = '门开了。医生向我伸出手。我打开他的手："我不是病人。我只是……上错了船。"窗外没有海。只有一扇被焊死的窗。', option = "", persona = "叛者", note = "发现·否认", effect = "", parent = "", condition = "人格=叛者 × 靠岸", ["goto"] = "" },
    ["4-3-003"] = { speaker = "旁白", text = '门开了。我看见查房记录，看见"氯氮平"，看见一年。我把雾海号写进了小说的最后一页，合上本子，平静地走出去。', option = "", persona = "观者", note = "发现·清醒", effect = "", parent = "", condition = "人格=观者 × 靠岸", ["goto"] = "" },
    ["4-3-004"] = { speaker = "旁白", text = "我转身，回到客舱。明天六点，汽笛还会响。合照上那个模糊的人，会慢慢重新清晰起来——然后，我会再一次忘记。", option = "", persona = "信者", note = "迷失·温柔", effect = "", parent = "", condition = "人格=信者 × 留下", ["goto"] = "" },
    ["4-3-005"] = { speaker = "旁白", text = "我把日记烧了，把救生艇钥匙扔进海里。现在雾海号归我管了。想靠岸？我说了算。", option = "", persona = "叛者", note = "迷失·主宰", effect = "", parent = "", condition = "人格=叛者 × 留下", ["goto"] = "" },
    ["4-3-006"] = { speaker = "旁白", text = "我留在甲板上，看雾起雾散。船客们日复一日地举杯。我是雾海号上唯一不再写故事的人——我成了故事本身。", option = "", persona = "观者", note = "迷失·旁观", effect = "", parent = "", condition = "人格=观者 × 留下", ["goto"] = "" },
    ["4-3-007"] = { speaker = "旁白", text = '猛地睁开眼。天花板、药瓶、白墙。有人问我："你还记得船吗？"我摇摇头。海面在记忆里起雾，什么都想不起来。', option = "", persona = "all", note = "发现·未理解，返回标题重开", effect = "", parent = "", condition = "清醒度=0（失败）", ["goto"] = "" },
}

-- 按 4-3-001..007 顺序排列；不设第八个隐藏结局（制作说明第 11 节）。
-- 终局靠岸/留下对三人格各有一个结局；失败不要求特定人格。
local endings = {
    { id = "4-3-001", name = "醒来", subtitle = "发现·接纳", persona = "信者", choice = "靠岸", text = nodes["4-3-001"].text },
    { id = "4-3-002", name = "不甘", subtitle = "发现·否认", persona = "叛者", choice = "靠岸", text = nodes["4-3-002"].text },
    { id = "4-3-003", name = "清醒地醒来", subtitle = "发现·清醒", persona = "观者", choice = "靠岸", text = nodes["4-3-003"].text },
    { id = "4-3-004", name = "循环", subtitle = "迷失·温柔", persona = "信者", choice = "留下", text = nodes["4-3-004"].text },
    { id = "4-3-005", name = "永眠", subtitle = "迷失·主宰", persona = "叛者", choice = "留下", text = nodes["4-3-005"].text },
    { id = "4-3-006", name = "消散", subtitle = "迷失·旁观", persona = "观者", choice = "留下", text = nodes["4-3-006"].text },
    { id = "4-3-007", name = "惊醒", subtitle = "发现·未理解", persona = "all", choice = "失败", text = nodes["4-3-007"].text },
}

-- writing[章节][选项]：三个章节，每章依次为共情 / 反抗 / 旁观。
-- 沿用节点 ID 读取正文，避免结局回放与写作选项出现文案差异。
local writing = {
    { nodes["0-6-002"].text, nodes["0-6-003"].text, nodes["0-6-004"].text },
    { nodes["1-5-001"].text, nodes["1-5-002"].text, nodes["1-5-003"].text },
    { nodes["2-5-001"].text, nodes["2-5-002"].text, nodes["2-5-003"].text },
}

return { nodes = nodes, endings = endings, writing = writing }
