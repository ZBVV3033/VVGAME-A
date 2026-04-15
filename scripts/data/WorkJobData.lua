-- ============================================================================
-- WorkJobData.lua - 职业配置数据（从 WorkSystem.lua 提取）
-- 包含：职业定义、莱德职业、称号、里程碑、制服、知识系统
-- ============================================================================

local M = {}

--- 职业信息映射
M.JOB_DATA = {
    waiter = {
        name = "服务员",
        expVar = "jobWaiterExp",
        levelVar = "jobWaiterLevel",
        wageVar = "waiterWage",
        stat = "LL",
        wageUp = 10,
        unlockVar = "unlockWaiter",
    },
    cleric = {
        name = "见习教士",
        expVar = "jobClericExp",
        levelVar = "jobClericLevel",
        wageVar = "clericWage",
        stat = "LG",
        wageUp = 10,
        unlockVar = "unlockCleric",
    },
    blacksmith = {
        name = "铁匠学徒",
        expVar = "jobBlacksmithExp",
        levelVar = "jobBlacksmithLevel",
        wageVar = "blacksmithWage",
        stat = "NL",
        wageUp = 10,
        unlockVar = "unlockBlacksmith",
    },
    laborer = {
        name = "港口杂工",
        expVar = "jobLaborerExp",
        levelVar = "jobLaborerLevel",
        wageVar = "laborerWage",
        stat = "LL",
        wageUp = 10,
        unlockVar = "unlockLaborer",
    },
    butler = {
        name = "侍从",
        expVar = "butlerExp",
        levelVar = "butlerLevel",
        wageVar = "butlerWage",
        stat = "ML",
        wageUp = 15,
        unlockVar = "unlockButler",
    },
}

--- 莱德职业数据映射
M.LEIDE_JOB_DATA = {
    laborer = {
        expVar = "initialNameLaborerExp",
        levelVar = "initialNameLaborerLevel",
        wageVar = "initialNameLaborerWage",
    },
    waiter = {
        expVar = "initialNameWaiterExp",
        levelVar = "initialNameWaiterLevel",
        wageVar = "initialNameWaiterWage",
    },
    cleric = {
        expVar = "initialNameClericExp",
        levelVar = "initialNameClericLevel",
        wageVar = "initialNameClericWage",
    },
    blacksmith = {
        expVar = "initialNameBlacksmithExp",
        levelVar = "initialNameBlacksmithLevel",
        wageVar = "initialNameBlacksmithWage",
    },
}

-- ==================== 职业称号体系 ====================

--- 每个职业10级称号（基于原作设定，体现从新手到被认可的过程）
M.JOB_TITLES = {
    waiter     = { "新手服务员", "帮工", "熟手服务员", "老练服务员", "酒馆常驻", "辛奇的帮手", "大堂负责人", "资深伙计", "酒馆台柱", "醉鹿招牌" },
    cleric     = { "见习教士", "打杂教士", "正式教士", "熟练教士", "克丽丝的助手", "祈祷引导员", "教堂帮办", "资深教士", "教区助理", "教堂支柱" },
    blacksmith = { "铁匠学徒", "烧火帮工", "打下手的", "初学锻造", "正式学徒", "麦拿拿的徒弟", "熟练铁匠", "独当一面", "半个师傅", "铁匠铺台柱" },
    laborer    = { "港口杂工", "搬货工", "熟练搬运工", "老练杂工", "码头常客", "黑胡子手下", "小队带头人", "码头老手", "黑胡子心腹", "码头顶梁柱" },
    butler     = { "见习侍从", "打杂侍从", "正式侍从", "合格侍从", "少爷身边人", "贴身侍从", "得力侍从", "首席侍从", "少爷心腹", "罗斯巴特家的人" },
}

