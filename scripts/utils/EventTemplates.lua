-- ============================================================================
-- EventTemplates.lua - 事件系统共享工具
-- 从 WorkSystem / HomePassages_Events / RandomEventData 中提取的
-- 重复逻辑，统一在此维护。
-- ============================================================================

local GameState = require("systems.GameState")
local NPCSystem = require("systems.NPCSystem")
local TimeSystem = require("systems.TimeSystem")

local ET = {}

-- ==================== NPC 显示名称映射 ====================

---@type table<string, string>
local NPC_LABELS = {
    initialName = nil, -- 动态：取 S.initialName
    k           = "K",
    npcSinchi   = "辛奇",
    npcClarice  = "克丽丝",
    npcMacnana  = "麦拿拿",
    npcBlackbeard = "黑胡子",
    oamelAffection = "小奥",
    meifeiAffection = "梅菲斯",
}

--- 获取 NPC 显示名称
---@param key string NPC 标识
---@return string
function ET.npcLabel(key)
    if key == "initialName" then
        return GameState.state.initialName or "莱德"
    end
    return NPC_LABELS[key] or key
end

-- ==================== 奖励效果应用 ====================
-- 适用于 WorkEventData 的声明式选项结构：
-- { gold, exp, item, npc, npcAmt, npc2, npc2Amt }

