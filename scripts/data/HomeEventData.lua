-- ============================================================================
-- HomeEventData.lua - 家庭事件数据（从 HomeSystem.lua 提取）
-- 莱德互动事件池 / K来访事件池 / 奥梅尔来访事件池 / 乌列尔信件
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local CommonUtils = require("utils.CommonUtils")

local HomeEventData = {}

-- ==================== 工具函数 ====================
local addAffection = CommonUtils.addAffection
local addDateLog = CommonUtils.addDateLog
local getTimePeriod = CommonUtils.getTimePeriod
local chance = CommonUtils.chance
local leideName = CommonUtils.leideName

function HomeEventData.isLeideHome()
    return GameState.state.initialNameAtHome
end

function HomeEventData.isNight()
    local h = GameState.state.hour or 8
    return h >= 22 or h < 6
end

-- ==================== 莱德在家的动态描述 ====================

function HomeEventData.getLeideHomeDesc()
    local S = GameState.state
    local name = leideName()
    local period = getTimePeriod()
    local level = S.initialNameLevel or 1

    if period == "morning" then
        if level >= 3 then
            return name .. " 坐在窗边，阳光落在他肩上。他正安静地翻着一本旧书，听到你的脚步声，抬头看了你一眼。"
        else
            return name .. " 靠在墙角，双手抱胸，闭着眼。你不确定他是在休息还是在想什么。"
        end
    elseif period == "afternoon" then
        if level >= 3 then
            return name .. " 在擦拭自己的剑。刀刃反射着午后的光，他的动作很慢，很专注。"
        else
            return name .. " 坐在桌边，面前放着一杯已经凉了的水。他看着窗外，不知道在想什么。"
        end
    elseif period == "evening" then
        if level >= 4 then
            return name .. " 正在厨房里忙碌，空气中飘着简单但温暖的饭菜香味。他听到你回来，头也不回地说：「饿了吧。」"
        else
            return name .. " 坐在角落里，身边放着几本书。烛光在他脸上投下柔和的阴影。"
        end
    else -- night
        if S.initialNameSleepTogether then
            return "卧室里，" .. name .. " 已经躺下了，被子只盖到腰。他似乎还没睡着，听到你的声音，微微侧了侧身。"
        else
            return name .. " 在自己的铺位上躺着，呼吸平缓。月光透过窗户洒在地板上。"
        end
    end
end

-- ==================== 莱德互动事件池 ====================

