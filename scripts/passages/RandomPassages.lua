-- ============================================================================
-- RandomPassages.lua - 随机事件连锁段落
-- 从 RandomEvents.lua 拆分：连锁事件的 passage handler
-- 包含11个段落：抓小偷、跟踪小偷、砍价、预测风暴、帮助渔民、
--   帮迷路孩子、花店等妈妈、偷听交易、打断交易、码头搬运、
--   鉴定蘑菇、罗伊稀有货
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local CommonUtils = require("utils.CommonUtils")

local statCheck = CommonUtils.statCheck
local chance = CommonUtils.chance

local handlers = {}

-- ==================== 抓小偷（技巧检定）====================
handlers["随机_抓小偷"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    if statCheck("JQ", 25, 8) then
        return {
            text = "你眼疾手快，一把抓住了少年的手腕！\n\n"
                .. "「放开！放开我！」他拼命挣扎。\n\n"
                .. "他看起来很年轻，脸上脏兮兮的，衣服也破破烂烂。\n"
                .. "你低头一看——他的手里空空的，什么也没偷到。\n\n"
                .. "「……我饿了。」他小声说。\n"
                .. "眼圈突然红了。",
            choices = {
                {
                    text = "🍞 给他买个面包（5金币）",
                    target = S._settingsFrom or "十字路口",
                    action = function()
                        if S.money >= 5 then
                            S.money = S.money - 5
                            S.ML = S.ML + 1
                            GameState.modStat("stress", -5)
                            GameState.showNotification("少年狼吞虎咽地吃完面包，抹了抹嘴。\n「……谢谢。」他跑远了。\n你心里暖暖的。魅力+1 压力-5")
                        else
                            GameState.showNotification("你摸了摸口袋……自己也没什么钱。")
                        end
                    end,
                },
                {
                    text = "⚠️ 警告他以后别偷东西",
                    target = S._settingsFrom or "十字路口",
                    action = function()
                        GameState.showNotification("你严肃地教育了他几句。他低着头，一声不吭。\n你放开手，他飞快地跑远了。")
                    end,
                },
                {
                    text = "🏛️ 把他交给巡逻守卫",
                    target = S._settingsFrom or "十字路口",
                    action = function()
                        S.YG = S.YG + 1
                        GameState.showNotification("你叫来了守卫。少年被带走了。\n他回头看了你一眼。那个眼神让你有点不舒服。勇敢+1")
                    end,
                },
            },
        }
    else
        return {
            text = "你伸手一抓——扑了个空！\n\n"
                .. "那少年像泥鳅一样滑溜，在人群中一闪就不见了。\n\n"
                .. "你赶紧检查口袋。还好，什么都没少。\n"
                .. "但是那小子的身手确实了得。\n\n"
                .. "（没有抓住，但也没有损失）",
            choices = { { text = "继续", target = S._settingsFrom or "十字路口" } },
        }
    end
end

-- ==================== 跟踪小偷（发现新情报）====================
handlers["随机_跟踪小偷"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(15)
    if statCheck("JQ", 30, 6) then
        return {
            text = "你不动声色地跟上了灰衣少年。\n\n"
                .. "他穿过几条小巷，来到一间破旧的仓库前。\n"
                .. "里面传来说话声——不止他一个人。\n\n"
                .. "你隔着窗户偷看了一眼。\n"
                .. "几个衣衫褴褛的孩子围坐在一起，\n"
                .. "中间放着一小堆面包和水果——应该是今天的'收获'。\n\n"
                .. "领头的少年把大部分食物分给了更小的孩子。\n"
                .. "他自己只留了一小块。\n\n"
                .. "你决定默默离开。\n\n"
                .. "（发现了流浪儿的据点。也许以后可以做点什么。）",
            choices = {
                { text = "继续", target = S._settingsFrom or "十字路口" },
            },
        }
    else
        return {
            text = "你试着跟上那个少年，但他很快就消失在错综复杂的小巷里。\n\n"
                .. "你在巷子里转了半天，最后连自己在哪都搞不清了。\n\n"
                .. "好不容易找到大路，已经过了不少时间。",
            choices = { { text = "继续", target = S._settingsFrom or "十字路口" } },
        }
    end
end

-- ==================== 砍价（魅力检定）====================
handlers["随机_砍价"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    if statCheck("ML", 20, 8) then
        return {
            text = "你微笑着走上前，认真打量那个皮带扣。\n\n"
                .. "「老板，这做工确实不错。不过边角有点磨损了，\n"
                .. "15金币怎么样？」\n\n"
                .. "摊主犹豫了一下。你又补了一句：\n"
                .. "「我可是经常来这条街的。以后还会照顾生意。」\n\n"
                .. "「……得，20金币，不能再少了。」\n\n"
                .. "你心满意足地收下了皮带扣。",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "商业区",
                    action = function()
                        S.money = S.money - 20
                        S.JQ = S.JQ + 1
                        GameState.showNotification("砍价成功！省了10金币。技巧+1")
                    end,
                },
            },
        }
    else
        return {
            text = "「老板，便宜点？」你试探着问。\n\n"
                .. "摊主看了你一眼。\n"
                .. "「年轻人，这已经是最低价了。\n"
                .. "你看这做工、这材质——哪里找得到第二个？」\n\n"
                .. "他说得头头是道，你完全插不上嘴。\n最后你还是原价买了……或者不买。",
            choices = {
                {
                    text = "💰 算了，原价买",
                    target = S._settingsFrom or "商业区",
                    action = function()
                        if S.money >= 30 then
                            S.money = S.money - 30
                            GameState.showNotification("你买下了皮带扣。没砍下来价……")
                        else
                            GameState.showNotification("摸了摸口袋，钱不够。")
                        end
                    end,
                },
                {
                    text = "🚶 还是算了",
                    target = S._settingsFrom or "商业区",
                },
            },
        }
    end
end

-- ==================== 预测风暴（灵感检定）====================
handlers["随机_预测风暴"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(10)
    if statCheck("LG", 20, 10) then
        return {
            text = "你仔细观察了云层的形状和风向变化。\n\n"
                .. "根据你的判断——风暴会从东北方向来，\n"
                .. "大约一个小时后到达港口。\n\n"
                .. "你把判断告诉了码头的渔民们。\n"
                .. "领头的老渔民将信将疑地看了看天，\n"
                .. "最后还是决定提前收网。\n\n"
                .. "果然，不到一小时，暴风雨就来了。\n"
                .. "渔民们感激地向你道谢。\n\n"
                .. "（你的判断救了大家！灵感+1 获得10金币）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "港口",
                    action = function()
                        S.LG = S.LG + 1
                        S.money = S.money + 10
                    end,
                },
            },
        }
    else
        return {
            text = "你盯着天空看了半天，\n"
                .. "但实在分不清哪朵云预示着风暴。\n\n"
                .. "「看不懂就算了。」旁边的渔民拍了拍你的肩膀。\n"
                .. "「这种事得靠经验。我干了三十年才看得准。」\n\n"
                .. "虽然没帮上忙，但你学到了一些观察天象的技巧。",
            choices = { { text = "继续", target = S._settingsFrom or "港口" } },
        }
    end
