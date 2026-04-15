-- passages/system/InventoryLog.lua
-- Auto-split sub-module

return function(handlers, deps)

local GameState = deps.GameState
local TimeSystem = deps.TimeSystem
local WorkSystem = deps.WorkSystem
local HomeSystem = deps.HomeSystem
local BattleSystem = deps.BattleSystem
local ChangelogData = deps.ChangelogData
local SaveSystem = deps.SaveSystem
local MainQuest = deps.MainQuest
local MainQuestCh2 = deps.MainQuestCh2
local MainQuestCh3 = deps.MainQuestCh3
local CookingSystem = deps.CookingSystem
local FarmingSystem = deps.FarmingSystem
local UniSystem = deps.UniSystem
local TownLife = deps.TownLife
local RandomEvents = deps.RandomEvents
local KeywordSystem = deps.KeywordSystem
local SideQuests = deps.SideQuests
local CommonUtils = deps.CommonUtils
local PassageDeps = deps.PassageDeps
local addAffection = deps.addAffection
local addDateLog = deps.addDateLog
local addOamelAffection = deps.addOamelAffection
local addMeifeiAffection = deps.addMeifeiAffection
local topicDialogues = deps.topicDialogues
local handlers = deps.handlers

handlers["背包"] = function(S)
    local text = "背包\n\n"

    -- 合并同名物品计数
    local inventory = S.inventory or {}
    local merged = {}
    local order = {}
    for _, item in ipairs(inventory) do
        local name = type(item) == "string" and item or (item.name or "???")
        if not merged[name] then
            merged[name] = 0
            table.insert(order, name)
        end
        merged[name] = merged[name] + (type(item) == "table" and (item.count or 1) or 1)
    end

    -- 森林采集物品
    local forageItems = S.forageItems or {}
    for itemName, count in pairs(forageItems) do
        if count > 0 then
            if not merged[itemName] then
                table.insert(order, itemName)
                merged[itemName] = 0
            end
            merged[itemName] = merged[itemName] + count
        end
    end

    if #order == 0 then
        text = text .. "背包空空如也。\n\n去探索一下世界吧，也许能找到些有用的东西。"
    else
        text = text .. "────────────────\n"
        for _, name in ipairs(order) do
            text = text .. "  " .. name .. "  x" .. merged[name] .. "\n"
        end
        text = text .. "────────────────\n"
        text = text .. "\n共 " .. #order .. " 种物品"
    end

    local returnTarget = S._settingsFrom or "家"

    return {
        text = text,
        choices = {
            { text = "返回", action = function() return returnTarget end },
        },
    }
end

---===================== 日志 =====================
--- Twine pid 17


