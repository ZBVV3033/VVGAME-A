-- ============================================================================
-- CommonUtils.lua - 公共工具函数（悠闲悠哉life）
-- 从 PassageData / TownLife / HomeSystem / RandomEvents / SideQuests 中
-- 提取的重复工具函数，统一在此维护。
-- ============================================================================

local GameState = require("systems.GameState")
local NPCSystem = require("systems.NPCSystem")

local CommonUtils = {}

--- 获取当前时段（英文标识）
---@return "morning"|"afternoon"|"evening"|"night"
function CommonUtils.getTimePeriod()
    local S = GameState.state
    local h = (S and S.hour) or 8
    if h >= 6 and h < 12 then return "morning"
    elseif h >= 12 and h < 18 then return "afternoon"
    elseif h >= 18 and h < 22 then return "evening"
    else return "night" end
end

--- 获取当前时段的中文名称
---@return string
function CommonUtils.getTimePeriodCN()
    local p = CommonUtils.getTimePeriod()
    if p == "morning" then return "早晨"
    elseif p == "afternoon" then return "午后"
    elseif p == "evening" then return "黄昏"
    else return "深夜" end
end

--- 按百分比概率判断（1-100）
---@param pct number 成功概率百分比
---@return boolean
function CommonUtils.chance(pct)
    return math.random(1, 100) <= pct
end

--- 获取莱德的名字（玩家自定义或默认）
---@return string
function CommonUtils.leideName()
    return GameState.state.initialName or "莱德"
end

--- 增加好感度（委托 NPCSystem）
---@param target string NPC标识
---@param amount number 好感度变化量
function CommonUtils.addAffection(target, amount)
    if NPCSystem and NPCSystem.addAffection then
        NPCSystem.addAffection(target, amount)
    end
end

--- 添加约会/互动日志
---@param person string 对象名字
---@param logType string 日志类型
---@param content string 日志内容
function CommonUtils.addDateLog(person, logType, content)
    local S = GameState.state
    if not S.dateLogs then S.dateLogs = {} end
    table.insert(S.dateLogs, {
        person = person,
        type = logType,
        content = content,
        date = string.format("%d年%d月 第%d天", S.year or 499, S.month or 1, S.day or 1),
        day = S.day,
        hour = S.hour,
    })
end

--- 今日事件限制检查（标记事件已触发，返回是否可触发）
---@param eventId string 事件唯一标识
---@return boolean 是否可触发
function CommonUtils.tryEvent(eventId)
    local S = GameState.state
    if S.townEventSeen[eventId] then return false end
    if S.townEventCount >= 5 then return false end
    S.townEventSeen[eventId] = true
    S.townEventCount = S.townEventCount + 1
    return true
end

--- 属性检定：成功率 = base + stat * mult
---@param statName string 属性字段名
---@param base number 基础成功率
---@param mult number? 属性乘数（默认5）
---@return boolean
function CommonUtils.statCheck(statName, base, mult)
    local val = GameState.state[statName] or 1
    local successRate = math.min(95, math.max(5, base + val * (mult or 5)))
    return math.random(1, 100) <= successRate
end

return CommonUtils
