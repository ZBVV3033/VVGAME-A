-- ============================================================================
-- BattleSystem.lua - 回合制战斗系统 · 聚合入口（悠闲悠哉life）
-- 本文件仅负责创建 BattleSystem 表并加载各子模块。
-- 所有实现已拆分至 systems/battle/ 目录：
--   BattleUtils.lua       共享工具函数（deepCopy、getUniCombatBonuses 等）
--   PartySystem.lua       队伍初始化、职业/技能体系、属性分配、状态文本
--   EnemySystem.lua       敌人技能实现 + AI 回合逻辑
--   PlayerSkills.lua      玩家三角色全部技能实现
--   BattleCore.lua        战斗流程核心（回合管理、胜败判定、数据持久化）
--   ForestExploration.lua 渡劫森林探索、事件、商人
--   BattlePassages.lua    所有战斗/森林相关段落（getPassage）
-- ============================================================================

local BattleData = require("data.BattleData")

-- 创建主表
local BattleSystem = {}

-- 数据引用
BattleSystem.ENEMY_TEMPLATES = BattleData.ENEMY_TEMPLATES

-- ==================== 加载子模块 ====================
-- 每个子模块返回 installer 函数: function(BS) ... end
-- 调用后会将方法安装到 BattleSystem 表上

require("systems.battle.PartySystem")(BattleSystem)
require("systems.battle.EnemySystem")(BattleSystem)
require("systems.battle.PlayerSkills")(BattleSystem)
require("systems.battle.BattleCore")(BattleSystem)
require("systems.battle.ForestExploration")(BattleSystem)
require("systems.battle.BattlePassages")(BattleSystem)

return BattleSystem