--- 里程碑等级加成（3/5/7/10级）
M.JOB_LEVEL_BONUSES = {
    waiter = {
        [3]  = { stats = {LL=1},                    wageBonus = 5,  msg = "辛奇开始让你招待重要的客人了。" },
        [5]  = { stats = {LL=1, ML=1},              wageBonus = 10, msg = "「你干得不错。」辛奇难得夸了你一句。" },
        [7]  = { stats = {LL=1, JQ=1},                              msg = "K笑着说你比刚来的时候像样多了。" },
        [10] = { stats = {LL=1, ML=1},                              msg = "醉鹿酒馆少了你，辛奇还真不习惯。" },
    },
    cleric = {
        [3]  = { stats = {LG=1},                    wageBonus = 5,  msg = "克丽丝让你独自负责清晨的祈祷了。" },
        [5]  = { stats = {LG=1, ML=1},              wageBonus = 10, msg = "信众开始习惯你的声音，祈祷时不再东张西望。" },
        [7]  = { stats = {LG=1, JQ=1},                              msg = "克丽丝说你的经文诵读越来越有模有样了。" },
        [10] = { stats = {LG=1, ML=1},                              msg = "教堂少了你，克丽丝一个人还真忙不过来。" },
    },
    blacksmith = {
        [3]  = { stats = {NL=1},                    wageBonus = 5,  msg = "麦拿拿让你试着自己敲了几锤。" },
        [5]  = { stats = {NL=1, LL=1},              wageBonus = 10, msg = "「手还行。」麦拿拿对你的活儿点了点头。" },
        [7]  = { stats = {NL=1, JQ=1},                              msg = "麦拿拿开始让你独自完成简单的订单了。" },
        [10] = { stats = {NL=1, LL=1},                              msg = "麦拿拿说你这个人类小子，手艺还凑合。" },
    },
    laborer = {
        [3]  = { stats = {LL=1},                    wageBonus = 5,  msg = "黑胡子让你带几个新来的工人干活。" },
        [5]  = { stats = {LL=1, NL=1},              wageBonus = 10, msg = "「这小子还行。」黑胡子对码头的人这么说。" },
        [7]  = { stats = {LL=1, JQ=1},                              msg = "黑胡子开始安排你做一些重要的活儿了。" },
        [10] = { stats = {LL=1, NL=1},                              msg = "码头上的人提到你，都竖大拇指。" },
    },
    butler = {
        [3]  = { stats = {ML=1},                    wageBonus = 5,  msg = "小奥瞥了你一眼：「至少不会打翻东西了。」" },
        [5]  = { stats = {ML=1, LG=1},              wageBonus = 15, msg = "小奥不再盯着你做事了，算是一种信任。" },
        [7]  = { stats = {ML=1, JQ=1},                              msg = "「今天的茶还行。」小奥难得没挑你毛病。" },
        [10] = { stats = {ML=1, LG=1},                              msg = "小奥出门的时候，开始习惯带上你了。" },
    },
}

-- ==================== 工作制服系统 ====================

