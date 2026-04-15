-- passages/npc_event/FairyInvitation.lua
-- Auto-split sub-module

return function(handlers, deps)

local GameState = deps.GameState
local TimeSystem = deps.TimeSystem
local WorkSystem = deps.WorkSystem
local CommonUtils = deps.CommonUtils
local PassageDeps = deps.PassageDeps
local addAffection = deps.addAffection
local addDateLog = deps.addDateLog
local addOamelAffection = deps.addOamelAffection
local addMeifeiAffection = deps.addMeifeiAffection
local addHistoryExp = deps.addHistoryExp
local dateScenes = deps.dateScenes
local banquetThemes = deps.banquetThemes
local readBook = deps.readBook
local handlers = deps.handlers

handlers["妖精的邀请"] = function(S)
    local text = "门童引你进去。大厅金碧辉煌，水晶吊灯下，几张赌桌旁围满了人。"

    -- 小奥出现判定
    local oamelInLobby = false
    if (S.hour >= 10 and S.hour < 18 and math.random(1, 100) <= 80) or (S.hour >= 18 and S.hour < 22) then
        oamelInLobby = true
    end
    if oamelInLobby then
        text = text .. "\n\n吧台后，一个穿黑色燕尾服的年轻人正在调酒。他抬起头，露出一张精致的脸——奥梅尔·罗斯巴特。\n他看见你，嘴角勾起一个似笑非笑的弧度：「哟，又来了？」"
    else
        text = text .. "\n\n吧台后空无一人，只有几只洗好的酒杯倒扣着。一个侍从过来：「罗斯巴特少爷在楼上，需要叫他吗？」"
    end

    -- 梅菲斯值班
    local meifeiInLobby = S.hour >= 10 and S.hour < 22
    if meifeiInLobby then
        text = text .. "\n\n大堂一角，穿着灰色正装的梅菲斯正与几位商人交谈。他看见你，微微点头示意。"
    end

    -- 阿斯特来谈生意 (下午/傍晚, 12%, Ch3揭秘前)
    local rosbatFatherPresent = false
    if not S.mq3FatherSecret and S.hour >= 14 and S.hour < 21 and math.random(1, 100) <= 12 then
        rosbatFatherPresent = true
        S.rosbatFatherFairyCount = (S.rosbatFatherFairyCount or 0) + 1

        if S.rosbatFatherFairyCount == 1 then
            text = text .. "\n\n忽然，大门被侍从毕恭毕敬地推开，一股无形的压迫感弥漫开来。"
                .. "走进来的是一位身穿深蓝色长大衣的中年男人，银灰色的头发一丝不苟地梳向脑后，"
                .. "颧骨高耸，下颌线条如刀削般凌厉。两个黑衣随从紧跟在他身后，目光警惕地扫视四周。\n\n"
                .. "大堂里的气氛微妙地变了——赌桌旁的几个商人不约而同地压低了声音，"
                .. "荷官的动作也比刚才规矩了许多。\n\n"
                .. "梅菲斯从座位上站起来，快步迎上去，脸上堆起了恰到好处的笑容："
                .. "「罗斯巴特伯爵，欢迎您莅临。雅间已经备好了。」\n\n"
                .. "中年男人——罗斯巴特伯爵，也就是奥梅尔的父亲——微微颔首，"
                .. "目光像鹰一样锐利地在大堂扫了一圈，最终落在了吧台后面。"
                .. "奥梅尔低下头假装擦杯子，但脊背明显绷直了。\n\n"
                .. "伯爵没有多看儿子一眼，跟着梅菲斯往楼上走去。经过你身旁时，"
                .. "那股檀木香水和皮革的气味短暂地笼罩了你。"
                .. "你注意到他的袖扣上刻着一只振翅的鹰——罗斯巴特家族的徽记。"
            if oamelInLobby then
                text = text .. "\n\n伯爵的脚步声消失在楼梯拐角后，奥梅尔才缓缓吐出一口气。"
                    .. "他像什么都没发生似的继续调酒，但你注意到他握着调酒壶的指节泛白。\n"
                    .. "「……别看了。」他头也不抬地低声说，「那位大人是来谈生意的，跟我没关系。」\n"
                    .. "他的语气平淡得有些刻意。"
            end
        else
            local scenes = {
                "阿斯特又来了。他跟上次一样，由随从簇拥着径直上了楼。"
                    .. "梅菲斯亲自在楼梯口迎接，两人低声交谈了几句，神色都很严肃。"
                    .. "你隐约听到「季度」「份额」之类的字眼。\n\n"
                    .. "楼下的赌客们照例安分了许多。似乎每个人都知道——"
                    .. "伯爵在的时候，最好不要惹出任何麻烦。",
                "罗斯巴特伯爵今天带了更多的人。除了两个老面孔的随从外，"
                    .. "还有一个夹着公文包的瘦高男人，看起来像是律师或者会计。\n\n"
                    .. "梅菲斯迎上去的时候，笑容比往常收敛了几分——看来今天的生意分量不轻。"
                    .. "几个人很快消失在楼上。你注意到，伯爵上楼前回头看了一眼吧台方向，"
                    .. "但奥梅尔恰好转身去取酒瓶，并没有对上那个目光。",
                "大门推开的瞬间，你已经能凭那股檀木香水的味道认出来者——"
                    .. "阿斯特。今天他穿着一件剪裁利落的黑色大衣，"
                    .. "左手无名指上多了一枚你以前没见过的戒指，暗红色的宝石在灯光下闪烁。\n\n"
                    .. "梅菲斯迎上前去，两人握手时交换了一个意味深长的眼神。"
                    .. "「楼上请。今天有件事需要当面确认。」梅菲斯压低了声音说。\n\n"
                    .. "伯爵点点头，大步流星地朝楼梯走去。他的步伐沉稳有力，每一步都透着不容质疑的自信。",
            }
            text = text .. "\n\n" .. scenes[math.random(1, #scenes)]

            if S.mqStage and S.mqStage >= 7 then
                text = text .. "\n\n你想起了奥梅尔委托你调查他父亲行踪的事。"
                    .. "阿斯特频繁来这里……真的只是谈生意吗？"
                    .. "他上楼时的表情太过严肃，不像是在处理普通的商务。"
            end

            if oamelInLobby then
                text = text .. "\n\n奥梅尔沉默地擦着酒杯，一言不发。"
                    .. "你注意到他的视线一直追随着父亲的背影，直到楼梯拐角把那道身影完全遮住。"
            end
        end
    end

    local choices = {}

    -- 小奥互动
    if oamelInLobby then
        table.insert(choices, { text = "💬 和罗斯巴特少爷聊聊", action = function()
            if not S.metOamelFirst then
                S.metOamelFirst = true
                S.mannerLevel = (S.mannerLevel or 0) + 1
                S.historyLevel = (S.historyLevel or 0) + 1
            end
            addOamelAffection(3)
            return "妖精的邀请"
        end })

        -- 关键词聊天（奥梅尔）
        table.insert(choices, { text = "🗨️ 聊聊见闻", action = function()
            S._keywordChatChar = "oamel"
            S._keywordChatReturn = "妖精的邀请"
            return "keyword_chat_select"
        end })

        -- 借钱
        if (S.oamelLevel or 1) >= 2 and not S.oamelLoanUsed and (S.money or 0) < (S.rentDue or 100) then
            table.insert(choices, { text = "💰 借钱应急", action = function()
                S.money = (S.money or 0) + 200
                S.oamelLoanUsed = true
                addDateLog("奥梅尔·罗斯巴特", "借钱", "借了200金币应急。他说不用还。")
                TimeSystem.addMinutes(5)
                return "妖精的邀请"
            end })
        end
    end

    -- 梅菲斯互动
    if meifeiInLobby then
        table.insert(choices, { text = "💬 和梅菲斯聊聊", action = function()
            if not S.metManagerFirst then
                S.metManagerFirst = true
                GameState.showNotification("你与梅菲斯正式认识了。他是「妖精的邀请」的经理，举止从容，目光锐利。")
            end
            if (S.meifeiAffection or 0) >= 50 then
                addMeifeiAffection(8)
                addHistoryExp(3)
            elseif (S.meifeiAffection or 0) >= 20 then
                addMeifeiAffection(5)
                addHistoryExp(2)
            else
                addMeifeiAffection(3)
            end
            return "妖精的邀请"
        end })

        -- 关键词聊天（梅菲斯）
        table.insert(choices, { text = "🗨️ 和梅菲斯聊见闻", action = function()
            S._keywordChatChar = "meifei"
            S._keywordChatReturn = "妖精的邀请"
            return "keyword_chat_select"
        end })
    end

    -- 阿斯特在场时的互动
    if rosbatFatherPresent then
        if S.mqStage and S.mqStage >= 7 then
            table.insert(choices, { text = "🔍 趁机打探伯爵的来意", action = function()
                TimeSystem.addMinutes(15)
                S.rosbatFatherInvestigated = true
                local roll = math.random(1, 3)
                if roll == 1 then
                    GameState.showNotification(
                        "你装作不经意地在楼梯口附近转悠，竖起耳朵捕捉楼上传来的只言片语。\n\n"
                        .. "「……那批货的数量必须翻倍。」是阿斯特的声音，低沉而不容置疑。\n"
                        .. "「伯爵，翻倍的话，通道方面恐怕……」梅菲斯似乎有些为难。\n"
                        .. "「通道的事我来解决。你只管准备好货物和账目。」\n\n"
                        .. "脚步声朝楼梯口移来，你赶紧退回大堂坐下。"
                        .. "什么货需要翻倍？什么通道？这些话听起来可不像是正常的生意。"
                    )
                elseif roll == 2 then
                    GameState.showNotification(
                        "你找了个借口靠近楼梯，正好撞见伯爵的一个随从下来取东西。\n"
                        .. "他手里拿着一个扁平的皮匣子，里面隐约露出蜡封信件的一角。\n"
                        .. "信封上有一个你看不太清的纹章——似乎不是罗斯巴特家族的鹰徽。\n\n"
                        .. "随从警觉地瞪了你一眼，加快脚步上了楼。\n"
                        .. "那枚纹章……你总觉得在哪里见过。"
                    )
                else
                    GameState.showNotification(
                        "你向一个端茶上楼的侍从随口打听：「楼上谈的什么生意啊？」\n"
                        .. "侍从压低声音：「不知道，但每次伯爵来都要锁上门，不让我们靠近。」\n"
                        .. "他左右看了看，补了一句：「上次我进去收茶具的时候，"
                        .. "桌上的地图被匆忙盖住了。好像标的是南边的什么地方。」\n\n"
                        .. "南边……暗教会在南部港口的活动不是最近才暴露的吗？"
                    )
                end
                return "妖精的邀请"
            end })
        else
            table.insert(choices, { text = "🤔 留意伯爵的动向", action = function()
                TimeSystem.addMinutes(10)
                local descs = {
                    "你坐在大堂角落，假装翻看一本放在茶几上的旧杂志，"
                        .. "眼角余光留意着楼上的动静。\n\n"
                        .. "大约过了二十分钟，阿斯特从楼上下来，脸色比上去时沉了几分。"
                        .. "他跟梅菲斯简短地说了几句话，然后带着随从大步离开。"
                        .. "梅菲斯目送他出门，若有所思地摸了摸下巴。\n\n"
                        .. "贵族的生意——你还是不去多想为好。",
                    "你端着酒杯在大堂慢慢喝，观察着进进出出的人。\n"
                        .. "楼上不时传来模糊的交谈声，听不清内容，但语气时而激烈时而平缓。\n\n"
                        .. "约莫半个时辰后，伯爵的随从先走了出来，每人手里都拿着一份文件。"
                        .. "最后阿斯特才出现，他跟梅菲斯握了握手，表情算不上满意，"
                        .. "但也不算太糟。\n\n「下个月见。」伯爵丢下一句话就走了。",
                }
                GameState.showNotification(descs[math.random(1, #descs)])
                return "妖精的邀请"
            end })
        end
    end

    -- 打听莱恩
    table.insert(choices, { text = "🔍 打听莱恩", action = function()
        S.secretNote = true
        TimeSystem.addMinutes(5)
        return "妖精的邀请"
    end })

    -- 赌博
    table.insert(choices, { text = "🎲 赌一把（-50金币）", action = function()
        if S.money >= 50 then
            S.money = S.money - 50
            local roll = math.random(1, 100)
            if roll <= 30 then
                local descs = {
                    "骰子在绿毡上滚了好几圈，最终停下来。你的心跟着一沉——点数差了那么一点点。"
                    .. "荷官面无表情地伸出手，用长杆把你的筹码划到庄家那一边。"
                    .. "周围几个赌客朝你投来同情的目光，但很快又把注意力转回了自己的赌局。"
                    .. "你攥了攥拳头，站起身离开了赌桌。五十枚金币，就这么没了。\n(-50金币)",
                    "你把筹码推到桌面上，骰子在手心里翻了个花，然后甩了出去。"
                    .. "骰子跳动着，撞到桌沿弹了回来，慢慢停下。你凑近一看——输了。"
                    .. "荷官的手像鹰爪一样迅速地把筹码收走，动作熟练得让人心里发凉。"
                    .. "旁边一个老赌客拍了拍你的肩：「赌场没有常胜将军，想开点。」\n(-50金币)",
                }
                GameState.showNotification(descs[math.random(1, #descs)])
            elseif roll <= 70 then
                S.money = S.money + 50
                local descs = {
                    "骰子停下时，你松了一口气——不赔不赚，刚好持平。"
                    .. "荷官把筹码推还给你，嘴角似乎勾了一下，像是在说「下次不一定有这么好运了」。"
                    .. "你把筹码收回口袋，心想还是见好就收吧。这种地方，能全身而退就算不错了。\n(+0金币)",
                    "骰子的结果出来了——平局。你和庄家各自收回了自己的筹码。"
                    .. "虽然没赚到什么，但至少也没亏。你端起旁边的水杯喝了一口，"
                    .. "稳了稳心神。赌桌上的气氛紧张而热烈，但你决定今天到此为止。\n(+0金币)",
                }
                GameState.showNotification(descs[math.random(1, #descs)])
            else
                S.money = S.money + 100
                local descs = {
                    "骰子在桌面上旋转了半天才停下来。你睁大眼睛看着点数——赢了！"
                    .. "荷官的表情终于出现了一丝裂缝，不情不愿地将双倍筹码推到你面前。"
                    .. "周围几个赌客啪啪鼓起掌来，有人吹了声口哨。"
                    .. "你把金灿灿的筹码收进口袋，觉得今晚的运气简直好得不像话。\n(+50金币)",
                    "「出了！出了！」你忍不住站起来——骰子停在了你押的点数上。"
                    .. "荷官沉默了一瞬，然后不紧不慢地数出双倍的筹码推给你。"
                    .. "旁边一个穿貂绒的胖商人朝你竖起大拇指：「小伙子好手气！」"
                    .. "你谦虚地笑了笑，但心里乐开了花。今天不虚此行。\n(+50金币)",
                }
                GameState.showNotification(descs[math.random(1, #descs)])
            end
            TimeSystem.addMinutes(15)
        else
            GameState.showNotification("金币不足！至少需要50金币才能上桌。")
        end
        return "妖精的邀请"
    end })

    -- 点酒
    table.insert(choices, { text = "🍸 点杯酒（-10金币）", action = function()
        if S.money >= 10 then
            S.money = S.money - 10
            GameState.modStat("satiety", 5)
            GameState.modStat("stress", -8)
            TimeSystem.addMinutes(15)
            local descs = {
                "侍从端上一只水晶高脚杯，里面的酒液呈渐变的橘红色，杯口用一片薄荷叶装饰。"
                .. "你啜饮一口——柑橘的酸甜最先涌上来，紧接着是烈酒的热辣在舌根扩散，"
                .. "最后是一丝蜂蜜的余韵缠绵不去。调酒师的手艺确实不凡。"
                .. "酒精的暖意从胃里向四肢蔓延，你靠在柔软的沙发椅背上，觉得整个人都松弛了下来。\n(饱食度+5, 压力-8)",
                "「今晚推荐的是「月光奏鸣曲」。」侍从把一杯泛着淡蓝色荧光的酒放在你面前。"
                .. "你好奇地端起来——酒液里似乎有细碎的银粉在缓缓沉浮，"
                .. "在灯光下看起来像一杯液态的星空。入口冰凉清冽，"
                .. "带着一种说不出的花香，像是把一整个春天的夜晚喝进了肚子。"
                .. "你一口一口慢慢品着，觉得这十枚铜币花得心甘情愿。\n(饱食度+5, 压力-8)",
                "你随手一指酒牌上的一款「落日熔金」。不多时，一杯金红色的鸡尾酒端了上来，"
                .. "杯壁上凝着一层细密的露珠。你凑近闻了闻——肉桂、丁香和一丝不易察觉的烟熏味。"
                .. "第一口入喉时有些呛，但很快回甘就追了上来，温暖而醇厚。"
                .. "你晃了晃杯子，看着酒液在灯光下流动，觉得花街的夜晚也没那么无聊。\n(饱食度+5, 压力-8)",
            }
            GameState.showNotification(descs[math.random(1, #descs)])
        else
            GameState.showNotification("金币不足！")
        end
        return "妖精的邀请"
    end })

    -- 二楼
    if S.unlockLounge then
        table.insert(choices, { text = "🚪 上二楼", target = "贵族休息室" })
    end

    -- 晚宴
    if not S.banquetAttendedThisWeek and S.hour >= 19 and S.hour < 23 then
        table.insert(choices, { text = "🎭 参加今晚的晚宴", action = function()
            S.banquetTheme = 0
            S.banquetStage = ""
            S.tip = 0
            return "晚宴"
        end })
    end

    table.insert(choices, { text = "🚪 离开", target = "花街" })

    return { text = text, choices = choices }
end

---===================== 白鸦书屋 =====================
--- Twine pid 33: 忠实原文


handlers["白鸦书屋"] = function(S)
    local text = "白鸦书屋\n\n"
        .. "推开雕刻着符文的老旧木门，淡淡的魔法气息扑面而来。"
        .. "店内光线昏暗，书架错落有致，一些书脊上浮动着微弱的荧光。\n\n"
        .. "柜台后坐着一位穿着灰色长袍的魔法师，兜帽遮住了大半张脸，"
        .. "正静静翻阅着一本泛黄的古籍，对进门的你毫无反应。\n\n"
        .. "一只羽毛漆黑、眼睛金黄的乌鸦站在柜台上，歪着头看你。\n\n"
        .. "「咕——客人想要什么书？」乌鸦忽然开口，声音沙哑却清晰，翅膀扑棱了一下。\n\n"
        .. "魔法师依旧没抬头，但你感觉到他微微侧了侧耳朵。"

    local choices = {}

    if not S.hasMannerBook then
        table.insert(choices, { text = "📖 《贵族礼仪入门》 - 50金币", action = function()
            if S.money >= 50 then
                S.money = S.money - 50; S.hasMannerBook = true; TimeSystem.addMinutes(5)
                GameState.showNotification("购买了《贵族礼仪入门》！")
            else
                GameState.showNotification("金币不足！")
            end
            return "白鸦书屋"
        end })
    end
    if not S.hasHistoryBook then
        table.insert(choices, { text = "📜 《日轮王国贵族名录》 - 50金币", action = function()
            if S.money >= 50 then
                S.money = S.money - 50; S.hasHistoryBook = true; TimeSystem.addMinutes(5)
                GameState.showNotification("购买了《日轮王国贵族名录》！")
            else
                GameState.showNotification("金币不足！")
            end
            return "白鸦书屋"
        end })
    end
    if not S.hasOsmiaBook then
        table.insert(choices, { text = "📚 《奥丝米娅时代的历史》 - 80金币", action = function()
            if S.money >= 80 then
                S.money = S.money - 80; S.hasOsmiaBook = true; TimeSystem.addMinutes(5)
                GameState.showNotification("购买了《奥丝米娅时代的历史》！")
            else
                GameState.showNotification("金币不足！")
            end
            return "白鸦书屋"
        end })
    end
    if not S.hasBotanyBook then
        table.insert(choices, { text = "🌿 《野外草药图鉴》 - 60金币", action = function()
            if S.money >= 60 then
                S.money = S.money - 60; S.hasBotanyBook = true; TimeSystem.addMinutes(5)
                GameState.showNotification("购买了《野外草药图鉴》！")
            else
                GameState.showNotification("金币不足！")
            end
            return "白鸦书屋"
        end })
    end
    if not S.hasRepairBook then
        table.insert(choices, { text = "🔧 《机械修理入门》 - 60金币", action = function()
            if S.money >= 60 then
                S.money = S.money - 60; S.hasRepairBook = true; TimeSystem.addMinutes(5)
                GameState.showNotification("购买了《机械修理入门》！")
            else
                GameState.showNotification("金币不足！")
            end
            return "白鸦书屋"
        end })
    end
    table.insert(choices, { text = "🔙 离开", target = "主城区" })

    return { text = text, choices = choices }
end

---===================== 贵族休息室 =====================
--- Twine pid 34: 忠实原文


handlers["贵族休息室"] = function(S)
    local text = "二楼 · 贵族休息室\n\n"
        .. "二楼比楼下安静许多。走廊铺着厚厚的地毯，墙上的油画记录着罗斯巴特家族的荣耀。"
        .. "你走到办公室门口，敲了敲门。\n\n"
        .. "「进来。」里面传来罗斯巴特少爷的声音。\n\n"
        .. "你推门进去。办公室不大，但布置考究：红木书桌、皮质沙发、整面墙的书柜。"
        .. "罗斯巴特少爷正靠在椅背上，手里拿着一本账册。"

    if S.hour >= 5 and S.hour < 10 then
        text = text .. "\n\n他看起来刚睡醒，头发有些凌乱，领结松松地挂着。「这么早？」他打了个哈欠。"
    else
        text = text .. "\n\n他放下账册，看着你：「又来了？」"
    end

    local choices = {}

    table.insert(choices, { text = "💬 聊天", action = function()
        TimeSystem.addMinutes(15)
        return "贵族休息室"
    end })
    table.insert(choices, { text = "🎲 下棋", action = function()
        addOamelAffection(3)
        TimeSystem.addMinutes(60)
        return "贵族休息室"
    end })
    table.insert(choices, { text = "📚 书柜", target = "贵族休息室_书柜" })
    table.insert(choices, { text = "🔙 下楼", target = "妖精的邀请" })

    return { text = text, choices = choices }
end

---===================== 贵族休息室_书柜 =====================


handlers["贵族休息室_书柜"] = function(S)
    local text = "书架上整齐地排列着各类典籍。罗斯巴特少爷靠在椅背上：「想看什么？」"
    local choices = {}

    -- 调酒笔记
    if S.hasBartenderNote then
        local count = S.bartenderNoteReadCount or 0
        local done = count >= 4
        table.insert(choices, { text = (done and "✅ " or "🍸 ") .. "K的调酒笔记  (" .. math.min(count, 4) .. "/4)", action = function()
            local result = WorkSystem.readBartenderNote()
            GameState.showNotification(result)
            return "贵族休息室_书柜"
        end })
    end

    -- 动态列出所有已拥有的书
    if WorkSystem.bookOrder then
        for _, bookId in ipairs(WorkSystem.bookOrder) do
            local info = WorkSystem.bookInfo[bookId]
            if info and S[info.hasVar] then
                local count = S[info.readCountVar] or 0
                local progress = math.min(count, 4)
                local done = progress >= 4
                local label = (done and "✅ " or "📖 ") .. info.fullName .. "  (" .. progress .. "/4)"
                table.insert(choices, { text = label, action = function()
                    local result = WorkSystem.readBook(bookId)
                    GameState.showNotification(result)
                    return "贵族休息室_书柜"
                end })
            end
        end
    end

    table.insert(choices, { text = "🔙 离开", target = "贵族休息室" })
    return { text = text, choices = choices }
end

---===================== 晚宴 =====================
--- Twine pid 30


end
