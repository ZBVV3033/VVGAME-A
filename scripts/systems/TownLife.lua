-- ============================================================================
-- TownLife.lua - 小镇生活系统（悠闲悠哉life）
-- 随机街头事件 + 新NPC + 好感度人物互动
-- 每个地点调用 TownLife.getEvents(location) 获取追加内容
-- 含贫民窟区域事件 | NPC段落已拆分至 passages/ 目录
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name, unknown-symbol, miss-symbol, exp-in-action, miss-exp, action-after-return

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local BattleSystem = require("systems.BattleSystem")
local CommonUtils = require("utils.CommonUtils")

local TownNPCData = require("data.TownNPCData")

-- 段落处理模块（handler registry 模式）
local _passageModules = {
    require("passages.TownPassages_Base"),
    require("passages.TownPassages_Special"),
    require("passages.TownPassages_Batch3"),
    require("passages.TownPassages_Events"),
}

local TownLife = {}

-- ==================== 工具函数（来自 CommonUtils） ====================
local getTimePeriod = CommonUtils.getTimePeriod
local tryEvent = CommonUtils.tryEvent
local chance = CommonUtils.chance

-- ==================== 新NPC资料（从 TownNPCData 引用） ====================

TownLife.NPC_INFO = TownNPCData.NPC_INFO

-- ==================== 地点事件数据 ====================
-- 每个事件: { id, prob, cond?, text, choices? }
-- cond: function(S) -> bool 触发条件
-- text: 追加到地点描述的文字
-- choices: 额外的选项 { text, target, action? }

--- 获取指定地点的随机事件
---@param location string 地点名
---@return { text: string, choices: table[] }
local TownEvents = require("systems.townlife.Events")

function TownLife.getEvents(location)
    return TownEvents.getEvents(location, TownLife)
end


-- ==================== NPC互动场景 Passage ====================
-- 通过 handler registry 模式分发到各段落模块

function TownLife.getPassage(passageName)
    for _, mod in ipairs(_passageModules) do
        local handler = mod[passageName]
        if handler then return handler() end
    end
    return nil
end

return TownLife
