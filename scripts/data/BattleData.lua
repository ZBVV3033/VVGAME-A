-- ============================================================================
-- BattleData.lua - 战斗系统数据表（悠闲悠哉life）
-- 从 BattleSystem.lua 提取的纯数据定义：
--   敌人模板、技能配置、职业定义、商人物品、森林事件
-- ============================================================================

local BattleData = {}

-- ==================== 敌人模板 ====================

BattleData.ENEMY_TEMPLATES = {
    -- ==================== 第1-2层：林间杂兵 ====================
    ["小石块"] = {
        name = "小石块",
        hp = 50, maxHp = 50,
        power = 3, insight = 2,
        speed = 4, def = 5,
        mdef = 0.2, skill = 1,
        atkBase = 3, matkBase = 2,
        expValue = 50, gold = 10,
        skillCycle = { "attack", "harden", "attack", "attack", "smash" },
        emergencySkill = "smash",
    },
    ["毒蘑菇"] = {
        name = "毒蘑菇",
        hp = 35, maxHp = 35,
        power = 2, insight = 4,
        speed = 5, def = 2,
        mdef = 0.4, skill = 2,
        atkBase = 2, matkBase = 4,
        expValue = 45, gold = 8,
        skillCycle = { "attack", "poison_spore", "attack", "attack" },
        emergencySkill = "poison_spore",
    },
    ["荆棘藤"] = {
        name = "荆棘藤",
        hp = 60, maxHp = 60,
        power = 4, insight = 1,
        speed = 2, def = 6,
        mdef = 0.1, skill = 1,
        atkBase = 4, matkBase = 1,
        expValue = 55, gold = 12,
        skillCycle = { "attack", "thorn_bind", "attack", "harden" },
        emergencySkill = "thorn_bind",
    },

    -- ==================== 第3-4层：林间猎手 ====================
    ["苔藓巨石"] = {
        name = "苔藓巨石",
        hp = 80, maxHp = 80,
        power = 5, insight = 3,
        speed = 3, def = 8,
        mdef = 0.3, skill = 2,
        atkBase = 5, matkBase = 3,
        expValue = 75, gold = 20,
        skillCycle = { "attack", "harden", "corrosion", "attack", "smash" },
        emergencySkill = "smash",
    },
    ["暗影狼"] = {
        name = "暗影狼",
        hp = 65, maxHp = 65,
        power = 6, insight = 3,
        speed = 9, def = 3,
        mdef = 0.2, skill = 3,
        atkBase = 6, matkBase = 2,
        expValue = 80, gold = 22,
        skillCycle = { "attack", "attack", "frenzy_bite", "attack" },
        emergencySkill = "frenzy_bite",
    },
    ["毒蜘蛛"] = {
        name = "毒蜘蛛",
        hp = 55, maxHp = 55,
        power = 4, insight = 5,
        speed = 7, def = 3,
        mdef = 0.3, skill = 3,
        atkBase = 3, matkBase = 5,
        expValue = 70, gold = 18,
        skillCycle = { "attack", "web_trap", "poison_spore", "attack" },
        emergencySkill = "web_trap",
    },

    -- ==================== 第5-6层：深林精英 ====================
    ["树精"] = {
        name = "树精",
        hp = 120, maxHp = 120,
        power = 5, insight = 6,
        speed = 4, def = 7,
        mdef = 0.4, skill = 3,
        atkBase = 5, matkBase = 6,
        expValue = 120, gold = 35,
        skillCycle = { "attack", "corrosion", "nature_heal", "attack", "smash" },
        emergencySkill = "nature_heal",
    },
    ["腐化精灵"] = {
        name = "腐化精灵",
        hp = 90, maxHp = 90,
        power = 3, insight = 8,
        speed = 8, def = 4,
        mdef = 0.5, skill = 4,
        atkBase = 3, matkBase = 8,
        expValue = 130, gold = 40,
        skillCycle = { "shadow_bolt", "attack", "shadow_bolt", "corrosion" },
        emergencySkill = "shadow_bolt",
    },

    -- ==================== 第7-8层：深渊守卫 ====================
    ["黑骑士"] = {
        name = "黑骑士",
        hp = 160, maxHp = 160,
        power = 8, insight = 4,
        speed = 5, def = 12,
        mdef = 0.25, skill = 4,
        atkBase = 8, matkBase = 3,
        expValue = 180, gold = 55,
        skillCycle = { "attack", "harden", "frenzy_bite", "attack", "smash" },
        emergencySkill = "smash",
    },
    ["古树守卫"] = {
        name = "古树守卫",
        hp = 200, maxHp = 200,
        power = 7, insight = 5,
        speed = 2, def = 15,
        mdef = 0.35, skill = 3,
        atkBase = 7, matkBase = 5,
        expValue = 200, gold = 60,
        skillCycle = { "attack", "harden", "thorn_bind", "corrosion", "smash" },
        emergencySkill = "nature_heal",
    },

    -- ==================== 第9层：精英怪 ====================
    ["堕落天使"] = {
        name = "堕落天使",
        hp = 180, maxHp = 180,
        power = 6, insight = 10,
        speed = 10, def = 6,
        mdef = 0.5, skill = 5,
        atkBase = 5, matkBase = 10,
        expValue = 250, gold = 80,
        skillCycle = { "shadow_bolt", "corrosion", "attack", "shadow_bolt", "smash" },
        emergencySkill = "shadow_bolt",
    },

    -- ==================== 第5层BOSS ====================
    ["石像鬼统领"] = {
        name = "石像鬼统领",
        hp = 150, maxHp = 150,
        power = 6, insight = 4,
        speed = 5, def = 10,
        mdef = 0.3, skill = 3,
        atkBase = 6, matkBase = 4,
        expValue = 250, gold = 100,
        isBoss = true,
        skillCycle = { "attack", "harden", "corrosion", "attack", "smash" },
        emergencySkill = "smash",
    },

    -- ==================== 第10层：最终BOSS ====================
    ["森林之主"] = {
        name = "森林之主",
        hp = 350, maxHp = 350,
        power = 10, insight = 10,
        speed = 7, def = 12,
        mdef = 0.4, skill = 5,
        atkBase = 10, matkBase = 10,
        expValue = 500, gold = 200,
        isBoss = true,
        skillCycle = { "attack", "nature_heal", "corrosion", "frenzy_bite", "shadow_bolt", "smash" },
        emergencySkill = "nature_heal",
    },

    -- ==================== 城内治安事件敌人 ====================
    ["小偷"] = {
        name = "小偷",
        hp = 30, maxHp = 30,
        power = 3, insight = 1,
        speed = 8, def = 2,
        mdef = 0.1, skill = 2,
        atkBase = 3, matkBase = 1,
        expValue = 25, gold = 15,
        skillCycle = { "attack", "attack", "attack" },
        emergencySkill = "attack",
    },
    ["醉汉"] = {
        name = "醉汉",
        hp = 55, maxHp = 55,
        power = 5, insight = 0,
        speed = 3, def = 3,
        mdef = 0.0, skill = 1,
        atkBase = 5, matkBase = 0,
        expValue = 30, gold = 8,
        skillCycle = { "attack", "attack", "frenzy_bite", "attack" },
        emergencySkill = "smash",
    },
    ["街头混混"] = {
        name = "街头混混",
        hp = 45, maxHp = 45,
        power = 4, insight = 1,
        speed = 6, def = 3,
        mdef = 0.1, skill = 2,
        atkBase = 4, matkBase = 1,
        expValue = 35, gold = 12,
        skillCycle = { "attack", "attack", "smash", "attack" },
        emergencySkill = "smash",
    },
    ["野狗"] = {
        name = "野狗",
        hp = 35, maxHp = 35,
        power = 4, insight = 0,
        speed = 7, def = 2,
        mdef = 0.0, skill = 1,
        atkBase = 4, matkBase = 0,
        expValue = 20, gold = 5,
        skillCycle = { "attack", "frenzy_bite", "attack" },
        emergencySkill = "frenzy_bite",
    },
    ["走私贩"] = {
        name = "走私贩",
        hp = 70, maxHp = 70,
        power = 5, insight = 2,
        speed = 5, def = 5,
        mdef = 0.15, skill = 3,
        atkBase = 5, matkBase = 2,
        expValue = 50, gold = 30,
        skillCycle = { "attack", "harden", "attack", "smash" },
        emergencySkill = "smash",
    },
}

