-- ============================================================================
-- UniversitySystem.lua - 社区大学（完整校园系统）
-- 固定课表 / 校园地图 / 最多2个专业 / 上课修炼 / 学业等级
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local WorkSystem = require("systems.WorkSystem")

local UniSystem = {}

-- ==================== 专业定义 ====================

UniSystem.MAJORS = {
    {
        id = "warrior",
        name = "战士学",
        icon = "⚔️",
        desc = "学习近战格斗、武器使用和体能训练。\n修完后大幅提升力量和战斗能力。",
        fiveStats = { LL = 2, NL = 1 },
        combatBonus = { type = "phys", perLevel = 0.05 },
        expPerClass = 15,
    },
    {
        id = "mage",
        name = "魔法学",
        icon = "🔮",
        desc = "研究元素法术、符文刻印和魔力控制。\n修完后掌握强大的魔法力量。",
        fiveStats = { ML = 2, LG = 1 },
        combatBonus = { type = "magic", perLevel = 0.05 },
        expPerClass = 15,
    },
    {
        id = "theology",
        name = "神学",
        icon = "📿",
        desc = "钻研神圣经典、治愈祷告和神谕解读。\n修完后大幅提升灵感与信仰之力。",
        fiveStats = { LG = 2, ML = 1 },
        combatBonus = { type = "mdef", perLevel = 0.03 },
        expPerClass = 15,
    },
    {
        id = "cooking",
        name = "烹饪学",
        icon = "🍳",
        desc = "从基础刀工到高级料理，系统学习烹饪技艺。\n修完后可解锁更多食谱，还能开小摊赚钱！",
        fiveStats = { JQ = 2, NL = 1 },
        combatBonus = nil,
        expPerClass = 20,
        cookingExpPerClass = 10,
    },
}

-- ==================== 固定周课表 ====================
-- day: 1=周一 2=周二 ... 7=周日
-- 设计原则：任意两个专业的课程时间互不冲突

UniSystem.SCHEDULE = {
    warrior = {
        { day = 1, hour = 9,  minute = 0, duration = 90, name = "基础剑术",   location = "训练场" },
        { day = 3, hour = 9,  minute = 0, duration = 90, name = "战术与兵法", location = "教室101" },
        { day = 5, hour = 14, minute = 0, duration = 90, name = "实战对练",   location = "训练场" },
    },
    mage = {
        { day = 2, hour = 9,  minute = 0, duration = 90, name = "元素理论",   location = "教室201" },
        { day = 4, hour = 9,  minute = 0, duration = 90, name = "符文与咒语", location = "教室201" },
        { day = 6, hour = 9,  minute = 0, duration = 90, name = "魔力实践",   location = "魔法实验室" },
    },
    theology = {
        { day = 1, hour = 14, minute = 0, duration = 90, name = "经典诵读",   location = "教室301" },
        { day = 3, hour = 14, minute = 0, duration = 90, name = "神谕解读",   location = "教室301" },
        { day = 5, hour = 9,  minute = 0, duration = 90, name = "冥想修行",   location = "冥想室" },
    },
    cooking = {
        { day = 2, hour = 14, minute = 0, duration = 90, name = "刀工基础",   location = "烹饪教室" },
        { day = 4, hour = 14, minute = 0, duration = 90, name = "食材学",     location = "教室401" },
        { day = 6, hour = 14, minute = 0, duration = 90, name = "实践料理",   location = "烹饪教室" },
    },
}

-- ==================== 课堂场景描述 ====================
-- 按 [专业][课程索引] 组织，每个课程 3 条随机描述

