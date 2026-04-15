---@diagnostic disable: missing-parameter
local PassageData = {}

-- 导入必要的模块
local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local WorkSystem = require("systems.WorkSystem")
local BattleSystem = require("systems.BattleSystem")
local ChangelogData = require("systems.ChangelogData")
local SaveSystem = require("systems.SaveSystem")
local TownLife = require("systems.TownLife")
local MainQuest = require("systems.MainQuest")
local CookingSystem = require("systems.CookingSystem")
local FarmingSystem = require("systems.FarmingSystem")
local UniSystem = require("systems.UniversitySystem")
local RandomEvents = require("systems.RandomEvents")
local HomeSystem = require("systems.HomeSystem")
local KeywordSystem = require("systems.KeywordSystem")
local SideQuests = require("systems.SideQuests")
local MainQuestCh2 = require("systems.MainQuestCh2")
local MainQuestCh3 = require("systems.MainQuestCh3")
local CommonUtils = require("utils.CommonUtils")

-- 工具函数（来自 CommonUtils）
local getTimePeriod = CommonUtils.getTimePeriod
local getTimePeriodCN = CommonUtils.getTimePeriodCN
local addAffection = CommonUtils.addAffection
local addDateLog = CommonUtils.addDateLog

-- 模块预检查
local hasTownLife = TownLife and type(TownLife.getPassage) == "function"
local hasRandomEvents = RandomEvents and type(RandomEvents.getPassage) == "function"
local hasSideQuests = SideQuests and type(SideQuests.getPassage) == "function"

-- PassageData 专用辅助函数
local function addOamelAffection(amount)
    local S = GameState.state
    S.oamelAffection = (S.oamelAffection or 0) + amount
end

local function addMeifeiAffection(amount)
    local S = GameState.state
    S.meifeiAffection = (S.meifeiAffection or 0) + amount
end

local function addMannerExp(amount)
    local S = GameState.state
    S.mannerExp = (S.mannerExp or 0) + amount
end

local function addHistoryExp(amount)
    local S = GameState.state
    S.historyExp = (S.historyExp or 0) + amount
end

local function isLeiDeHome()
    local S = GameState.state
    return S.initialNameAtHome and not (S.hour >= 22 or S.hour < 6)
end

-- 工作辅助（委托 WorkSystem，返回目标段落）
local function doWorkWithEvent(jobType, withLeiDe)
    local S = GameState.state
    local baseMsg, event = WorkSystem.doWorkWithEvent(jobType, withLeiDe or false)
    if event then
        -- 存储事件到 state，由 "打工事件" passage 展示
        S._workEvent = event
        S._workEventBase = baseMsg
        S._workEventJob = jobType
        S._workEventWithLeiDe = withLeiDe or false
        return "打工事件"
    end
    -- 无事件，直接显示结果
    S._workResultMsg = baseMsg .. "\n\n平静地度过了一小时，没有什么特别的事发生。"
    return "打工结果"
end

-- 读书辅助
local function readBook(bookType)
    local S = GameState.state
    if bookType == "manner" then
        if not S.mannerFirstReward then
            S.mannerFirstReward = true
            S.ML = (S.ML or 3) + 1
            return "读完《贵族礼仪入门》，魅力+1！"
        else
            return "你复习了礼仪知识。"
        end
    elseif bookType == "history" then
        if not S.historyFirstReward then
            S.historyFirstReward = true
            S.ZL = (S.ZL or 1) + 1
            return "读完《日轮王国贵族名录》，智力+1！"
        else
            return "你复习了历史知识。"
        end
    elseif bookType == "osmia" then
        if not S.osmiaFirstReward then
            S.osmiaFirstReward = true
            S.ZL = (S.ZL or 1) + 2
            return "读完《奥丝米娅时代的历史》，智力+2！"
        else
            return "你复习了奥丝米娅时代的历史。"
        end
    end
    return "你翻阅了一会儿书。"
