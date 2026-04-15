-- ============================================================================
-- KeywordSystem.lua - 关键词收集与好感角色闲聊系统
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")

local KeywordSystem = {}

-- ==================== 分类定义 ====================
KeywordSystem.CATEGORIES = {
    adventure = { name = "冒险", icon = "⚔️" },
    port      = { name = "港口", icon = "⚓" },
    smithing  = { name = "锻造", icon = "🔨" },
    animals   = { name = "动物", icon = "🐾" },
    culture   = { name = "文化", icon = "📚" },
    church    = { name = "教堂", icon = "⛪" },
    cooking   = { name = "烹饪", icon = "🍳" },
    garden    = { name = "花园", icon = "🌸" },
    social    = { name = "社交", icon = "🗣️" },
    etiquette = { name = "礼仪", icon = "🎩" },
    commerce  = { name = "商业", icon = "💰" },
    gossip    = { name = "八卦", icon = "👂" },
    academics = { name = "学术", icon = "🎓" },
    history   = { name = "历史", icon = "📜" },
    luxury    = { name = "奢华", icon = "💎" },
    power     = { name = "权力", icon = "👑" },
}

-- ==================== 角色兴趣映射 ====================
-- 3=非常感兴趣(+5) 2=感兴趣(+3) 1=一般(+1) 0=无兴趣(0)
KeywordSystem.CHARACTER_INTERESTS = {
    leiDe = {
        adventure = 3, port = 3, smithing = 2, animals = 2,
        culture = 1, church = 0, cooking = 1, garden = 0,
        social = 0, etiquette = 0, commerce = 0, gossip = 0,
        academics = 1, history = 1, luxury = 0, power = 0,
    },
    k = {
        adventure = 0, port = 1, smithing = 0, animals = 2,
        culture = 3, church = 2, cooking = 3, garden = 3,
        social = 1, etiquette = 1, commerce = 0, gossip = 0,
        academics = 2, history = 1, luxury = 0, power = 0,
    },
    meifei = {
        adventure = 0, port = 1, smithing = 0, animals = 0,
        culture = 1, church = 0, cooking = 1, garden = 1,
        social = 3, etiquette = 3, commerce = 3, gossip = 3,
        academics = 0, history = 1, luxury = 2, power = 2,
    },
    oamel = {
        adventure = 1, port = 0, smithing = 0, animals = 0,
        culture = 2, church = 1, cooking = 0, garden = 0,
        social = 1, etiquette = 2, commerce = 2, gossip = 1,
        academics = 3, history = 3, luxury = 3, power = 3,
    },
}