handlers["日志"] = function(S)
    -- ===== 任务面板（最顶部） =====
    local chapterNames = { [0] = "序章", "第一章 营救行动", "第一章 营救行动", "第一章 营救行动", "第一章 营救行动", "第一章 营救行动",
        "第二章 阶级裂痕", "第二章 阶级裂痕", "第二章 阶级裂痕", "第二章 阶级裂痕", "第二章 阶级裂痕", "第二章 阶级裂痕", "第二章 阶级裂痕",
        "第三章 真相之光", "第三章 真相之光", "第三章 真相之光", "第三章 真相之光", "第三章 真相之光", "第三章 真相之光", "第三章 真相之光", "终章" }
    local curStage = S.mqStage or 0
    local chapterName = chapterNames[curStage] or "未知"

    local text = "════════ 任务面板 ════════\n\n"
    text = text .. chapterName .. "\n"
    text = text .. "  " .. MainQuest.getQuestHint() .. "\n\n"

    local sideHints = MainQuest.getSideQuestHints()
    if #sideHints > 0 then
        text = text .. "支线任务\n"
        for _, hint in ipairs(sideHints) do
            text = text .. "  " .. hint .. "\n"
        end
        text = text .. "\n"
    end

    -- ===== 引导任务 =====
    if not S.firstJobBonusClaimed then
        text = text .. "引导任务\n"
        text = text .. "  金钱是立身之本\n"
        text = text .. "  你可以试试在十字路口的酒馆、教堂、铁匠铺、港口转转，\n"
        text = text .. "  和那里的人交谈获得打工机会，完成第一次打工吧。\n"
        text = text .. "  奖励：100 金币（政府就业补贴金）\n\n"
    else
        text = text .. "引导任务\n"
        text = text .. "  金钱是立身之本 —— 已完成\n\n"
    end

    -- ===== 原有日志内容 =====
    text = text .. "── 回忆录 ──\n\n"

    if S.evicted then
        text = text .. "无家可归\n你被赶出了家门，欠款 " .. (S.oweRent or 0) .. " 金币。凑齐后去找房东交钱，才能回家。\n\n"
    elseif not S.rentPaidThisWeek then
        local daysLeft = 7 - (S.day or 1)
        if (S.rentDueDate or 0) > 0 then
            text = text .. "房租逾期（第 " .. S.rentDueDate .. " 天）\n请立即支付 " .. (S.rentDue or 100) .. " 金币，否则将被赶出！\n\n"
        elseif daysLeft <= 2 then
            text = text .. "房租即将到期！\n本周房租 " .. (S.rentDue or 100) .. " 金币，还剩 " .. daysLeft .. " 天。请尽快支付！\n\n"
        else
            text = text .. "房租提醒\n本周房租 " .. (S.rentDue or 100) .. " 金币，还剩 " .. daysLeft .. " 天到期。\n\n"
        end
    else
        -- 已付房租，显示安心提示
        local daysLeft = 7 - (S.day or 1)
        text = text .. "房租已付清（本周 " .. (S.rentDue or 100) .. " 金币）。距下周还有 " .. daysLeft .. " 天。\n\n"
    end

    if S.oamelLoanUsed then
        text = text .. "本周已向奥梅尔·罗斯巴特借过钱。下周一可再次开口。\n\n"
    end

    -- 本周课表（已报名课程）
    local uniOk, UniSys = pcall(require, "systems.UniversitySystem")
    if uniOk and S.uniEnrolled and #(S.uniMajors or {}) > 0 then
        local dayNames = { "周一", "周二", "周三", "周四", "周五", "周六", "周日" }
        local currentDay = ((S.day - 1) % 7) + 1

        -- 收集已报名专业的课程，按星期分组
        local daySlots = {}
        for _, majorId in ipairs(S.uniMajors) do
            local schedule = UniSys.SCHEDULE[majorId]
            local majorInfo = UniSys.getMajorInfo and UniSys.getMajorInfo(majorId)
            if schedule and majorInfo then
                for _, cls in ipairs(schedule) do
                    if not daySlots[cls.day] then daySlots[cls.day] = {} end
                    table.insert(daySlots[cls.day], {
                        hour = cls.hour, minute = cls.minute,
                        icon = majorInfo.icon, clsName = cls.name, location = cls.location,
                    })
                end
            end
        end

        text = text .. "━━━ 本周课表 ━━━\n\n"
        local hasAny = false
        for day = 1, 7 do
            local slots = daySlots[day]
            if slots then
                hasAny = true
                table.sort(slots, function(a, b)
                    return a.hour * 60 + a.minute < b.hour * 60 + b.minute
                end)
                local marker = (day == currentDay) and " 今天" or ""
                text = text .. dayNames[day] .. marker .. "\n"
                for _, s in ipairs(slots) do
                    local timeStr = string.format("%02d:%02d", s.hour, s.minute)
                    text = text .. "  " .. timeStr .. " " .. s.icon .. " " .. s.clsName .. " @" .. s.location .. "\n"
                end
            end
        end
        if not hasAny then
            text = text .. "暂无课程安排。\n"
        end
        text = text .. "\n"
    end

    -- 最近动态（最近5条事件）
    local recentEvents = S.recentEvents or {}
    if #recentEvents > 0 then
        text = text .. "━━━ 最近动态 ━━━\n\n"
        for i = #recentEvents, 1, -1 do
            local ev = recentEvents[i]
            text = text .. (ev.date or "") .. " " .. (ev.time or "") .. "  " .. (ev.text or "") .. "\n"
        end
        text = text .. "\n"
    end

    text = text .. "━━━ 回忆录 ━━━\n\n"
    text = text .. "你和重要的人们一起度过的时光。\n\n"

    local logs = S.dateLogs or {}
    if #logs == 0 then
        text = text .. "还没有记录。一起去创造回忆吧。"
    else
        for i = #logs, 1, -1 do
            local entry = logs[i]
            text = text .. (entry.date or "") .. " - " .. (entry.person or "") .. " · " .. (entry.type or "") .. "\n"
                .. (entry.content or "") .. "\n\n"
        end
    end

    local from = S._settingsFrom or S.currentPassage or "家"
    return {
        text = text,
        choices = {
            { text = "返回", target = from },
        },
    }
end

---===================== 测试面板 =====================
--- Twine pid 18


end