end
---============================================================
--- Handler 调度表（合并子模块返回的 handler 表）
---============================================================
local handlers = {}

local function mergeHandlers(source)
    for k, v in pairs(source) do
        handlers[k] = v
    end
end

mergeHandlers(require("passages.ProloguePassages"))
mergeHandlers(require("passages.LocationPassages"))
mergeHandlers(require("passages.NPCEventPassages"))
mergeHandlers(require("passages.SystemPassages"))

---============================================================
--- 主函数：根据段落名返回段落数据
---============================================================
function PassageData.getPassage(passageName)
    local S = GameState.state

    -- 1) 查找 handler 表
    local handler = handlers[passageName]
    if handler then
        return handler(S)
    end

    -- 1.5) 动态前缀匹配（人物档案详情页）
    if passageName:sub(1, #"人物档案_") == "人物档案_" then
        local npcId = passageName:sub(#"人物档案_" + 1)
        local profiles = PassageData._getNpcProfiles(S)
        local profile = nil
        for _, p in ipairs(profiles) do
            if p.id == npcId then profile = p; break end
        end

        if not profile then
            return { text = "未找到该人物的档案。", choices = { { text = "🔙 返回", target = "社会关系" } } }
        end

        local text = profile.displayName .. "\n\n"
        text = text .. "━━━ 基本资料 ━━━\n"
        text = text .. "种族：" .. profile.race .. "\n"
        text = text .. "职业：" .. profile.job .. "\n"
        if profile.age then text = text .. "年龄：" .. profile.age .. "\n" end
        if profile.origin then text = text .. "出身：" .. profile.origin .. "\n" end
        text = text .. "\n━━━ 关系 ━━━\n"
        text = text .. "好感度：" .. profile.affection
        if profile.affectionMax then text = text .. "/" .. profile.affectionMax end
        text = text .. "\n"
        text = text .. "好感等级：Lv." .. profile.level .. "\n"
        text = text .. "关系阶段：" .. profile.relationStage .. "\n"

        if profile.stats then
            text = text .. "\n━━━ 五维属性 ━━━\n"
            text = text .. "力" .. profile.stats.LL .. " 灵" .. profile.stats.LG
                .. " 魅" .. profile.stats.ML .. " 耐" .. profile.stats.NL
                .. " 技" .. profile.stats.JQ .. "\n"
        end

        text = text .. "\n━━━ 简介 ━━━\n"
        text = text .. profile.bio .. "\n"

        if profile.plotHints and #profile.plotHints > 0 then
            text = text .. "\n━━━ 已知情报 ━━━\n"
            for _, hint in ipairs(profile.plotHints) do
                text = text .. "· " .. hint .. "\n"
            end
        end

        if profile.interactionStats then
            text = text .. "\n━━━ 互动记录 ━━━\n"
            text = text .. profile.interactionStats .. "\n"
        end

        return { text = text, choices = { { text = "🔙 返回社会关系", target = "社会关系" } } }
    end

    -- 2) 委托给其他模块
    if MainQuest and MainQuest.getPassage then
        local p = MainQuest.getPassage(passageName)
        if p then return p end
    end
    if MainQuestCh2 and MainQuestCh2.getPassage then
        local p = MainQuestCh2.getPassage(passageName)
        if p then return p end
    end
    if MainQuestCh3 and MainQuestCh3.getPassage then
        local p = MainQuestCh3.getPassage(passageName)
        if p then return p end
    end
    if CookingSystem and CookingSystem.getPassage then
        local p = CookingSystem.getPassage(passageName)
        if p then return p end
    end
    if FarmingSystem and FarmingSystem.getPassage then
        local p = FarmingSystem.getPassage(passageName)
        if p then return p end
    end
    if UniSystem and UniSystem.getPassage then
        local p = UniSystem.getPassage(passageName)
        if p then return p end
    end
    if hasTownLife then
        local p = TownLife.getPassage(passageName)
        if p then return p end
    end
    if hasSideQuests then
        local p = SideQuests.getPassage(passageName)
        if p then return p end
    end
    if hasRandomEvents then
        local p = RandomEvents.getPassage(passageName)
        if p then return p end
    end
    if HomeSystem and HomeSystem.getPassage then
        local p = HomeSystem.getPassage(passageName)
        if p then return p end
    end
    if KeywordSystem and KeywordSystem.getPassage then
        local p = KeywordSystem.getPassage(passageName)
        if p then return p end
    end
    if BattleSystem and BattleSystem.getPassage then
        local p = BattleSystem.getPassage(passageName)
        if p then return p end
    end

    -- 3) 默认 fallback
    return {
        text = "未知段落：" .. tostring(passageName),
        choices = {
            { text = "返回主页面", target = "主页面" },
        },
    }
