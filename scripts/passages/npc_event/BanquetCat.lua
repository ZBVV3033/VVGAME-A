-- passages/npc_event/BanquetCat.lua
-- Auto-split sub-module

return function(handlers, deps)

local GameState = deps.GameState
local TimeSystem = deps.TimeSystem
local WorkSystem = deps.WorkSystem
local CommonUtils = deps.CommonUtils
local PassageDeps = deps.PassageDeps
local addAffection = deps.addAffection
local addDateLog = deps.addDateLog
local addOamelAffection = deps.addOamelAffection
local addMeifeiAffection = deps.addMeifeiAffection
local addHistoryExp = deps.addHistoryExp
local dateScenes = deps.dateScenes
local banquetThemes = deps.banquetThemes
local readBook = deps.readBook
local handlers = deps.handlers

handlers["晚宴"] = function(S)
    local themeKeys = {"masquerade", "revelry", "flower", "hunt"}
    local themeKey = themeKeys[math.random(1, #themeKeys)]
    local theme = banquetThemes[themeKey]

    local text = theme.name .. "\n\n" .. theme.desc .. "\n\n"
        .. "罗斯巴特少爷站在门口迎接客人，今晚他换了一身深色礼服，红发梳得一丝不苟。"
        .. "他看见你，微微挑眉：「哦？你也来了。」\n"
        .. "「想见识见识。」你说。\n"
        .. "他上下打量你：「这身可不行。去换件合适的。」\n\n"
        .. "他让侍从带你去更衣室，那里挂满了各式礼服。你该选哪一套？"

    local choices = {}
    for _, outfit in ipairs(theme.outfits) do
        table.insert(choices, {
            text = outfit.name,
            action = function()
                S.chosenOutfitKey = outfit.key
                S.banquetThemeKey = themeKey
                if outfit.matchBonus then
                    S.tip = (S.tip or 0) + outfit.matchBonus
                elseif outfit.failBonus then
                    S.tip = (S.tip or 0) + outfit.failBonus
                end
                -- 执行事件
                local evt = theme.events[1]
                if evt then
                    S.tip = (S.tip or 0) + (evt.tip or 0)
                    if evt.oamel then addOamelAffection(evt.oamel) end
                end
                return "晚宴结束"
            end,
        })
    end

    return { text = text, choices = choices }
end

---===================== 晚宴结束 =====================
--- Twine pid 31


handlers["晚宴结束"] = function(S)
    local text = "夜深了，客人们渐渐散去。你帮侍从收拾杯盘时，罗斯巴特少爷靠在门边看你。"

    if (S.oamelAffection or 0) < 50 then
        text = text .. "\n\n「干得还行。」他扔给你一袋金币，「下次穿对衣服，别浪费我的时间。」说完转身离开，红发在月光下闪了闪。"
    elseif (S.oamelAffection or 0) < 100 then
        text = text .. "\n\n「今天表现不错。」他走近几步，声音低了些，「其实你穿那身挺好看。」说完自己先别过脸，「别多想，只是实话。」\n你笑了。他瞪你一眼：「笑什么，快回去！」"
    else
        text = text .. "\n\n「没想到你还有这本事。」他靠在你旁边的墙上，难得露出疲惫的神色，"
            .. "「今天多亏你。」他犹豫了一下，把一枚金色的徽章塞给你，「拿着，以后二楼可以自由进出。」\n"
            .. "你接过徽章，上面刻着罗斯巴特家族的纹章。他低声说：「别弄丢了。」"
        S.unlockLounge = true
    end

    local tip = S.tip or 0
    text = text .. "\n\n你赚了" .. tip .. "金币，并获得了一些罗斯巴特少爷的好感。"
    S.money = (S.money or 0) + tip
    S.banquetAttendedThisWeek = true
    TimeSystem.addMinutes(180)
    S.banquetTheme = 0
    S.banquetStage = ""
    S.tip = 0

    return {
        text = text,
        choices = {
            { text = "🔙 离开", target = "妖精的邀请" },
        },
    }
end

---===================== 收养小猫 =====================
--- Twine pid 35: 忠实原文


handlers["收养小猫"] = function(S)
    local text = "K走过来，看着你和小猫：「喜欢它？」她蹲下来，小猫立刻蹭过去。「这小家伙每天来蹭饭，也没人养。」"
    if (S.kLevel or 1) >= 3 then
        text = text .. "\n\n她抬头看你：「要不你带回家吧。我帮你照顾它？」"
    else
        text = text .. "\n\n「要不...你收养它？」K试探着问，「我会帮你照顾的。」"
    end

    return {
        text = text,
        choices = {
            { text = "收养它", action = function()
                S.catAdopted = true
                return "收养小猫_命名"
            end },
            { text = "算了", target = "商业区" },
        },
    }
end

---===================== 收养小猫_命名 =====================


handlers["收养小猫_命名"] = function(S)
    return {
        text = "「好。」你抱起小猫，它安静地窝在你怀里。K眼睛亮亮的：「给它取个名字吧。」",
        inputField = true,
        inputTarget = "catName",
        choices = {
            { text = "确定", action = function()
                addDateLog("小猫", "收养", "收养了小猫「" .. (S.catName or "小猫") .. "」。")
                TimeSystem.addMinutes(10)
                return "商业区"
            end },
        },
    }
end

---===================== 小猫互动 =====================


handlers["小猫互动"] = function(S)
    local choices = {}
    if not S.catFedToday then
        table.insert(choices, { text = "🍖 喂食", action = function()
            S.catAffection = (S.catAffection or 0) + 10
            S.catFedToday = true
            TimeSystem.addMinutes(5)
            if (S.catAffection or 0) >= 20 and not S.catAdopted then
                return "收养小猫"
            end
            return "商业区"
        end })
    end
    if not S.catPettedToday then
        table.insert(choices, { text = "🤚 抚摸", action = function()
            S.catAffection = (S.catAffection or 0) + 5
            S.catPettedToday = true
            TimeSystem.addMinutes(5)
            if (S.catAffection or 0) >= 20 and not S.catAdopted then
                return "收养小猫"
            end
            return "商业区"
        end })
    end
    table.insert(choices, { text = "💬 和小猫说话", action = function()
        S.catAffection = (S.catAffection or 0) + 2
        TimeSystem.addMinutes(5)
        if (S.catAffection or 0) >= 20 and not S.catAdopted then
            return "收养小猫"
        end
        return "商业区"
    end })
    table.insert(choices, { text = "返回", target = "商业区" })

    return {
        text = "小猫眯着眼睛看着你，尾巴轻轻摇摆。",
        choices = choices,
    }
end

---===================== 约会选择 =====================


end
