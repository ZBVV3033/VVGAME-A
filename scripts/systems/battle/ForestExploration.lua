-- ============================================================================
-- ForestExploration.lua - 森林探索、事件、商人、遇敌系统
-- ============================================================================

local GameState = require("systems.GameState")
local BattleData = require("data.BattleData")

--- 安装森林探索系统到 BattleSystem
---@param BS table BattleSystem 主表
return function(BS)

-- 数据引用
BS.FOREST_EVENTS = BattleData.FOREST_EVENTS
BS.MERCHANT_ITEMS = BattleData.MERCHANT_ITEMS

-- ==================== 遇敌判定 ====================

--- 判断是否遇敌（55%概率）
---@return boolean
function BS.checkEncounter()
    return math.random() < 0.55
end

--- 无遇敌时推进层数
function BS.advanceLayer()
    local S = GameState.state
    if S.forestLayer <= S.maxLayer then
        S.forestLayer = S.forestLayer + 1
    end
end

--- 森林是否已通关
---@return boolean
function BS.isForestCleared()
    local S = GameState.state
    return S.forestLayer > S.maxLayer
end

--- 重置森林（重新挑战）
function BS.resetForest()
    local S = GameState.state
    S.forestLayer = 1
    S.eventFruitUsed = false
    S.boughtPotion = false
    S.healUsedToday = 0
    S.dailyBuffs = { phys = 0, magic = 0, def = 0 }
end

-- ==================== 森林事件 ====================

--- 随机获取一个森林事件
---@return string
function BS.getRandomForestEvent()
    local idx = math.random(1, #BS.FOREST_EVENTS)
    return BS.FOREST_EVENTS[idx]
end

--- 处理果树事件
---@param choice string "red"(力量+1) / "blue"(灵感+1) / "leave"
---@return string 结果文本
function BS.handleFruitEvent(choice)
    local S = GameState.state
    if S.eventFruitUsed then
        return "果树上的果实已经被摘光了。"
    end
    if choice == "red" then
        S.eventFruitUsed = true
        S.playerCombat.power = S.playerCombat.power + 1
        return "你吃了红色果实，力量+1！"
    elseif choice == "blue" then
        S.eventFruitUsed = true
        S.playerCombat.insight = S.playerCombat.insight + 1
        return "你吃了蓝色果实，灵感+1！"
    else
        return "你离开了果树。"
    end
end

--- 处理温泉事件
---@param choice string "soak"(恢复20%HP) / "drink"(最大HP+5)
---@return string 结果文本
function BS.handleHotspringEvent(choice)
    local S = GameState.state
    if choice == "soak" then
        for _, p in ipairs(S.party) do
            p.hp = math.min(p.maxHp, p.hp + math.floor(p.maxHp * 0.2))
        end
        return "你们在温泉中休息，全体恢复20%生命值。"
    elseif choice == "drink" then
        S.playerCombat.maxHp = S.playerCombat.maxHp + 5
        S.playerCombat.hp = S.playerCombat.hp + 5
        return "你饮用泉水，最大HP+5！"
    end
    return ""
end

-- ==================== 商人系统 ====================

--- 购买商人物品
---@param itemId string
---@return boolean ok
---@return string msg
function BS.buyMerchantItem(itemId)
    local S = GameState.state

    if itemId == "phys_buff" then
        if S.gold < 100 then return false, "金币不足！" end
        S.gold = S.gold - 100
        S.dailyBuffs.phys = 0.3
        return true, "购买成功！物理伤害+30%。"

    elseif itemId == "magic_buff" then
        if S.gold < 100 then return false, "金币不足！" end
        S.gold = S.gold - 100
        S.dailyBuffs.magic = 0.3
        return true, "购买成功！魔法伤害+30%。"

    elseif itemId == "def_buff" then
        if S.gold < 100 then return false, "金币不足！" end
        S.gold = S.gold - 100
        S.dailyBuffs.def = 3
        return true, "购买成功！防御+3。"

    elseif itemId == "potion" then
        if S.boughtPotion then return false, "血红色药水限购1瓶！" end
        if S.gold < 100 then return false, "金币不足！" end
        S.gold = S.gold - 100
        S.boughtPotion = true
        S.playerCombat.maxHp = S.playerCombat.maxHp + 10
        S.playerCombat.hp = S.playerCombat.hp + 10
        return true, "购买成功！最大HP+10。"

    elseif itemId == "heal_self" then
        if S.gold < 50 then return false, "金币不足！" end
        S.gold = S.gold - 50
        S.playerCombat.hp = S.playerCombat.maxHp
        S.playerCombat.mp = S.playerCombat.maxMp
        return true, "恢复完毕！HP/MP已满。"

    elseif itemId == "heal_all" then
        if S.gold < 150 then return false, "金币不足！" end
        S.gold = S.gold - 150
        S.playerCombat.hp = S.playerCombat.maxHp
        S.playerCombat.mp = S.playerCombat.maxMp
        if S.kInParty then
            S.kCombat.hp = S.kCombat.maxHp
            S.kCombat.mp = S.kCombat.maxMp
        end
        return true, "全队恢复完毕！"
    end

    return false, "未知物品。"
end

end -- installer