UniSystem.CLASS_SCENES = {
    warrior = {
        { -- 基础剑术
            "今天练习了基础剑术。教官对你的站姿进行了纠正。手臂有点酸，但感觉力量在增长。",
            "和同学进行了木剑对练。虽然被敲了好几次，但身体开始记住防御的节奏。",
            "教官演示了三种基础斩击，你反复练习，汗水浸透了练习服。",
        },
        { -- 战术与兵法
            "学习了战术理论和战场急救。原来战士不只是打打杀杀。",
            "教授用沙盘推演了一场经典战役，你试着指挥方阵，虽然惨败但学到不少。",
            "今天讲了地形利用和伏击战术，你在笔记本上画满了图。",
        },
        { -- 实战对练
            "和同学进行了全副武装的对练。虽然被摔了好几次，但身体记住了很多反应动作。",
            "今天是体能训练日。跑步、俯卧撑、负重深蹲……累得像条狗，但感觉变强了。",
            "教官安排了二对一的模拟战。你和搭档配合得越来越默契。",
        },
    },
    mage = {
        { -- 元素理论
            "学习了初级元素理论。在手掌中凝聚出了微弱的光芒，虽然只是一闪而过，但很兴奋。",
            "教授讲解了四大元素的平衡原理，你在笔记本上画满了魔法阵图案。",
            "今天学了火、水、风三系的基础理论差异，你发现自己对某个系特别有感觉。",
        },
        { -- 符文与咒语
            "背诵了一整章符文词典。脑子嗡嗡的，但似乎记住了一些关键的咒语结构。",
            "练习在羊皮纸上描绘符文。你的第一个符文虽然歪歪扭扭，但竟然微微发了光！",
            "教授纠正了你咒语的发音，微小的差异竟然能完全改变法术效果。",
        },
        { -- 魔力实践
            "今天做了魔力流转练习。感觉体内有种温热的东西在流动。",
            "教授演示了水球术。你试了半天只搞出一滩水洼。任重道远。",
            "在实验室里练习精确控制魔力输出。你成功让一颗小石子悬浮了三秒！",
        },
    },
    theology = {
        { -- 经典诵读
            "诵读了一章神圣经典。心灵感到一阵平静，仿佛被温柔的光芒包围。",
            "和同学们一起朗诵祈祷文，声音在教室里回荡，空气中似乎弥漫着圣光。",
            "教授逐字解读了一段古老经文，你才发现原来每个词都有深层含义。",
        },
        { -- 神谕解读
            "今天的课是神谕解读。教授讲述了古老的神迹，你听得入了神。",
            "分析了三则古代神谕的隐喻，你提出了一个独特的解读角度，教授点头赞许。",
            "学习了如何辨别真假神谕。教授说，真正的神谕往往最朴素无华。",
        },
        { -- 冥想修行
            "学习了基础治愈祷告的手势和咒文。感觉手心微微发热。",
            "和同学一起进行了冥想训练。虽然中间走了好几次神，但结束后神清气爽。",
            "今天的冥想格外专注，你隐约感觉到了一丝神圣力量的回应。",
        },
    },
    cooking = {
        { -- 刀工基础
            "学习了基础刀工。切了一整筐土豆和胡萝卜。手有点抖，但切得越来越匀了。",
            "练习了丝、片、丁、块四种基本切法。教授说你的刀工有进步。",
            "今天学了鱼的处理方法。从去鳞到剔骨，你弄得一身腥味但很有成就感。",
        },
        { -- 食材学
            "学习了食材保鲜和调味搭配的理论。原来做菜也是一门科学。",
            "教授带来了十几种香料让你辨认。你闻到最后鼻子都麻了。",
            "今天学了不同地区的食材特色，你对异国料理产生了浓厚兴趣。",
        },
        { -- 实践料理
            "今天学做了蛋炒饭。虽然火候还差点意思，但味道居然还行！",
            "教授演示了高汤的熬制方法。满教室都是诱人的香味，肚子一直在叫。",
            "完成了一道完整的主菜料理！虽然摆盘不太好看，但同学们都说好吃。",
        },
    },
}

-- 学业等级经验阈值
local LEVEL_THRESHOLDS = { 40, 100, 180, 280, 400 }
-- 每节课花费
local CLASS_COST = 15
-- 最多同时报名专业数
local MAX_MAJORS = 2
-- 星期名
local DAY_NAMES = { "周一", "周二", "周三", "周四", "周五", "周六", "周日" }

-- ==================== 工具函数 ====================

function UniSystem.getMajorInfo(majorId)
    for _, m in ipairs(UniSystem.MAJORS) do
        if m.id == majorId then return m end
    end
    return nil
end

