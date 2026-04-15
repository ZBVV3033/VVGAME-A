-- ============================================================================
-- TownPassages_Special.lua - 特殊NPC互动段落
-- 黑帮少主、阿莫斯修士、罗伊、米娜修女、乌列尔信件、莱德K闲聊
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local kwOk, KW = pcall(require, "systems.KeywordSystem")
local U = require("passages.TownNPCUtils")

local handlers = {}

handlers["小镇_遇见黑帮少主"] = function()
    local S = GameState.state
    S.gangBossMet = true
    NPCSystem.addAffection("gangBoss", 5)
    TimeSystem.addMinutes(5)
    GameState.addDateLog("黑帮少主", "初遇", "在花街暗巷遇到了一个偷吃甜食的黑衣年轻人")

    if kwOk then KW.collectKeyword("political_news"); KW.collectKeyword("town_rumor") end
    return {
        text = "你悄悄跟上那个黑衣年轻人。\n\n"
            .. "他在巷子深处停下来，靠着墙壁，从纸袋里掏出一块——\n"
            .. "奶油蛋糕？\n\n"
            .. "他小口小口地吃着，表情认真得像在做什么重要的事。\n"
            .. "腮帮子鼓起来的样子和他凌厉的外表形成了巨大的反差。\n\n"
            .. "你没忍住，笑出了声。\n\n"
            .. "他猛地抬头，眼神瞬间变得锐利。\n"
            .. "手里的蛋糕差点掉地上——他以极快的速度稳住了。\n\n"
            .. "「……你看到了。」他的声音很低，不像是在陈述事实，\n"
            .. "更像是在确认一个威胁。\n\n"
            .. "但他没有做出进一步的动作。\n"
            .. "只是把蛋糕重新放回纸袋里，拍了拍手上的奶油渍。\n\n"
            .. "「我不知道你是谁。但如果你把刚才看到的说出去——」\n\n"
            .. "他没有说完。也许是觉得没必要把威胁说得太明显。\n"
            .. "又也许是因为他自己也知道，偷吃蛋糕这件事本身实在算不上什么秘密。\n\n"
            .. "（认识了一个奇怪的年轻人 好感+5）",
        choices = {
            {
                text = "🤐 我什么也没看到",
                target = S._settingsFrom or "花街",
                action = function()
                    NPCSystem.addAffection("gangBoss", 3)
                    GameState.showNotification("他微微点了一下头。似乎对你的态度比较满意。")
                end,
            },
            {
                text = "🍰 蛋糕好吃吗？",
                target = S._settingsFrom or "花街",
                action = function()
                    NPCSystem.addAffection("gangBoss", 5)
                    GameState.showNotification("他愣了一下。'……还行。'他小声说。")
                end,
            },
        },
    }
end

