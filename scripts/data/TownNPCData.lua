-- ============================================================================
-- TownNPCData.lua - 小镇 NPC 资料数据
-- 从 TownLife.lua 提取的纯数据表
-- ============================================================================

local TownNPCData = {}

TownNPCData.NPC_INFO = {
    eileen = {
        name = "艾琳",
        title = "流浪画家",
        desc = "背着画板的红发女孩，据说来自南方的艺术之城。\n喜欢在街头写生，画技精湛但性格古怪。",
        locations = { "花园小镇", "商业区", "十字路口" },
        timeActive = { "morning", "afternoon" },
    },
    oldYugen = {
        name = "老尤金",
        title = "退休水手",
        desc = "满脸皱纹的老水手，一条腿有些跛。\n最爱在港口边给年轻人讲航海故事，每个故事都以'那一年暴风雨的夜晚'开头。",
        locations = { "港口" },
        timeActive = { "morning", "afternoon", "evening" },
    },
    lillian = {
        name = "莉莉安",
        title = "花店老板娘",
        desc = "温柔的中年女性，经营着花园小镇唯一的花店。\n总是带着花香，对每一位客人都笑脸相迎。",
        locations = { "花园小镇" },
        timeActive = { "morning", "afternoon", "evening" },
    },
    dario = {
        name = "达里奥",
        title = "流浪乐手",
        desc = "戴着宽檐帽的年轻乐手，手里永远抱着一把旧吉他。\n来自北方，声称自己在'寻找完美的旋律'。",
        locations = { "十字路口", "商业区", "花街" },
        timeActive = { "afternoon", "evening" },
    },
    grandmaVera = {
        name = "薇拉奶奶",
        title = "退休教师",
        desc = "住在主城区的和蔼老太太，每天在教堂广场喂鸽子。\n据说年轻时是位了不起的魔法学者。",
        locations = { "主城区" },
        timeActive = { "morning", "afternoon" },
    },
    -- ---- 第三批NPC ----
    felix = {
        name = "费利克斯",
        title = "面包师",
        desc = "笑容满面的中年面包师，每天凌晨就起来揉面。\n面包房里永远飘着黄油和小麦的香气，据说他的酸面团已经养了二十年。",
        locations = { "商业区", "花园小镇" },
        timeActive = { "morning", "afternoon" },
    },
    isabella = {
        name = "伊莎贝拉",
        title = "草药医生",
        desc = "沉默寡言的年轻女性，总是围着深绿色的围裙。\n经营着一间小小的草药铺，熟知每一种植物的药性。",
        locations = { "花园小镇", "主城区" },
        timeActive = { "morning", "afternoon" },
    },
    jasper = {
        name = "贾斯帕",
        title = "守夜人",
        desc = "沉默的中年男子，提着一盏旧灯笼巡逻整座城市的夜晚。\n白天补觉，傍晚才出来，是这座城里最熟悉黑暗的人。",
        locations = { "十字路口", "港口", "商业区" },
        timeActive = { "evening", "night" },
    },
    nora = {
        name = "诺拉",
        title = "裁缝",
        desc = "手艺精湛的年轻裁缝，经营着一间不起眼但生意兴隆的小铺子。\n说话直爽，对审美有自己的坚持，据说连贵族都来找她改衣服。",
        locations = { "商业区", "花园小镇" },
        timeActive = { "morning", "afternoon" },
    },
    sebastian = {
        name = "塞巴斯蒂安",
        title = "流浪学者",
        desc = "头发蓬乱的年轻学者，背着一大袋子书四处旅行。\n自称在'收集世界各地的知识'，但常常连饭钱都不够。",
        locations = { "主城区", "港口" },
        timeActive = { "morning", "afternoon", "evening" },
    },
    xiaomei = {
        name = "小梅",
        title = "鱼贩女孩",
        desc = "扎着马尾辫的元气少女，每天天不亮就去码头接货。\n嗓门大、性格爽朗，是港口最受欢迎的鱼贩。",
        locations = { "港口", "十字路口" },
        timeActive = { "morning", "afternoon" },
    },
}

return TownNPCData
