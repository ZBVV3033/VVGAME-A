-- ============================================================================
-- PartySystem.lua - 队伍初始化、职业系统、属性分配、状态文本
-- ============================================================================

local GameState = require("systems.GameState")
local BattleData = require("data.BattleData")
local Utils = require("systems.battle.BattleUtils")

--- 安装队伍系统到 BattleSystem
---@param BS table BattleSystem 主表
return function(BS)

local deepCopy = Utils.deepCopy
local getUniCombatBonuses = Utils.getUniCombatBonuses

-- ==================== 技能分类定义（数据来自 BattleData） ====================

local HERO_BASE_SKILLS_PHYS = BattleData.HERO_BASE_SKILLS_PHYS
local HERO_BASE_SKILLS_BUFF = BattleData.HERO_BASE_SKILLS_BUFF
local HERO_UNLOCK_SKILLS = BattleData.HERO_UNLOCK_SKILLS
local HERO_CLASS_DEFS = BattleData.HERO_CLASS_DEFS
local K_CATEGORIES = BattleData.K_CATEGORIES
local LEIDE_CATEGORIES = BattleData.LEIDE_CATEGORIES

-- 导出到 BS
BS.HERO_CLASS_DEFS = HERO_CLASS_DEFS
BS.K_CATEGORIES = K_CATEGORIES
BS.LEIDE_CATEGORIES = LEIDE_CATEGORIES

--- 检查勇者升级时是否解锁新技能，返回提示消息列表
---@param newLevel number 升级后的等级
---@return string[] messages 解锁提示
function BS.checkSkillUnlocks(newLevel)
    local unlocked = {}
    for _, u in ipairs(HERO_UNLOCK_SKILLS) do
        if u.level == newLevel then
            table.insert(unlocked, string.format("🌟 解锁新技能【%s %s】！(%s)", u.skill.icon, u.skill.name, u.skill.desc))
        end
    end
    return unlocked
end

--- 根据勇者当前等级动态生成技能分类
function BS.getHeroCategories()
    local S = GameState.state
    local playerLevel = S.playerCombat and S.playerCombat.level or 10

    -- 复制基础技能列表
    local physSkills = {}
    for _, s in ipairs(HERO_BASE_SKILLS_PHYS) do table.insert(physSkills, s) end
    local buffSkills = {}
    for _, s in ipairs(HERO_BASE_SKILLS_BUFF) do table.insert(buffSkills, s) end

    -- 根据等级追加解锁技能
    for _, unlock in ipairs(HERO_UNLOCK_SKILLS) do
        if playerLevel >= unlock.level then
            if unlock.category == "物理" then
                table.insert(physSkills, unlock.skill)
            else
                table.insert(buffSkills, unlock.skill)
            end
        end
    end

    -- 根据职业追加专属技能
    local heroClass = S.playerCombat and S.playerCombat.heroClass or "none"
    if heroClass ~= "none" and HERO_CLASS_DEFS[heroClass] then
        for _, sk in ipairs(HERO_CLASS_DEFS[heroClass].skills) do
            if sk.category == "物理" then
                table.insert(physSkills, sk)
            else
                table.insert(buffSkills, sk)
            end
        end
    end

    return {
        { id = "物理", name = "⚔️ 物理攻击", skills = physSkills },
        { id = "增益", name = "💫 增益技能",  skills = buffSkills },
    }
end

--- 获取角色对应的技能分类表
function BS.getCategoriesForActor(actor)
    if actor.isHero then return BS.getHeroCategories() end
    if actor.isLeide then return LEIDE_CATEGORIES end
    return K_CATEGORIES
end

-- ==================== 职业系统（转职） ====================

--- 切换勇者职业
---@param newClass string "warrior"|"mage"|"none"
---@return string message 切换结果描述
function BS.switchHeroClass(newClass)
    local S = GameState.state
    local pc = S.playerCombat
    if not pc then return "错误：没有战斗数据。" end

    local oldClass = pc.heroClass or "none"
    if oldClass == newClass then
        local name = HERO_CLASS_DEFS[newClass] and HERO_CLASS_DEFS[newClass].name or newClass
        return string.format("你已经是%s了。", name)
    end

    -- 移除旧职业加成
    if oldClass ~= "none" and HERO_CLASS_DEFS[oldClass] then
        local oldBonuses = HERO_CLASS_DEFS[oldClass].bonuses
        for stat, val in pairs(oldBonuses) do
            pc[stat] = pc[stat] - val
        end
        if pc.hp > pc.maxHp then pc.hp = pc.maxHp end
        if pc.mp > pc.maxMp then pc.mp = pc.maxMp end
    end

    -- 应用新职业加成
    if newClass ~= "none" and HERO_CLASS_DEFS[newClass] then
        local newBonuses = HERO_CLASS_DEFS[newClass].bonuses
        for stat, val in pairs(newBonuses) do
            pc[stat] = pc[stat] + val
        end
    end

    pc.heroClass = newClass

    if newClass == "none" then
        return "你放弃了职业专精，回归了自由之身。"
    end
    local def = HERO_CLASS_DEFS[newClass]
    local bonusTexts = {}
    for stat, val in pairs(def.bonuses) do
        local statNames = { atkBase = "攻击", def = "防御", maxHp = "最大HP", matkBase = "魔攻", insight = "灵感", maxMp = "最大MP" }
        table.insert(bonusTexts, (statNames[stat] or stat) .. "+" .. val)
    end
    return string.format("🎖️ 转职成功！你成为了【%s %s】！\n属性加成：%s\n解锁职业技能！",
        def.icon, def.name, table.concat(bonusTexts, "、"))
