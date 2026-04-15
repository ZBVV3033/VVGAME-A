-- ============================================================================
-- NPCSystem.lua - NPC好感度与关系管理
-- ============================================================================

local GameState = require("systems.GameState")

local NPCSystem = {}

-- ==================== 好感度升级检查 ====================

--- 检查并处理主要NPC好感度升级（莱德/K，每100点升一级）
---@param character string "initialName" 或 "k"
---@return string 升级消息
function NPCSystem.affectionUpgrade(character)
    local S = GameState.state
    local msg = ""

    if character == "initialName" then
        while S.initialNameAffection >= 100 do
            S.initialNameLevel = S.initialNameLevel + 1
            S.initialNameAffection = S.initialNameAffection - 100
            S.initialName_LL = S.initialName_LL + 1
            S.initialName_LG = S.initialName_LG + 1
            S.initialName_ML = S.initialName_ML + 1
            S.initialName_NL = S.initialName_NL + 1
            S.initialName_JQ = S.initialName_JQ + 1
            msg = S.initialName .. " 的好感度等级提升到 " .. S.initialNameLevel .. "！"
            GameState.addDateLog(S.initialName, "好感提升",
                "好感度等级提升到 " .. S.initialNameLevel .. "，五维各+1。")
            GameState.showNotification(msg)
        end
    elseif character == "k" then
        while S.kAffection >= 100 do
            S.kLevel = S.kLevel + 1
            S.kAffection = S.kAffection - 100
            S.K_LL = S.K_LL + 1
            S.K_LG = S.K_LG + 1
            S.K_ML = S.K_ML + 1
            S.K_NL = S.K_NL + 1
            S.K_JQ = S.K_JQ + 1
            msg = "K 的好感度等级提升到 " .. S.kLevel .. "！"
            GameState.addDateLog("K", "好感提升",
                "好感度等级提升到 " .. S.kLevel .. "，五维各+1。")
            GameState.showNotification(msg)
        end
    elseif character == "gangBoss" then
        local oldLevel = S.gangBossLevel or 1
        while S.gangBossAffection >= 50 do
            S.gangBossLevel = (S.gangBossLevel or 1) + 1
            S.gangBossAffection = S.gangBossAffection - 50
            msg = "黑帮少主 的好感度等级提升到 " .. S.gangBossLevel .. "！"
            GameState.addDateLog("黑帮少主", "好感提升",
                "好感度等级提升到 " .. S.gangBossLevel .. "。")
            GameState.showNotification(msg)
        end
    end
    return msg
end

--- 增加主要NPC好感度
---@param character string "initialName" 或 "k" 或 "gangBoss"
---@param amount number
function NPCSystem.addAffection(character, amount)
    local S = GameState.state
    if character == "initialName" then
        S.initialNameAffection = S.initialNameAffection + amount
        NPCSystem.affectionUpgrade("initialName")
    elseif character == "k" then
        S.kAffection = S.kAffection + amount
        NPCSystem.affectionUpgrade("k")
    elseif character == "gangBoss" then
        S.gangBossAffection = (S.gangBossAffection or 0) + amount
        NPCSystem.affectionUpgrade("gangBoss")
    end
end

-- ==================== 奥梅尔好感度（每50点一级，技能解锁） ====================

--- 增加奥梅尔好感度
---@param amount number
function NPCSystem.addOamelAffection(amount)
    local S = GameState.state
    local oldLevel = math.floor(S.oamelAffection / 50) + 1
    S.oamelAffection = S.oamelAffection + amount
    local newLevel = math.floor(S.oamelAffection / 50) + 1

    if newLevel > oldLevel then
        for i = oldLevel + 1, newLevel do
            local bonus = 0
            if i == 2 then bonus = 5
            elseif i == 3 then bonus = 10
            end
            if bonus > 0 then
                S.oamelSkillActive = true
                -- 取更高等级的加成（而非覆盖）
                S.oamelSkillBonus = math.max(S.oamelSkillBonus or 0, bonus)
                GameState.addDateLog("奥梅尔·罗斯巴特", "技能解锁",
                    "获得“贵族的手腕”：打工工资+" .. bonus .. "%。")
                GameState.showNotification(
                    "罗斯巴特少爷对你的态度变了：“贵族的手腕”技能解锁，打工工资+" .. bonus .. "%！")
            end
        end
        GameState.addDateLog("奥梅尔·罗斯巴特", "好感提升",
            "好感度等级提升到 " .. newLevel .. "。")
        GameState.showNotification(
            "你与奥梅尔·罗斯巴特的关系加深了！好感等级" .. newLevel .. "。")
    end