HomeEventData.leideEvents = {
    -- 日常互动
    {
        id = "leide_sword",
        condition = function(S) return getTimePeriod() == "morning" end,
        text = function()
            return leideName() .. " 站在门口，握着剑，慢慢比划着。动作精准而沉默，像是在跟看不见的对手过招。\n\n你站在一旁看了一会儿，他似乎注意到了你，但没有停下。"
        end,
        choices = {
            { text = "「教我两招？」", aff = 5, reply = function()
                return "他停下来，看了你一眼。「站好。」他走过来，纠正你的站姿。手指碰到你肩膀的时候顿了一下，然后很快移开。"
            end, fatigue = 5, time = 30 },
            { text = "安静地看他练完", aff = 8, reply = function()
                return "他练了很久。收剑的时候，额头上有一层薄汗。他走过来，从你手里接过你不知道什么时候准备好的毛巾。「...谢谢。」"
            end, time = 20 },
            { text = "「别太累了。」", aff = 3, reply = function()
                return "他抬头看你，表情没什么变化，但动作放缓了一些。「嗯。」"
            end, time = 5 },
        },
    },
    {
        id = "leide_cook",
        condition = function(S) return getTimePeriod() == "evening" and (S.initialNameLevel or 1) >= 3 end,
        text = function()
            return "你走进厨房，发现" .. leideName() .. "正在炉子前忙碌。他围着一条有些旧的围裙，动作笨拙但认真。\n\n锅里的东西正在冒烟——不确定是煮熟了还是糊了。"
        end,
        choices = {
            { text = "「我来帮你。」", aff = 8, reply = function()
                return "你走过去，站在他旁边。两个人的手偶尔碰到一起。\n\n菜的味道一般，但他全部吃完了。"
            end, satiety = 20, time = 30 },
            { text = "「闻着不错。」", aff = 5, reply = function()
                return "他转过头看你。你确定他的耳尖红了一下。「...是吗。」\n\n后来你吃了一口。很咸。但你说好吃。他又做了一份。"
            end, satiety = 15, time = 20 },
            { text = "偷偷拍下他围围裙的样子", aff = 3, reply = function()
                return "他的背影意外地好看。他回头的时候你假装在看别的地方。\n\n他好像知道了。但什么都没说。"
            end, time = 5 },
        },
    },
    {
        id = "leide_nightmare",
        condition = function(S) return HomeEventData.isNight() and (S.initialNameLevel or 1) >= 2 end,
        text = function()
            local name = leideName()
            if GameState.state.initialNameSleepTogether then
                return "半夜，" .. name .. " 的身体突然绷紧了。他在梦里发出低低的声音，眉头紧锁，额头渗出冷汗。\n\n你被他的动作惊醒了。"
            else
                return "你被隔壁传来的声音惊醒。是" .. name .. "。他似乎在做噩梦，发出断断续续的低吟。"
            end
        end,
        choices = {
            { text = "轻轻握住他的手", aff = 10, reply = function()
                local name = leideName()
                return "你的手指碰到他的时候，他猛地一颤，差点醒来。\n\n但你没有松手。过了一会儿，他的呼吸慢慢平稳了。手指无意识地反握住你的。\n\n" .. name .. "没有醒来，但嘴角的紧绑松开了一些。"
            end, time = 15 },
            { text = function() return "「" .. leideName() .. "，醒醒。」" end, aff = 5, reply = function()
                local name = leideName()
                return name .. " 猛地睁开眼，眼神里满是惊恐。他看到是你，愣了几秒，然后慢慢坐起来。\n\n「...吵到你了？」他的声音有点哑。\n「没事。」\n「...嗯。」他靠在墙上，盯着天花板。过了很久才说：「以前做的梦。不重要了。」"
            end, time = 10 },
        },
    },
    {
        id = "leide_sweet",
        condition = function(S) return (S.initialNameLevel or 1) >= 4 and getTimePeriod() ~= "night" end,
        text = function()
            return "你在桌子下面发现了一个纸包。打开一看，是几块糖果——外面裹着彩色的糖纸。\n\n" .. leideName() .. " 正好走进来，看到你手里的东西，动作明显顿了一下。"
        end,
        choices = {
            { text = "「原来你喜欢吃甜的。」", aff = 8, reply = function()
                return "他站在那里，耳尖慢慢变红。\n「...不是。路上捡的。」\n「骗人。」\n「...」\n\n他走过来，从你手里拿走纸包。然后，递给你一颗。「别跟别人说。」"
            end, stress = -5, time = 10 },
            { text = "假装没看到，放回原位", aff = 12, reply = function()
                return "你把纸包原样放回去，若无其事地走开了。\n\n第二天，你发现桌子上多了一颗糖。没有纸条，也没有解释。\n\n但你知道是谁放的。"
            end, time = 5 },
        },
    },
    {
        id = "leide_rain",
        condition = function(S) return getTimePeriod() == "afternoon" end,
        text = function()
            return "外面突然下起了雨。雨点打在窗户上，啪啪作响。\n\n" .. leideName() .. " 站在窗边，看着外面的雨。他的表情比平时柔和了一些。"
        end,
        choices = {
            { text = "站在他旁边一起看雨", aff = 8, reply = function()
                return "你走过去，和他并肩站着。雨声很大，但屋子里很安静。\n\n过了很久，他开口：「...以前下雨的时候，没有地方躲。」\n\n他没有继续说下去。你也没有问。你们就这样站着，听雨。"
            end, stress = -8, time = 20 },
            { text = "「泡杯热茶吧。」", aff = 5, reply = function()
                return "你端来两杯热茶。他接过去的时候，手指碰到你的指尖。\n\n「...暖的。」他说。你不确定他说的是茶还是别的。"
            end, stress = -5, time = 15 },
        },
    },
    {
        id = "leide_scar",
        condition = function(S) return HomeEventData.isNight() and (S.initialNameLevel or 1) >= 3 and not S.leide_scar_seen end,
        text = function()
            local name = leideName()
            return "你无意间看到" .. name .. " 在换衣服。\n\n他背上有一道很长的伤疤，从左肩一直延伸到腰际。伤口早已愈合，但疤痕狰狞，像是一条苍白的蜈蚣。\n\n他注意到你的目光，动作停顿了一瞬。"
        end,
        choices = {
            { text = "「……疼吗？」", aff = 12, reply = function()
                local name = leideName()
                GameState.state.leide_scar_seen = true
                return name .. " 沉默了很久。\n\n「不疼了。」他把衣服穿好，背对着你。\n\n「……是逃出来的时候留下的。有人拿刀从后面砍了一刀。我跑了两天两夜才到安全的地方。」\n\n他转过身，看着你的眼睛：「但我活下来了。」\n\n你不知道该说什么。最后你走过去，轻轻碰了碰他的肩。他没有躲开。"
            end, time = 15 },
            { text = "假装没看到，转过身去", aff = 8, reply = function()
                GameState.state.leide_scar_seen = true
                return "你默默转过身，假装在找什么东西。\n\n身后传来窸窸窣窣穿衣服的声音。过了一会儿，" .. leideName() .. " 走到你身边坐下。\n\n「……你看到了。」不是疑问句。\n「嗯。」\n\n他没再说什么。但那天晚上，他坐在你旁边的时间比平时久了一些。"
            end, time = 10 },
        },
    },
    {
        id = "leide_birthday",
        condition = function(S) return not S.leide_birthday_done and (S.initialNameLevel or 1) >= 4 and getTimePeriod() ~= "night" end,
        text = function()
            local name = leideName()
            return name .. " 走进来的时候，手背在身后，表情比平时更僵硬。\n\n他站了一会儿，像是在做某种心理建设。然后他把手伸出来——\n\n是一条手工编织的手绳。编工说不上精致，线头还有些毛糙，但颜色搭配得很用心。\n\n「今天……是你的生辰。」他别过头，「不是什么好东西。嫌弃的话就扔了。」"
        end,
        choices = {
            { text = "立刻戴上", aff = 15, reply = function()
                GameState.state.leide_birthday_done = true
                return "你把手绳戴在手腕上。大小刚刚好。\n\n「你怎么知道我手腕多粗的？」\n\n" .. leideName() .. " 的耳根红了：「……估的。」\n\n你低头看了看手绳。仔细看的话，里面编进了一根黑色的细线——是他的头发。\n\n你没有说出来。有些事情不说比说了更好。"
            end, time = 10 },
            { text = "「你记得我的生日？」", aff = 12, reply = function()
                GameState.state.leide_birthday_done = true
                local name = leideName()
                return name .. " 不自然地清了清嗓子。\n\n「……上次你说过一次。」\n「我只提了一句。」\n「我记性好。」\n\n他顿了顿：「戴不戴随你。」\n\n你伸出手腕。他愣了一下，然后笨拙地帮你系好了手绳。系的时候你注意到，他的手指在微微发抖。"
            end, time = 10 },
        },
    },
    {
        id = "leide_training",
        condition = function(S) return getTimePeriod() == "afternoon" and (S.initialNameLevel or 1) >= 2 end,
        text = function()
            local name = leideName()
            return name .. " 在门口空地上比划着什么动作，看起来不像练剑——更像是在练一套拳法。\n\n动作不太流畅，有些笨拙。他注意到你在看，停了下来。\n\n「……在练一套防身术。给你学的。」"
        end,
        choices = {
            { text = "「给我学的？」", aff = 10, reply = function()
                return "他别过头：「你不会用剑。万一遇到麻烦……」\n\n他走过来，握住你的手腕调整姿势。动作很轻，像是怕弄疼你。\n\n「这样。拳头攥紧，拇指在外面。」\n\n你照做了。他点点头，嘴角动了一下。\n\n「……还行。」"
            end, fatigue = 5, time = 30 },
            { text = "跟着他比划几下", aff = 8, reply = function()
                local name = leideName()
                return "你跟着他的动作比划。他在旁边看着，偶尔走过来纠正你的姿势。\n\n「膝盖弯一点。」「重心放低。」「……出拳的时候不要闭眼。」\n\n你们练了半个下午。最后你累得靠在墙上喘气，" .. name .. " 递来一杯水。\n\n「明天继续。」他说。这是他第一次主动约你做什么事。"
            end, fatigue = 10, time = 40 },
        },
    },
    {
        id = "leide_letter",
        condition = function(S) return (S.initialNameLevel or 1) >= 3 and getTimePeriod() ~= "night" and not S.leide_letter_seen end,
        text = function()
            local name = leideName()
            return "你无意间看到" .. name .. "桌上有一张写了一半的纸。字迹歪歪扭扭，涂改了很多次。\n\n仔细辨认……开头写着：「致——」后面的名字被划掉了。再后面写着：「这段时间」，又划掉了。旁边写了「谢谢你」，也划掉了。\n\n整张纸上都是划掉的字，但每一行都在试图表达同一件事。\n\n" .. name .. " 走进来，看到你在看那张纸，脸色瞬间变了。"
        end,
        choices = {
            { text = "「你不需要写出来。我都知道。」", aff = 15, reply = function()
                GameState.state.leide_letter_seen = true
                local name = leideName()
                return name .. " 站在原地，嘴唇动了几下。\n\n然后他走过来，把纸折好收进衣兜里。\n\n「……嗯。」\n\n他的声音很轻。但你听到了所有他想说却写不出来的话。"
            end, time = 10 },
            { text = "假装什么都没看到", aff = 10, reply = function()
                GameState.state.leide_letter_seen = true
                local name = leideName()
                return "你把纸放回原位，转身做别的事。\n\n" .. name .. " 松了口气的声音你假装没听到。等你再回去看的时候，纸已经不在了。\n\n但第二天早上，你在枕头下面发现了一颗糖。"
            end, time = 5 },
        },
    },
    {
        id = "leide_music",
        condition = function(S) return getTimePeriod() == "evening" and (S.initialNameLevel or 1) >= 2 end,
        text = function()
            local name = leideName()
            return "你回来的时候，听到屋子里传来很轻的哼唱声。\n\n推开门——" .. name .. " 正在收拾东西，无意识地哼着一首曲子。旋律很古老，像是某种民间小调。\n\n他发现你在听，声音立刻断了。\n\n「……回来了。」他装作什么都没发生的样子。"
        end,
        choices = {
            { text = "「继续唱啊，挺好听的。」", aff = 8, reply = function()
                local name = leideName()
                return name .. " 的耳尖慢慢变红。\n\n「不是唱。」他说，「只是……习惯。小时候母亲哼过。」\n\n他沉默了一会儿，又小声哼了几句。这次没有停下来。\n\n你坐在旁边听着，窗外的晚霞把屋子染成了暖色。"
            end, stress = -8, time = 15 },
            { text = "什么都不说，坐下来静静听", aff = 10, reply = function()
                local name = leideName()
                return "你坐下来，没出声。\n\n" .. name .. " 顿了一下，然后继续哼着。声音比刚才大了一点点，像是在确认你不会笑他。\n\n你没有笑。那首歌很短，但他反复哼了好几遍。\n\n唱完之后，你们都没说话。窗外的风吹进来，蜡烛晃了晃。\n\n「……我母亲唱得比我好听很多。」他突然说。"
            end, stress = -10, time = 15 },
        },
    },
    {
        id = "leide_protect",
        condition = function(S) return HomeEventData.isNight() and (S.initialNameLevel or 1) >= 3 and S.initialNameSleepTogether end,
        text = function()
            local name = leideName()
            return "你半夜醒来，发现" .. name .. " 不在身边。\n\n你走到门口，看到他坐在门前的台阶上，手里握着剑，望着夜色中的街道。\n\n月光照在他的侧脸上，轮廓锋利而安静。"
        end,
        choices = {
            { text = "坐在他旁边", aff = 10, reply = function()
                local name = leideName()
                return "你在他身边坐下。石阶很凉，但他的体温透过衣袖传过来。\n\n「睡不着？」你问。\n\n「在听。」他说，「前几天街角有陌生人转悠。」\n\n你们在月光下坐了很久。他始终没有松开手中的剑。但另一只手，不知道什么时候，和你的手指交叠在了一起。\n\n「回去睡吧。」他说，「我守着。」"
            end, stress = -10, time = 20 },
            { text = "给他披一件外套", aff = 8, reply = function()
                local name = leideName()
                return "你取了一件外套出来，披在他肩上。\n\n他低头看了看肩上的衣服，沉默了几秒。\n\n「……你也一样。」他小声说，「不要光脚出来。」\n\n你低头一看——确实没穿鞋。\n\n" .. name .. " 叹了口气。然后他站起来，拉着你回屋了。「明天再守。」"
            end, time = 10 },
        },
    },
}