end

-- ==================== 队伍初始化 ====================

--- 初始化队伍（从 GameState 的持久数据复制到战斗用数组）
function BS.initParty()
    local S = GameState.state
    S.party = {}

    -- 主角
    local player = deepCopy(S.playerCombat)
    player.isPlayer = true
    player.isHero = true
    player.isEnemy = false
    player.name = (S.PNN ~= "" and S.PNN or "勇者")
    -- 大学专业战斗加成：神学魔防加成
    local uniBonus = getUniCombatBonuses()
    if uniBonus.mdef > 0 then
        player.mdef = (player.mdef or 0) + uniBonus.mdef
    end
    table.insert(S.party, player)

    -- K（如果在队伍中）
    if S.kInParty then
        local k = deepCopy(S.kCombat)
        k.isPlayer = true
        k.isEnemy = false
        table.insert(S.party, k)
    end

    -- 莱德（如果入队）
    if S.initialNameInParty and S.initialNameCombat then
        local leide = deepCopy(S.initialNameCombat)
        leide.isPlayer = true
        leide.isEnemy = false
        leide.isLeide = true
        leide.name = S.initialName or "莱德"
        table.insert(S.party, leide)
    end
end

-- ==================== 战斗属性分配 ====================

--- 分配战斗属性点
---@param who string "player" / "k"
---@param stat string "power"/"insight"/"charm"/"stamina"/"skill"/"speed"
---@return boolean, string
function BS.allocateCombatAttr(who, stat)
    local S = GameState.state
    local target = nil

    if who == "player" then
        target = S.playerCombat
    elseif who == "k" then
        target = S.kCombat
    end

    if not target then return false, "无效目标。" end
    if target.attrPoints <= 0 then return false, "没有可用属性点。" end

    local validStats = { power = true, insight = true, charm = true,
                         stamina = true, skill = true, speed = true }
    if not validStats[stat] then return false, "无效属性。" end

    target.attrPoints = target.attrPoints - 1
    target[stat] = target[stat] + 1

    local statNames = {
        power = "力量", insight = "灵感", charm = "魅力",
        stamina = "耐力", skill = "技巧", speed = "速度",
    }

    return true, string.format("%s的%s+1！剩余属性点：%d",
        target.name, statNames[stat], target.attrPoints)
end

-- ==================== 获取状态描述（供UI使用）====================

--- 获取角色状态描述
---@param actor table
---@return string
function BS.getActorStatusText(actor)
    local lines = {}
    table.insert(lines, actor.name)
    if actor.hp <= 0 then
        table.insert(lines, "❤️ HP: 0/" .. actor.maxHp .. " (死亡)")
    else
        table.insert(lines, string.format("❤️ HP: %.0f/%d", actor.hp, actor.maxHp))
    end
    table.insert(lines, string.format("💙 MP: %.0f/%d", actor.mp, actor.maxMp))

    -- Buff信息
    if actor.buff and actor.buff.turns and actor.buff.turns > 0 then
        table.insert(lines, string.format("⚡ Buff: 力+%d 灵+%d 伤害+%.0f%% 剩%d回合",
            actor.buff.power, actor.buff.insight,
            actor.buff.dmgMult * 100, actor.buff.turns))
    end

    -- K附魔信息
    if actor.enchant and actor.enchant.turns and actor.enchant.turns > 0 then
        local enchantNames = { light = "光", fire = "火", ice = "冰" }
        table.insert(lines, string.format("✨ 附魔: %s 剩%d回合",
            enchantNames[actor.enchant.type] or actor.enchant.type,
            actor.enchant.turns))
    end

    -- 祝福
    if actor.bless and actor.bless.turns > 0 then
        table.insert(lines, string.format("🙏 祝福 剩%d回合", actor.bless.turns))
    end

    -- 腐烂
    if actor.rotTurns and actor.rotTurns > 0 then
        table.insert(lines, string.format("☠️ 腐烂 剩%d回合", actor.rotTurns))
    end

    return table.concat(lines, "\n")
end

--- 获取敌人状态描述
---@param enemy table
---@return string
function BS.getEnemyStatusText(enemy)
    local lines = {}
    table.insert(lines, enemy.name)
    if enemy.hp <= 0 then
        table.insert(lines, "💔 HP: 0/" .. enemy.maxHp .. " (死亡)")
    else
        table.insert(lines, string.format("💔 HP: %.0f/%d", enemy.hp, enemy.maxHp))
    end

    if (enemy.buffDef or 0) > 0 then
        table.insert(lines, string.format("🛡️ 硬化: 防+%d 剩%d回合",
            enemy.buffDef, enemy.buffTurns or 0))
    end
    if enemy.burn and enemy.burn.turns > 0 then
        table.insert(lines, string.format("🔥 灼伤 剩%d回合", enemy.burn.turns))
    end
    if enemy.frost and enemy.frost.turns > 0 then
        table.insert(lines, string.format("❄️ 冻伤 -%.0f%% 剩%d回合",
            enemy.frost.reduction * 100, enemy.frost.turns))
    end

    return table.concat(lines, "\n")
end

end -- installer
