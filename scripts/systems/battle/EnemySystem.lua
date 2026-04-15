-- ============================================================================
-- EnemySystem.lua - 敌人技能库 + AI 行动
-- ============================================================================

local GameState = require("systems.GameState")
local Utils = require("systems.battle.BattleUtils")

--- 安装敌人系统到 BattleSystem
---@param BS table BattleSystem 主表
return function(BS)

-- ==================== 敌人技能库 ====================

BS.enemySkills = {}

--- 普通攻击（取物理/魔法伤害的较大者）
function BS.enemySkills.attack(caster, target, party)
    local physRaw = caster.atkBase + 2 * (caster.power + (caster.buffStr or 0))
    local physDmg = math.max(1, physRaw - target.def)

    local magRaw = (caster.matkBase or 0) + 2 * caster.insight
    local magDmg = math.max(1, magRaw * (1 - (target.mdef or 0)))

    if physDmg >= magDmg then
        target.hp = target.hp - physDmg
        return string.format("%s使用冲撞，对%s造成 %.1f 点物理伤害。",
            caster.name, target.name, physDmg)
    else
        target.hp = target.hp - magDmg
        return string.format("%s使用暗影球，对%s造成 %.1f 点魔法伤害。",
            caster.name, target.name, magDmg)
    end
end

--- 硬化（防御+2，力量+1，2回合）
function BS.enemySkills.harden(caster, target, party)
    caster.buffDef = (caster.buffDef or 0) + 2
    caster.buffStr = (caster.buffStr or 0) + 1
    caster.buffTurns = 2
    return caster.name .. "使用硬化，防御+2，力量+1，持续2回合。"
end

--- 粉身碎骨（高伤害，降低自身防御）
function BS.enemySkills.smash(caster, target, party)
    caster.def = math.max(0, caster.def - 1)
    local raw = caster.atkBase + 4 * (caster.power + (caster.buffStr or 0))
    local damage = math.max(1, raw - target.def)
    target.hp = target.hp - damage
    return string.format("%s使用粉身碎骨，对%s造成 %.1f 点伤害，自身防御-1。",
        caster.name, target.name, damage)
end

--- 腐蚀气息（全体魔法伤害+腐烂）
function BS.enemySkills.corrosion(caster, target, party)
    local msgs = {}
    for _, p in ipairs(party) do
        if p.hp > 0 then
            local dmg = 10 * (1 - (p.mdef or 0))
            dmg = math.max(1, math.floor(dmg))
            p.hp = p.hp - dmg
            p.rotTurns = 2
            table.insert(msgs, string.format("%s受到 %d 点腐蚀伤害", p.name, dmg))
        end
    end
    return caster.name .. "使用腐蚀气息，" .. table.concat(msgs, "，") .. "，施加腐烂2回合。"
end

--- 毒孢子（单体魔法伤害+中毒2回合）
function BS.enemySkills.poison_spore(caster, target, party)
    local magRaw = (caster.matkBase or 0) + 2 * caster.insight
    local dmg = math.max(1, magRaw * (1 - (target.mdef or 0)))
    target.hp = target.hp - dmg
    target.poisonTurns = (target.poisonTurns or 0) + 2
    return string.format("%s释放毒孢子，对%s造成 %.1f 点毒素伤害，中毒2回合。",
        caster.name, target.name, dmg)
end

--- 荆棘缠绕（单体伤害+降速2回合）
function BS.enemySkills.thorn_bind(caster, target, party)
    local raw = caster.atkBase + 2 * caster.power
    local dmg = math.max(1, raw - target.def)
    target.hp = target.hp - dmg
    target.speed = math.max(1, target.speed - 2)
    return string.format("%s使用荆棘缠绕，对%s造成 %.1f 点伤害，速度降低2点。",
        caster.name, target.name, dmg)
end

