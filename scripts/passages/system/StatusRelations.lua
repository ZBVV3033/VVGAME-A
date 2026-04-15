-- passages/system/StatusRelations.lua
-- Auto-split sub-module

return function(handlers, deps)

local GameState = deps.GameState
local TimeSystem = deps.TimeSystem
local WorkSystem = deps.WorkSystem
local HomeSystem = deps.HomeSystem
local BattleSystem = deps.BattleSystem
local ChangelogData = deps.ChangelogData
local SaveSystem = deps.SaveSystem
local MainQuest = deps.MainQuest
local MainQuestCh2 = deps.MainQuestCh2
local MainQuestCh3 = deps.MainQuestCh3
local CookingSystem = deps.CookingSystem
local FarmingSystem = deps.FarmingSystem
local UniSystem = deps.UniSystem
local TownLife = deps.TownLife
local RandomEvents = deps.RandomEvents
local KeywordSystem = deps.KeywordSystem
local SideQuests = deps.SideQuests
local CommonUtils = deps.CommonUtils
local PassageDeps = deps.PassageDeps
local addAffection = deps.addAffection
local addDateLog = deps.addDateLog
local addOamelAffection = deps.addOamelAffection
local addMeifeiAffection = deps.addMeifeiAffection
local topicDialogues = deps.topicDialogues
local handlers = deps.handlers