-- ==================== 勇者技能配置 ====================

-- 勇者基础技能（始终可用）
BattleData.HERO_BASE_SKILLS_PHYS = {
    { id = "light",       name = "轻攻击",   icon = "⚔️", cost = "",       desc = "基础物理攻击" },
    { id = "heavy",       name = "重攻击",    icon = "💥", cost = "10%HP",  desc = "强力物理攻击" },
    { id = "holy_strike", name = "圣光斩",   icon = "✨", cost = "5MP",    desc = "无视40%防御" },
}
BattleData.HERO_BASE_SKILLS_BUFF = {
    { id = "guard",       name = "守护姿态", icon = "🛡️", cost = "3MP",    desc = "防+3 魔抗+15% 2回合" },
    { id = "powerstance", name = "全力架势",  icon = "⚡", cost = "5HP+5MP",desc = "攻+20% 力灵+1 3回合" },
    { id = "heal",        name = "恢复魔法",  icon = "💊", cost = "",       desc = "治疗最低血量队友" },
}

-- 勇者等级解锁技能定义
BattleData.HERO_UNLOCK_SKILLS = {
    { level = 12, skill = { id = "combo_strike",    name = "连击斩",   icon = "⚔️", cost = "8MP",  desc = "二连击各60%攻击力" },     category = "物理" },
    { level = 14, skill = { id = "light_barrier",   name = "光盾术",   icon = "🛡️", cost = "10MP", desc = "全队防+3 魔抗+10% 3回合" }, category = "增益" },
    { level = 16, skill = { id = "divine_judgment",  name = "审判之光", icon = "✨", cost = "15MP", desc = "光属性AOE 全体敌人" },     category = "物理" },
}

