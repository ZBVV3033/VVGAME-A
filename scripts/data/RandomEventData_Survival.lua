-- ============================================================================
-- RandomEventData_Survival.lua - 生存属性联动事件
-- 从 RandomEvents.lua 拆分：饥饿/疲劳/压力触发的特殊事件
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local CommonUtils = require("utils.CommonUtils")

local chance = CommonUtils.chance
local tryEvent = CommonUtils.tryEvent

local RandomEventData_Survival = {}

-- ==================== 生存属性联动事件 ====================
-- 当饱食度低/疲劳高/压力高时触发特殊事件

function RandomEventData_Survival.getSurvivalEvents(location)
    local S = GameState.state
    local text = ""
    local choices = {}

    -- 饥饿事件（饱食度 <= 25）
    if S.satiety <= 25 and chance(40) and tryEvent("hunger_" .. location) then
        if S.satiety <= 10 then
            text = text .. "\n\n你的肚子发出一声响亮的抗议。\n"
                .. "视线有些模糊，脚步也变得不太稳。\n"
                .. "再不吃点东西，恐怕要晕倒在路上了……"
            table.insert(choices, {
                text = "🍞 花5金币买个面包垫垫肚子",
                target = location,
                action = function()
                    if S.money >= 5 then
                        S.money = S.money - 5
                        GameState.modStat("satiety", 25)
                        GameState.showNotification("你买了一个面包狼吞虎咽地吃了。饱食度+25")
                    else
                        GameState.showNotification("口袋空空……你连面包都买不起。")
                    end
                end,
            })
            table.insert(choices, {
                text = "😤 忍一忍，强撑过去",
                target = location,
                action = function()
                    GameState.modStat("stress", 5)
                    GameState.showNotification("你强忍着饥饿继续走。压力+5")
                end,
            })
        else
            local hungerTexts = {
                "\n\n肚子隐隐作响。你上一顿是什么时候吃的来着？\n路过面包店的时候，刚出炉的面包香味让人口水直流。",
                "\n\n你路过一个小吃摊，热气腾腾的包子看起来格外诱人。\n摊主注意到你的眼神，笑着说：「来一个？便宜卖你。」",
                "\n\n你闻到了谁家炖肉的香味。\n胃像是被提醒了一样，发出了不争气的咕噜声。",
            }
            text = text .. hungerTexts[math.random(1, #hungerTexts)]
        end
    end

    -- 疲劳事件（疲劳 >= 70）
    if S.fatigue >= 70 and chance(35) and tryEvent("tired_" .. location) then
        if S.fatigue >= 90 then
            text = text .. "\n\n你的眼皮越来越沉。\n靠在路边的栏杆上，差点就这么睡着了。\n再这样下去真的会倒在路上……"
            table.insert(choices, {
                text = "💤 找个角落打个盹（30分钟）",
                target = location,
                action = function()
                    TimeSystem.addMinutes(30)
                    GameState.modStat("fatigue", -15)
                    GameState.showNotification("你在角落里打了个盹。疲劳-15，但时间过去了30分钟。")
                end,
            })
            table.insert(choices, {
                text = "☕ 去买杯浓茶提提神（3金币）",
                target = location,
                action = function()
                    if S.money >= 3 then
                        S.money = S.money - 3
                        GameState.modStat("fatigue", -10)
                        GameState.showNotification("一杯浓茶让你稍微清醒了一些。疲劳-10")
                    else
                        GameState.showNotification("连茶都买不起了……")
                    end
                end,
            })
        else
            local tiredTexts = {
                "\n\n你打了一个大大的哈欠。\n旁边的路人看了你一眼，也跟着打了个哈欠。",
                "\n\n脚步变得有些拖沓。\n你发现自己盯着同一个路牌看了好一会儿——发呆了。",
                "\n\n阳光暖洋洋的，让人昏昏欲睡。\n你需要提提精神才行。",
            }
            text = text .. tiredTexts[math.random(1, #tiredTexts)]
        end
    end

    -- 高压力事件（压力 >= 60）
    if S.stress >= 60 and chance(30) and tryEvent("stress_" .. location) then
        if S.stress >= 85 then
            text = text .. "\n\n一切都让你感到烦躁。\n路人的说话声、商贩的叫卖、甚至阳光都让你不舒服。\n你需要找个方式放松一下……"
            table.insert(choices, {
                text = "🌿 找一处安静的地方独处一会儿",
                target = location,
                action = function()
                    TimeSystem.addMinutes(15)
                    GameState.modStat("stress", -12)
                    GameState.showNotification("你独自安静地待了一会儿。思绪渐渐平复。压力-12")
                end,
            })
            table.insert(choices, {
                text = "🏃 跑一圈发泄一下",
                target = location,
                action = function()
                    TimeSystem.addMinutes(10)
                    GameState.modStat("stress", -8)
                    GameState.modStat("fatigue", 5)
                    GameState.showNotification("你绕着街区跑了一圈。出了一身汗，心情好多了。压力-8 疲劳+5")
                end,
            })
        else
            local stressTexts = {
                "\n\n你觉得有些烦闷。深深吸了一口气。\n城市的空气算不上清新，但总比闷在心里好。",
                "\n\n你在路边停了一下，揉了揉太阳穴。\n最近事情太多了，需要好好休息一下。",
            }
            text = text .. stressTexts[math.random(1, #stressTexts)]
        end
    end

    return text, choices
end

return RandomEventData_Survival