-- ==================== K来访事件池 ====================

HomeEventData.kVisitEvents = {
    {
        id = "k_gift_flower",
        condition = function(S) return (S.kAffection or 0) >= 200 and getTimePeriod() == "morning" end,
        text = "K站在门口，手里捧着一束刚采的野花。精灵耳微微颤动，光环在晨光中闪烁。\n\n「早上路过花园小镇的时候看到的。送给你。」她笑着把花递过来。",
        choices = {
            { text = "「好漂亮，谢谢你。」", aff = 10, reply = "K的光环闪了一下，整个人好像都亮了起来：「喜欢就好！我下次给你带不一样的。」" },
            { text = "把花插到窗边的瓶子里", aff = 12, reply = "K看着你小心翼翼地插花，歪着头笑了：「嗯，放这里正好。每天一醒来就能看到。」" },
        },
    },
    {
        id = "k_cook_together",
        condition = function(S) return getTimePeriod() == "afternoon" end,
        text = "K在厨房里翻找着什么。她的光环碰到了挂着的锅铲，叮当作响。\n\n「想做点心。」她回头看你，「你会做吗？我只会倒茶。」",
        choices = {
            { text = "「我教你。」", aff = 8, reply = "你手把手教K揉面团。她很认真，眉头微蹙，精灵耳随着节奏轻轻动着。\n\n成品歪歪扭扭的，但她看着自己的作品，开心得光环都在发光。\n「下次一定做得更好！」", time = 40, satiety = 10 },
            { text = "「我来做，你在旁边看。」", aff = 5, reply = "K乖乖坐在一旁，下巴搁在手背上看你忙碌。\n\n「你做东西的样子很好看。」她突然冒出这么一句，然后假装在看别的地方。", time = 30, satiety = 15 },
        },
    },
    {
        id = "k_sing",
        condition = function(S) return getTimePeriod() == "evening" end,
        text = "K坐在窗台上，双腿晃荡着，哼着一首你没听过的歌。旋律悠远绵长，像是很古老的曲子。\n\n光环随着音符轻轻摇曳，整个房间都被柔和的光笼罩。",
        choices = {
            { text = "安静地听完", aff = 10, reply = "她唱完了，看到你在听，耳尖微红。\n「...天使的摇篮曲。很老很老的歌了。」\n「很好听。」\n「...真的？」她笑了，光环闪了闪，「那我以后常唱给你听。」", stress = -10 },
            { text = "「能再唱一遍吗？」", aff = 8, reply = "K愣了一下，然后认真地点点头。\n\n她重新唱了一遍。这次唱得更轻、更慢，像是只唱给你一个人听。\n\n窗外的月光和她的光环交织在一起，很美。", stress = -12 },
        },
    },
    {
        id = "k_patch",
        condition = function(S) return (S.kAffection or 0) >= 150 end,
        text = "K盘腿坐在客厅地板上，正在缝补一件衣服。她的针线活出奇地好——每一针都整齐均匀。\n\n「酒馆的围裙破了。」她头也不抬，「顺便帮你也补了件外套。」",
        choices = {
            { text = "「你手真巧。」", aff = 5, reply = "「嗯。」她抬头看你，微微笑了，「活了很久嘛，什么都会一点。」\n\n她的语气很轻松，但你注意到她说「活了很久」的时候，眼神里闪过一丝不易察觉的什么。" },
            { text = "坐在她旁边，看她缝", aff = 8, reply = "你们肩并着肩坐着。她缝着衣服，你看着她的手指灵巧地穿梭。\n\n时间过得很慢，很安静，很好。" },
        },
    },
    {
        id = "k_stargazing",
        condition = function(S) return getTimePeriod() == "evening" and (S.kAffection or 0) >= 200 end,
        text = "K突然拉住你的手：「快来！今晚的星星特别亮！」\n\n她拽着你爬上屋顶——你不知道她什么时候发现了上去的路。\n\n屋顶上，整片星空铺展在头顶。K的光环在星光下变得若隐若现，像是融入了银河。",
        choices = {
            { text = "和她一起躺在屋顶看星星", aff = 12, reply = "你们并排躺在屋顶上。K指着天上的星星，给你讲天使的星座——那些人类星图上没有的故事。\n\n「那颗最亮的，天使叫它'归途之星'。迷路的时候看着它，就能找到回家的路。」\n\n她转头看你：「不过现在，我觉得不用看星星也能找到。」\n\n她的耳尖在月光下红得发烫。", stress = -15, time = 30 },
            { text = "「你以前常看星星吗？」", aff = 8, reply = "K抱着膝盖，光环黯了一下。\n\n「在天界的时候，每天都看。但那时候……觉得很孤独。」\n\n她沉默了一会儿，然后笑了起来：「现在不一样了。有人一起看，星星都变好看了。」\n\n风吹过屋顶，带着夜的凉意。K的光环重新亮了起来，比星星还温暖。", stress = -10, time = 20 },
        },
    },
    {
        id = "k_mask_off",
        condition = function(S) return (S.kAffection or 0) >= 300 and (S.kLevel or 1) >= 3 and not S.kMaskRevealed end,
        text = "K今天很安静。她坐在窗边，手指无意识地摸着自己的脸——那张看起来完美无瑕的脸。\n\n她犹豫了很久，终于开口：「……我想给你看一样东西。但你要答应我，不要害怕。」\n\n她深吸一口气，然后——\n\n她的右脸上浮现出细密的裂纹，像是瓷器上的龟裂。裂纹中透出微弱的金色光芒。\n\n「这是……我坠落时留下的。」她的声音很轻，「在天界的时候，这叫'堕痕'。」",
        choices = {
            { text = "伸手轻轻碰触那些裂纹", aff = 20, reply = function()
                GameState.state.kMaskRevealed = true
                return "你的指尖碰到她脸上的裂纹。温热的，像是触摸到了她体内的光。\n\nK闭上了眼睛，睫毛在颤抖。\n\n「……不疼的。」她说。但你感觉到她在轻轻发抖。\n\n「只是一直藏着，有点累。」\n\n你没有收回手。过了很久，她覆上你的手指，将你的手按在自己脸颊上。\n\n「谢谢你没有躲开。」\n\n她的光环比任何时候都亮。"
            end, time = 15 },
            { text = "「你不用在我面前藏着。」", aff = 15, reply = function()
                GameState.state.kMaskRevealed = true
                return "K睁大了眼睛。光环闪烁了几下，像是在消化你的话。\n\n然后她笑了。是那种会皱鼻子的、不加修饰的笑。\n\n「好。」她把幻术彻底解除。右半边脸上布满了金色的裂纹，在光环的映照下像是一幅抽象画。\n\n「以后在你面前，我就这样了。」\n\n她歪了歪头：「是不是比原来更好看？」\n\n你被她逗笑了。她也跟着笑了起来。"
            end, time = 10 },
        },
    },
    {
        id = "k_sick",
        condition = function(S) return (S.kAffection or 0) >= 150 and getTimePeriod() ~= "night" end,
        text = "K进门的时候脚步不太稳。她的光环暗了很多，精灵耳也耷拉着。\n\n「没事没事……」她打了个喷嚏，光环跟着闪了一下，「就是有点……阿嚏！」\n\n她不好意思地揉了揉鼻子：「原来天使也会感冒……当了三百年神使都没发现这件事。」",
        choices = {
            { text = "让她躺下，去煮姜汤", aff = 12, reply = "你扶她到床边躺下，又去厨房煮了一碗姜汤。\n\nK窝在被子里，只露出一双眼睛和耷拉的精灵耳。她小口小口地喝着姜汤，表情皱成一团。\n\n「好辣……」她嘟囔。但还是乖乖喝完了。\n\n你坐在床边陪她。不知道什么时候，她睡着了，手指攥着你的袖角。\n光环在睡梦中一明一暗，像是在安静地呼吸。", time = 40, stress = -5 },
            { text = "摸摸她的额头看有没有发烧", aff = 8, reply = "你把手贴上她的额头。温度比正常人高一些，但K的体温本来就偏高。\n\n她眨了眨眼睛，没有躲开。\n\n「你的手好凉。」她说，然后把脸往你手心里蹭了蹭，「……好舒服。」\n\n你没忍住笑了一声。她的耳尖红了，但也没有挪开。\n\n「生病的时候有人照顾的感觉……原来是这样的。」她小声说。", time = 20 },
        },
    },
    {
        id = "k_drawing",
        condition = function(S) return getTimePeriod() == "afternoon" and (S.kAffection or 0) >= 120 end,
        text = "K趴在桌上，拿着一根炭笔，认真地画着什么。她的精灵耳随着笔触微微晃动，光环安静地悬在头顶。\n\n你走近看——画的是你家的窗户，窗外有一小块天空。画得歪歪扭扭，但能看出来很用心。\n\n「啊！别看！」她慌忙用手臂挡住画纸。",
        choices = {
            { text = "「画得很好啊。」", aff = 8, reply = "K的耳尖慢慢变红。她犹豫了一下，还是把画纸递给你。\n\n「……其实是想画你来着。但画不像。就画了窗户。」\n\n你仔细看，窗台上画了一个模糊的人影。她画了又擦了又画，纸都快磨破了。\n\n「下次我画好一点的送你。」她小声说。", time = 10 },
            { text = "「那个是我吗？」指着窗台上的人影", aff = 12, reply = "K把脸埋在手臂里，光环亮得像灯泡。\n\n「……才不是。是窗帘。」\n\n窗帘不会有头发。你没有戳破她。\n\n第二天你在枕头下面发现了一张折好的画——画的是一只猫。背面写着：「这个比较好画。下次一定画你。」", time = 10 },
        },
    },
    {
        id = "k_nightmare",
        condition = function(S) return getTimePeriod() == "evening" and (S.kAffection or 0) >= 200 and (S.kLevel or 1) >= 2 end,
        text = "K坐在角落里，双手抱着膝盖，光环暗得几乎看不见。精灵耳紧紧贴着头发。\n\n她没有听到你进来。你走近才发现她在发抖。\n\n「……那些声音又出现了。」她的声音很低，「坠落的时候听到的声音。有时候会突然回来。」",
        choices = {
            { text = "坐在她旁边，握住她的手", aff = 15, reply = "你在她身边坐下，轻轻握住她冰凉的手。\n\nK颤了一下，然后慢慢把头靠在你的肩膀上。\n\n「……它们说我不配拥有光环。」她的声音闷闷的，「说我是叛徒。」\n\n你握紧了她的手。过了很久，她的光环重新亮了起来——先是微弱的，然后越来越稳定。\n\n「你的手很暖。」她抬头看你，眼角有一点水光，但在笑。\n\n「声音走了。」", stress = -5, time = 20 },
            { text = "给她泡一杯热茶，安静地陪着", aff = 10, reply = "你没有说话，去厨房泡了一杯热茶端过来。\n\nK接过杯子，双手包着，像是在汲取温度。\n\n你们就这样坐着。你翻着书，她捧着茶。慢慢地，她的精灵耳重新直了起来，光环也恢复了平时的亮度。\n\n「……你不问我怎么了吗？」\n「你想说的时候会说的。」\n\n她低头喝茶，嘴角浮起一个小小的弧度：「嗯。」", stress = -8, time = 25 },
        },
    },
    {
        id = "k_dance",
        condition = function(S) return getTimePeriod() == "morning" and (S.kAffection or 0) >= 180 end,
        text = "你推门进来，发现K正在客厅中央旋转——光环在她头顶画出金色的圆弧，精灵耳随着动作轻轻飘动。\n\n她在跳舞。动作很轻盈，脚尖几乎不碰地面，像是真的在飞。\n\n她看到你，旋转的动作顿了一下，差点绊倒。\n\n「哈、哈哈……早上好？」她的脸红得像番茄。",
        choices = {
            { text = "「教我跳？」", aff = 10, reply = "K愣了一下，然后开心得光环都在发光：「真的？！」\n\n她拉着你的手，开始教你天使的舞步。说是舞步，其实更像是在空中画圈的游戏。\n\n你们在狭小的客厅里绕着圈，碰翻了一把椅子。K笑到弯腰，你扶着她，两个人都站不稳。\n\n「天使的舞本来是飞着跳的……」她擦着笑出来的眼泪，「在地上跳确实有点难。」", stress = -10, time = 20 },
            { text = "鼓掌", aff = 8, reply = "你拍了几下手。K的耳尖红透了，但她没有躲开。\n\n她深吸一口气，重新开始跳。这次更认真了，每一个动作都舒展到极致。\n\n光环在她头顶织出一道道光线，像是微型的极光。\n\n跳完以后她有点喘，但笑得很灿烂：「在天界的时候，没有人看过我跳。」\n\n她小声说：「有观众的感觉……很好。」", stress = -8, time = 15 },
        },
    },
}