function UniSystem.getLevelName(level)
    local names = { [0] = "未入学", "初学者", "学徒", "进阶", "高级", "毕业" }
    return names[level] or "未知"
end

function UniSystem.getExpToNext(level)
    if level >= 5 then return 0 end
    return LEVEL_THRESHOLDS[level + 1] or 999
end

--- 确保新版多专业状态字段已初始化（兼容旧存档）
function UniSystem.ensureInit(S)
    -- 迁移旧版单专业数据
    if S.uniMajor and S.uniMajor ~= "" and not S.uniMajors then
        S.uniMajors = { S.uniMajor }
        S.uniMajorData = {
            [S.uniMajor] = {
                level = S.uniLevel or 0,
                exp = S.uniExp or 0,
                totalClasses = S.uniTotalClasses or 0,
            }
        }
    end
    if not S.uniMajors then S.uniMajors = {} end
    if not S.uniMajorData then S.uniMajorData = {} end
    if not S.uniAttendedToday then S.uniAttendedToday = {} end
end

--- 获取某专业的数据
function UniSystem.getMajorData(majorId)
    local S = GameState.state
    UniSystem.ensureInit(S)
    return S.uniMajorData[majorId] or { level = 0, exp = 0, totalClasses = 0 }
end

--- 是否已报名某专业
function UniSystem.isEnrolled(majorId)
    local S = GameState.state
    UniSystem.ensureInit(S)
    for _, id in ipairs(S.uniMajors) do
        if id == majorId then return true end
    end
    return false
end

--- 给指定专业增加经验（含升级逻辑）
function UniSystem.addMajorExp(majorId, amount)
    local S = GameState.state
    UniSystem.ensureInit(S)
    local data = S.uniMajorData[majorId]
    if not data then return end

    data.exp = data.exp + amount
    local major = UniSystem.getMajorInfo(majorId)
    local majorName = major and major.name or majorId

    -- 检查升级
    while data.level < 5 do
        local threshold = LEVEL_THRESHOLDS[data.level + 1]
        if not threshold or data.exp < threshold then break end

        data.level = data.level + 1

        -- 五维属性加成
        local statNames = { LL = "力量", LG = "灵感", ML = "魅力", NL = "耐力", JQ = "技巧" }
        local statMsgs = {}
        if major and major.fiveStats then
            for stat, val in pairs(major.fiveStats) do
                GameState.modStat(stat, val)
                table.insert(statMsgs, (statNames[stat] or stat) .. "+" .. val)
            end
        end

        -- 生活经验
        WorkSystem.addLifeExp(50)

        -- 战斗加成
        if major and major.combatBonus then
            local bonusKey = "uniCombatBonus_" .. major.combatBonus.type
            S[bonusKey] = (S[bonusKey] or 0) + major.combatBonus.perLevel
            local bonusNames = { phys = "物理伤害", magic = "魔法伤害", mdef = "魔法抗性" }
            local bonusName = bonusNames[major.combatBonus.type] or major.combatBonus.type
            table.insert(statMsgs, bonusName .. "+" .. math.floor(major.combatBonus.perLevel * 100 + 0.5) .. "%")
        end

        local levelName = UniSystem.getLevelName(data.level)
        local statText = #statMsgs > 0 and ("，" .. table.concat(statMsgs, "、")) or ""
        GameState.showNotification("学业升级! " .. majorName .. " → " .. levelName .. " (Lv." .. data.level .. ")" .. statText)
        GameState.addDateLog("社区大学", "学业升级", majorName .. "等级提升到" .. levelName .. statText)

        if data.level >= 5 then
            GameState.showNotification("恭喜！你从社区大学" .. majorName .. "专业毕业了！")
        end
    end

    -- 同步旧版字段（兼容其他系统读取）
    if #S.uniMajors > 0 then
        local firstData = S.uniMajorData[S.uniMajors[1]]
        if firstData then
            S.uniLevel = firstData.level
            S.uniExp = firstData.exp
        end
    end
end

--- 获取战斗加成（兼容旧接口）
function UniSystem.getCombatBonuses()
    local S = GameState.state
    return {
        phys = S.uniCombatBonus_phys or 0,
        magic = S.uniCombatBonus_magic or 0,
        mdef = S.uniCombatBonus_mdef or 0,
    }
