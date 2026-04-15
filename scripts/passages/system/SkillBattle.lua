-- passages/system/SkillBattle.lua
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

handlers["技能"] = function(S)
    local from = S._settingsFrom or S.currentPassage or "家"
    local text = "── 技能总览 ──\n\n"

    -- 职业等级评价
    local jobComments = {
        waiter = {
            "新手侍应：端盘子还会手抖，不过至少没摔过。",
            "你已经能熟练地在桌间穿梭，偶尔还能记住常客的喜好。",
            "老练的侍应生，连最挑剔的客人都挑不出毛病。",
            "餐厅的顶梁柱，新来的侍应都要跟你学规矩。",
            "传说中的侍应之神，任何突发状况都难不倒你。",
        },
        cleric = {
            "新人文员：你刚学会不把经书拿倒，克丽丝对你很有耐心。",
            "你能准确地翻到需要的段落，抄写也不再出错了。",
            "教堂里的可靠帮手，连长老都开始信任你整理重要文献。",
            "资深文员，教堂的档案室在你手里井井有条。",
            "几乎半个神职人员了，你对教义的理解超过了大多数人。",
        },
        blacksmith = {
            "学徒铁匠：你还分不清哪块是废铁哪块是好钢，麦拿拿没少骂你。",
            "你终于能打出像样的铁钉了，虽然麦拿拿说还差得远。",
            "能独立完成简单的修理工作，麦拿拿偶尔会点头认可。",
            "熟练的铁匠，冒险者开始指名找你修装备。",
            "铁匠铺的台柱子，麦拿拿嘴上不说，心里把你当半个师傅看。",
        },
        laborer = {
            "新手搬运工：你搬了半天腰都直不起来，但至少没偷懒。",
            "你已经掌握了省力的搬运技巧，不再是最后一个收工的人。",
            "码头上的老手了，黑胡子派活时总会优先想到你。",
            "搬运组的骨干，新来的工人都听你指挥。",
            "码头传奇，连黑胡子都说你是他见过最靠谱的工人。",
        },
        butler = {
            "新人侍从：你完全不擅长照顾别人，现在可能是别人在照顾你。",
            "你学会了基本的侍奉礼仪，至少不会再把茶洒在客人身上。",
            "称职的侍从，主人的日常起居被你安排得井井有条。",
            "优秀的侍从，贵族们在社交场合都会夸赞你的专业。",
            "传说级别的侍从，你的存在本身就是主人身份的象征。",
        },
    }
    local jobKeyMap = {
        { key = "jobWaiterLevel", expKey = "jobWaiterExp", name = "侍应生", unlockKey = "unlockWaiter", commentKey = "waiter" },
        { key = "jobClericLevel", expKey = "jobClericExp", name = "教堂文员", unlockKey = "unlockCleric", commentKey = "cleric" },
        { key = "jobBlacksmithLevel", expKey = "jobBlacksmithExp", name = "铁匠", unlockKey = "unlockBlacksmith", commentKey = "blacksmith" },
        { key = "jobLaborerLevel", expKey = "jobLaborerExp", name = "港口杂工", unlockKey = "unlockLaborer", commentKey = "laborer" },
        { key = "butlerLevel", expKey = "butlerExp", name = "侍从", unlockKey = "unlockButler", commentKey = "butler" },
    }
    local jobLines = {}
    for _, jd in ipairs(jobKeyMap) do
        local lv = S[jd.key] or 0
        if S[jd.unlockKey] == true or lv > 1 then
            local exp = S[jd.expKey] or 0
            local line = jd.name .. " Lv." .. lv .. " (" .. exp .. "/100)\n"
            local comments = jobComments[jd.commentKey]
            if comments then
                local ci = math.min(lv, #comments)
                if ci >= 1 then line = line .. "  " .. comments[ci] .. "\n" end
            end
            table.insert(jobLines, line)
        end
    end
    if #jobLines > 0 then
        text = text .. "── 职业等级 ──\n"
        for _, line in ipairs(jobLines) do
            text = text .. line
        end
        text = text .. "\n"
    end

    -- 大学专业评价
    local majorComments = {
        warrior = {
            "刚入门的战士学员，连木剑都握不稳。",
            "你开始理解基本的战斗站位和攻防节奏。",
            "能够灵活运用课堂所学，在实战中有模有样。",
            "战术素养出众，教官经常拿你当示范。",
            "战士学的佼佼者，毕业后必成一方悍将。",
        },
        mage = {
            "魔法学新生，你对魔力的感知还停留在「好像有点麻」的阶段。",
            "你能稳定地感应魔力流动，虽然还不能做太复杂的事。",
            "能独立完成中等难度的魔法实验，同学们开始刮目相看。",
            "魔法理论和实践并重，你是教授最看好的学生之一。",
            "魔法学的天才，你对魔力的理解已经超越了课本的范畴。",
        },
        theology = {
            "神学新生，你背经文还会背串行，但虔诚的心是有的。",
            "你对教义的理解逐渐深入，能参与神学讨论不掉队了。",
            "能独立解读古代经文，你的见解有时连教授都称赞。",
            "神学造诣深厚，教会已经注意到你这颗冉冉升起的新星。",
            "神学大师级别的理解力，也许某天你会写出自己的教义注释。",
        },
        cooking = {
            "烹饪学新生，你煮的东西目前只有「能吃」这一个优点。",
            "你掌握了基本的调味技巧，做出来的菜终于有人愿意吃第二口了。",
            "厨艺日益精进，你的创意料理经常让同学们排队品尝。",
            "烹饪学的明星学员，你的毕业作品可能会惊艳整个学院。",
            "厨神在世，你对食材的理解已经到了化腐朽为神奇的境界。",
        },
    }
    if S.uniMajorData then
        local majorNames = { warrior = "战士学", mage = "魔法学", theology = "神学", cooking = "烹饪学" }
        local majorLines = {}
        for major, data in pairs(S.uniMajorData) do
            if data.level and data.level >= 1 then
                local mName = majorNames[major] or major
                local line = mName .. " Lv." .. data.level .. " (" .. (data.exp or 0) .. "/100)\n"
                local comments = majorComments[major]
                if comments then
                    local ci = math.min(data.level, #comments)
                    if ci >= 1 then line = line .. "  " .. comments[ci] .. "\n" end
                end
                table.insert(majorLines, line)
            end
        end
        if #majorLines > 0 then
            text = text .. "── 大学专业 ──\n"
            for _, line in ipairs(majorLines) do
                text = text .. line
            end
            text = text .. "\n"
        end
    end

    -- 生活技能（烹饪）评价
    local cookLv = S.cookingLevel or 0
    local cookExp = S.cookingExp or 0
    local cookTitles = { [0] = "未学习", [1] = "入门", [2] = "熟练", [3] = "精通" }
    local cookTitle = cookTitles[cookLv] or ""
    local cookComments = {
        [0] = "你还没学过烹饪，但肚子饿的时候谁都是天才。",
        [1] = "你能做出不烧焦的煎蛋了，这是一个好的开始。",
        [2] = "你做的菜已经有回头客了，虽然菜单还比较简单。",
        [3] = "大厨级别的手艺，你随手做的家常菜都能让人赞不绝口。",
    }
    text = text .. "── 生活技能 ──\n"
    text = text .. "烹饪 Lv." .. cookLv
    if cookTitle ~= "" then text = text .. "（" .. cookTitle .. "）" end
    text = text .. " (" .. cookExp .. "/100)\n"
    if cookComments[cookLv] then
        text = text .. "  " .. cookComments[cookLv] .. "\n"
    end
    text = text .. "\n"

    -- 知识（数据驱动，>=1级才显示，含等级评价）
    local wsOk2, WS2 = pcall(require, "systems.WorkSystem")
    local knowledgeComments = {
        manner = {
            "你的礼仪水平仅仅是不闹笑话的程度。",
            "基本的社交礼仪你已经掌握，至少贵族不会当面皱眉了。",
            "你的举止得体，在正式场合也不会显得格格不入。",
            "礼仪大师，你的一举一动都散发着教养的光芒。",
            "行走的礼仪教科书，连宫廷都请不到比你更优雅的人。",
        },
        history = {
            "你记得自己的家庭成员，不过祖先们你就不认识了。",
            "你能说出王国近百年的大事件，虽然年份有时会搞混。",
            "对本地历史了如指掌，阿莫斯都愿意和你讨论学术问题。",
            "历史学者级别的知识储备，古籍中的记载你信手拈来。",
            "活着的百科全书，你对历史的理解比大多数学者都深刻。",
        },
        theology = {
            "你能分清教堂和酒馆的区别，这算是一个起点。",
            "你对基本教义有了了解，祈祷时不再只是装样子。",
            "能独立解读经文含义，克丽丝说你有神学天赋。",
            "对神学有深刻理解，连教堂长老都会征求你的意见。",
            "神学权威，你的见解足以写成新的教义注释。",
        },
        botany = {
            "你能分清杂草和鲜花，但仅此而已。",
            "你认识了常见的草药，至少不会把毒草当野菜吃。",
            "能辨认大部分野外植物，知道哪些能入药哪些有毒。",
            "植物学家级别，珍稀草药在你眼里就像老朋友一样熟悉。",
            "行走的草药百科，你对植物的了解已经超越了书本记载。",
        },
        repair = {
            "你知道锤子是用来敲东西的，这已经是你全部的修理知识了。",
            "简单的修补工作你能应付，复杂的就得找专业人士了。",
            "你能修理大多数日常物品，麦拿拿说你有当铁匠的潜力。",
            "精通各种修理技术，从钟表到武器都难不倒你。",
            "修理大师，你能让任何破损的东西焕发新生。",
        },
        tactics = {
            "你知道打架要用拳头，但这不算战术。",
            "你开始理解基本的战斗阵型和进退时机。",
            "能分析敌人的弱点并制定针对性的战术方案。",
            "战术家级别，你的指挥能让一支小队发挥出数倍战力。",
            "战略大师，你在脑中推演战局的速度比别人挥剑还快。",
        },
        magicTheory = {
            "你知道魔法存在，但它对你来说和变戏法没什么区别。",
            "你理解了魔力的基本原理，能看懂简单的魔法阵图。",
            "能分析中级魔法的构成原理，对魔法世界的认知大幅提升。",
            "魔法理论学者，你对魔力运行规律的理解令人叹服。",
            "理论宗师，你的论文足以改写魔法学教科书。",
        },
        cookTheory = {
            "你知道盐是咸的糖是甜的，但烹饪理论？完全是空白。",
            "你了解了基本的食材搭配原理，做菜不再全靠感觉。",
            "对食材的化学反应有深入理解，你的料理开始有科学依据了。",
            "烹饪理论大师，你能从分子层面解释为什么这道菜好吃。",
            "食神级理论素养，你对烹饪的理解已经上升到了哲学高度。",
        },
    }
    local knowledgeLines = {}
    if wsOk2 and WS2.knowledgeOrder and WS2.knowledgeDefs then
        for _, kId in ipairs(WS2.knowledgeOrder) do
            local def = WS2.knowledgeDefs[kId]
            if def then
                local lv = S[def.levelVar] or 0
                if lv >= 1 then
                    local exp = S[def.expVar] or 0
                    local line = def.name .. " Lv." .. lv .. " (" .. exp .. "/100)"
                        .. "  → 升级:" .. def.statName .. "+1\n"
                    local comments = knowledgeComments[kId]
                    if comments then
                        local ci = math.min(lv, #comments)
                        if ci >= 1 then line = line .. "  " .. comments[ci] .. "\n" end
                    end
                    table.insert(knowledgeLines, line)
                end
            end
        end
    end
    if #knowledgeLines > 0 then
        text = text .. "── 知识 ──\n"
        for _, line in ipairs(knowledgeLines) do
            text = text .. line
        end
    end

    return {
        text = text,
        choices = {
            { text = "返回", target = from },
        },
    }
end

---===================== 战斗面板 =====================


handlers["战斗面板"] = function(S)
    local from = S._settingsFrom or S.currentPassage or "十字路口"
    local bsOk, BS = pcall(require, "systems.BattleSystem")
    local text = "── 战斗面板 ──\n"

    -- 通用：渲染一个角色的战斗数据和技能
    local function renderCombat(name, combat, categories)
        local t = "\n── " .. name .. " ──\n"
            .. "HP " .. (combat.hp or 0) .. "/" .. (combat.maxHp or 0)
            .. "　MP " .. (combat.mp or 0) .. "/" .. (combat.maxMp or 0) .. "\n"
            .. "攻 " .. (combat.atkBase or 0) .. "　魔攻 " .. (combat.matkBase or 0)
            .. "　防 " .. (combat.def or 0) .. "　魔防 " .. (combat.mdef or 0) .. "\n"
            .. "力" .. (combat.power or 0) .. " 灵" .. (combat.insight or 0)
            .. " 魅" .. (combat.charm or 0) .. " 耐" .. (combat.stamina or 0)
            .. " 技" .. (combat.skill or 0) .. "　速" .. (combat.speed or 0) .. "\n"
            .. "等级 Lv." .. (combat.level or 1) .. "\n"

        if categories then
            for _, cat in ipairs(categories) do
                t = t .. "\n── " .. cat.name .. " ──\n"
                for _, sk in ipairs(cat.skills) do
                    local costStr = ""
                    if sk.cost and sk.cost ~= "" then
                        costStr = " [" .. sk.cost .. "]"
                    end
                    t = t .. sk.icon .. " " .. sk.name .. costStr .. "　" .. sk.desc .. "\n"
                end
            end
        end
        return t
    end

    -- 主角（始终显示）
    local pName = (S.PNN ~= "" and S.PNN) or "勇者"
    if S.playerCombat then
        local heroCats = bsOk and BS.getHeroCategories and BS.getHeroCategories() or nil
        text = text .. renderCombat(pName, S.playerCombat, heroCats)
    end

    -- K（条件：已入队）
    if S.kInParty and S.kCombat then
        local kCats = bsOk and BS.K_CATEGORIES or nil
        text = text .. renderCombat("K", S.kCombat, kCats)
    end

    -- 莱德（条件：已入队）
    if S.initialNameInParty and S.initialNameCombat then
        local leideName = S.initialName or "莱德"
        local leideCats = bsOk and BS.LEIDE_CATEGORIES or nil
        text = text .. renderCombat(leideName, S.initialNameCombat, leideCats)
    end

    -- 无队友提示
    if not S.kInParty and not S.initialNameInParty then
        text = text .. "\n── 暂无其他队友 ──\n"
            .. "在冒险中结识伙伴，他们可能会加入你的队伍。\n"
    end

    -- 显示当前职业
    local heroClass = S.playerCombat and S.playerCombat.heroClass or "none"
    local classNames = { none = "无（自由勇者）", warrior = "战士", mage = "法师" }
    text = text .. "\n── 当前职业：" .. (classNames[heroClass] or "无") .. " ──\n"

    return {
        text = text,
        choices = {
            { text = "转职", target = "转职" },
            { text = "返回", target = from },
        },
    }
end

---===================== 转职 =====================


handlers["转职"] = function(S)
    local bsOk, BS = pcall(require, "systems.BattleSystem")
    local heroClass = S.playerCombat and S.playerCombat.heroClass or "none"
    local classNames = { none = "无", warrior = "战士", mage = "法师" }

    local text = "── 职业转职 ──\n\n"
        .. "当前职业：" .. (classNames[heroClass] or "无") .. "\n\n"

    if bsOk and BS.HERO_CLASS_DEFS then
        for classId, def in pairs(BS.HERO_CLASS_DEFS) do
            local isCurrent = (heroClass == classId)
            local mark = isCurrent and " ★当前" or ""
            text = text .. "── " .. def.icon .. " " .. def.name .. mark .. " ──\n"
            text = text .. def.desc .. "\n"
            -- 属性加成
            local statNames = { atkBase = "攻击", def = "防御", maxHp = "最大HP", matkBase = "魔攻", insight = "灵感", maxMp = "最大MP" }
            local bonusParts = {}
            for stat, val in pairs(def.bonuses) do
                table.insert(bonusParts, (statNames[stat] or stat) .. "+" .. val)
            end
            text = text .. "属性加成：" .. table.concat(bonusParts, "、") .. "\n"
            -- 专属技能
            for _, sk in ipairs(def.skills) do
                text = text .. "  " .. sk.icon .. " " .. sk.name .. " [" .. sk.cost .. "] " .. sk.desc .. "\n"
            end
            text = text .. "\n"
        end
    end

    text = text .. "转职后可随时再次切换职业。\n选择\"放弃职业\"可回归自由勇者状态。\n"

    local choices = {}
    -- 战士选项
    if heroClass ~= "warrior" then
        table.insert(choices, {
            text = "转职战士",
            action = function()
                if bsOk then
                    local result = BS.switchHeroClass("warrior")
                    S._tempMsg = result
                end
                return "转职结果"
            end,
        })
    end
    -- 法师选项
    if heroClass ~= "mage" then
        table.insert(choices, {
            text = "转职法师",
            action = function()
                if bsOk then
                    local result = BS.switchHeroClass("mage")
                    S._tempMsg = result
                end
                return "转职结果"
            end,
        })
    end
    -- 放弃职业
    if heroClass ~= "none" then
        table.insert(choices, {
            text = "放弃职业",
            action = function()
                if bsOk then
                    local result = BS.switchHeroClass("none")
                    S._tempMsg = result
                end
                return "转职结果"
            end,
        })
    end
    table.insert(choices, { text = "返回战斗面板", target = "战斗面板" })

    return { text = text, choices = choices }
end

---===================== 转职结果 =====================


handlers["转职结果"] = function(S)
    local result = S._tempMsg or "转职完成。"
    S._tempMsg = nil
    return {
        text = result,
        choices = {
            { text = "查看战斗面板", target = "战斗面板" },
            { text = "继续转职", target = "转职" },
        },
    }
end

---===================== 属性 =====================


end
