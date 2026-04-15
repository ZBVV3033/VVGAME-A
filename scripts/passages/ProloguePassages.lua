-- passages/ProloguePassages.lua
-- 序章相关段落（主页面、角色创建、序章剧情）
local GameState = require("systems.GameState")

local handlers = {}

---===================== 主页面 =====================
--- Twine pid 1: 主页面 → 命名输入 → 角色创建
handlers["主页面"] = function(S)
    local pName = S.PNN or ""
    local greeting = pName ~= "" and ("当前名字：" .. pName .. "\n\n") or ""
    return {
        text = "悠闲悠哉life\n\n"
            .. greeting
            .. "📝 请输入你的名字，然后点击「开始」",
        inputField = true,
        inputTarget = "PNN",
        choices = {
            { text = "开始", target = "命名" },
            { text = "幕后", target = "幕后" },
        },
    }
end

---===================== 幕后 =====================
--- Twine pid 4
handlers["幕后"] = function(S)
    return {
        text = "完全含有200%的作者XP，抱歉。",
        choices = {
            { text = "返回", target = "主页面" },
        },
    }
end

---===================== 命名（角色创建 - 外观选择） =====================
--- Twine pid 3
handlers["命名"] = function(S)
    local pName = (S.PNN ~= "" and S.PNN) or "诺兰"
    local curStyle = S.hairstyle or "及肩长发"
    local curColor = S.hairColor or "淡黄色"
    local curEye   = S.eyeColor  or "赤色"
    local tab = S._appearanceTab  -- nil / "hair" / "color" / "eye"

    local text = "─── 角色创建 ───\n\n"
        .. "名字：" .. pName .. "\n\n"
        .. "捏个脸先。\n\n"
        .. "当前外观：" .. curColor .. curStyle .. "，" .. curEye .. "瞳\n"

    local choices = {}

    if not tab then
        -- 主菜单：选择要修改的类型
        table.insert(choices, {
            text = "💇 发型（当前：" .. curStyle .. "）",
            action = function() S._appearanceTab = "hair"; return "命名" end,
        })
        table.insert(choices, {
            text = "🎨 发色（当前：" .. curColor .. "）",
            action = function() S._appearanceTab = "color"; return "命名" end,
        })
        table.insert(choices, {
            text = "👁 瞳色（当前：" .. curEye .. "）",
            action = function() S._appearanceTab = "eye"; return "命名" end,
        })
        table.insert(choices, { text = "🪞 审视自己", target = "自我审视" })

    elseif tab == "hair" then
        local hairstyles = { "短发", "长发", "及肩长发", "马尾", "寸头", "卷发", "编发", "披肩发" }
        for _, style in ipairs(hairstyles) do
            local mark = (style == curStyle) and " ✦" or ""
            table.insert(choices, {
                text = "💇 " .. style .. mark,
                action = function() S.hairstyle = style; S._appearanceTab = nil; return "命名" end,
            })
        end
        table.insert(choices, {
            text = "🔙 返回",
            action = function() S._appearanceTab = nil; return "命名" end,
        })

    elseif tab == "color" then
        local hairColors = { "黑色", "棕色", "金色", "淡黄色", "红色", "白色", "灰色", "蓝色" }
        for _, color in ipairs(hairColors) do
            local mark = (color == curColor) and " ✦" or ""
            table.insert(choices, {
                text = "🎨 " .. color .. mark,
                action = function() S.hairColor = color; S._appearanceTab = nil; return "命名" end,
            })
        end
        table.insert(choices, {
            text = "🔙 返回",
            action = function() S._appearanceTab = nil; return "命名" end,
        })

    elseif tab == "eye" then
        local eyeColors = { "赤色", "蓝色", "金色", "翠绿", "紫色", "银色", "琥珀", "黑色" }
        for _, ec in ipairs(eyeColors) do
            local mark = (ec == curEye) and " ✦" or ""
            table.insert(choices, {
                text = "👁 " .. ec .. mark,
                action = function() S.eyeColor = ec; S._appearanceTab = nil; return "命名" end,
            })
        end
        table.insert(choices, {
            text = "🔙 返回",
            action = function() S._appearanceTab = nil; return "命名" end,
        })
    end

    return {
        text = text,
        choices = choices,
        action = function()
            S.inPrologue = true
        end,
    }