--- 疯狂撕咬（高伤害连击）
function BS.enemySkills.frenzy_bite(caster, target, party)
    local raw = caster.atkBase + 3 * (caster.power + (caster.buffStr or 0))
    local hits = math.random(2, 3)
    local totalDmg = 0
    for _ = 1, hits do
        local dmg = math.max(1, raw - target.def)
        totalDmg = totalDmg + dmg
    end
    target.hp = target.hp - totalDmg
    return string.format("%s疯狂撕咬%s %d次，共造成 %.1f 点伤害！",
        caster.name, target.name, hits, totalDmg)
end

--- 蛛网陷阱（降速+降防）
function BS.enemySkills.web_trap(caster, target, party)
    target.speed = math.max(1, target.speed - 3)
    target.def = math.max(0, target.def - 2)
    local dmg = math.max(1, caster.matkBase * (1 - (target.mdef or 0)))
    target.hp = target.hp - dmg
    return string.format("%s喷射蛛网缠住%s，速度-3，防御-2，造成 %.1f 点伤害。",
        caster.name, target.name, dmg)
end

--- 暗影箭（高魔法伤害单体）
function BS.enemySkills.shadow_bolt(caster, target, party)
    local magRaw = (caster.matkBase or 0) + 3 * caster.insight
    local dmg = math.max(1, magRaw * (1 - (target.mdef or 0) * 0.5))
    target.hp = target.hp - dmg
    return string.format("%s发射暗影箭，对%s造成 %.1f 点暗属性伤害！",
        caster.name, target.name, dmg)
end

--- 自然治愈（回复自身30%HP）
function BS.enemySkills.nature_heal(caster, target, party)
    local heal = math.floor(caster.maxHp * 0.3)
    caster.hp = math.min(caster.maxHp, caster.hp + heal)
    return string.format("%s汲取自然之力，回复 %d 点生命值。", caster.name, heal)
end

-- ==================== 敌人AI行动 ====================

--- 执行敌人的AI回合
---@param enemy table
---@return string 行动描述
function BS.enemyAITurn(enemy)
    local S = GameState.state
    local msg = ""

    -- 冻结检查（冰霜新星）：跳过本回合行动
    if enemy.frozenTurns and enemy.frozenTurns > 0 then
        msg = enemy.name .. "被冻结，无法行动！"
        S.lastBattleMessage = msg
        BS.advanceTurn()
        return msg
    end

    -- 灼伤DOT
    if enemy.burn and enemy.burn.turns > 0 then
        local player = S.party[1]
        local burnDmg = enemy.burn.mult * (player and player.insight or 1)
        enemy.hp = enemy.hp - burnDmg
        msg = msg .. string.format("灼伤造成 %.1f 伤害。", burnDmg)
        enemy.burn.turns = enemy.burn.turns - 1
        if enemy.burn.turns <= 0 then enemy.burn.mult = 0 end
    end

    -- 获取攻击目标（血最低的队友）
    local target = Utils.getLowestHpTarget(S.party)
    if not target then
        S.lastBattleMessage = msg .. "没有可攻击的目标。"
        return S.lastBattleMessage
    end

    -- 紧急技能（HP<50%且未使用过）
    if enemy.hp < enemy.maxHp / 2 and not enemy.desperateUsed then
        enemy.desperateUsed = true
        local skillName = enemy.emergencySkill or "smash"
        local skillFunc = BS.enemySkills[skillName]
        if skillFunc then
            msg = msg .. skillFunc(enemy, target, S.party)
        end
        S.lastBattleMessage = msg
        BS.advanceTurn()
        return msg
    end

    -- 按技能循环行动
    local cycle = (enemy.actionCycle or 0)
    local skillName = enemy.skillCycle[((cycle) % #enemy.skillCycle) + 1]
    local skillFunc = BS.enemySkills[skillName]
    if skillFunc then
        msg = msg .. skillFunc(enemy, target, S.party)
    end
    enemy.actionCycle = (cycle + 1) % #enemy.skillCycle

    S.lastBattleMessage = msg
    BS.advanceTurn()
    return msg
end

end -- installer