-- ==================== 职业定义 ====================

BattleData.HERO_CLASS_DEFS = {
    warrior = {
        name = "战士",
        icon = "⚔️",
        desc = "近战猛将，攻高防厚",
        bonuses = { atkBase = 3, def = 2, maxHp = 20 },
        skills = {
            { id = "armor_break", name = "破甲斩", icon = "🗡️", cost = "6MP",  desc = "削减敌人防御3点 3回合", category = "物理" },
            { id = "war_cry",     name = "战吼",   icon = "📣", cost = "8MP",  desc = "全队攻+2 2回合",       category = "增益" },
        },
    },
    mage = {
        name = "法师",
        icon = "🔮",
        desc = "魔法之力，智慧超群",
        bonuses = { matkBase = 3, insight = 2, maxMp = 20 },
        skills = {
            { id = "frost_nova",  name = "冰霜新星", icon = "❄️", cost = "12MP", desc = "魔法AOE全体+冻结1回合",  category = "物理" },
            { id = "mana_surge",  name = "魔力涌动", icon = "💠", cost = "5MP",  desc = "回复30%MP 灵+2 2回合", category = "增益" },
        },
    },
}

-- ==================== K技能分类 ====================

BattleData.K_CATEGORIES = {
    {
        id = "物理", name = "⚔️ 物理攻击",
        skills = {
            { id = "sword_single", name = "挥剑", icon = "⚔️", cost = "",   desc = "单体物理攻击" },
            { id = "sword_sweep",  name = "横扫", icon = "🌀", cost = "",   desc = "AOE(60%)" },
        },
    },
    {
        id = "魔法", name = "🔮 魔法技能",
        skills = {
            { id = "fireball",      name = "小火球",   icon = "🔥", cost = "15MP", desc = "强力魔法伤害" },
            { id = "enchant_light", name = "光辉于我", icon = "✨", cost = "10MP", desc = "全体回复+光属性" },
            { id = "enchant_fire",  name = "炙热于心", icon = "🔥", cost = "10MP", desc = "全体灼烧+火属性" },
            { id = "enchant_ice",   name = "严寒外衣", icon = "❄️", cost = "10MP", desc = "灵感+3 魔抗+40%" },
            { id = "holy_light",    name = "神圣光辉", icon = "✨", cost = "15MP", desc = "全体祝福3回合" },
        },
    },
    {
        id = "增益", name = "💫 增益/切换",
        skills = {
            { id = "form_mage",    name = "魔法元祖", icon = "🔮", cost = "", desc = "法师形态" },
            { id = "form_sword",   name = "剑术大师", icon = "⚔️", cost = "", desc = "剑士形态" },
            { id = "light_shield", name = "光盾",     icon = "🛡️", cost = "", desc = "防御+减伤护盾" },
        },
    },
}

-- ==================== 莱德技能分类 ====================

BattleData.LEIDE_CATEGORIES = {
    {
        id = "物理", name = "⚔️ 物理攻击",
        skills = {
            { id = "slash",      name = "斩击",   icon = "⚔️", cost = "",      desc = "基础物理攻击" },
            { id = "quick_draw", name = "拔刀术", icon = "💨", cost = "8MP",   desc = "先手高速攻击，必定先出手" },
            { id = "cross_cut",  name = "十字斩", icon = "✖️", cost = "10%HP", desc = "两连击，每击70%攻击力" },
        },
    },
    {
        id = "增益", name = "💫 增益技能",
        skills = {
            { id = "focus",  name = "集中", icon = "🎯", cost = "5MP", desc = "攻+25% 暴击率提升 2回合" },
            { id = "endure", name = "硬撑", icon = "🛡️", cost = "",    desc = "防+4 减伤30% 1回合" },
            { id = "rally",  name = "鼓舞", icon = "📣", cost = "8MP", desc = "全体攻+10% 速+1 2回合" },
        },
    },
}

-- ==================== 勇者技能完整列表（供UI展示） ====================

