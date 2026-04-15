-- ============================================================================
-- RandomEventData_StatCheck.lua - 属性检定随机事件
-- 从 RandomEvents.lua 拆分：各区域的属性检定触发事件
-- 包含：小偷、砍价、风暴、迷路孩子、流浪猫、交易、赌博、卖花老人、
--       码头求职、蘑菇、占卜师、醉汉、罗伊稀有货、流浪琴师、猫咪骚乱、
--       瓶中信、迷路画家、马车事故、蒙面舞者、天降横财/横祸
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local CommonUtils = require("utils.CommonUtils")

local getTimePeriod = CommonUtils.getTimePeriod
local chance = CommonUtils.chance
local statCheck = CommonUtils.statCheck
local tryEvent = CommonUtils.tryEvent

local RandomEventData_StatCheck = {}

-- ==================== 属性检定事件 ====================
-- DOL核心：事件结果取决于玩家属性

function RandomEventData_StatCheck.getStatCheckEvents(location)
    local S = GameState.state
    local period = getTimePeriod()
    local text = ""
    local choices = {}

    -- ============ 十字路口：小偷事件（技巧检定）============
    if location == "十字路口" and chance(15) and tryEvent("pickpocket_cross") then
        text = text .. "\n\n你忽然感觉有只手碰了一下你的口袋！\n一个灰衣少年正想从你身边溜走。"
        table.insert(choices, {
            text = "🖐️ 抓住他！（技巧检定）",
            target = "随机_抓小偷",
        })
        table.insert(choices, {
            text = "👀 装作没发现，暗中观察",
            target = "随机_跟踪小偷",
        })
        table.insert(choices, {
            text = "🤷 算了，检查一下东西丢没丢",
            target = location,
            action = function()
                if S.money > 10 and chance(50) then
                    local lost = math.random(3, 8)
                    S.money = S.money - lost
                    GameState.showNotification("你摸了摸口袋……少了" .. lost .. "金币。")
                else
                    GameState.showNotification("还好，东西都在。")
                end
            end,
        })
    end

    -- ============ 商业区：讨价还价（魅力检定）============
    if location == "商业区" and period == "afternoon" and chance(18) and tryEvent("bargain_market") then
        text = text .. "\n\n一个摊主正在收摊，你注意到他的货品里有一件做工精致的皮带扣。\n「最后一件，30金币！」他喊道。"
        table.insert(choices, {
            text = "💬 砍价试试（魅力检定）",
            target = "随机_砍价",
        })
        table.insert(choices, {
            text = "💰 原价买下",
            target = location,
            action = function()
                if S.money >= 30 then
                    S.money = S.money - 30
                    S.JQ = S.JQ + 1
                    GameState.showNotification("你买下了皮带扣。虽然贵了点，但做工确实不错。技巧+1")
                else
                    GameState.showNotification("你摸了摸口袋……钱不够。")
                end
            end,
        })
        table.insert(choices, {
            text = "🚶 不感兴趣",
            target = location,
        })
    end

    -- ============ 港口：暴风雨前兆（灵感检定）============
    if location == "港口" and period == "afternoon" and chance(12) and tryEvent("storm_sign") then
        text = text .. "\n\n天空的云层变得异常厚重，海面上泛起不安的波浪。\n码头上的渔民们在紧急收拾渔具。"
        table.insert(choices, {
            text = "🌊 观察天象判断风暴走向（灵感检定）",
            target = "随机_预测风暴",
        })
        table.insert(choices, {
            text = "🤝 帮渔民们收拾（力量检定）",
            target = "随机_帮助渔民",
        })
        table.insert(choices, {
            text = "🏃 赶紧离开港口",
            target = location,
            action = function()
                GameState.showNotification("你明智地离开了。后来听说港口被大浪淹了一小段。")
            end,
        })
    end

    -- ============ 花园小镇：迷路的孩子（多分支）============
    if location == "花园小镇" and period == "morning" and chance(15) and tryEvent("lost_child") then
        text = text .. "\n\n一个小女孩蹲在路边哭泣，手里抱着一只布偶兔子。\n她说她和妈妈走散了，找不到回家的路。"
        table.insert(choices, {
            text = "🫂 安慰她，帮她找妈妈",
            target = "随机_帮迷路孩子",
        })
        table.insert(choices, {
            text = "🏪 带她去莉莉安的花店等（需认识莉莉安）",
            target = "随机_花店等妈妈",
        })
        table.insert(choices, {
            text = "🤔 告诉她去教堂找修女",
            target = location,
            action = function()
                GameState.showNotification("你指了指教堂的方向。小女孩抹了抹眼泪，跑过去了。")
                S.LG = S.LG + 0 -- 没有奖励，因为没有亲自帮忙
            end,
        })
    end

    -- ============ 主城区：流浪猫求助（温情事件）============
    if location == "主城区" and chance(12) and tryEvent("stray_cat_help") then
        text = text .. "\n\n一只瘦弱的流浪猫蜷缩在巷口。\n它用湿漉漉的眼睛看着你，发出微弱的叫声。\n看起来又冷又饿。"
        table.insert(choices, {
            text = "🐟 花3金币买条小鱼喂它",
            target = location,
            action = function()
                if S.money >= 3 then
                    S.money = S.money - 3
                    GameState.modStat("stress", -5)
                    GameState.showNotification("小猫大口吃着鱼，满足地蹭了蹭你的手。\n你的心情变好了。压力-5")
                else
                    GameState.showNotification("你想喂它，但口袋里一分钱都没有……")
                end
            end,
        })
        table.insert(choices, {
            text = "🧥 把它暖和一下再放走",
            target = location,
            action = function()
                GameState.modStat("stress", -3)
                GameState.showNotification("你抱起小猫暖了一会儿。它在你怀里打起了呼噜。压力-3")
            end,
        })
        table.insert(choices, {
            text = "😔 无能为力，离开",
            target = location,
            action = function()
                GameState.modStat("stress", 2)
                GameState.showNotification("你走了几步又回头看了看。小猫还蜷在那里。")
            end,
        })
    end

    -- ============ 花街：深夜可疑交易（夜晚限定）============
    if location == "花街" and period == "night" and chance(15) and tryEvent("shady_deal") then
        text = text .. "\n\n你经过一条暗巷时，隐约听到低声交谈。\n两个人影正在交换什么东西。\n其中一个人转过头来——你看到了一张带伤疤的脸。"
        table.insert(choices, {
            text = "🕵️ 靠近偷听（技巧检定）",
            target = "随机_偷听交易",
        })
        table.insert(choices, {
            text = "🚶 假装没看见，快步走开",
            target = location,
            action = function()
                GameState.showNotification("你加快脚步离开了。有些事还是别掺和为好。")
            end,
        })
        table.insert(choices, {
            text = "😤 大声咳嗽打断他们（勇气检定）",
            target = "随机_打断交易",
        })
    end

    -- ============ 商业区：赌博摊位（DOL经典）============
    if location == "商业区" and period == "evening" and chance(15) and tryEvent("gamble_stall") then
        text = text .. "\n\n街角有人在路边摆了三个碗。\n「来来来，猜猜球在哪个碗下面！押对了翻倍！」\n围观的人不少，有人赢了正兴高采烈。"
        table.insert(choices, {
            text = "🎲 押10金币试试运气",
            target = location,
            action = function()
                if S.money < 10 then
                    GameState.showNotification("你摸了摸口袋，钱不够……")
                    return
                end
                S.money = S.money - 10
                if statCheck("JQ", 30, 8) then
                    S.money = S.money + 20
                    GameState.showNotification("你一眼就看穿了他的手法！赢了10金币！")
                else
                    GameState.showNotification("你猜错了。那个人得意地翻开碗——球根本不在你猜的那个下面。亏了10金币。")
                end
            end,
        })
        table.insert(choices, {
            text = "🔍 先观察一会儿他的手法（灵感检定）",
            target = location,
            action = function()
                if statCheck("LG", 25, 8) then
                    GameState.showNotification("你看出来了——他用了障眼法，球其实一直在袖子里。\n你冲围观的人使了个眼色，大家都散了。")
                    S.LG = S.LG + 1
                    GameState.modStat("stress", -3)
                else
                    GameState.showNotification("你看了半天，愣是没看出什么门道。")
                end
            end,
        })
        table.insert(choices, {
            text = "🚶 不参与，走开",
            target = location,
        })
    end

    -- ============ 十字路口：卖花老人（温情）============
    if location == "十字路口" and period == "morning" and chance(12) and tryEvent("flower_elder") then
        text = text .. "\n\n一位白发苍苍的老人坐在路边卖花。\n他的花篮里只剩最后几枝野菊花了。\n老人的手在微微发抖，似乎很冷。"
        table.insert(choices, {
            text = "💐 买一枝花（2金币）",
            target = location,
            action = function()
                if S.money >= 2 then
                    S.money = S.money - 2
                    GameState.modStat("stress", -5)
                    GameState.showNotification("老人颤巍巍地递给你一枝菊花，说了声「谢谢孩子」。\n花虽然普通，但心里暖暖的。压力-5")
                else
                    GameState.showNotification("你摸了摸口袋……连2金币都没有。")
                end
            end,
        })
        table.insert(choices, {
            text = "🧣 把围巾借给他暖暖",
            target = location,
            action = function()
                GameState.modStat("stress", -8)
                S.ML = S.ML + 1
                GameState.showNotification("老人把围巾围上，眼角泛起泪光。\n「好孩子……像我年轻时的孙女。」\n你的心被触动了。压力-8 魅力+1")
            end,
        })
        table.insert(choices, {
            text = "🚶 匆匆走过",
            target = location,
        })
    end

    -- ============ 港口：求职信息（连锁事件）============
    if location == "港口" and period == "morning" and S.money <= 30 and chance(20) and tryEvent("dock_job_offer") then
        text = text .. "\n\n码头告示板上贴着一张新的招工启事：\n「急需搬运工！日薪25金币。力气大者优先。」\n旁边有个壮汉正在那里登记。"
        table.insert(choices, {
            text = "💪 报名试试（力量检定）",
            target = "随机_码头搬运",
        })
        table.insert(choices, {
            text = "📋 看看还有没有别的工作",
            target = location,
            action = function()
                if S.JQ >= 3 then
                    GameState.showNotification("你注意到角落有一张小纸条：「需要会修补渔网的人。日薪15金币。」\n也许可以试试。")
                else
                    GameState.showNotification("其他招工启事要么需要经验，要么薪水太低。")
                end
            end,
        })
        table.insert(choices, {
            text = "🚶 不感兴趣",
            target = location,
        })
    end

    -- ============ 花园小镇：神秘蘑菇（灵感事件）============
    if location == "花园小镇" and period == "afternoon" and chance(10) and tryEvent("mystery_mushroom") then
        text = text .. "\n\n你在花园角落发现了一丛颜色鲜艳的蘑菇。\n紫色的伞盖上点缀着金色的斑点，看起来非常不普通。"
        table.insert(choices, {
            text = "🔬 仔细观察它们（灵感检定）",
            target = "随机_鉴定蘑菇",
        })
        table.insert(choices, {
            text = "🍄 摘几朵带走",
            target = location,
            action = function()
                if statCheck("LG", 20, 10) then
                    local ing = S.ingredients or {}
                    ing["神秘蘑菇"] = (ing["神秘蘑菇"] or 0) + 1
                    S.ingredients = ing
                    GameState.showNotification("你凭直觉判断这些蘑菇没有毒。摘了几朵放进背包。\n获得了「神秘蘑菇」x1")
                else
                    GameState.modStat("satiety", -10)
                    GameState.showNotification("你摘了几朵，闻了闻……突然一阵恶心。\n还是别乱摘了。饱食度-10")
                end
            end,
        })
        table.insert(choices, {
            text = "🚫 不碰，谁知道有没有毒",
            target = location,
            action = function()
                GameState.showNotification("你明智地绕开了它们。安全第一。")
            end,
        })
    end

    -- ============ 主城区：占卜师（DOL经典）============
    if location == "主城区" and period == "evening" and chance(12) and tryEvent("fortune_teller") then
        text = text .. "\n\n教堂广场边上，一个蒙面女人摆了一张小桌子。\n桌上铺着星图，旁边放着一副磨损的塔罗牌。\n「年轻人，想知道你的命运吗？只要5金币。」"
        table.insert(choices, {
            text = "🔮 算一卦（5金币）",
            target = location,
            action = function()
                if S.money < 5 then
                    GameState.showNotification("你囊中羞涩……")
                    return
                end
                S.money = S.money - 5
                local fortunes = {
                    { text = "「塔牌逆位……近期要小心意外之财，可能是陷阱。」", stat = "LG", delta = 1 },
                    { text = "「星星正位。前方有贵人相助。保持善良，好运自来。」", stat = "ML", delta = 1 },
                    { text = "「力量逆位。你最近是否过于勉强自己？\n有时候认输也是一种力量。」", stress = -8 },
                    { text = "「命运之轮。一切都在变化中。\n你现在经历的困难，终将成为你最珍贵的经验。」", stat = "NL", delta = 1 },
                    { text = "「愚者正位——呵，这是最好的牌。\n意味着一切重新开始。无畏地前行吧。」", stress = -5, fatigue = -5 },
                }
                local f = fortunes[math.random(1, #fortunes)]
                if f.stat then
                    GameState.modStat(f.stat, f.delta)
                end
                if f.stress then
                    GameState.modStat("stress", f.stress)
                end
                if f.fatigue then
                    GameState.modStat("fatigue", f.fatigue)
                end
                GameState.showNotification(f.text)
            end,
        })
        table.insert(choices, {
            text = "🙅 不信这个",
            target = location,
        })
    end

    -- ============ 花街：醉汉纠缠（夜晚限定，属性检定）============
    if location == "花街" and period == "night" and chance(20) and tryEvent("drunk_trouble") then
        text = text .. "\n\n一个醉醺醺的大汉挡住了你的去路。\n「嗝——你、你长得挺面生的……\n请我喝一杯呗？」\n他的口气里全是酒味。"
        table.insert(choices, {
            text = "💪 推开他（力量检定）",
            target = location,
            action = function()
                if statCheck("LL", 30, 8) then
                    GameState.showNotification("你轻轻一推，醉汉踉跄几步坐到了地上。\n他含糊地骂了几句，就在原地睡着了。")
                else
                    GameState.modStat("money", -5)
                    GameState.showNotification("他比看起来壮……你没推动，被他缠住了。\n等脱身的时候发现口袋里少了5金币。")
                end
            end,
        })
        table.insert(choices, {
            text = "😊 用话术哄走他（魅力检定）",
            target = location,
            action = function()
                if statCheck("ML", 25, 8) then
                    GameState.showNotification("「那边有人免费请客哦！」你指向酒馆方向。\n醉汉眼睛一亮，歪歪扭扭地走了。")
                    S.ML = S.ML + 1
                else
                    GameState.showNotification("醉汉不为所动。「别骗我……嗝。」\n你只好绕了一大圈才甩掉他。")
                    TimeSystem.addMinutes(15)
                end
            end,
        })
        table.insert(choices, {
            text = "🏃 转身就跑",
            target = location,
            action = function()
                TimeSystem.addMinutes(5)
                GameState.showNotification("三十六计走为上！你飞快地跑开了。")
            end,
        })
    end

    -- ============ 商业区：旅行商人（好感度门槛解锁）============
    if location == "商业区" and period == "afternoon" and S.npcMerchantRoy >= 8
        and chance(15) and tryEvent("roy_rare_goods") then
        text = text .. "\n\n罗伊今天换了个摆摊地点——在商业区主街上。\n他冲你招手：「嘿！有好东西给你看！」\n他神神秘秘地从怀里掏出一个小盒子。"
        table.insert(choices, {
            text = "🎁 看看是什么",
            target = "随机_罗伊稀有货",
        })
        table.insert(choices, {
            text = "🙄 又是你的骗人把戏？",
            target = location,
            action = function()
                GameState.showNotification("「这次是真的！」罗伊一脸委屈。\n你笑着走开了。")
            end,
        })
    end

    -- ============ 新增：各区域补充事件 ============

    -- 十字路口：流浪琴师（傍晚，魅力检定）
    if location == "十字路口" and period == "evening" and chance(12) and tryEvent("street_musician") then
        text = text .. "\n\n傍晚的十字路口笼罩在一层暖橘色的余晖中，人流渐渐稀疏。"
            .. "就在你准备转弯的时候，一阵断断续续的琴声飘进了耳朵。\n\n"
            .. "街角的石阶上坐着一位衣衫褴褛的琴师，头发花白凌乱，下巴上有一道很深的旧疤。"
            .. "他怀中的小提琴少了一根弦，琴身上布满了裂痕和磨损的痕迹——"
            .. "但他拉琴的姿势却异常端正，仿佛站在某个金碧辉煌的音乐厅里。\n\n"
            .. "旋律从残缺的弦上流淌出来，时断时续，像一封没有写完的信。"
            .. "路过的行人偶尔投来一瞥，随即加快脚步离去。"
            .. "只有一只瘦削的灰猫蹲在他脚边，竖着耳朵，静静地听。"
        table.insert(choices, {
            text = "🎵 驻足聆听，投下几枚铜币",
            target = location,
            action = function()
                GameState.modStat("money", -3)
                GameState.modStat("stress", -8)
                if (S.ML or 0) >= 8 then
                    GameState.showNotification("你在他面前的石阶上坐了下来，双手环膝，安静地听着。\n\n"
                        .. "琴师似乎注意到了你，手指微微颤了一下，随即稳住了弓弦。"
                        .. "他开始拉一首完整的曲子——旋律从低沉的呜咽逐渐攀升，"
                        .. "像是穿过了漫长的雨夜，最终在黎明前绽放出一丝微弱却固执的光芒。\n\n"
                        .. "曲终。余韵在暮色中回荡了很久。\n\n"
                        .. "琴师缓缓抬起头，浑浊的眼睛里泛着水光。"
                        .. "「很久没有人……愿意听完了。」他的嗓音沙哑得像砂纸。\n\n"
                        .. "他从大衣内侧摸出一枚银色的纽扣——上面刻着一个精致的音符图案，"
                        .. "在夕阳下闪着柔和的光。「带着它吧，年轻人。」他说，「好运应该属于懂得倾听的人。」\n\n"
                        .. "你接过纽扣，金属触感冰凉。你想问他一些什么——他的名字，"
                        .. "他的过去——但他已经低下头，重新拉起了琴。\n\n"
                        .. "灰猫蹭了蹭你的脚踝，像是替主人道别。\n"
                        .. "金币-3 压力-8 获得「琴师的纽扣」")
                    S.musicianButton = true
                else
                    GameState.showNotification("你在旁边站了一会儿，把几枚铜币轻轻放在他面前的旧布上。\n\n"
                        .. "琴师并没有停下来道谢，只是微微偏了偏头，像是一个无声的致意。"
                        .. "残缺的旋律继续在暮色里流淌，断裂的地方像极了一声叹息。\n\n"
                        .. "你站了一会儿，直到路灯亮起来，才转身离去。"
                        .. "琴声在身后越来越轻，但那种说不出的哀伤一直跟着你，"
                        .. "像衣服上沾了一缕隐约的花香，很久都散不掉。\n"
                        .. "金币-3 压力-8")
                end
            end,
        })
        table.insert(choices, {
            text = "🚶 低头走过",
            target = location,
            action = function()
                GameState.showNotification("你把双手插进口袋，低着头加快了脚步。\n\n"
                    .. "琴声在身后一点一点地变弱，像退潮的海水慢慢离开沙滩。"
                    .. "走出很远之后你回头看了一眼——琴师还坐在那里，灰猫还蹲在他脚边。"
                    .. "暮色正一寸一寸地把他们吞没。\n\n"
                    .. "你转过头继续走。生活已经够沉重了，你没有余力再去承接别人的悲伤。")
            end,
        })
    end

    -- 商业区：猫咪骚乱（上午，体力检定）
    if location == "商业区" and period == "morning" and chance(12) and tryEvent("cat_chaos") then
        text = text .. "\n\n上午的商业区正是最热闹的时候，各家摊贩扯着嗓子吆喝，"
            .. "空气里弥漫着香料和鲜鱼的味道。\n\n"
            .. "就在你经过鱼摊的时候，一道橘黄色的影子以迅雷不及掩耳之势从摊板上一跃而过——"
            .. "一只肥得像南瓜的橘猫叼着一条足有它半个身子长的大鱼，"
            .. "尾巴高高翘起，以与身材完全不匹配的速度冲进了巷子。\n\n"
            .. "「我的鱼——！我那条银鳕鱼啊！」鱼贩的脸涨得通红，"
            .. "胖身子撞倒了自己的摊架，木板一歪，哗啦啦——"
            .. "十几条鱼像银色的雨点一样滑落在石板地上。\n\n"
            .. "消息传得比风还快。不知从哪里窜出来五六只野猫，"
            .. "黑的白的花的，争先恐后地扑向地上的鲜鱼。鱼贩一边追一边骂，"
            .. "旁边的菜贩子笑得前仰后合，卖花的老太太连忙护住自己的花篮。\n\n"
            .. "整条街陷入了一片鸡飞猫跳的混乱。"
        table.insert(choices, {
            text = "💪 帮鱼贩收拾摊位",
            target = location,
            action = function()
                TimeSystem.addMinutes(10)
                if (S.TL or 0) >= 6 then
                    S.money = S.money + 8
                    S.reputation = (S.reputation or 0) + 2
                    GameState.showNotification("你二话不说撸起袖子就冲了上去。\n\n"
                        .. "先是一脚挡住正准备溜走的一条大鲈鱼——那滑溜的手感差点让你摔倒，"
                        .. "但你稳住了重心，弯腰把鱼捞起来扔回木桶。接着你搬起倒下的摊板，"
                        .. "用膝盖顶住，双手一推，咔嚓一声归了位。\n\n"
                        .. "「嘿！干得漂亮！」鱼贩大叔从巷口气喘吁吁地跑回来，"
                        .. "看到你已经捡回了大半的鱼，感动得眼圈都红了。\n\n"
                        .. "「小伙子你真是好人哪！」他从围裙口袋里掏出一把铜币塞进你手里，"
                        .. "「拿着拿着，不嫌少的话就当是谢礼！"
                        .. "那只死胖猫——等我逮住它——」他恶狠狠地朝巷子方向挥了挥拳头。\n\n"
                        .. "旁边的菜贩子冲你竖了个大拇指：「有你的，年轻人！」\n"
                        .. "金币+8 声望+2")
                else
                    S.reputation = (S.reputation or 0) + 1
                    GameState.showNotification("你连忙蹲下来帮着捡鱼，但那些鱼滑溜得像抹了油一样，"
                        .. "怎么抓都从指缝里溜走。你好不容易抓住一条，"
                        .. "结果它一甩尾巴，鱼鳞飞了你一脸。\n\n"
                        .. "忙活了好一阵子，你总共才救回来三条鱼——身上却已经沾满了鱼腥味和泥水。\n\n"
                        .. "鱼贩大叔拍了拍你的肩膀：「辛苦了小伙子，心意我收到了！」"
                        .. "虽然帮得不多，但他的感激是真心的。\n"
                        .. "声望+1")
                end
            end,
        })
        table.insert(choices, {
            text = "😂 站在旁边看热闹",
            target = location,
            action = function()
                GameState.modStat("stress", -3)
                GameState.showNotification("你靠在对面的墙上，双手抱胸，决定纯粹享受这场免费的好戏。\n\n"
                    .. "那只肥橘猫已经叼着鱼蹿上了二楼的窗台，"
                    .. "用一种「你们谁也别想从我嘴里夺走它」的表情俯视着下方的混乱。"
                    .. "鱼贩在下面跳脚骂街，周围的摊贩笑得东倒西歪。\n\n"
                    .. "一只黑白花的小猫从你脚边溜过，嘴里叼着一条沙丁鱼，步伐轻快得像在跳舞。"
                    .. "你忍不住笑出了声。\n\n"
                    .. "生活不总是温柔的，但偶尔也会给你一场猫和鱼的闹剧作为补偿。\n"
                    .. "压力-3")
            end,
        })
    end

    -- 港口：瓶中信（下午，智力检定）
    if location == "港口" and period == "afternoon" and chance(10) and tryEvent("bottle_message") then
        text = text .. "\n\n午后的港口有些慵懒，渔船大多已经靠岸卸完了货。"
            .. "你沿着防波堤散步，海风带着咸湿的气息拂过脸颊。\n\n"
            .. "退潮的沙滩上，一个小小的反光引起了你的注意——"
            .. "那是一个玻璃瓶，被海草和碎贝壳半掩着，瓶身上附满了细密的水渍。"
            .. "瓶塞被火漆密封着，虽然外面的标签早已被海水冲刷得一干二净，"
            .. "但透过磨花的玻璃壁，能隐约看到里面塞着一张泛黄的纸条。\n\n"
            .. "你把瓶子捡起来，对着阳光举高——纸条上确实有字迹，但模糊不清，"
            .. "像是经历了很长很长的漂泊。"
        table.insert(choices, {
            text = "📜 拾起瓶子，试着辨认字迹",
            target = location,
            action = function()
                TimeSystem.addMinutes(10)
                if (S.ZL or 0) >= 8 then
                    S.knowledge = (S.knowledge or 0) + 1
                    GameState.showNotification("你小心翼翼地撬开火漆瓶塞，将那张脆得像枯叶的纸条取了出来。\n\n"
                        .. "纸条上的字迹用的是一种罕见的古航海密码——"
                        .. "你在教堂的旧书里见过类似的符号体系。"
                        .. "花了好一会儿工夫，你成功辨认出了大部分内容：\n\n"
                        .. "『自红灯塔起，北偏东三十七度，驶过三十海里。"
                        .. "过珊瑚礁区后，寻找形似巨龟的礁石。"
                        .. "翡翠群岛就在那里。此地有——』\n\n"
                        .. "后面的字迹彻底被海水溶蚀了，再也无法辨认。\n\n"
                        .. "「翡翠群岛」——你从未在任何海图上见过这个名字。"
                        .. "也许它只是某个水手的幻想，也许……它真的存在。"
                        .. "你把纸条上的信息默默记在了心里。\n"
                        .. "知识+1")
                else
                    GameState.showNotification("你撬开火漆，小心地展开那张薄如蝉翼的纸条。\n\n"
                        .. "字迹被海水泡得面目全非，大部分已经变成了模糊的墨渍。"
                        .. "你辨认了半天，只能勉强认出几个零散的词——"
                        .. "「三十海里」「北偏东」「珊瑚礁」「巨龟礁石」。\n\n"
                        .. "这些碎片勾勒出某种航线的轮廓，但你的知识还不足以将它们拼凑完整。"
                        .. "你把纸条塞回瓶子里，也许将来你的见识更广，"
                        .. "能从这些线索中读出更多的故事。\n\n"
                        .. "你把瓶子收好，在心底默默许下一个小小的愿望——有朝一日，"
                        .. "你要读懂这封来自大海深处的信。")
                end
            end,
        })
        table.insert(choices, {
            text = "🌊 把它推回海里",
            target = location,
            action = function()
                GameState.showNotification("你凝视着瓶子片刻，最终还是弯下腰，"
                    .. "把它轻轻推回了涌上来的浪花里。\n\n"
                    .. "海水毫不犹豫地接纳了它。小小的玻璃瓶在浪尖上颠簸了几下，"
                    .. "随即被一道更大的波浪卷了出去，越漂越远。\n\n"
                    .. "你站在原地看了一会儿，直到它变成海面上一个微不足道的光点。"
                    .. "不知道写下这些字的人现在在哪里。也不知道这个瓶子还要漂多久，"
                    .. "才能到达一个愿意读它的人手中。\n\n"
                    .. "海风吹干了你指尖残留的盐渍。你转身离去，"
                    .. "把这个小插曲留给了下午的海和无尽的潮汐。")
            end,
        })
    end

    -- 花园小镇：迷路的旅行画家（上午，魅力检定）
    if location == "花园小镇" and period == "morning" and chance(10) and tryEvent("lost_painter") then
        text = text .. "\n\n晨光温柔地洒在花园小镇的石板路上，露珠还挂在路边的蔷薇花瓣上。\n\n"
            .. "村口那棵老橡树下——你经过时注意到了一个陌生的身影。"
            .. "一个年轻的女子坐在树根上，身旁立着一个沾满颜料渍的画夹，"
            .. "一只帆布背包随意地靠在树干上，包口露出几支画笔和一卷素描纸。\n\n"
            .. "她正捧着一张展开的地图，眉头微蹙，不时抬头看看四周又低头对照，"
            .. "嘴里喃喃自语着什么。地图被她翻来覆去折了好几遍，"
            .. "有个角已经揉皱了。\n\n"
            .. "她穿着一件沾了零星油彩的亚麻外套，栗色短发被一条蓝色头带束起，"
            .. "看上去像是一个游历各地的旅行画家——只不过眼下显然被地图困住了。"
        table.insert(choices, {
            text = "🗺️ 上前帮忙指路",
            target = location,
            action = function()
                TimeSystem.addMinutes(15)
                S.reputation = (S.reputation or 0) + 2
                if (S.ML or 0) >= 6 then
                    GameState.showNotification("「请问……这里是花园小镇吗？」她看到你走近，"
                        .. "带着几分不好意思地问。地图上的标注和实际地形对不上号，"
                        .. "她本来想去东边的向日葵田写生，结果走到了完全相反的方向。\n\n"
                        .. "你笑着帮她重新辨认了方位，还顺手给她推荐了几个当地人才知道的好去处——"
                        .. "河边的石桥在上午十点光线最好，老磨坊后面的薰衣草田这个季节正是盛花期，"
                        .. "教堂钟楼上看小镇全景是整个地区最美的视角。\n\n"
                        .. "她的眼睛越听越亮，最后合上地图，从画夹里抽出一张速写递给你。\n\n"
                        .. "「这是我今早画的花园小镇入口，」她说，笑容腼腆而温暖，"
                        .. "「不值什么钱，但算是谢礼吧。遇到你真是太幸运了！」\n\n"
                        .. "你接过速写——寥寥几笔水彩，却把小镇清晨的光影捕捉得栩栩如生。"
                        .. "她收拾好画具，朝你挥了挥手，轻快地沿着你指的方向走了。\n"
                        .. "声望+2 获得「画家的速写」")
                    S.hasPainterSketch = true
                else
                    GameState.showNotification("「那个……请问这里是花园小镇吗？」她看到你，"
                        .. "松了口气似的站了起来。你帮她看了看地图，"
                        .. "指出了她要去的向日葵田在东边——她走反了。\n\n"
                        .. "「天哪，我就知道……」她不好意思地拍了拍脑袋，"
                        .. "连声说了好几句谢谢，手忙脚乱地折好地图，"
                        .. "背起画具匆匆往东边去了。\n\n"
                        .. "你看着她的背影消失在拐角处。"
                        .. "旅行画家的生活听起来很浪漫，但在陌生的地方迷路大概就没那么浪漫了。\n"
                        .. "声望+2")
                end
            end,
        })
        table.insert(choices, {
            text = "🙈 假装没看见",
            target = location,
            action = function()
                GameState.showNotification("你目光闪烁了一下，假装被路边的蔷薇花吸引，"
                    .. "不经意地从她身旁绕了过去。\n\n"
                    .. "走出一段路后你忍不住回头看了一眼——"
                    .. "她还坐在老橡树下，地图已经被风吹翻了一个面，"
                    .. "她正一脸茫然地试图把它翻回来。\n\n"
                    .. "你心里有一丁点歉疚，但随即被「今天还有很多事要做」这个理由盖了过去。"
                    .. "她最终会找到路的。大概吧。")
            end,
        })
    end

    -- 主城区：贵族马车事故（傍晚，敏捷/体力检定）
    if location == "主城区" and period == "evening" and chance(10) and tryEvent("carriage_accident") then
        text = text .. "\n\n傍晚的主城区街道上，马蹄声和车轮声交织在一起。"
            .. "夕阳将石砌建筑的影子拉得很长，行人们带着一天的疲惫匆匆赶路。\n\n"
            .. "忽然，前方传来一声尖锐的嘶鸣——一辆漆着暗红色金纹的四马马车"
            .. "在弯道处速度过快，车厢猛烈地向一侧倾斜。"
            .. "后方行李架上的一只包着铜皮的木箱被甩了出去，"
            .. "砰的一声砸在石板路上，箱盖弹开。\n\n"
            .. "精美的青花瓷器碎了一地，几本皮革封面的古籍散落在碎片之间，"
            .. "还有一只镶嵌着宝石的首饰盒滚到了排水沟边。"
            .. "车夫使劲拉住缰绳，但四匹高头大马受了惊，"
            .. "前蹄不安地刨着地面，鼻孔喷出白气。\n\n"
            .. "路人纷纷后退避让。马车帘子一动，里面隐约传出一个女人的惊呼声。"
        table.insert(choices, {
            text = "🏃 冲上去帮忙安抚马匹",
            target = location,
            action = function()
                TimeSystem.addMinutes(10)
                if (S.TL or 0) >= 7 then
                    S.money = S.money + 15
                    S.reputation = (S.reputation or 0) + 3
                    GameState.showNotification("你一个箭步冲上去，双手紧紧抓住领头马的缰绳。\n\n"
                        .. "马匹猛地扬起头，几乎要把你拽离地面——但你扎稳了脚步，"
                        .. "身体前倾，用肩膀抵住马颈，一只手抚上它的鬃毛。"
                        .. "「嘘……嘘……没事了，没事了。」你压低声音，沉稳地安抚着。\n\n"
                        .. "也许是你的力气，也许是你语气里的镇定——马匹渐渐平静下来，"
                        .. "喘着粗气，前蹄不再刨地了。车夫趁机收紧了其他马的缰绳，"
                        .. "整辆马车终于稳住了。\n\n"
                        .. "马车帘子掀开，一位衣着考究的中年贵妇人探出身来。"
                        .. "她的目光沉稳而锐利，像是见惯了大场面的人。"
                        .. "她上下打量了你片刻，微微颔首。\n\n"
                        .. "「有胆识，有力量。」她说了这五个字，然后对身旁的侍从使了个眼色。\n\n"
                        .. "侍从从车厢里取出一只绣花绸袋递给你——入手沉甸甸的，"
                        .. "里面是十五枚崭新的银币。\n\n"
                        .. "贵妇人收回目光，放下帘子。马车重新启程，"
                        .. "消失在暮色深处。你攥着那袋银币，心跳还没完全平复。\n"
                        .. "金币+15 声望+3")
                else
                    S.reputation = (S.reputation or 0) + 1
                    GameState.modStat("stress", 5)
                    GameState.showNotification("你鼓起勇气冲上前去，伸手去抓缰绳——但受惊的马匹猛地一偏头，"
                        .. "缰绳从你掌心滑过，灼热的摩擦让你本能地缩回了手。\n\n"
                        .. "紧接着那匹棕马一蹄子踢在你脚边的石板上，"
                        .. "碎石崩起来打在你的小腿上，疼得你龇了龇牙。"
                        .. "你被迫后退了几步，心脏砰砰直跳。\n\n"
                        .. "好在车夫经验丰富，使出浑身解数终于控制住了局面。"
                        .. "马车停稳后，帘子掀开露出贵妇人冷淡的面孔——"
                        .. "她扫了你一眼，什么也没说，帘子就放了下来。\n\n"
                        .. "马车重新上路。你揉着发疼的小腿，"
                        .. "有些后悔自己的冲动——但至少你试过了。\n"
                        .. "声望+1 压力+5")
                end
            end,
        })
        table.insert(choices, {
            text = "📦 帮忙收拾散落的物品",
            target = location,
            action = function()
                TimeSystem.addMinutes(5)
                S.reputation = (S.reputation or 0) + 1
                GameState.showNotification("你没有去碰那些焦躁的马匹，而是蹲下来，"
                    .. "小心地从碎瓷片之间捡出那些还完好的东西。\n\n"
                    .. "几本古籍的封面沾了泥，你用衣角轻轻擦拭干净。"
                    .. "那只滚到排水沟边的首饰盒你也找了回来——上面镶着的红宝石在夕阳下闪着光，"
                    .. "看起来价值不菲。\n\n"
                    .. "车夫费了好大劲才稳住马匹，回头看到你已经把东西归拢好了，"
                    .. "感激得连连作揖：「谢谢您啊！这要是丢了什么，我可赔不起！」\n\n"
                    .. "马车里的主人始终没有露面。车夫把东西搬回行李架后，"
                    .. "马车便缓缓驶走了。你拍了拍膝盖上的灰，继续赶路。\n"
                    .. "声望+1")
            end,
        })
    end

    -- 花街：蒙面舞者（夜晚，魅力检定）
    if location == "花街" and period == "night" and chance(12) and tryEvent("masked_dancer") then
        text = text .. "\n\n夜晚的花街灯火通明，笑语声和乐器声从各家酒馆飘出来，"
            .. "空气里混着香水和烤坚果的甜味。\n\n"
            .. "你正穿过一个小广场，忽然——人群自动散开了一个圆圈。"
            .. "圆圈中央的十字灯柱下，一个修长的身影正在独舞。\n\n"
            .. "她戴着一只精致的银色面具，只露出下半张脸和一双在灯光下闪烁的眼睛。"
            .. "一袭暗紫色丝裙垂至脚踝，裙摆缀着细碎的银珠，"
            .. "每一次旋转都会在灯光下划出流光溢彩的弧线——"
            .. "仿佛夜空中有一条银河在她身边流淌。\n\n"
            .. "她的动作轻盈得不像是在踩着地面，而像是悬浮在一层薄雾之上。"
            .. "手臂伸展如天鹅的翅膀，收回时又柔若无骨。"
            .. "围观的人群安静了下来，连呼吸都变得小心翼翼，"
            .. "生怕惊扰了这不属于凡间的一幕。\n\n"
            .. "不知是谁在角落里拉起了手风琴，悠远而忧伤的旋律正好为她的舞步伴奏。"
        table.insert(choices, {
            text = "💃 鼓掌喝彩",
            target = location,
            action = function()
                GameState.modStat("stress", -5)
                if (S.ML or 0) >= 10 then
                    GameState.showNotification("手风琴的最后一个音符消散在夜风中。\n\n"
                        .. "舞者完成了最后一个旋转——裙摆像一朵绽放到极致的花，"
                        .. "在空中定了一瞬，然后缓缓收拢。她微微屈膝，向四周行了一个优雅的礼。\n\n"
                        .. "人群爆发出热烈的掌声和喝彩声。但在那片嘈杂中，"
                        .. "她的目光穿过人群，准确地找到了你。\n\n"
                        .. "她朝你走来——步伐轻盈得像踩在水面上——"
                        .. "在你面前停下，歪了歪头。银色面具后面，那双眼睛含着笑意。\n\n"
                        .. "「你的眼神很特别。」她的声音低而清晰，像月光落在琴弦上。"
                        .. "「大多数人看舞蹈，看的是身体。你看的是灵魂。」\n\n"
                        .. "她伸出手，在你的掌心轻轻放下一朵银色的绢花。"
                        .. "花瓣是用最细的银丝编成的，在灯光下闪着柔和的光泽。\n\n"
                        .. "你抬起头想说些什么——但她已经转身融入了夜色，"
                        .. "像一缕烟一样消散在花街的灯火之间。\n\n"
                        .. "你低头看着掌心的银花，金属触感微凉。"
                        .. "周围的人群已经散去，仿佛什么都没发生过。"
                        .. "只有手风琴的余韵还在空气里隐约震颤。\n"
                        .. "压力-5 获得「银色绢花」")
                    S.silverFlower = true
                else
                    GameState.showNotification("你和周围的人一起鼓起了掌。\n\n"
                        .. "舞者优雅地行了一礼，银珠裙摆在最后一次旋转中发出清脆的碰撞声。"
                        .. "人群中有人往她脚边扔了几枚铜币，有人吹了声口哨。\n\n"
                        .. "她没有去捡地上的铜币，只是朝人群微微颔首，"
                        .. "然后像来时一样安静地离开了。\n\n"
                        .. "你看着她消失的方向愣了一会儿。"
                        .. "那场舞让你想起了一些说不清的东西——"
                        .. "也许是某个旧梦里的片段，也许是你从未拥有过的某种自由。\n\n"
                        .. "你深吸一口夜晚的凉风，心情莫名地轻松了许多。\n"
                        .. "压力-5")
                end
            end,
        })
        table.insert(choices, {
            text = "🔍 试着看清面具后的脸",
            target = location,
            action = function()
                GameState.showNotification("好奇心驱使你往前挤了几步，试图看清面具后面的容貌。\n\n"
                    .. "你侧着身子从人群缝隙中探出头——但就在你几乎能看清的那一刻，"
                    .. "她恰好完成了一个旋转，裙摆像一道银色的屏障从你眼前掠过。\n\n"
                    .. "等裙摆落下时，她已经面朝另一个方向了。"
                    .. "但你隐约捕捉到了一些东西——面具下弯起的嘴角，"
                    .. "一颗位于左侧嘴角的小痣，以及一缕从面具边缘溢出的银灰色发丝。\n\n"
                    .. "她似乎察觉到了你的注视，微微偏头看了你一眼。"
                    .. "面具后的眼睛含着一丝戏谑——仿佛在说：「看到了什么？什么也没看到吧。」\n\n"
                    .. "你不由得笑了。是啊，也许有些美丽的东西，"
                    .. "本来就不该被看得太清楚。")
            end,
        })
    end

    -- ============ 全局：天降横财/横祸（低概率高影响）============
    if chance(5) and tryEvent("fortune_turn_" .. location) then
        if chance(50) then
            -- 捡到钱
            local amount = math.random(5, 15)
            text = text .. "\n\n你走在路上，目光无意间扫过脚边——"
                .. "一只深棕色的小皮袋就躺在路边的排水沟旁，系口的绳子松松地散开着。\n\n"
                .. "你弯腰捡起来，掂了掂——沉甸甸的。"
                .. "解开一看，里面是" .. amount .. "枚金币，还有一张揉皱的酒馆收据。"
                .. "看起来像是某个喝多了的倒霉蛋从口袋里掉出来的。\n\n"
                .. "你环顾四周——行人来来往往，没人在找东西的样子。"
                .. "这笔小财就这么安安静静地等在这里，像是命运的一个小玩笑。"
            table.insert(choices, {
                text = "💰 收下它",
                target = location,
                action = function()
                    S.money = S.money + amount
                    GameState.showNotification("你左看右看确认没人注意，把钱袋利索地揣进了怀里。\n\n"
                        .. "铜币在口袋里相互碰撞，发出令人愉悦的叮当声。"
                        .. "你忍不住嘴角上扬——谁说运气不是一种实力呢？\n\n"
                        .. "不过走出一段路之后，你还是下意识回头看了一眼。"
                        .. "没人追上来，也没有愤怒的喊叫声。那就好。\n\n"
                        .. "今天是个好日子。\n"
                        .. "金币+" .. amount)
                end,
            })
            table.insert(choices, {
                text = "🔍 交给附近的巡逻守卫",
                target = location,
                action = function()
                    GameState.modStat("stress", -5)
                    S.ML = S.ML + 1
                    GameState.showNotification("你拎着钱袋走到最近的一个巡逻守卫面前。\n\n"
                        .. "「在那边捡到的，可能是谁丢的。」你把钱袋递过去。\n\n"
                        .. "守卫接过来打开看了看，有些惊讶地挑了挑眉。"
                        .. "「" .. amount .. "枚金币……不少了。你没自己拿走？」\n\n"
                        .. "你摇了摇头。守卫打量了你一眼，嘴角微微翘起。\n\n"
                        .. "「现在像你这样的年轻人可不多了。」他认真地点了点头，"
                        .. "「放心吧，我会想办法找到失主的。」\n\n"
                        .. "你转身走开时心情意外地好。口袋里没多一分钱，"
                        .. "但胸口好像装满了什么轻飘飘的东西。\n"
                        .. "压力-5 魅力+1")
                end,
            })
        else
            -- 踩到坑
            text = text .. "\n\n你正想着心事，完全没注意脚下——"
                .. "「扑通」一声，一只脚直接踩进了路边的一个泥水坑里。\n\n"
                .. "冰凉的泥水瞬间灌满了鞋子，溅得裤腿上到处都是棕色的污渍。"
                .. "你僵在原地，低头看着自己那只已经面目全非的鞋——"
                .. "一种无法言说的挫败感从脚底升到了头顶。\n\n"
                .. "路过的一个老太太同情地看了你一眼。"
                .. "旁边一个小孩指着你的鞋咯咯直笑，被他妈妈拽走了。"
            table.insert(choices, {
                text = "😤 自认倒霉",
                target = location,
                action = function()
                    GameState.modStat("stress", 3)
                    GameState.showNotification("你深吸一口气，把那只湿透的鞋从泥水里拔出来——"
                        .. "伴随着一声不太体面的「啵」声。\n\n"
                        .. "你甩了甩鞋上的泥水，试图挽回最后一点体面。"
                        .. "然而每走一步，湿袜子在鞋里发出的「咕叽咕叽」声"
                        .. "都在提醒你今天的运气有多糟糕。\n\n"
                        .. "算了。就当是生活给你开了个玩笑。\n"
                        .. "压力+3")
                end,
            })
        end
    end

    return text, choices
end

return RandomEventData_StatCheck
