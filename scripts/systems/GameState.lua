-- ============================================================================
-- GameState.lua - 游戏状态管理（悠闲悠哉life）
-- 所有游戏变量的中心存储，对应 Twine StoryInit
-- ============================================================================

local GameState = {}

--- 初始化所有游戏状态
function GameState.init()
    local S = {}

    -- 玩家名字
    S.PNN = ""

    -- 时间系统
    S.year = 499
    S.month = 1
    S.day = 1
    S.hour = 8
    S.minute = 0
    S.inPrologue = false  -- 序章标记（序章期间不显示具体日期）

    -- 金钱
    S.money = 0

    -- 五维属性
    S.LL = 1   -- 力量
    S.LG = 1   -- 灵感
    S.ML = 3   -- 魅力
    S.NL = 2   -- 耐力
    S.JQ = 1   -- 技巧

    -- 个性
    S.YG = 0   -- 勇敢
    S.LJ = 0   -- 冷静
    S.BZ = 0   -- 暴躁
    S.ZL = 0   -- 智力

    -- 声望与邪恶
    S.reputation = 0   -- 声望（完成正面事件增加）
    S.evilness = 0     -- 邪恶（作恶增加）

    -- 外观
    S.hairstyle = "及肩长发"   -- 发型（序章默认）
    S.hairColor = "淡黄色"      -- 发色（序章默认）
    S.eyeColor  = "赤色"        -- 瞳色（序章默认）
    S.appearance = "普通"       -- 容貌描述

    -- 魔法适应性
    S.ASX = 1  -- 暗属性
    S.GSX = 5  -- 光属性
    S.MSY = 1  -- 木属性

    -- 当前位置
    S.currentRoom = "客厅"
    S.currentArea = "square"
    S.currentPassage = "命名"

    -- 莱德（主要NPC）
    S.initialName = "莱德"
    S.initialNameAffection = 0
    S.initialNameLevel = 1
    S.initialNameInvited = false
    S.initialNameAtHome = false
    S.initialNameTalkCount = 0
    S.initialNameMealCount = 0
    S.initialNameSleepTogether = false
    S.initialName_LL = 2
    S.initialName_LG = 2
    S.initialName_ML = 2
    S.initialName_NL = 2
    S.initialName_JQ = 2
    S.initialNameLaborerExp = 0
    S.initialNameLaborerLevel = 1
    S.initialNameLaborerWage = 20
    S.initialNameWaiterExp = 0
    S.initialNameWaiterLevel = 1
    S.initialNameWaiterWage = 30
    S.initialNameClericExp = 0
    S.initialNameClericLevel = 1
    S.initialNameClericWage = 15
    S.initialNameBlacksmithExp = 0
    S.initialNameBlacksmithLevel = 1
    S.initialNameBlacksmithWage = 20
    S.initialNameSavings = 0
    S.initialNameInParty = false    -- 莱德是否入队（战斗）

    -- K（精灵天使·神使/教会枢机）
    S.kAffection = 0
    S.kLevel = 1
    S.kTalkCount = 0
    S.kMealCount = 0
    S.kMet = false
    S.kVisiting = false
    S.kDateAvailable = true
    S.K_LL = 4
    S.K_LG = 6
    S.K_ML = 2
    S.K_NL = 1
    S.K_JQ = 3

    -- 玩家职业系统
    S.jobWaiterExp = 0
    S.jobWaiterLevel = 1
    S.jobClericExp = 0
    S.jobClericLevel = 1
    S.jobBlacksmithExp = 0
    S.jobBlacksmithLevel = 1
    S.jobLaborerExp = 0
    S.jobLaborerLevel = 1
    S.waiterWage = 50
    S.clericWage = 20
    S.blacksmithWage = 30
    S.laborerWage = 50

    -- 侍从（高级职业）
    S.butlerExp = 0
    S.butlerLevel = 1
    S.butlerWage = 80

    -- 生活等级
    S.lifeLevel = 1
    S.lifeExp = 0
    S.attrPoints = 0

    -- 职业解锁
    S.unlockWaiter = false
    S.unlockCleric = false
    S.unlockBlacksmith = false
    S.unlockLaborer = false
    S.unlockButler = false
    S.firstJobBonusClaimed = false  -- 首次打工政府就业补贴

    -- 次要NPC好感度
    S.npcSinchi = 0       -- 辛奇（酒馆老板）
    S.npcClarice = 0      -- 克丽丝（修女）
    S.npcMacnana = 0      -- 麦拿拿（矮人铁匠）
    S.npcBlackbeard = 0   -- 黑胡子（港口头目）

    -- 新增小镇NPC
    S.npcEileen = 0       -- 艾琳（流浪画家）
    S.npcEileenMet = false
    S.npcOldYugen = 0     -- 老尤金（退休水手/说书人）
    S.npcOldYugenMet = false
    S.npcLillian = 0      -- 莉莉安（花店老板娘）
    S.npcLillianMet = false
    S.npcDario = 0        -- 达里奥（流浪乐手）
    S.npcDarioMet = false
    S.npcGrandmaVera = 0  -- 薇拉奶奶（主城区老太太）
    S.npcGrandmaVeraMet = false

    -- 乌列尔（诺兰的亲哥哥，暗中守护）
    S.urielAffection = 0
    S.urielLevel = 1
    S.urielMet = false        -- 是否正式见面
    S.urielHelpCount = 0      -- 乌列尔暗中帮助次数
    S.urielLetterCount = 0    -- 收到信件数

    -- 黑帮少主
    S.gangBossAffection = 0
    S.gangBossLevel = 1
    S.gangBossMet = false
    S.npcGangBoss = 0         -- 次要NPC好感池

    -- 新增小镇NPC（第二批）
    S.npcBrotherAmos = 0      -- 阿莫斯修士（教堂图书管理员）
    S.npcBrotherAmosMet = false
    S.npcMerchantRoy = 0      -- 罗伊（走私商人/杂货贩子）
    S.npcMerchantRoyMet = false
    S.npcSisterMina = 0       -- 米娜（孤儿院修女/克丽丝的同事）
    S.npcSisterMinaMet = false

    -- 新增小镇NPC（第三批）
    S.npcFelix = 0            -- 费利克斯（面包师）
    S.npcFelixMet = false
    S.npcIsabella = 0         -- 伊莎贝拉（草药医生）
    S.npcIsabellaMet = false
    S.npcJasper = 0           -- 贾斯帕（守夜人）
    S.npcJasperMet = false
    S.npcNora = 0             -- 诺拉（裁缝）
    S.npcNoraMet = false
    S.npcSebastian = 0        -- 塞巴斯蒂安（流浪学者）
    S.npcSebastianMet = false
    S.npcXiaomei = 0          -- 小梅（鱼贩女孩）
    S.npcXiaomeiMet = false
    S.felixBreadToday = false -- 费利克斯今日免费面包

    -- 小镇事件标记
    S.townEventSeen = {}  -- 记录今天已看到的事件ID，每天重置
    S.townEventCount = 0  -- 今日已触发事件数

    -- 主线任务
    S.mqStage = 0           -- 0=未开始 1=听到传闻 2=调查完毕 3=潜入中 4=逃离 5=完成
    S.mqInfilMethod = ""    -- 潜入方式: charm/stealth/secret/wait
    S.mqLockMethod = ""     -- 开锁方式: pick/key/force/light/search
    S.mqOamelChoice = ""    -- 奥梅尔选择: ignore/help/threaten
    S.mqAlertLevel = 0      -- 警戒等级（影响逃离难度）
    S.mqInvestSources = 0   -- 已调查信息源数量
    S.mqHasLockpick = false -- 是否有黑胡子给的铁片
    S.mqKnowsSecretDoor = false -- 是否知道暗门
    S.mqSettled = false     -- 营救完成，安顿下来

    -- 家具/道具
    S.candles = 0
    S.renamed = false
    S.renaming = false
    S.secretNote = false
    S.gameAware = false
    S.nobleSecret = false

    -- 小猫
    S.catPresent = false
    S.catAffection = 0
    S.catAdopted = false
    S.catName = "小猫"
    S.catFedToday = false
    S.catPettedToday = false

    -- 约会系统
    S.leiDeDateAvailable = true
    S.leiDeDateLocation = ""
    S.dateLocation = ""
    S.dateTarget = ""
    S.dateChoice = 0
    S.lastDateLocation = ""
    S.meetLocationVar = ""
    S.meetActionVar = ""
    S.randomEvent = 0
    S.workResult = ""
    S.selectedTopic = ""
    S.currentEvent = nil

    -- 日志/话题
    S.dateLogs = {}
    S.recentEvents = {}    -- 最近动态（最多5条）

    -- 关键词聊天系统
    S.collectedKeywords = {}       -- { keywordId = true }
    S.chattedKeywordsToday = {}    -- { "charKey:kwId" = true }
    S.keywordChatCount = 0

    -- 家具解锁
    S.furnitureCoffee = false
    S.furnitureBible = false
    S.furnitureDummy = false
    S.furnitureSeagull = false

    -- ==================== 家庭生活系统 ====================
    S.homeEventSeen = {}       -- 今日已触发的家庭事件ID
    S.homeEventCount = 0       -- 今日家庭事件计数
    S.oamelVisitingToday = false  -- 奥梅尔今日是否来访
    S.oamelVisitHandled = false   -- 奥梅尔来访是否已处理
    S.urielLetterPending = false  -- 是否有未读乌列尔信件
    S.urielLetterHandled = false  -- 今日信件是否已处理
    S.kGiftLamp = false           -- K是否已赠送小夜灯
    S.kMaskRevealed = false       -- K是否已摘过面具

    -- ==================== 支线任务追踪 ====================
    S.quest_painting = 0       -- 失窃的画：0=未触发 1=已触发 2=调查中 3=对质 9=完成
    S.quest_watchman = 0       -- 深夜守望：0=未触发 1=跟踪中 2=发现真相 9=完成
    S.quest_vera = 0           -- 薇拉的秘密：0=未触发 1=找书中 2=发现真相 9=完成
    S.quest_underflow = 0      -- 花街暗流：0=未触发 1=了解中 2=选边 9=完成
    S.quest_sourdough = 0      -- 消失的酵母：0=未触发 1=调查中 2=发现真相 9=完成
    S.quest_moongrass = 0      -- 月光草：0=未触发 1=采集中 2=炼药中 9=完成
    S.quest_reddress = 0       -- 红婚纱：0=未触发 1=寻找布料 2=缝制中 9=完成
    S.quest_seasong = 0        -- 海之声：0=未触发 1=追踪中 2=发现真相 9=完成
    S.quest_oldlamp = 0        -- 旧灯之约：0=未触发 1=寻找零件 2=修复中 9=完成

    -- ==================== 切磋与城内战斗 ====================
    S.sparringCount = 0        -- 与莱德切磋次数
    S.sparringToday = false    -- 今日是否已切磋
    S.townBattleToday = 0      -- 今日城内战斗次数

    -- ==================== 主线第二章：阶级裂痕 ====================
    S.mq2Route = 0             -- 路线选择：0=未选 1=黑帮线 2=调停线 3=贵族线
    S.mq2RouteProgress = 0     -- 路线子任务完成进度（0-3）
    S.mq2CoatChoice = 0        -- 外套告白：0=未触发 1=温柔回应 2=回避 3=反问
    S.mq2DarkChurchKnow = false -- 是否发现暗教会线索
    S.mq2UrielMet = false      -- 是否已遇见乌列尔
    S.mq2NobleDebt = 0         -- 贵族债务线索收集数（0-3）
    S.mq2GangTrust = 0         -- 黑帮信任积累（0-10）
    S.mq2MediateTrust = 0     -- 调停信任积累（0-10）
    S.mq2RiotJoined = false    -- 是否参与了抗议/暴动
    S.mq2ConfrontNoble = false -- 是否正面对抗过贵族
    S.mq2SealClue = 0          -- 封印线索收集数（0-3）

    -- ==================== 主线第三章：真相之光 ====================
    S.mq3Ending = 0            -- 结局编号：0=未定 1=打破壁垒 2=革命 3=改良 4=牺牲 5=隐藏
    S.mq3TruthLevel = 0        -- 真相揭露程度（0-5）
    S.mq3FatherSecret = false  -- 是否知道父亲与太阳神的交易
    S.mq3AngelPact = false     -- 是否了解天使契约
    S.mq3UrielAlliance = 0     -- 乌列尔立场：0=未定 1=支持诺兰 2=中立 3=对立
    S.mq3FinalChoice = 0       -- 最终抉择：0=未选
    S.mq3LeideSacrifice = false -- 莱德是否愿意牺牲
    S.mq3KReveal = false       -- K的真实身份是否揭露

    -- 好感度深度互动标记
    S.leide_scar_seen = false     -- 是否看过莱德伤疤事件
    S.leide_birthday_done = false -- 是否触发过生日事件
    S.oamel_asleep_seen = false   -- 奥梅尔睡着事件

    -- 地区发现记录
    S.hasRecordedPort = false
    S.hasRecordedMainCity = false
    S.hasRecordedGarden = false
    S.hasRecordedChurch = false
    S.hasRecordedSmithy = false
    S.hasRecordedTavern = false
    S.hasRecordedCat = false

    -- ==================== 生存属性 ====================
    S.satiety = 80       -- 饱食度 0-100（80起始）
    S.fatigue = 0        -- 疲劳 0-100（0起始，越高越累）
    S.stress = 0         -- 压力 0-100（0起始，越高越焦虑）
    S.cleanliness = 90   -- 清洁度 0-100（90起始，越低越脏）
    S.outfit = "casual"  -- 当前着装：casual/uniform_xxx/formal/pajamas
    S.ownedUniforms = {} -- 已拥有的制服 { uniform_waiter=true, ... }

    -- ==================== 烹饪系统 ====================
    S.cookingExp = 0
    S.cookingLevel = 0   -- 0=未学习 1=入门 2=熟练 3=精通
    S.knownRecipes = {}  -- 已学会的食谱名列表
    S.stallOpen = false  -- 是否开了小摊
    S.stallRevenue = 0   -- 今日小摊收入
    S.stallDayCount = 0  -- 累计出摊天数
    -- 食材背包 { name = count }
    S.ingredients = {}

    -- ==================== 种植系统 ====================
    -- 家门口3块地：每块 { crop, plantDay, stage, watered }
    S.farmPlots = {
        { crop = nil, plantDay = 0, stage = 0, watered = false },
        { crop = nil, plantDay = 0, stage = 0, watered = false },
        { crop = nil, plantDay = 0, stage = 0, watered = false },
    }
    S.farmSeeds = {}     -- 种子背包 { name = count }

    -- ==================== 社区大学 ====================
    S.uniEnrolled = false       -- 是否已入学
    S.uniMajor = ""             -- 专业: warrior/mage/theology/cooking
    S.uniMajorName = ""         -- 专业中文名
    S.uniLevel = 0              -- 学业等级 0-5
    S.uniExp = 0                -- 学业经验
    S.uniClassesToday = 0       -- 今日已上课次数
    S.uniTotalClasses = 0       -- 累计上课次数
    -- 大学专业战斗加成（随等级累积）
    S.uniCombatBonus_phys = 0   -- 战士学：物理伤害百分比加成
    S.uniCombatBonus_magic = 0  -- 魔法学：魔法伤害百分比加成
    S.uniCombatBonus_mdef = 0   -- 神学：魔法抗性加成
    -- 多专业系统（新）
    S.uniMajors = {}            -- 已报名专业列表（最多2个），如 {"warrior","mage"}
    S.uniMajorData = {}         -- 各专业数据 { warrior = {level=0,exp=0,totalClasses=0}, ... }
    S.uniAttendedToday = {}     -- 今日已上过的课程时段 { "warrior_1_9" = true }

    -- 采集物品（森林等）
    S.forageItems = {}          -- { ["野莓"] = 3, ["薄荷草"] = 1, ... }

    -- 知识系统
    S.mannerExp = 0
    S.mannerLevel = 1
    S.historyExp = 0
    S.historyLevel = 1
    S.theologyExp = 0
    S.theologyLevel = 0
    S.botanyExp = 0
    S.botanyLevel = 0
    S.repairExp = 0
    S.repairLevel = 0
    S.tacticsExp = 0
    S.tacticsLevel = 0
    S.magicTheoryExp = 0
    S.magicTheoryLevel = 0
    S.cookTheoryExp = 0
    S.cookTheoryLevel = 0

    -- 书籍
    S.hasMannerBook = false
    S.hasHistoryBook = false
    S.hasOsmiaBook = false
    S.mannerBookReadCount = 0
    S.historyBookReadCount = 0
    S.osmiaBookReadCount = 0
    S.mannerFirstReward = false
    S.historyFirstReward = false
    S.osmiaFirstReward = false
    -- 新增书籍
    S.hasTheologyBook = false
    S.theologyBookReadCount = 0
    S.theologyFirstReward = false
    S.hasBotanyBook = false
    S.botanyBookReadCount = 0
    S.botanyFirstReward = false
    S.hasRepairBook = false
    S.repairBookReadCount = 0
    S.repairFirstReward = false
    S.hasTacticsText = false
    S.tacticsTextReadCount = 0
    S.tacticsTextFirstReward = false
    S.hasMagicText = false
    S.magicTextReadCount = 0
    S.magicTextFirstReward = false
    S.hasTheologyText = false
    S.theologyTextReadCount = 0
    S.theologyTextFirstReward = false
    S.hasCookText = false
    S.cookTextReadCount = 0
    S.cookTextFirstReward = false

    -- 调酒笔记
    S.hasBartenderNote = false
    S.bartenderNoteReadCount = 0
    S.bartenderNoteRewarded = false

    -- 梅菲斯（经理NPC）
    S.metOamelFirst = false
    S.metManagerFirst = false
    S.metManagerCount = 0
    S.meifeiAffection = 0
    S.meifeiLevel = 1
    S.meifeiWageBonus = 0
    S.meifeiChatCount = 0

    -- 奥梅尔·罗斯巴特（少爷NPC）
    S.oamelAffection = 0
    S.oamelLevel = 1
    S.oamelSkillActive = false
    S.oamelSkillBonus = 0
    S.oamelLoanUsed = false

    -- 房租系统
    S.rentPaidThisWeek = true
    S.rentWeek = 1
    S.rentDue = 100
    S.rentWarningShown = false
    S.evicted = false
    S.oweRent = 0
    S.rentDueDate = 0

    -- 晚宴系统
    S.banquetTheme = 0
    S.banquetStage = ""
    S.banquetAttendedThisWeek = false
    S.etiquetteTrainedThisWeek = false

    -- 二楼解锁
    S.unlockLounge = false

    -- ==================== 战斗系统 ====================

    -- 森林探索
    S.gold = 0              -- 森林金币（独立于money）
    S.forestLayer = 1       -- 当前层数
    S.maxLayer = 10         -- 最大层数
    S.eventFruitUsed = false -- 果树事件已用
    S.kInParty = false      -- K是否在队伍中
    S.boughtPotion = false  -- 商人药水已购
    S.healUsedToday = 0     -- 今日恢复次数
    S.maxHealPerDay = 3     -- 每日最大恢复次数

    -- 战斗状态
    S.inCombat = false
    S.turnOrder = {}
    S.turnIndex = 0
    S.lastBattleMessage = ""
    S.battleResult = ""     -- "victory"/"defeat"/""

    -- 主角战斗属性
    S.playerCombat = {
        name = "勇者",
        hp = 105, maxHp = 105,
        mp = 60, maxMp = 60,
        power = 6, insight = 1,
        charm = 3, stamina = 5,
        skill = 1, speed = 5,
        def = 7.5,
        atkBase = 6, matkBase = 2,
        mdef = 0,
        level = 10, exp = 0,
        expNext = 450,
        attrPoints = 0,
        buff = { power = 0, insight = 0, dmgMult = 0, turns = 0 },
        rotTurns = 0,
        bless = nil,
        heroClass = "none",  -- 战斗职业：none/warrior/mage
    }

    -- K战斗属性
    S.kCombat = {
        name = "K",
        hp = 75, maxHp = 75,
        mp = 50, maxMp = 50,
        power = 9, insight = 6,
        charm = 2, stamina = 4,
        skill = 3, speed = 4,
        def = 6.5,
        atkBase = 11, matkBase = 7,
        mdef = 0.1,
        level = 10, exp = 0,
        expNext = 450,
        attrPoints = 0,
        form = "mage",  -- "mage" / "sword"
        enchant = { type = "", turns = 0, extra = 0 },
        passive = { mageRegen = 2, swordDmgReduction = 0.3 },
        skillCooldown = { lightShield = 0 },
        shield = { active = false },
        buff = { power = 0, insight = 0, dmgMult = 0, turns = 0 },
        rotTurns = 0,
        bless = nil,
    }

    -- 莱德战斗属性（物理速攻型）
    S.initialNameCombat = {
        name = "莱德",
        hp = 90, maxHp = 90,
        mp = 30, maxMp = 30,
        power = 8, insight = 2,
        charm = 2, stamina = 6,
        skill = 4, speed = 6,
        def = 6,
        atkBase = 9, matkBase = 1,
        mdef = 0,
        level = 8, exp = 0,
        expNext = 350,
        attrPoints = 0,
        buff = { power = 0, insight = 0, dmgMult = 0, turns = 0 },
        rotTurns = 0,
        bless = nil,
    }

    -- 当前战斗中的队伍和敌人（战斗初始化时填充）
    S.party = {}
    S.enemies = {}

    -- 每日Buff（商人购买）
    S.dailyBuffs = { phys = 0, magic = 0, def = 0 }

    -- 背包（保留扩展）
    S.inventory = {}

    -- 话题对话状态
    S.currentTopic = ""
    S.dialogueNode = ""
    S.dialogueChar = ""
    S.returnPassage = ""
    S.dialogueChoice = 0

    -- 设置/版本日志
    S._settingsFrom = nil
    S._changelogPage = 1

    -- 通知队列
    S.notifications = {}

    GameState.state = S
    return S