BattleData.PLAYER_SKILLS = {
    { id = "light",          name = "轻攻击",   icon = "⚔️",  cost = "",        desc = "基础物理攻击" },
    { id = "heavy",          name = "重攻击",    icon = "💥",  cost = "10%HP",   desc = "强力物理攻击，消耗10%HP" },
    { id = "holy_strike",    name = "圣光斩",   icon = "✨",  cost = "5MP",     desc = "光属性物理攻击，部分无视防御" },
    { id = "guard",          name = "守护姿态", icon = "🛡️",  cost = "3MP",     desc = "防御+3，魔抗+15%，持续2回合" },
    { id = "powerstance",    name = "全力架势",  icon = "⚡",  cost = "5HP+5MP", desc = "攻击+20%，力灵+1，3回合" },
    { id = "heal",           name = "恢复魔法",  icon = "💊",  cost = "",        desc = "治疗血量最低的队友30%HP" },
    { id = "combo_strike",   name = "连击斩",   icon = "⚔️",  cost = "8MP",     desc = "二连击各60%攻击力 [Lv.12]", unlock = 12 },
    { id = "light_barrier",  name = "光盾术",   icon = "🛡️",  cost = "10MP",    desc = "全队防+3 魔抗+10% 3回合 [Lv.14]", unlock = 14 },
    { id = "divine_judgment", name = "审判之光", icon = "✨",  cost = "15MP",    desc = "光属性AOE全体敌人 [Lv.16]", unlock = 16 },
    -- 战士职业技能
    { id = "armor_break",    name = "破甲斩",   icon = "🗡️",  cost = "6MP",     desc = "伤害+削减防御3点 3回合 [战士]", class = "warrior" },
    { id = "war_cry",        name = "战吼",     icon = "📣",  cost = "8MP",     desc = "全队攻击+2 2回合 [战士]",      class = "warrior" },
    -- 法师职业技能
    { id = "frost_nova",     name = "冰霜新星", icon = "❄️",  cost = "12MP",    desc = "魔法AOE+冻结1回合 [法师]",     class = "mage" },
    { id = "mana_surge",     name = "魔力涌动", icon = "💠",  cost = "5MP",     desc = "回复30%MP 灵+2 2回合 [法师]",  class = "mage" },
}

-- ==================== K技能完整列表（供UI展示） ====================

BattleData.K_SKILLS = {
    { id = "form_mage",     name = "魔法元祖",   icon = "🔮", cost = "",     desc = "切换法师形态" },
    { id = "form_sword",    name = "剑术大师",   icon = "⚔️", cost = "",     desc = "切换剑士形态" },
    { id = "enchant_light", name = "光辉于我",   icon = "✨", cost = "10MP", desc = "全体恢复2%HP，附加光属性" },
    { id = "enchant_fire",  name = "炙热于心",   icon = "🔥", cost = "10MP", desc = "全体敌人灼烧，附加火属性" },
    { id = "enchant_ice",   name = "严寒外衣",   icon = "❄️", cost = "10MP", desc = "灵感+3魔抗+40%，附加冰属性" },
    { id = "light_shield",  name = "光盾",       icon = "🛡️", cost = "",     desc = "防御buff+减伤护盾" },
    { id = "sword_single",  name = "挥剑",       icon = "⚔️", cost = "",     desc = "单体物理攻击" },
    { id = "sword_sweep",   name = "横扫",       icon = "🌀", cost = "",     desc = "AOE物理攻击(60%)" },
    { id = "fireball",      name = "小火球",     icon = "🔥", cost = "15MP", desc = "强力魔法伤害" },
    { id = "holy_light",    name = "神圣光辉",   icon = "✨", cost = "15MP", desc = "全体祝福恢复3回合" },
}

-- ==================== 森林探索事件 ====================

BattleData.FOREST_EVENTS = {
    "fruit",     -- 神秘果树
    "girl",      -- 被袭女孩
    "hotspring", -- 温泉
}

-- ==================== 商人物品 ====================

BattleData.MERCHANT_ITEMS = {
    { id = "phys_buff",   name = "物理伤害+30% buff", cost = 100, desc = "物理伤害提升30%" },
    { id = "magic_buff",  name = "魔法伤害+30% buff", cost = 100, desc = "魔法伤害提升30%" },
    { id = "def_buff",    name = "防御+3 buff",       cost = 100, desc = "防御力提升3" },
    { id = "potion",      name = "血红色药水",        cost = 100, desc = "最大HP+10（限购1次）" },
    { id = "heal_self",   name = "恢复自己HP/MP",     cost = 50,  desc = "完全恢复自身" },
    { id = "heal_all",    name = "恢复全队HP/MP",     cost = 150, desc = "完全恢复全队" },
}

return BattleData