end

-- ==================== 帮助渔民（力量检定）====================
handlers["随机_帮助渔民"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(20)
    if statCheck("LL", 25, 8) then
        return {
            text = "你挽起袖子，帮渔民们把沉重的渔网和木箱搬到安全的地方。\n\n"
                .. "你的力气不小，一个人扛起了别人需要两人抬的木箱。\n"
                .. "渔民们投来赞许的目光。\n\n"
                .. "忙完之后，一个渔民塞给你几条新鲜的鱼：\n"
                .. "「谢谢你小伙子！拿回去烤了吃。」\n\n"
                .. "（力量+1 获得新鲜的鱼 饱食度+15）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "港口",
                    action = function()
                        S.LL = S.LL + 1
                        GameState.modStat("satiety", 15)
                        GameState.modStat("fatigue", 10)
                    end,
                },
            },
        }
    else
        return {
            text = "你努力搬着木箱，但它实在太重了。\n"
                .. "你的胳膊酸得不行，勉强搬了两趟就搬不动了。\n\n"
                .. "一个壮实的渔民笑着接过木箱：\n"
                .. "「行了行了，你这身板还得练练。心意领了。」\n\n"
                .. "虽然没帮上太大忙，但渔民们还是给了你一小块干面包。\n\n"
                .. "（疲劳+8 饱食度+5）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "港口",
                    action = function()
                        GameState.modStat("fatigue", 8)
                        GameState.modStat("satiety", 5)
                    end,
                },
            },
        }
    end
