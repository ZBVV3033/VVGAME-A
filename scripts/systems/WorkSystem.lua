-- ============================================================================
-- WorkSystem.lua - 职业、打工、经验、读书系统
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local ET = require("utils.EventTemplates")

-- 数据模块
local WorkJobData = require("data.WorkJobData")
local WorkEventData = require("data.WorkEventData")
local WorkBookData = require("data.WorkBookData")

local WorkSystem = {}

-- ==================== 数据重导出（向后兼容） ====================
WorkSystem.JOB_DATA = WorkJobData.JOB_DATA
WorkSystem.LEIDE_JOB_DATA = WorkJobData.LEIDE_JOB_DATA
WorkSystem.JOB_TITLES = WorkJobData.JOB_TITLES
WorkSystem.JOB_LEVEL_BONUSES = WorkJobData.JOB_LEVEL_BONUSES
WorkSystem.UNIFORMS = WorkJobData.UNIFORMS
WorkSystem.knowledgeDefs = WorkJobData.knowledgeDefs
WorkSystem.knowledgeOrder = WorkJobData.knowledgeOrder
WorkSystem.WORK_EVENTS = WorkEventData.WORK_EVENTS
WorkSystem.bookTexts = WorkBookData.bookTexts
WorkSystem.bookOrder = WorkBookData.bookOrder
WorkSystem.bookInfo = WorkBookData.bookInfo

