-- ============================================================================
-- HomePassages_Events.lua - 家庭事件段落（从 HomeSystem.lua 提取）
-- 莱德互动 / 互动结果 / K互动 / 奥梅尔来访 / 来访结果 / 乌列尔信件 / 厨房 / 门口空地
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local CommonUtils = require("utils.CommonUtils")
local HomeEventData = require("data.HomeEventData")
local ET = require("utils.EventTemplates")

local handlers = {}

-- CommonUtils aliases
local addAffection = CommonUtils.addAffection
local addDateLog = CommonUtils.addDateLog
local getTimePeriod = CommonUtils.getTimePeriod
local chance = CommonUtils.chance
local leideName = CommonUtils.leideName

-- HomeEventData aliases
local isLeideHome = HomeEventData.isLeideHome
local isNight = HomeEventData.isNight

-- ==================== 莱德在家互动 ====================

handlers["家_莱德互动"] = function()
    local S = GameState.state

    -- 从事件池中选择合适的事件
    local validEvents = {}
    for _, ev in ipairs(HomeEventData.leideEvents) do
        if not ev.condition or ev.condition(S) then
            table.insert(validEvents, ev)
        end
    end

    if #validEvents == 0 then
        -- 没有特殊事件时的通用互动
        local name = leideName()
        local genericChats = {
            { text = name .. " 看着你，点了点头。「...怎么了？」", reply = "你们聊了一会儿。没什么特别的事，但感觉很好。" },
            { text = name .. " 正在擦拭自己的装备。「...坐。」他指了指旁边的椅子。", reply = "你们安静地坐了一会儿。不需要说话也很舒服。" },
            { text = name .. " 在翻一本旧书。看到你，他稍微挪了挪，让出一点位置。", reply = "你凑过去看。是一本冒险者手记。他偶尔指着某一行，给你讲里面的故事。" },
            { text = name .. " 靠在窗边，手指无意识地敲着窗框。看到你走过来，他停下了动作。", reply = "「...在想以前的事。」他说完顿了顿，又补了一句：「不是什么重要的事。」\n\n你没有追问。窗外的光落在他脸上，很安静。" },
            { text = "你进屋的时候，" .. name .. " 正盯着桌上一小截蜡烛发呆。烛光摇曳，映得他的表情忽明忽暗。", reply = "他回过神来，有些不好意思：「...在算蜡烛还能烧多久。」\n\n你觉得他在想的不只是蜡烛的事。" },
            { text = name .. " 正蹲在门口，手里拿着一块干面包，小心地撕成碎屑撒在地上。几只麻雀围着他跳来跳去。", reply = "你走近的时候，麻雀们扑棱棱飞走了。他站起来，拍了拍手上的面包屑。\n「...它们明天还会来。」他说这话的时候，嘴角微微上扬了一瞬。" },
            { text = name .. " 站在墙角，对着一面发黄的小镜子发愣。他看到你在看他，立刻转过身。", reply = "「...没什么。」他的声音比平时低了一些。\n\n你注意到镜子旁边贴着一张纸条，上面歪歪扭扭写着几个字。但他用手挡住了，不让你看。" },
            { text = "你回来的时候，" .. name .. " 已经把晚餐摆好了——虽然只有面包和腌菜。碗筷摆得整整齐齐。", reply = "他没说「你回来了」。只是默默把你的那份往前推了推。\n\n面包切得大小一样，你的那一份比他的厚一点点。" },
        }
        local chat = genericChats[math.random(#genericChats)]
        addAffection("initialName", 3)
        TimeSystem.addMinutes(15)
        GameState.modStat("stress", -3)

        return {
            text = chat.text .. "\n\n" .. chat.reply .. "\n\n(" .. name .. " 好感+3)",
            choices = { { text = "🔙 回客厅", target = "家" } },
        }
    end

    local event = validEvents[math.random(#validEvents)]
    local eventText = type(event.text) == "function" and event.text() or event.text

    local choices = {}
    for _, c in ipairs(event.choices) do
        local choiceText = type(c.text) == "function" and c.text() or c.text
        table.insert(choices, {
            text = choiceText,
            action = function()
                ET.applyHomeChoiceEffects(c, "initialName")
                local replyText = type(c.reply) == "function" and c.reply() or c.reply
                S._homeReplyText = replyText
                S._homeReplyAff = c.aff or 0
                return "家_互动结果"
            end,
        })
    end
    -- 关键词聊天（莱德）
    table.insert(choices, { text = "💬 聊聊见闻", action = function()
        S._keywordChatChar = "leiDe"
        S._keywordChatReturn = "家"
        return "keyword_chat_select"
    end })

    table.insert(choices, { text = "🔙 算了，回客厅", target = "家" })

    return { text = eventText, choices = choices }
end

-- ==================== 互动结果 ====================

handlers["家_互动结果"] = function()
    local S = GameState.state
    local text = S._homeReplyText or "..."
    local aff = S._homeReplyAff or 0
    S._homeReplyText = nil
    S._homeReplyAff = nil

    return {
        text = text .. "\n\n(" .. leideName() .. " 好感+" .. aff .. ")",
        choices = { { text = "🔙 回客厅", target = "家" } },
    }
end

-- ==================== K在家互动 ====================

handlers["家_K互动"] = function()
    local S = GameState.state
    local text = "K在客厅里转悠，精灵耳微微颤动，光环在烛光下若隐若现。"
    local choices = {}

    -- 从K事件池中选一个特殊事件
    local validEvents = {}
    for _, ev in ipairs(HomeEventData.kVisitEvents) do
        if not ev.condition or ev.condition(S) then
            table.insert(validEvents, ev)
        end
    end

    if #validEvents > 0 then
        local event = validEvents[math.random(#validEvents)]
        text = type(event.text) == "function" and event.text() or event.text

        for _, c in ipairs(event.choices) do
            table.insert(choices, {
                text = c.text,
                action = function()
                    ET.applyHomeChoiceEffects(c, "k")
                    local replyText = type(c.reply) == "function" and c.reply() or c.reply
                    GameState.showNotification("K 好感+" .. (c.aff or 0))
                    return "家"
                end,
            })
        end
    end

    -- 莱德和K在一起时的互动
    if isLeideHome() and not isNight() then
        table.insert(choices, {
            text = "🍵 三个人一起喝茶",
            action = function()
                addAffection("initialName", 3)
                addAffection("k", 3)
                TimeSystem.addMinutes(30)
                GameState.modStat("stress", -5)
                GameState.showNotification("三个人安静地喝了茶。(莱德好感+3, K好感+3)")
                return "家"
            end,
        })
    end

    -- 家具互动
    if S.furnitureCoffee then
        table.insert(choices, {
            text = "☕ 请K喝咖啡",
            action = function()
                addAffection("k", 2)
                TimeSystem.addMinutes(10)
                GameState.showNotification("K捧着咖啡杯，开心地喝了起来。(好感+2)")
                return "家"
            end,
        })
    end
    if S.furnitureBible then
        table.insert(choices, {
            text = "📖 给K看圣典",
            action = function()
                addAffection("k", 5)
                TimeSystem.addMinutes(10)
                GameState.showNotification("K认真地翻看着圣典，光环都亮了几分。(好感+5)")
                return "家"
            end,
        })
    end

    -- K送夜灯（高好感触发）
    if (S.kAffection or 0) >= 300 and (S.kLevel or 1) >= 3 and not S.kGiftLamp then
        table.insert(choices, {
            text = "🎁 K好像有话要说",
            action = function()
                S.kGiftLamp = true
                S.candles = (S.candles or 0) + 1
                addAffection("k", 10)
                addDateLog("K", "赠送礼物", "送了一盏仿制光环的小夜灯。")
                GameState.showNotification("K送给你一盏精灵光环造型的小夜灯！(蜡烛+1, 好感+10)")
                return "家"
            end,
        })
    end

    -- 关键词聊天（K）
    table.insert(choices, { text = "💬 聊聊见闻", action = function()
        S._keywordChatChar = "k"
        S._keywordChatReturn = "家"
        return "keyword_chat_select"
    end })

    -- 送K离开
    table.insert(choices, {
        text = "🌅 送K离开",
        action = function()
            S.kVisiting = false
            TimeSystem.addMinutes(5)
            GameState.showNotification("你送K到门口。她挥挥手：「下次再来玩！」")
            return "家"
        end,
    })

    table.insert(choices, { text = "🔙 回客厅", target = "家" })

    return { text = text, choices = choices }
end

-- ==================== 奥梅尔来访 ====================

handlers["家_奥梅尔来访"] = function()
    local S = GameState.state
    S.oamelVisitHandled = true

    -- 从事件池选一个
    local validEvents = {}
    for _, ev in ipairs(HomeEventData.oamelVisitEvents) do
        if not ev.condition or ev.condition(S) then
            table.insert(validEvents, ev)
        end
    end

    local event = validEvents[math.random(#validEvents)]
    local eventText = type(event.text) == "function" and event.text() or event.text

    local choices = {}
    for _, c in ipairs(event.choices) do
        table.insert(choices, {
            text = c.text,
            action = function()
                S.oamelAffection = (S.oamelAffection or 0) + (c.aff or 0)
                TimeSystem.addMinutes(c.time or 20)
                local replyText = type(c.reply) == "function" and c.reply() or c.reply
                GameState.showNotification("奥梅尔 好感+" .. (c.aff or 0))
                S._homeReplyText = replyText
                S._homeReplyAff = c.aff or 0
                S._homeReplyTarget = "奥梅尔"
                return "家_来访结果"
            end,
        })
    end

    return { text = eventText, choices = choices }
end

-- ==================== 来访互动结果 ====================

handlers["家_来访结果"] = function()
    local S = GameState.state
    local text = S._homeReplyText or "..."
    local aff = S._homeReplyAff or 0
    local target = S._homeReplyTarget or "???"
    S._homeReplyText = nil
    S._homeReplyAff = nil
    S._homeReplyTarget = nil

    return {
        text = text .. "\n\n(" .. target .. " 好感+" .. aff .. ")",
        choices = { { text = "🔙 回客厅", target = "家" } },
    }
end

-- ==================== 乌列尔信件 ====================

handlers["家_乌列尔信件"] = function()
    local S = GameState.state
    S.urielLetterHandled = true
    S.urielLetterPending = false

    -- 查找匹配的信件
    local letter = nil
    for _, l in ipairs(HomeEventData.urielLetters) do
        if l.condition(S) then
            letter = l
            break
        end
    end

    if not letter then
        return {
            text = "你仔细看了看，只是一张传单。",
            choices = { { text = "🔙 回去", target = "家" } },
        }
    end

    local letterText = type(letter.text) == "function" and letter.text() or letter.text
    if letter.effect then letter.effect(S) end
    S.urielLetterCount = (S.urielLetterCount or 0) + 1

    -- 概率看到莱昂哈特的身影（诺兰/乌列尔的父亲, 20%, 第2封信之后）
    if (S.urielLetterCount or 0) >= 2 and math.random(1, 100) <= 20 then
        local leonScenes = {
            "\n\n你弯腰捡信的时候，余光瞥见巷子口有一个金发的身影一闪而过。"
                .. "等你直起身仔细看——已经没有人了。"
                .. "但空气里残留着一丝淡淡的松木香气，和信纸上的味道不太一样。",
            "\n\n你打开门的时候，恰好看见远处一个穿灰色外套的中年人转过街角。"
                .. "那个背影……你好像在广场上见过。"
                .. "金发，步伐稳健，是莱昂哈特·瓦勒姆？"
                .. "\n\n他为什么会出现在这附近？",
            "\n\n信封上除了那个熟悉的蜡封，你注意到角落多了一个极小的铅笔记号——"
                .. "像是有人在检查信封是否完好时留下的。"
                .. "那种记号的画法很精确，不像是随手涂的，"
                .. "倒像是经过军事训练的人才有的习惯。",
        }
        letterText = letterText .. leonScenes[math.random(1, #leonScenes)]
    end

    local choices = {}
    if (S.urielLetterCount or 0) <= 1 then
        table.insert(choices, {
            text = "小心地把信收好",
            action = function()
                addDateLog("乌列尔", "收到信件", "收到了一封没有署名的信。")
                return "家"
            end,
        })
    else
        table.insert(choices, {
            text = "把信和之前的放在一起",
            action = function()
                addDateLog("乌列尔", "收到信件", "又收到哥哥的信了。")
                return "家"
            end,
        })
        if (S.urielLetterCount or 0) >= 3 then
            table.insert(choices, {
                text = "试着写一封回信",
                action = function()
                    S.urielAffection = (S.urielAffection or 0) + 10
                    TimeSystem.addMinutes(20)
                    addDateLog("乌列尔", "写回信", "给哥哥写了一封回信。")
                    GameState.showNotification("你写了一封简短的回信，交给管家转交。(乌列尔好感+10)")
                    return "家"
                end,
            })
        end
    end
    table.insert(choices, { text = "🔙 回客厅", target = "家" })

    return { text = letterText, choices = choices }
end

-- ==================== 厨房 ====================

handlers["家_厨房"] = function()
    local S = GameState.state
    local name = leideName()
    local text = "厨房\n\n"
        .. "简陋的厨房，一张木板搭的灶台，几口铁锅，墙上挂着一排调料瓶。"

    if isLeideHome() then
        local kitchenDescs = {
            name .. " 靠在门框上，好奇地看着你进厨房。",
            name .. " 正在角落里削一个苹果。",
            name .. " 在检查食材储备，看起来若有所思。",
        }
        text = text .. "\n\n" .. kitchenDescs[math.random(#kitchenDescs)]
    end

    -- 食材描述
    local ingredientList = {}
    local ingredients = S.ingredients or {}
    for k, v in pairs(ingredients) do
        if v and v > 0 then
            table.insert(ingredientList, k .. "x" .. v)
        end
    end
    if #ingredientList > 0 then
        text = text .. "\n\n食材储备：" .. table.concat(ingredientList, "、")
    else
        text = text .. "\n\n食材储备：空空如也。"
    end

    local choices = {}

    -- 简单烹饪
    table.insert(choices, {
        text = "🍳 做一顿简单的饭（30分钟 | 饱食+25）",
        action = function()
            TimeSystem.addMinutes(30)
            GameState.modStat("satiety", 25)
            GameState.modStat("fatigue", 5)
            if isLeideHome() then
                addAffection("initialName", 2)
                GameState.modStat("satiety", 5)
                GameState.showNotification(name .. " 帮你打了下手，两个人一起吃了顿简单但温暖的饭。(饱食+30, 好感+2)")
            else
                GameState.showNotification("你做了顿简单的饭菜，味道还凑合。(饱食+25)")
            end
            return "家_厨房"
        end,
    })

    -- 烧水泡茶
    table.insert(choices, {
        text = "🍵 烧水泡茶（10分钟 | 压力-3）",
        action = function()
            TimeSystem.addMinutes(10)
            GameState.modStat("stress", -3)
            GameState.modStat("satiety", 5)
            if isLeideHome() then
                addAffection("initialName", 1)
                GameState.showNotification("你泡了两杯茶，" .. name .. " 接过一杯，点了点头。(压力-3, 好感+1)")
            else
                GameState.showNotification("热茶暖了暖胃。(压力-3, 饱食+5)")
            end
            return "家_厨房"
        end,
    })

    -- 整理厨房
    table.insert(choices, {
        text = "🧹 打扫厨房（15分钟 | 清洁+5）",
        action = function()
            TimeSystem.addMinutes(15)
            GameState.modStat("cleanliness", 5)
            GameState.modStat("stress", -2)
            if isLeideHome() then
                GameState.showNotification(name .. " 递来一块抹布：「……我擦桌子。」\n两个人一起把厨房收拾干净了。(清洁+5)")
            else
                GameState.showNotification("你把厨房里里外外擦了一遍。(清洁+5)")
            end
            return "家_厨房"
        end,
    })

    -- 用食材做菜（有食材时）
    if #ingredientList > 0 then
        table.insert(choices, {
            text = "👨‍🍳 用现有食材做一顿好的（45分钟 | 饱食+40）",
            action = function()
                -- 消耗一种食材
                local usedKey = nil
                for k, v in pairs(S.ingredients) do
                    if v and v > 0 then
                        usedKey = k
                        break
                    end
                end
                if usedKey then
                    S.ingredients[usedKey] = S.ingredients[usedKey] - 1
                    if S.ingredients[usedKey] <= 0 then S.ingredients[usedKey] = nil end
                end
                TimeSystem.addMinutes(45)
                GameState.modStat("satiety", 40)
                GameState.modStat("stress", -5)
                if isLeideHome() then
                    addAffection("initialName", 3)
                    GameState.showNotification("你和" .. name .. " 一起做了一顿丰盛的饭。他负责切菜，你负责翻炒。配合默契。\n(饱食+40, 压力-5, 好感+3)")
                else
                    GameState.showNotification("你用" .. (usedKey or "食材") .. "做了一顿像样的饭。(饱食+40, 压力-5)")
                end
                return "家_厨房"
            end,
        })
    end

    -- 学了烹饪后可按食谱做菜（CookingSystem 食谱系统）
    if (S.cookingLevel or 0) >= 1 then
        table.insert(choices, {
            text = "📖 按食谱做菜（烹饪Lv." .. S.cookingLevel .. "）",
            target = "家_食谱烹饪",
        })
    end

    table.insert(choices, { text = "🔙 回走廊", target = "家" })

    return { text = text, choices = choices }
end

-- ==================== 门口空地 ====================

handlers["家_门口空地"] = function()
    local S = GameState.state
    local name = leideName()
    local h = S.hour or 8
    local text = "门口空地\n\n"

    if h >= 6 and h < 10 then
        text = text .. "清晨的空气带着露水的气息。门前的空地上，几棵杂草在微风中摇曳。远处传来隐约的鸟鸣。"
    elseif h >= 10 and h < 17 then
        text = text .. "阳光照在门前的空地上，泥土被晒得微微发烫。几只不知名的小虫在草丛间跳来跳去。"
    elseif h >= 17 and h < 20 then
        text = text .. "傍晚的天空染成了橘红色。门前的空地上拉出长长的影子，空气开始变得凉爽。"
    else
        text = text .. "夜色笼罩着门前的空地，月光在地上投下斑驳的影子。四周很安静，只有远处偶尔传来夜虫的鸣叫。"
    end

    if isLeideHome() then
        local yardDescs = {
            name .. " 站在一旁，望着远处的天际线出神。",
            name .. " 蹲在地上，不知道在研究什么。看到你出来，站起身拍了拍土。",
            name .. " 靠着墙，双臂抱胸，享受着难得的安宁。",
        }
        text = text .. "\n\n" .. yardDescs[math.random(#yardDescs)]
    end

    local choices = {}

    -- 锻炼
    table.insert(choices, {
        text = "💪 做些简单锻炼",
        action = function()
            TimeSystem.addMinutes(30)
            GameState.modStat("fatigue", 10)
            GameState.modStat("stress", -8)
            GameState.modStat("TL", 1)
            if isLeideHome() then
                addAffection("initialName", 2)
                GameState.showNotification(name .. " 看你在锻炼，也跟着做了起来。他的动作比你标准多了。\n(体力+1, 压力-8, 好感+2)")
            else
                GameState.showNotification("你做了些简单的拉伸和俯卧撑，出了一身汗。(体力+1, 压力-8)")
            end
            return "家_门口空地"
        end,
    })

    -- 发呆/晒太阳
    if h >= 8 and h < 17 then
        table.insert(choices, {
            text = "☀️ 晒晒太阳",
            action = function()
                TimeSystem.addMinutes(20)
                GameState.modStat("stress", -5)
                GameState.modStat("fatigue", -3)
                if isLeideHome() then
                    GameState.showNotification("你和" .. name .. " 并排坐在门口，谁也没说话。阳光很暖。(压力-5, 疲劳-3)")
                else
                    GameState.showNotification("你坐在门口晒了一会儿太阳，脑子放空了片刻。(压力-5, 疲劳-3)")
                end
                return "家_门口空地"
            end,
        })
    else
        table.insert(choices, {
            text = "🌙 坐在门口发呆",
            action = function()
                TimeSystem.addMinutes(15)
                GameState.modStat("stress", -4)
                if isLeideHome() then
                    GameState.showNotification("夜风拂过。" .. name .. " 不知什么时候也出来了，默默在你身旁坐下。(压力-4)")
                else
                    GameState.showNotification("你在门口坐了一会儿，听着夜风。(压力-4)")
                end
                return "家_门口空地"
            end,
        })
    end

    -- K来访时的户外互动
    if S.kVisiting and not isNight() then
        table.insert(choices, {
            text = "✨ 和K一起看云",
            action = function()
                addAffection("k", 5)
                TimeSystem.addMinutes(20)
                GameState.modStat("stress", -8)
                local scenes = {
                    "K躺在草地上，指着天空：「那朵像不像一只猫？」\n你歪头看——确实有点像。她开心地晃着精灵耳。\n「在天界从来不用抬头看云。因为就在云里面。」\n她顿了顿：「但从下面往上看，更好看。」",
                    "K把光环当作参照物，在空中比划着星座的位置：「等天黑了我指给你看！」\n你们就这样躺在草地上，看着白云慢慢飘过。\n「你知道吗，天使不需要睡觉。」她忽然说，「但我现在特别想打盹。」",
                    "K摘了一根草叶叼在嘴里，模仿人类的样子。然后被草叶呛到，咳嗽了半天。\n你笑到肚子疼。她一边咳一边笑：「人类为什么喜欢干这种事啊！」",
                }
                GameState.showNotification(scenes[math.random(#scenes)] .. "\n(K好感+5, 压力-8)")
                return "家_门口空地"
            end,
        })
    end

    -- 莱德在家时的训练互动（门口空地特有）
    if isLeideHome() and not isNight() and (S.initialNameLevel or 1) >= 2 then
        table.insert(choices, {
            text = "🗡️ 看" .. name .. "练剑",
            action = function()
                addAffection("initialName", 3)
                TimeSystem.addMinutes(20)
                GameState.modStat("stress", -5)
                local scenes = {
                    name .. " 的剑在空气中划出银色的弧线。动作流畅而沉默，像是在和看不见的对手对话。\n你坐在门口的台阶上看着，不自觉地看入了迷。",
                    name .. " 收剑的时候额头有一层薄汗。他走过来，在你旁边坐下，接过你递去的水杯。\n「看着无聊吧。」\n「不无聊。」\n他没接话，但嘴角动了一下。",
                    "一只蝴蝶飞过来落在" .. name .. " 的剑尖上。他的动作猛地停住，屏住呼吸看着蝴蝶。\n过了几秒，蝴蝶飞走了。他回头看你——你们都笑了。",
                }
                GameState.showNotification(scenes[math.random(#scenes)] .. "\n(好感+3, 压力-5)")
                return "家_门口空地"
            end,
        })
    end

    -- 种菜（如果有种植系统）
    if S.farmPlots then
        table.insert(choices, {
            text = "🌱 查看菜园",
            target = "家_菜园",
        })
    end

    table.insert(choices, { text = "🔙 回走廊", target = "家" })

    return { text = text, choices = choices }
end

return handlers