end

-- ==================== 帮迷路孩子 ====================
handlers["随机_帮迷路孩子"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(20)
    return {
        text = "你蹲下来，轻声安慰小女孩。\n"
            .. "「别哭了。你记得妈妈长什么样吗？」\n\n"
            .. "小女孩抽噎着说：「妈妈……穿着蓝色的裙子……」\n\n"
            .. "你牵着她的手，在花园附近转了一圈。\n"
            .. "终于在喷泉边找到了一个焦急的妇人。\n\n"
            .. "「妮娜！」妇人冲过来一把抱住小女孩。\n"
            .. "然后她转向你，连连道谢。\n\n"
            .. "「真是太感谢你了！」她从口袋里掏出几枚硬币塞给你。\n"
            .. "「不多，是一点心意。」\n\n"
            .. "小女孩从妈妈怀里探出头来，冲你挥了挥布偶兔子的手。\n\n"
            .. "（魅力+1 获得8金币 压力-8）",
        choices = {
            {
                text = "继续",
                target = S._settingsFrom or "花园小镇",
                action = function()
                    S.ML = S.ML + 1
                    S.money = S.money + 8
                    GameState.modStat("stress", -8)
                end,
            },
        },
    }
end

-- ==================== 花店等妈妈（需要认识莉莉安）====================
handlers["随机_花店等妈妈"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(15)
    if not S.npcLillianMet then
        return {
            text = "你带着小女孩来到花店门口。\n"
                .. "但你其实并不认识这里的店主……\n\n"
                .. "不过花店老板娘看到小女孩在哭，\n"
                .. "马上走出来，温柔地蹲下来安慰她。\n"
                .. "「小朋友别哭，姐姐给你一朵花好不好？」\n\n"
                .. "小女孩被花吸引了注意力，渐渐不哭了。\n"
                .. "不一会儿，她的妈妈找了过来。\n\n"
                .. "（压力-5）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "花园小镇",
                    action = function()
                        GameState.modStat("stress", -5)
                    end,
                },
            },
        }
    else
        return {
            text = "你带着小女孩来到莉莉安的花店。\n\n"
                .. "莉莉安看到哭泣的小女孩，立刻明白了情况。\n"
                .. "她蹲下来，从花束中抽出一朵粉色的小花递过去。\n"
                .. "「这朵花送给你。它叫'勿忘我'。\n"
                .. "花语是——永远不会走丢。」\n\n"
                .. "小女孩破涕为笑。莉莉安冲你眨了眨眼。\n\n"
                .. "十几分钟后，妈妈找来了。\n"
                .. "小女孩举着花跑过去：「妈妈！这是'永远不走丢'的花！」\n\n"
                .. "（莉莉安 好感+3 魅力+1 压力-8）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "花园小镇",
                    action = function()
                        S.npcLillian = S.npcLillian + 3
                        S.ML = S.ML + 1
                        GameState.modStat("stress", -8)
                    end,
                },
            },
        }
    end
end