end

--- 属性范围表（未列出的默认 0~999）
local STAT_RANGES = {
    stress      = { 0, 100 },
    fatigue     = { 0, 100 },
    satiety     = { 0, 100 },
    cleanliness = { 0, 100 },
    money       = { 0, 999999 },
}

--- 修改属性值（按属性范围自动钳位）
---@param stat string
---@param delta number
function GameState.modStat(stat, delta)
    local S = GameState.state
    local cur = S[stat]
    if type(cur) ~= "number" then cur = 0 end
    local range = STAT_RANGES[stat]
    local lo, hi = 0, 999
    if range then lo, hi = range[1], range[2] end
    S[stat] = math.max(lo, math.min(hi, cur + delta))
end

--- 添加日志
---@param person string
---@param logType string
---@param content string
function GameState.addDateLog(person, logType, content)
    local S = GameState.state
    local dateStr = S.year .. "年" .. S.month .. "月" .. S.day .. "日"
    table.insert(S.dateLogs, {
        date = dateStr,
        person = person,
        type = logType,
        content = content,
    })
    if #S.dateLogs > 50 then
        table.remove(S.dateLogs, 1)
    end
end

--- 添加最近动态（最多保留5条）
---@param text string 动态描述
function GameState.addRecentEvent(text)
    local S = GameState.state
    local dateStr = S.year .. "年" .. S.month .. "月" .. S.day .. "日"
    local timeStr = GameState.getTimeStr()
    table.insert(S.recentEvents, {
        date = dateStr,
        time = timeStr,
        text = text,
    })
    if #S.recentEvents > 5 then
        table.remove(S.recentEvents, 1)
    end
end

--- 添加通知
---@param msg string
function GameState.showNotification(msg)
    local S = GameState.state
    table.insert(S.notifications, {
        text = msg,
        time = 3.0,  -- 显示时间
    })
end

--- 获取星期几
function GameState.getDayOfWeek()
    local S = GameState.state
    local names = { "周一", "周二", "周三", "周四", "周五", "周六", "周日" }
    local idx = ((S.day - 1) % 7) + 1
    return names[idx]
end

--- 获取格式化时间
function GameState.getTimeStr()
    local S = GameState.state
    local h = S.hour < 10 and ("0" .. S.hour) or tostring(S.hour)
    local m = S.minute < 10 and ("0" .. S.minute) or tostring(S.minute)
    return h .. ":" .. m
end

return GameState
