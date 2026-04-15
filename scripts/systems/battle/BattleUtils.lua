-- ============================================================================
-- BattleUtils.lua - 战斗系统共享工具函数
-- 供各战斗子模块 require 使用
-- ============================================================================

local GameState = require("systems.GameState")

local M = {}

--- 深拷贝表
---@param orig any
---@return any
function M.deepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = M.deepCopy(v)
    end
    return copy
end

--- 获取大学专业战斗加成（延迟加载避免循环依赖）
---@return table { phys = 0.0, magic = 0.0, mdef = 0.0 }
function M.getUniCombatBonuses()
    local S = GameState.state
    return {
        phys = S.uniCombatBonus_phys or 0,
        magic = S.uniCombatBonus_magic or 0,
        mdef = S.uniCombatBonus_mdef or 0,
    }
end

--- 获取血量最低的存活目标
---@param list table[]
---@return table|nil
function M.getLowestHpTarget(list)
    local lowest = nil
    local minHp = math.huge
    for _, p in ipairs(list) do
        if p.hp > 0 and p.hp < minHp then
            minHp = p.hp
            lowest = p
        end
    end
    return lowest
end

--- 获取第一个存活敌人
---@return table|nil
function M.getFirstLiveEnemy()
    local S = GameState.state
    for _, e in ipairs(S.enemies) do
        if e.hp > 0 then return e end
    end
    return nil
end

--- 获取所有存活敌人
---@return table[]
function M.getAllLiveEnemies()
    local S = GameState.state
    local live = {}
    for _, e in ipairs(S.enemies) do
        if e.hp > 0 then
            table.insert(live, e)
        end
    end
    return live
end

return M