end
-- ==================== 特殊事件注入（前置到地点描述之前） ====================
-- TownLife.getEvents / RandomEvents.getEvents 返回的事件文本和选项
-- 注入到地点段落中：文本前置于地点描述之前，选项插入到选择列表顶部

local _eventLocations = {
    ["十字路口"] = true,
    ["商业区"] = true,
    ["港口"] = true,
    ["花园小镇"] = true,
    ["主城区"] = true,
    ["花街"] = true,
    ["贫民窟"] = true,
}

local _rawGetPassage = PassageData.getPassage

function PassageData.getPassage(passageName)
    local result = _rawGetPassage(passageName)
    if not result or not result.text then return result end

    -- 从文本第一行提取实际地点名（处理子区域：酒馆/教堂等首行不匹配，自动跳过）
    local firstNewline = string.find(result.text, "\n")
    local locationName = firstNewline and string.sub(result.text, 1, firstNewline - 1) or result.text
    locationName = locationName:match("^%s*(.-)%s*$") or locationName

    if not _eventLocations[locationName] then
        return result
    end

    -- 收集事件
    local eventText = ""
    local eventChoices = {}

    -- TownLife NPC 事件
    if TownLife and TownLife.getEvents then
        local townEvents = TownLife.getEvents(locationName)
        if townEvents then
            if townEvents.text and townEvents.text ~= "" then
                eventText = eventText .. townEvents.text
            end
            if townEvents.choices then
                for _, c in ipairs(townEvents.choices) do
                    table.insert(eventChoices, c)
                end
            end
        end
    end

    -- RandomEvents 随机事件（生存事件 + 属性检定事件）
    if RandomEvents and RandomEvents.getEvents then
        local randEvents = RandomEvents.getEvents(locationName)
        if randEvents then
            if randEvents.text and randEvents.text ~= "" then
                eventText = eventText .. randEvents.text
            end
            if randEvents.choices then
                for _, c in ipairs(randEvents.choices) do
                    table.insert(eventChoices, c)
                end
            end
        end
    end

    -- 无事件则直接返回
    if eventText == "" and #eventChoices == 0 then
        return result
    end

    -- 注入事件文本：插入到地点名之后、地点描述之前
    if eventText ~= "" then
        local splitPos = string.find(result.text, "\n\n")
        if splitPos then
            local header = string.sub(result.text, 1, splitPos - 1)
            local body = string.sub(result.text, splitPos)
            result.text = header .. eventText .. body
        else
            result.text = result.text .. eventText
        end
    end

    -- 注入事件选项：插入到 choices 最前面（在主线任务触发之后）
    if #eventChoices > 0 and result.choices then
        -- 跳过已有的主线任务触发选项（通常带 ⚔️/📜/🗡 图标）
        local insertPos = 1
        for i, c in ipairs(result.choices) do
            if c.text and (string.find(c.text, "⚔") or string.find(c.text, "📜") or string.find(c.text, "🗡")) then
                insertPos = i + 1
            else
                break
            end
        end
        for i = #eventChoices, 1, -1 do
            table.insert(result.choices, insertPos, eventChoices[i])
        end
    end

    return result