-- ==================== 关键词数据库 ====================
KeywordSystem.KEYWORDS = {
    -- 冒险
    storm_tale    = { name = "暴风雨传说", category = "adventure", desc = "老尤金讲的银鱼暴风雨故事" },
    sea_monster   = { name = "海怪传闻",   category = "adventure", desc = "水手们口中的深海巨兽" },
    sword_scar    = { name = "剑痕",       category = "adventure", desc = "铁匠铺里一把断剑上的故事" },
    -- 港口
    cargo_ship    = { name = "远洋货船",   category = "port", desc = "从南方来的大帆船" },
    sailor_knot   = { name = "水手结",     category = "port", desc = "老尤金教的绳结打法" },
    fish_market   = { name = "鱼市行情",   category = "port", desc = "小梅说的今日鱼价" },
    -- 锻造
    quench_method = { name = "淬火秘法",   category = "smithing", desc = "麦拿拿传授的淬火技巧" },
    dwarf_craft   = { name = "矮人工艺",   category = "smithing", desc = "麦拿拿的锻造哲学" },
    -- 动物
    stray_cat     = { name = "流浪猫",     category = "animals", desc = "酒馆收养的那只小猫" },
    plaza_pigeons = { name = "广场鸽子",   category = "animals", desc = "薇拉奶奶喂的鸽子群" },
    -- 文化
    ancient_book  = { name = "古籍残页",   category = "culture", desc = "教堂图书室的古书" },
    street_art    = { name = "街头画作",   category = "culture", desc = "艾琳画的紫色天空十字路口" },
    northern_ballad = { name = "北方牧歌", category = "culture", desc = "达里奥弹的北方草原曲子" },
    -- 教堂
    sun_scripture = { name = "太阳神经典", category = "church", desc = "克丽丝讲的太阳神故事" },
    healing_prayer = { name = "治愈祷告", category = "church", desc = "在社区大学学到的祷文" },
    -- 烹饪
    sourdough     = { name = "酸面团",     category = "cooking", desc = "费利克斯养了二十年的酸面团" },
    new_recipe    = { name = "新食谱",     category = "cooking", desc = "最近学会的料理做法" },
    spice_secret  = { name = "调味秘诀",   category = "cooking", desc = "烹饪课上学到的搭配技巧" },
    -- 花园
    herb_knowledge = { name = "草药知识", category = "garden", desc = "伊莎贝拉教的薄荷采摘时机" },
    flower_language = { name = "花语",   category = "garden", desc = "莉莉安说的雏菊花语" },
    crop_harvest   = { name = "丰收体验", category = "garden", desc = "自家菜地的收获" },
    -- 社交
    tavern_gossip  = { name = "酒馆见闻", category = "social", desc = "酒馆打工时听到的各种消息" },
    market_bustle  = { name = "集市热闹", category = "social", desc = "商业区的各种叫卖和趣事" },
    -- 礼仪
    noble_manners  = { name = "贵族礼仪", category = "etiquette", desc = "在晚宴上学到的礼节" },
    toast_words    = { name = "祝酒词",   category = "etiquette", desc = "在花街学到的社交辞令" },
    -- 商业
    vendor_trick   = { name = "商贩话术", category = "commerce", desc = "罗伊教的推销哲学" },
    stall_experience = { name = "摆摊心得", category = "commerce", desc = "自己出摊卖食物的经验" },
    -- 八卦
    mystery_letter = { name = "神秘来信", category = "gossip", desc = "不知名者寄来的信" },
    gang_rumor     = { name = "花街传闻", category = "gossip", desc = "花街暗巷里的势力暗涌" },
    -- 学术
    magic_theory   = { name = "魔法理论", category = "academics", desc = "社区大学学到的魔力流转" },
    combat_training = { name = "战术训练", category = "academics", desc = "社区大学学到的战斗技巧" },
    -- 历史
    old_map        = { name = "古地图",   category = "history", desc = "阿莫斯给你看的200年前地图" },
    vera_magic     = { name = "薇拉的魔法", category = "history", desc = "薇拉奶奶让植物冬天开花的秘密" },
    -- 奢华
    crystal_chandelier = { name = "水晶吊灯", category = "luxury", desc = "妖精的邀请里的奢华装饰" },
    noble_outfit   = { name = "华丽礼服", category = "luxury", desc = "晚宴上的各种华丽礼服" },
    -- 权力
    gang_territory = { name = "地盘争夺", category = "power", desc = "黑帮少主暗示的势力划分" },
    noble_hierarchy = { name = "贵族等级", category = "power", desc = "从晚宴观察到的贵族关系" },
}

-- ==================== 对话数据库 ====================
-- CHAT_DIALOGUES[角色key][关键词id] = { function(name)->string, ... }

