-- ============================================================================
-- HomePassages_Rooms.lua - 家庭房间段落（从 HomeSystem.lua 提取）
-- 家（主入口） / 客厅 / 卧室 / 浴室 / 读书
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local MainQuest = require("systems.MainQuest")
local CommonUtils = require("utils.CommonUtils")
local HomeEventData = require("data.HomeEventData")

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
local getLeideHomeDesc = HomeEventData.getLeideHomeDesc

-- ==================== 家（主入口） ====================

handlers["家"] = function()
    local S = GameState.state
    local lines = {}
    local period = getTimePeriod()

    -- 基础环境描述
    if period == "morning" then
        table.insert(lines, "家\n\n清晨的阳光透过窗户洒进来，屋子里有种慵懒的暖意。")
    elseif period == "afternoon" then
        table.insert(lines, "家\n\n午后的光线明亮而安静。屋子里弥漫着淡淡的木头味道。")
    elseif period == "evening" then
        local candleCount = S.candles or 0
        if candleCount >= 3 then
            table.insert(lines, "家\n\n" .. candleCount .. "根蜡烛点亮了屋子，烛光摇曳，影子在墙上轻轻晃动。")
        else
            table.insert(lines, "家\n\n傍晚了，屋子里渐渐暗下来。你点了一根蜡烛，橘色的光在墙上摇晃。")
        end
    else
        table.insert(lines, "家\n\n夜深了。窗外的月光洒在地板上，屋子里很安静。")
    end

    -- 早晨课程提醒
    if (period == "morning" or (S.hour >= 6 and S.hour < 10)) and S.uniEnrolled and #(S.uniMajors or {}) > 0 then
        local uniOk3, UniSys3 = pcall(require, "systems.UniversitySystem")
        if uniOk3 then
            local dayNames3 = { "周一", "周二", "周三", "周四", "周五", "周六", "周日" }
            local wakeDay = ((S.day - 1) % 7) + 1
            local todayClasses = {}
            for _, majorId in ipairs(S.uniMajors) do
                local schedule = UniSys3.SCHEDULE[majorId]
                local majorInfo = UniSys3.getMajorInfo and UniSys3.getMajorInfo(majorId)
                if schedule and majorInfo then
                    for _, cls in ipairs(schedule) do
                        if cls.day == wakeDay then
                            table.insert(todayClasses, {
                                hour = cls.hour, minute = cls.minute,
                                icon = majorInfo.icon, clsName = cls.name, location = cls.location,
                            })
                        end
                    end
                end
            end
            if #todayClasses > 0 then
                table.sort(todayClasses, function(a, b)
                    return a.hour * 60 + a.minute < b.hour * 60 + b.minute
                end)
                local reminderLine = "\n📚 今天（" .. dayNames3[wakeDay] .. "）有课：\n"
                for _, c in ipairs(todayClasses) do
                    reminderLine = reminderLine .. "  " .. string.format("%02d:%02d", c.hour, c.minute) .. " " .. c.icon .. " " .. c.clsName .. " @" .. c.location .. "\n"
                end
                table.insert(lines, reminderLine)
            end
        end
    end

    -- 莱德在家的描述
    if isLeideHome() then
        table.insert(lines, "\n" .. getLeideHomeDesc())
    end

    -- K来访的描述
    if S.kVisiting then
        table.insert(lines, "\nK在客厅里转悠，精灵耳微微颤动，光环在烛光下若隐若现。")
    end

    -- 奥梅尔来访
    if S.oamelVisitingToday and not S.oamelVisitHandled then
        table.insert(lines, "\n门外传来敲门声。")
    end

    -- 乌列尔信件
    if S.urielLetterPending and not S.urielLetterHandled then
        table.insert(lines, "\n门口好像有一封信。")
    end

    local choices = {}

    -- ══ 主线任务触发（最高优先级） ══
    local mqTrigger = MainQuest.getCh2TriggerChoice("家")
        or MainQuest.getCh3TriggerChoice("家")
    if mqTrigger then
        table.insert(choices, mqTrigger)
    end

    -- ===== 紧急事件（门口事件，由文字引出） =====
    if S.oamelVisitingToday and not S.oamelVisitHandled then
        table.insert(choices, {
            text = "🚪 去开门",
            target = "家_奥梅尔来访",
        })
    end
    if S.urielLetterPending and not S.urielLetterHandled then
        table.insert(choices, {
            text = "✉️ 去看看那封信",
            target = "家_乌列尔信件",
        })
    end

    -- ===== 房间导航（分组折叠） =====
    table.insert(choices, {
        group = "房间",
        icon = "🏠",
        expanded = true,
        children = {
            { text = "🛋️ 客厅", target = "家_客厅" },
            { text = "🛏️ 卧室", target = "家_卧室" },
            { text = "🚿 浴室", target = "家_浴室" },
            { text = "🍳 厨房", target = "家_厨房" },
            { text = "🌱 门口空地", target = "家_门口空地" },
        },
    })

    -- ===== 同居人互动（分组折叠） =====
    if isLeideHome() then
        local name = leideName()
        local leideChildren = {}

        -- 基础互动
        table.insert(leideChildren, {
            text = "💬 和" .. name .. "聊聊",
            target = "家_莱德互动",
        })

        -- 日常互动（根据好感等级解锁）
        if (S.initialNameLevel or 1) >= 2 then
            table.insert(leideChildren, {
                text = "🍵 一起喝茶（15分钟 | 压力-5）",
                action = function()
                    addAffection("initialName", 5)
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -5)
                    GameState.showNotification("和" .. name .. "安静地喝了一会儿茶。(好感+5)")
                    return "家"
                end,
            })
        end
        if (S.initialNameLevel or 1) >= 3 then
            table.insert(leideChildren, {
                text = "📖 一起看书（30分钟 | 压力-8）",
                action = function()
                    addAffection("initialName", 6)
                    TimeSystem.addMinutes(30)
                    GameState.modStat("stress", -8)
                    GameState.showNotification("你们靠在一起看书，肩膀碰着肩膀。(好感+6)")
                    return "家"
                end,
            })
        end
        -- 一起做家务（等级>=2）
        if (S.initialNameLevel or 1) >= 2 and not isNight() then
            table.insert(leideChildren, {
                text = "🧹 一起打扫（20分钟 | 清洁+10）",
                action = function()
                    addAffection("initialName", 4)
                    TimeSystem.addMinutes(20)
                    GameState.modStat("cleanliness", 10)
                    GameState.modStat("stress", -3)
                    local scenes = {
                        "你擦桌子，" .. name .. " 扫地。他扫到你脚边的时候会绕过去。",
                        name .. " 擦窗户的时候够不到最上面——不对，他比你高。是你够不到，他帮你擦的。",
                        "你们一边打扫一边聊天。" .. name .. " 说小时候在公爵府，从来不用自己收拾。「...现在觉得也不坏。」",
                    }
                    GameState.showNotification(scenes[math.random(#scenes)] .. "\n(好感+4, 清洁+10)")
                    return "家"
                end,
            })
        end
        -- 一起做饭（等级>=3，傍晚）
        if (S.initialNameLevel or 1) >= 3 and getTimePeriod() == "evening" then
            table.insert(leideChildren, {
                text = "🍲 一起做晚饭（30分钟 | 饱食+35）",
                action = function()
                    addAffection("initialName", 6)
                    TimeSystem.addMinutes(30)
                    GameState.modStat("satiety", 35)
                    GameState.modStat("stress", -5)
                    local scenes = {
                        "你切菜，" .. name .. " 负责炒。他的刀工意外地好——大概跟用剑有关。\n两个人面对面吃饭的时候，他偶尔抬头看你一眼，又迅速低下去。",
                        name .. " 试着调味的时候放多了盐。你尝了一口，没说什么，默默加了水。\n他注意到了：「……下次我少放。」\n你们把一整锅都吃完了。",
                        "做饭的时候你们的手碰到了几次。第三次的时候，" .. name .. " 干脆不动了，等你先拿完调料。\n他的耳尖红了一点点。晚饭很好吃。",
                    }
                    GameState.showNotification(scenes[math.random(#scenes)] .. "\n(好感+6, 饱食+35)")
                    return "家"
                end,
            })
        end
        -- 一起散步（等级>=2，非深夜）
        if (S.initialNameLevel or 1) >= 2 and not isNight() then
            table.insert(leideChildren, {
                text = "🚶 门口散步（15分钟 | 压力-6）",
                action = function()
                    addAffection("initialName", 4)
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -6)
                    local curPeriod = getTimePeriod()
                    local scenes
                    if curPeriod == "morning" then
                        scenes = "清晨的空气很清新。" .. name .. " 走在你旁边，步伐比平时慢了些，像是在配合你的节奏。"
                    elseif curPeriod == "afternoon" then
                        scenes = "午后的阳光有些晃眼。" .. name .. " 走到你的阳光侧，替你挡住了一些。他自己大概没意识到。"
                    else
                        scenes = "傍晚的风吹过来，带着远处食物的香味。" .. name .. " 的影子和你的影子在地上连在一起。"
                    end
                    GameState.showNotification(scenes .. "\n(好感+4, 压力-6)")
                    return "家"
                end,
            })
        end
        -- 深夜互动（同床时）
        if isNight() and S.initialNameSleepTogether then
            table.insert(leideChildren, {
                text = "🌙 和" .. name .. "说悄悄话",
                action = function()
                    addAffection("initialName", 5)
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -8)
                    local talks = {
                        "黑暗中，" .. name .. " 的声音很低很轻。他说起小时候偷偷溜出公爵府去集市的事。\n「那时候觉得外面的世界很大。现在觉得……这间屋子就够了。」",
                        "你问他今天的梦。他沉默了一会儿：「梦到了森林。还有你。」\n「我在梦里做什么？」\n「……在笑。」他翻了个身，声音闷闷的：「别问了。睡吧。」",
                        "窗外有猫叫。" .. name .. " 忽然说：「你冷不冷？」\n你还没回答，他就把被子往你那边拽了拽。\n被子底下你们的手指碰在一起，谁都没有移开。",
                        name .. " 大概以为你睡着了，小声说了句什么。你没听清，但感觉是你的名字。\n你装作翻身，把额头靠近他的肩膀。他的呼吸停了一秒，然后继续了。",
                    }
                    GameState.showNotification(talks[math.random(#talks)] .. "\n(好感+5, 压力-8)")
                    return "家"
                end,
            })
        end
        -- 关键词聊天
        table.insert(leideChildren, {
            text = "💬 聊聊见闻",
            action = function()
                S._keywordChatChar = "leiDe"
                S._keywordChatReturn = "家"
                return "keyword_chat_select"
            end,
        })

        table.insert(choices, {
            group = name .. "·同居",
            icon = "🏡",
            expanded = false,
            children = leideChildren,
        })
    end

    -- ===== K来访互动（分组折叠） =====
    if S.kVisiting then
        local kChildren = {}
        table.insert(kChildren, {
            text = "✨ 和K互动",
            target = "家_K互动",
        })
        -- 简单互动直接在走廊做
        table.insert(kChildren, {
            text = "🍵 请K喝茶（10分钟）",
            action = function()
                addAffection("k", 3)
                TimeSystem.addMinutes(10)
                GameState.modStat("stress", -3)
                GameState.showNotification("K捧着茶杯，精灵耳舒展开来：「好香！」(好感+3)")
                return "家"
            end,
        })
        if not isNight() then
            table.insert(kChildren, {
                text = "🎵 听K哼歌（15分钟 | 压力-10）",
                action = function()
                    addAffection("k", 5)
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -10)
                    local scenes = {
                        "K坐在窗台上哼着天界的旋律。光环随着音符一明一暗，像是在跳舞。你靠在墙上听着，不知不觉就放松了。",
                        "K轻声唱着一首你没听过的歌。歌词是天使语，你听不懂，但旋律让你想起温暖的壁炉和下雪的傍晚。",
                        "K在哼一首欢快的小曲，精灵耳随着节拍轻轻晃动。她看到你在听，笑着唱得更大声了一点。",
                    }
                    GameState.showNotification(scenes[math.random(#scenes)] .. "\n(好感+5, 压力-10)")
                    return "家"
                end,
            })
        end
        -- 一起做事
        if (S.kAffection or 0) >= 150 then
            table.insert(kChildren, {
                text = "🧹 和K一起整理屋子（20分钟）",
                action = function()
                    addAffection("k", 4)
                    TimeSystem.addMinutes(20)
                    GameState.modStat("cleanliness", 8)
                    local scenes = {
                        "K认真地擦着桌子，光环不小心碰到花瓶，发出叮的一声。她吓了一跳，连忙扶住。「没坏没坏！」",
                        "K帮你叠被子的时候被子缠住了精灵耳。你帮她解开的时候，她的脸红得像苹果。",
                        "K扫地的时候哼着歌，把灰尘扫成了一个笑脸的形状。「看！像不像你？」她得意地指着地上。",
                    }
                    GameState.showNotification(scenes[math.random(#scenes)] .. "\n(好感+4, 清洁+8)")
                    return "家"
                end,
            })
        end
        table.insert(kChildren, {
            text = "💬 聊聊见闻",
            action = function()
                S._keywordChatChar = "k"
                S._keywordChatReturn = "家"
                return "keyword_chat_select"
            end,
        })
        table.insert(kChildren, {
            text = "🌅 送K离开",
            action = function()
                S.kVisiting = false
                TimeSystem.addMinutes(5)
                GameState.showNotification("你送K到门口。她挥挥手：「下次再来玩！」")
                return "家"
            end,
        })

        table.insert(choices, {
            group = "K·来访",
            icon = "✨",
            expanded = false,
            children = kChildren,
        })
    end

    -- ===== 出门 =====
    table.insert(choices, {
        text = "🚶 出门（十字路口）",
        action = function()
            TimeSystem.addMinutes(3)
            return "十字路口"
        end,
    })

    return { text = table.concat(lines, "\n"), choices = choices }
end

-- ==================== 客厅 ====================

handlers["家_客厅"] = function()
    local S = GameState.state
    local text = "客厅\n\n"
        .. "不大的客厅，一张旧木桌，两把椅子，角落堆着些杂物。"

    -- 家具展示
    local furnitureList = {}
    if S.furnitureCoffee then table.insert(furnitureList, "☕咖啡机嗡嗡作响") end
    if S.furnitureBible then table.insert(furnitureList, "📖圣典静静摊开在桌上") end
    if S.furnitureDummy then table.insert(furnitureList, "🥊训练铁人立在角落") end
    if S.furnitureSeagull then table.insert(furnitureList, "🕊️小海鸥装饰挂在窗边") end
    if #furnitureList > 0 then
        text = text .. "\n" .. table.concat(furnitureList, "。") .. "。"
    end

    -- 来访者描述
    if S.kVisiting then
        text = text .. "\n\nK正在客厅里好奇地东张西望，精灵耳微微颤动。"
    end

    local choices = {}

    -- 看书/休息
    if not isNight() then
        table.insert(choices, {
            text = "📚 看书",
            target = "家_读书",
        })
        table.insert(choices, {
            text = "☀️ 在沙发上休息一会儿（1小时 | 疲劳-15）",
            action = function()
                TimeSystem.addMinutes(60)
                GameState.modStat("fatigue", -15)
                GameState.modStat("stress", -8)
                GameState.showNotification("休息了一会儿。(疲劳-15, 压力-8)")
                return "家_客厅"
            end,
        })
    end

    -- 莱德互动（白天在客厅）
    if isLeideHome() and not isNight() then
        text = text .. "\n\n" .. leideName() .. " 坐在桌边，神情放松。"
        local leideItems = {
            {
                text = "💬 和" .. leideName() .. "聊聊",
                target = "家_莱德互动",
            },
        }
        if (S.initialNameLevel or 1) >= 2 then
            table.insert(leideItems, {
                text = "🍵 一起喝茶（15分钟 | 压力-5）",
                action = function()
                    addAffection("initialName", 5)
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -5)
                    GameState.showNotification("和" .. leideName() .. "安静地喝了一会儿茶。(好感+5)")
                    return "家_客厅"
                end,
            })
        end
        if (S.initialNameLevel or 1) >= 3 then
            table.insert(leideItems, {
                text = "📖 一起看书（30分钟 | 压力-8）",
                action = function()
                    addAffection("initialName", 6)
                    TimeSystem.addMinutes(30)
                    GameState.modStat("stress", -8)
                    GameState.showNotification("你们靠在一起看书，肩膀碰着肩膀。(好感+6)")
                    return "家_客厅"
                end,
            })
        end
        -- 下棋（等级>=3）
        if (S.initialNameLevel or 1) >= 3 then
            table.insert(leideItems, {
                text = "♟️ 下棋（30分钟 | 压力-6）",
                action = function()
                    addAffection("initialName", 5)
                    TimeSystem.addMinutes(30)
                    GameState.modStat("stress", -6)
                    GameState.modStat("ZL", 1)
                    local scenes = {
                        leideName() .. " 下棋很稳，从不冒进。你赢了一局的时候，他看了你很久：「……再来。」",
                        "棋局陷入僵持。" .. leideName() .. " 托着下巴思考的样子很认真，烛光映在他的眼睛里。",
                        "你连输三局。" .. leideName() .. " 难得露出一点得意的表情：「……你在走神。」\n他说得对。你在看他。",
                    }
                    GameState.showNotification(scenes[math.random(#scenes)] .. "\n(好感+5, 智力+1, 压力-6)")
                    return "家_客厅"
                end,
            })
        end
        -- 帮他处理伤口（等级>=2，低概率触发）
        if (S.initialNameLevel or 1) >= 2 and chance(25) and not S._todayLeideWound then
            table.insert(leideItems, {
                text = "💊 他手上好像有伤",
                action = function()
                    S._todayLeideWound = true
                    addAffection("initialName", 8)
                    TimeSystem.addMinutes(10)
                    local name = leideName()
                    GameState.showNotification("你注意到" .. name .. "手背上有道新伤。他说是练剑时划的。\n你找来干净的布帮他包扎。他一开始想缩手，但最后还是没动。\n「……下次小心点。」你说。\n「嗯。」他的声音比平时轻了很多。\n(好感+8)")
                    return "家_客厅"
                end,
            })
        end
        table.insert(choices, {
            group = leideName(),
            icon = "🗡️",
            expanded = true,
            children = leideItems,
        })
    end

    -- K来访互动
    if S.kVisiting then
        table.insert(choices, {
            text = "✨ 和K互动",
            target = "家_K互动",
        })
    end

    table.insert(choices, { text = "🔙 回走廊", target = "家" })

    return { text = text, choices = choices }
end

-- ==================== 卧室 ====================

handlers["家_卧室"] = function()
    local S = GameState.state
    local name = leideName()
    local text = "卧室\n\n"

    -- 基础描述
    if S.initialNameSleepTogether then
        text = text .. "房间里摆着一张刚好够两个人的木板床。" .. name .. " 的衣物叠在床头的柜子上，和你的放在一起。"
    else
        text = text .. "一张简陋的木板床，被子叠得整整齐齐。窗户边放着一盏小油灯。"
    end

    if S.kGiftLamp then
        text = text .. "\nK送的小夜灯摆在床头，散发着柔和的暖光。"
    end

    -- 莱德在家时的描述（未同睡）
    if isLeideHome() and not S.initialNameSleepTogether then
        if isNight() then
            text = text .. "\n\n" .. name .. " 睡在客厅的临时床铺上，隐约传来平稳的呼吸声。"
        else
            text = text .. "\n\n" .. name .. " 的行李整齐地放在客厅角落。"
        end
    end

    -- 莱德同睡时的描述
    if isLeideHome() and S.initialNameSleepTogether then
        if isNight() then
            text = text .. "\n\n" .. name .. " 已经躺在床的一侧，背对着你。月光从窗户洒进来，映在他安静的侧脸上。"
        else
            local morningDescs = {
                name .. " 正坐在床边整理衣物，看到你回来，微微点头。",
                "床上的被子皱巴巴的——" .. name .. " 大概刚起来不久。",
                name .. " 的枕头上还留着浅浅的凹痕。他已经起来了。",
            }
            text = text .. "\n\n" .. morningDescs[math.random(#morningDescs)]
        end
    end

    -- 衣柜/梳妆台描述
    text = text .. "\n\n角落有一个旧衣柜，门上的铜把手已经发黑。旁边还有一面小镜子，边缘有些磨损。"

    local choices = {}

    -- 睡觉选项
    -- 辅助：执行睡眠效果
    local function doSleep(hours, isUntilMorning)
        local sleepMinutes
        if isUntilMorning then
            -- 睡到明天早上7点
            if S.hour >= 7 then
                sleepMinutes = (24 - S.hour + 7) * 60 - S.minute
            else
                sleepMinutes = (7 - S.hour) * 60 - S.minute
            end
        else
            sleepMinutes = hours * 60
        end
        TimeSystem.addMinutes(sleepMinutes)
        -- 疲劳恢复按睡眠时长比例计算（8小时=-60, 每小时约-7.5）
        local fatigueRecover = math.floor(hours * 7.5)
        if isUntilMorning then
            local actualHours = sleepMinutes / 60
            fatigueRecover = math.floor(actualHours * 7.5)
        end
        fatigueRecover = math.min(fatigueRecover, 70) -- 最多恢复70
        GameState.modStat("fatigue", -(fatigueRecover))
        local stressRecover = math.floor(fatigueRecover * 0.2)
        GameState.modStat("stress", -(stressRecover))
        S.outfit = "pajamas"

        local actualH = isUntilMorning and math.floor(sleepMinutes / 60) or hours
        if isLeideHome() and S.initialNameSleepTogether then
            GameState.modStat("stress", -5)
            addAffection("initialName", 2)
            GameState.showNotification("你和" .. name .. "一起入睡了。身旁传来的温热让你睡得格外安稳。\n(睡了" .. actualH .. "小时, 疲劳-" .. fatigueRecover .. ", 压力-" .. (stressRecover + 5) .. ", 好感+2)")
        else
            GameState.showNotification("你睡了" .. actualH .. "小时，精神好多了。\n(疲劳-" .. fatigueRecover .. ", 压力-" .. stressRecover .. ")")
        end

        -- 起床时课程提醒
        local uniOk2, UniSys2 = pcall(require, "systems.UniversitySystem")
        if uniOk2 and S.uniEnrolled and #(S.uniMajors or {}) > 0 then
            local dayNames2 = { "周一", "周二", "周三", "周四", "周五", "周六", "周日" }
            local wakeDay = ((S.day - 1) % 7) + 1
            local todayClasses = {}
            for _, majorId in ipairs(S.uniMajors) do
                local schedule = UniSys2.SCHEDULE[majorId]
                local majorInfo = UniSys2.getMajorInfo and UniSys2.getMajorInfo(majorId)
                if schedule and majorInfo then
                    for _, cls in ipairs(schedule) do
                        if cls.day == wakeDay and (cls.hour > S.hour or (cls.hour == S.hour and cls.minute > S.minute)) then
                            table.insert(todayClasses, {
                                hour = cls.hour, minute = cls.minute,
                                icon = majorInfo.icon, clsName = cls.name,
                            })
                        end
                    end
                end
            end
            if #todayClasses > 0 then
                table.sort(todayClasses, function(a, b)
                    return a.hour * 60 + a.minute < b.hour * 60 + b.minute
                end)
                local reminder = "📚 今天（" .. dayNames2[wakeDay] .. "）的课程：\n"
                for _, c in ipairs(todayClasses) do
                    reminder = reminder .. "  " .. string.format("%02d:%02d", c.hour, c.minute) .. " " .. c.icon .. " " .. c.clsName .. "\n"
                end
                GameState.showNotification(reminder)
            end
        end

        return "家"
    end

    if isNight() then
        -- 一键睡到明天早上7点
        local sleepLabel = isLeideHome() and S.initialNameSleepTogether
            and "🛌 睡到明天早上（7:00）" or "🛌 睡到明天早上（7:00）"
        table.insert(choices, {
            text = sleepLabel,
            action = function() return doSleep(0, true) end,
        })

        -- 自选睡眠时长
        for _, h in ipairs({2, 4, 6, 8}) do
            -- 计算预计起床时间
            local wakeH = (S.hour + h) % 24
            local wakeStr = string.format("%02d:00", wakeH)
            table.insert(choices, {
                text = "💤 睡" .. h .. "小时（" .. wakeStr .. "起）",
                action = function() return doSleep(h, false) end,
            })
        end
    end

    -- 换衣服：便装 + 已拥有的制服
    if S.outfit ~= "casual" then
        table.insert(choices, {
            text = "👕 换上便装",
            action = function()
                S.outfit = "casual"
                TimeSystem.addMinutes(2)
                if isLeideHome() and S.initialNameSleepTogether then
                    GameState.showNotification(name .. " 瞥了你一眼，默默转过身去。你换上了干净的便装。")
                else
                    GameState.showNotification("你换上了干净的便装。")
                end
                return "家_卧室"
            end,
        })
    end
    -- 列出已拥有的制服（排除当前穿着的）
    local wsOk, WS = pcall(require, "systems.WorkSystem")
    if wsOk and WS.getOwnedUniformList then
        local owned = WS.getOwnedUniformList()
        for _, u in ipairs(owned) do
            if u.id ~= S.outfit then
                table.insert(choices, {
                    text = "👔 换上" .. u.name,
                    action = function()
                        S.outfit = u.id
                        TimeSystem.addMinutes(2)
                        GameState.showNotification("你换上了「" .. u.name .. "」。")
                        return "家_卧室"
                    end,
                })
            end
        end
    end

    -- 看书（卧室也能看）
    if not isNight() then
        table.insert(choices, {
            text = "📚 看书",
            target = "家_读书",
        })
    end

    -- 整理房间
    table.insert(choices, {
        text = "🧹 整理房间",
        action = function()
            TimeSystem.addMinutes(20)
            GameState.modStat("stress", -3)
            GameState.modStat("cleanliness", 5)
            if isLeideHome() then
                addAffection("initialName", 1)
                GameState.showNotification(name .. " 看你在整理，也默默地帮忙叠了被子。(压力-3, 好感+1)")
            else
                GameState.showNotification("你把房间收拾了一遍，心情好了些。(压力-3)")
            end
            return "家_卧室"
        end,
    })

    -- 照镜子 / 改发型
    table.insert(choices, {
        text = "🪞 照照镜子",
        target = "改变发型",
    })

    -- 小睡（白天）
    if not isNight() and (S.fatigue or 0) >= 30 then
        table.insert(choices, {
            text = "💤 小睡一会儿",
            action = function()
                TimeSystem.addMinutes(60)
                GameState.modStat("fatigue", -20)
                GameState.modStat("stress", -5)
                if isLeideHome() then
                    GameState.showNotification("你迷迷糊糊地睡了一会儿。醒来时，" .. name .. " 帮你盖了条毯子。(疲劳-20, 压力-5)")
                else
                    GameState.showNotification("你在床上小睡了一会儿，头没那么沉了。(疲劳-20, 压力-5)")
                end
                return "家_卧室"
            end,
        })
    end

    -- 莱德深夜互动
    if isLeideHome() and isNight() and (S.initialNameLevel or 1) >= 2 then
        if S.initialNameSleepTogether then
            table.insert(choices, {
                text = "🌙 和" .. name .. "说说话",
                action = function()
                    addAffection("initialName", 4)
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -5)
                    local talks = {
                        "黑暗中，你们小声聊着。" .. name .. " 说起了一些过去的事——那些他很少对别人提起的。",
                        "「睡不着？」" .. name .. " 翻过身来看你。你们就这样有一搭没一搭地说着话，直到困意袭来。",
                        "你们并排躺着，" .. name .. " 忽然轻声说了句什么。你没听清，但感觉很温暖。",
                    }
                    GameState.showNotification(talks[math.random(#talks)] .. "\n(好感+4, 压力-5)")
                    return "家_卧室"
                end,
            })
        else
            table.insert(choices, {
                text = "🌙 去客厅看看" .. name,
                target = "家_莱德互动",
            })
        end
    end

    -- 邀请莱德同睡（好感>=3且尚未同睡）
    if isLeideHome() and not S.initialNameSleepTogether and (S.initialNameLevel or 1) >= 3 then
        table.insert(choices, {
            text = "💬 「要不…搬过来睡？」",
            action = function()
                S.initialNameSleepTogether = true
                addAffection("initialName", 10)
                TimeSystem.addMinutes(5)
                GameState.showNotification(name .. " 愣了一下，耳根微微泛红。「……好。」\n(" .. name .. " 好感+10，以后会和你同睡了)")
                return "家_卧室"
            end,
        })
    end

    table.insert(choices, { text = "🔙 回走廊", target = "家" })

    return { text = text, choices = choices }
end

-- ==================== 浴室 ====================

handlers["家_浴室"] = function()
    local S = GameState.state
    local clean = S.cleanliness or 90
    local text = "浴室\n\n"
        .. "狭小的浴室，墙角有个木桶，旁边挂着一块毛巾。"

    if clean <= 30 then
        text = text .. "\n你闻了闻自己，确实该洗洗了。"
    elseif clean <= 60 then
        text = text .. "\n身上有些汗味，洗一洗会舒服很多。"
    else
        text = text .. "\n你还挺干净的。"
    end

    local choices = {}

    -- 简单洗漱（+20清洁，10分钟）
    table.insert(choices, {
        text = "🪥 简单洗漱（10分钟 | 清洁+20）",
        action = function()
            GameState.modStat("cleanliness", 20)
            GameState.modStat("stress", -2)
            TimeSystem.addMinutes(10)
            GameState.showNotification("你洗了把脸，漱了口，清爽了些。(清洁+20)")
            return "家_浴室"
        end,
    })

    -- 洗澡（清洁拉满，30分钟）
    table.insert(choices, {
        text = "🛁 洗澡（30分钟 | 清洁↑↑）",
        action = function()
            S.cleanliness = 100
            GameState.modStat("stress", -8)
            GameState.modStat("fatigue", -5)
            TimeSystem.addMinutes(30)
            S.outfit = "casual"
            GameState.showNotification("你舒舒服服地泡了个澡，焕然一新。(清洁=100, 压力-8)")
            return "家_浴室"
        end,
    })

    table.insert(choices, { text = "🔙 回走廊", target = "家" })

    return { text = text, choices = choices }
end

-- ==================== 家_读书 ====================

handlers["家_读书"] = function()
    local S = GameState.state
    local wsOk, WS = pcall(require, "systems.WorkSystem")
    local text = "📚 书架\n\n"
    local hasAnyBook = false
    local choices = {}

    if wsOk and WS.bookOrder then
        for _, bookId in ipairs(WS.bookOrder) do
            local info = WS.bookInfo[bookId]
            if info and S[info.hasVar] then
                hasAnyBook = true
                local count = S[info.readCountVar] or 0
                local progress = math.min(count, 4)
                local done = progress >= 4
                local label = (done and "✅ " or "📖 ") .. info.fullName
                    .. "  (" .. progress .. "/4)"
                table.insert(choices, {
                    text = label,
                    action = function()
                        local result = WS.readBook(bookId)
                        GameState.modStat("stress", -3)
                        GameState.modStat("fatigue", 2)
                        GameState.showNotification(result)
                        return "家_读书"
                    end,
                })
            end
        end
    end

    -- 调酒笔记（特殊书籍）
    if S.hasBartenderNote then
        hasAnyBook = true
        local count = S.bartenderNoteReadCount or 0
        local done = count >= 4
        local label = (done and "✅ " or "🍸 ") .. "K的调酒笔记"
            .. "  (" .. math.min(count, 4) .. "/4)"
        table.insert(choices, {
            text = label,
            action = function()
                local result = WS.readBartenderNote()
                GameState.modStat("stress", -3)
                GameState.showNotification(result)
                return "家_读书"
            end,
        })
    end

    if not hasAnyBook then
        text = text .. "你的书架上还没有书。\n去白鸦书屋逛逛吧，那里有不少好书。"
    else
        text = text .. "你的书架上摆着几本书。选一本看看吧。\n（每次阅读30分钟，+20知识经验，压力-3）"
    end

    table.insert(choices, { text = "🔙 返回", action = function()
        return "家_客厅"
    end })

    return { text = text, choices = choices }
end

return handlers