handlers["小镇_黑帮少主闲聊"] = function()
    local S = GameState.state
    NPCSystem.addAffection("gangBoss", 5)
    TimeSystem.addMinutes(5)
    local talks = {
        {
            text = "你朝他走过去。他警惕地把手里的东西往身后藏了藏。\n\n"
                .. "「……又是你。」他的语气不太热情，但也没有赶你走。\n\n"
                .. "你注意到他嘴角有一点奶油渍。\n\n"
                .. "「什么？」他伸手一擦。「……见鬼。」\n\n"
                .. "他靠在墙上，安静了一会儿。\n"
                .. "「你一个人在这座城？」\n"
                .. "你点了点头。\n"
                .. "「嗯。」他说，语气里似乎有一丝理解。\n"
                .. "「一个人挺好的。没人管你吃什么。」\n\n"
                .. "他从纸袋里掏出一块小饼干，犹豫了一下，递给你。\n"
                .. "「别告诉任何人。」\n\n"
                .. "（黑帮少主 好感+3）",
        },
        {
            text = "今天他没在吃东西，而是蹲在巷口数地上的蚂蚁。\n\n"
                .. "你愣了一下。他抬头看你，面无表情。\n"
                .. "「看什么。我在巡视。」\n"
                .. "「……巡视蚂蚁？」\n"
                .. "「巡视地盘。蚂蚁恰好路过。」\n\n"
                .. "你蹲到他旁边。两个人一起看蚂蚁搬面包渣。\n"
                .. "沉默了半分钟。\n\n"
                .. "「它们挺勤快的。」他忽然说。\n"
                .. "「比我手下那帮人强多了。」\n\n"
                .. "（黑帮少主 好感+3）",
        },
        {
            text = "你找到他的时候，他正在翻一本小册子。\n"
                .. "看到你走近，他飞快地把册子塞进怀里。\n\n"
                .. "「是甜品店的菜单？」你随口猜了一句。\n\n"
                .. "他的表情微妙地变了一下。\n"
                .. "「……不是。是情报。」\n\n"
                .. "你没有拆穿他。\n\n"
                .. "但你注意到他怀里那本'情报'的封面印着一个草莓蛋糕。\n\n"
                .. "（黑帮少主 好感+3）",
        },
    }
    local talk = talks[math.random(1, #talks)]
    return {
        text = talk.text,
        choices = { { text = "继续", target = S._settingsFrom or "花街" } },
    }
end

handlers["小镇_遇见阿莫斯"] = function()
    local S = GameState.state
    S.npcBrotherAmosMet = true
    S.npcBrotherAmos = S.npcBrotherAmos + 5
    TimeSystem.addMinutes(5)
    GameState.addDateLog("阿莫斯修士", "初遇", "在教堂图书室认识了阿莫斯修士")
    return {
        text = "你推开教堂的侧门走进去。\n\n"
            .. "里面是一间不大的图书室，墙壁被书架填得满满当当。\n"
            .. "阳光从彩色玻璃窗透进来，在书脊上投下斑斓的光斑。\n\n"
            .. "那个年轻修士正站在梯子上，把一本厚书放回高处的架子。\n"
            .. "他的动作很轻，像是怕吵醒书里沉睡的故事。\n\n"
            .. "他注意到你，推了推圆框眼镜。\n\n"
            .. "「你好。欢迎来图书室。」\n\n"
            .. "他从梯子上下来，拍了拍僧袍上的灰尘。\n"
            .. "「我叫阿莫斯。负责这里的图书管理。\n"
            .. "如果你想借书的话——呃，目前不对外借阅。\n"
            .. "但是你可以在这里看。」\n\n"
            .. "他歉意地笑了笑。\n"
            .. "「上次对外借阅，有人拿《神圣咒语大全》垫桌脚。\n"
            .. "从那以后主教就不让借了。」\n\n"
            .. "（认识了阿莫斯修士 好感+5）",
        choices = {
            {
                text = "📚 看看有什么有趣的书",
                target = S._settingsFrom or "主城区",
                action = function()
                    S.npcBrotherAmos = S.npcBrotherAmos + 2
                    GameState.modStat("LG", 1)
                    GameState.showNotification("你在图书室待了一会儿。灵感+1。")
                end,
            },
            {
                text = "继续",
                target = S._settingsFrom or "主城区",
            },
        },
    }
end

handlers["小镇_阿莫斯闲聊"] = U.chat { var = "npcBrotherAmos", loc = "主城区",
    talks = {
        {
            text = "阿莫斯今天在修补一本破损的书。\n\n"
                .. "他用极细的毛笔蘸着浆糊，一点一点粘合撕裂的书页。\n"
                .. "「这本书有两百年了。」他头也不抬地说。\n"
                .. "「里面记录了这座城最早的地图。\n"
                .. "你知道吗？两百年前这里根本没有港口。」\n\n"
                .. "他翻出一页，上面画着海岸线的草图。\n"
                .. "「那时候的海岸线比现在往内陆退了差不多一百米。\n"
                .. "是后来修建防波堤，才有了现在的港口。」\n\n"
                .. "你在他身边待了一会儿。\n"
                .. "图书室里安静得只有翻书声和远处鸽子的咕咕叫。\n\n"
                .. "（阿莫斯 好感+3）",
        },
        {
            text = "「你对魔法感兴趣吗？」阿莫斯忽然问你。\n\n"
                .. "不等你回答，他从角落的书架上抽出一本薄薄的小书。\n"
                .. "「这本是入门读物。不涉及实际咒语，所以可以给你看。\n"
                .. "主要讲魔力的流动方式——比较枯燥。」\n\n"
                .. "你翻开看了几页。确实很枯燥。\n"
                .. "但阿莫斯在旁边一边整理书架一边解释，\n"
                .. "倒是听懂了不少。\n\n"
                .. "他对这些知识有真挚的热情——\n"
                .. "讲到兴奋的地方，眼镜都歪了也没注意。\n\n"
                .. "（阿莫斯 好感+3）",
        },
        {
            text = "你走进图书室的时候，阿莫斯在打瞌睡。\n\n"
                .. "他趴在桌子上，圆框眼镜歪到一边，面前摊着一本翻开的书。\n"
                .. "桌上还放着一杯已经凉了的茶。\n\n"
                .. "你轻手轻脚地在旁边坐下来，翻了翻他正在看的书。\n"
                .. "是一本关于古代遗迹的考察笔记。\n\n"
                .. "他醒过来的时候，看到你在看书，有些不好意思地扶正眼镜。\n"
                .. "「……我不是在偷懒。是昨晚整理新到的捐赠书籍到太晚了。」\n\n"
                .. "他打了个哈欠。「新到了三箱书。三箱！」\n"
                .. "他说这话时的语气，像是在说'三箱金币'。\n\n"
                .. "（阿莫斯 好感+3）",
        },
    },
}

handlers["小镇_遇见罗伊"] = function()
    local S = GameState.state
    S.npcMerchantRoyMet = true
    S.npcMerchantRoy = S.npcMerchantRoy + 5
    TimeSystem.addMinutes(5)
    GameState.addDateLog("罗伊", "初遇", "在港口认识了来路不明的杂货贩子罗伊")
    return {
        text = "你走近那个蹲在地上的人。他抬起头，露出一个狡猾的笑容。\n\n"
            .. "「嘿，年轻人。第一次见。」\n\n"
            .. "他摊开的布上放着几样东西：一枚铜质怀表、\n"
            .. "一个磨损的放大镜、一小瓶不明液体，还有一块奇怪的石头。\n\n"
            .. "「我叫罗伊。做点小买卖，混口饭吃。」\n\n"
            .. "他拿起那块石头晃了晃。\n"
            .. "「看到这个了吗？据说是从远东运来的魔法石。\n"
            .. "放在枕头底下可以做好梦。」\n\n"
            .. "你有些怀疑。他咧嘴笑了。\n"
            .. "「好吧，我也不确定。但至少颜色挺好看的，对吧？\n"
            .. "做买卖嘛，真真假假的，乐趣就在这里。」\n\n"
            .. "他说话的方式有种让人放不下警惕又讨厌不起来的魅力。\n\n"
            .. "（认识了罗伊 好感+5）",
        choices = {
            {
                text = "🔍 问问他还有什么好东西",
                target = S._settingsFrom or "港口",
                action = function()
                    S.npcMerchantRoy = S.npcMerchantRoy + 2
                    GameState.showNotification("罗伊如数家珍地介绍了几样'宝贝'。真假难辨，但听着挺有意思。")
                end,
            },
            {
                text = "继续",
                target = S._settingsFrom or "港口",
            },
        },
    }
end

handlers["小镇_罗伊闲聊"] = U.chat { var = "npcMerchantRoy", loc = "港口",
    talks = {
        {
            text = "「来来来，看看新货。」罗伊热情地招呼你。\n\n"
                .. "他摊子上多了一个小木盒。他故作神秘地打开——\n"
                .. "里面是一面巴掌大的铜镜。\n\n"
                .. "「据说是某位落魄贵族家传的。」\n"
                .. "他压低声音，「照这面镜子能看到自己的前世。」\n\n"
                .. "你拿起来照了照。看到了自己灰扑扑的脸。\n\n"
                .. "「……也许你的前世就长这样？」罗伊一脸无辜地说。\n\n"
                .. "（罗伊 好感+3）",
        },
        {
            text = "罗伊今天没在卖东西，而是在码头边吃烤鱼。\n\n"
                .. "「收摊了？」你问。\n\n"
                .. "「今天生意不好。就卖出去一根绳子。」\n"
                .. "他咬了口鱼。「不过也无所谓。\n"
                .. "做这行最重要的不是赚钱，是自由。」\n\n"
                .. "他望着远处的大海。\n"
                .. "「我以前在一家大商行干过。工钱是不错，\n"
                .. "但每天要穿一样的衣服、说一样的话。\n"
                .. "干了三年，有天早上起来突然不想去了。」\n\n"
                .. "他掰了半条鱼给你。\n"
                .. "「然后就变成了现在这个样子。怎么说呢——\n"
                .. "穷是穷了点，但心里舒坦。」\n\n"
                .. "（罗伊 好感+3）",
        },
        {
            text = "你走过去的时候，罗伊正和一个水手争执。\n\n"
                .. "「这明明是假的！」水手拿着一个铜扣大声说。\n"
                .. "「我什么时候说过它是真的了？」罗伊摊手。\n"
                .. "「你自己说'这东西很有价值'！」\n"
                .. "「有价值啊。它有观赏价值。」\n\n"
                .. "水手被气笑了，骂了一句走了。\n"
                .. "罗伊冲你眨了眨眼。\n\n"
                .. "「做买卖嘛。最重要的是——」\n"
                .. "他竖起一根手指。\n"
                .. "「永远不要亲口说'这是真的'。\n"
                .. "说'有价值'就行了。世界上什么东西没有价值呢？」\n\n"
                .. "（罗伊 好感+3）",
        },
    },
}

handlers["小镇_遇见米娜"] = function()
    local S = GameState.state
    S.npcSisterMinaMet = true
    S.npcSisterMina = S.npcSisterMina + 5
    TimeSystem.addMinutes(5)
    GameState.addDateLog("米娜", "初遇", "在花园小镇遇到了带孤儿散步的年轻修女米娜")
    return {
        text = "你走近那个年轻修女。\n\n"
            .. "她正蹲下来给一个小男孩擦鼻涕。\n"
            .. "旁边的孩子们叽叽喳喳地讨论着刚才看到的蝴蝶。\n\n"
            .. "「姐姐！那个蝴蝶是蓝色的！」\n"
            .. "「不对！是紫色的！」\n"
            .. "「是蓝紫色！」\n\n"
            .. "修女站起身来，注意到你在看她，温和地笑了笑。\n\n"
            .. "「你好。我叫米娜。是教堂孤儿院的。\n"
            .. "天气好的时候我会带孩子们出来走走。」\n\n"
            .. "一个小女孩拽着她的袖子：\n"
            .. "「米娜姐姐，那个人是谁呀？」\n\n"
            .. "「是路过的好人哦。」米娜微笑着说。\n\n"
            .. "你不确定自己够不够格被叫'好人'，\n"
            .. "但她说话的语气让人没法反驳。\n\n"
            .. "（认识了米娜 好感+5）",
        choices = {
            {
                text = "🌼 帮她一起看着孩子们",
                target = S._settingsFrom or "花园小镇",
                action = function()
                    S.npcSisterMina = S.npcSisterMina + 3
                    TimeSystem.addMinutes(10)
                    GameState.showNotification("你帮米娜看了一会儿孩子。虽然有点吵，但挺开心的。")
                end,
            },
            {
                text = "继续",
                target = S._settingsFrom or "花园小镇",
            },
        },
    }
end

handlers["小镇_乌列尔信件"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(3)
    NPCSystem.addUrielAffection(3)
    return {
        text = "你仔细看那个蜡封。\n\n"
            .. "红色的蜡，压出的印记是一只展翅的鸟。\n"
            .. "做工很精致——不是普通人用的东西。\n\n"
            .. "你翻过信封。没有寄件地址，也没有邮戳。\n"
            .. "是有人亲手送过来放进信箱的。\n\n"
            .. "再看那行字——\n"
            .. "'吃饱了吗。天冷了加衣服。'\n\n"
            .. "笔迹工整到近乎刻板，但最后的'服'字收笔时有一个弯勾。\n"
            .. "像是写字的人犹豫了一下——想再写点什么，又忍住了。\n\n"
            .. "你闻了闻信纸。\n"
            .. "有很淡很淡的皂角花香气。\n\n"
            .. "你不知道是谁寄的。\n"
            .. "但你把信小心地折好，放进了衣服内袋里。\n\n"
            .. "（收到了一封来路不明的信）",
        choices = { { text = "继续", target = S._settingsFrom or "十字路口" } },
    }
end

handlers["小镇_莱德K闲聊"] = function()
    local S = GameState.state
    TimeSystem.addMinutes(5)
    NPCSystem.addAffection("initialName", 3)
    NPCSystem.addAffection("k", 3)
    local scenes = {
        {
            text = "你凑过去，听到了两人对话的片段。\n\n"
                .. S.initialName .. "：「……所以你到底是什么？精灵？半精灵？」\n\n"
                .. "K不紧不慢地回答：「你到底是什么？人类？半人类？」\n\n"
                .. S.initialName .. "一愣，然后笑了出来。\n"
                .. "「行吧，算你赢了。」\n\n"
                .. "K转过头看到你，挑了挑眉。\n"
                .. "「小家伙也来了？正好，帮我评评理——\n"
                .. "刚才这位先生说我做的酒太烈了。」\n\n"
                .. S.initialName .. "连忙辩解：「我是说对大多数人来说太烈了！\n"
                .. "我自己喝没问题的！」\n\n"
                .. "（" .. S.initialName .. " 好感+3 K好感+3）",
        },
        {
            text = "走近一看，" .. S.initialName .. "正在给K看手上的伤痕。\n\n"
                .. S.initialName .. "：「搬货的时候磨的。不碍事。」\n\n"
                .. "K皱了皱眉，不知道从哪里掏出一小瓶药膏。\n"
                .. "「涂上。三天就好。」\n\n"
                .. S.initialName .. "有些意外：「你随身带这种东西？」\n\n"
                .. "K：「调酒的人手不能受伤。多备一些而已。」\n\n"
                .. "他看到你过来，补了一句：\n"
                .. "「别想太多，我只是不想看到这只手浪费了。」\n\n"
                .. "（" .. S.initialName .. " 好感+3 K好感+3）",
        },
    }
    local scene = scenes[math.random(1, #scenes)]
    return {
        text = scene.text,
        choices = { { text = "继续", target = S._settingsFrom or "十字路口" } },
    }
end

return handlers
