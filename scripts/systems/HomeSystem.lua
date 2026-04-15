-- ============================================================================
-- HomeSystem.lua - 家庭生活系统（悠闲悠哉life）
-- 家中房间探索 / 莱德日常互动 / K来访 / 奥梅尔来访 / 乌列尔信件
-- ============================================================================
-- 段落逻辑已拆分至:
--   passages/HomePassages_Rooms.lua  (5个房间段落)
--   passages/HomePassages_Events.lua (8个事件段落)
-- 事件数据已拆分至:
--   data/HomeEventData.lua
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local GameState = require("systems.GameState")
local CommonUtils = require("utils.CommonUtils")

local HomeSystem = {}

-- ==================== 工具函数别名 ====================
local chance = CommonUtils.chance

-- ==================== 段落 handler 注册 ====================
local _homeHandlers = {}
for k, v in pairs(require("passages.HomePassages_Rooms")) do _homeHandlers[k] = v end
for k, v in pairs(require("passages.HomePassages_Events")) do _homeHandlers[k] = v end

-- ==================== 每日重置 ====================

function HomeSystem.onDayChange()
    local S = GameState.state
    S.homeEventSeen = {}
    S.homeEventCount = 0
    S.homeProfessorAsked = false
    S._todayLeideWound = false
    S.oamelVisitHandled = false   -- 重置奥梅尔来访处理标记
    S.urielLetterHandled = false  -- 重置乌列尔信件处理标记
    -- 奥梅尔来访判定（好感>=100，20%概率，非连续来访）
    if (S.oamelAffection or 0) >= 100 and not S.oamelVisitingToday then
        S.oamelVisitingToday = chance(20)
    else
        S.oamelVisitingToday = false
    end
    -- K来访判定（好感>=100，30%概率）
    if (S.kAffection or 0) >= 100 and not S.kVisiting then
        if chance(30) then
            S.kVisiting = true
        end
    end
    -- 乌列尔信件（好感>=50，每7天15%概率）
    if (S.urielAffection or 0) >= 50 and (S.day or 1) % 7 == 0 then
        if chance(15) then
            S.urielLetterPending = true
        end
    end
end

-- ==================== 段落系统 ====================

function HomeSystem.getPassage(passageName)
    local handler = _homeHandlers[passageName]
    if handler then return handler() end
    return nil
end

return HomeSystem