-- ==================== 偷听交易（技巧检定）====================
handlers["随机_偷听交易"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(10)
    if statCheck("JQ", 30, 6) then
        return {
            text = "你蹑手蹑脚地靠近，躲在一堆木箱后面。\n\n"
                .. "「……货已经到了。三天后老地方交接。」\n"
                .. "「这次的量比上次多一倍。上面催得紧。」\n"
                .. "「行。钱呢？」\n"
                .. "「先付一半。」\n\n"
                .. "一个人递出一个沉甸甸的布袋。另一个人接过去掂了掂。\n"
                .. "「可以。三天后见。」\n\n"
                .. "两个人分开走了。你又等了一会儿才出来。\n\n"
                .. "这个信息也许对某些人有用……\n\n"
                .. "（技巧+1 获得了一条情报）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "花街",
                    action = function()
                        S.JQ = S.JQ + 1
                    end,
                },
            },
        }
    else
        return {
            text = "你小心翼翼地靠近，但是——\n\n"
                .. "「咔嚓。」\n\n"
                .. "你踩到了一根干树枝。\n\n"
                .. "两个人影猛地转过头来。\n"
                .. "你来不及跑，疤脸男人已经走到你面前。\n\n"
                .. "「你听到了什么？」\n\n"
                .. "你疯狂摇头。\n\n"
                .. "他盯着你看了几秒。然后掏出一枚硬币弹给你。\n"
                .. "「今晚你什么也没看到。明白？」\n\n"
                .. "你点头如捣蒜。他们消失在夜色中。\n\n"
                .. "你低头看那枚硬币——是真金的。\n\n"
                .. "（虚惊一场。获得1金币 压力+5）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "花街",
                    action = function()
                        S.money = S.money + 1
                        GameState.modStat("stress", 5)
                    end,
                },
            },
        }
    end
end

-- ==================== 打断交易（勇气检定）====================
handlers["随机_打断交易"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    if S.YG >= 3 and statCheck("LL", 20, 6) then
        return {
            text = "你大声咳了一声。\n\n"
                .. "两个人影吓了一跳，纷纷后退。\n"
                .. "疤脸男人眯起眼睛打量你。\n\n"
                .. "你挺起胸膛，面无惧色地回望他。\n\n"
                .. "片刻的沉默。然后疤脸男人冷笑一声。\n"
                .. "「有胆量。但劝你别多管闲事。」\n\n"
                .. "他们收起东西，消失在暗巷深处。\n\n"
                .. "你的心跳了好一会儿才平复下来。但你没有退缩。\n\n"
                .. "（勇敢+2）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "花街",
                    action = function()
                        S.YG = S.YG + 2
                    end,
                },
            },
        }
    else
        return {
            text = "你用力咳了一声——\n"
                .. "但声音从嗓子里出来的时候变成了一个尴尬的嗝。\n\n"
                .. "疤脸男人转过头来，表情阴沉。\n"
                .. "「小鬼，想找麻烦？」\n\n"
                .. "你的腿不争气地开始发抖。\n"
                .. "他走过来，居高临下地看着你。\n"
                .. "然后——他在你头上弹了一下。\n\n"
                .. "「滚。」\n\n"
                .. "你灰溜溜地跑了。\n\n"
                .. "（压力+8 但你至少没受伤）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "花街",
                    action = function()
                        GameState.modStat("stress", 8)
                    end,
                },
            },
        }
    end
end

-- ==================== 码头搬运（力量检定）====================
handlers["随机_码头搬运"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(120)
    if statCheck("LL", 20, 10) then
        return {
            text = "你报了名。工头看了看你的体格，点了点头。\n\n"
                .. "接下来的两个小时，你搬了数不清的木箱和货袋。\n"
                .. "虽然累得要死，但你扛了下来。\n\n"
                .. "收工时，工头拍了拍你的肩膀。\n"
                .. "「不错，小子。力气够用。\n以后要是还想干，直接来找我就行。」\n\n"
                .. "他递给你25金币。\n\n"
                .. "（力量+1 获得25金币 疲劳+20 饱食度-15）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "港口",
                    action = function()
                        S.LL = S.LL + 1
                        S.money = S.money + 25
                        GameState.modStat("fatigue", 20)
                        GameState.modStat("satiety", -15)
                    end,
                },
            },
        }
    else
        return {
            text = "你报了名，但搬运工作比想象中艰苦得多。\n\n"
                .. "第一个小时你还勉强能跟上节奏。\n"
                .. "到了第二个小时，你的胳膊已经完全抬不起来了。\n\n"
                .. "工头皱着眉看了你一眼。\n"
                .. "「行了，你先歇着吧。」\n\n"
                .. "他递给你15金币。「就这些了。下次练练力气再来。」\n\n"
                .. "（获得15金币 疲劳+25 饱食度-10）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "港口",
                    action = function()
                        S.money = S.money + 15
                        GameState.modStat("fatigue", 25)
                        GameState.modStat("satiety", -10)
                    end,
                },
            },
        }
    end
