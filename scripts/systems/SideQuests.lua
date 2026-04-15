-- ============================================================
-- SideQuests.lua — 支线任务系统
-- ============================================================

local SideQuests = {}

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local CommonUtils = require("utils.CommonUtils")

-- 工具函数（来自 CommonUtils）
local addAffection = CommonUtils.addAffection

-- 辅助：增加好感度（小镇NPC直接加数值）
local function addNpc(key, amount)
    local S = GameState.state
    S[key] = (S[key] or 0) + amount
end

local SQPassages = require("systems.sidequests.Passages")

function SideQuests.getPassage(passageName)
    return SQPassages.getPassage(passageName, SideQuests)
end


return SideQuests