end

--- 获取当前时间可以上的课（在时间窗口内且今天未上过）
function UniSystem.getAvailableClasses()
    local S = GameState.state
    UniSystem.ensureInit(S)
    local currentDay = ((S.day - 1) % 7) + 1
    local currentMin = S.hour * 60 + S.minute
    local available = {}

    for _, majorId in ipairs(S.uniMajors) do
        local schedule = UniSystem.SCHEDULE[majorId]
        local major = UniSystem.getMajorInfo(majorId)
        local mData = UniSystem.getMajorData(majorId)
        if schedule and mData.level < 5 then
            for i, cls in ipairs(schedule) do
                if cls.day == currentDay then
                    local classStart = cls.hour * 60 + cls.minute
                    local classEnd = classStart + cls.duration
                    -- 课程时间段内都可以进入上课
                    if currentMin >= classStart and currentMin < classEnd then
                        local slotKey = majorId .. "_" .. i
                        if not S.uniAttendedToday[slotKey] then
                            table.insert(available, {
                                majorId = majorId,
                                majorName = major and major.name or majorId,
                                majorIcon = major and major.icon or "📚",
                                cls = cls,
                                slotIndex = i,
                                slotKey = slotKey,
                                remainingMin = classEnd - currentMin,
                            })
                        end
                    end
                end
            end
        end
    end
    return available
end

--- 获取今日课表
function UniSystem.getTodaySchedule()
    local S = GameState.state
    UniSystem.ensureInit(S)
    local currentDay = ((S.day - 1) % 7) + 1
    local todayClasses = {}

    for _, majorId in ipairs(S.uniMajors) do
        local schedule = UniSystem.SCHEDULE[majorId]
        local major = UniSystem.getMajorInfo(majorId)
        local mData = UniSystem.getMajorData(majorId)
        if schedule then
            for i, cls in ipairs(schedule) do
                if cls.day == currentDay then
                    local slotKey = majorId .. "_" .. i
                    table.insert(todayClasses, {
                        majorId = majorId,
                        majorName = major and major.name or majorId,
                        majorIcon = major and major.icon or "📚",
                        cls = cls,
                        slotKey = slotKey,
                        attended = S.uniAttendedToday[slotKey] or false,
                        graduated = mData.level >= 5,
                    })
                end
            end
        end
    end

    -- 按时间排序
    table.sort(todayClasses, function(a, b)
        return (a.cls.hour * 60 + a.cls.minute) < (b.cls.hour * 60 + b.cls.minute)
    end)
    return todayClasses
end

--- 课程提醒（由 TimeSystem.onHourTick 调用）
function UniSystem.checkClassReminder()
    local S = GameState.state
    if not S.uniEnrolled then return end
    UniSystem.ensureInit(S)

    local currentDay = ((S.day - 1) % 7) + 1
    for _, majorId in ipairs(S.uniMajors) do
        local schedule = UniSystem.SCHEDULE[majorId]
        if schedule then
            for i, cls in ipairs(schedule) do
                if cls.day == currentDay and S.hour == cls.hour then
                    local slotKey = majorId .. "_" .. i
                    if not S.uniAttendedToday[slotKey] then
                        local mData = UniSystem.getMajorData(majorId)
                        if mData.level < 5 then
                            local major = UniSystem.getMajorInfo(majorId)
                            local timeStr = string.format("%02d:%02d", cls.hour, cls.minute)
                            GameState.showNotification("📚 " .. (major and major.name or majorId)
                                .. "「" .. cls.name .. "」" .. timeStr
                                .. "在" .. cls.location .. "开课了！")
                        end
                    end
                end
            end
        end
    end
end

-- ==================== 每日重置 ====================

function UniSystem.onDayChange()
    local S = GameState.state
    UniSystem.ensureInit(S)
    S.uniAttendedToday = {}
    S.uniClassesToday = 0  -- 旧版兼容
end

-- ==================== 段落系统 ====================

local UniPassages = require("systems.university.Passages")

function UniSystem.getPassage(passageName)
    return UniPassages.getPassage(passageName, UniSystem)
end


return UniSystem
