-- systems/mainquest/Ch1Passages.lua
-- Extracted Ch1 passage logic from MainQuest

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")

local Ch1Passages = {}

function Ch1Passages.getPassage(passageName, MainQuest)
    local S = GameState.state

    -- ==================== 传闻 ====================
    if passageName == "主线_传闻" then
        S.mqStage = 1
        TimeSystem.addMinutes(10)

        return {
            text = "你路过酒馆门口，几个搬运工围在一起，压低声音说着什么。\n\n"
                .. "'听说了没？前天有个流浪汉在贵族区动了手——'\n"
                .. "'岂止动手，差点把人家侍从的手砍断了。'\n"
                .. "'魏德曼家的人当场就把他按住了。'\n\n"
                .. "你停下脚步。\n\n"
                .. "'什么样的人？'你假装随口一问。\n\n"
                .. "搬运工看了你一眼，不太在意。\n"
                .. "'黑头发的，年纪不大，穿得破破烂烂的。\n"
                .. "长得倒还行，就是一脸死人相，不爱说话。'\n\n"
                .. "你的手指收紧了。\n"
                .. "黑发。不爱说话。破烂的衣服。\n\n"
                .. "那是" .. S.initialName .. "。\n\n"
                .. "'……现在人呢？'\n\n"
                .. "'关着呗。魏德曼家的地下室，\n"
                .. "听说打算过几天送去贵族法庭。\n"
                .. "攻击贵族的仆从，轻则坐牢，重则——'\n\n"
                .. "他做了个抹脖子的动作，然后摇了摇头。\n"
                .. "'流浪汉嘛，没人管的。'\n\n"
                .. "你站在原地，心跳很快。\n"
                .. "海风吹过来，吹不散你脑子里翻腾的东西。",
            choices = {
                { text = "（继续打听）他为什么动手？", target = "主线_传闻2" },
                { text = "（先冷静）……我需要想想", target = "商业区" },
            },
        }
    end

    if passageName == "主线_传闻2" then
        return {
            text = "'谁知道呢。'搬运工耸了耸肩。\n"
                .. "'有人说那个侍从先挑衅的，\n"
                .. "拿鞭子抽他，说什么'下等人滚远点'。\n"
                .. "那家伙就一把夺过鞭子，反手一剑——'\n\n"
                .. "另一个人接过话头：\n"
                .. "'我听的版本不一样。\n"
                .. "说是那个流浪汉路过贵族区，\n"
                .. "侍从嫌他挡路，想把他推到水沟里。\n"
                .. "他躲开了，侍从摔了一跤丢了面子，\n"
                .. "拔刀就砍。然后被反杀了——呃，反伤了。'\n\n"
                .. "'反正不管怎么说，先动手的是贵族那边。'\n"
                .. "'那有什么用？流浪汉伤了贵族的人，\n"
                .. "在这个城里就是死罪。'\n\n"
                .. "你听完了。\n"
                .. "你知道" .. S.initialName .. "不是那种无缘无故伤人的人。\n"
                .. "他沉默，冷淡，面无表情——\n"
                .. "但他不会主动攻击别人。\n\n"
                .. "除非被逼到了退无可退的地步。",
            choices = {
                { text = "我得想办法帮他", target = "主线_追查" },
                { text = "……先回去整理一下思路", target = "十字路口" },
            },
        }
    end

    -- ==================== 追查 ====================
    if passageName == "主线_追查" then
        local text = "━━━ 打听消息 ━━━\n\n"
            .. "你需要更多情报。\n"
            .. S.initialName .. "被关在魏德曼家的地下室——\n"
            .. "但你连那座宅邸的大门朝哪儿开都不知道。\n\n"
            .. "你能找谁打听？\n"

        local choices = {}

        -- 信息源1: 辛奇（酒馆老板，好感>=15或直接可问）
        if S.mqInvestSources == nil then S.mqInvestSources = 0 end
        table.insert(choices, {
            text = "🍺 去酒馆找辛奇打听",
            target = "主线_追查_辛奇",
        })

        -- 信息源2: 克丽丝（教堂修女，好感>=15解锁额外信息）
        table.insert(choices, {
            text = "⛪ 去教堂找克丽丝",
            target = "主线_追查_克丽丝",
        })

        -- 信息源3: 黑胡子（港口头目，好感>=15或付钱）
        table.insert(choices, {
            text = "⚓ 去港口找黑胡子",
            target = "主线_追查_黑胡子",
        })

        -- 信息源4: 知识判定（有书本知识）
        if S.mannerLevel >= 1 or S.historyLevel >= 1 then
            table.insert(choices, {
                text = "📚 凭借你的知识推理（礼仪/历史）",
                target = "主线_追查_知识",
            })
        end

        -- 调查够了就可以行动
        if S.mqInvestSources >= 2 then
            table.insert(choices, {
                text = "✊ 情报够了，准备行动",
                target = "主线_决定",
                action = function() S.mqStage = 2 end,
            })
        end

        table.insert(choices, { text = "🔙 先回去", target = "十字路口" })

        return { text = text, choices = choices }
    end

    -- --- 辛奇线 ---
    if passageName == "主线_追查_辛奇" then
        TimeSystem.addMinutes(15)
        S.mqInvestSources = (S.mqInvestSources or 0) + 1

        local text = "辛奇正在擦杯子。\n"
            .. "你坐到吧台前，压低声音问他关于魏德曼家的事。\n\n"

        if S.npcSinchi >= 15 then
            text = text
                .. "辛奇看了你一眼，放下杯子，凑过来。\n"
                .. "'你问这个干什么？'他的语气里带着警告。\n\n"
                .. "你没说话。他看了你半天，叹了口气。\n\n"
                .. "'魏德曼家的宅子在花街东侧尽头，\n"
                .. "三层楼，门口两个守卫，晚上九点换岗。\n"
                .. "换岗的时候有大概十秒钟的空档。'\n\n"
                .. "他又拿起杯子，继续擦。\n"
                .. "'地下室入口在后院的杂物棚里，\n"
                .. "有个铁门，平时锁着。\n"
                .. "钥匙在管家腰上，也可能在厨房墙上挂着。'\n\n"
                .. "他停了一下。\n"
                .. "'我什么都没说过。'"
        else
            text = text
                .. "辛奇看了你一眼，没有多问。\n"
                .. "'魏德曼家？花街东边那个大宅子。\n"
                .. "三层楼，很好认。门口有守卫。'\n\n"
                .. "他犹豫了一下，又加了一句：\n"
                .. "'听说他们家后院有个地下室，\n"
                .. "以前是酒窖，现在不知道用来干什么。'\n\n"
                .. "他的意思你听懂了。"
        end

        return {
            text = text,
            choices = {
                { text = "继续打听其他消息", target = "主线_追查" },
                { text = "谢谢，我知道了", target = "商业区" },
            },
        }
    end

    -- --- 克丽丝线 ---
    if passageName == "主线_追查_克丽丝" then
        TimeSystem.addMinutes(15)
        S.mqInvestSources = (S.mqInvestSources or 0) + 1

        local text = "克丽丝正在教堂里整理经书。\n"
            .. "你走过去，她抬起头，微微一笑。\n\n"

        if S.npcClarice >= 15 then
            text = text
                .. "'你来找我，不是为了祈祷吧？'\n"
                .. "她看出了你的心事。\n\n"
                .. "你把事情简单说了一遍。她沉默了一会儿。\n\n"
                .. "'魏德曼家……那位少爷嘛，\n"
                .. "在这座城里名声不太好，花天酒地的。'\n"
                .. "她轻轻合上经书。\n\n"
                .. "'不过我倒是听说，罗斯巴特家的奥梅尔少爷\n"
                .. "也在打听那个被关起来的人的事。\n"
                .. "他每个月都匿名给教堂捐善款——\n"
                .. "不是一个坏人。也许你可以找他帮忙。'\n\n"
                .. "她从书架后面拿出一个小布包。\n"
                .. "'这是教堂给贫困者发放的物资通行证。\n"
                .. "拿着它进贵族区，守卫通常不会为难你。'"
                -- 获得道具：通行证
        else
            text = text
                .. "'关于那件事啊……'她犹豫了一下。\n\n"
                .. "'我听说被关起来的那个人伤势不轻。\n"
                .. "魏德曼家的人关了他，\n"
                .. "但似乎有人偷偷给他送过药。\n"
                .. "不知道是谁的意思。'\n\n"
                .. "她看着你的眼睛：\n"
                .. "'无论你要做什么，太阳神会保佑善良的人。'"
        end

        return {
            text = text,
            choices = {
                { text = "继续打听其他消息", target = "主线_追查" },
                { text = "谢谢你，克丽丝", target = "商业区" },
            },
        }
    end

    -- --- 黑胡子线 ---
    if passageName == "主线_追查_黑胡子" then
        TimeSystem.addMinutes(15)
        S.mqInvestSources = (S.mqInvestSources or 0) + 1

        local text = "黑胡子在港口的仓库里，正指挥人搬货。\n"
            .. "你走过去，他斜眼看了你一下。\n\n"

        if S.npcBlackbeard >= 15 then
            text = text
                .. "'嗬，你也听说了？'他嘿嘿一笑。\n"
                .. "'那个黑头发的小子，有点本事。\n"
                .. "一个人把三个侍从打趴下了。'\n\n"
                .. "他压低声音：\n"
                .. "'魏德曼家后面有条运货的小巷，\n"
                .. "平时不锁门，守卫也不怎么去。\n"
                .. "我们……呃，运货的时候偶尔走那边。'\n\n"
                .. "他拍了拍你的肩膀。\n"
                .. "'你要是想干点什么，最好带上这个。'\n"
                .. "他塞给你一根弯曲的铁片——开锁用的。\n\n"
                .. "（获得铁片工具）"
            S.mqHasLockpick = true
        else
            text = text
                .. "'问这种事要花钱的，小子。'\n\n"
            if S.money >= 30 then
                text = text
                    .. "你掏出30金币放在箱子上。\n"
                    .. "他数了数，满意地点点头。\n\n"
                    .. "'魏德曼家宅子后面有条小巷，\n"
                    .. "围墙不高，翻得过去。\n"
                    .. "里面守卫不多，但有巡逻。\n"
                    .. "小心别被逮住就行。'\n\n"
                    .. "（-30金币）"
                S.money = S.money - 30
            else
                text = text
                    .. "你摸了摸口袋。不够。\n\n"
                    .. "黑胡子摆了摆手：\n"
                    .. "'没钱就别问。不过我可以告诉你一件事——\n"
                    .. "那小子关在地下室。免费的。'"
            end
        end

        return {
            text = text,
            choices = {
                { text = "继续打听其他消息", target = "主线_追查" },
                { text = "够了，我该走了", target = "港口" },
            },
        }
    end

    -- --- 知识推理线 ---
    if passageName == "主线_追查_知识" then
        TimeSystem.addMinutes(10)
        S.mqInvestSources = (S.mqInvestSources or 0) + 1

        local text = ""
        if S.mannerLevel >= 1 and S.historyLevel >= 1 then
            text = "你坐在家里，翻开读过的那些书，回忆关于贵族宅邸的知识。\n\n"
                .. "礼仪课本上写过——魏德曼家族世代高官，\n"
                .. "宅邸按照标准公爵规格建造。\n"
                .. "这意味着：前厅用于接待，后院用于仓储，\n"
                .. "地下层是酒窖或关押间。\n\n"
                .. "历史书上提到——这类公爵府邸的地下层，\n"
                .. "通常有两个入口：一个在后院杂物棚内，\n"
                .. "另一个在厨房角落的暗门后面。\n\n"
                .. "暗门……如果能找到厨房，就不需要钥匙。\n\n"
                .. "你合上书。心里已经有了大致的计划。"
            S.mqKnowsSecretDoor = true
        elseif S.mannerLevel >= 1 then
            text = "你回忆礼仪课上学过的贵族宅邸布局——\n"
                .. "前厅、会客室在一楼，仆人区在侧翼，\n"
                .. "地下室入口通常在后院。\n\n"
                .. "这些知识也许能帮上忙。"
        else
            text = "你翻开历史书，找到了关于魏德曼家族的记载。\n"
                .. "当朝丞相家族，世代把持朝政。\n"
                .. "宅邸位于花街东侧，建筑风格气派而冷硬。\n\n"
                .. "书上没有更多有用的信息，\n"
                .. "但至少你知道了那是什么样的地方。"
        end

        return {
            text = text,
            choices = {
                { text = "继续打听其他消息", target = "主线_追查" },
                { text = "开始制定计划", target = "主线_追查" },
            },
        }
    end

    -- ==================== 决定营救 ====================
    if passageName == "主线_决定" then
        S.mqStage = 2

        local text = "夜里你躺在床上，翻来覆去睡不着。\n\n"
            .. "天花板上晃动着蜡烛的影子。\n"
            .. "你一直在想" .. S.initialName .. "的事。\n\n"
            .. "你想起他蹲在路边，穿着破旧的灰色外衣。\n"
            .. "你想起他说'……什么事？'时平静的语气。\n"
            .. "你想起你们一起吃饭时，他会把自己碗里的肉\n"
            .. "夹到你碗里，然后装作什么都没发生。\n\n"
            .. "他现在被关在地下室里。\n"
            .. "也许受了伤。也许在等一个不会来的人。\n\n"
            .. "你坐起来。\n\n"
            .. "蜡烛快烧完了。火焰在风里晃了一下。\n"
            .. "你的手在发抖——不是因为冷。"

        local choices = {}
        table.insert(choices, {
            text = "我去救他",
            target = "主线_潜入准备",
            action = function()
                S.mqStage = 3
            end,
        })
        table.insert(choices, {
            text = "……再等等看，也许事情会有转机",
            target = "十字路口",
        })

        return { text = text, choices = choices }
    end

    -- ==================== 潜入准备 ====================
    if passageName == "主线_潜入准备" then
        local text = "你下了决心。\n\n"
            .. "换上深色的衣服，把剑别在腰后。\n"
            .. "推开门，夜风迎面吹来。\n\n"
            .. "魏德曼家的宅邸在花街东侧尽头。\n"
            .. "你站在街角，远远看着那座三层楼的建筑。\n"
            .. "灯火通明，门口站着两个守卫。\n\n"
            .. "你深吸一口气。\n"
            .. "怎么进去？"

        local choices = {}

        -- 方式A：正面混入（魅力>=5 或 有通行证）
        local canCharm = S.ML >= 5
        local hasPass = S.npcClarice >= 15 and S.mqInvestSources and S.mqInvestSources >= 1
        if canCharm or hasPass then
            local label = ""
            if hasPass then
                label = "📜 用教堂通行证正面走进去"
            else
                label = "🗣️ 和守卫搭话，混进去（魅力" .. S.ML .. "）"
            end
            table.insert(choices, {
                text = label,
                target = "主线_潜入_正面",
                action = function() S.mqInfilMethod = "charm" end,
            })
        end

        -- 方式B：夜间翻墙（技巧>=5 或 耐力>=4）
        if S.JQ >= 5 or S.NL >= 4 then
            table.insert(choices, {
                text = "🌙 从后巷翻墙进去（技巧" .. S.JQ .. "/耐力" .. S.NL .. "）",
                target = "主线_潜入_翻墙",
                action = function() S.mqInfilMethod = "stealth" end,
            })
        end

        -- 方式C：暗门（知识推理线发现）
        if S.mqKnowsSecretDoor then
            table.insert(choices, {
                text = "📚 从厨房暗门潜入（你记得书上写过……）",
                target = "主线_潜入_暗门",
                action = function() S.mqInfilMethod = "secret" end,
            })
        end

        -- 方式D：蹲守换岗（默认，永远可用）
        table.insert(choices, {
            text = "⏳ 蹲在暗处，等守卫换岗",
            target = "主线_潜入_蹲守",
            action = function() S.mqInfilMethod = "wait" end,
        })

        return { text = text, choices = choices }
    end

    -- --- 潜入方式A：正面 ---
    if passageName == "主线_潜入_正面" then
        local text = ""
        S.mqAlertLevel = 0

        if S.npcClarice >= 15 then
            text = "你从墙根后走出来，步伐不急不缓。\n"
                .. "手里举着教堂的通行证。\n\n"
                .. "'教堂送物资的。'你的声音很稳。\n\n"
                .. "守卫接过通行证看了一眼，对视一下，让开了。\n"
                .. "你走进去。\n"
                .. "后背的衣服贴在皮肤上，凉的。\n\n"
                .. "过了门厅，空气里有淡淡的花香。\n"
                .. "走廊很长，两侧挂着油画。\n"
                .. "你低着头，快步走向后院方向。"
        else
            text = "你深吸一口气，整了整衣领，大大方方地走过去。\n\n"
                .. "'晚上好。'你对守卫点了点头，\n"
                .. "语气自然得像来过一百次。\n"
                .. "'我来送东西的，约好了的。'\n\n"
                .. "守卫犹豫了一下。\n"
                .. "你没有停步，保持着微笑往里走。\n\n"
                .. "'喂——'\n"
                .. "'管家知道的。'你头也不回。\n\n"
                .. "脚步声在身后顿了一下。\n"
                .. "然后——没有追上来。\n\n"
                .. "你走进门厅，心跳在耳朵里擂鼓。\n"
                .. "但你的步伐始终是稳的。"
        end

        return {
            text = text,
            choices = { { text = "（继续）", target = "主线_寻找地下室" } },
        }
    end

    -- --- 潜入方式B：翻墙 ---
    if passageName == "主线_潜入_翻墙" then
        S.mqAlertLevel = 0

        local text = "你绕到宅邸后面的小巷。\n"
            .. "围墙不算太高，大概两人高，石头砌的。\n\n"

        if S.JQ >= 5 then
            text = text
                .. "你找到一处石缝较多的地方，\n"
                .. "手指卡进石缝，脚尖踩着凸出的砖块，\n"
                .. "像猫一样翻了上去。\n\n"
                .. "墙头上你伏低身子，确认下面没有人，\n"
                .. "然后无声落地。\n"
                .. "鞋底踩在草地上，几乎没发出声音。"
        else
            text = text
                .. "你抓住墙头，用力往上撑。\n"
                .. "手臂酸得发抖，但你咬着牙爬了上去。\n\n"
                .. "翻过墙头时膝盖磕在石头上，疼了一下。\n"
                .. "你忍着没出声，翻身落到另一边。\n"
                .. "落地的声音比你想的响——\n\n"
                .. "你缩在灌木丛后面，一动不动。\n"
                .. "等了好一会儿，没人来。"
        end

        text = text .. "\n\n后院很大，种着修剪整齐的月季花。\n"
            .. "你贴着墙壁，慢慢往杂物棚的方向移动。"

        return {
            text = text,
            choices = { { text = "（继续）", target = "主线_寻找地下室" } },
        }
    end

    -- --- 潜入方式C：暗门 ---
    if passageName == "主线_潜入_暗门" then
        S.mqAlertLevel = 0

        return {
            text = "你绕到宅邸侧面。\n"
                .. "书上说旧式皇族宅邸的厨房通常在侧翼一楼，\n"
                .. "通风窗开得很低，方便排出油烟。\n\n"
                .. "你找到了那扇通风窗。\n"
                .. "窗户没锁——厨房在这个时间已经没人了。\n\n"
                .. "你侧着身子挤进去，脚落在灶台上，\n"
                .. "再跳到地面。月光从窗口照进来，\n"
                .. "锅碗瓢盆的影子落了一地。\n\n"
                .. "你摸索着走到厨房角落，\n"
                .. "在一排架子后面找到了那扇暗门。\n"
                .. "门很旧，铰链生了锈，但还能打开。\n\n"
                .. "门后面是向下的石阶。\n"
                .. "黑洞洞的，一股霉味扑面而来。\n\n"
                .. "你走了下去。",
            choices = { { text = "（继续）", target = "主线_发现莱德" } },
            -- 暗门直通地下室，跳过寻找环节
        }
    end

    -- --- 潜入方式D：蹲守 ---
    if passageName == "主线_潜入_蹲守" then
        S.mqAlertLevel = 0

        return {
            text = "你蹲在街对面的木箱后面。\n"
                .. "等。\n\n"
                .. "十分钟。二十分钟。四十分钟。\n"
                .. "腿蹲麻了，你换了个姿势，继续等。\n\n"
                .. "终于——守卫交接。\n"
                .. "换岗的人从里面出来，当班的人回身说了句什么。\n"
                .. "两个人的注意力都不在门口。\n\n"
                .. "就是现在。\n\n"
                .. "你起身，低着头快步走过去。\n"
                .. "从半掩的门缝挤了进去。\n\n"
                .. "门在身后合上。你靠在墙壁上，大口喘气。\n"
                .. "心跳快得像要从嗓子眼蹦出来。\n\n"
                .. "但你进来了。",
            choices = { { text = "（继续）", target = "主线_寻找地下室" } },
        }
    end

    -- ==================== 寻找地下室 ====================
    if passageName == "主线_寻找地下室" then
        local text = "宅邸内部比你想的更大。\n"
            .. "走廊很长，地板铺着深红色的地毯，\n"
            .. "墙上挂着交叉羽笔与天平的魏德曼家徽。\n\n"
            .. "你贴着墙壁走，尽量不发出声音。\n"
            .. "拐过一个弯，看到了通往后院的门。\n\n"

        -- 根据技巧判定遭遇
        if S.JQ >= 4 then
            text = text
                .. "你听到脚步声从前面传来——巡逻的仆人。\n"
                .. "你迅速闪进旁边的壁龛里，屏住呼吸。\n"
                .. "脚步声从身边经过，渐渐远去。\n\n"
                .. "你溜进后院，找到了杂物棚。\n"
                .. "棚里堆满了旧家具和破箱子。\n"
                .. "角落有一扇铁门——上了锁。"
        else
            text = text
                .. "你加快脚步穿过走廊。\n"
                .. "一个仆人端着托盘从侧门出来，差点撞上你。\n\n"
                .. "'你是谁——'\n"
                .. "'管家让我来搬东西的。'你脱口而出。\n"
                .. "仆人狐疑地看了你一眼，但没追问，\n"
                .. "端着托盘走了。\n\n"
                .. "你擦了擦额头的冷汗，快步走进后院。\n"
                .. "杂物棚在角落——里面有一扇铁门，锁着。"
            S.mqAlertLevel = (S.mqAlertLevel or 0) + 1
        end

        return {
            text = text,
            choices = { { text = "（继续）", target = "主线_开锁" } },
        }
    end

    -- ==================== 开锁 ====================
    if passageName == "主线_开锁" then
        local text = "铁门很厚，锁是老式的挂锁。\n"
            .. "门缝里透出一点微弱的光——里面有人。\n\n"
            .. "你的心跳加速了。\n"

        local choices = {}

        -- 方式A：撬锁（技巧>=7 或 有黑胡子给的铁片）
        if S.JQ >= 7 or S.mqHasLockpick then
            local label = S.mqHasLockpick
                and "🔧 用黑胡子给的铁片撬锁"
                or "🔧 用随身的铁片撬锁（技巧" .. S.JQ .. "）"
            table.insert(choices, {
                text = label,
                target = "主线_开锁_撬",
                action = function() S.mqLockMethod = "pick" end,
            })
        end

        -- 方式B：寻找钥匙（灵感>=5，感知能力）
        if S.LG >= 5 then
            table.insert(choices, {
                text = "🔍 凭直觉搜索钥匙（灵感" .. S.LG .. "）",
                target = "主线_开锁_钥匙",
                action = function() S.mqLockMethod = "key" end,
            })
        end

        -- 方式C：踹门（力量>=6）
        if S.LL >= 6 then
            table.insert(choices, {
                text = "🦵 踹开铁门（力量" .. S.LL .. "）",
                target = "主线_开锁_踹",
                action = function() S.mqLockMethod = "force" end,
            })
        end

        -- 方式D：光属性（光属性高）
        if S.GSX >= 8 then
            table.insert(choices, {
                text = "✨ 用光属性熔化锁芯（光属性" .. S.GSX .. "）",
                target = "主线_开锁_光",
                action = function() S.mqLockMethod = "light" end,
            })
        end

        -- 默认：寻找其他办法（永远可用）
        table.insert(choices, {
            text = "👀 仔细检查周围，想别的办法",
            target = "主线_开锁_搜索",
            action = function() S.mqLockMethod = "search" end,
        })

        return { text = text, choices = choices }
    end

    -- --- 开锁A：撬锁 ---
    if passageName == "主线_开锁_撬" then
        return {
            text = "你从口袋里摸出铁片，插进锁孔。\n"
                .. "贴着锁芯慢慢拨，感受着弹子的位置。\n\n"
                .. "手指微微发抖。你强迫自己冷静下来。\n\n"
                .. "第一颗……第二颗……\n\n"
                .. "很轻的一声「咔」。\n"
                .. "锁开了。\n\n"
                .. "铁片磨得很薄，在月光下发亮。\n"
                .. "你把它揣回口袋里。",
            choices = { { text = "（推开门）", target = "主线_发现莱德" } },
        }
    end

    -- --- 开锁B：找钥匙 ---
    if passageName == "主线_开锁_钥匙" then
        return {
            text = "你环顾四周。\n"
                .. "杂物棚很乱，但你觉得钥匙不会离锁太远。\n\n"
                .. "管家不可能每次都跑回房间拿钥匙——\n"
                .. "一定有个放备用钥匙的地方。\n\n"
                .. "你蹲下来，摸了摸铁门旁边的砖缝。\n"
                .. "手指碰到了冰凉的金属。\n\n"
                .. "一串钥匙。藏在松动的砖头后面。\n\n"
                .. "试了第三把的时候，锁开了。\n"
                .. "钥匙很凉，握在手心里硌着。",
            choices = { { text = "（推开门）", target = "主线_发现莱德" } },
        }
    end

    -- --- 开锁C：踹门 ---
    if passageName == "主线_开锁_踹" then
        S.mqAlertLevel = (S.mqAlertLevel or 0) + 2
        return {
            text = "没时间了。\n\n"
                .. "你抬脚踹在锁上。\n"
                .. "门框震了一下。\n"
                .. "第二脚——锁弹开了，\n"
                .. "门撞在墙上发出一声闷响。\n\n"
                .. "心跳很快，耳朵里嗡嗡的。\n"
                .. "这动静肯定惊动了人。\n\n"
                .. "你没有时间犹豫了。",
            choices = { { text = "（冲进去）", target = "主线_发现莱德" } },
        }
    end

    -- --- 开锁D：光属性 ---
    if passageName == "主线_开锁_光" then
        return {
            text = "你伸出手，掌心朝向锁孔。\n\n"
                .. "你想起安德鲁老管家的话——\n"
                .. "'光属性……不要随便让人看到。'\n\n"
                .. "一道金色的光从掌心涌出，\n"
                .. "细而集中，像一根发光的针。\n"
                .. "锁芯在光的热力下开始发红、软化——\n\n"
                .. "轻轻的「嘀嗒」一声，锁芯断了。\n"
                .. "挂锁掉在地上，冒着热气。\n\n"
                .. "你收回手。掌心有一点烫。\n"
                .. "你第一次用自己的力量做了这样的事。",
            choices = { { text = "（推开门）", target = "主线_发现莱德" } },
        }
    end

    -- --- 开锁E：搜索 ---
    if passageName == "主线_开锁_搜索" then
        return {
            text = "你仔细检查铁门。\n"
                .. "锁很结实，但门铰链是老旧的——\n"
                .. "固定铰链的螺丝已经锈蚀了。\n\n"
                .. "你在杂物堆里翻了一会儿，\n"
                .. "找到一把旧螺丝刀。\n\n"
                .. "你蹲下来，一颗一颗地拧。\n"
                .. "手指被锈蚀的金属划破了，渗出血来。\n"
                .. "你咬着嘴唇，继续拧。\n\n"
                .. "最后一颗螺丝落地的时候，\n"
                .. "铰链那一侧的门板松了。\n"
                .. "你把门板掀起来，露出一个能侧身通过的缝隙。",
            choices = { { text = "（挤进去）", target = "主线_发现莱德" } },
        }
    end

    -- ==================== 发现莱德 ====================
    if passageName == "主线_发现莱德" then
        local name = S.initialName

        return {
            text = "石阶向下延伸。\n"
                .. "空气变得潮湿阴冷，带着铁锈和霉菌的味道。\n\n"
                .. "地下室不大。一张破木板床，一盏快灭的油灯。\n"
                .. "角落里蜷缩着一个人。\n\n"
                .. name .. "。\n\n"
                .. "他靠在墙角，双手绑着粗绳。\n"
                .. "嘴角有干涸的血迹，左眼下面青了一大块。\n"
                .. "衣服更破了，膝盖那里的布料磨穿了，\n"
                .. "露出下面的擦伤。\n\n"
                .. "他听到脚步声，抬起头。\n"
                .. "看到你的那一刻，他的眼睛微微睁大了——\n"
                .. "然后又恢复了那种惯常的面无表情。\n\n"
                .. "'……你来干什么。'\n"
                .. "他的声音沙哑，像好几天没喝水。\n\n"
                .. "你蹲到他面前，解开他手上的绳子。\n"
                .. "绳子勒得很紧，手腕上有深红色的勒痕。\n\n"
                .. "'走了。'你说。\n\n"
                .. "他看着你。很久。\n"
                .. "然后他用没受伤的那只手撑着墙壁，站了起来。\n"
                .. "站起来的时候踉跄了一下，你扶住了他。\n\n"
                .. "他很轻。比你想的轻得多。",
            choices = { { text = "扶着他往外走", target = "主线_遭遇奥梅尔" } },
        }
    end

    -- ==================== 遭遇奥梅尔 ====================
    if passageName == "主线_遭遇奥梅尔" then
        local name = S.initialName

        local text = "你扶着" .. name .. "走上石阶，推开门。\n\n"
            .. "楼梯拐角站着一个人。\n\n"
            .. "红头发。深色外套。领口扣得整整齐齐。\n"
            .. "——奥梅尔·罗斯巴特。\n\n"
            .. "他不是魏德曼家的人。\n"
            .. "他看着你们，表情复杂。没有叫守卫。\n"
            .. "也没有让开。\n\n"
            .. "就那样站在那里。\n"
            .. "灯光从他背后照过来，他的手里拿着一串钥匙——\n"
            .. "看起来，他也是来救人的。\n\n"
            .. name .. "的手抓紧了你的衣袖。"

        local choices = {}

        -- 选择A：无视他（勇敢>=2 或 冷静>=2）
        table.insert(choices, {
            text = "（无视他，扶着" .. name .. "走过去）",
            target = "主线_奥梅尔_无视",
            action = function()
                S.mqOamelChoice = "ignore"
            end,
        })

        -- 选择B：开口求助
        table.insert(choices, {
            text = "（开口）'他走不动了。'",
            target = "主线_奥梅尔_求助",
            action = function()
                S.mqOamelChoice = "help"
                NPCSystem.addOamelAffection(5)
            end,
        })

        -- 选择C：挟持/威胁
        table.insert(choices, {
            text = "（挡在" .. name .. "身前）'让开。'",
            target = "主线_奥梅尔_对峙",
            action = function()
                S.mqOamelChoice = "threaten"
            end,
        })

        return { text = text, choices = choices }
    end

    -- --- 奥梅尔A：无视 ---
    if passageName == "主线_奥梅尔_无视" then
        local name = S.initialName

        return {
            text = "你扶着" .. name .. "走过去。\n"
                .. "经过奥梅尔身边时，肩膀几乎擦着他的衣服。\n\n"
                .. "他没有动。\n"
                .. "目光一直追着你们。\n\n"
                .. "走到楼梯口的时候，\n"
                .. "背后传来很轻的声音：\n\n"
                .. "'他伤得很重。出去以后，往东走。'\n\n"
                .. "你停了一下。\n"
                .. name .. "的手抓紧了你的衣服。\n\n"
                .. "你没有回头。继续走。\n\n"
                .. "奥梅尔没有追上来。\n"
                .. "他站在原地，把手里的钥匙慢慢收进口袋。\n"
                .. "你们先到了一步——他本来也打算今晚动手。",
            choices = { { text = "（继续）", target = "主线_逃离" } },
        }
    end

    -- --- 奥梅尔B：求助 ---
    if passageName == "主线_奥梅尔_求助" then
        local name = S.initialName

        return {
            text = "奥梅尔看了你一眼。又看了看" .. name .. "。\n\n"
                .. "他走过来。\n"
                .. "把" .. name .. "的另一只手臂搭在自己肩上。\n\n"
                .. "三个人挤在窄楼梯上。\n"
                .. "奥梅尔等" .. name .. "每一步都站稳了才走下一步。\n"
                .. "他的衣服蹭到了" .. name .. "身上的血，\n"
                .. "深色面料上出现了更深的一块。\n"
                .. "他没说什么。\n\n"
                .. "到了门口，他松开手。\n\n"
                .. "'走东边。没有灯，也没人。\n"
                .. "西边有人。'\n\n"
                .. "你点了点头，扶着" .. name .. "往东走。\n"
                .. "回头的时候，他还站在门口。\n"
                .. "影子拉得很长，肩膀上沾着血。\n\n"
                .. "他本来就是来救人的。\n"
                .. "只不过你先到了一步。",
            choices = { { text = "（继续）", target = "主线_逃离" } },
        }
    end

    -- --- 奥梅尔C：对峙 ---
    if passageName == "主线_奥梅尔_对峙" then
        local name = S.initialName

        return {
            text = "你挡在" .. name .. "身前，手按在腰后的剑柄上。\n\n"
                .. "奥梅尔看着你的手，又抬起头看你的眼睛。\n\n"
                .. "'……你认真的？'他的语气很轻。\n"
                .. "不像是愤怒，更像是一种……无奈。\n\n"
                .. "你没有说话。手没有离开剑柄。\n\n"
                .. "他抬起手——\n"
                .. "你绷紧了身体。\n\n"
                .. "他把手里的钥匙举起来，晃了晃，\n"
                .. "然后放在旁边的窗台上。\n"
                .. "侧过身，让出了路。\n\n"
                .. "'我本来打算用更体面的方式。'\n"
                .. "他的声音很低，像在自言自语。\n"
                .. "'瓦勒姆家的人，做事总是这么急。'\n\n"
                .. "你没有回答。\n"
                .. "扶着" .. name .. "快步走了出去。",
            choices = { { text = "（继续）", target = "主线_逃离" } },
        }
    end

    -- ==================== 逃离 ====================
    if passageName == "主线_逃离" then
        local name = S.initialName
        S.mqStage = 4

        local text = "你们从宅邸后门出去，钻进窄巷。\n\n"
            .. "夜风冷得刺骨。\n"
            .. name .. "靠在你身上，脚步踉跄。\n"
            .. "你能感觉到他的身体在发抖——\n"
            .. "不知道是因为冷，还是因为疼。\n\n"
            .. "'别说话，走。'你扶着他加快脚步。\n\n"
            .. "身后传来喊声——\n"
            .. "'有人闯进来过！检查地下室！'\n"
            .. "'人不在了！快追！'\n\n"
            .. "脚步声。火把的光。\n"
            .. "越来越近。\n\n"

        if (S.mqAlertLevel or 0) >= 2 then
            text = text
                .. "你踹门的声音惊动了太多人。\n"
                .. "巷子两头都出现了追兵的影子。\n\n"
                .. name .. "忽然抓住你的手腕。\n"
                .. "'这边。'\n\n"
                .. "他拖着你钻进一个更窄的缝隙——\n"
                .. "两栋房子之间的夹道，\n"
                .. "窄到只能侧身通过。\n"
                .. "火把的光从头顶掠过，没有照进来。"
        else
            text = text
                .. "你拉着" .. name .. "拐进一条暗巷。\n"
                .. "追兵的脚步声从大路上冲过去了——\n"
                .. "他们没有发现你们拐弯。\n\n"
                .. "你们靠在墙壁上，大口喘气。\n"
                .. name .. "咳了几声，额头上全是冷汗。"
        end

        text = text .. "\n\n'……你不该来的。'他的声音很低。\n\n"
            .. "你没有回答。\n"
            .. "因为你知道——如果再来一次，你还是会来。"

        return {
            text = text,
            choices = { { text = "（继续）", target = "主线_莱德的手段" } },
        }
    end

    -- ==================== 莱德的手段 ====================
    if passageName == "主线_莱德的手段" then
        local name = S.initialName

        return {
            text = "你们躲在暗巷里。\n"
                .. "追兵在附近来回搜索，火把晃来晃去。\n\n"
                .. name .. "忽然站直了。\n"
                .. "他的表情变了——不是你熟悉的那种冷淡。\n"
                .. "是一种你没见过的……锐利。\n\n"
                .. "'等一下。'他说。\n\n"
                .. "然后他走了出去。\n"
                .. "你想拉住他，但他已经站到了巷口。\n\n"
                .. "追兵看到他，举起火把。\n"
                .. "'就是他——'\n\n"
                .. name .. "把外衣扯开，露出胸口的伤疤。\n"
                .. "那些伤不是今天的。是更早的、更旧的。\n"
                .. "在火光下像一幅扭曲的地图。\n\n"
                .. "'回去告诉你们的少爷。'\n"
                .. "他的声音不大，但很清楚。\n"
                .. "'我记住他了。我也记住了你们每一个人的脸。\n"
                .. "这条路往北走，出了城就是黑帮的地盘。\n"
                .. "我和那边的人很熟。\n"
                .. "今天的事，到此为止。\n"
                .. "如果有下次——'\n\n"
                .. "他没有说完。\n"
                .. "但追兵们互相看了看，\n"
                .. "慢慢后退了。\n\n"
                .. "火把的光一个接一个消失在巷口。\n\n"
                .. name .. "站在原地，看着他们走远。\n"
                .. "然后他转身，靠在墙上。\n"
                .. "双腿一软，差点跪下去。\n\n"
                .. "你冲过去扶住他。\n\n"
                .. "'……走吧。'他的声音恢复了平时的平淡。\n"
                .. "'我知道一个地方。安全的。'",
            choices = { { text = "你带路", target = "主线_K的酒馆" } },
        }
    end

    -- ==================== K的酒馆 ====================
    if passageName == "主线_K的酒馆" then
        local name = S.initialName

        local text = name .. "带着你穿过半个港城。\n"
            .. "天快亮了。街上开始有人走动。\n"
            .. "你们看起来一定很狼狈——\n"
            .. "两个浑身是土的年轻人，一个还在流血。\n\n"
            .. "最后他们停在一家酒馆门口。\n"
            .. "招牌上写着三个字，油漆已经剥落了大半。\n\n"

        if S.kMet then
            text = text
                .. "是K的酒馆。\n"
                .. "你来过这里。\n\n"
                .. name .. "推开门。K正在吧台后面擦杯子。\n"
                .. "他抬起头，看到你们的样子，\n"
                .. "手里的杯子放下了——但表情几乎没变。\n\n"
                .. "'进来。'他只说了两个字。\n"
                .. "然后他从吧台下面翻出急救箱。"
        else
            text = text
                .. name .. "推开门。\n\n"
                .. "吧台后面站着一个人。\n"
                .. "银白色的长发，碧绿的眼睛，\n"
                .. "耳朵尖尖的——精灵？\n"
                .. "他的头顶有一圈若隐若现的光环。\n\n"
                .. "'K。'莱德说。像是在叫一个很熟的人。\n\n"
                .. "那个叫K的人看了看" .. name .. "，\n"
                .. "又看了看你。\n"
                .. "他的表情很平静，甚至带着一点微笑。\n\n"
                .. "'进来吧。'他说。\n"
                .. "语气像是早就知道你们会来。\n\n"
                .. "他从吧台下面翻出急救箱，\n"
                .. "动作熟练得像做过无数次。"
            S.kMet = true
            NPCSystem.addAffection("k", 10)
        end

        text = text .. "\n\n"
            .. "K帮" .. name .. "处理伤口。\n"
            .. "擦药的时候" .. name .. "的眉头皱了一下，\n"
            .. "但一声没吭。\n\n"
            .. "你坐在旁边的椅子上，\n"
            .. "忽然觉得很累。全身的力气都在一瞬间抽空了。\n\n"
            .. "K包扎好伤口，直起身来。\n\n"
            .. "'你们今晚睡这里。\n"
            .. "楼上有空房间。不干净，但安全。'\n\n"
            .. "他看着你。\n"
            .. "'不要担心追兵的事。\n"
            .. "这间酒馆……有一些特殊的保护。\n"
            .. "只要你们在这里，没人能闯进来。'\n\n"
            .. "他微微笑了一下。\n"
            .. "那个笑容让你莫名安心——\n"
            .. "像是有什么远比你能理解的力量在守护着这个地方。"

        return {
            text = text,
            choices = { { text = "（继续）", target = "主线_新的清晨" } },
        }
    end

    -- ==================== 新的清晨 ====================
    if passageName == "主线_新的清晨" then
        local name = S.initialName
        S.mqStage = 5
        S.mqSettled = true
        S.mqSettledDay = S.day or 1  -- 记录安顿日期，用于第二章触发计时

        -- 大幅提升好感
        NPCSystem.addAffection("initialName", 30)
        NPCSystem.addAffection("k", 10)
        S.YG = S.YG + 2  -- 勇敢+2

        return {
            text = "你醒过来的时候，阳光从窗缝里照进来。\n\n"
                .. "你躺在一张嘎吱作响的木板床上，\n"
                .. "身上盖着一条洗得发白的毛毯。\n"
                .. "不知道是谁给你盖的。\n\n"
                .. "隔壁传来轻微的动静。\n"
                .. "你推门看了一眼——\n"
                .. name .. "睡在另一张床上，呼吸均匀。\n"
                .. "伤口上的绷带换过了。\n"
                .. "他的眉头在睡梦中是舒展的。\n\n"
                .. "你走下楼。\n"
                .. "K已经在吧台后面了。\n"
                .. "他递给你一杯热茶。\n\n"
                .. "'喝点东西。'他说。\n"
                .. "'昨天的事我大致听懂了。\n"
                .. "你们可以在这里住下来——\n"
                .. "不收房租。\n"
                .. "但酒馆的活你们得帮忙干。\n"
                .. "这算是……互相帮助吧。'\n\n"
                .. "他端起自己的杯子抿了一口。\n\n"
                .. "'还有——以后小心一点。\n"
                .. "魏德曼家不会善罢甘休的。\n"
                .. "不过……'\n\n"
                .. "他的碧绿眼睛里闪过一丝深意。\n"
                .. "'不管发生什么，我都会帮你们。\n"
                .. "这是我的工作。也是——'\n\n"
                .. "他没有说完，转身去洗杯子了。\n\n"
                .. "热茶在胃里暖开来。\n"
                .. "窗外是港城寻常的早晨——\n"
                .. "海鸥叫着，海风吹过来，带着盐的味道。\n\n"
                .. "一切都和昨天一样。\n"
                .. "又什么都不一样了。\n\n"
                .. "（" .. name .. "好感+30 K好感+10 勇敢+2）\n"
                .. "（主线任务完成：营救" .. name .. "）",
            choices = {
                { text = "新的一天开始了", target = "十字路口" },
            },
        }
    end

    return nil
end

return Ch1Passages
