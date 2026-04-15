-- ============================================================================
-- PlayerSkills.lua - 玩家角色技能（勇者 / K / 莱德）
-- ============================================================================

local GameState = require("systems.GameState")
local Utils = require("systems.battle.BattleUtils")

--- 安装玩家技能到 BattleSystem
---@param BS table BattleSystem 主表
return function(BS)

local getFirstLiveEnemy = Utils.getFirstLiveEnemy
local getAllLiveEnemies = Utils.getAllLiveEnemies
local getLowestHpTarget = Utils.getLowestHpTarget
local getUniCombatBonuses = Utils.getUniCombatBonuses

--- 消耗附魔回合（内部工具）
function BS._consumeEnchant(actor)
    if actor.enchant and actor.enchant.turns > 0 then
        actor.enchant.turns = actor.enchant.turns - 1
        if actor.enchant.turns <= 0 then
            -- 清除附魔带来的属性加成
            if actor.enchant.type == "ice" then
                actor.insight = actor.insight - 3
                actor.mdef = actor.mdef - 0.4
            elseif actor.enchant.type == "light" then
                actor.power = actor.power - 1
            end
            actor.enchant = { type = "", turns = 0, extra = 0 }
        end
    end
end

--- 执行玩家角色的技能
---@param actor table 行动者（勇者、K 或莱德）
---@param skill string 技能名称
---@return string 行动描述
function BS.actorAct(actor, skill)
    local S = GameState.state
    local msg = ""
    local power = actor.power + (actor.buff and actor.buff.power or 0)
    local insight = actor.insight + (actor.buff and actor.buff.insight or 0)
    local dmgMult = 1 + (actor.buff and actor.buff.dmgMult or 0)

    -- 大学专业战斗加成（仅对主角生效）
    local uniBonus = actor.isHero and getUniCombatBonuses() or { phys = 0, magic = 0, mdef = 0 }

    -- 商人每日buff（全队生效）
    local dailyPhys  = S.dailyBuffs and S.dailyBuffs.phys or 0
    local dailyMagic = S.dailyBuffs and S.dailyBuffs.magic or 0
    local dailyDef   = S.dailyBuffs and S.dailyBuffs.def or 0

    -- ==================== 通用技能 ====================
    if skill == "defend" then
        local heal = math.ceil(actor.maxHp * 0.05)
        actor.hp = math.min(actor.maxHp, actor.hp + heal)
        msg = string.format("%s采取防御姿态，恢复 %d HP。", actor.name, heal)
        S.lastBattleMessage = msg
        BS.advanceTurn()
        return msg
    end

    -- ==================== 勇者技能 ====================
    if actor.isHero then
        if skill == "light" then
            local target = getFirstLiveEnemy()
            if not target then msg = "没有目标。"
            else
                local enemyDef = target.def + (target.buffDef or 0)
                local damage = math.max(1, (actor.atkBase + power) - enemyDef)
                damage = math.floor(damage * dmgMult * (1 + uniBonus.phys) * (1 + dailyPhys))
                target.hp = target.hp - damage
                msg = string.format("%s轻攻击造成 %d 伤害。", actor.name, damage)
            end

        elseif skill == "heavy" then
            local target = getFirstLiveEnemy()
            if not target then msg = "没有目标。"
            else
                local cost = math.max(1, math.floor(actor.hp / 10))
                actor.hp = actor.hp - cost
                local enemyDef = target.def + (target.buffDef or 0)
                local effectiveDef = enemyDef * 0.8
                local damage = math.max(1, (2 * actor.atkBase + 2 * power) - effectiveDef)
                damage = math.floor(damage * dmgMult * (1 + uniBonus.phys) * (1 + dailyPhys))
                target.hp = target.hp - damage
                msg = string.format("重攻击消耗 %d HP，造成 %d 伤害。", cost, damage)
            end

        elseif skill == "holy_strike" then
            if actor.mp < 5 then
                msg = "MP不足！"
            else
                local target = getFirstLiveEnemy()
                if not target then msg = "没有目标。"
                else
                    actor.mp = actor.mp - 5
                    local gsxBonus = (S.GSX or 0) * 1.5
                    local enemyDef = target.def + (target.buffDef or 0)
                    local effectiveDef = enemyDef * 0.6
                    local damage = math.max(1, (actor.atkBase + power + gsxBonus) - effectiveDef)
                    damage = math.floor(damage * dmgMult * (1 + uniBonus.phys) * (1 + dailyPhys))
                    target.hp = target.hp - damage
                    msg = string.format("圣光斩造成 %d 伤害（无视40%%防御）。", damage)
                end
            end

        elseif skill == "guard" then
            if actor.mp < 3 then
                msg = "MP不足！"
            else
                actor.mp = actor.mp - 3
                actor.guardActive = 2
                actor.def = actor.def + 3 + dailyDef
                actor.mdef = (actor.mdef or 0) + 0.15
                msg = dailyDef > 0
                    and string.format("守护姿态：防御+%d（含商人buff+%d），魔抗+15%%，持续2回合。", 3 + dailyDef, dailyDef)
                    or "守护姿态：防御+3，魔抗+15%，持续2回合。"
            end

        elseif skill == "powerstance" then
            if actor.hp <= 5 or actor.mp < 5 then
                msg = "HP或MP不足！"
            else
                actor.hp = actor.hp - 5
                actor.mp = actor.mp - 5
                actor.buff.power = actor.buff.power + 1
                actor.buff.insight = actor.buff.insight + 1
                actor.buff.dmgMult = actor.buff.dmgMult + 0.2
                actor.buff.turns = 3
                msg = "全力架势：力量+1，灵感+1，伤害+20%，持续3回合。"
            end

        elseif skill == "heal" then
            if S.healUsedToday >= S.maxHealPerDay then
                msg = "今日恢复次数已用完！"
            else
                S.healUsedToday = S.healUsedToday + 1
                local target = getLowestHpTarget(S.party)
                if target then
                    local heal = math.ceil(target.maxHp * 0.3)
                    target.hp = math.min(target.maxHp, target.hp + heal)
                    msg = string.format("恢复魔法治疗 %s，恢复 %d HP。剩余次数 %d",
                        target.name, heal, S.maxHealPerDay - S.healUsedToday)
                else
                    msg = "没有需要治疗的目标。"
                end
            end

        elseif skill == "combo_strike" then
            if actor.mp < 8 then
                msg = "MP不足！"
            else
                local target = getFirstLiveEnemy()
                if not target then msg = "没有目标。"
                else
                    actor.mp = actor.mp - 8
                    local enemyDef = target.def + (target.buffDef or 0)
                    local baseDmg = math.max(1, (actor.atkBase + power) - enemyDef)
                    baseDmg = math.floor(baseDmg * dmgMult * (1 + uniBonus.phys) * (1 + dailyPhys))
                    local hit1 = math.floor(baseDmg * 0.6)
                    local hit2 = math.floor(baseDmg * 0.6)
                    target.hp = target.hp - hit1 - hit2
                    msg = string.format("连击斩：第一击 %d + 第二击 %d = 共 %d 伤害！", hit1, hit2, hit1 + hit2)
                end
            end

        elseif skill == "light_barrier" then
            if actor.mp < 10 then
                msg = "MP不足！"
            else
                actor.mp = actor.mp - 10
                local barrierDef = 3
                for _, p in ipairs(S.party) do
                    if p.hp > 0 then
                        if p.barrierActive and p.barrierActive > 0 then
                            p.def = p.def - (p.barrierDefBonus or 3)
                            p.mdef = (p.mdef or 0) - 0.1
                        end
                        p.def = p.def + barrierDef
                        p.mdef = (p.mdef or 0) + 0.1
                        p.barrierActive = 3
                        p.barrierDefBonus = barrierDef
                    end
                end
                local selfHeal = math.floor(actor.maxHp * 0.2)
                actor.hp = math.min(actor.maxHp, actor.hp + selfHeal)
                msg = string.format("光盾术：全队防御+%d、魔抗+10%%（3回合），自身回复 %d HP！", barrierDef, selfHeal)
            end

        elseif skill == "divine_judgment" then
            if actor.mp < 15 then
                msg = "MP不足！"
            else
                actor.mp = actor.mp - 15
                local gsxBonus = (S.GSX or 0) * 2
                local totalDmg = 0
                local hitCount = 0
                for _, e in ipairs(S.enemies) do
                    if e.hp > 0 then
                        local enemyDef = e.def + (e.buffDef or 0)
                        local effectiveDef = enemyDef * 0.5
                        local damage = math.max(1, (actor.atkBase + power + insight + gsxBonus) - effectiveDef)
                        damage = math.floor(damage * dmgMult * (1 + uniBonus.phys) * (1 + dailyPhys))
                        e.hp = e.hp - damage
                        totalDmg = totalDmg + damage
                        hitCount = hitCount + 1
                    end
                end
                msg = string.format("审判之光照耀战场！命中 %d 个敌人，共造成 %d 伤害！", hitCount, totalDmg)
            end

        -- ==================== 战士职业技能 ====================
        elseif skill == "armor_break" then
            if actor.mp < 6 then
                msg = "MP不足！"
            else
                local target = getFirstLiveEnemy()
                if not target then msg = "没有目标。"
                else
                    actor.mp = actor.mp - 6
                    local enemyDef = target.def + (target.buffDef or 0)
                    local damage = math.max(1, (actor.atkBase + power) - enemyDef)
                    damage = math.floor(damage * dmgMult * (1 + uniBonus.phys) * (1 + dailyPhys))
                    target.hp = target.hp - damage
                    local armorReduce = 3
                    if target.armorBreakTurns and target.armorBreakTurns > 0 then
                        target.def = target.def + (target.armorBreakVal or 0)
                    end
                    target.def = target.def - armorReduce
                    target.armorBreakTurns = 3
                    target.armorBreakVal = armorReduce
                    msg = string.format("破甲斩！造成 %d 伤害，敌人防御降低 %d（3回合）！", damage, armorReduce)
                end
            end

        elseif skill == "war_cry" then
            if actor.mp < 8 then
                msg = "MP不足！"
            else
                actor.mp = actor.mp - 8
                for _, p in ipairs(S.party) do
                    if p.hp > 0 then
                        if p.warCryActive and p.warCryActive > 0 then
                            p.atkBase = p.atkBase - (p.warCryBonus or 2)
                        end
                        p.atkBase = p.atkBase + 2
                        p.warCryActive = 2
                        p.warCryBonus = 2
                    end
                end
                msg = "战吼响彻战场！全队攻击+2（2回合）！"
            end

        -- ==================== 法师职业技能 ====================
        elseif skill == "frost_nova" then
            if actor.mp < 12 then
                msg = "MP不足！"
            else
                actor.mp = actor.mp - 12
                local totalDmg = 0
                local hitCount = 0
                for _, e in ipairs(S.enemies) do
                    if e.hp > 0 then
                        local damage = math.max(1, (actor.matkBase + insight * 2) - (e.def * 0.3))
                        damage = math.floor(damage * dmgMult * (1 + uniBonus.magic) * (1 + dailyMagic))
                        e.hp = e.hp - damage
                        e.frozenTurns = 1
                        totalDmg = totalDmg + damage
                        hitCount = hitCount + 1
                    end
                end
                msg = string.format("冰霜新星爆发！命中 %d 个敌人，共 %d 伤害，冻结1回合！", hitCount, totalDmg)
            end

        elseif skill == "mana_surge" then
            if actor.mp < 5 then
                msg = "MP不足！"
            else
                actor.mp = actor.mp - 5
                local mpRestore = math.floor(actor.maxMp * 0.3)
                actor.mp = math.min(actor.maxMp, actor.mp + mpRestore)
                if actor.manaSurgeActive and actor.manaSurgeActive > 0 then
                    actor.insight = actor.insight - (actor.manaSurgeBonus or 2)
                end
                actor.insight = actor.insight + 2
                actor.manaSurgeActive = 2
                actor.manaSurgeBonus = 2
                msg = string.format("魔力涌动！恢复 %d MP，灵感+2（2回合）！", mpRestore)
            end
        end

    -- ==================== K技能 ====================
    elseif actor.name == "K" then
        if skill == "form_mage" then
            actor.form = "mage"
            msg = "K切换到魔法元祖形态。"

        elseif skill == "form_sword" then
            actor.form = "sword"
            msg = "K切换到剑术大师形态。"

        elseif skill == "enchant_light" then
            if actor.mp < 10 then msg = "MP不足！"
            else
                actor.mp = actor.mp - 10
                for _, p in ipairs(S.party) do
                    if p.hp > 0 then
                        p.hp = math.min(p.maxHp, p.hp + math.ceil(p.maxHp * 0.02))
                    end
                end
                actor.power = actor.power + 1
                actor.enchant = { type = "light", turns = 4, extra = 1 }
                msg = "光辉于我：全体恢复2% HP，力量+1，普攻附加灵感伤害，持续4回合。"
            end

        elseif skill == "enchant_fire" then
            if actor.mp < 10 then msg = "MP不足！"
            else
                actor.mp = actor.mp - 10
                for _, e in ipairs(S.enemies) do
                    if e.hp > 0 then
                        if e.burn.turns > 0 then
                            e.burn.mult = e.burn.mult + 1
                        else
                            e.burn.mult = 1
                        end
                        e.burn.turns = 2
                    end
                end
                actor.enchant = { type = "fire", turns = 4, extra = 1.5 }
                msg = "炙热于心：全体敌人灼烧2回合，普攻附加1.5倍灵感伤害。"
            end

        elseif skill == "enchant_ice" then
            if actor.mp < 10 then msg = "MP不足！"
            else
                actor.mp = actor.mp - 10
                actor.insight = actor.insight + 3
                actor.mdef = actor.mdef + 0.4
                actor.enchant = { type = "ice", turns = 4, extra = 1 }
                msg = "严寒外衣：灵感+3，魔抗+40%，普攻附加冻伤，持续4回合。"
            end

        elseif skill == "light_shield" then
            if actor.skillCooldown and actor.skillCooldown.lightShield > 0 then
                msg = string.format("光盾冷却中，剩余 %d 回合。", actor.skillCooldown.lightShield)
            else
                actor.mp = math.min(actor.maxMp, actor.mp + 2)
                actor.buff = actor.buff or {}
                actor.buff.defBonus = 2
                actor.buff.mdefBonus = 0.1
                actor.buff.dmgReduction = 0.3
                actor.buff.turns = 2
                actor.shield = { active = true, type = "percent", value = 0.5 }
                actor.skillCooldown = actor.skillCooldown or {}
                actor.skillCooldown.lightShield = 3
                msg = "光盾：回复2MP，防御+2、魔抗+10%、减伤30%持续2回合，获得50%减伤护盾。"
            end

        elseif skill == "sword_single" then
            local target = getFirstLiveEnemy()
            if not target then msg = "没有目标。"
            else
                local physDmg = actor.atkBase + 2 * power
                local finalDmg = math.max(1, physDmg - (target.def + (target.buffDef or 0)))
                if actor.enchant and actor.enchant.turns > 0 then
                    local extra = actor.enchant.extra * insight
                    finalDmg = finalDmg + extra
                    if actor.enchant.type == "ice" then
                        if target.frost.turns > 0 then
                            target.frost.reduction = target.frost.reduction + 0.1
                        else
                            target.frost.reduction = 0.1
                        end
                        target.frost.turns = 2
                    end
                end
                if actor.form == "sword" then
                    finalDmg = finalDmg * 1.1
                end
                finalDmg = math.floor(finalDmg * (1 + dailyPhys))
                target.hp = target.hp - finalDmg
                msg = string.format("K挥剑造成 %d 伤害。", finalDmg)
                BS._consumeEnchant(actor)
            end

        elseif skill == "sword_sweep" then
            local targets = getAllLiveEnemies()
            if #targets == 0 then msg = "没有目标。"
            else
                local physBase = actor.atkBase + 2 * power
                local physDmg = physBase * 0.6
                for _, t in ipairs(targets) do
                    local dmg = math.max(1, physDmg - (t.def + (t.buffDef or 0)))
                    if actor.enchant and actor.enchant.turns > 0 then
                        dmg = dmg + actor.enchant.extra * insight
                        if actor.enchant.type == "ice" then
                            if t.frost.turns > 0 then
                                t.frost.reduction = t.frost.reduction + 0.1
                            else
                                t.frost.reduction = 0.1
                            end
                            t.frost.turns = 2
                        end
                    end
                    if actor.form == "sword" then dmg = dmg * 1.1 end
                    dmg = math.floor(dmg * (1 + dailyPhys))
                    t.hp = t.hp - dmg
                end
                msg = "K使用横扫，对所有敌人造成伤害。"
                BS._consumeEnchant(actor)
            end

        elseif skill == "fireball" then
            if actor.mp < 15 then msg = "MP不足！"
            else
                local target = getFirstLiveEnemy()
                if not target then msg = "没有目标。"
                else
                    actor.mp = actor.mp - 15
                    local base = actor.matkBase + insight
                    local dmg = base + 2 * insight
                    if actor.form == "mage" then dmg = dmg * 1.2 end
                    dmg = dmg * (1 - (target.mdef or 0)) * (1 + dailyMagic)
                    dmg = math.max(1, math.floor(dmg))
                    target.hp = target.hp - dmg
                    msg = string.format("K小火球造成 %d 伤害。", dmg)
                end
            end

        elseif skill == "holy_light" then
            if actor.mp < 15 then msg = "MP不足！"
            else
                actor.mp = actor.mp - 15
                for _, p in ipairs(S.party) do
                    if p.hp > 0 then
                        p.bless = { turns = 3 }
                    end
                end
                msg = "神圣光辉：全体队友获得祝福，每回合恢复0.5% HP/MP，持续3回合。"
            end
        end

    -- ==================== 莱德技能 ====================
    elseif actor.isLeide then
        if skill == "slash" then
            local target = getFirstLiveEnemy()
            if not target then msg = "没有目标。"
            else
                local enemyDef = target.def + (target.buffDef or 0)
                local damage = math.max(1, (actor.atkBase + power) - enemyDef)
                damage = math.floor(damage * dmgMult * (1 + dailyPhys))
                target.hp = target.hp - damage
                msg = string.format("%s斩击造成 %d 伤害。", actor.name, damage)
            end

        elseif skill == "quick_draw" then
            if actor.mp < 8 then msg = "MP不足！"
            else
                local target = getFirstLiveEnemy()
                if not target then msg = "没有目标。"
                else
                    actor.mp = actor.mp - 8
                    local enemyDef = target.def + (target.buffDef or 0)
                    local damage = math.max(1, (actor.atkBase + power) * 1.2 - enemyDef)
                    damage = math.floor(damage * dmgMult * (1 + dailyPhys))
                    target.hp = target.hp - damage
                    msg = string.format("%s拔刀术造成 %d 伤害！", actor.name, damage)
                end
            end

        elseif skill == "cross_cut" then
            local cost = math.max(1, math.floor(actor.hp * 0.1))
            actor.hp = actor.hp - cost
            local target = getFirstLiveEnemy()
            if not target then msg = "没有目标。"
            else
                local enemyDef = target.def + (target.buffDef or 0)
                local hitDmg = math.max(1, math.floor((actor.atkBase + power) * 0.7) - enemyDef)
                hitDmg = math.floor(hitDmg * dmgMult * (1 + dailyPhys))
                local total = hitDmg * 2
                target.hp = target.hp - total
                msg = string.format("%s十字斩两连击，各造成 %d 伤害（共 %d）。消耗 %d HP。",
                    actor.name, hitDmg, total, cost)
            end

        elseif skill == "focus" then
            if actor.mp < 5 then msg = "MP不足！"
            else
                actor.mp = actor.mp - 5
                actor.buff.dmgMult = actor.buff.dmgMult + 0.25
                actor.buff.turns = math.max(actor.buff.turns, 2)
                msg = string.format("%s集中精神：伤害+25%%，持续2回合。", actor.name)
            end

        elseif skill == "endure" then
            actor.def = actor.def + 4
            actor.guardActive = 1
            msg = string.format("%s硬撑：防御+4，减伤30%%，持续1回合。", actor.name)

        elseif skill == "rally" then
            if actor.mp < 8 then msg = "MP不足！"
            else
                actor.mp = actor.mp - 8
                for _, p in ipairs(S.party) do
                    if p.hp > 0 then
                        p.buff = p.buff or { power = 0, insight = 0, dmgMult = 0, turns = 0 }
                        p.buff.dmgMult = p.buff.dmgMult + 0.10
                        p.buff.turns = math.max(p.buff.turns, 2)
                        p.speed = (p.speed or 0) + 1
                    end
                end
                msg = string.format("%s鼓舞全队：全体伤害+10%%，速度+1，持续2回合。", actor.name)
            end
        end
    end

    S.lastBattleMessage = msg
    BS.advanceTurn()
    return msg
end

end -- installer
