-- ============================================================================
-- WorkBookData.lua - 书籍数据（从 WorkSystem.lua 提取）
-- 包含：书籍文本、书籍顺序、书籍元信息
-- ============================================================================

local M = {}

--- 书籍文本
M.bookTexts = {
    manner = {
        "“问候他人时，目光应落在对方眉间，既不卑不亢，又显尊重……”",
        "“用餐时，刀叉由外向内使用，面包需手撕成小块，切勿直接咬……”",
        "“进入房间前，应先敲门三下，得到允许后方可入内……”",
        "“真正的贵族风度，不在于出身，而在于让他人感到舒适。”",
    },
    history = {
        "“瓦勒姆公爵家，封地北境，以暗魔法与太阳神契约闻名……”",
        "“罗斯巴特家族，前朝皇族后裔，现居花街，家主奥梅尔·罗斯巴特……”",
        "“辛奇家族，商业世家，经营酒馆与贸易……”",
        "“血脉终会淡去，但荣耀需自己争取。”",
    },
    osmia = {
        "“奥丝米娅国王登基时年仅十六，却以铁腕整合了分裂的贵族……”",
        "“他大兴土木，修建图书馆与剧院，鼓励学者与艺术家……”",
        "“晚年却沉溺魔法研究，将政务交由心腹，最终导致皇权旁落……”",
        "“历史没有对错，只有选择。”",
    },
    theology = {
        "\xe2\x80\x9c太阳神赐予人类光明，而黑暗并非敌人，它是光的另一面……\xe2\x80\x9d",
        "\xe2\x80\x9c祈祷不是索取，而是与神对话。静心冥想，感受圣光的流动……\xe2\x80\x9d",
        "\xe2\x80\x9c圣典记载：'凡心怀慈悲者，即为神之使徒。'修行始于善念……\xe2\x80\x9d",
        "\xe2\x80\x9c信仰的力量不在于奇迹，而在于面对苦难时仍能保持希望。\xe2\x80\x9d",
    },
    botany = {
        "\xe2\x80\x9c薄荷草喜阴凉湿润处生长，叶片对生，揉碎有清凉香气……\xe2\x80\x9d",
        "\xe2\x80\x9c红棘果外皮有毒，但果肉可入药，辨别时注意茎上是否有细刺……\xe2\x80\x9d",
        "\xe2\x80\x9c菌类采集须格外小心——色彩鲜艳者多有剧毒，白色无味者也未必安全……\xe2\x80\x9d",
        "\xe2\x80\x9c大自然是最好的药房，前提是你能分辨朋友和敌人。\xe2\x80\x9d",
    },
    repair = {
        "\xe2\x80\x9c齿轮的啮合需要精确计算——每个齿的角度偏差不得超过半度……\xe2\x80\x9d",
        "\xe2\x80\x9c锁具的原理看似简单，但一把好锁的弹簧张力需要反复调试……\xe2\x80\x9d",
        "\xe2\x80\x9c修理最重要的不是工具，而是耐心。拆开之前，先观察它是怎么坏的……\xe2\x80\x9d",
        "\xe2\x80\x9c万物皆可修，只要你理解它为何而造。\xe2\x80\x9d",
    },
    tactics_text = {
        "\xe2\x80\x9c战场上最重要的是地形——高处射箭、窄道设伏、平原列阵……\xe2\x80\x9d",
        "\xe2\x80\x9c兵法云：知己知彼，百战不殆。战前侦察敌情是指挥官的第一课……\xe2\x80\x9d",
        "\xe2\x80\x9c阵型不是死板的队列，而是根据战况随时调整的活物……\xe2\x80\x9d",
        "\xe2\x80\x9c真正的将才，能在混乱中找到秩序，在绝境中创造转机。\xe2\x80\x9d",
    },
    magic_text = {
        "\xe2\x80\x9c魔力的本质是精神力的具象化，施法者需要极高的专注力……\xe2\x80\x9d",
        "\xe2\x80\x9c元素魔法分为四系：火、水、风、土。每系又有攻击、防御、辅助三类……\xe2\x80\x9d",
        "\xe2\x80\x9c魔法阵的绘制必须一气呵成，线条断裂会导致魔力失控……\xe2\x80\x9d",
        "\xe2\x80\x9c魔法的极致不是毁灭，而是创造——治愈伤痛，点亮黑暗。\xe2\x80\x9d",
    },
    theology_text = {
        "\xe2\x80\x9c神学的核心问题：神的意志是否干预凡人的命运？各派争论千年……\xe2\x80\x9d",
        "\xe2\x80\x9c光明教派主张积极行善，而隐修派认为沉思冥想才是通往神明之路……\xe2\x80\x9d",
        "\xe2\x80\x9c宗教仪式的每个环节都有深意——焚香象征净化，钟声驱散邪祟……\xe2\x80\x9d",
        "\xe2\x80\x9c理解神学，就是理解人类对未知的敬畏和对秩序的渴望。\xe2\x80\x9d",
    },
    cook_text = {
        "\xe2\x80\x9c火候是烹饪的灵魂——猛火爆炒锁住鲜味，文火慢炖提取精华……\xe2\x80\x9d",
        "\xe2\x80\x9c调味的基本原则：咸提鲜、酸解腻、甜增厚、辣开胃、苦回甘……\xe2\x80\x9d",
        "\xe2\x80\x9c食材的新鲜度决定了菜品的上限，再好的厨艺也救不了变质的原料……\xe2\x80\x9d",
        "\xe2\x80\x9c烹饪不只是填饱肚子，它是对食材的尊重，对生活的热爱。\xe2\x80\x9d",
    },
}