--- 制服数据：每个职业两套制服（等级1获得第一套，等级≥5获得第二套）
M.UNIFORMS = {
    waiter = {
        { id = "uniform_waiter",  name = "醉鹿酒馆围裙",   shortDesc = "系着酒馆围裙",   desc = "一条深棕色的粗布围裙，胸口绣着醉鹿酒馆的标志——一头歪着脑袋的鹿。围裙上隐约沾着酒渍和油点，但洗得还算干净。", level = 1 },
        { id = "uniform_waiter2", name = "醉鹿高级侍者服", shortDesc = "穿着侍者制服",   desc = "一套剪裁合身的侍者制服，深红色马甲搭配白衬衫和黑裤子。袖口缝着醉鹿酒馆的小鹿徽章，比围裙体面多了。", level = 5 },
    },
    cleric = {
        { id = "uniform_cleric",  name = "教堂见习袍",     shortDesc = "穿着见习袍",     desc = "一件素白色的见习教士长袍，布料虽然朴素但浆洗得很挺括。领口处有一枚简单的太阳徽章，标识着见习者的身份。", level = 1 },
        { id = "uniform_cleric2", name = "教堂正式圣袍",   shortDesc = "穿着教堂圣袍",   desc = "一件镶着金色滚边的正式圣袍，质地比见习袍好上不少。胸前的太阳徽章换成了银制的，在光线下微微闪烁。", level = 5 },
    },
    blacksmith = {
        { id = "uniform_blacksmith",  name = "铁匠学徒围裙", shortDesc = "系着铁匠围裙",   desc = "一条厚实的皮围裙，表面满是烧痕和锤击留下的凹痕。腰间挂着一个简易工具袋，是学徒的标配装束。", level = 1 },
        { id = "uniform_blacksmith2", name = "铁匠正式工装", shortDesc = "穿着铁匠工装",   desc = "一套经过改良的铁匠工装，耐火皮革背心搭配护臂，胸口刻着麦拿拿铁匠铺的矮人锤纹章。做工精良，穿着很有范儿。", level = 5 },
    },
    laborer = {
        { id = "uniform_laborer",  name = "码头工人背心",   shortDesc = "穿着码头背心",   desc = "一件洗到发白的粗棉背心，袖口磨得起了毛边。背后用黑墨印着港口管理局的编号，标识这是正式在册的码头工。", level = 1 },
        { id = "uniform_laborer2", name = "码头工头马甲",   shortDesc = "穿着工头马甲",   desc = "一件结实的深蓝色帆布马甲，口袋比普通工服多了好几个。左胸绣着黑胡子工班的船锚标志，这是老手才有资格穿的。", level = 5 },
    },
    butler = {
        { id = "uniform_butler",  name = "侍从见习制服",   shortDesc = "穿着侍从制服",   desc = "一套黑白配色的简素侍从服，立领衬衫搭配黑色长裤。虽然样式朴素，但在罗斯巴特家连这个也是要靠本事才能穿上的。", level = 1 },
        { id = "uniform_butler2", name = "贴身侍从礼服",   shortDesc = "穿着侍从礼服",   desc = "一套剪裁考究的侍从礼服，深灰色配银色纽扣，领口别着罗斯巴特家族的蔷薇胸针。穿上这身衣服，连小奥看你的眼神都不一样了。", level = 5 },
    },
}

-- ==================== 知识系统 ====================

--- 知识定义表（数据驱动）
M.knowledgeDefs = {
    manner      = { name = "礼仪",     stat = "ML", statName = "魅力",  expVar = "mannerExp",      levelVar = "mannerLevel" },
    history     = { name = "历史",     stat = "LG", statName = "灵感",  expVar = "historyExp",     levelVar = "historyLevel" },
    theology    = { name = "神学",     stat = "LG", statName = "灵感",  expVar = "theologyExp",    levelVar = "theologyLevel" },
    botany      = { name = "植物学",   stat = "NL", statName = "耐力",  expVar = "botanyExp",      levelVar = "botanyLevel" },
    repair      = { name = "修理技术", stat = "JQ", statName = "技巧",  expVar = "repairExp",      levelVar = "repairLevel" },
    tactics     = { name = "战术学",   stat = "LL", statName = "力量",  expVar = "tacticsExp",     levelVar = "tacticsLevel" },
    magicTheory = { name = "魔法理论", stat = "LG", statName = "灵感",  expVar = "magicTheoryExp", levelVar = "magicTheoryLevel" },
    cookTheory  = { name = "烹饪学",   stat = "JQ", statName = "技巧",  expVar = "cookTheoryExp",  levelVar = "cookTheoryLevel" },
}

--- 知识ID有序列表（用于UI展示）
M.knowledgeOrder = {
    "manner", "history", "theology", "botany", "repair", "tactics", "magicTheory", "cookTheory"
}

return M