function WorkSystem.getJobTitleForLevel(job, level)
    local titles = WorkSystem.JOB_TITLES[job]
    if not titles then return "未知" end
    local idx = math.min(math.max(level or 1, 1), #titles)
    return titles[idx]
end

--- 获取玩家当前职业称号
---@param job string
---@return string title, number level
function WorkSystem.getJobTitle(job)
    local S = GameState.state
    local data = WorkSystem.JOB_DATA[job]
    if not data then return "未知", 0 end
    local level = S[data.levelVar] or 1
    return WorkSystem.getJobTitleForLevel(job, level), level
end

-- ==================== 工作制服系统 ====================


-- ==================== 工作制服系统 ====================

local function getUniformLookup()
    if _uniformLookup then return _uniformLookup end
    _uniformLookup = {}
    for _, uniforms in pairs(WorkSystem.UNIFORMS) do
        for _, u in ipairs(uniforms) do
            _uniformLookup[u.id] = u
        end
    end
    return _uniformLookup
end

--- 判断 outfitId 是否为制服
---@param outfitId string
---@return boolean
function WorkSystem.isUniform(outfitId)
    if not outfitId then return false end
    return string.find(outfitId, "^uniform_") ~= nil
end

--- 获取制服信息
---@param outfitId string
---@return table|nil { id, name, shortDesc, desc, level }
function WorkSystem.getUniformInfo(outfitId)
    return getUniformLookup()[outfitId]
end

--- 获取玩家所有已拥有的制服列表
---@return table[] 制服信息数组
function WorkSystem.getOwnedUniformList()
    local S = GameState.state
    local list = {}
    local lookup = getUniformLookup()
    for uid, owned in pairs(S.ownedUniforms or {}) do
        if owned and lookup[uid] then
            table.insert(list, lookup[uid])
        end
    end
    return list
end

--- 返回该职业当前应穿的制服ID（最高等级的已拥有制服）
---@param job string
---@return string uniformId
function WorkSystem.getUniformForJob(job)
    local S = GameState.state
    local uniforms = WorkSystem.UNIFORMS[job]
    if not uniforms then return "uniform_" .. job end
    local best = uniforms[1].id
    for _, u in ipairs(uniforms) do
        if S.ownedUniforms[u.id] then
            best = u.id
        end
    end
    return best
end

--- 检查并发放制服（首次打工+等级升级时）
--- 返回发放提示消息（无新制服则返回nil）
---@param job string
---@return string|nil msg
function WorkSystem.grantUniform(job)
    local S = GameState.state
    if not S.ownedUniforms then S.ownedUniforms = {} end
    local uniforms = WorkSystem.UNIFORMS[job]
    if not uniforms then return nil end
    local data = WorkSystem.JOB_DATA[job]
    if not data then return nil end
    local level = S[data.levelVar] or 1

    local msgs = {}
    for _, u in ipairs(uniforms) do
        if level >= u.level and not S.ownedUniforms[u.id] then
            S.ownedUniforms[u.id] = true
            table.insert(msgs, "你获得了一套新制服：「" .. u.name .. "」！")
        end
    end
    if #msgs > 0 then return table.concat(msgs, "\n") end
    return nil
end

-- ==================== 知识系统 ====================

-- ==================== 知识系统 ====================

function WorkSystem.addKnowledgeExp(knowledgeId, amount)
    local def = WorkSystem.knowledgeDefs[knowledgeId]
    if not def then return end
    local S = GameState.state
    local exp = (S[def.expVar] or 0) + amount
    local level = S[def.levelVar] or 0
    while exp >= 100 do
        exp = exp - 100
        level = level + 1
        GameState.modStat(def.stat, 1)
        WorkSystem.addLifeExp(50)
        GameState.addDateLog(def.name, "等级提升",
            def.name .. "等级提升到 " .. level .. "，" .. def.statName .. "+1。")
        GameState.showNotification(
            def.name .. "等级提升到 " .. level .. "！" .. def.statName .. "+1。")
    end
    S[def.expVar] = exp
    S[def.levelVar] = level
end

--- 通用知识直接升级函数
---@param knowledgeId string
---@param amount number
function WorkSystem.addKnowledgeLevel(knowledgeId, amount)
    local def = WorkSystem.knowledgeDefs[knowledgeId]
    if not def then return end
    local S = GameState.state
    for _ = 1, amount do
        S[def.levelVar] = (S[def.levelVar] or 0) + 1
        GameState.modStat(def.stat, 1)
        WorkSystem.addLifeExp(50)
        GameState.addDateLog(def.name, "等级提升",
            def.name .. "等级提升到 " .. S[def.levelVar] .. "，" .. def.statName .. "+1。")
        GameState.showNotification(
            def.name .. "等级提升到 " .. S[def.levelVar] .. "！" .. def.statName .. "+1。")
    end
end

--- 兼容包装：增加礼仪经验
---@param amount number
function WorkSystem.addMannerExp(amount)
    WorkSystem.addKnowledgeExp("manner", amount)
end

--- 兼容包装：增加历史经验
---@param amount number
function WorkSystem.addHistoryExp(amount)
    WorkSystem.addKnowledgeExp("history", amount)
end

--- 兼容包装：直接增加礼仪等级
---@param amount number
function WorkSystem.addMannerLevel(amount)
    WorkSystem.addKnowledgeLevel("manner", amount)
end

--- 兼容包装：直接增加历史等级
---@param amount number
function WorkSystem.addHistoryLevel(amount)
    WorkSystem.addKnowledgeLevel("history", amount)
end

-- ==================== 生活等级 ====================

--- 增加生活经验（每150点升一级，给2属性点）
---@param exp number
function WorkSystem.addLifeExp(exp)
    local S = GameState.state
    local newExp = S.lifeExp + exp
    local level = S.lifeLevel
    if newExp >= 150 then
        local oldLevel = level
        level = level + math.floor(newExp / 150)
        newExp = newExp % 150
        local pointsGain = (level - oldLevel) * 2
        S.attrPoints = S.attrPoints + pointsGain
        GameState.addDateLog("生活等级", "等级提升",
            "等级提升到 " .. level .. "，获得 " .. pointsGain .. " 点属性点。")
        GameState.showNotification(
            "生活等级提升到 " .. level .. "！获得 " .. pointsGain .. " 属性点。")
    end
    S.lifeExp = newExp
    S.lifeLevel = level
end

-- ==================== 职业经验 ====================

--- 增加玩家职业经验（每100点升一级，对应属性+1，时薪+10/15，里程碑额外加成）
---@param job string "waiter"/"cleric"/"blacksmith"/"laborer"/"butler"
---@param exp number
function WorkSystem.addJobExp(job, exp)
    local S = GameState.state
    local data = WorkSystem.JOB_DATA[job]
    if not data then return end

    local newExp = S[data.expVar] + exp
    local oldLevel = S[data.levelVar]
    local level = oldLevel

    while newExp >= 100 do
        level = level + 1
        newExp = newExp - 100
        -- 基础升级：属性+1，时薪+wageUp
        GameState.modStat(data.stat, 1)
        S[data.wageVar] = S[data.wageVar] + data.wageUp
        -- 里程碑检查（3/5/7/10级额外奖励）
        local bonuses = WorkSystem.JOB_LEVEL_BONUSES[job]
        local bonus = bonuses and bonuses[level]
        if bonus then
            if bonus.stats then
                for stat, amt in pairs(bonus.stats) do
                    GameState.modStat(stat, amt)
                end
            end
            if bonus.wageBonus then
                S[data.wageVar] = S[data.wageVar] + bonus.wageBonus
            end
            if bonus.item then
                S.inventory = S.inventory or {}
                table.insert(S.inventory, bonus.item)
            end
        end
    end

    if level > oldLevel then
        local title = WorkSystem.getJobTitleForLevel(job, level)
        local statName = data.stat == "ML" and "魅力"
            or data.stat == "LG" and "灵感"
            or data.stat == "NL" and "耐力"
            or "力量"
        -- 里程碑额外信息
        local bonuses = WorkSystem.JOB_LEVEL_BONUSES[job]
        local bonus = bonuses and bonuses[level]
        local bonusMsg = ""
        if bonus then
            bonusMsg = "\n" .. (bonus.msg or "")
            if bonus.item then
                bonusMsg = bonusMsg .. "\n🎁 获得: " .. bonus.item
            end
        end
        GameState.addDateLog(data.name, "职业升级",
            "晋升为「" .. title .. "」(Lv." .. level .. ")，时薪+" .. data.wageUp .. "，" .. statName .. "+1。" .. bonusMsg)
        GameState.showNotification(
            "🎖️ 晋升为「" .. title .. "」！" .. bonusMsg)
        GameState.addRecentEvent("晋升为「" .. title .. "」(Lv." .. level .. ")！" .. statName .. "+1。")
        WorkSystem.addLifeExp(50)
    end

    S[data.expVar] = newExp
    S[data.levelVar] = level
end

--- 增加莱德职业经验（每100点升一级，力量+1，时薪+10）
---@param job string
---@param exp number
---@return number 莱德当前时薪
function WorkSystem.addInitialNameJobExp(job, exp)
    local S = GameState.state
    local data = WorkSystem.LEIDE_JOB_DATA[job]
    if not data then return 0 end

    local newExp = S[data.expVar] + exp
    local level = S[data.levelVar]
    local upgraded = false

    while newExp >= 100 do
        level = level + 1
        newExp = newExp - 100
        upgraded = true
        S.initialName_LL = S.initialName_LL + 1
        S[data.wageVar] = S[data.wageVar] + 10
    end

    if upgraded then
        local jobName = WorkSystem.JOB_DATA[job] and WorkSystem.JOB_DATA[job].name or job
        GameState.addDateLog(S.initialName, "职业升级",
            jobName .. "等级提升到 " .. level .. "，时薪+10。")
        GameState.showNotification(
            S.initialName .. "的" .. jobName .. "等级提升到 " .. level .. "！")
    end

    S[data.expVar] = newExp
    S[data.levelVar] = level
    return S[data.wageVar]
end

-- ==================== 打工函数 ====================

--- 计算含加成的实际工资
---@param job string
---@return number
function WorkSystem.calcWage(job)
    local S = GameState.state
    local data = WorkSystem.JOB_DATA[job]
    if not data then return 0 end

    local wage = S[data.wageVar]
    -- 奥梅尔技能加成
    if S.oamelSkillActive then
        wage = math.floor(wage * (1 + S.oamelSkillBonus / 100))
    end
    -- 梅菲斯工资加成
    wage = wage + (S.meifeiWageBonus or 0)
    return wage
end

--- 普通打工（1小时，加经验加工资）
---@param job string
---@return string 结果描述
function WorkSystem.doWork(job)
    local S = GameState.state
    local moneyGain = WorkSystem.calcWage(job)

    WorkSystem.addJobExp(job, 20)
    S.money = S.money + moneyGain
    TimeSystem.addMinutes(60)

    local result = "你忙碌了一小时，赚了" .. moneyGain .. "金币。"

    -- 首次打工政府就业补贴
    if not S.firstJobBonusClaimed then
        S.firstJobBonusClaimed = true
        S.money = S.money + 100
        result = result .. "\n\n🎉 恭喜完成第一份工作！政府就业补贴金 +100 金币已发放到你的钱袋。"
        GameState.addRecentEvent("获得政府就业补贴金 100 金币")
    end

    return result
end

--- 和莱德一起打工
---@param job string
---@return string 结果描述
function WorkSystem.workWithLeiDe(job)
    local S = GameState.state
    local wage = WorkSystem.calcWage(job)

    S.money = S.money + wage
    WorkSystem.addJobExp(job, 20)

    local leiDeWage = WorkSystem.addInitialNameJobExp(job, 20)
    local share = math.floor(leiDeWage / 2)
    S.initialNameSavings = S.initialNameSavings + leiDeWage
    S.money = S.money + share
    S.initialNameSavings = S.initialNameSavings - share
    NPCSystem.addAffection("initialName", 3)

    TimeSystem.addMinutes(60)

    local jobName = WorkSystem.JOB_DATA[job] and WorkSystem.JOB_DATA[job].name or job
    return "你和" .. S.initialName .. "一起做" .. jobName .. "一小时，你赚了" .. wage .. "金币，" ..
        S.initialName .. "赚了" .. leiDeWage .. "金币，分给你" .. share .. "金币。"
end

-- ==================== 打工事件触发 ====================

--- 执行打工并触发随机事件（返回基础信息 + 事件数据）
---@param job string
---@param withLeiDe boolean
---@return string baseMsg, table|nil event
function WorkSystem.doWorkWithEvent(job, withLeiDe)
    local S = GameState.state
    local moneyGain = WorkSystem.calcWage(job)

    WorkSystem.addJobExp(job, 20)
    S.money = S.money + moneyGain
    -- 打工后清洁度下降
    local cleanDrop = (job == "laborer" or job == "blacksmith") and 8 or 5
    GameState.modStat("cleanliness", -(cleanDrop))

    -- 发放并换上工作制服
    local uniformMsg = WorkSystem.grantUniform(job)
    S.outfit = WorkSystem.getUniformForJob(job)
    TimeSystem.addMinutes(60)

    -- 收集打工关键词
    local kwOk, KW = pcall(require, "systems.KeywordSystem")
    if kwOk and KW.collectKeyword then
        if job == "waiter" then KW.collectKeyword("tavern_work")
        elseif job == "laborer" then KW.collectKeyword("port_labor")
        elseif job == "butler" then KW.collectKeyword("noble_gossip")
        elseif job == "blacksmith" then KW.collectKeyword("guild_mission")
        elseif job == "cleric" then KW.collectKeyword("history_class")
        end
        if math.random() < 0.3 then KW.collectKeyword("market_trade") end
    end

    local jobName = WorkSystem.JOB_DATA[job] and WorkSystem.JOB_DATA[job].name or job
    local msg = "你忙碌了一小时，赚了 " .. moneyGain .. " 金币。"
    if uniformMsg then
        msg = msg .. "\n" .. uniformMsg
    end

    -- 记录最近动态
    GameState.addRecentEvent("在" .. jobName .. "岗位工作，赚了 " .. moneyGain .. " 金币。")

    -- 和莱德一起
    if withLeiDe and job ~= "butler" then
        local leiDeWage = WorkSystem.addInitialNameJobExp(job, 20)
        local share = math.floor(leiDeWage / 2)
        S.initialNameSavings = S.initialNameSavings + leiDeWage
        S.money = S.money + share
        S.initialNameSavings = S.initialNameSavings - share
        NPCSystem.addAffection("initialName", 3)
        msg = msg .. "\n" .. S.initialName .. "也和你一起工作，他赚了 " ..
            leiDeWage .. " 金币，分给你 " .. share .. " 金币。"
    end

    -- 75% 概率触发带选择的随机事件
    local event = nil
    local events = WorkSystem.WORK_EVENTS[job]
    if events and #events > 0 and math.random() < 0.75 then
        event = events[math.random(1, #events)]
    end

    return msg, event
end

--- 应用事件选择的奖励（委托 EventTemplates）
---@param choice table { gold, exp, item, npc, npcAmt, npc2, npc2Amt, result, statCheck }
---@return string 结果描述
function WorkSystem.applyEventReward(choice)
    local lines = ET.applyRewardEffects(choice, WorkSystem.addLifeExp)

    -- 属性检定分支
    if choice.statCheck then
        return ET.executeStatCheck(
            choice.statCheck, lines,
            WorkSystem.knowledgeDefs, WorkSystem.addLifeExp,
            choice.result or "事件结束。"
        )
    end

    local result = choice.result or "事件结束。"
    return result .. ET.formatRewardText(lines)
end
-- ==================== 读书系统 ====================

function WorkSystem.readBook(book)
    local S = GameState.state
    local info = WorkSystem.bookInfo[book]
    if not info then return "没有这本书。" end

    -- 检查是否拥有
    if not S[info.hasVar] then
        return "你还没有" .. info.fullName .. "。"
    end

    -- 增加阅读次数
    local count = (S[info.readCountVar] or 0) + 1
    S[info.readCountVar] = count

    -- 增加经验
    WorkSystem.addKnowledgeExp(info.knowledgeId, 20)

    -- 首次读完奖励（满4次）
    if count >= 4 and not S[info.firstRewardVar] then
        S[info.firstRewardVar] = true
        GameState.modStat(info.rewardStat, 1)
        GameState.addDateLog(info.fullName, "首次读完",
            info.fullName .. " 读完，" .. info.statName .. "+1。")
        GameState.showNotification(
            "你读完了" .. info.fullName .. "，" .. info.statName .. "+1！")
    end

    TimeSystem.addMinutes(30)

    -- 返回对应的阅读文本
    local texts = WorkSystem.bookTexts[book]
    local idx = ((count - 1) % #texts) + 1
    return texts[idx]
end

-- ==================== 调酒笔记 ====================

--- 阅读调酒笔记
---@return string 阅读文本
function WorkSystem.readBartenderNote()
    local S = GameState.state
    if not S.hasBartenderNote then
        return "你还没有调酒笔记。"
    end

    S.bartenderNoteReadCount = (S.bartenderNoteReadCount or 0) + 1

    -- 增加技巧经验
    GameState.modStat("JQ", 1)
    TimeSystem.addMinutes(20)

    local texts = {
        "K的字迹出乎意料地工整：“调酒的关键是温度和时间……”",
        "“先倒基酒，再加配料。搅拌十二下，不多不少。”",
        "“客人的情绪比口味更重要。学会看他们的眼睛。”",
        "“这是我自创的配方：月光之吻。配料是秘密。”",
    }
    local idx = ((S.bartenderNoteReadCount - 1) % #texts) + 1

    -- 首次读完奖励
    if S.bartenderNoteReadCount >= 4 and not S.bartenderNoteRewarded then
        S.bartenderNoteRewarded = true
        GameState.modStat("JQ", 2)
        GameState.addDateLog("调酒笔记", "首次读完",
            "K的调酒笔记读完，技巧+2。")
        GameState.showNotification("你读完了K的调酒笔记，技巧+2！")
    end

    return texts[idx]
end

-- ==================== 属性分配 ====================

--- 分配属性点
---@param stat string "LL"/"LG"/"ML"/"NL"/"JQ"
---@return boolean 是否成功
function WorkSystem.allocateAttrPoint(stat)
    local S = GameState.state
    if S.attrPoints <= 0 then return false end

    local validStats = { LL = true, LG = true, ML = true, NL = true, JQ = true }
    if not validStats[stat] then return false end

    S.attrPoints = S.attrPoints - 1
    GameState.modStat(stat, 1)

    local statNames = { LL = "力量", LG = "灵感", ML = "魅力", NL = "耐力", JQ = "技巧" }
    GameState.showNotification(statNames[stat] .. "+1！剩余属性点：" .. S.attrPoints)
    return true
end

-- ==================== 房租系统 ====================

--- 获取当前应交房租
---@return number
function WorkSystem.getCurrentRent()
    local S = GameState.state
    if S.rentWeek <= 1 then
        return 300
    else
        return 700
    end
end

--- 交房租
---@return string 结果描述
function WorkSystem.payRent()
    local S = GameState.state
    local rent = WorkSystem.getCurrentRent()

    if S.money < rent then
        return "你没有足够的钱交房租（需要" .. rent .. "金币）。"
    end

    S.money = S.money - rent
    S.rentPaidThisWeek = true
    if S.oweRent > 0 then
        -- 先还欠款
        local payBack = math.min(S.oweRent, S.money)
        S.money = S.money - payBack
        S.oweRent = S.oweRent - payBack
        if payBack > 0 then
            return "你交了" .. rent .. "金币的房租，还还了" .. payBack .. "金币的欠款。"
        end
    end

    GameState.addDateLog("房东", "交租", "交了" .. rent .. "金币的房租。")
    return "你交了" .. rent .. "金币的房租。"
end

--- 处理NPCSystem中梅菲斯的延迟礼仪经验
function WorkSystem.processPendingMeifeiExp()
    local pending = NPCSystem._pendingMeifeiMannerExp or 0
    if pending > 0 then
        WorkSystem.addMannerExp(pending)
        NPCSystem._pendingMeifeiMannerExp = 0
    end
end

return WorkSystem
