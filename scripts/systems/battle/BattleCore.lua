-- ============================================================================
-- BattleCore.lua - 战斗核心：回合管理、初始化/结束、数据保存、被动效果
-- ============================================================================

local GameState = require("systems.GameState")
local BattleData = require("data.BattleData")
local Utils = require("systems.battle.BattleUtils")

--- 安装战斗核心到 BattleSystem
---@param BS table BattleSystem 主表
return function(BS)

local deepCopy = Utils.deepCopy
local getUniCombatBonuses = Utils.getUniCombatBonuses

-- 敌人模板
BS.ENEMY_TEMPLATES = BattleData.ENEMY_TEMPLATES

--- 从列表中随机选取一个
---@param list table
---@return any
local function pickRandom(list)
    return list[math.random(1, #list)]
end

-- ==================== 存活检查 ====================

--- 获取所有存活的玩家方
---@return table[]
function BS.getLivePlayers()
    local S = GameState.state
    local live = {}
    for _, p in ipairs(S.party) do
        if p.hp > 0 then table.insert(live, p) end
    end
    return live
end

--- 获取所有存活的敌人
---@return table[]
function BS.getLiveEnemies()
    local S = GameState.state
    local live = {}
    for _, e in ipairs(S.enemies) do
        if e.hp > 0 then table.insert(live, e) end
    end
    return live
end

-- ==================== 逃跑系统 ====================

--- 尝试逃跑（基础40% + 速度差*5%，Boss战不可逃）
---@return boolean success
---@return string message
function BS.tryEscape()
    local S = GameState.state

    for _, e in ipairs(S.enemies) do
        if e.hp > 0 and e.isBoss then
            return false, "无法从Boss战中逃跑！"
        end
    end

    local pSpd, pCnt = 0, 0
    for _, p in ipairs(S.party) do
        if p.hp > 0 then pSpd = pSpd + (p.speed or 0); pCnt = pCnt + 1 end
    end
    local eSpd, eCnt = 0, 0
    for _, e in ipairs(S.enemies) do
        if e.hp > 0 then eSpd = eSpd + (e.speed or 0); eCnt = eCnt + 1 end
    end

    local avgP = pCnt > 0 and (pSpd / pCnt) or 0
    local avgE = eCnt > 0 and (eSpd / eCnt) or 0
    local tacticsBonus = (S.tacticsLevel or 0) * 0.05
    local chance = math.max(0.10, math.min(0.85, 0.40 + (avgP - avgE) * 0.05 + tacticsBonus))

    if math.random() < chance then
        S.inCombat = false
        S.battleResult = "escape"
        return true, string.format("逃跑成功！(成功率%.0f%%)", chance * 100)
    else
        return false, string.format("逃跑失败！(成功率%.0f%%)", chance * 100)
    end
end

-- ==================== 敌人创建 ====================

--- 从模板创建敌人实例
---@param templateName string
---@return table
function BS.createEnemy(templateName)
    local template = BS.ENEMY_TEMPLATES[templateName]
    if not template then
        return { name = "未知敌人", hp = 10, maxHp = 10, power = 1, insight = 1,
                 speed = 1, def = 1, mdef = 0, skill = 1, atkBase = 1, matkBase = 1,
                 expValue = 10, gold = 5, skillCycle = {"attack"}, emergencySkill = "attack" }
    end
    local enemy = deepCopy(template)
    enemy.buffDef = 0
    enemy.buffStr = 0
    enemy.buffTurns = 0
    enemy.burn = { turns = 0, mult = 0 }
    enemy.frost = { turns = 0, reduction = 0 }
    enemy.actionCycle = 0
    enemy.desperateUsed = false
    enemy.isEnemy = true
    return enemy
end

--- 根据森林层数生成敌人
function BS.generateEnemies()
    local S = GameState.state
    S.enemies = {}
    local layer = S.forestLayer

    if layer <= 2 then
        local pool = { "小石块", "毒蘑菇", "荆棘藤" }
        local count = math.random(1, 2)
        for _ = 1, count do
            table.insert(S.enemies, BS.createEnemy(pickRandom(pool)))
        end
    elseif layer <= 4 then
        local pool = { "暗影狼", "毒蜘蛛", "苔藓巨石" }
        if math.random() < 0.4 then
            table.insert(S.enemies, BS.createEnemy(pickRandom(pool)))
            table.insert(S.enemies, BS.createEnemy(pickRandom({"小石块", "毒蘑菇"})))
        else
            table.insert(S.enemies, BS.createEnemy(pickRandom(pool)))
        end
    elseif layer == 5 then
        table.insert(S.enemies, BS.createEnemy("石像鬼统领"))
    elseif layer <= 7 then
        local pool = { "树精", "腐化精灵" }
        if math.random() < 0.3 then
            table.insert(S.enemies, BS.createEnemy(pickRandom(pool)))
            table.insert(S.enemies, BS.createEnemy(pickRandom({"暗影狼", "毒蜘蛛"})))
        else
            table.insert(S.enemies, BS.createEnemy(pickRandom(pool)))
        end
    elseif layer <= 9 then
        local pool = { "黑骑士", "古树守卫" }
        if layer == 9 then
            table.insert(pool, "堕落天使")
        end
        if math.random() < 0.3 then
            table.insert(S.enemies, BS.createEnemy(pickRandom(pool)))
            table.insert(S.enemies, BS.createEnemy(pickRandom({"树精", "腐化精灵"})))
        else
            table.insert(S.enemies, BS.createEnemy(pickRandom(pool)))
        end
    else
        table.insert(S.enemies, BS.createEnemy("森林之主"))
    end
end

-- ==================== 战斗启动 ====================

--- 开始战斗
function BS.startBattle()
    local S = GameState.state
    BS.initParty()
    BS.generateEnemies()
    S.inCombat = true
    S.battleResult = ""
    S.lastBattleMessage = ""
    BS.generateTurnOrder()
end

--- 开始指定敌人的战斗（如事件战斗）
---@param enemyNames string[]
function BS.startBattleWith(enemyNames)
    local S = GameState.state
    BS.initParty()
    S.enemies = {}
    for _, name in ipairs(enemyNames) do
        table.insert(S.enemies, BS.createEnemy(name))
    end
    S.inCombat = true
    S.battleResult = ""
    S.lastBattleMessage = ""
    BS.generateTurnOrder()
end

--- 开始切磋战斗（莱德作为对手，不加入队伍）
function BS.startSparring()
    local S = GameState.state

    S.party = {}
    local player = deepCopy(S.playerCombat)
    player.isPlayer = true
    player.isHero = true
    player.isEnemy = false
    player.name = (S.PNN ~= "" and S.PNN or "勇者")
    local uniBonus = getUniCombatBonuses()
    if uniBonus.mdef > 0 then
        player.mdef = (player.mdef or 0) + uniBonus.mdef
    end
    table.insert(S.party, player)

    if S.kInParty then
        local k = deepCopy(S.kCombat)
        k.isPlayer = true
        k.isEnemy = false
        table.insert(S.party, k)
    end

    S.enemies = {}
    local leideCombat = deepCopy(S.initialNameCombat)
    leideCombat.isEnemy = true
    leideCombat.name = (S.initialName or "莱德") .. "（切磋）"
    leideCombat.buffDef = 0
    leideCombat.buffStr = 0
    leideCombat.buffTurns = 0
    leideCombat.burn = { turns = 0, mult = 0 }
    leideCombat.frost = { turns = 0, reduction = 0 }
    leideCombat.actionCycle = 0
    leideCombat.desperateUsed = false
    leideCombat.isSparring = true
    leideCombat.skillCycle = { "attack", "attack", "frenzy_bite", "harden", "attack", "smash" }
    leideCombat.emergencySkill = "harden"
    leideCombat.expValue = 0
    leideCombat.gold = 0
    table.insert(S.enemies, leideCombat)

    S.inCombat = true
    S.battleResult = ""
    S.lastBattleMessage = ""
    S.battleSource = "sparring"
    BS.generateTurnOrder()
end

-- ==================== 回合管理 ====================

--- 按速度排序生成行动顺序
function BS.generateTurnOrder()
    local S = GameState.state
    local order = {}

    for _, p in ipairs(S.party) do
        if p.hp > 0 then table.insert(order, p) end
    end
    for _, e in ipairs(S.enemies) do
        if e.hp > 0 then table.insert(order, e) end
    end

    table.sort(order, function(a, b)
        return (a.speed or 0) > (b.speed or 0)
    end)

    S.turnOrder = order
    S.turnIndex = 1
end

--- 推进到下一个存活角色的回合
function BS.advanceTurn()
    local S = GameState.state
    local idx = S.turnIndex

    repeat
        idx = idx + 1
    until idx > #S.turnOrder or S.turnOrder[idx].hp > 0

    if idx > #S.turnOrder then
        BS.applyPassives()
        BS.generateTurnOrder()
    else
        S.turnIndex = idx
    end

    BS.checkBattleEnd()
end

--- 获取当前行动者
---@return table|nil
function BS.getCurrentActor()
    local S = GameState.state
    if S.turnIndex >= 1 and S.turnIndex <= #S.turnOrder then
        return S.turnOrder[S.turnIndex]
    end
    return nil
end

--- 当前行动者是否是玩家方
---@return boolean
function BS.isPlayerTurn()
    local actor = BS.getCurrentActor()
    if actor then
        return actor.isPlayer == true
    end
    return false
end

--- 自动推进敌人回合（用于战斗开始和逃跑失败后）
function BS.processEnemyTurnsUntilPlayer()
    local S = GameState.state
    local safe = 0
    while S.inCombat and not BS.isPlayerTurn() and safe < 20 do
        local cur = BS.getCurrentActor()
        if cur and cur.hp > 0 and cur.isEnemy then
            BS.enemyAITurn(cur)
        else
            BS.advanceTurn()
        end
        safe = safe + 1
        if not S.inCombat then break end
    end
end

-- ==================== 被动效果（回合结束） ====================

function BS.applyPassives()
    local S = GameState.state

    for _, p in ipairs(S.party) do
        if p.hp > 0 then
            if p.name == "K" and p.form == "mage" then
                p.hp = math.min(p.maxHp, p.hp + 2)
            end
            if p.isHero and p.guardActive and p.guardActive > 0 then
                p.guardActive = p.guardActive - 1
                if p.guardActive <= 0 then
                    p.def = p.def - 3
                    p.mdef = (p.mdef or 0) - 0.15
                    p.guardActive = nil
                end
            end
            if p.bless and p.bless.turns > 0 then
                p.hp = math.min(p.maxHp, p.hp + math.floor(p.maxHp * 0.005))
                p.mp = math.min(p.maxMp, p.mp + math.floor(p.maxMp * 0.005))
                p.bless.turns = p.bless.turns - 1
                if p.bless.turns <= 0 then p.bless = nil end
            end
            if p.buff and p.buff.turns > 0 then
                p.buff.turns = p.buff.turns - 1
                if p.buff.turns <= 0 then
                    p.buff = { power = 0, insight = 0, dmgMult = 0, turns = 0 }
                end
            end
            if p.barrierActive and p.barrierActive > 0 then
                p.barrierActive = p.barrierActive - 1
                if p.barrierActive <= 0 then
                    p.def = p.def - (p.barrierDefBonus or 3)
                    p.mdef = (p.mdef or 0) - 0.1
                    p.barrierActive = nil
                    p.barrierDefBonus = nil
                end
            end
            if p.warCryActive and p.warCryActive > 0 then
                p.warCryActive = p.warCryActive - 1
                if p.warCryActive <= 0 then
                    p.atkBase = p.atkBase - (p.warCryBonus or 2)
                    p.warCryActive = nil
                    p.warCryBonus = nil
                end
            end
            if p.manaSurgeActive and p.manaSurgeActive > 0 then
                p.manaSurgeActive = p.manaSurgeActive - 1
                if p.manaSurgeActive <= 0 then
                    p.insight = p.insight - (p.manaSurgeBonus or 2)
                    p.manaSurgeActive = nil
                    p.manaSurgeBonus = nil
                end
            end
            if p.skillCooldown and p.skillCooldown.lightShield and p.skillCooldown.lightShield > 0 then
                p.skillCooldown.lightShield = p.skillCooldown.lightShield - 1
            end
            if p.rotTurns and p.rotTurns > 0 then
                p.rotTurns = p.rotTurns - 1
            end
        end
    end

    for _, e in ipairs(S.enemies) do
        if e.hp > 0 then
            if e.buffTurns and e.buffTurns > 0 then
                e.buffTurns = e.buffTurns - 1
                if e.buffTurns <= 0 then
                    e.buffDef = 0
                    e.buffStr = 0
                end
            end
            if e.burn and e.burn.turns > 0 then
                e.burn.turns = e.burn.turns - 1
                if e.burn.turns <= 0 then e.burn.mult = 0 end
            end
            if e.frost and e.frost.turns > 0 then
                e.frost.turns = e.frost.turns - 1
                if e.frost.turns <= 0 then e.frost.reduction = 0 end
            end
            if e.armorBreakTurns and e.armorBreakTurns > 0 then
                e.armorBreakTurns = e.armorBreakTurns - 1
                if e.armorBreakTurns <= 0 then
                    e.def = e.def + (e.armorBreakVal or 3)
                    e.armorBreakTurns = nil
                    e.armorBreakVal = nil
                end
            end
            if e.frozenTurns and e.frozenTurns > 0 then
                e.frozenTurns = e.frozenTurns - 1
            end
        end
    end
end

-- ==================== 战斗结束检查 ====================

function BS.checkBattleEnd()
    local S = GameState.state

    local allEnemiesDead = true
    for _, e in ipairs(S.enemies) do
        if e.hp > 0 then allEnemiesDead = false; break end
    end

    local allPlayersDead = true
    for _, p in ipairs(S.party) do
        if p.hp > 0 then allPlayersDead = false; break end
    end

    if allEnemiesDead then
        S.inCombat = false
        S.battleResult = "victory"
        if S.battleSource == "sparring" then
            BS.processSparringVictory()
        elseif S.battleSource == "town" then
            BS.processTownBattleVictory()
        else
            BS.processVictory()
        end
    elseif allPlayersDead then
        S.inCombat = false
        S.battleResult = "defeat"
    end
end

-- ==================== 胜利处理 ====================

--- 处理普通胜利：经验、金币、升级
function BS.processVictory()
    local S = GameState.state
    local totalExp = 0
    local totalGold = 0
    local hasBoss = false

    for _, e in ipairs(S.enemies) do
        totalExp = totalExp + (e.expValue or 0)
        totalGold = totalGold + (e.gold or 0)
        if e.isBoss then hasBoss = true end
    end

    S.gold = S.gold + totalGold

    local messages = {}
    table.insert(messages, "战斗胜利！获得 " .. totalExp .. " 经验，" .. totalGold .. " 金币。")

    for _, p in ipairs(S.party) do
        if p.hp > 0 then
            p.exp = p.exp + totalExp
            while p.exp >= p.expNext do
                p.exp = p.exp - p.expNext
                p.level = p.level + 1
                p.attrPoints = p.attrPoints + 1
                p.hp = math.min(p.maxHp, p.hp + math.floor(p.maxHp / 2))
                p.mp = math.min(p.maxMp, p.mp + math.floor(p.maxMp / 2))
                if p.level == 5 or p.level == 10 then
                    p.atkBase = p.atkBase + 3
                    p.matkBase = p.matkBase + 2
                end
                p.expNext = math.floor(p.expNext * 1.2)
                table.insert(messages, p.name .. " 升级到 Lv." .. p.level .. "！获得 1 属性点。")
                if p.isHero then
                    for _, m in ipairs(BS.checkSkillUnlocks(p.level)) do
                        table.insert(messages, m)
                    end
                end
            end
        end
    end

    BS.saveCombatData()

    if hasBoss then
        S.forestLayer = S.maxLayer + 1
    else
        S.forestLayer = S.forestLayer + 1
    end

    S.lastBattleMessage = table.concat(messages, "\n")
end

--- 处理切磋胜利
function BS.processSparringVictory()
    local S = GameState.state
    local sparExp = 15 + (S.playerCombat.level or 1) * 3
    local unlockMsgs = {}
    for _, p in ipairs(S.party) do
        if p.hp > 0 then
            p.exp = p.exp + sparExp
            while p.exp >= p.expNext do
                p.exp = p.exp - p.expNext
                p.level = p.level + 1
                p.attrPoints = p.attrPoints + 1
                p.hp = math.min(p.maxHp, p.hp + math.floor(p.maxHp / 2))
                p.mp = math.min(p.maxMp, p.mp + math.floor(p.maxMp / 2))
                if p.level == 5 or p.level == 10 then
                    p.atkBase = p.atkBase + 3
                    p.matkBase = p.matkBase + 2
                end
                p.expNext = math.floor(p.expNext * 1.2)
                if p.isHero then
                    for _, m in ipairs(BS.checkSkillUnlocks(p.level)) do
                        table.insert(unlockMsgs, m)
                    end
                end
            end
        end
    end
    BS.saveCombatData()
    local msg = string.format("切磋结束！你获得了 %d 点练习经验。", sparExp)
    if #unlockMsgs > 0 then
        msg = msg .. "\n" .. table.concat(unlockMsgs, "\n")
    end
    S.lastBattleMessage = msg
end

--- 处理城内治安战斗胜利
function BS.processTownBattleVictory()
    local S = GameState.state
    local totalExp = 0
    local totalGold = 0

    for _, e in ipairs(S.enemies) do
        totalExp = totalExp + (e.expValue or 0)
        totalGold = totalGold + (e.gold or 0)
    end

    S.money = (S.money or 0) + totalGold

    local messages = {}
    table.insert(messages, "治安事件解决！获得 " .. totalExp .. " 经验，" .. totalGold .. " 铜币。")

    for _, p in ipairs(S.party) do
        if p.hp > 0 then
            p.exp = p.exp + totalExp
            while p.exp >= p.expNext do
                p.exp = p.exp - p.expNext
                p.level = p.level + 1
                p.attrPoints = p.attrPoints + 1
                p.hp = math.min(p.maxHp, p.hp + math.floor(p.maxHp / 2))
                p.mp = math.min(p.maxMp, p.mp + math.floor(p.maxMp / 2))
                if p.level == 5 or p.level == 10 then
                    p.atkBase = p.atkBase + 3
                    p.matkBase = p.matkBase + 2
                end
                p.expNext = math.floor(p.expNext * 1.2)
                table.insert(messages, p.name .. " 升级到 Lv." .. p.level .. "！获得 1 属性点。")
                if p.isHero then
                    for _, m in ipairs(BS.checkSkillUnlocks(p.level)) do
                        table.insert(messages, m)
                    end
                end
            end
        end
    end

    BS.saveCombatData()
    S.lastBattleMessage = table.concat(messages, "\n")
end

-- ==================== 数据保存 ====================

--- 清除角色身上的临时战斗buff对基础属性的污染
---@param p table 战斗中的角色数据
local function stripTempBuffs(p)
    if p.guardActive and p.guardActive > 0 then
        if p.isLeide then
            p.def = p.def - 4
        elseif p.isHero then
            p.def = p.def - 3
            p.mdef = (p.mdef or 0) - 0.15
        end
        p.guardActive = nil
    end
    if p.enchant and p.enchant.turns and p.enchant.turns > 0 then
        if p.enchant.type == "ice" then
            p.insight = p.insight - 3
            p.mdef = (p.mdef or 0) - 0.4
        elseif p.enchant.type == "light" then
            p.power = p.power - 1
        end
    end
    if p.isHero then
        local uniBonus = getUniCombatBonuses()
        if uniBonus.mdef > 0 then
            p.mdef = (p.mdef or 0) - uniBonus.mdef
        end
    end
    if p.barrierActive and p.barrierActive > 0 then
        p.def = p.def - (p.barrierDefBonus or 3)
        p.mdef = (p.mdef or 0) - 0.1
        p.barrierActive = nil
        p.barrierDefBonus = nil
    end
    if p.warCryActive and p.warCryActive > 0 then
        p.atkBase = p.atkBase - (p.warCryBonus or 2)
        p.warCryActive = nil
        p.warCryBonus = nil
    end
    if p.manaSurgeActive and p.manaSurgeActive > 0 then
        p.insight = p.insight - (p.manaSurgeBonus or 2)
        p.manaSurgeActive = nil
        p.manaSurgeBonus = nil
    end
end

--- 需要从战斗角色同步回持久存储的字段列表
local SYNC_FIELDS = {
    "level", "exp", "expNext", "attrPoints",
    "hp", "mp", "maxHp", "maxMp",
    "power", "insight", "def", "atkBase", "matkBase", "speed", "mdef",
}

--- 将战斗后的数据同步回 GameState 持久存储
function BS.saveCombatData()
    local S = GameState.state
    for _, p in ipairs(S.party) do
        stripTempBuffs(p)

        -- 确定目标持久存储
        local target = nil
        if p.isHero then
            target = S.playerCombat
        elseif p.name == "K" then
            target = S.kCombat
        elseif p.isLeide then
            target = S.initialNameCombat
        end

        if target then
            for _, field in ipairs(SYNC_FIELDS) do
                target[field] = p[field]
            end
        end
    end
end

end -- installer
