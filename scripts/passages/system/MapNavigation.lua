-- passages/system/MapNavigation.lua
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

handlers["区域地图"] = function(S)
    local cp = S.currentPassage or "十字路口"
    local from = S._settingsFrom or cp

    -- 支持从世界地图指定查看某个区域
    local viewArea = S._viewMapArea
    S._viewMapArea = nil
    local isViewingOther = (viewArea ~= nil)  -- 是否在查看非当前位置的区域

    -- 根据当前所在位置判断区域
    local areaName, areaDesc, areaPlaces

    -- 判断当前所在的大区域（或指定查看的区域）
    local function inArea(names)
        if viewArea then
            for _, n in ipairs(names) do
                if viewArea == n then return true end
            end
            return false
        end
        for _, n in ipairs(names) do
            if from == n or cp == n then return true end
        end
        return false
    end

    if inArea({"家"}) then
        areaName = "家"
        areaDesc = "你的小屋，位于十字路口角落的那条小径尽头。虽然简陋，但至少是个遮风挡雨的地方。"
        areaPlaces = {
            { name = "家", icon = "🏠", desc = "你的住所", passage = "家", here = (from == "家") },
            { name = "十字路口", icon = "🔀", desc = "走出家门（约1分钟）", passage = "十字路口", time = 1 },
        }
    elseif inArea({"商业区"}) then
        areaName = "商业区"
        areaDesc = "热闹的商业中心，外围是小吃街，里面有各种商店、酒馆、教堂和铁匠铺。"
        areaPlaces = {
            { name = "广场", icon = "🏪", desc = "商业区中心", passage = "商业区", here = true },
            { name = "十字路口", icon = "🔀", desc = "往南走回十字路口（约1分钟）", passage = "十字路口", time = 1 },
        }
    elseif inArea({"港口"}) then
        areaName = "港口"
        areaDesc = "码头边堆着木箱，工人们搬运货物。渔贩的摊位一字排开，海风带着咸腥气。"
        areaPlaces = {
            { name = "港口码头", icon = "🚢", desc = "你现在在这里", passage = "港口", here = true },
            { name = "十字路口", icon = "🔀", desc = "往南走（约5分钟）", passage = "十字路口", time = 5 },
        }
    elseif inArea({"花园小镇", "花园小镇_小巷"}) then
        areaName = "花园小镇"
        areaDesc = "破败的村庄，土路坑洼，木屋歪斜。虽然简陋，但生活气息浓厚。"
        areaPlaces = {
            { name = "花园小镇", icon = "🏘️", desc = "村庄中心", passage = "花园小镇", here = true },
            { name = "主城区", icon = "🏛️", desc = "往北走（约5分钟）", passage = "主城区", time = 5 },
            { name = "十字路口", icon = "🔀", desc = "往南走（约5分钟）", passage = "十字路口", time = 5 },
        }
    elseif inArea({"主城区", "白鸦书屋", "贵族休息室", "贵族休息室_书柜"}) then
        areaName = "主城区"
        areaDesc = "宽阔的石板路，整齐的商铺和住宅。空气中飘着烤面包和咖啡香气。"
        areaPlaces = {
            { name = "城区大街", icon = "🏛️", desc = "城区中心", passage = "主城区", here = (from == "主城区") },
            { name = "白鸦书屋", icon = "📖", desc = "安静的书店", passage = "白鸦书屋", here = (from == "白鸦书屋") },
            { name = "花街", icon = "🌹", desc = "往东走（约5分钟）", passage = "花街", time = 5 },
            { name = "花园小镇", icon = "🏘️", desc = "往南走（约5分钟）", passage = "花园小镇", time = 5 },
        }
    elseif inArea({"花街", "妖精的邀请"}) then
        areaName = "花街"
        areaDesc = "喧闹的街道，空气中飘着浓烈的胭脂水粉味。灯火通明，华丽的马车来来往往。"
        areaPlaces = {
            { name = "花街", icon = "🌹", desc = "街道上", passage = "花街", here = (from == "花街") },
            { name = "妖精的邀请", icon = "🎭", desc = "最大的那栋建筑", passage = "妖精的邀请", here = (from == "妖精的邀请") },
            { name = "主城区", icon = "🏛️", desc = "往西走（约5分钟）", passage = "主城区", time = 5 },
        }
    elseif inArea({"渡劫森林"}) or (from and from:sub(1, 4) == "森林") then
        areaName = "渡劫森林"
        areaDesc = "深邃的森林，林间小径蜿蜒曲折。木牌上写着：「深处危险，入者自负。」"
        areaPlaces = {
            { name = "森林入口", icon = "🌲", desc = "你现在在这里", passage = "渡劫森林", here = true },
            { name = "十字路口", icon = "🔀", desc = "走出森林（约10分钟）", passage = "十字路口", time = 10 },
        }
    elseif inArea({"大学校门"}) or (from and from:sub(1, 4) == "大学_") or (cp and cp:sub(1, 4) == "大学_") then
        areaName = "社区大学"
        areaDesc = "艾瑟顿社区大学，门口挂着「知识改变命运」的校训牌匾。"
        areaPlaces = {
            { name = "校门", icon = "🎓", desc = "大学入口", passage = "大学校门", here = true },
            { name = "十字路口", icon = "🔀", desc = "离开大学（约5分钟）", passage = "十字路口", time = 5 },
        }
    else
        -- 默认：十字路口区域
        areaName = "十字路口"
        areaDesc = "艾瑟顿镇最热闹的一片街区，无论昼夜都有行人在这里奔走。"
        areaPlaces = {
            { name = "十字路口", icon = "🔀", desc = "你现在在这里", passage = "十字路口", here = true },
            { name = "家", icon = "🏠", desc = "沿小径回家（约1分钟）", passage = "家", time = 1 },
            { name = "商业区", icon = "🍜", desc = "进入商业区（约1分钟）", passage = "商业区", time = 1 },
            { name = "港口", icon = "🚢", desc = "往北走（约5分钟）", passage = "港口", time = 5 },
            { name = "花园小镇", icon = "⛲", desc = "往北走（约5分钟）", passage = "花园小镇", time = 5 },
            { name = "渡劫森林", icon = "🌲", desc = "进入森林（约10分钟）", passage = "渡劫森林", time = 10 },
            { name = "社区大学", icon = "🎓", desc = "去大学（约5分钟）", passage = "大学校门", time = 5 },
        }
    end

    -- 查看其他区域时不显示"你在这里"标记
    if isViewingOther then
        for _, p in ipairs(areaPlaces) do
            p.here = false
        end
    end

    -- 构建文字
    local text
    if isViewingOther then
        text = "区域地图 —— " .. areaName .. "（浏览中）\n\n" .. areaDesc .. "\n\n"
        text = text .. "── 该区域的地点 ──\n\n"
    else
        text = "区域地图 —— " .. areaName .. "\n\n" .. areaDesc .. "\n\n"
        text = text .. "── 当前区域可到达的地点 ──\n\n"
    end
    for _, p in ipairs(areaPlaces) do
        if p.here then
            text = text .. p.icon .. " " .. p.name .. "  ◀ 你在这里\n"
        else
            text = text .. p.icon .. " " .. p.name .. " — " .. p.desc .. "\n"
        end
    end

    local choices = {}
    -- 只有当前位置区域才显示前往按钮
    if not isViewingOther then
        for _, p in ipairs(areaPlaces) do
            if not p.here then
                table.insert(choices, {
                    text = p.icon .. " 前往" .. p.name,
                    action = function()
                        if p.time then
                            TimeSystem.addMinutes(p.time)
                        end
                        return p.passage
                    end,
                })
            end
        end
    end

    -- 查看世界地图
    table.insert(choices, {
        text = "查看世界地图",
        action = function()
            return "世界地图"
        end,
    })

    -- 返回
    table.insert(choices, {
        text = "收起地图",
        target = from,
    })

    return { text = text, choices = choices }