KeywordSystem.CHAT_DIALOGUES = {
    -- ==================== 莱德 ====================
    leiDe = {
        storm_tale = {
            function(n) return '你提起老尤金讲的暴风雨故事。\n\n' .. n .. ' 沉默了一会儿，低声说：\n"银鱼救船……听起来像是编的。但大海确实有很多人不了解的东西。"\n\n他的眼神变得有些遥远。' end,
            function(n) return '"老尤金的故事都是真的吗？"你好奇地问。\n\n' .. n .. ' 想了想：\n"真不真的不重要。重要的是……他愿意一遍又一遍地讲。"\n\n你第一次听到' .. n .. '对别人的评价这么温和。' end,
        },
        sea_monster = {
            function(n) return '你聊起港口水手说的海怪传闻。\n\n' .. n .. ' 忽然来了兴趣：\n"深海巨兽？……我在古书里见过类似的记载。"\n他难得主动凑近了些："具体说说，什么样的？"' end,
            function(n) return '"听说港口外海有海怪出没。"\n\n' .. n .. ' 挑了挑眉："如果是真的，总有一天要去看看。"\n他的语气平淡，但你感觉他是认真的。' end,
        },
        sword_scar = {
            function(n) return '你提到铁匠铺里那把断剑上的痕迹。\n\n' .. n .. ' 的目光锐利了一瞬：\n"那种剑痕……不是普通武器留下的。"\n他顿了顿："……你别碰那些东西。"' end,
            function(n) return '"铁匠铺有把断剑，上面有很奇怪的痕迹。"\n\n' .. n .. ' 接过话："……是魔法留下的。某种高阶的切割术式。"\n\n他看了你一眼："你倒是观察力不错。"' end,
        },
        cargo_ship = {
            function(n) return '你说起港口来了艘远洋大船。\n\n' .. n .. ' 望向窗外的方向：\n"南方来的……那边的海域很危险。能活着到这里的船，都不简单。"' end,
            function(n) return '"今天港口来了好大一艘帆船！"\n\n' .. n .. ' 若有所思："……有时候我在想，如果坐上那种船，能走多远。"\n\n他说完，像是不小心暴露了什么，很快转开了话题。' end,
        },
        quench_method = {
            function(n) return '你兴奋地描述了麦拿拿教的淬火技巧。\n\n' .. n .. ' 难得露出了感兴趣的表情：\n"水淬还是油淬？温度控制在什么范围？"\n\n你被问住了。' .. n .. ' 轻笑一声："下次帮我问清楚。"' end,
            function(n) return '"麦拿拿说好钢要经过千锤百炼。"\n\n' .. n .. ' 沉默片刻，轻声说：\n"人也一样吧。"\n\n你感觉他说的不只是铁匠铺的事。' end,
        },
        stray_cat = {
            function(n) return '你聊起酒馆收养的那只小猫。\n\n' .. n .. ' 的表情柔和了一瞬：\n"……它还好吧？吃得够吗？"\n\n你没想到' .. n .. '会关心一只猫。他注意到你的目光，别过脸去："……随便问问。"' end,
            function(n) return '"小猫今天追着自己的尾巴转了好久。"\n\n' .. n .. ' 嘴角微微上扬，虽然很快压了下去：\n"……幼稚。"\n\n但你分明看到他在忍笑。' end,
        },
        plaza_pigeons = {
            function(n) return '你说起广场上薇拉奶奶喂的鸽子。\n\n' .. n .. ' 回忆了一下：\n"那些鸽子……其中有只是信鸽。我认得出来。"\n\n他说得很随意，但你觉得这个信息并不简单。' end,
        },
    },

    -- ==================== K ====================
    k = {
        sourdough = {
            function(n) return '你提到费利克斯养了二十年的酸面团。\n\nK眼睛亮了起来：\n"二十年？那个酵母菌群一定非常稳定了。好的面包就像好的酒——需要时间。"\n\n她难得说了这么长一段话。' end,
            function(n) return '"费利克斯说心情好的时候面团更好。"\n\nK认真地想了想：\n"可能不是迷信。情绪影响手法力度，力度影响面筋结构……从科学角度看，说得通。"\n\n你忍不住笑了。K疑惑地看你。' end,
        },
        new_recipe = {
            function(n) return '你得意地分享了最近学会的新菜式。\n\nK听得很认真，时不时点头：\n"……听起来不错。下次做的话……可以叫我。"\n\n她说完脸微微红了一下。' end,
            function(n) return '"我学会做新菜了！"\n\nK歪了歪头："什么菜？"\n你描述了一番。她沉默半晌："……能尝尝吗？"\n\n语气很轻，像是怕被拒绝。' end,
        },
        flower_language = {
            function(n) return '"莉莉安说雏菊的花语是「一切都会好起来」。"\n\nK低头沉默了一会儿。\n"……真好。"她的声音很轻。"如果花能说话的话。"' end,
            function(n) return '你说起莉莉安教你的花语。\n\nK忽然问："你知道蓝色铃兰的花语吗？"\n你摇头。\n"「再次相遇的幸福」。"她说完就转过头去了。' end,
        },
        herb_knowledge = {
            function(n) return '你分享了伊莎贝拉教的草药知识。\n\nK的精灵耳微微颤动，表情变得柔和：\n"薄荷……在精灵的传说中是守护草。用来编花环。"\n\n她的目光有些悠远。' end,
            function(n) return '"伊莎贝拉说薄荷要在清晨露水干之前采。"\n\nK点点头："精灵也是这样做的。植物在清晨最有灵气。"\n\n你第一次听她主动提起精灵。' end,
        },
        crop_harvest = {
            function(n) return '你兴奋地说起菜地里的第一次丰收。\n\nK听着，嘴角慢慢上扬：\n"自己种的……一定很好吃。"\n\n她想了想，补充道："……能分我一点吗？"' end,
        },
        ancient_book = {
            function(n) return '你提到教堂图书室的古籍残页。\n\nK的表情变得严肃：\n"那些书……有些内容不应该被遗忘。"\n她停顿片刻："有机会的话，我也想去看看。"' end,
            function(n) return '"阿莫斯修士给我看了两百年前的古书。"\n\nK安静地听着，然后轻声说：\n"两百年……对精灵来说还不算太久。\n但足以改变一个国家了。"' end,
        },
        street_art = {
            function(n) return '你描述了艾琳画的那幅紫色天空的十字路口。\n\nK很认真地想象着那幅画：\n"紫色的天空……她画的可能不是天空的颜色，\n而是她眼中这座城市的颜色。"\n\n你觉得K说得很有道理。' end,
        },
        northern_ballad = {
            function(n) return '你哼起达里奥教你的北方牧歌旋律。\n\nK静静地听，精灵耳跟着旋律微微抖动。\n\n曲毕，她轻声说："这首歌……精灵也有一个类似的版本。"\n她没有唱，但你能感觉到她被触动了。' end,
        },
        sun_scripture = {
            function(n) return '你聊起克丽丝讲的太阳神故事。\n\nK想了一下："太阳神……不同种族有不同的名字。\n但核心都一样——光明驱散黑暗。"\n\n她看着窗外的天空："……我相信光。"' end,
        },
    },

    -- ==================== 梅菲斯 ====================
    meifei = {
        tavern_gossip = {
            function(n) return '你把酒馆里听到的消息说给梅菲斯听。\n\n他举起酒杯遮住半张脸，眼里带着笑意：\n"不错，继续。你在酒馆的位置很好……\n有些消息从下面传上来才最真实。"' end,
            function(n) return '"酒馆最近来了个可疑的外地人。"\n\n梅菲斯放下扇子，目光微亮：\n"什么样的？穿着？口音？"\n\n你尽力描述，他若有所思地点了点头：\n"有意思。你的观察力进步了。"' end,
        },
        noble_manners = {
            function(n) return '你提起在晚宴上学到的礼节。\n\n梅菲斯挑起眉毛，唇角含笑：\n"哦？学了几分皮毛就来跟我炫耀了？"\n\n他打量了你一下："不过……至少比第一次见面时像样了。"' end,
            function(n) return '"梅菲斯，贵族用餐时为什么要从外侧开始用刀叉？"\n\n他放下酒杯，意味深长地笑了：\n"因为规则本身就是权力的一部分。谁制定规则，谁就站在上面。"\n\n他的眼神犀利而深邃。' end,
        },
        toast_words = {
            function(n) return '你试着用在花街学到的祝酒词敬了梅菲斯一杯。\n\n他听完，轻轻鼓掌：\n"词不错，但是你的眼神不够自信。"\n他又给自己倒了一杯："社交的核心不是言辞，是气场。"' end,
        },
        vendor_trick = {
            function(n) return '你说起罗伊教的推销哲学。\n\n梅菲斯笑了："罗伊那套……只能骗骗小鬼。\n真正的谈判，是让对方觉得自己占了便宜。"\n\n他看着你："想学吗？代价可不便宜。"' end,
            function(n) return '"罗伊说卖东西最重要的是「把需要变成想要」。"\n\n梅菲斯点头："他说得对，但只对了一半。\n最高明的是——让对方觉得这是他自己的主意。"\n\n你感觉学到了很厉害的东西。' end,
        },
        stall_experience = {
            function(n) return '你分享了摆摊卖小吃的经验。\n\n梅菲斯听得饶有兴致：\n"小本生意也是生意。你学会了定价、推销、还有看人下菜碟。"\n\n他举杯："敬你的第一桶金。"' end,
        },
        market_bustle = {
            function(n) return '你绘声绘色地描述了商业区的热闹场面。\n\n梅菲斯托着下巴听：\n"集市是最好的情报来源。每个小贩都是眼线，每笔交易都是线索。"\n\n他看你的眼神带着几分赞许："你开始用正确的方式看世界了。"' end,
        },
        gang_rumor = {
            function(n) return '你小心翼翼地提起花街的传闻。\n\n梅菲斯的笑容没变，但眼神冷了几度：\n"你听到了什么？"\n\n停了一拍，他又笑起来："开玩笑的。不过我建议你……少打听不该打听的事。"' end,
        },
        crystal_chandelier = {
            function(n) return '你赞叹妖精的邀请里的水晶吊灯有多华丽。\n\n梅菲斯轻笑一声：\n"那些水晶是从北方矿脉运来的。光是运费就够买十间酒馆。"\n\n他的语气很随意，但你隐约感觉到了某种骄傲。' end,
        },
        noble_hierarchy = {
            function(n) return '你试探着聊起晚宴上的贵族关系。\n\n梅菲斯放下酒杯，表情变得认真：\n"你能看出来？不错。"\n他压低声音："记住——在那种场合，坐在谁旁边，比吃什么重要一百倍。"' end,
        },
    },

    -- ==================== 奥梅尔 ====================
    oamel = {
        noble_hierarchy = {
            function(n) return '你提起晚宴上观察到的贵族等级关系。\n\n奥梅尔放下酒杯，眼中闪过赞许：\n"你比我想象的敏锐。在那种场合能看出权力关系的人不多。"\n\n他微微点头："也许你适合走更远的路。"' end,
            function(n) return '"奥梅尔少爷，那些伯爵之间是什么关系？"\n\n他露出一个复杂的笑容：\n"表面上？盟友。实际上？……你觉得在狼群里会有真正的「朋友」吗？"\n\n他没有继续说下去，但你觉得学到了很多。' end,
        },
        old_map = {
            function(n) return '你说起阿莫斯给你看的200年前古地图。\n\n奥梅尔忽然认真起来：\n"那张地图——上面有没有标注家族纹章？我们罗斯巴特家的领地……"\n\n他顿住了，挥挥手："算了。旧事不提。"' end,
            function(n) return '"古地图上的边界线和现在完全不同。"\n\n奥梅尔端起酒杯，若有所思：\n"两百年前……这里还是一片荒地。\n罗斯巴特家的先祖是第一批开拓者。"\n\n他的语气里带着一丝不易察觉的骄傲。' end,
        },
        vera_magic = {
            function(n) return '你聊起薇拉奶奶让植物冬天开花的魔法。\n\n奥梅尔来了兴趣：\n"生命魔法……那是非常古老的流派。\n现在会的人已经不多了。"\n\n他沉吟片刻："那位老太太……不简单。"' end,
        },
        magic_theory = {
            function(n) return '你分享了在社区大学学到的魔法理论。\n\n奥梅尔听得很认真：\n"魔力流转的基础……你学得不错。\n不过理论和实践之间，隔着一道鸿沟。"\n\n他举起手，指尖微微发光："像这样。需要感受，不只是理解。"' end,
            function(n) return '"魔法理论说魔力存在于万物之中。"\n\n奥梅尔点点头：\n"说得简单。但能感知到的人，千中无一。"\n他看了你一眼："你……有那种潜质吗？"' end,
        },
        combat_training = {
            function(n) return '你聊起社区大学的战术训练内容。\n\n奥梅尔微笑：\n"社区大学教的那些……只是皮毛。\n真正的战斗，在书本之外。"\n\n他放下酒杯："不过基础很重要。先把皮毛学扎实。"' end,
        },
        crystal_chandelier = {
            function(n) return '你说起妖精的邀请里的水晶吊灯。\n\n奥梅尔淡淡一笑：\n"那些？在我家的宴会厅里只能算中等。"\n\n你不确定他是在炫耀还是在陈述事实。可能两者都是。' end,
        },
        noble_outfit = {
            function(n) return '你描述了晚宴上看到的华丽礼服。\n\n奥梅尔打量了一下你的衣着，微微摇头：\n"你的穿着……嗯。改天我让诺拉帮你量个尺寸。"\n\n他说得很自然，仿佛帮人定制礼服是再平常不过的事。' end,
        },
        gang_territory = {
            function(n) return '你小心地提起黑帮少主说的地盘划分。\n\n奥梅尔的表情没什么变化：\n"那些人……不过是在权力的阴影里捡残渣。\n真正的势力划分，发生在更高的地方。"\n\n他的语气让你意识到，罗斯巴特家的视野远不止于此。' end,
        },
        ancient_book = {
            function(n) return '你提到教堂图书室里的古籍。\n\n奥梅尔来了兴趣：\n"那里有些书……是外面买不到的。\n如果你能帮我找几本特定的……"\n\n他欲言又止，然后笑了笑："下次再说吧。"' end,
        },
    },
}

