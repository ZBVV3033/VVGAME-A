-- systems/townlife/Events.lua
-- Extracted getEvents logic from TownLife

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local BattleSystem = require("systems.BattleSystem")
local CommonUtils = require("utils.CommonUtils")

local Events = {}

function Events.getEvents(location, TownLife)
    local S = GameState.state
    local period = getTimePeriod()
    local extraText = ""
    local extraChoices = {}

    -- ============ 十字路口 ============
    if location == "十字路口" then

        -- 达里奥弹琴 (下午/傍晚, 40%)
        if (period == "afternoon" or period == "evening") and chance(40) and tryEvent("dario_play") then
            if not S.npcDarioMet then
                extraText = extraText .. "\n\n一个戴宽檐帽的年轻人坐在路边弹吉他，旋律悠扬。\n周围聚了几个路人驻足聆听。"
                table.insert(extraChoices, {
                    text = "🎵 走近听一会儿",
                    target = "小镇_遇见达里奥",
                })
            else
                extraText = extraText .. "\n\n达里奥又在老地方弹吉他了。今天的曲子听起来格外欢快。"
                table.insert(extraChoices, {
                    text = "🎵 跟达里奥聊聊",
                    target = "小镇_达里奥闲聊",
                })
            end
        end

        -- 莱德×K互动 (莱德未受邀 & K已认识, 20%)
        if not S.initialNameInvited and S.kMet and chance(20) and tryEvent("leide_k_cross") then
            extraText = extraText .. "\n\n你注意到" .. S.initialName .. "正和一个银发的人说话——是K？\n两人似乎在争论什么，但氛围并不紧张。"
            table.insert(extraChoices, {
                text = "👀 凑过去看看他们在聊什么",
                target = "小镇_莱德K闲聊",
            })
        end

        -- 艾琳写生 (上午, 30%)
        if period == "morning" and chance(30) and tryEvent("eileen_sketch_cross") then
            if not S.npcEileenMet then
                extraText = extraText .. "\n\n路边有个红发女孩正对着街景画画，画板上的十字路口栩栩如生。"
                table.insert(extraChoices, {
                    text = "🎨 走过去看她画画",
                    target = "小镇_遇见艾琳",
                })
            else
                extraText = extraText .. "\n\n艾琳坐在路边专注地写生，手指沾满了颜料。"
            end
        end

        -- 小梅卖鱼路过 (上午, 35%)
        if period == "morning" and chance(35) and tryEvent("xiaomei_cross") then
            if not S.npcXiaomeiMet then
                extraText = extraText .. "\n\n一个扎马尾的少女推着满满一车鲜鱼走过十字路口，\n大声吆喝着：'新鲜的海鱼嘞——今早刚到的！'"
                table.insert(extraChoices, {
                    text = "🐟 走过去看看",
                    target = "小镇_遇见小梅",
                })
            else
                extraText = extraText .. "\n\n小梅推着鱼车经过，看到你大声打招呼：'嘿！今天的鱼特别肥！'"
                table.insert(extraChoices, {
                    text = "🐟 跟小梅聊几句",
                    target = "小镇_小梅闲聊",
                })
            end
        end

        -- 贾斯帕巡夜 (傍晚/夜晚, 40%)
        if (period == "evening" or period == "night") and chance(40) and tryEvent("jasper_cross") then
            if not S.npcJasperMet then
                extraText = extraText .. "\n\n暮色中，一个提着旧灯笼的沉默男子从街角走过。\n他的脚步很轻，灯笼的光在石板路上投下摇晃的影子。"
                table.insert(extraChoices, {
                    text = "🏮 跟上去看看",
                    target = "小镇_遇见贾斯帕",
                })
            else
                extraText = extraText .. "\n\n贾斯帕提着灯笼走过来。他朝你微微点了点头，算是打了招呼。"
                table.insert(extraChoices, {
                    text = "🏮 跟贾斯帕走一段",
                    target = "小镇_贾斯帕闲聊",
                })
            end
        end

        -- 【支线触发】深夜守望 (夜晚, 贾斯帕已认识, quest未触发, 25%)
        if period == "night" and S.npcJasperMet and (S.quest_watchman or 0) == 0
            and chance(25) and tryEvent("quest_watchman_trigger") then
            extraText = extraText .. "\n\n贾斯帕急匆匆地走过来，表情严肃。他压低声音，似乎有什么要紧的事。"
            table.insert(extraChoices, {
                text = "🏮 「怎么了？」",
                target = "支线_深夜守望",
            })
        end

        -- 达里奥即兴合唱 (傍晚, 达里奥已认识且好感>=20, 20%)
        if period == "evening" and S.npcDarioMet and (S.npcDario or 0) >= 20
            and chance(20) and tryEvent("dario_duet") then
            extraText = extraText .. "\n\n达里奥看到你，眼睛一亮：「嘿！正好！我新写了一首歌，需要有人帮我和声。来来来！」"
            table.insert(extraChoices, {
                text = "🎵 和达里奥合唱一曲",
                target = "小镇_达里奥合唱",
            })
        end

        -- 【城内战斗】小偷抢包 (傍晚/夜晚, 每日限2次, 20%)
        if (period == "evening" or period == "night") and (S.townBattleToday or 0) < 2
            and chance(20) and tryEvent("town_battle_thief") then
            extraText = extraText .. "\n\n「抓小偷啊！！」一个妇人尖叫着追出来。\n一个身影灵活地在人群中穿梭，手里还攥着什么东西。"
            table.insert(extraChoices, {
                text = "⚔️ 拦住那个小偷！",
                target = "城内治安_小偷",
            })
        end

        -- 【切磋入口】莱德在十字路口练剑 (下午, 已入队即可, 今日未切磋, 30%)
        if period == "afternoon" and S.initialNameInParty and not S.sparringToday
            and chance(30) and tryEvent("leide_spar_cross") then
            extraText = extraText .. "\n\n" .. S.initialName .. "正在路边的空地上独自练剑。\n他的动作流畅而锐利，剑锋划过空气发出嗡嗡的声响。\n注意到你的目光，他停了下来。"
            table.insert(extraChoices, {
                text = "⚔️ 提议切磋一下",
                target = "切磋_提议",
            })
        end

        -- 路人小事件 (25%)
        if chance(25) and tryEvent("cross_flavor") then
            local flavors = {
                "\n\n一个小男孩追着蝴蝶跑过十字路口，差点撞到你。他的母亲慌忙道歉。",
                "\n\n远处传来钟声——是主城区教堂的整点报时。行人们习以为常地继续赶路。",
                "\n\n一辆马车飞驰而过，卷起一阵灰尘。赶车的人大声吆喝着'让开让开'。",
                "\n\n两个商人在路边讨价还价，声音越来越大，最后握手成交，一起去酒馆庆祝了。",
                "\n\n一只肥鸽子大摇大摆地在路中间散步，完全不理会来往的行人。",
            }
            extraText = extraText .. flavors[math.random(1, #flavors)]
        end

    -- ============ 商业区 ============
    elseif location == "商业区" then

        -- 艾琳卖画 (下午, 30%)
        if period == "afternoon" and chance(30) and tryEvent("eileen_sell") then
            if S.npcEileenMet then
                extraText = extraText .. "\n\n艾琳在街边摆了个小摊卖画。她冲你招了招手。"
                table.insert(extraChoices, {
                    text = "🎨 去看看艾琳的画",
                    target = "小镇_艾琳卖画",
                })
            else
                extraText = extraText .. "\n\n街角有个红发女孩在摆摊卖画，色彩斑斓的画作引来不少围观。"
                table.insert(extraChoices, {
                    text = "🎨 好奇地走过去",
                    target = "小镇_遇见艾琳",
                })
            end
        end

        -- 达里奥和辛奇互动 (傍晚, 25%)
        if period == "evening" and S.npcDarioMet and chance(25) and tryEvent("dario_sinchi") then
            extraText = extraText .. "\n\n达里奥抱着吉他靠在酒馆门口，辛奇端了一杯酒出来递给他。\n两人有说有笑的，看起来关系不错。"
        end

        -- K采购 (上午, 20%)
        if period == "morning" and S.kMet and chance(20) and tryEvent("k_shopping") then
            extraText = extraText .. "\n\nK提着一个布袋从杂货店走出来。\n她似乎在采购调酒用的材料，步伐轻快得不像是在干活。"
        end

        -- 费利克斯面包房 (上午/下午, 40%)
        if (period == "morning" or period == "afternoon") and chance(40) and tryEvent("felix_bakery") then
            if not S.npcFelixMet then
                extraText = extraText .. "\n\n空气中飘来一阵诱人的面包香气。\n循着香味望去，街角有一间小面包房，橱窗里摆满了金黄色的面包。"
                table.insert(extraChoices, {
                    text = "🍞 进去看看",
                    target = "小镇_遇见费利克斯",
                })
            else
                extraText = extraText .. "\n\n费利克斯的面包房又飘出了好闻的香气。他在门口擦手，朝你笑着招手。"
                table.insert(extraChoices, {
                    text = "🍞 去面包房坐坐",
                    target = "小镇_费利克斯闲聊",
                })
            end
        end

        -- 诺拉裁缝铺 (上午/下午, 35%)
        if (period == "morning" or period == "afternoon") and chance(35) and tryEvent("nora_tailor") then
            if not S.npcNoraMet then
                extraText = extraText .. "\n\n一间小店的门帘被风吹开，里面传来缝纫机嗒嗒的声响。\n透过窗户，能看到一个年轻女子正专注地裁剪布料。"
                table.insert(extraChoices, {
                    text = "🧵 进去瞧瞧",
                    target = "小镇_遇见诺拉",
                })
            else
                extraText = extraText .. "\n\n诺拉的裁缝铺门口挂着新做好的样品。她在里面缝东西，头也不抬地说：'进来啊，别杵门口。'"
                table.insert(extraChoices, {
                    text = "🧵 进去找诺拉聊聊",
                    target = "小镇_诺拉闲聊",
                })
            end
        end

        -- 【支线触发】失窃的画 (上午, 艾琳已认识, quest未触发, 30%)
        if period == "morning" and S.npcEileenMet and (S.quest_painting or 0) == 0
            and chance(30) and tryEvent("quest_painting_trigger") then
            extraText = extraText .. "\n\n你在巷口看到艾琳蹲在墙角，红发凌乱地遮住半张脸。她看起来很不对劲。"
            table.insert(extraChoices, {
                text = "🎨 走过去看看她怎么了",
                target = "支线_失窃的画",
            })
        end

        -- 【支线触发】消失的酵母 (上午, 费利克斯已认识且好感>=10, quest未触发, 25%)
        if period == "morning" and S.npcFelixMet and (S.npcFelix or 0) >= 10
            and (S.quest_sourdough or 0) == 0 and chance(25) and tryEvent("quest_sourdough_trigger") then
            extraText = extraText .. "\n\n费利克斯的面包房门口围了好几个人。他满脸焦急地搓着手，似乎出了什么事。"
            table.insert(extraChoices, {
                text = "🍞 过去看看怎么了",
                target = "支线_消失的酵母",
            })
        end

        -- 【支线触发】红婚纱 (下午, 诺拉已认识且好感>=15, quest未触发, 25%)
        if period == "afternoon" and S.npcNoraMet and (S.npcNora or 0) >= 15
            and (S.quest_reddress or 0) == 0 and chance(25) and tryEvent("quest_reddress_trigger") then
            extraText = extraText .. "\n\n诺拉的裁缝铺关着门，但透过窗缝你能看到里面的灯还亮着。隐约听到里面传来一声叹气。"
            table.insert(extraChoices, {
                text = "🧵 敲门看看诺拉怎么了",
                target = "支线_红婚纱",
            })
        end

        -- 费利克斯教烤面包 (上午, 费利克斯已认识且好感>=15, 20%)
        if period == "morning" and S.npcFelixMet and (S.npcFelix or 0) >= 15
            and chance(20) and tryEvent("felix_bake_teach") then
            extraText = extraText .. "\n\n费利克斯站在面包店门口，围裙上沾满面粉。他看到你，高兴地招了招手：「来得正好！今天做新品，要不要来学？」"
            table.insert(extraChoices, {
                text = "🍞 跟费利克斯学烤面包",
                target = "小镇_费利克斯教烤面包",
            })
        end

        -- 【支线触发】旧灯之约 (傍晚, 贾斯帕已认识且好感>=10, quest未触发, 25%)
        if period == "evening" and S.npcJasperMet and (S.npcJasper or 0) >= 10
            and (S.quest_oldlamp or 0) == 0 and chance(25) and tryEvent("quest_oldlamp_trigger") then
            extraText = extraText .. "\n\n贾斯帕一个人蹲在路灯下，正低头摆弄什么东西。走近了才看到——是他那盏旧灯笼，好像坏了。"
            table.insert(extraChoices, {
                text = "🏮 走过去看看",
                target = "支线_旧灯之约",
            })
        end

        -- 【城内战斗】醉汉闹事 (傍晚, 每日限2次, 20%)
        if period == "evening" and (S.townBattleToday or 0) < 2
            and chance(20) and tryEvent("town_battle_drunk") then
            extraText = extraText .. "\n\n一个壮硕的醉汉摇摇晃晃地走在街上，逢人就推搡。\n他一脚踢翻了水果贩子的摊位，嘴里还骂骂咧咧的。\n周围的人都不敢上前。"
            table.insert(extraChoices, {
                text = "⚔️ 上去制止这个醉汉",
                target = "城内治安_醉汉",
            })
        end

        -- 商业区热闹小事件 (30%)
        if chance(30) and tryEvent("biz_flavor") then
            local flavors = {
                "\n\n一个水果贩子大声吆喝：'新鲜的金苹果！刚从南边运来的！'围观的人不少。",
                "\n\n街角有人在表演魔术，一枚硬币在他指间消失又出现，引来阵阵掌声。",
                "\n\n两个妇人一边挑菜一边聊天，讨论着最近港口来了什么新货。",
                "\n\n一个小贩的推车翻了，橘子滚了一地。几个好心路人帮忙捡了起来。",
            }
            extraText = extraText .. flavors[math.random(1, #flavors)]
        end

    -- ============ 港口 ============
    elseif location == "港口" then

        -- 老尤金讲故事 (白天, 45%)
        if period ~= "night" and chance(45) and tryEvent("yugen_story") then
            if not S.npcOldYugenMet then
                extraText = extraText .. "\n\n码头边有个老人坐在木箱上，正绘声绘色地给几个渔民讲故事。\n'那一年暴风雨的夜晚——'他的声音沙哑但充满激情。"
                table.insert(extraChoices, {
                    text = "🌊 坐下来听老人讲故事",
                    target = "小镇_遇见老尤金",
                })
            else
                extraText = extraText .. "\n\n老尤金又在码头边讲故事了。今天围观的人比平时还多。"
                table.insert(extraChoices, {
                    text = "🌊 听老尤金讲故事",
                    target = "小镇_老尤金故事",
                })
            end
        end

        -- 莱德在港口搬货 x 黑胡子 (上午, 25%)
        if period == "morning" and S.initialNameInvited and chance(25) and tryEvent("leide_port") then
            extraText = extraText .. "\n\n你看到" .. S.initialName .. "正在帮黑胡子搬货。\n黑胡子拍了拍他的肩膀，说了句什么，" .. S.initialName .. "笑了起来。"
        end

        -- 奥梅尔×老尤金 (傍晚, 20%)
        if period == "evening" and S.metOamelFirst and S.npcOldYugenMet and chance(20) and tryEvent("oamel_yugen") then
            extraText = extraText .. "\n\n奥梅尔竟然坐在老尤金旁边听故事？\n贵族少爷居然也会对航海冒险感兴趣……他听得很认真。"
        end

        -- 小梅卖鱼 (上午, 45%)
        if period == "morning" and chance(45) and tryEvent("xiaomei_port") then
            if not S.npcXiaomeiMet then
                extraText = extraText .. "\n\n码头上有个扎马尾的少女在大声吆喝卖鱼。\n她动作麻利地挑鱼、称重、找零，忙得不亦乐乎。"
                table.insert(extraChoices, {
                    text = "🐟 去买条鱼",
                    target = "小镇_遇见小梅",
                })
            else
                extraText = extraText .. "\n\n小梅在鱼摊前忙活着。看到你，她用沾了鱼鳞的手指比了个OK：'今天的货特好！'"
                table.insert(extraChoices, {
                    text = "🐟 找小梅聊聊",
                    target = "小镇_小梅闲聊",
                })
            end
        end

        -- 【支线触发】海之声 (上午, 小梅已认识且好感>=10, quest未触发, 25%)
        if period == "morning" and S.npcXiaomeiMet and (S.npcXiaomei or 0) >= 10
            and (S.quest_seasong or 0) == 0 and chance(25) and tryEvent("quest_seasong_trigger") then
            extraText = extraText .. "\n\n小梅今天不在鱼摊上。有人说她一大早就跑到栈桥最远端去了，好像在看什么东西。"
            table.insert(extraChoices, {
                text = "🐚 去栈桥找小梅",
                target = "支线_海之声",
            })
        end

        -- 塞巴斯蒂安看海读书 (下午, 35%)
        if period == "afternoon" and chance(35) and tryEvent("sebastian_port") then
            if not S.npcSebastianMet then
                extraText = extraText .. "\n\n防波堤上坐着一个头发蓬乱的年轻人，旁边放着一个塞满了书的大背包。\n他对着大海翻书，偶尔在笔记本上写几行字。"
                table.insert(extraChoices, {
                    text = "📖 走过去搭话",
                    target = "小镇_遇见塞巴斯蒂安",
                })
            else
                extraText = extraText .. "\n\n塞巴斯蒂安又在防波堤上看书了。海风吹得书页哗哗作响，他用石头压住。"
                table.insert(extraChoices, {
                    text = "📖 去找塞巴斯蒂安",
                    target = "小镇_塞巴斯蒂安闲聊",
                })
            end
        end

        -- 老尤金秘密海湾 (傍晚, 老尤金已认识且好感>=25, 15%)
        if period == "evening" and S.npcOldYugenMet and (S.npcOldYugen or 0) >= 25
            and chance(15) and tryEvent("yugen_bay") then
            extraText = extraText .. "\n\n老尤金朝你使了个眼色，然后不动声色地朝码头西边走去。那里似乎通往一个你从未注意过的小海湾。"
            table.insert(extraChoices, {
                text = "🌊 跟着老尤金去看看",
                target = "小镇_老尤金海湾",
            })
        end

        -- 【城内战斗】走私贩交易 (夜晚, 每日限2次, 15%)
        if period == "night" and (S.townBattleToday or 0) < 2
            and chance(15) and tryEvent("town_battle_smuggler") then
            extraText = extraText .. "\n\n码头角落的阴影中，几个人正在进行某种交易。\n其中一个人发现了你的目光，神色紧张地朝你走来。\n「你看到了什么？」他的手伸向腰间。"
            table.insert(extraChoices, {
                text = "⚔️ 被迫应战",
                target = "城内治安_走私贩",
            })
        end

        -- 港口小事件 (30%)
        if chance(30) and tryEvent("port_flavor") then
            local flavors = {
                "\n\n一艘大帆船正在入港，水手们大声呼喊着，码头上忙碌起来。",
                "\n\n海鸥盘旋在头顶，偶尔俯冲下来抢渔民手里的鱼，惹来一阵骂声。",
                "\n\n几个孩子在码头边钓鱼，有人钓到一条大的，引来一阵欢呼。",
                "\n\n远处海面上有鲸鱼喷出的水柱，在阳光下闪着七彩的光。好美。",
            }
            extraText = extraText .. flavors[math.random(1, #flavors)]
        end

    -- ============ 花园小镇 ============
    elseif location == "花园小镇" then

        -- 莉莉安花店 (白天, 50%)
        if period ~= "night" and chance(50) and tryEvent("lillian_shop") then
            if not S.npcLillianMet then
                extraText = extraText .. "\n\n小镇入口有一家温馨的花店，橱窗里摆满了五颜六色的花束。\n一位温柔的女士正在修剪玫瑰。"
                table.insert(extraChoices, {
                    text = "🌹 走进花店看看",
                    target = "小镇_遇见莉莉安",
                })
            else
                extraText = extraText .. "\n\n莉莉安的花店今天摆出了新的花束。她远远看到你，微笑着打招呼。"
                table.insert(extraChoices, {
                    text = "🌹 去花店坐坐",
                    target = "小镇_莉莉安闲聊",
                })
            end
        end

        -- K在花园散步 (上午, 20%)
        if period == "morning" and S.kMet and chance(20) and tryEvent("k_garden") then
            extraText = extraText .. "\n\nK正在花丛间散步，银白色的长发在晨光中泛着柔光。\n她弯腰闻了闻一朵蓝色的花，表情难得地柔和。"
        end

        -- 莉莉安×麦拿拿互动 (下午, 20%)
        if S.npcLillianMet and S.npcMacnana > 0 and period == "afternoon" and chance(20) and tryEvent("lillian_mac") then
            extraText = extraText .. "\n\n莉莉安正在和麦拿拿说话。矮人铁匠手里捧着一个铁制的花架。\n'这次做得真漂亮！'莉莉安高兴地接过来，麦拿拿不好意思地挠了挠头。"
        end

        -- 伊莎贝拉采草药 (上午, 40%)
        if period == "morning" and chance(40) and tryEvent("isabella_garden") then
            if not S.npcIsabellaMet then
                extraText = extraText .. "\n\n花园深处，一个围着深绿围裙的年轻女子蹲在草丛里。\n她小心翼翼地摘着什么植物，放进随身携带的竹篮中。"
                table.insert(extraChoices, {
                    text = "🌿 好奇地走过去",
                    target = "小镇_遇见伊莎贝拉",
                })
            else
                extraText = extraText .. "\n\n伊莎贝拉在花丛中采集草药。她抬头看了你一眼，轻轻点了点头。"
                table.insert(extraChoices, {
                    text = "🌿 去找伊莎贝拉",
                    target = "小镇_伊莎贝拉闲聊",
                })
            end
        end

        -- 诺拉买布料 (下午, 30%)
        if period == "afternoon" and S.npcNoraMet and chance(30) and tryEvent("nora_garden") then
            extraText = extraText .. "\n\n诺拉提着一袋子布料从小镇集市走出来。\n她仔细检查着手里的料子，嘴里嘀咕着：'这个染色还行……这个差点意思。'"
        end

        -- 莉莉安教插花 (下午, 莉莉安已认识且好感>=20, 20%)
        if period == "afternoon" and S.npcLillianMet and (S.npcLillian or 0) >= 20
            and chance(20) and tryEvent("lillian_flower_arrange") then
            extraText = extraText .. "\n\n莉莉安正在花丛边摆弄着一束刚剪下来的花，色彩搭配精妙绝伦。她看到你，露出了温柔的微笑：「要不要学几招？插花可是修身养性的好方法。」"
            table.insert(extraChoices, {
                text = "🌸 跟莉莉安学插花",
                target = "小镇_莉莉安插花",
            })
        end

        -- 【支线触发】月光草 (下午, 伊莎贝拉已认识且好感>=15, quest未触发, 20%)
        if period == "afternoon" and S.npcIsabellaMet and (S.npcIsabella or 0) >= 15
            and (S.quest_moongrass or 0) == 0 and chance(20) and tryEvent("quest_moongrass_trigger") then
            extraText = extraText .. "\n\n伊莎贝拉蹲在路边的花圃前，手里握着一株枯萎的银色小草，眉头紧锁。她看起来很少见地焦虑。"
            table.insert(extraChoices, {
                text = "🌿 走过去问问她怎么了",
                target = "支线_月光草",
            })
        end

        -- 花园小事件 (30%)
        if chance(30) and tryEvent("garden_flavor") then
            local flavors = {
                "\n\n几只蝴蝶在花丛中翩翩起舞，像是一场无声的舞会。",
                "\n\n喷泉边有个老人在下棋，对手是他自己——两边都下得很认真。",
                "\n\n一阵微风吹过，花瓣漫天飞舞。有个小女孩张开双臂在花瓣雨中旋转。",
                "\n\n远处传来悠扬的笛声，不知道是谁在演奏，但旋律令人心旷神怡。",
            }
            extraText = extraText .. flavors[math.random(1, #flavors)]
        end

    -- ============ 主城区 ============
    elseif location == "主城区" then

        -- 薇拉奶奶喂鸽子 (上午/下午, 45%)
        if (period == "morning" or period == "afternoon") and chance(45) and tryEvent("vera_pigeons") then
            if not S.npcGrandmaVeraMet then
                extraText = extraText .. "\n\n教堂广场上，一位穿着朴素的老太太正在喂鸽子。\n鸽子们毫不怕人地围在她脚边，她笑得很慈祥。"
                table.insert(extraChoices, {
                    text = "🕊️ 走过去和老太太聊聊",
                    target = "小镇_遇见薇拉奶奶",
                })
            else
                extraText = extraText .. "\n\n薇拉奶奶又在广场上喂鸽子了。她看到你，招手让你过去坐坐。"
                table.insert(extraChoices, {
                    text = "🕊️ 去陪薇拉奶奶聊天",
                    target = "小镇_薇拉奶奶闲聊",
                })
            end
        end

        -- 克丽丝×薇拉奶奶 (上午, 20%)
        if period == "morning" and S.npcClarice > 0 and S.npcGrandmaVeraMet and chance(20) and tryEvent("clarice_vera") then
            extraText = extraText .. "\n\n克丽丝端着一杯热茶从教堂走出来，递给广场上的薇拉奶奶。\n两人坐在长椅上聊着天，画面十分温馨。"
        end

        -- 梅菲斯路过主城 (傍晚, 15%)
        if period == "evening" and S.metManagerFirst and chance(15) and tryEvent("meifei_main") then
            extraText = extraText .. "\n\n你瞥见梅菲斯从一条小巷走出来，身后跟着两个低着头的人。\n他注意到你的视线，意味深长地笑了笑，然后转身消失在街角。"
        end

        -- 伊莎贝拉送药 (下午, 35%)
        if period == "afternoon" and chance(35) and tryEvent("isabella_main") then
            if not S.npcIsabellaMet then
                extraText = extraText .. "\n\n教堂门口，一个围着绿围裙的年轻女子提着一篮草药走进去。\n门口的修女接过篮子，感激地点了点头。"
                table.insert(extraChoices, {
                    text = "🌿 跟进去看看",
                    target = "小镇_遇见伊莎贝拉",
                })
            else
                extraText = extraText .. "\n\n伊莎贝拉正在教堂门口和克丽丝交接草药。她看到你，微微颔首。"
                table.insert(extraChoices, {
                    text = "🌿 过去打个招呼",
                    target = "小镇_伊莎贝拉闲聊",
                })
            end
        end

        -- 塞巴斯蒂安在白鸦书屋 (上午, 35%)
        if period == "morning" and chance(35) and tryEvent("sebastian_main") then
            if not S.npcSebastianMet then
                extraText = extraText .. "\n\n白鸦书屋门口坐着一个头发蓬乱的年轻人。\n他面前摊着好几本书，正在飞快地做笔记，完全沉浸在自己的世界里。"
                table.insert(extraChoices, {
                    text = "📖 上前搭话",
                    target = "小镇_遇见塞巴斯蒂安",
                })
            else
                extraText = extraText .. "\n\n塞巴斯蒂安靠在书屋外墙上看书。他的大背包就放在脚边，看起来随时准备出发。"
                table.insert(extraChoices, {
                    text = "📖 找塞巴斯蒂安聊聊",
                    target = "小镇_塞巴斯蒂安闲聊",
                })
            end
        end

        -- 【支线触发】薇拉的秘密 (下午, 薇拉已认识且好感>=20, quest未触发, 20%)
        if period == "afternoon" and S.npcGrandmaVeraMet and (S.npcGrandmaVera or 0) >= 20
            and (S.quest_vera or 0) == 0 and chance(20) and tryEvent("quest_vera_trigger") then
            extraText = extraText .. "\n\n薇拉奶奶今天看起来有些不同。她坐在长椅上，手里没有像往常那样拿着鸽食，而是攥着一本破旧的小册子，目光远远地望着什么。"
            table.insert(extraChoices, {
                text = "📖 走过去关心一下她",
                target = "支线_薇拉的秘密",
            })
        end

        -- 薇拉展示魔法小技巧 (上午, 薇拉已认识且好感>=30, 20%)
        if period == "morning" and S.npcGrandmaVeraMet and (S.npcGrandmaVera or 0) >= 30
            and chance(20) and tryEvent("vera_magic_trick") then
            extraText = extraText .. "\n\n薇拉奶奶朝你招招手，神秘兮兮地笑了笑：「过来，让我给你看个有趣的东西。」她的手指间似乎有微光闪烁。"
            table.insert(extraChoices, {
                text = "✨ 看薇拉奶奶表演",
                target = "小镇_薇拉魔法",
            })
        end

        -- 小奥闲逛主城区 (下午/傍晚, 已认识, 20%)
        if (period == "afternoon" or period == "evening") and S.metOamelFirst
            and chance(20) and tryEvent("oamel_main_stroll") then
            local oamelAff = S.oamelAffection or 0
            if oamelAff >= 50 then
                extraText = extraText .. "\n\n你在广场的长椅上看见了奥梅尔。"
                    .. "他靠在椅背上，手里拿着一本薄薄的诗集，红发在午后的光线下泛着暖铜色。"
                    .. "\n\n看到你走过来，他合上书，嘴角微扬："
                    .. "「别露出那种表情，贵族也是会读书的。」"
                    .. "他拍了拍旁边的位子：「坐吧。今天妖精的邀请歇业，难得清闲。」"
                table.insert(extraChoices, {
                    text = "🪑 坐下来和奥梅尔聊聊",
                    action = function()
                        TimeSystem.addMinutes(15)
                        S.oamelAffection = (S.oamelAffection or 0) + 5
                        GameState.showNotification(
                            "你坐在奥梅尔旁边。他给你倒了杯从街角茶馆买来的红茶。\n\n"
                            .. "「知道吗，小时候我特别讨厌这个广场。」他望着来来往往的行人，\n"
                            .. "「太吵了，到处都是……各种人。」\n\n"
                            .. "他喝了口茶，语气变得平淡：「现在倒觉得……有点意思。\n"
                            .. "妖精的邀请里那些人，表面上恭恭敬敬，心里想的全是怎么从你身上捞好处。\n"
                            .. "这里的人不一样。他们不认识我，也不在乎我是谁。」\n\n"
                            .. "你们聊了一会儿。奥梅尔说起最近在读的一本游记，\n"
                            .. "关于南方海域的岛屿和那里的奇异风俗。说到兴起处，\n"
                            .. "他的眼睛亮了起来，少见地没有摆出那副高人一等的样子。\n\n"
                            .. "「哪天有机会的话，真想去南方看看。」他说完，\n"
                            .. "又恢复了惯常的表情：「当然，等我把手上的事情处理完再说。」\n\n"
                            .. "(奥梅尔好感+5)"
                        )
                        return "主城区"
                    end,
                })
            elseif oamelAff >= 20 then
                extraText = extraText .. "\n\n一辆黑色马车停在广场边上，车门上刻着蔷薇纹章——罗斯巴特家的。"
                    .. "\n\n奥梅尔从马车上跳下来，对车夫摆了摆手。"
                    .. "他今天穿着一件剪裁考究的深蓝色外套，红发整齐地梳到脑后，"
                    .. "看起来像是刚办完什么正事。"
                    .. "\n\n他在一家茶馆前站定，推门走了进去。透过玻璃窗，能看到他点了一壶茶，"
                    .. "然后掏出一叠文件开始翻看。偶尔皱眉，偶尔在纸上写几笔。"
                    .. "\n\n你从窗外走过时，他恰好抬头，视线交错了一瞬。"
                    .. "他微微点了点头，算是打了个招呼，然后又低下头继续看文件。"
            else
                extraText = extraText .. "\n\n你远远看见一个红发青年在广场上走过。"
                    .. "他身边跟着一个毕恭毕敬的仆从，替他拎着几个精致的纸袋。"
                    .. "\n\n是奥梅尔·罗斯巴特。他偶尔停下来，挑剔地看看路边店铺橱窗里的东西，"
                    .. "然后轻轻摇头走开。"
                    .. "\n\n仆从连忙追上去：「少爷，那家新开的帽子店评价不错——」"
                    .. "\n\n「款式太俗了。」奥梅尔头也不回地说。仆从习以为常地闭上嘴，默默跟在后面。"
                    .. "\n\n路过的行人偷偷看他，交头接耳：「那是罗斯巴特家的少爷吧？」"
                    .. "「听说在花街那边调酒呢。」「贵族调酒？怕不是闹着玩的吧。」"
            end
        end

        -- 阿斯特在主城区 (上午/下午, 10%, Ch3揭秘前)
        if (period == "morning" or period == "afternoon") and not S.mq3FatherSecret
            and chance(10) and tryEvent("rosbat_father_main") then
            S.rosbatFatherMainCount = (S.rosbatFatherMainCount or 0) + 1
            if S.rosbatFatherMainCount == 1 then
                extraText = extraText .. "\n\n一辆装饰华丽的四马马车从广场穿过，"
                    .. "车身上绘着金色的蔷薇纹章。两侧各有两名持剑骑士护卫。"
                    .. "\n\n马车停在市政厅门前，一个穿深红色大衣的中年男人走了下来。"
                    .. "他身材高大，留着修剪整齐的络腮胡，红发比奥梅尔的颜色深沉许多，"
                    .. "步伐沉稳而有力，每一步都像是踩在别人看不见的红毯上。"
                    .. "\n\n广场上的人纷纷让路，有人低声议论：「那是罗斯巴特家的家主……」"
                    .. "「听说他最近跟北方的矿主们在谈一笔大买卖。」"
                    .. "「嘘，别让他听见。那个人的眼睛比鹰还尖。」"
                    .. "\n\n阿斯特抬头扫了一眼广场，目光在你身上停留了一瞬——"
                    .. "然后收回视线，大步走进了市政厅的大门。"
                    .. "\n\n那一瞬间的审视让你后背微微发凉。"
                    .. "一旁的薇拉奶奶叹了口气：「罗斯巴特家的人啊……"
                    .. "老的深不可测，小的傲气冲天。这一家子，从来不让人省心。」"
            elseif S.mqStage and S.mqStage >= 7 then
                extraText = extraText .. "\n\n你又看到了阿斯特。这次他没有乘马车，"
                    .. "而是穿着一件不太显眼的灰色长袍，帽檐压得很低。"
                    .. "\n\n如果不是你之前见过他，几乎认不出来。"
                    .. "他快步走进一条僻静的小巷，身后没有护卫。"
                    .. "\n\n你想起奥梅尔让你调查他父亲行踪的事……"
                    .. "这身装扮，这种行动方式——他在隐瞒什么？"
                table.insert(extraChoices, {
                    text = "🔍 悄悄跟上去看看",
                    action = function()
                        TimeSystem.addMinutes(20)
                        S.rosbatFatherFollowed = true
                        GameState.showNotification(
                            "你远远地跟在阿斯特身后，小心翼翼地保持距离。\n\n"
                            .. "他七拐八拐，走进了主城区北面的一条死胡同。\n"
                            .. "你躲在拐角处，看见他在一扇没有招牌的门前站定。\n\n"
                            .. "他轻轻敲了三下——停顿——再敲两下。\n"
                            .. "门开了一条缝，一只戴手套的手伸出来，接过阿斯特递过去的一个信封。\n"
                            .. "没有一句话。门重新关上了。\n\n"
                            .. "阿斯特转身离开的时候，你差点和他迎面撞上。\n"
                            .. "你飞快地躲进旁边的巷子里，心脏砰砰跳。\n\n"
                            .. "透过墙角的缝隙，你看见他停了一步，回头看了看——\n"
                            .. "然后继续走了。\n\n"
                            .. "你不确定他有没有发现你。但那扇没有招牌的门上，\n"
                            .. "你隐约看到了一个刻痕——像是太阳的图案，但中间是空的。\n\n"
                            .. "(发现了重要线索)"
                        )
                        return "主城区"
                    end,
                })
            else
                local scenes = {
                    "\n\n阿斯特的马车又出现在广场上。"
                        .. "这次他没有下车，只是透过车窗和一个穿着灰袍的人交谈了几句。"
                        .. "\n\n灰袍人接过一个小包裹，低头行礼后迅速消失在人群中。"
                        .. "马车随即驶离。整个过程不超过两分钟——"
                        .. "干净利落得像是排练过无数次。",
                    "\n\n你在白鸦书屋门口看见阿斯特从里面走出来。"
                        .. "他手里拿着一本厚厚的旧书，封面上的文字你看不懂——像是某种古代文字。"
                        .. "\n\n他注意到你的目光，微微颔首，那个动作高贵而疏离——"
                        .. "就像在说「我看见你了，但你不值得我多看一眼」。"
                        .. "\n\n然后他上了等在路边的马车。"
                        .. "书屋的老板娘在门口望着马车远去，表情有些复杂："
                        .. "「他每次来都只看那一类书——古代仪式和契约法典。奇怪的品味。」",
                    "\n\n广场喷泉旁，阿斯特正和两个你没见过的外地商人交谈。"
                        .. "两人身旁各有随从，但阿斯特身边只站着一个人——"
                        .. "看穿着不像护卫，更像是秘书或管家。"
                        .. "\n\n「这批货的价格，我只说一次。」阿斯特的声音不大，但字字清晰。"
                        .. "商人们频频点头，态度恭敬得像是在面对国王。"
                        .. "\n\n谈完之后，他们握手告别。阿斯特转身时，"
                        .. "嘴角浮现出一丝意味深长的笑——那个表情，和奥梅尔如出一辙。",
                }
                extraText = extraText .. scenes[math.random(1, #scenes)]
            end
        end

        -- 小奥和阿斯特父子同行 (下午, 两人都出现过, 8%)
        if period == "afternoon" and S.metOamelFirst and (S.rosbatFatherMainCount or 0) > 0
            and not S.mq3FatherSecret and chance(8) and tryEvent("rosbat_father_son_main") then
            extraText = extraText .. "\n\n你在广场上看到了罕见的一幕——奥梅尔和他的父亲并肩走在一起。"
                .. "\n\n阿斯特穿着深红色大衣，步伐稳健如山；"
                .. "奥梅尔穿着黑色礼服，红发在阳光下和父亲的胡须颜色一模一样。"
                .. "如果不是年龄的差距，几乎像是一个人的两个倒影。"
                .. "\n\n他们似乎在讨论什么。阿斯特说话时目不斜视，"
                .. "声音平稳得像在陈述一个不可更改的事实。"
                .. "奥梅尔在认真听，但嘴角微微抿着——那是他不太高兴时的表情。"
                .. "\n\n「我说的话，你考虑一下。」阿斯特的声音传来，不大，但很清楚。"
                .. "「……知道了。」奥梅尔的回答很短。"
                .. "\n\n两人在广场中央分开，朝不同的方向走去。"
                .. "奥梅尔走了几步，停下来，回头看了一眼父亲的背影。"
                .. "那个表情——不是愤怒，也不是委屈，更像是一种复杂的、"
                .. "说不清道不明的情感。\n\n"
                .. "然后他转过头，快步离开了。"
        end

        -- 莱昂哈特在主城区散步（退休将军, 上午/下午, 8%）
        if (period == "morning" or period == "afternoon")
            and chance(8) and tryEvent("leonhart_main") then
            S.leonhartMainCount = (S.leonhartMainCount or 0) + 1
            if S.leonhartMainCount == 1 then
                extraText = extraText .. "\n\n你注意到广场长椅上坐着一个金发的中年男人。"
                    .. "他穿着一件洗得有些发白的灰色外套，脚边放着一个布袋。"
                    .. "乍一看像是个普通的闲人——但他的坐姿笔挺如松，"
                    .. "和周围弯腰驼背的路人形成了鲜明的对比。"
                    .. "\n\n最引人注目的是他的眼睛——赤红色的瞳孔，像两颗被打磨过的红玉。"
                    .. "那种颜色太不自然了，让你忍不住多看了几眼。"
                    .. "\n\n薇拉奶奶从旁边经过，轻声跟你说："
                    .. "「那是莱昂哈特·瓦勒姆。诺兰的父亲。以前是北境军团的总指挥，"
                    .. "退休几年了。月亮女神的诅咒——瓦勒姆家的人都有那双赤瞳。」"
                    .. "\n\n她叹了口气：「不过他的诅咒已经稳定下来了，不然也退不了休。"
                    .. "现在整天就是看书画画，偶尔出来走走。跟当年那个杀伐果断的将军……"
                    .. "简直像两个人。」"
            else
                local scenes = {
                    "\n\n莱昂哈特又坐在广场的长椅上。今天他在看书，"
                        .. "一本封面已经翻旧了的精装书。偶尔翻一页，偶尔抬头看看路过的行人。"
                        .. "\n\n一个小女孩跑过去，被他脚边的布袋绊了一下。"
                        .. "他连忙扶住小女孩，温和地问她有没有摔着。"
                        .. "小女孩盯着他的赤瞳看了一会儿，说：「叔叔你的眼睛好漂亮！」"
                        .. "\n\n莱昂哈特愣了一下，然后笑了起来。那个笑容温暖而真诚。",
                    "\n\n你在白鸦书屋门口遇见了莱昂哈特。"
                        .. "他怀里抱着一摞书，正和书屋老板娘攀谈。"
                        .. "\n\n「有'A'的新作吗？」他问，语气里带着一种掩饰不住的期待。"
                        .. "老板娘摇了摇头：「那位作者很久没出新书了。」"
                        .. "莱昂哈特有些失望地点了点头：「那把上次那本再拿一册吧。"
                        .. "之前那本被我翻烂了。」"
                        .. "\n\n你注意到他买的书封面上写着一个很长的书名，"
                        .. "看不太清，但隐约能辨认出是关于历史和战争策略的内容。",
                    "\n\n莱昂哈特拎着一袋苹果从集市走过来。"
                        .. "他走路的步伐很稳，每一步都像是量过距离——"
                        .. "那是多年军旅生涯留下的习惯。"
                        .. "\n\n路过喷泉的时候他停了一下，从袋子里掏出一个苹果，"
                        .. "擦了擦在手上，然后咬了一口。"
                        .. "阳光照在他的金发上，赤红的眼瞳在光线下变得通透。"
                        .. "\n\n那一瞬间，退休将军莱昂哈特·瓦勒姆看起来就是一个——"
                        .. "平凡的、享受着午后时光的中年男人。",
                }
                extraText = extraText .. scenes[math.random(1, #scenes)]
            end
        end

        -- 莱昂哈特和阿斯特在主城区偶遇（军校老同学, 下午, 5%, 两人都出现过）
        if period == "afternoon" and (S.leonhartMainCount or 0) >= 1 and (S.rosbatFatherMainCount or 0) >= 1
            and chance(5) and tryEvent("leonhart_aster_main") then
            extraText = extraText .. "\n\n广场上出现了一幕有趣的场景——"
                .. "莱昂哈特坐在长椅上看书，阿斯特的马车恰好停在不远处。"
                .. "\n\n阿斯特从马车上走下来，看见莱昂哈特，脚步停顿了一瞬。"
                .. "然后他挥退了随从，独自走过去坐了下来。"
                .. "\n\n「还是整天游手好闲。」阿斯特的语气听起来像是批评，"
                .. "但他坐下时的姿态比平时放松了许多。"
                .. "\n\n「退休的人可不是游手好闲。」莱昂哈特合上书，"
                .. "「倒是你，整天忙得跟上了发条似的。当年在军校可不是这样。」"
                .. "\n\n「当年在军校是你拖累我。」阿斯特冷冷地说，"
                .. "但嘴角有一丝几不可见的弧度。"
                .. "\n\n两人沉默了一会儿。莱昂哈特从布袋里掏出一个苹果递过去。"
                .. "阿斯特看了一眼，没接。"
                .. "莱昂哈特就把苹果放在两人中间的长椅上。"
                .. "\n\n过了一会儿，你远远看见阿斯特起身离开了。"
                .. "长椅上的苹果不见了。"
        end

        -- 主城小事件 (25%)
        if chance(25) and tryEvent("main_flavor") then
            local flavors = {
                "\n\n教堂的彩色玻璃窗在阳光下投射出绚丽的光斑，好几个人驻足欣赏。",
                "\n\n一个男孩跑过来问你：'你见过龙吗？书上说以前这里有龙！'然后跑远了。",
                "\n\n白鸦书屋的乌鸦飞出来在广场上转了一圈，又飞回去了。路人已经见怪不怪。",
                "\n\n两个学生模样的年轻人在讨论魔法理论，声音越来越大，险些吵起来。",
            }
            extraText = extraText .. flavors[math.random(1, #flavors)]
        end

    -- ============ 花街 ============
    elseif location == "花街" then

        -- 达里奥在花街卖艺 (傍晚, 35%)
        if period == "evening" and S.npcDarioMet and chance(35) and tryEvent("dario_flower") then
            extraText = extraText .. "\n\n达里奥抱着吉他在花街入口弹唱，曲调带着异国风情。\n不少衣着华丽的客人经过时会往他帽子里扔硬币。"
        end

        -- 奥梅尔×梅菲斯 (傍晚, 20%)
        if period == "evening" and S.metOamelFirst and S.metManagerFirst and chance(20) and tryEvent("oamel_meifei") then
            extraText = extraText .. "\n\n奥梅尔和梅菲斯站在走廊上低声交谈。\n奥梅尔表情严肃，梅菲斯倒是一脸轻松。看起来在谈什么生意上的事。"
        end

        -- 莱德×奥梅尔 (傍晚, 15%, 莱德受邀后)
        if period == "evening" and S.initialNameInvited and S.metOamelFirst and chance(15) and tryEvent("leide_oamel") then
            extraText = extraText .. "\n\n" .. S.initialName .. "竟然出现在花街？他看起来有些不自在。\n奥梅尔叫住了他，递给他一杯什么东西。" .. S.initialName .. "犹豫了一下，接了过来。"
        end

        -- 【支线触发】花街的暗流 (傍晚, 梅菲斯和黑帮少主都已认识, quest未触发, 25%)
        if period == "evening" and S.metManagerFirst and S.gangBossMet
            and (S.quest_underflow or 0) == 0 and chance(25) and tryEvent("quest_underflow_trigger") then
            extraText = extraText .. "\n\n梅菲斯站在一盏路灯下，和一个你没见过的男人低声交谈。对方的表情很阴沉。梅菲斯注意到你的视线，微微皱了皱眉。"
            table.insert(extraChoices, {
                text = "🌙 假装路过，但留意他们的对话",
                target = "支线_花街暗流",
            })
        end

        -- 黑帮少主天台 (夜晚, 黑帮少主已认识且好感>=25, 15%)
        if period == "night" and S.gangBossMet and (S.gangBossAffection or 0) >= 25
            and chance(15) and tryEvent("gangboss_rooftop") then
            extraText = extraText .. "\n\n你抬头看到某栋楼的天台上有个人影，黑色的风衣在夜风中猎猎作响。是那个黑帮少主，他似乎在独自抽烟。"
            table.insert(extraChoices, {
                text = "🖤 爬上天台去找他",
                target = "小镇_黑帮少主天台",
            })
        end

        -- 黑帮少主出没 (夜晚, 25%)
        if period == "night" and chance(25) and tryEvent("gangboss_flower") then
            if not S.gangBossMet then
                extraText = extraText .. "\n\n一个穿着黑色风衣的年轻人从暗巷走出来，\n手里拿着一个纸袋——似乎是面包店的？\n他警惕地环顾四周，然后咬了一口什么东西，表情舒展开来。"
                table.insert(extraChoices, {
                    text = "🖤 （好奇地跟过去看看）",
                    target = "小镇_遇见黑帮少主",
                })
            else
                extraText = extraText .. "\n\n你在暗巷口瞥见那个黑帮少主。\n他正偷偷摸摸地吃一块蛋糕，表情像个做了坏事的小孩。"
                table.insert(extraChoices, {
                    text = "🖤 打个招呼",
                    target = "小镇_黑帮少主闲聊",
                })
            end
        end

    -- ============ 贫民窟 ============
    elseif location == "贫民窟" then

        -- 流民乞讨 (白天, 30%)
        if (period == "morning" or period == "afternoon") and chance(30) and tryEvent("slum_beggar") then
            local scenes = {
                "\n\n一个衣衫褴褛的老人蜷缩在墙角，伸出干瘦的手。\n「行行好……给口吃的也行……」",
                "\n\n一个瘸腿的女人抱着孩子坐在路边，面前放着一个破碗。\n孩子睡着了，女人的眼睛却一直盯着过路的行人。",
                "\n\n一个失去了一条胳膊的年轻人在翻垃圾堆，动作熟练得令人心酸。",
            }
            extraText = extraText .. scenes[math.random(1, #scenes)]
            if S.money >= 5 then
                table.insert(extraChoices, {
                    text = "🪙 施舍几个铜板（-5金币）",
                    action = function()
                        S.money = S.money - 5
                        S.reputation = (S.reputation or 0) + 1
                        GameState.addRecentEvent("在贫民窟施舍了流民")
                        return "贫民窟"
                    end,
                })
            end
        end

        -- 残疾者求助 (全天, 20%)
        if chance(20) and tryEvent("slum_disabled") then
            local scenes = {
                "\n\n一个双目失明的老人摸索着走路，差点撞上了石墙。\n「谁能帮我带个路……我只是想去水井那里……」",
                "\n\n一个断了腿的前矿工坐在木板上，用手撑着地面移动。\n他的目光中没有自怜，只有一种固执的倔强。",
                "\n\n一个聋哑的少年在比划着什么，旁边的流民不耐烦地推了他一把。\n少年跌倒在地，默默爬起来，继续比划。",
            }
            extraText = extraText .. scenes[math.random(1, #scenes)]
        end

        -- 【城内战斗】街头混混 (傍晚/夜晚, 每日限2次, 20%)
        if (period == "evening" or period == "night") and (S.townBattleToday or 0) < 2
            and chance(20) and tryEvent("town_battle_thug") then
            extraText = extraText .. "\n\n几个纹身青年拦住了你的去路。\n为首的人上下打量了你一眼，嘿嘿一笑：\n「留下买路钱，不然别想过去。」"
            table.insert(extraChoices, {
                text = "⚔️ 拒绝并迎战",
                target = "城内治安_混混",
            })
        end

        -- 【城内战斗】野狗 (夜晚, 每日限2次, 15%)
        if period == "night" and (S.townBattleToday or 0) < 2
            and chance(15) and tryEvent("town_battle_dog") then
            extraText = extraText .. "\n\n暗巷中传来低沉的嘶吼声。\n一条瘦骨嶙峋的野狗从垃圾堆后面钻出来，\n龇着牙，眼睛闪着幽绿的光。它似乎很饿，也很危险。"
            table.insert(extraChoices, {
                text = "⚔️ 保护自己",
                target = "城内治安_野狗",
            })
        end

        -- 黑帮小弟巡逻 (傍晚/夜晚, 35%)
        if (period == "evening" or period == "night") and chance(35) and tryEvent("slum_gang_patrol") then
            local scenes = {
                "\n\n两个穿黑衣的年轻人靠在墙上抽烟，目光锐利地打量每个经过的人。\n看到你时，其中一个冲另一个努了努嘴，低声说了句什么。",
                "\n\n几个黑衣人押着一个哭哭啼啼的男人从巷子里出来。\n「说了多少次了，欠的钱到期就得还——」\n看到你在看，为首的人冷冷扫了你一眼。",
                "\n\n一个纹着蛇纹身的壮汉从那栋宅邸的方向走出来，\n手里提着一个沉甸甸的袋子。他脚步很快，似乎有急事。",
            }
            extraText = extraText .. scenes[math.random(1, #scenes)]
        end

        -- 地下赌场传闻 (夜晚, 20%)
        if period == "night" and chance(20) and tryEvent("slum_gambling") then
            extraText = extraText .. "\n\n暗巷深处传来骰子碰撞的声音和压低的叫喊。\n偶尔有人从一扇半掩的门里出来，有的满面红光，有的垂头丧气。"
        end

        -- 威廉（黑帮少主）在贫民窟出没 (傍晚/夜晚, gangBossMet, 25%)
        if (period == "evening" or period == "night") and S.gangBossMet and chance(25) and tryEvent("slum_william_walk") then
            local aff = S.gangBossAffection or 0
            if aff >= 25 then
                extraText = extraText .. "\n\n你看到威廉从宅邸出来，身边只带了一个随从。\n他注意到你，嘴角微微一弯：「又来了？怎么，开始喜欢这里了？」"
            else
                extraText = extraText .. "\n\n你瞥见威廉站在宅邸的窗户后面，似乎在看着外面的贫民窟。\n他的表情很复杂——不是厌恶，也不是同情。"
            end
        end

        -- 氛围文字 (40%)
        if chance(40) and tryEvent("slum_flavor") then
            local flavors = {
                "\n\n不知哪里飘来了烤红薯的香味。在这种地方，这算是难得的温暖了。",
                "\n\n几个孩子在水沟边上玩泥巴，笑声在破败的巷子里回荡。他们似乎还不知道自己的处境。",
                "\n\n墙上歪歪扭扭地写着几个字：「这里被遗忘了」。墨迹已经很淡了。",
                "\n\n一只瘦骨嶙峋的野猫从你脚边跑过，嘴里叼着一条不知从哪弄来的小鱼。",
                "\n\n远处传来婴儿的哭声。哭了一会儿，被一个沙哑的女声哄住了。",
            }
            extraText = extraText .. flavors[math.random(1, #flavors)]
        end
    end

    -- ============ 全局：乌列尔暗中守护事件 ============
    -- 乌列尔不直接出现，但玩家会察觉到有人在暗中帮忙
    if S.day >= 5 and not S.urielMet then
        -- 遭遇困难时乌列尔暗中帮助（每5天可触发一次）
        if (S.urielHelpCount < 3) and chance(15) and tryEvent("uriel_shadow_" .. S.urielHelpCount) then
            local helpEvents = {
                -- 第1次：有人替你付了房租差额
                function()
                    if S.oweRent > 0 and S.money < S.rentDue then
                        extraText = extraText .. "\n\n你回家的时候发现门口放着一个信封。\n没有署名。里面是钱——刚好够补上这周的房租差额。\n信封角落有一个极小的蜡封印记，你似乎在哪里见过。"
                        S.urielHelpCount = S.urielHelpCount + 1
                        S.oweRent = 0
                        NPCSystem.addUrielAffection(5)
                        return true
                    end
                    return false
                end,
                -- 第2次：有人帮你解围
                function()
                    if S.money <= 20 then
                        extraText = extraText .. "\n\n路过小巷的时候，两个混混拦住了你。\n'小子，留下点买路钱——'\n话没说完，一道影子从屋顶掠过。\n混混的刀掉在了地上。他们互相看了一眼，骂骂咧咧地跑了。\n\n你抬头看向屋顶。什么也没有。\n但你闻到了一股很淡的……皂角花的香气。"
                        S.urielHelpCount = S.urielHelpCount + 1
                        NPCSystem.addUrielAffection(5)
                        return true
                    end
                    return false
                end,
                -- 第3次：有人给你送了一封信
                function()
                    extraText = extraText .. "\n\n信箱里多了一封信。\n没有寄件人，只有一行字：\n\n'吃饱了吗。天冷了加衣服。'\n\n字迹工整到几乎不像手写的，但最后一笔有一个很小的勾——\n像是写字的人犹豫了很久，想写更多，最终还是收住了。\n\n你不知道这封信是谁寄的。\n但你把它叠好，放进了抽屉里。"
                    S.urielHelpCount = S.urielHelpCount + 1
                    S.urielLetterCount = S.urielLetterCount + 1
                    NPCSystem.addUrielAffection(8)
                    table.insert(extraChoices, {
                        text = "📨 （仔细看看信封上的蜡封）",
                        target = "小镇_乌列尔信件",
                    })
                    return true
                end,
            }
            local idx = math.min(S.urielHelpCount + 1, #helpEvents)
            helpEvents[idx]()
        end
    end

    -- ============ 全局：莱昂哈特与乌列尔的联系 ============
    -- 当乌列尔暗中守护事件触发过之后，概率看到莱昂哈特（乌列尔的父亲）
    if (S.urielHelpCount or 0) >= 1 and (S.leonhartMainCount or 0) >= 1
        and chance(6) and tryEvent("leonhart_uriel_shadow") then
        local scenes = {
            "\n\n你远远看见莱昂哈特站在一条小巷的入口处，"
                .. "正和一个黑衣人低声交谈。那个人的身形高瘦，帽檐压得很低，看不清面容。"
                .. "但你隐约觉得那个侧影有些熟悉——和那股淡淡的皂角花香气一样熟悉。"
                .. "\n\n莱昂哈特对黑衣人点了点头，从怀里掏出一个小包裹递了过去。"
                .. "黑衣人接过，转身消失在巷子深处。"
                .. "\n\n莱昂哈特望着那人离去的方向，站了很久。"
                .. "你注意到他的表情——不是退休后那种淡然的平和，"
                .. "而是一种深沉的、带着些许愧疚的温柔。"
                .. "\n\n那是父亲看着孩子远去时才会有的表情。",
            "\n\n你在教堂附近看到莱昂哈特。"
                .. "他没有像往常一样坐在长椅上看书，而是站在拐角处，"
                .. "目光追随着远处街道上一个模糊的身影。"
                .. "\n\n那个身影走路的姿势很特别——步伐轻快但警觉，"
                .. "像一只时刻准备起飞的鸟。"
                .. "\n\n「……走慢一点啊。」莱昂哈特的嘴唇动了一下，声音小得几乎听不见。"
                .. "但你站得近，还是听到了。"
                .. "\n\n他的赤瞳里映着远处那道越来越小的身影，"
                .. "目光里有一种你之前从未在这个退休将军身上见过的柔软。",
            "\n\n你偶然瞥见莱昂哈特蹲在你家门口附近。"
                .. "他似乎在检查什么——低头看了看门缝，又抬头看了看窗户。"
                .. "然后他直起身，像是确认了什么，微微点了点头。"
                .. "\n\n他转身离开时差点和你撞个正着。"
                .. "「啊，抱歉。」他笑了笑，赤瞳里有一闪而过的紧张。"
                .. "「路过而已。」"
                .. "\n\n你看着他走远的背影，心里冒出一个奇怪的想法——"
                .. "那些没有署名的信，真的只是乌列尔自己送来的吗？",
        }
        extraText = extraText .. scenes[math.random(1, #scenes)]
    end

    -- ============ 全局：跨NPC互动（好感人物之间）============

    -- 莱德帮辛奇酒馆搬酒桶（莱德受邀 & 辛奇好感>=15, 20%）
    if S.initialNameInvited and S.npcSinchi >= 15 and location == "商业区"
        and period == "morning" and chance(20) and tryEvent("leide_sinchi_barrels") then
        extraText = extraText .. "\n\n" .. S.initialName .. "正帮辛奇从马车上搬酒桶。\n辛奇递给他一杯水：'慢点，别伤了腰。'\n" .. S.initialName .. "接过来喝了一口，淡淡地说：'不会。'"
    end

    -- K给克丽丝送草药（K已认识 & 克丽丝好感>=10, 15%）
    if S.kMet and S.npcClarice >= 10 and location == "主城区"
        and period == "afternoon" and chance(15) and tryEvent("k_clarice_herb") then
        extraText = extraText .. "\n\nK提着一个布包走进教堂。\n克丽丝接过去打开看了看：'这些草药……你从哪里找到的？'\nK笑了笑：'山里。给你们的病人用。'\n克丽丝认真地鞠了一躬。K摆了摆手，转身走了。"
    end

    -- 艾琳给莱德画肖像（两人都认识, 20%）
    if S.npcEileenMet and S.initialNameInvited and location == "十字路口"
        and period == "afternoon" and chance(20) and tryEvent("eileen_draw_leide") then
        extraText = extraText .. "\n\n艾琳正对着" .. S.initialName .. "画速写。\n" .. S.initialName .. "一脸不情愿地坐在那里，但没有离开。\n'别动！就差最后一笔——'\n'……你已经说了三次最后一笔了。'\n艾琳笑嘻嘻地继续画。"
    end

    -- 达里奥给莉莉安的花店伴奏（两人都认识, 15%）
    if S.npcDarioMet and S.npcLillianMet and location == "花园小镇"
        and period == "afternoon" and chance(15) and tryEvent("dario_lillian_music") then
        extraText = extraText .. "\n\n达里奥坐在莉莉安花店门口弹吉他。\n莉莉安在里面插花，偶尔跟着旋律轻轻哼唱。\n'这首曲子叫什么？'莉莉安问。\n'还没起名字。'达里奥说，'就叫……《花店》吧。'\n莉莉安笑着摇了摇头：'太偷懒了。'"
    end

    -- 薇拉奶奶教莱德魔法知识（两人都认识, 15%）
    if S.npcGrandmaVeraMet and S.initialNameInvited and location == "主城区"
        and period == "morning" and chance(15) and tryEvent("vera_teach_leide") then
        extraText = extraText .. "\n\n薇拉奶奶坐在广场长椅上，" .. S.initialName .. "居然坐在旁边。\n老太太手里拿着一本旧书，在给他讲什么。\n" .. S.initialName .. "听得很认真，偶尔点一下头。\n\n你没有打扰他们。"
    end

    -- 费利克斯给伊莎贝拉送面包（花园小镇, 上午, 15%）
    if S.npcFelixMet and S.npcIsabellaMet and location == "花园小镇"
        and period == "morning" and chance(15) and tryEvent("felix_isabella_bread") then
        extraText = extraText .. "\n\n费利克斯提着一袋面包走进花园，找到正在采药的伊莎贝拉。\n'又来了？'伊莎贝拉接过面包，语气淡淡的，但嘴角有一丝微笑。\n'你上次给的草药茶确实管用。'费利克斯拍拍肚子，'就当谢礼。'"
    end

    -- 小梅给老尤金送鱼（港口, 上午, 15%）
    if S.npcXiaomeiMet and S.npcOldYugenMet and location == "港口"
        and period == "morning" and chance(15) and tryEvent("xiaomei_yugen_fish") then
        extraText = extraText .. "\n\n小梅蹲到老尤金面前，塞给他一条烤好的鱼。\n'尤金爷爷，趁热吃！'\n老尤金乐呵呵地接过来：'谢了，丫头。来，我给你讲个故事——'\n'又是那一年暴风雨的夜晚？'小梅笑着跑开了。"
    end

    -- 塞巴斯蒂安向薇拉奶奶请教（主城区, 上午, 15%）
    if S.npcSebastianMet and S.npcGrandmaVeraMet and location == "主城区"
        and period == "morning" and chance(15) and tryEvent("sebastian_vera_study") then
        extraText = extraText .. "\n\n塞巴斯蒂安捧着一本旧书坐在薇拉奶奶身边请教。\n老太太翻了几页，笑着说：'这个注释是错的，原典不是这么写的。'\n塞巴斯蒂安连忙在笔记本上修改，如获至宝。"
    end

    -- 诺拉给达里奥补衣服（商业区, 下午, 15%）
    if S.npcNoraMet and S.npcDarioMet and location == "商业区"
        and period == "afternoon" and chance(15) and tryEvent("nora_dario_mend") then
        extraText = extraText .. "\n\n诺拉叉着腰站在裁缝铺门口，达里奥不好意思地递过他那件满是补丁的外套。\n'又勾破了？你是不是在荆棘丛里弹琴的？'\n'是树枝……大概。'达里奥小声辩解。\n诺拉翻了个白眼，接过外套开始补。"
    end

    -- 贾斯帕和费利克斯交接（商业区, 傍晚, 15%）
    if S.npcJasperMet and S.npcFelixMet and location == "商业区"
        and period == "evening" and chance(15) and tryEvent("jasper_felix_shift") then
        extraText = extraText .. "\n\n费利克斯正在关店门，贾斯帕提着灯笼走过来。\n两人简短地点了点头——这是他们每天傍晚的默契。\n费利克斯锁好门，回头递了一个纸包：'今天剩的面包。'\n贾斯帕接过来，道了声谢，消失在暮色里。"
    end

    -- 小梅和诺拉逛集市（花园小镇, 下午, 15%）
    if S.npcXiaomeiMet and S.npcNoraMet and location == "花园小镇"
        and period == "afternoon" and chance(15) and tryEvent("xiaomei_nora_market") then
        extraText = extraText .. "\n\n小梅和诺拉走在一起逛集市。\n'这块布好看！'小梅指着一块蓝色碎花布。\n诺拉瞥了一眼：'花色太碎，做衣服压不住。'\n'那做围巾呢？'\n诺拉想了想：'……倒是可以。'然后痛快地掏了钱。"
    end

    -- 阿莫斯修士在教堂看书（主城区, 上午, 30%）
    if location == "主城区" and period == "morning" and chance(30) and tryEvent("amos_read") then
        if not S.npcBrotherAmosMet then
            extraText = extraText .. "\n\n教堂侧门敞开着，里面传来翻书的声音。\n一个戴着圆框眼镜的年轻修士正在整理书架，动作极其仔细。"
            table.insert(extraChoices, {
                text = "📖 进去看看",
                target = "小镇_遇见阿莫斯",
            })
        else
            extraText = extraText .. "\n\n阿莫斯修士又在整理他的书架了。他透过圆框眼镜看到你，抬手打了个招呼。"
            table.insert(extraChoices, {
                text = "📖 找阿莫斯聊聊",
                target = "小镇_阿莫斯闲聊",
            })
        end
    end

    -- 罗伊在港口兜售（港口, 傍晚, 25%）
    if location == "港口" and period == "evening" and chance(25) and tryEvent("roy_sell") then
        if not S.npcMerchantRoyMet then
            extraText = extraText .. "\n\n码头角落蹲着一个鬼鬼祟祟的人，面前摊着一块脏兮兮的布，\n上面放着几样看不出来历的小玩意儿。"
            table.insert(extraChoices, {
                text = "🎒 好奇地走过去",
                target = "小镇_遇见罗伊",
            })
        else
            extraText = extraText .. "\n\n罗伊又在老地方摆摊了。他看到你，咧嘴一笑：'嘿，老主顾！'"
            table.insert(extraChoices, {
                text = "🎒 看看罗伊有什么新货",
                target = "小镇_罗伊闲聊",
            })
        end
    end

    -- 米娜带孤儿散步（花园小镇, 上午, 25%）
    if location == "花园小镇" and period == "morning" and chance(25) and tryEvent("mina_walk") then
        if not S.npcSisterMinaMet then
            extraText = extraText .. "\n\n一个年轻的修女带着四五个小孩走过花园。\n孩子们叽叽喳喳地围着她，她笑得像个姐姐。"
            table.insert(extraChoices, {
                text = "🌸 走过去打个招呼",
                target = "小镇_遇见米娜",
            })
        else
            extraText = extraText .. "\n\n米娜又带孩子们来花园了。一个小男孩正拽着她的袖子要她看蚂蚱。"
        end
    end

    -- 米娜×克丽丝（教堂同事互动, 主城区, 下午）
    if S.npcSisterMinaMet and S.npcClarice >= 10 and location == "主城区"
        and period == "afternoon" and chance(15) and tryEvent("mina_clarice") then
        extraText = extraText .. "\n\n米娜和克丽丝坐在教堂台阶上喝茶。\n'那个新来的孩子又哭了一晚上。'米娜叹了口气。\n克丽丝把自己的饼干掰了一半递过去：'明天我去看看他。'\n米娜接过来，小声说了句'谢谢姐姐'。"
    end

    -- 老尤金×黑胡子（港口老搭档互动）
    if S.npcOldYugenMet and S.npcBlackbeard >= 10 and location == "港口"
        and period == "afternoon" and chance(15) and tryEvent("yugen_blackbeard") then
        extraText = extraText .. "\n\n老尤金和黑胡子坐在码头边抽旱烟。\n'那一年暴风雨的夜晚——'\n'老尤金，你能不能换个开头？'黑胡子无奈地说。\n'不行。这是规矩。'老尤金一本正经。\n黑胡子翻了个白眼，但还是听了下去。"
    end

    return { text = extraText, choices = extraChoices }
end

return Events