end

---===================== 世界地图 =====================


handlers["世界地图"] = function(S)
    local from = S._settingsFrom or S.currentPassage or "十字路口"

    -- 判断当前大致区域（用于标记"你在这里"）
    local function isHere(names)
        for _, n in ipairs(names) do
            if from == n then return true end
        end
        -- 检查前缀
        for _, n in ipairs(names) do
            if from:sub(1, #n) == n then return true end
        end
        return false
    end

    local currentMark = " ◀ 你在这里"

    local text = "世界地图 —— 艾瑟顿镇\n\n"

    -- 区域列表（紧凑展示）
    local regions = {
        { name = "十字路口", icon = "🔀",
          check = {"十字路口"} },
        { name = "家", icon = "🏠",
          check = {"家"} },
        { name = "商业区", icon = "🍜",
          check = {"商业区"} },
        { name = "港口", icon = "🚢",
          check = {"港口"} },
        { name = "花园小镇", icon = "⛲",
          check = {"花园小镇", "花园小镇_小巷"} },
        { name = "主城区", icon = "🏛️",
          check = {"主城区", "白鸦书屋", "贵族休息室"} },
        { name = "花街", icon = "🌹",
          check = {"花街", "妖精的邀请"} },
        { name = "渡劫森林", icon = "🌲",
          check = {"渡劫森林", "森林事件", "森林商人"} },
        { name = "社区大学", icon = "🎓",
          check = {"大学校门", "大学_"} },
    }

    for _, r in ipairs(regions) do
        local mark = isHere(r.check) and currentMark or ""
        text = text .. r.icon .. " " .. r.name .. mark .. "\n"
    end

    text = text .. "\n各区域步行约 1~10 分钟。"

    -- 选项
    local choices = {}

    -- 回家引导（非直接传送，计算路途时间）
    if not isHere({"家"}) then
        local totalTime = 2 -- 默认
        if isHere({"十字路口"}) then totalTime = 1
        elseif isHere({"商业区"}) then totalTime = 2
        elseif isHere({"港口"}) then totalTime = 6
        elseif isHere({"花园小镇", "花园小镇_小巷"}) then totalTime = 6
        elseif isHere({"主城区", "白鸦书屋", "贵族休息室"}) then totalTime = 11
        elseif isHere({"花街", "妖精的邀请"}) then totalTime = 16
        elseif isHere({"渡劫森林", "森林事件", "森林商人"}) then totalTime = 11
        elseif isHere({"大学校门", "大学_"}) then totalTime = 6
        end

        table.insert(choices, {
            text = "🏠 启程回家（约" .. totalTime .. "分钟路程）",
            action = function()
                TimeSystem.addMinutes(totalTime)
                GameState.modStat("fatigue", math.floor(totalTime / 3))
                GameState.showNotification("你沿着熟悉的路走回家，一路上偶尔遇到几个行人。到家时天色"
                    .. (((S.hour or 8) >= 18 or (S.hour or 8) < 6) and "已暗" or "还亮着") .. "。\n(用时" .. totalTime .. "分钟，疲劳+" .. math.floor(totalTime / 3) .. ")")
                return "家"
            end,
        })
    end

    -- 各区域：查看地图 + 快速前往
    local navTargets = {
        { name = "十字路口", passage = "十字路口", icon = "🔀", mapKey = "十字路口" },
        { name = "家", passage = "家", icon = "🏠", mapKey = "家" },
        { name = "商业区", passage = "商业区", icon = "🍜", mapKey = "商业区" },
        { name = "港口", passage = "港口", icon = "🚢", mapKey = "港口" },
        { name = "花园小镇", passage = "花园小镇", icon = "⛲", mapKey = "花园小镇" },
        { name = "主城区", passage = "主城区", icon = "🏛️", mapKey = "主城区" },
        { name = "花街", passage = "花街", icon = "🌹", mapKey = "花街" },
        { name = "渡劫森林", passage = "渡劫森林", icon = "🌲", mapKey = "渡劫森林" },
        { name = "社区大学", passage = "大学校门", icon = "🎓", mapKey = "大学校门" },
    }
    for _, nav in ipairs(navTargets) do
        local here = isHere({nav.passage})
        -- 查看该区域的详细地图
        table.insert(choices, {
            text = nav.icon .. (here and " " or " ") .. nav.name .. " 区域地图" .. (here and "（当前）" or ""),
            action = function()
                S._viewMapArea = nav.mapKey
                return "区域地图"
            end,
        })
    end

    table.insert(choices, {
        text = "收起地图",
        target = from,
    })

    return { text = text, choices = choices }
end

---===================== 设置 =====================


end