end

---===================== 序章 =====================
--- Twine pid 5: 0序章
handlers["序章"] = function(S)
    local pName = (S.PNN ~= "" and S.PNN) or "诺兰"
    return {
        text = "0：序章\n"
            .. "无数的命运于你开始。\n\n"
            .. "你的名字是 " .. pName .. "。\n\n"
            .. "0岁：神祝福你的诞生，愿你的未来衡有辉光的启示。\n"
            .. "这一天，一片终年被黑暗阴影遮盖的阴森古堡奇迹般的引来了一阵神圣的大片光芒。"
            .. "这照耀在瓦勒姆公爵疲惫苍白的脸上，使长年沉浸在无尽癫狂中的他恢复了一丝清明，"
            .. "他对这个可爱的，神圣的婴儿挤出了一个怪异又真诚的笑容，虽然他竭尽全力，效果上完全适得其反。\n\n"
            .. "「父亲，您这是多久没笑过了？恕我所说您这个微笑与其说是亲切更像是一种可怕的武器，"
            .. "威力完全不逊于您的利爪，您的利刃。」\n"
            .. "小小个的长子表情严肃，像个大人一样对着公爵说教，"
            .. "似乎他的心比起这个疯疯癫癫的父亲已经更加偏向这个让人爱不释手的新生命了。\n\n"
            .. "公爵摇了摇头，流露出一些悲痛的情绪。",
        choices = {
            { text = "🪞 审视自己", target = "自我审视" },
            { text = "继续", target = "序章_0.1" },
        },
        action = function()
            S.inPrologue = true
            S.money = 0
            S.state = 0
        end,
    }
end

---===================== 序章_0.1 =====================
--- Twine pid 6
handlers["序章_0.1"] = function(S)
    return {
        text = "「记不清了，或许是你出生的时候？不过这个称赞确实很恰当。」"
            .. "公爵的笑容转瞬即逝，又变回面无表情的状态，似乎这只是一场可以忽略不计的意外。"
            .. "如此暗黑的一家人就这样沉默地站在古堡内的庭院里，"
            .. "这些暖暖的光反而让喜暗的魔法植物十分难受，它们张牙舞爪地嘶嘶表达自己的抗拒，"
            .. "没一会就被公爵禁言了。这里徒留一片寂静。\n\n"
            .. "公爵夫人温柔地怀抱着幼小的婴儿，平静的面容之下含有着浓浓的温情。"
            .. "你被盯久了感觉有点不适应，你感觉：",
        choices = {
            { text = "很恐怖", target = "序章_恐怖" },
            { text = "很平静", target = "序章_平静" },
            { text = "很温暖", target = "序章_温暖" },
        },
    }
end

---===================== 序章_恐怖 =====================
--- Twine pid 7
handlers["序章_恐怖"] = function(S)
    return {
        text = "「你的心中被恐惧淹没。」\n"
            .. "你无法控制地接纳了来自血脉最真挚的\"祝福\"，同时也是最无望的\"诅咒\"。"
            .. "恐惧在你幼小的身体里生根，但也赋予了你某种原始的力量——"
            .. "你的双手在黑暗中微微发光，空气仿佛在你身边变得沉重。"
            .. "公爵夫人轻轻皱了皱眉，但很快又恢复了温柔的神情。\n\n"
            .. "（力量+2，魅力+2）",
        choices = {
            { text = "时光飞逝", target = "序章_0.2" },
        },
        action = function()
            S.LL = (S.LL or 1) + 2
            S.ML = (S.ML or 3) + 2
        end,
    }
end