-- ==================== 敷衍回应（兴趣不足时） ====================
KeywordSystem.FALLBACK_DIALOGUES = {
    leiDe = {
        mild = {
            function(n) return n .. ' 听了你说的话，淡淡地"嗯"了一声。\n似乎不太感兴趣，但也没有打断你。' end,
            function(n) return n .. ' 静静听着，然后说："……不太了解这个。"' end,
        },
        none = {
            function(n) return n .. ' 微微皱眉："……跟我说这个做什么。"' end,
        },
    },
    k = {
        mild = {
            function(n) return 'K想了想：\n"嗯……有点意思。不过我不太懂这个。"' end,
        },
        none = {
            function(n) return 'K歪了歪头："这个……跟我没什么关系吧？"' end,
        },
    },
    meifei = {
        mild = {
            function(n) return '梅菲斯轻轻摇了摇扇子：\n"哦？说来听听。"\n\n他听完后微笑："还行。"' end,
        },
        none = {
            function(n) return '梅菲斯看了你一眼：\n"这种事……不在我的兴趣范围内。"' end,
        },
    },
    oamel = {
        mild = {
            function(n) return '奥梅尔抿了口酒：\n"有点意思。继续。"\n\n不过他很快就转移了话题。' end,
        },
        none = {
            function(n) return '奥梅尔不置可否地点点头：\n"和我无关。还有别的想聊的吗？"' end,
        },
    },
}