end

-- ==================== NPC 档案数据库 ====================

--- 关系阶段名称（根据好感等级）
local function getRelationStage(level, stages)
    if stages and stages[level] then return stages[level] end
    if level <= 0 then return "陌生人"
    elseif level == 1 then return "初识"
    elseif level == 2 then return "熟识"
    elseif level == 3 then return "亲近"
    elseif level == 4 then return "挚友"
    else return "至交" end
end

--- 次要NPC关系阶段（好感阈值：15/30/50/70/90）
local function getMinorRelationStage(val)
    if val >= 90 then return "至交"
    elseif val >= 70 then return "挚友"
    elseif val >= 50 then return "亲近"
    elseif val >= 30 then return "熟识"
    elseif val >= 15 then return "友善"
    else return "初识" end
end

--- 计算两个地点之间的大致步行时间（分钟）
---@param fromPassage string
---@param toPassage string
---@return number minutes
function PassageData._calcTravelTime(fromPassage, toPassage)
    -- 简化的距离图（双向）: 两地之间的直达时间
    local directTimes = {
        ["十字路口"] = { ["家"] = 1, ["商业区"] = 1, ["港口"] = 5, ["花园小镇"] = 5, ["渡劫森林"] = 10, ["大学校门"] = 5 },
        ["家"] = { ["十字路口"] = 1 },
        ["商业区"] = { ["十字路口"] = 1 },
        ["港口"] = { ["十字路口"] = 5 },
        ["花园小镇"] = { ["十字路口"] = 5, ["主城区"] = 5 },
        ["主城区"] = { ["花园小镇"] = 5, ["花街"] = 5 },
        ["花街"] = { ["主城区"] = 5 },
        ["渡劫森林"] = { ["十字路口"] = 10 },
        ["大学校门"] = { ["十字路口"] = 5 },
        ["白鸦书屋"] = { ["主城区"] = 1 },
        ["妖精的邀请"] = { ["花街"] = 1 },
    }

    -- 规范化起点：将子区域映射到主区域
    local function normalize(p)
        if not p then return "十字路口" end
        if p == "花园小镇_小巷" then return "花园小镇" end
        if p == "贵族休息室" or p == "贵族休息室_书柜" then return "主城区" end
        if p:sub(1, 4) == "森林" then return "渡劫森林" end
        if p:sub(1, 4) == "大学_" then return "大学校门" end
        return p
    end

    local src = normalize(fromPassage)
    local dst = normalize(toPassage)
    if src == dst then return 0 end

    -- BFS 最短路径
    local visited = { [src] = 0 }
    local queue = { { node = src, cost = 0 } }
    local head = 1
    while head <= #queue do
        local cur = queue[head]
        head = head + 1
        local neighbors = directTimes[cur.node]
        if neighbors then
            for neighbor, time in pairs(neighbors) do
                if not visited[neighbor] then
                    local total = cur.cost + time
                    visited[neighbor] = total
                    if neighbor == dst then return total end
                    table.insert(queue, { node = neighbor, cost = total })
                end
            end
        end
    end
    -- 未找到路径，返回估算值
    return 10
end