handlers["属性"] = function(S)
    -- 第三人称状态描述
    local pName = (S.PNN ~= "" and S.PNN) or "诺兰"
    local outfitTxt = ""
    local o = S.outfit or "casual"
    if string.find(o, "^uniform_") then
        local wsOk, WS = pcall(require, "systems.WorkSystem")
        local info = wsOk and WS.getUniformInfo and WS.getUniformInfo(o)
        outfitTxt = info and ("穿着" .. info.name) or "穿着工作服"
    elseif o == "work" then outfitTxt = "穿着工作服"
    elseif o == "formal" then outfitTxt = "衣着整洁"
    elseif o == "pajamas" then outfitTxt = "穿着睡衣"
    else outfitTxt = "穿着便装" end

    local bodyTxt = ""
    local fat = S.fatigue or 0
    local str = S.stress or 0
    local sat = S.satiety or 80
    local cln = S.cleanliness or 90
    if fat >= 80 then bodyTxt = "，顶着浓重的黑眼圈"
    elseif fat >= 60 then bodyTxt = "，眼下挂着淡淡青黑"
    elseif str >= 80 then bodyTxt = "，面目狰狞情绪暴躁"
    elseif str >= 60 then bodyTxt = "，眉头紧锁满脸焦虑"
    elseif sat <= 15 then bodyTxt = "，饿得面色发白"
    elseif sat <= 30 then bodyTxt = "，肚子咕咕叫"
    elseif cln <= 20 then bodyTxt = "，浑身脏兮兮的"
    elseif cln <= 40 then bodyTxt = "，身上有些汗味"
    elseif fat <= 10 and str <= 10 and sat >= 70 and cln >= 80 then bodyTxt = "，精神饱满容光焕发"
    elseif fat <= 30 then bodyTxt = "，看起来状态不错"
    else bodyTxt = "，神情平淡" end

    local statusDesc = pName .. outfitTxt .. bodyTxt .. "。"

    -- 声望与邪恶
    local rep = S.reputation or 0
    local evil = S.evilness or 0
    local repTitle = "无名小卒"
    if rep >= 100 then repTitle = "传奇英雄"
    elseif rep >= 60 then repTitle = "远近闻名"
    elseif rep >= 30 then repTitle = "小有名气"
    elseif rep >= 10 then repTitle = "略有耳闻" end
    local evilTitle = ""
    if evil >= 80 then evilTitle = "恶贯满盈"
    elseif evil >= 50 then evilTitle = "臭名昭著"
    elseif evil >= 20 then evilTitle = "劣迹斑斑"
    elseif evil >= 5 then evilTitle = "小有恶名" end

    local text = statusDesc .. "\n\n"
        .. "── 角色属性 ──\n\n"
        .. "五维　力" .. (S.LL or 1) .. " 灵" .. (S.LG or 1) .. " 魅" .. (S.ML or 3) .. " 耐" .. (S.NL or 2) .. " 技" .. (S.JQ or 1) .. "\n\n"
        .. "生活等级 Lv." .. (S.lifeLevel or 1) .. " (" .. (S.lifeExp or 0) .. "/100)\n\n"
        .. "── 声望与名声 ──\n"
        .. "声望：" .. rep .. "（" .. repTitle .. "）\n"
        .. (evilTitle ~= "" and ("邪恶：" .. evil .. "（" .. evilTitle .. "）\n") or "")
        .. "\n"

    text = text
        .. "── 个性 ──\n"
        .. "勇敢：" .. (S.YG or 0) .. "　|　冷静：" .. (S.LJ or 0) .. "　|　暴躁：" .. (S.BZ or 0) .. "\n\n"
        .. "── 魔法适应性 ──\n"
        .. "暗：" .. (S.ASX or 1) .. "　|　光：" .. (S.GSX or 5) .. "　|　木：" .. (S.MSY or 1) .. "\n\n"
        .. "角色简介\n"
        .. (S.PNN or "???") .. " —— 一个在小镇艾瑟顿生活的普通人。\n"
        .. "· 力量：影响体力劳动和搬重物\n"
        .. "· 灵感：影响学习新事物和突发灵感\n"
        .. "· 魅力：影响与人交往的第一印象\n"
        .. "· 耐力：影响长时间工作不累\n"
        .. "· 技巧：影响手艺活和精细操作\n"
        .. "· 礼仪：贵族社交知识，每级提升魅力\n"
        .. "· 历史：王国历史知识，每级提升灵感"

    -- ========== 队友属性 ==========
    -- 莱德（条件：已住在家中）
    if S.initialNameAtHome then
        local leideName = S.initialName or "莱德"
        text = text .. "\n\n── " .. leideName .. " 的属性 ──\n"
            .. "五维　力" .. (S.initialName_LL or 2) .. " 灵" .. (S.initialName_LG or 2)
            .. " 魅" .. (S.initialName_ML or 2) .. " 耐" .. (S.initialName_NL or 2)
            .. " 技" .. (S.initialName_JQ or 2) .. "\n"
            .. "等级 Lv." .. (S.initialNameLevel or 1) .. "\n"

        -- 莱德的职业等级（仅显示>1的）
        local leideJobs = {
            { key = "initialNameLaborerLevel", expKey = "initialNameLaborerExp", name = "杂工" },
            { key = "initialNameWaiterLevel", expKey = "initialNameWaiterExp", name = "侍应生" },
            { key = "initialNameClericLevel", expKey = "initialNameClericExp", name = "文员" },
            { key = "initialNameBlacksmithLevel", expKey = "initialNameBlacksmithExp", name = "铁匠" },
        }
        local leideJobLines = {}
        for _, jd in ipairs(leideJobs) do
            local lv = S[jd.key] or 1
            if lv > 1 then
                local exp = S[jd.expKey] or 0
                table.insert(leideJobLines, jd.name .. " Lv." .. lv .. " (" .. exp .. "/100)")
            end
        end
        if #leideJobLines > 0 then
            text = text .. "职业："
            for i, line in ipairs(leideJobLines) do
                text = text .. line .. (i < #leideJobLines and "、" or "") 
            end
            text = text .. "\n"
        end
        text = text .. "好感度：" .. (S.initialNameAffection or 0) .. "\n"
    end

    -- K（条件：已入队）
    if S.kInParty then
        text = text .. "\n\n── K 的属性 ──\n"
            .. "五维　力" .. (S.K_LL or 4) .. " 灵" .. (S.K_LG or 6)
            .. " 魅" .. (S.K_ML or 2) .. " 耐" .. (S.K_NL or 1)
            .. " 技" .. (S.K_JQ or 3) .. "\n"
            .. "等级 Lv." .. (S.kLevel or 1) .. "\n"
        -- K 的战斗信息
        if S.kCombat then
            local kc = S.kCombat
            text = text .. "形态：" .. (kc.form == "sword" and "剑士" or "法师") .. "\n"
            text = text .. "HP " .. (kc.hp or 0) .. "/" .. (kc.maxHp or 75)
                .. "　MP " .. (kc.mp or 0) .. "/" .. (kc.maxMp or 50) .. "\n"
        end
        text = text .. "好感度：" .. (S.kAffection or 0) .. "\n"
    end

    local from = S._settingsFrom or S.currentPassage or "家"
    return {
        text = text,
        choices = {
            { text = "返回", target = from },
        },
    }
end

---===================== 属性分配 =====================
--- Twine pid 13


handlers["属性分配"] = function(S)
    local text = "属性分配\n\n你当前有 " .. (S.attrPoints or 0) .. " 点可分配属性。"
    local choices = {}

    if (S.attrPoints or 0) > 0 then
        table.insert(choices, { text = "力量 +1", action = function() S.LL = (S.LL or 1) + 1; S.attrPoints = S.attrPoints - 1; return "属性分配" end })
        table.insert(choices, { text = "灵感 +1", action = function() S.LG = (S.LG or 1) + 1; S.attrPoints = S.attrPoints - 1; return "属性分配" end })
        table.insert(choices, { text = "魅力 +1", action = function() S.ML = (S.ML or 3) + 1; S.attrPoints = S.attrPoints - 1; return "属性分配" end })
        table.insert(choices, { text = "耐力 +1", action = function() S.NL = (S.NL or 2) + 1; S.attrPoints = S.attrPoints - 1; return "属性分配" end })
        table.insert(choices, { text = "技巧 +1", action = function() S.JQ = (S.JQ or 1) + 1; S.attrPoints = S.attrPoints - 1; return "属性分配" end })
    else
        text = text .. "\n没有可分配的属性点。"
    end

    table.insert(choices, { text = "返回属性", target = "属性" })
    table.insert(choices, { text = "返回主页面", target = "家" })

    return { text = text, choices = choices }
end

---===================== 社会关系 =====================
--- Twine pid 14


handlers["社会关系"] = function(S)
    -- NPC 档案数据库
    local npcProfiles = PassageData._getNpcProfiles(S)

    -- 分类：核心 / 重要 / 小镇居民
    local coreNpcs = {}     -- 始终判定已遇见的核心角色
    local importantNpcs = {}
    local townNpcs = {}

    for _, p in ipairs(npcProfiles) do
        if p.met then
            if p.category == "core" then
                table.insert(coreNpcs, p)
            elseif p.category == "important" then
                table.insert(importantNpcs, p)
            else
                table.insert(townNpcs, p)
            end
        end
    end

    local text = "社会关系\n\n"

    if #coreNpcs == 0 and #importantNpcs == 0 and #townNpcs == 0 then
        text = text .. "你还没有遇见任何人。\n出门走走，认识一下这个小镇的居民吧。"
        return { text = text, choices = { { text = "返回", target = S._settingsFrom or "家" } } }
    end

    -- 渲染分组
    local function renderGroup(title, npcs)
        if #npcs == 0 then return "" end
        local t = "━━━ " .. title .. " ━━━\n"
        for _, p in ipairs(npcs) do
            local heartIcon = p.affection >= 80 and "💖" or (p.affection >= 40 and "💛" or "🤍")
            t = t .. heartIcon .. " " .. p.displayName .. "\n"
            t = t .. "    " .. p.race .. " · " .. p.job .. "\n"
            t = t .. "    好感 " .. p.affection .. " | " .. p.relationStage .. "\n"
            if p.location then
                t = t .. "    " .. p.location .. "\n"
            end
            t = t .. "\n"
        end
        return t
    end

    text = text .. renderGroup("羁绊", coreNpcs)
    text = text .. renderGroup("往来", importantNpcs)
    text = text .. renderGroup("小镇居民", townNpcs)

    -- 未遇见的可攻略角色线索
    local hints = {}
    if not S.urielMet then
        table.insert(hints,
            "? 神秘的守护者\n"
            .. "    身份不明的血亲，似乎一直在暗中关注着你。\n"
            .. "    在小镇生活一段时间后，你可能会注意到一些蛛丝马迹……\n"
            .. "    匿名的帮助、没有署名的信件——有人在暗处默默守护着你。\n")
    end
    if not S.gangBossMet then
        table.insert(hints,
            "? 贫民窟的主人\n"
            .. "    据说花园小镇西面的贫民窟里，有一栋与周围格格不入的华丽宅邸。\n"
            .. "    穿过花园小镇西边的小巷前往贫民窟，走向那栋宅邸试试看。\n"
            .. "    那里的主人是个年轻人，对外人倒不算排斥。\n")
    end
    if #hints > 0 then
        text = text .. "━━━ 未知的缘分 ━━━\n"
        for _, h in ipairs(hints) do
            text = text .. h .. "\n"
        end
    end

    -- 选项：每个已遇见的 NPC 可点击查看详情
    local choices = {}
    local allMet = {}
    for _, list in ipairs({ coreNpcs, importantNpcs, townNpcs }) do
        for _, p in ipairs(list) do table.insert(allMet, p) end
    end
    for _, p in ipairs(allMet) do
        table.insert(choices, {
            text = p.displayName .. " 的档案",
            target = "人物档案_" .. p.id,
        })
    end
    table.insert(choices, { text = "返回", action = function() return S._settingsFrom or "家" end })

    return { text = text, choices = choices }
end


end