end

-- ==================== 鉴定蘑菇（灵感检定 + 植物学加成）====================
handlers["随机_鉴定蘑菇"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    local botanyBonus = (S.botanyLevel or 0) * 15  -- 每级植物学+15%成功率
    if statCheck("LG", 25 + botanyBonus, 8) then
        return {
            text = "你蹲下来仔细观察这些蘑菇。\n\n"
                .. "紫色的伞盖，金色的斑点……\n"
                .. "你想起在阿莫斯的图书室里看到过类似的描述。\n\n"
                .. "这是「星尘蘑菇」！据说磨成粉后可以做药引，\n"
                .. "也能用来给料理增添独特的风味。\n\n"
                .. "你小心翼翼地摘了几朵。\n\n"
                .. "（灵感+1 获得「神秘蘑菇」x2）",
            choices = {
                {
                    text = "继续",
                    target = S._settingsFrom or "花园小镇",
                    action = function()
                        S.LG = S.LG + 1
                        local ing = S.ingredients or {}
                        local key = "神秘蘑菇"
                        ing[key] = (ing[key] or 0) + 2
                        S.ingredients = ing
                    end,
                },
            },
        }
    else
        return {
            text = "你蹲下来看了半天。\n"
                .. "颜色很鲜艳……这到底是珍贵的药材还是毒蘑菇？\n\n"
                .. "你拿不准。最后还是决定不碰了。\n"
                .. "万一吃了中毒就麻烦了。\n\n"
                .. "也许下次遇到懂行的人可以问问。",
            choices = { { text = "继续", target = S._settingsFrom or "花园小镇" } },
        }
    end
end

-- ==================== 罗伊稀有货（好感度门槛事件）====================
handlers["随机_罗伊稀有货"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    return {
        text = "罗伊打开小盒子。里面是一枚造型奇特的戒指。\n\n"
            .. "「这是我从一个水手那里收来的。」\n"
            .. "他压低声音，「据说是从古代遗迹里挖出来的。」\n\n"
            .. "你仔细看了看。戒指上刻着你不认识的文字，\n"
            .. "但做工确实精致得不像现代的东西。\n\n"
            .. "「50金币。老主顾价。」罗伊竖起一根手指。\n\n"
            .. "「至于是真是假……」他眨了眨眼。\n"
            .. "「这就看你信不信了。」",
        choices = {
            {
                text = "💰 买下戒指（50金币）",
                target = S._settingsFrom or "商业区",
                action = function()
                    if S.money >= 50 then
                        S.money = S.money - 50
                        -- 随机效果：可能是真的也可能是假的
                        if chance(40) then
                            S.LG = S.LG + 2
                            S.NL = S.NL + 1
                            GameState.showNotification("戒指戴上后微微发热——居然是真的古代魔具！\n灵感+2 耐力+1")
                        else
                            S.JQ = S.JQ + 1
                            GameState.showNotification("戒指……什么反应也没有。\n大概是假的。不过做工确实不错。技巧+1（你学会了鉴别做工）")
                        end
                    else
                        GameState.showNotification("你凑不够50金币……")
                    end
                end,
            },
            {
                text = "🤔 再考虑考虑",
                target = S._settingsFrom or "商业区",
                action = function()
                    GameState.showNotification("罗伊收起盒子：「下次再来，说不定就被别人买走了。」")
                end,
            },
        },
    }
end

return handlers