-- ==================== 核心函数 ====================

--- 收集关键词
---@param keywordId string
---@return boolean 是否新收集
function KeywordSystem.collectKeyword(keywordId)
    local S = GameState.state
    if not S.collectedKeywords then S.collectedKeywords = {} end
    if S.collectedKeywords[keywordId] then return false end
    local kw = KeywordSystem.KEYWORDS[keywordId]
    if not kw then return false end
    S.collectedKeywords[keywordId] = true
    local cat = KeywordSystem.CATEGORIES[kw.category]
    GameState.showNotification("解锁新话题: " .. (cat and cat.icon or "") .. " " .. kw.name)
    return true
end

--- 获取角色感兴趣的已收集关键词（兴趣>=2）
---@param characterKey string "leiDe"/"k"/"meifei"/"oamel"
---@return table[]
function KeywordSystem.getInterestedKeywords(characterKey)
    local S = GameState.state
    if not S.collectedKeywords then return {} end
    local interests = KeywordSystem.CHARACTER_INTERESTS[characterKey]
    if not interests then return {} end
    local result = {}
    for kwId, _ in pairs(S.collectedKeywords) do
        local kw = KeywordSystem.KEYWORDS[kwId]
        if kw then
            local interestLevel = interests[kw.category] or 0
            if interestLevel >= 2 then
                local chatKey = characterKey .. ":" .. kwId
                local usedToday = (S.chattedKeywordsToday or {})[chatKey] or false
                table.insert(result, {
                    id = kwId,
                    keyword = kw,
                    interestLevel = interestLevel,
                    usedToday = usedToday,
                })
            end
        end
    end
    -- 未聊优先，然后按兴趣度降序
    table.sort(result, function(a, b)
        if a.usedToday ~= b.usedToday then return not a.usedToday end
        return a.interestLevel > b.interestLevel
    end)
    return result