--- 书籍有序列表（用于UI展示）
M.bookOrder = {
    "manner", "history", "osmia", "theology", "botany", "repair",
    "tactics_text", "magic_text", "theology_text", "cook_text",
}

--- 书籍信息
M.bookInfo = {
    manner = {
        readCountVar = "mannerBookReadCount",
        firstRewardVar = "mannerFirstReward",
        hasVar = "hasMannerBook",
        knowledgeId = "manner",
        rewardStat = "ML",
        fullName = "《贵族礼仪入门》",
        statName = "魅力",
    },
    history = {
        readCountVar = "historyBookReadCount",
        firstRewardVar = "historyFirstReward",
        hasVar = "hasHistoryBook",
        knowledgeId = "history",
        rewardStat = "LG",
        fullName = "《日轮王国贵族名录》",
        statName = "灵感",
    },
    osmia = {
        readCountVar = "osmiaBookReadCount",
        firstRewardVar = "osmiaFirstReward",
        hasVar = "hasOsmiaBook",
        knowledgeId = "history",
        rewardStat = "LG",
        fullName = "《奥丝米娅时代的历史》",
        statName = "灵感",
    },
    theology = {
        readCountVar = "theologyBookReadCount",
        firstRewardVar = "theologyFirstReward",
        hasVar = "hasTheologyBook",
        knowledgeId = "theology",
        rewardStat = "LG",
        fullName = "《圣典基础教义》",
        statName = "灵感",
    },
    botany = {
        readCountVar = "botanyBookReadCount",
        firstRewardVar = "botanyFirstReward",
        hasVar = "hasBotanyBook",
        knowledgeId = "botany",
        rewardStat = "NL",
        fullName = "《野外草药图鉴》",
        statName = "耐力",
    },
    repair = {
        readCountVar = "repairBookReadCount",
        firstRewardVar = "repairFirstReward",
        hasVar = "hasRepairBook",
        knowledgeId = "repair",
        rewardStat = "JQ",
        fullName = "《机械修理入门》",
        statName = "技巧",
    },
    tactics_text = {
        readCountVar = "tacticsTextReadCount",
        firstRewardVar = "tacticsTextFirstReward",
        hasVar = "hasTacticsText",
        knowledgeId = "tactics",
        rewardStat = "LL",
        fullName = "《战术学教材》",
        statName = "力量",
    },
    magic_text = {
        readCountVar = "magicTextReadCount",
        firstRewardVar = "magicTextFirstReward",
        hasVar = "hasMagicText",
        knowledgeId = "magicTheory",
        rewardStat = "LG",
        fullName = "《魔法理论概论》",
        statName = "灵感",
    },
    theology_text = {
        readCountVar = "theologyTextReadCount",
        firstRewardVar = "theologyTextFirstReward",
        hasVar = "hasTheologyText",
        knowledgeId = "theology",
        rewardStat = "LG",
        fullName = "《神学经典诠释》",
        statName = "灵感",
    },
    cook_text = {
        readCountVar = "cookTextReadCount",
        firstRewardVar = "cookTextFirstReward",
        hasVar = "hasCookText",
        knowledgeId = "cookTheory",
        rewardStat = "JQ",
        fullName = "《烹饪学原理》",
        statName = "技巧",
    },
}

return M
