-- ============================================================================
-- RandomEvents.lua - 随机事件入口（悠闲悠哉life）
-- 委托三个子模块：生存事件、属性检定事件、连锁事件段落
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local RandomEventData_Survival  = require("data.RandomEventData_Survival")
local RandomEventData_StatCheck = require("data.RandomEventData_StatCheck")

local RandomEvents = {}

-- ==================== 段落 handler 注册表 ====================

local _randomHandlers = {}
for k, v in pairs(require("passages.RandomPassages")) do _randomHandlers[k] = v end

--- 获取连锁事件段落
function RandomEvents.getPassage(passageName)
    local handler = _randomHandlers[passageName]
    if handler then return handler() end
    return nil
end

-- ==================== 主入口 ====================

--- 获取指定地点的随机事件（追加到地点描述）
function RandomEvents.getEvents(location)
    local survText, survChoices = RandomEventData_Survival.getSurvivalEvents(location)
    local statText, statChoices = RandomEventData_StatCheck.getStatCheckEvents(location)

    local text = survText .. statText
    local choices = {}
    for _, c in ipairs(survChoices) do table.insert(choices, c) end
    for _, c in ipairs(statChoices) do table.insert(choices, c) end

    return { text = text, choices = choices }
end

return RandomEvents