end

--- 执行关键词聊天
---@param characterKey string
---@param keywordId string
---@return number 好感增加量
function KeywordSystem.doKeywordChat(characterKey, keywordId)
    local S = GameState.state
    if not S.chattedKeywordsToday then S.chattedKeywordsToday = {} end
    local chatKey = characterKey .. ":" .. keywordId
    S.chattedKeywordsToday[chatKey] = true
    S.keywordChatCount = (S.keywordChatCount or 0) + 1

    local kw = KeywordSystem.KEYWORDS[keywordId]
    if not kw then return 0 end
    local interests = KeywordSystem.CHARACTER_INTERESTS[characterKey]
    local level = interests and interests[kw.category] or 0

    local gain = 0
    if level >= 3 then gain = 5
    elseif level >= 2 then gain = 3
    elseif level >= 1 then gain = 1
    end

    return gain
end

--- 每日重置
function KeywordSystem.onDayChange()
    local S = GameState.state
    S.chattedKeywordsToday = {}
end

-- ==================== Passage 处理 ====================

--- 角色名获取辅助
local function getCharName(charKey)
    local S = GameState.state
    local names = {
        leiDe = S.initialName or "莱德",
        k = "K",
        meifei = "梅菲斯",
        oamel = "奥梅尔",
    }
    return names[charKey] or charKey