---===================== 序章_平静 =====================
--- Twine pid 8
handlers["序章_平静"] = function(S)
    return {
        text = "「你的心毫无波澜。」\n"
            .. "你很轻易地接受了这个家阴森的氛围，你的灵魂在悄无声息地变化着，变得更坚韧强大。"
            .. "黑暗对你而言就像拥抱一样自然，阴影在你脚边温顺地流淌，"
            .. "庭院里那些嘶嘶作响的魔法植物似乎也对你格外亲近。\n\n"
            .. "（灵感+3，勇敢+1，冷静+2，暗属性+10 → 微弱）",
        choices = {
            { text = "时光飞逝", target = "序章_0.2" },
        },
        action = function()
            S.LG = (S.LG or 1) + 3
            S.YG = (S.YG or 0) + 1
            S.LJ = (S.LJ or 0) + 2
            S.ASX = (S.ASX or 1) + 10
        end,
    }
end

---===================== 序章_温暖 =====================
--- Twine pid 9
handlers["序章_温暖"] = function(S)
    return {
        text = "「你的心中并不冰冷，反而充满了温暖。」\n"
            .. "你受到了光的祝福。一道柔和的金光从你小小的身体里透出，"
            .. "在古堡阴沉的庭院里显得格外明亮。公爵夫人的眼中闪过一丝惊喜，"
            .. "她将你抱得更紧了一些。连一向面无表情的公爵也微微侧过了头。\n\n"
            .. "（耐力+2，光属性+10 → 微弱）",
        choices = {
            { text = "时光飞逝", target = "序章_0.2" },
        },
        action = function()
            S.NL = (S.NL or 2) + 2
            S.GSX = (S.GSX or 5) + 10
        end,
    }
end

---===================== 序章_0.2 =====================
--- Twine pid 10
handlers["序章_0.2"] = function(S)
    return {
        text = "1岁：大部分时候由女仆和执事们照顾你，母亲偶尔来抱抱你，带你去隔壁小镇晒晒太阳。"
            .. "父亲除了生日宴会之外几乎没露过脸，哥哥在繁重的学习之余会来掐掐你的小脸蛋，力度控制在你不会放声哭泣的程度。"
            .. "2岁：你在家庭教师的教导下学会了说话，还尝试学习了阅读和写字。"
            .. "这让偶尔来找你玩的哥哥非常高兴，他整天对你说着复杂的政治历史和前沿魔法研究——不过你完全听不懂。",
        choices = {
            { text = "于是你长大了", target = "序章_1.0" },
        },
    }
end

---===================== 序章_1.0 =====================
--- Twine pid 11
handlers["序章_1.0"] = function(S)
    return {
        text = "你在一个黎明前的夜里离开了家族的庄园。没有告别，没有回头。"
            .. "行囊里只有几件换洗衣物、一小袋铜币，和那位在学校时期照顾过你的上司写的一封推荐信。\n\n"
            .. "马车颠簸了三天两夜。当你终于看见艾瑟顿镇的城门时，"
            .. "晨光正从云层间倾泻而下，把港口的帆船桅杆染成金色。"
            .. "空气里混着海盐和新烤面包的味道。人群熙熙攘攘，叫卖声此起彼伏。"
            .. "没有人认识你，没有人在乎你姓什么。\n\n"
            .. "你在十字路口附近租了一间小阁楼。房东是个精明的矮胖男人，"
            .. "看了推荐信后勉强点头：「第一周先付100金币，之后每周500。迟一天都不行。」"
            .. "你把最后的积蓄数了又数。不多了，但足够开始。\n\n"
            .. "窗外，艾瑟顿的钟楼敲响了清晨的第一声钟。属于你的故事，从这里开始。",
        choices = {
            { text = "🌅 迎接新的一天", target = "家" },
        },
        action = function()
            -- 序章结束，恢复到游戏正式开始的时间
            S.inPrologue = false
            S.year = 499
            S.month = 1
            S.day = 1
            S.hour = 8
            S.minute = 0
            GameState.showNotification("💡 提示：点击左上角的「📋 日志」可以查看当前任务、房租信息和生存指引。初来乍到，记得去十字路口找份工作！")
        end,
    }
end

return handlers