-- ==================== 奥梅尔来访事件池 ====================

HomeEventData.oamelVisitEvents = {
    {
        id = "oamel_door",
        text = function()
            return "有人敲门。你打开门，看到奥梅尔站在门口，穿着深色外套，红发扎在脑后。\n\n他扫了一眼你的住处，眉头皱了皱：「...你就住这种地方？」\n\n语气很嫌弃，但他还是走进来了。"
        end,
        choices = {
            { text = "「稀客啊，请进。」", aff = 5, reply = "他径直走到唯一的椅子前坐下，翘起二郎腿。\n\n「路过。」他说，目光在屋子里转了一圈，「真的只是路过。」\n\n他带了一袋点心。「别误会，太多了吃不完。」" },
            { text = "「你怎么知道我住这？」", aff = 3, reply = "他的耳尖微微泛红。「随便问的。」他走进来，把一个纸袋放在桌上。\n\n「顺路买的。不是特意的。」\n\n纸袋里是你上次说过好吃的那家面包店的甜面包。" },
            { text = "「要喝点什么吗？」", aff = 5, reply = "「你这也有东西喝？」他挑了挑眉，坐下了。\n\n你倒了杯水给他。他看了看杯子，没说什么，慢慢喝了。\n\n走的时候他把杯子摆得整整齐齐。" },
        },
    },
    {
        id = "oamel_rain",
        condition = function(S) return getTimePeriod() == "evening" end,
        text = function()
            return "门外传来急促的敲门声。你打开门，奥梅尔站在雨里，红发湿透了贴在脸上，表情很凶。\n\n「让开。」他挤进来，外套上的水滴了一地。\n\n「...不是来找你的。」他站在门口发着抖，「马车坏了。」"
        end,
        choices = {
            { text = "递给他毛巾", aff = 8, reply = "他接过毛巾的时候手指碰到你的。他猛地缩回去，然后又慢慢接过来。\n\n「...谢了。」他把头发擦干，红色的发丝蓬松起来，看起来没那么凶了。\n\n他坐在角落里等雨停，你们有一搭没一搭地说着话。走的时候他把毛巾叠得很整齐放在桌上。" },
            { text = "「外套脱了吧，会着凉。」", aff = 10, reply = "他僵了一下。「...不用你管。」\n\n但他还是脱了。你把外套挂在火边烤。他坐在一旁，抱着胳膊，耳尖红得快滴血。\n\n「你跟谁都这样？」他突然问。\n\n你还没回答，他就低头看着自己的鞋尖：「...算了，不想知道。」" },
        },
    },
    {
        id = "oamel_jealous",
        condition = function(S) return HomeEventData.isLeideHome() and (S.oamelAffection or 0) >= 150 end,
        text = function()
            local name = leideName()
            return "奥梅尔进门的时候看到" .. name .. "，脚步顿了一下。\n\n「...你在啊。」他的语气冷了几度，下巴抬得更高了。\n\n" .. name .. " 看了他一眼，没说话，继续擦剑。\n\n空气突然变得有点微妙。"
        end,
        choices = {
            { text = "「你们认识？」", aff = 3, reply = function()
                local name = leideName()
                return "奥梅尔冷哼一声：「谁要认识他。」\n\n" .. name .. " 头也不抬：「...嗯。」\n\n奥梅尔的耳朵更红了。他坐得离" .. name .. "尽可能远的地方，但眼角一直在瞟。"
            end },
            { text = "给两人都倒杯茶", aff = 5, reply = function()
                local name = leideName()
                return "你端来三杯茶。奥梅尔接过的时候特意看了看" .. name .. "杯里的量。\n\n「...你给他的比我多。」\n「一样多。」\n「哼。」\n\n" .. name .. " 嘴角动了一下。你不确定那算不算笑。"
            end },
        },
    },
    {
        id = "oamel_gift",
        condition = function(S) return (S.oamelAffection or 0) >= 200 end,
        text = function()
            return "奥梅尔走进来的时候，手里拎着一个精致的纸袋。\n\n他把纸袋往桌上一放，扭过头：「路上看到的。打折。不买白不买。」\n\n你打开纸袋——是一件质地极好的围巾，颜色恰好是你常穿的衣服的配色。\n\n「不是特意挑的颜色。」他补充，「碰巧而已。」\n\n围巾上还挂着价签。你瞥了一眼——那个数字绝对不是「打折」能解释的。"
        end,
        choices = {
            { text = "「很好看，谢谢。」直接围上", aff = 12, reply = "你把围巾围上。很软，很暖。\n\n奥梅尔瞟了你一眼，又迅速移开视线。他的耳尖红得像要滴血。\n\n「……还行。」他清了清嗓子，「比你之前那条好多了。之前那条难看死了。」\n\n他说完就坐到角落去了，假装看窗外。但你注意到他的嘴角一直没放下来。", time = 10 },
            { text = "「这个很贵吧？我不能收。」", aff = 8, reply = "奥梅尔的脸色瞬间难看了几分。\n\n「谁说贵了？打折的。」他把纸袋推回你手里，「收着。嫌贵的话就当……就当我预付的房间茶水费。」\n\n他转身就走，在门口停了一下：「围巾洗的时候用冷水。别搓。」\n\n门关上之后你笑了。他嘴硬的样子真的很好笑。", time = 5 },
        },
    },
    {
        id = "oamel_asleep",
        condition = function(S) return (getTimePeriod() == "afternoon" or getTimePeriod() == "evening") and not S.oamel_asleep_seen end,
        text = function()
            return "你从外面回来，发现奥梅尔靠在椅子上睡着了。\n\n他的表情不像清醒时那么尖锐。红发松散地垂下来，呼吸很平稳。\n\n桌上放着一杯喝了一半的茶——他大概是等你等着等着就睡着了。\n\n你从来没见过他这么安静的样子。"
        end,
        choices = {
            { text = "轻轻给他盖上外套", aff = 12, reply = function()
                GameState.state.oamel_asleep_seen = true
                return "你把自己的外套轻轻搭在他身上。他动了一下，嘴里含糊不清地嘟囔了什么。\n\n你凑近一点——\n\n「……别走。」\n\n他说的声音很小，不确定是在说梦话还是半醒。\n\n你在他旁边坐下，没有出声。过了大约半小时，他醒了，看到身上的外套愣了一下。\n\n「……我不是故意睡着的。」他站起来，把外套叠得整整齐齐放在桌上。\n\n走到门口的时候，他停了一下：「你的外套……挺暖的。」\n\n然后他就走了。但他今天走路的姿势比平时轻快。"
            end, time = 35 },
            { text = "在旁边安静地看书，等他醒", aff = 8, reply = function()
                GameState.state.oamel_asleep_seen = true
                return "你拿了本书，在旁边的椅子上坐下。\n\n奥梅尔的睡相意外地好。不打呼，不流口水，就是安安静静地靠在那里。\n\n大约过了二十分钟，他睁开了眼。看到你在旁边，先是一愣，然后脸色瞬间变得通红。\n\n「你、你什么时候回来的？！」\n「半小时前。」\n「你就坐在旁边看着我睡？！」\n「嗯。」\n\n他站起来，抓起外套就往门外走。\n「不来了！再也不来了！」\n\n第二天他又来了。"
            end, time = 30 },
        },
    },
    {
        id = "oamel_cook_critic",
        condition = function(S) return getTimePeriod() == "afternoon" and (S.oamelAffection or 0) >= 120 end,
        text = function()
            return "奥梅尔站在厨房里，手里拿着你的铁锅，表情嫌弃到了极点。\n\n「这个锅生锈了。这把刀也该磨了。你平时用这种东西做饭？」\n\n他卷起袖子——露出手臂上淡淡的几道旧伤疤——开始翻找食材。\n\n「让开，我来。」"
        end,
        choices = {
            { text = "乖乖让到一边看他做", aff = 10, reply = function()
                return "奥梅尔做菜的动作干净利落，像是经过专业训练。调料放得精确，火候拿捏得恰到好处。\n\n二十分钟后，桌上摆了一道色香味俱全的炒菜。\n\n「一般般。」他坐下来，假装不在意地瞟着你的表情。\n\n你吃了一口。很好吃。你说了。\n\n他猛地低头，耳尖红得像他的头发：「……当然了。」"
            end, satiety = 30, time = 25 },
            { text = "「我帮你打下手？」", aff = 8, reply = function()
                return "「别碍事。」他说。但他递给你一把蒜头：「剥这个。」\n\n你们在狭小的厨房里忙碌。他会绕过你的时候故意保持距离，但偶尔还是会碰到。\n\n做好以后他尝了一口，点了点头。又给你盛了一碗——比他自己的那碗多。\n\n「别说出去。」他严肃地看着你，「我给你做了饭这件事。」"
            end, satiety = 25, time = 30 },
        },
    },
    {
        id = "oamel_book",
        condition = function(S) return getTimePeriod() ~= "night" and (S.oamelAffection or 0) >= 160 end,
        text = function()
            return "奥梅尔今天带了一本书过来。封面很精致，是一本关于草药学的典籍。\n\n他翻了几页，皱着眉头：「这个镇子上的药铺水平太差了。连基础的复方都配不对。」\n\n他抬头看你：「你有没有学过一点基础医药？万一受伤了连自己处理都不会。」"
        end,
        choices = {
            { text = "「你教我？」", aff = 10, reply = function()
                return "奥梅尔「哼」了一声，但把书推到你面前。\n\n「这三种草药记住。这个是止血的，这个消炎，这个退烧。」他指着图，讲解得出人意料地耐心。\n\n你认真地听着。他的语气渐渐从嫌弃变成了正常的教学口吻。\n\n讲完以后他合上书：「……记住了？」\n「记住了。」\n\n他点点头，把书留在桌上：「这本先放你这。不准弄脏。」"
            end, time = 30 },
            { text = "「你好像很懂？」", aff = 5, reply = function()
                return "奥梅尔的表情微妙地变了一下。\n\n「……小时候学过。」他停顿了一下，「我母亲以前是药剂师。」\n\n他说完又恢复了那副满不在乎的样子，但你注意到他翻书的动作变轻了。\n\n「反正比你懂就是了。」"
            end, time = 15 },
        },
    },
    {
        id = "oamel_injury",
        condition = function(S) return (S.oamelAffection or 0) >= 180 and not S.oamel_injury_seen end,
        text = function()
            return "你打开门，奥梅尔站在外面。他的嘴角有一道破口，左手的指关节擦破了皮，青紫一片。\n\n「……能借个洗手间吗？」他的语气比平时冷硬，像是在强撑着什么。\n\n他走进来的时候步子有点虚。仔细看，外套下面隐约渗出一点血。"
        end,
        choices = {
            { text = "什么都不问，默默去拿布和药", aff = 15, reply = function()
                GameState.state.oamel_injury_seen = true
                return "你端来一盆温水和干净的布条，蹲在他面前。\n\n他顿了一下，然后慢慢把外套脱了。肋骨的位置有一道不深但很长的划伤。\n\n你帮他清洗伤口的时候，他一声不吭。但他的手在发抖。\n\n「……跟帮派有关。不是什么大事。」\n\n你没说话，把伤口包扎好了。\n\n他低头看着你绑的绷带，沉默了很久：「你手真轻。」\n\n然后更小声地：「……谢谢。」"
            end, time = 20 },
            { text = "「谁干的？」", aff = 10, reply = function()
                GameState.state.oamel_injury_seen = true
                return "他的眼神冷了一瞬。「不关你事。」\n\n但他还是坐了下来，任你给他处理伤口。\n\n「……是以前的人。想找麻烦。」他在你给他擦药的时候吸了一口冷气。\n\n「已经解决了。不会再来了。」\n\n你觉得他说的「解决」，可能跟你理解的「解决」不太一样。\n\n「别用那种眼神看我。」他别过头。\n\n但他在你包好绷带之后，很久很久都没有站起来。"
            end, time = 15 },
        },
    },
}