end

--- 获取passage
---@param passageName string
---@return table|nil
function KeywordSystem.getPassage(passageName)
    local S = GameState.state

    -- ==================== 关键词选择 ====================
    if passageName == "keyword_chat_select" then
        local charKey = S._keywordChatChar or "leiDe"
        local charName = getCharName(charKey)
        local keywords = KeywordSystem.getInterestedKeywords(charKey)

        if #keywords == 0 then
            return {
                text = "你想了想，好像没有什么" .. charName
                    .. "会感兴趣的话题。\n\n（多参加活动、探索小镇来收集话题关键词吧！）",
                choices = { { text = "🔙 算了", target = S._keywordChatReturn or "十字路口" } },
            }
        end

        local text = "你想跟" .. charName .. "聊点什么呢？\n\n── 可聊的话题 ──\n"
        local choices = {}
        for _, item in ipairs(keywords) do
            local kw = item.keyword
            local cat = KeywordSystem.CATEGORIES[kw.category]
            local icon = cat and cat.icon or "💬"
            local stars = ""
            if item.interestLevel >= 3 then stars = " ★★★"
            elseif item.interestLevel >= 2 then stars = " ★★"
            end
            local suffix = item.usedToday and "（今天已聊）" or ""
            table.insert(choices, {
                text = icon .. " " .. kw.name .. stars .. suffix,
                action = function()
                    if item.usedToday then
                        GameState.showNotification("今天已经跟" .. charName .. "聊过「" .. kw.name .. "」了。")
                        return "keyword_chat_select"
                    end
                    S._keywordChatKeyword = item.id
                    return "keyword_chat_dialogue"
                end,
            })
        end
        table.insert(choices, { text = "🔙 不聊了", target = S._keywordChatReturn or "十字路口" })

        return { text = text, choices = choices }
    end

    -- ==================== 聊天对话 ====================
    if passageName == "keyword_chat_dialogue" then
        local charKey = S._keywordChatChar or "leiDe"
        local kwId = S._keywordChatKeyword or ""
        local kw = KeywordSystem.KEYWORDS[kwId]
        if not kw then
            return {
                text = "话题好像搞混了……",
                choices = { { text = "返回", target = S._keywordChatReturn or "十字路口" } },
            }
        end

        local charName = getCharName(charKey)
        local interests = KeywordSystem.CHARACTER_INTERESTS[charKey]
        local interestLevel = interests and interests[kw.category] or 0

        -- 获取对话文本
        local dialogueText
        local charDialogues = KeywordSystem.CHAT_DIALOGUES[charKey]
        if charDialogues and charDialogues[kwId] then
            local pool = charDialogues[kwId]
            local fn = pool[math.random(1, #pool)]
            dialogueText = fn(charName)
        else
            -- 使用敷衍回应
            local fb = KeywordSystem.FALLBACK_DIALOGUES[charKey]
            if interestLevel >= 1 and fb and fb.mild then
                local pool = fb.mild
                dialogueText = pool[math.random(1, #pool)](charName)
            elseif fb and fb.none then
                local pool = fb.none
                dialogueText = pool[math.random(1, #pool)](charName)
            else
                dialogueText = charName .. " 没有太大反应。"
            end
        end

        -- 执行聊天
        local gain = KeywordSystem.doKeywordChat(charKey, kwId)
        TimeSystem.addMinutes(5)

        -- 加好感
        if gain > 0 then
            -- 需要延迟加载避免循环依赖
            local ok, NPCSystem = pcall(require, "systems.NPCSystem")
            if ok then
                if charKey == "leiDe" then
                    if NPCSystem.addAffection then NPCSystem.addAffection("initialName", gain) end
                elseif charKey == "k" then
                    if NPCSystem.addAffection then NPCSystem.addAffection("k", gain) end
                elseif charKey == "meifei" then
                    if NPCSystem.addMeifeiAffection then NPCSystem.addMeifeiAffection(gain) end
                elseif charKey == "oamel" then
                    if NPCSystem.addOamelAffection then NPCSystem.addOamelAffection(gain) end
                end
            end
        end

        local resultText = dialogueText
        if gain > 0 then
            resultText = resultText .. "\n\n（" .. charName .. " 好感+" .. gain .. "）"
        end

        return {
            text = resultText,
            choices = {
                { text = "💬 再聊一个话题", target = "keyword_chat_select" },
                { text = "🔙 结束聊天", target = S._keywordChatReturn or "十字路口" },
            },
        }
    end

    return nil
end

return KeywordSystem
