-- passages/location/GardenTown.lua
-- Auto-split sub-module, returns installer function

return function(handlers, deps)

local GameState = deps.GameState
local TimeSystem = deps.TimeSystem
local NPCSystem = deps.NPCSystem
local WorkSystem = deps.WorkSystem
local HomeSystem = deps.HomeSystem
local MainQuest = deps.MainQuest
local CommonUtils = deps.CommonUtils
local PassageDeps = deps.PassageDeps
local addAffection = deps.addAffection
local addDateLog = deps.addDateLog
local doWorkWithEvent = deps.doWorkWithEvent
local isLeiDeHome = deps.isLeiDeHome

handlers["花园小镇"] = function(S)
    local text = "花园小镇\n\n"
        .. "从十字路口往北，穿过一片稀疏的白桦林，空气逐渐变得清甜——花园小镇到了。"
        .. "这里不大，木屋沿着蜿蜒的土路错落分布，篱笆墙上攀满了牵牛花和蔷薇。"
        .. "偶尔有蝴蝶从花丛中飞起，在阳光里划出轻盈的弧线。\n\n"
        .. "虽然房屋有些陈旧，但家家户户门前都摆着花盆，打理得干干净净。"
        .. "几个孩子光着脚在巷子里追逐嬉闹，一位老妇人坐在门廊下纳鞋底，时不时抬头喊一声。"

    -- 事件描述融入正文
    local kFlowerEvent = false
    if (S.kAffection or 0) >= 100 and S.hour >= 8 and S.hour < 17 then
        kFlowerEvent = true
        text = text .. "\n\n村口的一小片花圃前，K正蹲在地上侍弄花草，光环在阳光下若隐若现。"
    end

    if (S.LL or 1) >= 6 then
        text = text .. "\n\n拐角处有一条漆黑的小道，隐约传来争吵声。"
    end

    local choices = {}

    -- ══════ 地点导航（置顶） ══════
    table.insert(choices, { text = "🏘️ 在小镇里转转", action = function()
        TimeSystem.addMinutes(15)
        local scenes = {
            "你在小镇的巷子里穿行。石板路被岁月磨得光溜溜的，两旁的墙壁上爬满了常春藤。"
            .. "几个孩子正追着一只跛脚的花猫嬉闹，笑声在窄巷中回荡。"
            .. "花猫灵巧地跳上墙头，回头看了孩子们一眼，尾巴一甩便消失在屋顶的另一边。"
            .. "一个倚在门框上的妇人朝你笑了笑：「又来溜达了？今天天气不错呢。」",
            "路边的一棵老橡树下，一个白发老人正慢悠悠地修补木桶。"
            .. "他的手指关节粗大，布满了岁月的痕迹，但箍桶的动作却依然精准。"
            .. "铁箍敲上去「咚」的一声，木桶发出一种沉闷的共鸣。"
            .. "老人抬头看了你一眼，眼角的皱纹挤在一起：「年轻人，不忙的话坐会儿？」"
            .. "你在旁边的石阶上坐了一小会儿，听着叮叮当当的敲击声，出奇地安心。",
            "巷子深处传来断断续续的锤声。你好奇地走过去，发现一个小院子里有人在做木工——"
            .. "一个中年女人正给一把椅子的腿刷上深红色的漆，地上散着刨花和木屑。"
            .. "空气中飘着新鲜木材的清香，混合着从隔壁传来的炖肉的味道。"
            .. "女人冲你点点头：「走路小心，别踩着钉子。」你绕过木屑堆继续往前走。",
            "你经过镇子中央的小水井。几个妇人正围在井边洗衣服聊天，"
            .. "湿漉漉的衣服搭在旁边的绳子上，被风吹得鼓鼓囊囊。"
            .. "一个梳着辫子的小女孩蹲在井沿上往下探头，被母亲一把拽了回来。"
            .. "「跟你说了多少次不要靠近！」小女孩吐了吐舌头，转身又跑去追蝴蝶了。"
            .. "你站在一旁看了会儿，这种平凡又喧闹的日常让你觉得很温暖。",
            "小镇的尽头有一片小小的果园，篱笆缺了好几根木桩，里面的苹果树上挂着青涩的果子。"
            .. "一只灰色的松鼠在树枝间窜来窜去，嘴里叼着一颗不知从哪儿偷来的坚果。"
            .. "你靠在篱笆上发了一会儿呆，听着树叶在风中沙沙作响，"
            .. "远处有人在用走调的嗓门哼着不知名的歌谣。日子就这样不紧不慢地过着。",
            "你走进一条从没来过的小巷。巷口种着两棵枣树，地上落了一层枣花，踩上去软绵绵的。"
            .. "巷子里只有一户人家，门口的条凳上坐着一个打瞌睡的老爷爷，"
            .. "膝盖上蜷着一只胖橘猫，两个都睡得很沉。"
            .. "你放轻脚步走过去，生怕吵醒这幅安详的画面。阳光斜斜地照进巷子，"
            .. "把老人和猫咪的影子拉得长长的。你觉得这大概就是「岁月静好」的模样。",
        }
        GameState.showNotification(scenes[math.random(1, #scenes)])
        return "花园小镇"
    end })
    table.insert(choices, { text = "🚶 往北走（主城区）", action = function() TimeSystem.addMinutes(5) return "主城区" end })
    table.insert(choices, { text = "🏚️ 穿过小巷往西（贫民窟）", action = function() TimeSystem.addMinutes(5) return "贫民窟" end })
    table.insert(choices, { text = "🔙 返回十字路口", action = function() TimeSystem.addMinutes(5) return "十字路口" end })

    -- ══════ 事件互动（由文字引出） ══════
    if kFlowerEvent then
        table.insert(choices, {
            text = "🌸 走过去看看K在种什么",
            action = function()
                addAffection("k", 5)
                TimeSystem.addMinutes(20)
                return "花园小镇"
            end,
        })
    end

    if (S.LL or 1) >= 6 then
        table.insert(choices, {
            text = "⚠️ 走进那条漆黑的小道",
            target = "花园小镇_小巷",
        })
    end

    return { text = text, choices = choices }
end

---===================== 花园小镇_小巷 =====================
--- Twine pid 24 内嵌的力量门控巷子事件（莱恩救援）


handlers["花园小镇_小巷"] = function(S)
    local text = "你拐进巷子，几个痞子样的人靠在墙上，见你进来，其中一个叼着烟卷的歪嘴笑笑：「哟，哪来的小羊羔？」\n\n"
        .. "你没理他，径直往里走。他伸手拦你，你一把抓住他手腕，反拧。他惨叫一声，其他人愣住，你扫了一眼：「让开。」\n\n"
        .. "他们骂骂咧咧地退开。你走到巷子深处，看见一个人靠着墙，衣服上沾着血，脸上有淤青。"
        .. "他抬起头，眼神锐利，像受伤的狼。\n\n"
        .. "「多管闲事？」他声音哑，但语气很冲。\n\n"
        .. "你蹲下来看他伤口：「被谁打的？」\n\n"
        .. "「不关你事。」他想站起来，腿一软又靠回去。"

    return {
        text = text,
        choices = {
            { text = "🏥 带他去诊所", action = function()
                if S.money >= 10 then
                    S.money = S.money - 10
                    addAffection("initialName", 5)
                    TimeSystem.addMinutes(30)
                else
                    TimeSystem.addMinutes(10)
                end
                return "花园小镇"
            end },
            { text = "🍞 给他点吃的和水", action = function()
                addAffection("initialName", 3)
                TimeSystem.addMinutes(15)
                return "花园小镇"
            end },
            { text = "🚶 转身离开", action = function()
                TimeSystem.addMinutes(5)
                return "花园小镇"
            end },
        },
    }
end

---===================== 贫民窟 =====================


end