end

-- ==================== 梅菲斯好感度（每50点一级，工资加成） ====================

--- 增加梅菲斯好感度
---@param amount number
function NPCSystem.addMeifeiAffection(amount)
    local S = GameState.state
    local oldLevel = S.meifeiLevel
    S.meifeiAffection = S.meifeiAffection + amount
    local newLevel = math.floor(S.meifeiAffection / 50) + 1

    if newLevel > oldLevel then
        local levelGain = newLevel - oldLevel
        S.meifeiWageBonus = S.meifeiWageBonus + levelGain * 10
        S.meifeiLevel = newLevel
        -- 梅菲斯升级还给礼仪经验（需 WorkSystem，延迟调用）
        NPCSystem._pendingMeifeiMannerExp = (NPCSystem._pendingMeifeiMannerExp or 0) + levelGain
        GameState.addDateLog("梅菲斯", "好感提升",
            "好感度等级提升到 " .. newLevel .. "，时薪+" .. (levelGain * 10) .. "，礼仪经验+" .. levelGain .. "。")
        GameState.showNotification(
            "梅菲斯对你的好感加深了！时薪+" .. (levelGain * 10) .. "，礼仪经验+" .. levelGain .. "。")
    end
end

-- ==================== 乌列尔好感度（每50点一级，暗中守护） ====================

--- 增加乌列尔好感度
---@param amount number
function NPCSystem.addUrielAffection(amount)
    local S = GameState.state
    local oldLevel = S.urielLevel
    S.urielAffection = S.urielAffection + amount
    local newLevel = math.floor(S.urielAffection / 50) + 1

    if newLevel > oldLevel then
        S.urielLevel = newLevel
        GameState.addDateLog("乌列尔", "好感提升",
            "好感度等级提升到 " .. newLevel .. "。")
        GameState.showNotification(
            "你感觉到那个人一直在你身后。乌列尔好感等级" .. newLevel .. "。")
    end
end

-- ==================== 次要NPC好感度系统 ====================

--- NPC好感度等级映射
local NPC_LEVEL_THRESHOLDS = { 15, 30, 50, 70, 90 }

--- 获取NPC好感度等级（0~5）
---@param val number
---@return number
function NPCSystem.getNpcLevel(val)
    for i = #NPC_LEVEL_THRESHOLDS, 1, -1 do
        if val >= NPC_LEVEL_THRESHOLDS[i] then
            return i
        end
    end
    return 0
end

--- NPC名称映射
local NPC_NAMES = {
    sinchi = "辛奇",
    clarice = "克丽丝",
    macnana = "麦拿拿",
    blackbeard = "黑胡子",
    -- 第三批NPC
    felix = "费利克斯",
    isabella = "伊莎贝拉",
    jasper = "贾斯帕",
    nora = "诺拉",
    sebastian = "塞巴斯蒂安",
    xiaomei = "小梅",
}

--- 家具映射
local NPC_FURNITURE = {
    sinchi    = { var = "furnitureCoffee",  name = "咖啡机" },
    clarice   = { var = "furnitureBible",   name = "圣典" },
    macnana   = { var = "furnitureDummy",   name = "训练铁人" },
    blackbeard = { var = "furnitureSeagull", name = "小海鸥装饰" },
}

