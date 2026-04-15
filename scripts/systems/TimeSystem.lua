-- ============================================================================
-- TimeSystem.lua - 时间推进与日期变更
-- ============================================================================

local GameState = require("systems.GameState")

local TimeSystem = {}

--- 推进分钟
---@param minutes number
function TimeSystem.addMinutes(minutes)
    local S = GameState.state
    local oldHour = S.hour
    S.minute = S.minute + minutes

    while S.minute >= 60 do
        S.minute = S.minute - 60
        S.hour = S.hour + 1
        TimeSystem.onHourTick()
    end

    while S.hour >= 24 do
        S.hour = S.hour - 24
        S.day = S.day + 1
        TimeSystem.onDayChange()
    end
end

--- 每小时生存属性消耗
function TimeSystem.onHourTick()
    local S = GameState.state

    -- 饱食度自然衰减 (~2/小时)
    GameState.modStat("satiety", -2)

    -- 疲劳自然增长 (~1/小时，深夜加速)
    local fatigueGain = 1
    if S.hour >= 23 or S.hour < 5 then
        fatigueGain = 2  -- 熬夜更容易累
    end
    GameState.modStat("fatigue", fatigueGain)

    -- 清洁度自然衰减 (~1/小时，打工/运动后更快，由具体系统额外扣除)
    GameState.modStat("cleanliness", -1)

    -- 压力：饥饿或疲劳时增长
    local stressGain = 0
    if S.satiety <= 20 then
        stressGain = stressGain + 1  -- 很饿时压力增加
    end
    if S.fatigue >= 70 then
        stressGain = stressGain + 1  -- 很累时压力增加
    end
    if (S.cleanliness or 90) <= 20 then
        stressGain = stressGain + 1  -- 很脏时压力增加
    end
    GameState.modStat("stress", stressGain)

    -- 极端状态警告
    if S.satiety <= 10 and S.satiety > 0 then
        GameState.showNotification("你饿得头晕眼花……赶紧吃点东西吧。")
    end
    if S.fatigue >= 90 then
        GameState.showNotification("你已经困得站不稳了……该休息了。")
    end
    if (S.cleanliness or 90) <= 15 and (S.cleanliness or 90) > 0 then
        GameState.showNotification("你浑身黏糊糊的……该洗个澡了。")
    end

    -- 社区大学：课程提醒
    local okUni, UniSystem = pcall(require, "systems.UniversitySystem")
    if okUni and UniSystem.checkClassReminder then
        UniSystem.checkClassReminder()
    end
end

--- 日期变更处理
function TimeSystem.onDayChange()
    local S = GameState.state

    -- 每周重置（7天一周）
    if S.day >= 8 then
        S.day = 1
        S.rentWeek = S.rentWeek + 1
        TimeSystem.onWeekChange()
    end

    -- 每日重置
    S.catFedToday = false
    S.catPettedToday = false
    S.kDateAvailable = true
    S.leiDeDateAvailable = true
    S.townEventSeen = {}
    S.townEventCount = 0
    S.dailyBuffs = { phys = 0, magic = 0, def = 0 }
    S.felixBreadToday = false
    S.sparringToday = false
    S.townBattleToday = 0

    -- K随机来访逻辑已移至 HomeSystem.onDayChange()

    -- 种植系统：作物每日生长
    local okFarm, FarmingSystem = pcall(require, "systems.FarmingSystem")
    if okFarm and FarmingSystem.onDayChange then
        FarmingSystem.onDayChange()
    end

    -- 社区大学：每日重置上课次数
    local okUni, UniSystem = pcall(require, "systems.UniversitySystem")
    if okUni and UniSystem.onDayChange then
        UniSystem.onDayChange()
    end

    -- 家庭系统：每日来访判定与事件重置
    local okHome, HomeSystem = pcall(require, "systems.HomeSystem")
    if okHome and HomeSystem.onDayChange then
        HomeSystem.onDayChange()
    end

    -- 关键词聊天：每日重置已聊话题
    local okKw, KeywordSystem = pcall(require, "systems.KeywordSystem")
    if okKw and KeywordSystem.onDayChange then
        KeywordSystem.onDayChange()
    end

    -- 小摊：每日重置收入
    S.stallRevenue = 0

    -- 疲劳：睡觉后重置（睡眠在别处处理，这里处理自然恢复）
    -- 如果连续一天未睡觉，疲劳不会自然恢复
end

--- 周变更处理
function TimeSystem.onWeekChange()
    local S = GameState.state

    -- 先检查上周是否欠租（必须在重置 rentPaidThisWeek 之前判断）
    if not S.rentPaidThisWeek and S.rentWeek > 1 then
        S.oweRent = S.oweRent + S.rentDue
        if S.oweRent >= S.rentDue * 2 then
            S.evicted = true
            GameState.showNotification("你因为欠租太多被赶出了家门！")
            GameState.addDateLog("房东", "驱逐", "因欠租 " .. S.oweRent .. " 金币被赶出家门。")
        end
    end

    -- 重置本周状态（放在欠租检查之后）
    S.rentPaidThisWeek = false
    S.rentWarningShown = false
    S.rentDueDate = 0
    if S.rentWeek >= 2 then
        S.rentDue = 500
    end
    S.etiquetteTrainedThisWeek = false
    S.banquetAttendedThisWeek = false
    S.oamelLoanUsed = false
end

--- 判断莱德是否在家
function TimeSystem.isLeiDeHome()
    local S = GameState.state
    if not S.initialNameAtHome then return false end
    local hour = S.hour
    return (hour >= 19 or hour < 6) or (hour >= 11 and hour < 13)
end

--- 获取莱德状态描述
function TimeSystem.getLeiDeStatusDesc()
    local S = GameState.state
    local hour = S.hour
    local name = S.initialName

    if hour >= 22 or hour < 6 then
        if S.initialNameSleepTogether then
            return name .. " 已经睡着了。他侧躺着，黑发散在枕上，呼吸平稳。月光从窗帘缝隙透进来，勾勒出他安静的轮廓。"
        else
            return name .. " 已经躺在沙发上睡着了。他蜷缩着，呼吸均匀，睡得很沉。"
        end
    end

    if hour >= 21 and hour < 22 then
        local light = S.candles > 0 and "蜡烛的光" or "窗外的月光"
        local pos = S.initialNameSleepTogether and "床头" or "沙发上"
        return name .. " 靠在" .. pos .. "，借着" .. light .. "翻阅一本厚重的魔法书。他看得专注，连你进来都没察觉。"
    end

    return name .. " 坐在桌边，面前摊着厚厚的魔法书籍和论文草稿。他眉头微蹙，笔尖在纸上沙沙作响，偶尔停下来沉思。"
end

--- 获取时段描述
function TimeSystem.getTimeOfDayDesc()
    local S = GameState.state
    local h = S.hour
    if h >= 5 and h < 8 then return "清晨"
    elseif h >= 8 and h < 12 then return "上午"
    elseif h >= 12 and h < 14 then return "中午"
    elseif h >= 14 and h < 17 then return "下午"
    elseif h >= 17 and h < 19 then return "傍晚"
    elseif h >= 19 and h < 22 then return "晚上"
    else return "深夜"
    end
end

return TimeSystem