-- ==================== 乌列尔信件 ====================

HomeEventData.urielLetters = {
    {
        condition = function(S) return (S.urielLetterCount or 0) == 0 end,
        text = "你在门口发现了一封没有署名的信。信封上没有任何标记，但字迹很漂亮。\n\n「一切都好。注意身体。」\n\n只有这一行字。但你认得这个字迹。是哥哥的。",
        effect = function(S) S.urielAffection = (S.urielAffection or 0) + 5 end,
    },
    {
        condition = function(S) return (S.urielLetterCount or 0) == 1 end,
        text = "门缝里塞着一封信。和上次一样的信封，一样漂亮的字迹。\n\n「听说那边入冬了。窗户关好。不要踢被子。」\n\n你笑了一下。他还把你当小孩子。",
        effect = function(S) S.urielAffection = (S.urielAffection or 0) + 5 end,
    },
    {
        condition = function(S) return (S.urielLetterCount or 0) == 2 end,
        text = "第三封信。这次信封里除了信纸，还有一张折好的钞票。\n\n「不是很多。别省着不吃饭。有事写信给管家转交。」\n\n钞票很新，像是特意换的。",
        effect = function(S) S.urielAffection = (S.urielAffection or 0) + 8; S.money = S.money + 200 end,
    },
    {
        condition = function(S) return (S.urielLetterCount or 0) == 3 end,
        text = "又一封信。这次的信比以前长一些。\n\n「你小时候总问我什么时候回来。我说等你长大。你长大了，自己出去住了。有时候家里太安静，我会去你以前的房间站一会儿。\n\n不用回信。知道你好就行。」\n\n纸上有一个地方的墨迹晕开了一点。你不确定是水渍还是什么。",
        effect = function(S) S.urielAffection = (S.urielAffection or 0) + 10 end,
    },
    {
        condition = function(S) return (S.urielLetterCount or 0) >= 4 end,
        text = function()
            local letters = {
                "「天气转暖了。别穿太少。」",
                "「听说你交了朋友。很好。」",
                "「管家说你没写信回来。不强求。但偶尔写一封。」",
                "「今天整理书房，找到你小时候画的画。画得很丑。我留着了。」",
                "「如果遇到麻烦，不要硬撑。」",
            }
            local idx = ((GameState.state.urielLetterCount or 0) - 4) % #letters + 1
            return "又一封没有署名的信。\n\n" .. letters[idx] .. "\n\n字迹和往常一样工整。你把信小心地收好。"
        end,
        effect = function(S) S.urielAffection = (S.urielAffection or 0) + 5 end,
    },
}

return HomeEventData
