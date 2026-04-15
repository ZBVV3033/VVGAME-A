-- passages/location/Crossroads.lua
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

handlers["十字路口"] = function(S)
    local name = S.initialName or "莱德"
    local h = S.hour or 8

    -- ── 构建场景描述文字 ──
    local timeDesc
    if h >= 6 and h < 12 then
        timeDesc = "晨光洒在鹅卵石路面上，商贩们正掀开布篷、摆放货品，马蹄声和车轮声在巷口回荡。"
    elseif h >= 12 and h < 18 then
        timeDesc = "午后的阳光有些慵懒，行人穿梭在石板路上，空气中飘着咖啡和烤饼的香气。"
    elseif h >= 18 and h < 22 then
        timeDesc = "暮色渐浓，街灯一盏接一盏亮起来，酒馆里传来模糊的笑声和碰杯声。"
    else
        timeDesc = "夜深了，街上行人稀疏，远处偶尔传来守夜人的打更声和野猫的叫唤。"
    end
    local text = "十字路口\n\n"
        .. "四条主路在这里交汇，形成艾瑟顿镇最繁忙的枢纽。"
        .. timeDesc .. "\n"
        .. "密密麻麻的商铺角落有一条小径，通往你的家。"

    -- 莱德场景描述（融入正文，根据时段变化）
    local meetLocation = ""
    local meetAction = ""
    local meetDesc = ""

    if not S.initialNameAtHome then
        if h >= 6 and h < 12 then
            meetLocation = "港口"
            meetAction = "搬货"
            meetDesc = "你走到港口，看见 " .. name .. " 正和几个工人一起扛着木箱。他动作利落，额头上沁着汗珠，却始终面无表情。"
            text = text .. "\n\n远处的港口方向传来嘈杂声，" .. name .. " 应该在那边搬货。"
        elseif h >= 12 and h < 13 then
            meetLocation = "十字路口"
            meetAction = "休息"
            meetDesc = "你路过街角的咖啡店，看见 " .. name .. " 坐在窗边，面前放着一杯冒着热气的咖啡。他盯着杯子，似乎在研究什么，神情专注。"
            text = text .. "\n\n街角的咖啡店窗边，" .. name .. " 正独自坐着，面前冒着热气。"
        elseif h >= 13 and h < 18 then
            meetLocation = "十字路口"
            meetAction = "跑腿"
            meetDesc = "你看见 " .. name .. " 正帮一个商人拎着包裹，快步穿过人群。他朝你点点头，脚步没停。"
            text = text .. "\n\n人群中，" .. name .. " 正帮一个商人拎着包裹快步走过，他似乎注意到了你。"
        elseif h >= 22 or h < 6 then
            meetLocation = "帐篷"
            meetAction = "睡觉"
            meetDesc = "夜深了，你走到十字路口角落的草地，看见 " .. name .. " 的帐篷里透出微弱的光，他已经睡着了。"
            text = text .. "\n\n夜色中，十字路口角落的帐篷透出一点微弱的光——" .. name .. " 似乎已经睡下了。"
        else
            meetLocation = "十字路口"
            meetAction = "锻炼"
            meetDesc = "天色已晚，你走到十字路口角落的那片草地，看见 " .. name .. " 正在帐篷边练剑。剑光在月光下闪动，动作精准而沉默。"
            text = text .. "\n\n暮色中，" .. name .. " 正在角落的草地上练剑，剑光在月光下闪动。"
        end
    end

    local choices = {}

    -- ══════ 地点导航（置顶） ══════
    table.insert(choices, {
        text = "🏠 回家",
        target = "家",
    })
    table.insert(choices, {
        text = "🍜 进入商业区",
        action = function()
            S.currentArea = "square"
            TimeSystem.addMinutes(1)
            return "商业区"
        end,
    })
    table.insert(choices, {
        text = "⛲ 往北走（花园小镇，5分钟）",
        action = function()
            TimeSystem.addMinutes(5)
            return "花园小镇"
        end,
    })
    table.insert(choices, {
        text = "🚢 往北走（港口，5分钟）",
        action = function()
            TimeSystem.addMinutes(5)
            return "港口"
        end,
    })
    table.insert(choices, {
        text = "🌲 进入渡劫森林（10分钟）",
        action = function()
            TimeSystem.addMinutes(10)
            return "渡劫森林"
        end,
    })

    table.insert(choices, {
        text = "🎓 去社区大学（5分钟）",
        action = function()
            TimeSystem.addMinutes(5)
            return "大学校门"
        end,
    })

    -- ══════ 事件互动（由文字引出） ══════
    if not S.initialNameAtHome then
        -- 莱德互动（文字已在上方描述，这里提供互动入口）
        if h >= 22 or h < 6 then
            -- 深夜：他睡着了
            if (S.initialNameLevel or 1) >= 2 and not S.initialNameInvited then
                table.insert(choices, {
                    text = "⏰ 走过去叫醒" .. name,
                    action = function()
                        if (S.initialNameLevel or 1) < 3 then
                            GameState.showNotification("你走近" .. (S.initialName or "莱德") .. "，但他睡得很沉。你不忍心叫醒他，轻轻退开了。\n(好感度不够，无法叫醒他)")
                            return "十字路口"
                        else
                            S.hour = 6
                            TimeSystem.addMinutes(0)
                            addAffection("initialName", 3)
                            GameState.showNotification((S.initialName or "莱德") .. "揉了揉眼睛：「……天亮了？」他看见你，表情柔和下来。(好感+3)")
                            return "十字路口"
                        end
                    end,
                })
            end
        else
            -- 白天/傍晚：可以上前打招呼
            table.insert(choices, {
                text = "💬 走过去找" .. name,
                action = function()
                    TimeSystem.addMinutes(1)
                    S.meetLocationVar = meetLocation
                    S.meetActionVar = meetAction
                    S.meetDesc = meetDesc
                    return "偶遇与改名"
                end,
            })
            -- 邀请打工（条件：等级>=2, 未邀请, 白天）
            if (S.initialNameLevel or 1) >= 2 and not S.initialNameInvited
               and (h >= 6 and h < 18) then
                table.insert(choices, {
                    text = "🤝 邀请" .. name .. "一起去打工 ⏱30分钟",
                    action = function()
                        TimeSystem.addMinutes(30)
                        addAffection("initialName", 10)
                        S.initialNameCoworked = true
                        GameState.showNotification("你邀请" .. (S.initialName or "莱德") .. "一起去打工。他犹豫了一下，最终还是跟上了你的步伐。\n「……走吧。」他的语气虽然淡淡的，但步子迈得很坚定。(好感+10)")
                        return "十字路口"
                    end,
                })
            end
        end
    else
        -- 莱德在家，没有互动选项
    end

    -- ══ 主线任务触发（插入到最前面） ══
    local mqTrigger = MainQuest.getTriggerChoice("十字路口")
        or MainQuest.getCh2TriggerChoice("十字路口")
        or MainQuest.getCh3TriggerChoice("十字路口")
    if mqTrigger then
        table.insert(choices, 1, mqTrigger)
    end

    return { text = text, choices = choices }
end

---===================== 家 =====================
--- 委托给 HomeSystem 处理（包括家主页、莱德/K/奥梅尔互动、乌列尔信件）


handlers["家"] = function(S)
    if HomeSystem and HomeSystem.getPassage then
        local p = HomeSystem.getPassage(passageName)
        if p then return p end
    end
    -- fallback
    return {
        text = "家\n\n你回到了家中。",
        choices = { { text = "返回十字路口", target = "十字路口" } },
    }
end

---===================== 商业区 =====================
--- Twine pid 22: 使用 $currentArea 状态机


end