--- 应用声明式奖励效果，返回描述行数组
---@param choice table 选项定义（含 gold/exp/item/npc/npcAmt 等字段）
---@param addExpFn function? 自定义经验添加函数（默认直接加 S.exp）
---@return string[] lines 效果描述行
function ET.applyRewardEffects(choice, addExpFn)
    local S = GameState.state
    local lines = {}

    -- 金币
    if choice.gold and choice.gold ~= 0 then
        S.money = S.money + choice.gold
        if choice.gold > 0 then
            lines[#lines + 1] = "💰 +" .. choice.gold .. " 金币"
        else
            lines[#lines + 1] = "💸 " .. choice.gold .. " 金币"
        end
    end

    -- 经验
    if choice.exp and choice.exp > 0 then
        if addExpFn then
            addExpFn(choice.exp)
        else
            S.exp = (S.exp or 0) + choice.exp
        end
        lines[#lines + 1] = "⭐ +" .. choice.exp .. " 生活经验"
    end

    -- 物品
    if choice.item then
        S.inventory = S.inventory or {}
        table.insert(S.inventory, choice.item)
        lines[#lines + 1] = "🎁 获得：" .. choice.item
    end

    -- NPC 好感（主要 NPC）
    if choice.npc and choice.npcAmt then
        NPCSystem.addAffection(choice.npc, choice.npcAmt)
        local label = ET.npcLabel(choice.npc)
        if choice.npcAmt > 0 then
            lines[#lines + 1] = "❤️ " .. label .. " 好感+" .. choice.npcAmt
        else
            lines[#lines + 1] = "💔 " .. label .. " 好感" .. choice.npcAmt
        end
    end

    -- NPC 好感（第二 NPC）
    if choice.npc2 and choice.npc2Amt then
        NPCSystem.addAffection(choice.npc2, choice.npc2Amt)
        local label = ET.npcLabel(choice.npc2)
        if choice.npc2Amt > 0 then
            lines[#lines + 1] = "❤️ " .. label .. " 好感+" .. choice.npc2Amt
        end
    end

    return lines
end

--- 将效果描述行拼接为奖励文本
---@param lines string[]
---@return string
function ET.formatRewardText(lines)
    if #lines > 0 then
        return "\n\n" .. table.concat(lines, "　")
    end
    return ""
end

-- ==================== 属性检定执行 ====================
-- 适用于 WorkEventData 的声明式 statCheck 结构：
-- { stat, threshold, successResult, failResult, successGold, successExp,
--   successNpc, successNpcAmt, failGold, failExp, knowledgeId, knowledgeBonus,
--   successItem }

---@type table<string, string>
ET.STAT_NAMES = {
    ML = "魅力", ZL = "智力", TL = "体力",
    LL = "力量", JQ = "技巧", NL = "耐力", LG = "灵感",
}

--- 执行声明式属性检定，应用效果并返回结果文本
---@param sc table statCheck 定义
---@param baseLines string[]? 已有的效果描述行（会被追加）
---@param knowledgeDefs table? 知识定义表（用于知识加成）
---@param addExpFn function? 自定义经验添加函数
---@param fallbackResult string? 默认结果文本
---@return string 结果描述文本
function ET.executeStatCheck(sc, baseLines, knowledgeDefs, addExpFn, fallbackResult)
    local S = GameState.state
    local lines = baseLines or {}
    local statVal = S[sc.stat] or 0
    local statName = ET.STAT_NAMES[sc.stat] or sc.stat

    -- 知识加成
    local effectiveThreshold = sc.threshold
    if sc.knowledgeId and sc.knowledgeBonus and knowledgeDefs then
        local kDef = knowledgeDefs[sc.knowledgeId]
        if kDef then
            local kLv = S[kDef.levelVar] or 0
            if kLv > 0 then
                local bonus = kLv * sc.knowledgeBonus
                effectiveThreshold = math.max(1, effectiveThreshold - bonus)
                lines[#lines + 1] = "📖 " .. kDef.name .. "Lv." .. kLv .. " 知识加成（阈值-" .. bonus .. "）"
            end
        end
    end

    if statVal >= effectiveThreshold then
        -- 检定成功
        lines[#lines + 1] = "🎯 " .. statName .. "检定成功（" .. statVal .. "/" .. effectiveThreshold .. "）"
        if sc.successGold then
            S.money = S.money + sc.successGold
            lines[#lines + 1] = "💰 +" .. sc.successGold .. " 金币"
        end
        if sc.successExp then
            if addExpFn then addExpFn(sc.successExp) else S.exp = (S.exp or 0) + sc.successExp end
            lines[#lines + 1] = "⭐ +" .. sc.successExp .. " 生活经验"
        end
        if sc.successNpc and sc.successNpcAmt then
            NPCSystem.addAffection(sc.successNpc, sc.successNpcAmt)
        end
        if sc.successItem then
            S.inventory = S.inventory or {}
            table.insert(S.inventory, sc.successItem)
            lines[#lines + 1] = "🎁 获得：" .. sc.successItem
        end
        local result = sc.successResult or fallbackResult or "事件结束。"
        return result .. ET.formatRewardText(lines)
    else
        -- 检定失败
        lines[#lines + 1] = "❌ " .. statName .. "检定失败（" .. statVal .. "/" .. effectiveThreshold .. "）"
        if sc.failGold then
            S.money = S.money + sc.failGold
            if sc.failGold > 0 then
                lines[#lines + 1] = "💰 +" .. sc.failGold .. " 金币"
            else
                lines[#lines + 1] = "💸 " .. sc.failGold .. " 金币"
            end
        end
        if sc.failExp then
            if addExpFn then addExpFn(sc.failExp) else S.exp = (S.exp or 0) + sc.failExp end
            lines[#lines + 1] = "⭐ +" .. sc.failExp .. " 生活经验"
        end
        local result = sc.failResult or fallbackResult or "事情没有按预想的发展。"
        return result .. ET.formatRewardText(lines)
    end
end

-- ==================== 家庭事件选项效果应用 ====================
-- 适用于 HomeEventData 的选项结构：
-- { aff, time, fatigue, stress, satiety }

--- 应用家庭事件选项效果
---@param c table 选项定义（含 aff/time/fatigue/stress/satiety）
---@param npcKey string? 好感对象（默认 "initialName"）
function ET.applyHomeChoiceEffects(c, npcKey)
    local S = GameState.state
    local target = npcKey or "initialName"

    if c.aff and c.aff ~= 0 then
        NPCSystem.addAffection(target, c.aff)
    end
    if c.time then
        TimeSystem.addMinutes(c.time)
    end
    if c.fatigue then
        GameState.modStat("fatigue", c.fatigue)
    end
    if c.stress then
        GameState.modStat("stress", c.stress)
    end
    if c.satiety then
        GameState.modStat("satiety", c.satiety)
    end
end

--- 批量应用属性修改（用于 RandomEventData 中的内联效果）
--- 例: ET.modStats({ money = -10, stress = 5, ML = 2 })
---@param mods table<string, number> 属性名到变化量的映射
function ET.modStats(mods)
    local S = GameState.state
    for stat, delta in pairs(mods) do
        if stat == "money" then
            S.money = (S.money or 0) + delta
        elseif stat == "stress" then
            GameState.modStat("stress", delta)
        elseif stat == "fatigue" then
            GameState.modStat("fatigue", delta)
        elseif stat == "satiety" then
            GameState.modStat("satiety", delta)
        else
            GameState.modStat(stat, delta)
        end
    end
end

--- 应用效果并显示通知（用于简化 RandomEventData 中的 action 函数）
---@param mods table<string, number> 属性修改映射
---@param message string 通知消息
function ET.modStatsAndNotify(mods, message)
    ET.modStats(mods)
    GameState.showNotification(message)
end

return ET