--- NPC好感升级时的台词
local NPC_LEVEL_UP_LINES = {
    sinchi    = "和辛奇的关系加深了。他塞给你一杯酒：“好好干。”",
    clarice   = "和克丽丝的关系加深了。她微笑着说：“愿太阳神保佑你。”",
    macnana   = "和麦拿拿的关系加深了。他拍着你肩膀：“小子，有前途！”",
    blackbeard = "和黑胡子的关系加深了。他咧嘴一笑：“以后跟我混。”",
    -- 第三批NPC
    felix = "和费利克斯的关系加深了。他递来一块热腾腾的面包：“尝尝，今天的新配方。”",
    isabella = "和伊莎贝拉的关系加深了。她把一束干花别在你胸前：“薰衣草，安神用的。”",
    jasper = "和贾斯帕的关系加深了。他点了点头：“夜路走多了，总会遇见值得信任的人。”",
    nora = "和诺拉的关系加深了。她量了量你的肩宽：“下次给你做件合身的。”",
    sebastian = "和塞巴斯蒂安的关系加深了。他翻开笔记本：“这页留给你——值得记录的人。”",
    xiaomei = "和小梅的关系加深了。她把最新鲜的一条鱼塞给你：“不许推辞！”",
}

--- NPC赠书映射（好感达到指定等级时赠送）
local NPC_BOOK_GIFTS = {
    clarice   = { var = "hasTheologyBook", name = "《圣典基础教义》", level = 2 },
    macnana   = { var = "hasRepairBook",   name = "《机械修理入门》", level = 2 },
}

--- 赠送家具
---@param npc string
function NPCSystem.giveFurniture(npc)
    local S = GameState.state
    local info = NPC_FURNITURE[npc]
    if not info then return end
    S[info.var] = true
    local npcName = NPC_NAMES[npc] or npc
    GameState.addDateLog(npcName, "赠送家具", "送来了" .. info.name .. "。")
    GameState.showNotification("你收到了" .. npcName .. "送的礼物！")
end

--- 赠送书籍（好感升级时检查）
---@param npc string
---@param newLevel number
function NPCSystem.checkBookGift(npc, newLevel)
    local S = GameState.state
    local gift = NPC_BOOK_GIFTS[npc]
    if not gift then return end
    if newLevel >= gift.level and not S[gift.var] then
        S[gift.var] = true
        local npcName = NPC_NAMES[npc] or npc
        GameState.addDateLog(npcName, "赠送书籍", npcName .. "送给你一本" .. gift.name .. "。")
        GameState.showNotification(npcName .. "赠送了" .. gift.name .. "！可以在家中阅读。")
    end
end

--- 增加次要NPC好感度（含升级检查和家具赠送）
---@param npc string "sinchi"/"clarice"/"macnana"/"blackbeard"
---@param amount number
function NPCSystem.addNpcAffection(npc, amount)
    local S = GameState.state
    local varName = "npc" .. npc:sub(1, 1):upper() .. npc:sub(2)
    local current = S[varName] or 0
    local newVal = current + amount
    local oldLevel = NPCSystem.getNpcLevel(current)
    local newLevel = NPCSystem.getNpcLevel(newVal)
    S[varName] = newVal

    if newLevel > oldLevel then
        local npcName = NPC_NAMES[npc] or npc
        local logMsg = NPC_LEVEL_UP_LINES[npc] or ("和" .. npcName .. "的关系加深了。")
        GameState.addDateLog(npcName, "好感提升", logMsg)
        GameState.showNotification(logMsg)
        -- 首次达到等级1时赠送家具
        if oldLevel == 0 and newLevel >= 1 then
            NPCSystem.giveFurniture(npc)
        end
        -- 检查赠书
        NPCSystem.checkBookGift(npc, newLevel)
    end
end

--- 修改玩家属性（委托给 GameState.modStat）
---@param stat string 属性键名（如 "YG", "LG", "JQ" 等）
---@param delta number 增减量
function NPCSystem.modStat(stat, delta)
    GameState.modStat(stat, delta)
end

return NPCSystem