--- 构建完整 NPC 档案列表
---@param S table GameState.state
---@return table[] profiles
function PassageData._getNpcProfiles(S)
    local profiles = {}
    local name = S.initialName or "莱德"

    -- ========== 核心NPC ==========

    -- 莱德
    local leideHints = { "序章中与你一同逃离古堡的少年。" }
    if S.initialNameAtHome then table.insert(leideHints, "目前住在你家中。") end
    if S.initialNameSleepTogether then table.insert(leideHints, "和你同睡一张床。") end
    if (S.initialNameTalkCount or 0) > 0 then
        table.insert(leideHints, "你们已经深入交谈过 " .. S.initialNameTalkCount .. " 次。")
    end
    if S.initialNameInvited then table.insert(leideHints, "你曾邀请他来家中居住。") end
    local leideLocation = "十字路口随机偶遇"
    if S.initialNameAtHome then leideLocation = "家中（同住）/ 十字路口偶遇" end
    table.insert(profiles, {
        id = "leide",
        displayName = name,
        category = "core",
        race = "人类",
        job = "流浪者",
        age = "约18岁",
        origin = "瓦勒姆公爵领",
        met = true, -- 序章即相遇
        location = leideLocation,
        affection = S.initialNameAffection or 0,
        affectionMax = 100,
        level = S.initialNameLevel or 1,
        relationStage = getRelationStage(S.initialNameLevel or 1, {
            [1] = "同行者", [2] = "伙伴", [3] = "挚友", [4] = "知己", [5] = "灵魂伴侣",
        }),
        stats = {
            LL = S.initialName_LL or 2, LG = S.initialName_LG or 2,
            ML = S.initialName_ML or 2, NL = S.initialName_NL or 2,
            JQ = S.initialName_JQ or 2,
        },
        bio = "沉默寡言的少年，与你在序章的古堡中相遇。"
            .. "总是一副冷淡的表情，但偶尔会流露出不易察觉的温柔。"
            .. "过去的经历让他不太擅长表达感情。",
        plotHints = leideHints,
        interactionStats = "交谈 " .. (S.initialNameTalkCount or 0) .. " 次"
            .. " | 共餐 " .. (S.initialNameMealCount or 0) .. " 次",
    })

    -- K
    local kHints = {}
    if S.kMet then
        table.insert(kHints, "在酒馆打工时认识的调酒师。")
        if S.kVisiting then table.insert(kHints, "最近来家里做客了。") end
        if (S.kTalkCount or 0) > 5 then table.insert(kHints, "他偶尔会提起精灵的往事。") end
        if S.kGiftLamp then table.insert(kHints, "送了你一盏精灵光环造型的小夜灯。") end
    end
    table.insert(profiles, {
        id = "k",
        displayName = "K",
        category = "core",
        race = "精灵（伪装）",
        job = "调酒师",
        age = "外表约20岁（实际不明）",
        origin = "不明",
        met = S.kMet or false,
        location = "「妖精的邀请」酒馆（十字路口→酒馆）",
        affection = S.kAffection or 0,
        affectionMax = 100,
        level = S.kLevel or 1,
        relationStage = getRelationStage(S.kLevel or 1, {
            [1] = "同事", [2] = "朋友", [3] = "亲密伙伴", [4] = "知己", [5] = "灵魂伴侣",
        }),
        stats = {
            LL = S.K_LL or 4, LG = S.K_LG or 6,
            ML = S.K_ML or 2, NL = S.K_NL or 1,
            JQ = S.K_JQ or 3,
        },
        bio = "银发尖耳的神秘青年，头顶时隐时现地浮着光环。"
            .. "自称是精灵，在酒馆「妖精的邀请」担任调酒师。"
            .. "性格温和慵懒，偶尔会展现出不属于这个时代的深邃目光。",
        plotHints = kHints,
        interactionStats = "交谈 " .. (S.kTalkCount or 0) .. " 次"
            .. " | 共餐 " .. (S.kMealCount or 0) .. " 次",
    })

    -- ========== 重要NPC ==========

    -- 梅菲斯
    local meifeiHints = {}
    if S.metManagerFirst then table.insert(meifeiHints, "「妖精的邀请」酒馆的经理。") end
    if (S.meifeiWageBonus or 0) > 0 then table.insert(meifeiHints, "他的赏识让你的时薪提高了 " .. S.meifeiWageBonus .. "。") end
    table.insert(profiles, {
        id = "meifei",
        displayName = "梅菲斯",
        category = "important",
        race = "人类",
        job = "酒馆经理",
        age = "中年",
        origin = "不明",
        met = S.metManagerFirst or false,
        location = "「妖精的邀请」酒馆（十字路口→酒馆）",
        affection = S.meifeiAffection or 0,
        affectionMax = nil,
        level = S.meifeiLevel or 1,
        relationStage = getRelationStage(S.meifeiLevel or 1, {
            [1] = "雇主", [2] = "赏识", [3] = "信任", [4] = "心腹",
        }),
        bio = "穿着考究的中年绅士，酒馆「妖精的邀请」的经理。"
            .. "说话温和但眼神犀利，似乎总在审视什么。"
            .. "对有能力的人会给予不动声色的帮助。",
        plotHints = meifeiHints,
    })

    -- 奥梅尔·罗斯巴特
    local oamelHints = {}
    if S.metOamelFirst then table.insert(oamelHints, "罗斯巴特家族的少爷，在酒馆后台调酒。") end
    if S.oamelLoanUsed then table.insert(oamelHints, "曾借给你200金币，说不用还。") end
    if S.oamelSkillActive then table.insert(oamelHints, "「贵族的手腕」：打工工资+" .. (S.oamelSkillBonus or 0) .. "%。") end
    table.insert(profiles, {
        id = "oamel",
        displayName = "奥梅尔·罗斯巴特",
        category = "important",
        race = "人类",
        job = "贵族少爷 / 调酒师",
        age = "约20岁",
        origin = "罗斯巴特家族",
        met = S.metOamelFirst or false,
        location = "「妖精的邀请」酒馆后台（十字路口→酒馆）",
        affection = S.oamelAffection or 0,
        affectionMax = nil,
        level = S.oamelLevel or 1,
        relationStage = getRelationStage(S.oamelLevel or 1, {
            [1] = "点头之交", [2] = "熟人", [3] = "朋友", [4] = "密友",
        }),
        bio = "出身贵族却在酒馆调酒的年轻人，面容精致，嘴角常挂着似笑非笑的弧度。"
            .. "罗斯巴特家族是当地的名门望族。"
            .. "对平民出身的你态度意外地友善。",
        plotHints = oamelHints,
    })

    -- 乌列尔
    local urielHints = {}
    if S.urielMet then table.insert(urielHints, "你的亲哥哥，一直在暗中守护你。") end
    if (S.urielLetterCount or 0) > 0 then table.insert(urielHints, "已收到 " .. S.urielLetterCount .. " 封他的来信。") end
    if (S.urielHelpCount or 0) > 0 then table.insert(urielHints, "他已暗中帮助过你 " .. S.urielHelpCount .. " 次。") end
    table.insert(profiles, {
        id = "uriel",
        displayName = "乌列尔",
        category = "important",
        race = "人类（瓦勒姆血脉）",
        job = "不明",
        age = "约25岁",
        origin = "瓦勒姆公爵领",
        met = S.urielMet or false,
        location = "行踪不明（通过信件联系）",
        affection = S.urielAffection or 0,
        affectionMax = nil,
        level = S.urielLevel or 1,
        relationStage = getRelationStage(S.urielLevel or 1, {
            [1] = "陌生的血亲", [2] = "重逢", [3] = "兄弟", [4] = "至亲",
        }),
        bio = "诺兰的亲哥哥。在古堡事变后下落不明，"
            .. "但似乎一直在暗中守护着弟弟。"
            .. "偶尔会寄来没有署名的信件。",
        plotHints = urielHints,
    })

    -- 黑帮少主（威廉）
    if S.gangBossMet then
        table.insert(profiles, {
            id = "gangboss",
            displayName = "威廉（黑帮少主）",
            category = "important",
            race = "人类",
            job = "地下势力首领",
            age = "约22岁",
            origin = "贫民窟",
            met = true,
            affection = S.gangBossAffection or 0,
            affectionMax = nil,
            level = S.gangBossLevel or 1,
            relationStage = getRelationStage(S.gangBossLevel or 1, {
                [1] = "警惕", [2] = "利用", [3] = "合作", [4] = "信赖",
            }),
            bio = "贫民窟地下势力的年轻首领，自称「威廉」。"
                .. "在破败的贫民窟中拥有一栋格格不入的华丽宅邸。"
                .. "外表彬彬有礼，但眼神偶尔流露出危险的锐利。"
                .. "似乎对你有某种兴趣。",
            location = "贫民窟（花园小镇→贫民窟→宅邸）",
            plotHints = { "在贫民窟的宅邸中可以稳定遇见他。花街夜晚也偶尔出没。" },
        })
    end

    -- ========== 小镇居民 ==========

    local townData = {
        { id = "sinchi",     key = "Sinchi",     name = "辛奇",       race = "人类",   job = "酒馆老板",     age = "40多岁", location = "酒馆（十字路口→酒馆）", bio = "「妖精的邀请」酒馆的老板，粗犷直接，嗓门大心眼也大。对手下的伙计嘴上不饶人，但暗地里很照顾人。" },
        { id = "clarice",    key = "Clarice",    name = "克丽丝",     race = "人类",   job = "修女",         age = "20多岁", location = "教堂（十字路口→教堂）", bio = "教堂的修女，温和耐心，总是面带微笑。虔诚地信仰太阳神，对任何人都一视同仁。" },
        { id = "macnana",    key = "Macnana",    name = "麦拿拿",     race = "矮人",   job = "铁匠",         age = "不明",   location = "铁匠铺（十字路口→铁匠铺）", bio = "矮人铁匠，嘴硬心软。锻造手艺精湛，铁匠铺里却偷偷摆着小花盆。似乎和花店老板娘莉莉安走得很近。" },
        { id = "blackbeard", key = "Blackbeard", name = "黑胡子",     race = "人类",   job = "码头工头",     age = "50多岁", location = "港口码头（十字路口→港口）", bio = "港口的老水手，豪爽义气。满脸络腮胡，笑起来声如洪钟。退休后在码头当工头，管着一帮搬货工人。" },
        { id = "eileen",     key = "Eileen",     name = "艾琳",       race = "人类",   job = "流浪画家",     age = "20多岁", location = "十字路口随机偶遇", bio = "背着画架四处游荡的年轻女画家。性格自由洒脱，喜欢捕捉小镇日常的美好瞬间。" },
        { id = "oldyugen",   key = "OldYugen",   name = "老尤金",     race = "人类",   job = "退休水手/说书人", age = "60多岁", location = "港口附近（十字路口→港口）", bio = "退休的老水手，如今在港口附近给人讲故事。满脑子都是年轻时冒险的传说，真假难辨。" },
        { id = "lillian",    key = "Lillian",    name = "莉莉安",     race = "人类",   job = "花店老板娘",   age = "30多岁", location = "花园（十字路口→花园）", bio = "花园小镇的花店老板娘，热情开朗。喜欢各种花草，也喜欢八卦。和矮人铁匠麦拿拿是好友。" },
        { id = "dario",      key = "Dario",      name = "达里奥",     race = "人类",   job = "流浪乐手",     age = "30多岁", location = "十字路口随机偶遇", bio = "来自北方的流浪乐手，擅长弹唱北方牧歌。性格浪漫不羁，居无定所但总在小镇出没。" },
        { id = "grandmavera",key = "GrandmaVera",name = "薇拉奶奶",   race = "人类",   job = "退休（主城区老太太）", age = "70多岁", location = "主城区（十字路口→主城区）", bio = "主城区慈祥的老太太，据说年轻时也是个厉害人物。喜欢在门口晒太阳，给路过的年轻人塞点心。" },
        { id = "felix",      key = "Felix",      name = "费利克斯",   race = "人类",   job = "面包师",       age = "30多岁", location = "面包坊（十字路口→商业区）", bio = "小镇面包坊的师傅，热情好客。每天清晨最早起床揉面，整条街都弥漫着面包香。偶尔会送你一块免费的面包。" },
        { id = "isabella",   key = "Isabella",   name = "伊莎贝拉",   race = "人类",   job = "草药医生",     age = "40多岁", location = "药草铺（十字路口→主城区）", bio = "懂得草药医术的女医生，沉静内敛。在小镇边缘开了一间药草铺，薄荷和薰衣草的香味总是从门缝里飘出来。" },
        { id = "jasper",     key = "Jasper",     name = "贾斯帕",     race = "人类",   job = "守夜人",       age = "30多岁", location = "深夜巡逻（夜间十字路口偶遇）", bio = "小镇的守夜人，沉默寡言。每天深夜提着灯巡逻，见过这座小镇最黑暗的一面，但从不多说。" },
        { id = "nora",       key = "Nora",       name = "诺拉",       race = "人类",   job = "裁缝",         age = "20多岁", location = "裁缝铺（十字路口→商业区）", bio = "心灵手巧的年轻裁缝，在商业区开了一间小裁缝铺。量体裁衣的手法利落干脆，话不多但眼光很准。" },
        { id = "sebastian",  key = "Sebastian",  name = "塞巴斯蒂安", race = "人类",   job = "流浪学者",     age = "40多岁", location = "十字路口随机偶遇", bio = "戴着圆框眼镜的流浪学者，博学多识。随身带着一本厚厚的笔记本，记录着各种见闻和思考。" },
        { id = "xiaomei",    key = "Xiaomei",    name = "小梅",       race = "人类",   job = "鱼贩",         age = "十几岁", location = "港口鱼市（十字路口→港口）", bio = "港口卖鱼的少女，活泼爽朗。嗓门不输黑胡子，讲价时寸步不让，但对朋友大方得很。" },
        { id = "brotheramos",key = "BrotherAmos",name = "阿莫斯修士", race = "人类",   job = "教堂图书管理员", age = "50多岁", location = "教堂图书室（十字路口→教堂）", bio = "教堂图书室的管理员，沉默寡言的老修士。管理着大量古籍，偶尔会向你推荐一些有意思的书。" },
        { id = "merchantroy",key = "MerchantRoy",name = "罗伊",       race = "人类",   job = "杂货商人",     age = "30多岁", location = "商业区（十字路口→商业区）", bio = "在商业区游走的杂货商人，据说什么都能搞到。笑眯眯的，但眼神总是在算计什么。" },
        { id = "sistermina", key = "SisterMina", name = "米娜",       race = "人类",   job = "孤儿院修女",   age = "20多岁", location = "教堂（十字路口→教堂）", bio = "孤儿院的年轻修女，克丽丝的同事。比克丽丝更活泼些，擅长和孩子们打成一片。" },
    }

    for _, td in ipairs(townData) do
        local varName = "npc" .. td.key
        local metVar = varName .. "Met"
        -- 前四位（辛奇/克丽丝/麦拿拿/黑胡子）没有 Met 标记，通过好感>0或打工解锁判断
        local isMet = false
        if td.id == "sinchi" then
            isMet = (S.npcSinchi or 0) > 0 or S.unlockWaiter
        elseif td.id == "clarice" then
            isMet = (S.npcClarice or 0) > 0 or S.unlockCleric
        elseif td.id == "macnana" then
            isMet = (S.npcMacnana or 0) > 0 or S.unlockBlacksmith
        elseif td.id == "blackbeard" then
            isMet = (S.npcBlackbeard or 0) > 0 or S.unlockLaborer
        else
            isMet = S[metVar] or false
        end

        local val = S[varName] or 0
        local lvl = NPCSystem.getNpcLevel(val)

        table.insert(profiles, {
            id = td.id,
            displayName = td.name,
            category = "town",
            race = td.race,
            job = td.job,
            age = td.age,
            met = isMet,
            location = td.location,
            affection = val,
            level = lvl,
            relationStage = getMinorRelationStage(val),
            bio = td.bio,
            plotHints = nil,
        })
    end

    return profiles
end

return PassageData
