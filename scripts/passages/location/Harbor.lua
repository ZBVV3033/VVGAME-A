-- passages/location/Harbor.lua
-- Auto-split sub-module, returns installer function

return function(handlers, deps)

local GameState = deps.GameState
local TimeSystem = deps.TimeSystem
local NPCSystem = deps.NPCSystem
local WorkSystem = deps.WorkSystem
local HomeSystem = deps.HomeSystem
local MainQuest = deps.MainQuest
local CommonUtils = deps.CommonUtils
local PassageDeps = deps.PassageDeps
local addAffection = deps.addAffection
local addDateLog = deps.addDateLog
local doWorkWithEvent = deps.doWorkWithEvent
local isLeiDeHome = deps.isLeiDeHome

handlers["港口"] = function(S)
    local text = "港口\n\n"
        .. "从十字路口往北走，海风的气息越来越浓。码头边堆着大大小小的木箱，工人们喊着号子搬运货物。"
        .. "渔贩的摊位一字排开，海鱼在木板上闪着银光。\n\n"
        .. "远处，碧蓝的海面一望无际，几艘轮船正缓缓驶出港口，白帆鼓满了风。"

    -- 事件描述融入正文
    if (S.npcBlackbeard or 0) >= 15 then
        text = text .. "\n\n码头尽头，黑胡子正靠在系缆桩上抽烟斗，看见你来，他朝你点了点头。"
    end

    local choices = {}

    -- ══════ 地点导航（置顶） ══════
    table.insert(choices, { text = "🐟 逛逛鱼市（10分钟）", action = function()
        TimeSystem.addMinutes(10)
        local scenes = {
            "你穿过熙熙攘攘的人群，走进鱼市的核心区域。空气中弥漫着浓烈的海腥味和盐水的咸涩。"
            .. "鱼贩们扯着嗓子吆喝，将银光闪闪的鲜鱼高高举起——「新鲜的银鳕鱼！今早刚打的！」"
            .. "你在一个摊位前停下来，看着渔娘麻利地给一条大鱼剖肚去鳞，"
            .. "鱼鳞在阳光下像碎银子一样飞溅开来。你认识了好几种以前从没见过的鱼。",
            "一个壮实的渔夫站在鱼市中央，正得意洋洋地展示今天的收获——"
            .. "一条足有半人高的蓝鳍鱼，尾巴上还挂着海水。围观的人群啧啧称奇，"
            .. "几个商人已经开始出价竞购。「三十枚金币！」「三十五！」"
            .. "渔夫叉着腰哈哈大笑：「这条至少值五十！你们知道我花了多大劲才把它拽上来吗？」"
            .. "你看着这场热闹的竞价，觉得码头的生活真是生猛。",
            "鱼市的角落里有个不起眼的小摊，摊主是个弯腰驼背的老奶奶。"
            .. "她面前摆着一排排整整齐齐的鱼干，有的泛着金黄色，有的呈深褐色，全都散发着浓郁的咸鲜气味。"
            .. "「尝一块吧。」老奶奶笑眯眯地递过一小片。你咬了一口——"
            .. "外层咸香酥脆，里面的鱼肉还保留着微微的甜味。"
            .. "「好吃吧？这是我用老方子晒的，足足晒了七天呢。」",
            "你在一个卖贝壳的小摊前驻足。摊主是个黑瘦的少年，赤着脚，"
            .. "面前的木箱里铺满了各式各样的贝壳——扇贝、螺壳、海星，还有几颗磨得光溜溜的海玻璃。"
            .. "「这个好看吧？」少年举起一枚虹彩贝壳在阳光下转了转，"
            .. "贝壳内壁折射出珍珠般的光泽。你欣赏了一番，虽然没有买，但心情莫名变好了。",
            "今天的鱼市格外热闹，因为一艘远洋渔船刚刚靠岸。"
            .. "水手们搬下一箱箱从未见过的海产——带着长长触须的章鱼、壳上布满棘刺的海胆、"
            .. "通体透明的水母。围观的人群议论纷纷，有人好奇地伸手去碰，被水手笑着拦住。"
            .. "你看着这些来自深海的奇异生物，不禁对海洋的辽阔产生了莫名的向往。",
            "你沿着鱼市的窄巷慢慢走着，两旁摊位上的冰块正在融化，"
            .. "冰水混着鱼鳞和海藻在石板地上蜿蜒。一个胖胖的鱼贩正和主妇讨价还价，"
            .. "声音大得像在吵架，但两人最后都笑了起来。"
            .. "转角处，一只橘色的野猫蹲在鱼筐边，虎视眈眈地盯着里面的小鱼。"
            .. "你弯腰逗了逗它，它喵了一声，叼起一条漏网之鱼就跑了。",
        }
        GameState.showNotification(scenes[math.random(1, #scenes)])
        return "港口"
    end })
    table.insert(choices, { text = "🌊 眺望海边（15分钟 | 压力-5）", action = function()
        TimeSystem.addMinutes(15)
        GameState.modStat("stress", -5)
        local scenes = {
            "你走到码头最远端的一根系缆桩旁坐下，双腿悬在木栈道边缘。"
            .. "海风裹着咸湿的水汽拂过面颊，吹乱了你的头发。远处一艘三桅帆船正缓缓驶出港湾，"
            .. "白帆在阳光下鼓胀得像巨大的云朵。海鸥在桅杆顶上盘旋鸣叫，"
            .. "声音被风撕扯成断断续续的碎片。你什么都没想，只是看着，看着海浪一遍遍拍打着堤坝。\n(压力-5)",
            "碧蓝的海面波光粼粼，像是谁在水底铺满了碎钻石。"
            .. "几朵洁白的云倒映在水面上，随着波浪缓缓变形、散开、又重新聚拢。"
            .. "远处的天际线上隐约浮现出另一座岛屿的轮廓——灰蓝色的山影朦朦胧胧，"
            .. "像一幅淡彩水墨画。你深深地吸了一口海风，胸腔里仿佛被清洗了一遍，"
            .. "那些积压的烦闷随着呼气一点点散去。\n(压力-5)",
            "夕阳正在沉入海面，将整片天空和海水都染成了金红色。"
            .. "渔船陆续归港，桅杆上的灯笼一盏接一盏亮起来，在暮色中摇曳生辉。"
            .. "一个老水手坐在你旁边的码头上，嘴里叼着一截灭了的烟斗，"
            .. "粗糙的手指灵巧地穿梭在渔网的破洞之间。他吹着一首你从没听过的曲子，"
            .. "调子悠长而略带忧伤，像是在给大海唱一首晚安曲。\n(压力-5)",
            "今天的海面出奇地平静，像一面巨大的蓝色镜子。"
            .. "你站在栏杆边，看着自己模糊的倒影在水面上微微晃动。"
            .. "一群银色的小鱼在码头的阴影下穿梭，偶尔有一条大胆的跃出水面，"
            .. "溅起一朵小小的水花。远处的灯塔静静矗立着，塔身被夕照镀上了一层暖金色。"
            .. "你觉得时间在这里走得特别慢，慢到可以让人好好喘口气。\n(压力-5)",
            "海风忽然大了起来，你不得不抓紧帽子。码头上的旗帜猎猎作响，"
            .. "几个水手急忙加固缆绳。你靠在一根粗大的木桩上，看着远处的海面上翻起白色的浪花——"
            .. "一排接一排，像是无数白马奔腾而来。空气中充满了大海独有的力量感和野性。"
            .. "你深呼吸了好几次，感觉胸口那团说不清的烦闷被海风吹散了大半。\n(压力-5)",
            "你在码头的一张旧长椅上坐下，这里是你最喜欢的位置——"
            .. "刚好能看见港口的全景。左边是鱼市的喧嚣，右边是船坞的锤声叮当，"
            .. "正前方是无边无际的大海。一只白色的海鸟从你头顶飞过，投下一个转瞬即逝的影子。"
            .. "你闭上眼，听着海浪的声音，它有一种奇妙的节奏感，"
            .. "像是某个巨大的心脏在水底缓缓跳动。等你再睁开眼，心里已经平静了许多。\n(压力-5)",
        }
        GameState.showNotification(scenes[math.random(1, #scenes)])
        return "港口"
    end })
    table.insert(choices, { text = "🔙 返回十字路口", action = function() TimeSystem.addMinutes(5) return "十字路口" end })

    -- ══════ 工作（由场景自然引出） ══════
    if not S.unlockLaborer then
        table.insert(choices, { text = "💬 向工头咨询工作", action = function()
            S.unlockLaborer = true
            TimeSystem.addMinutes(5)
            return "港口"
        end })
    else
        table.insert(choices, { text = "🔨 当港口杂工（1小时 | 💰+）", action = function()
            return doWorkWithEvent("laborer")
        end })
        if isLeiDeHome() then
            table.insert(choices, { text = "🤝 和" .. (S.initialName or "莱德") .. "一起搬货（1小时 | 💰+）", action = function()
                return doWorkWithEvent("laborer", true)
            end })
        end
    end

    if (S.npcBlackbeard or 0) >= 15 then
        table.insert(choices, { text = "💬 走过去和黑胡子聊聊", action = function()
            TimeSystem.addMinutes(5)
            local aff = S.npcBlackbeard or 0
            S.npcBlackbeard = aff + 3
            if aff >= 40 then
                GameState.showNotification("黑胡子从兜里掏出一枚磨得发亮的铜币：「这是我第一次出海时的工钱。」他看了看你，又收了回去，「等你出海时再给你。」(好感+3)")
            elseif aff >= 25 then
                GameState.showNotification("黑胡子指着远处的船：「看见那艘三桅帆船了吗？我年轻时驾过比那大三倍的。」他嘿嘿一笑，「当然，那时头发还没白。」(好感+3)")
            else
                GameState.showNotification("黑胡子吐了口烟圈，眯着眼看海：「小鬼，海上的事你不懂。」(好感+3)")
            end
            return "港口"
        end })
    end

    return { text = text, choices = choices }
end

---===================== 打工事件 =====================


handlers["打工事件"] = function(S)
    local event = S._workEvent
    local baseMsg = S._workEventBase or ""
    local withLeiDe = S._workEventWithLeiDe or false
    local name = S.initialName or "莱德"

    if not event then
        return { text = baseMsg .. "\n\n没有什么特别的事发生。",
                 choices = { { text = "🔙 继续", target = "十字路口" } } }
    end

    -- 选择描述文本（莱德差分 or 普通）
    local desc = event.desc
    if withLeiDe and event.descLeiDe then
        desc = event.descLeiDe:gsub("{name}", name)
    end

    local text = baseMsg .. "\n\n" .. string.rep("─", 30)
          .. "\n\n✨ 发生了一件事：\n\n" .. desc

    -- 选择列表（莱德差分 or 普通）
    local eventChoices = event.choices
    if withLeiDe and event.choicesLeiDe then
        eventChoices = event.choicesLeiDe
    end

    local choices = {}
    for _, ch in ipairs(eventChoices) do
        local choiceText = ch.text:gsub("{name}", name)
        table.insert(choices, {
            text = choiceText,
            action = function()
                -- 将 result 中的 {name} 替换
                local applied = {}
                for k, v in pairs(ch) do applied[k] = v end
                if applied.result then
                    applied.result = applied.result:gsub("{name}", name)
                end
                local resultText = WorkSystem.applyEventReward(applied)
                S._workResultMsg = resultText
                S._workEvent = nil
                return "打工结果"
            end,
        })
    end

    return { text = text, choices = choices }
end

---===================== 打工结果 =====================


handlers["打工结果"] = function(S)
    local msg = S._workResultMsg or "工作完成了。"
    S._workResultMsg = nil

    -- 判断返回目标
    local job = S._workEventJob or "waiter"
    S._workEventJob = nil
    S._workEventWithLeiDe = nil
    local returnTarget = "商业区"
    if job == "laborer" then returnTarget = "港口" end

    return {
        text = msg,
        choices = { { text = "🔙 返回", target = returnTarget } },
    }
end

---===================== 花园小镇 =====================
--- Twine pid 24: 忠实原文


end
