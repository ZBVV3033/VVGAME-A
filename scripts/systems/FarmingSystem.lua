-- ============================================================================
-- FarmingSystem.lua - 种植系统（悠闲悠哉life）
-- 种子 / 种植 / 浇水 / 收获 / 家门口小空地
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")

local FarmingSystem = {}

-- ==================== 种子定义 ====================

FarmingSystem.SEEDS = {
    { name = "土豆种子",   price = 3,  crop = "土豆",   growDays = 3, yield = {2, 3} },
    { name = "胡萝卜种子", price = 2,  crop = "胡萝卜", growDays = 2, yield = {2, 4} },
    { name = "白菜种子",   price = 2,  crop = "白菜",   growDays = 2, yield = {1, 3} },
    { name = "番茄种子",   price = 4,  crop = "番茄",   growDays = 3, yield = {2, 4} },
    { name = "洋葱种子",   price = 3,  crop = "洋葱",   growDays = 3, yield = {1, 3} },
    { name = "小麦种子",   price = 3,  crop = "小麦",   growDays = 4, yield = {3, 5} },
}

-- ==================== 生长阶段 ====================
-- stage: 0=空地, 1=已播种, 2=发芽, 3=生长中, 4=成熟可收获

local STAGE_NAMES = {
    [0] = "空地",
    [1] = "已播种",
    [2] = "发芽了",
    [3] = "生长中",
    [4] = "成熟了!",
}

-- ==================== 工具函数 ====================

--- 获取种子信息
function FarmingSystem.getSeedInfo(seedName)
    for _, seed in ipairs(FarmingSystem.SEEDS) do
        if seed.name == seedName then return seed end
    end
    return nil
end

--- 获取作物对应的种子
function FarmingSystem.getSeedByCrop(cropName)
    for _, seed in ipairs(FarmingSystem.SEEDS) do
        if seed.crop == cropName then return seed end
    end
    return nil
end

--- 添加种子
function FarmingSystem.addSeed(seedName, count)
    local S = GameState.state
    S.farmSeeds[seedName] = (S.farmSeeds[seedName] or 0) + (count or 1)
end

--- 获取种子背包文本
function FarmingSystem.getSeedsText()
    local S = GameState.state
    local parts = {}
    for name, count in pairs(S.farmSeeds) do
        if count > 0 then
            table.insert(parts, name .. "×" .. count)
        end
    end
    if #parts == 0 then return "（空空如也）" end
    return table.concat(parts, "、")
end

--- 获取地块状态图标
function FarmingSystem.getPlotIcon(plot)
    if plot.stage == 0 or plot.crop == nil then return "⬜" end
    if plot.stage == 1 then return "🟤" end
    if plot.stage == 2 then return "🌱" end
    if plot.stage == 3 then return "🌿" end
    if plot.stage == 4 then return "🌾" end
    return "⬜"
end

--- 获取地块描述
function FarmingSystem.getPlotDesc(index, plot)
    local icon = FarmingSystem.getPlotIcon(plot)
    if plot.crop == nil or plot.stage == 0 then
        return icon .. " 第" .. index .. "块地: 空地"
    end
    local stageName = STAGE_NAMES[plot.stage] or "未知"
    local waterIcon = plot.watered and " 💧" or " 🏜️"
    return icon .. " 第" .. index .. "块地: " .. plot.crop .. " [" .. stageName .. "]" .. waterIcon
end

--- 每日作物生长（由 TimeSystem.onDayChange 调用）
function FarmingSystem.onDayChange()
    local S = GameState.state
    local harvestReady = false

    for _, plot in ipairs(S.farmPlots) do
        if plot.crop and plot.stage > 0 and plot.stage < 4 then
            -- 浇过水的作物才会生长
            if plot.watered then
                plot.stage = plot.stage + 1
                if plot.stage >= 4 then
                    plot.stage = 4
                    harvestReady = true
                end
            end
            -- 每天重置浇水状态
            plot.watered = false
        end
    end

    if harvestReady then
        GameState.showNotification("门口有作物成熟了！去看看吧。")
    end
end

--- 种植种子到指定地块
function FarmingSystem.plantSeed(plotIndex, seedName)
    local S = GameState.state
    local plot = S.farmPlots[plotIndex]
    if not plot then return false, "无效地块" end
    if plot.crop ~= nil and plot.stage > 0 then return false, "这块地已经种了东西" end
    if (S.farmSeeds[seedName] or 0) <= 0 then return false, "没有这种种子" end

    local seed = FarmingSystem.getSeedInfo(seedName)
    if not seed then return false, "未知种子" end

    S.farmSeeds[seedName] = S.farmSeeds[seedName] - 1
    if S.farmSeeds[seedName] <= 0 then S.farmSeeds[seedName] = nil end

    plot.crop = seed.crop
    plot.plantDay = S.day
    plot.stage = 1
    plot.watered = false

    return true, seed.crop
end

--- 浇水
function FarmingSystem.waterPlot(plotIndex)
    local S = GameState.state
    local plot = S.farmPlots[plotIndex]
    if not plot then return false, "无效地块" end
    if plot.crop == nil or plot.stage == 0 then return false, "这块地是空的" end
    if plot.stage >= 4 then return false, "作物已经成熟了" end
    if plot.watered then return false, "今天已经浇过水了" end

    plot.watered = true
    return true
end

--- 收获
function FarmingSystem.harvest(plotIndex)
    local S = GameState.state
    local plot = S.farmPlots[plotIndex]
    if not plot then return nil end
    if plot.crop == nil or plot.stage < 4 then return nil end

    local seed = FarmingSystem.getSeedByCrop(plot.crop)
    local cropName = plot.crop
    local yieldMin = seed and seed.yield[1] or 1
    local yieldMax = seed and seed.yield[2] or 2
    local amount = math.random(yieldMin, yieldMax)

    -- 添加到食材背包
    S.ingredients[cropName] = (S.ingredients[cropName] or 0) + amount

    -- 收获时收集关键词
    local kwOk, KW = pcall(require, "systems.KeywordSystem")
    if kwOk and KW.collectKeyword then
        KW.collectKeyword("crop_harvest")
        if math.random() < 0.15 then KW.collectKeyword("rare_seed") end
    end

    -- 清空地块
    plot.crop = nil
    plot.plantDay = 0
    plot.stage = 0
    plot.watered = false

    return { crop = cropName, amount = amount }
end

-- ==================== 段落系统 ====================

function FarmingSystem.getPassage(passageName)
    local S = GameState.state

    -- ==================== 家门口空地 ====================

    if passageName == "家_门口空地" then
        local lines = {
            "你走到家门口的小空地。\n",
            "三块整齐的田垄沐浴在阳光下。\n",
        }

        -- 地块状态
        for i, plot in ipairs(S.farmPlots) do
            table.insert(lines, FarmingSystem.getPlotDesc(i, plot))
        end

        table.insert(lines, "\n种子袋: " .. FarmingSystem.getSeedsText())

        local choices = {}

        -- 检查是否有可浇水的地块
        local hasWaterable = false
        for i, plot in ipairs(S.farmPlots) do
            if plot.crop and plot.stage > 0 and plot.stage < 4 and not plot.watered then
                hasWaterable = true
                break
            end
        end

        if hasWaterable then
            table.insert(choices, {
                text = "💧 浇水",
                target = "家_浇水",
            })
        end

        -- 检查是否有可收获的地块
        local hasHarvestable = false
        for _, plot in ipairs(S.farmPlots) do
            if plot.stage >= 4 then
                hasHarvestable = true
                break
            end
        end

        if hasHarvestable then
            table.insert(choices, {
                text = "🌾 收获",
                target = "家_收获",
            })
        end

        -- 检查是否有空地和种子
        local hasEmpty = false
        for _, plot in ipairs(S.farmPlots) do
            if plot.crop == nil or plot.stage == 0 then
                hasEmpty = true
                break
            end
        end

        local hasSeeds = false
        for _, count in pairs(S.farmSeeds) do
            if count > 0 then hasSeeds = true; break end
        end

        if hasEmpty and hasSeeds then
            table.insert(choices, {
                text = "🌰 播种",
                target = "家_播种",
            })
        elseif hasEmpty and not hasSeeds then
            table.insert(choices, {
                text = "🌰 播种（没有种子，去超市买吧）",
                target = "家_门口空地",
                action = function()
                    GameState.showNotification("你没有种子。去商业区超市看看？")
                end,
            })
        end

        table.insert(choices, { text = "🔙 回家", target = "家" })

        return {
            text = table.concat(lines, "\n"),
            choices = choices,
        }
    end

    -- ==================== 播种选择 ====================

    if passageName == "家_播种" then
        -- 找空地
        local emptyPlots = {}
        for i, plot in ipairs(S.farmPlots) do
            if plot.crop == nil or plot.stage == 0 then
                table.insert(emptyPlots, i)
            end
        end

        if #emptyPlots == 0 then
            return {
                text = "所有地块都已经种上东西了。",
                choices = { { text = "🔙 返回", target = "家_门口空地" } },
            }
        end

        -- 列出可用种子
        local choices = {}
        for seedName, count in pairs(S.farmSeeds) do
            if count > 0 then
                local seed = FarmingSystem.getSeedInfo(seedName)
                local cropName = seed and seed.crop or "?"
                local growDays = seed and seed.growDays or "?"
                table.insert(choices, {
                    text = "🌰 " .. seedName .. "×" .. count
                        .. " (种出" .. cropName .. "，" .. growDays .. "天成熟)",
                    target = "家_播种确认",
                    action = function()
                        S._selectedSeed = seedName
                        S._emptyPlots = emptyPlots
                    end,
                })
            end
        end

        table.insert(choices, { text = "🔙 返回", target = "家_门口空地" })

        return {
            text = "选择要播种的种子:\n\n种子袋: " .. FarmingSystem.getSeedsText(),
            choices = choices,
        }
    end

    -- ==================== 播种确认（选择地块） ====================

    if passageName == "家_播种确认" then
        local seedName = S._selectedSeed
        local emptyPlots = S._emptyPlots or {}

        -- 重新检查空地
        emptyPlots = {}
        for i, plot in ipairs(S.farmPlots) do
            if plot.crop == nil or plot.stage == 0 then
                table.insert(emptyPlots, i)
            end
        end

        local choices = {}
        for _, plotIdx in ipairs(emptyPlots) do
            table.insert(choices, {
                text = "⬜ 种在第" .. plotIdx .. "块地",
                target = "家_门口空地",
                action = function()
                    local ok, result = FarmingSystem.plantSeed(plotIdx, seedName)
                    if ok then
                        TimeSystem.addMinutes(15)
                        GameState.showNotification("在第" .. plotIdx .. "块地种下了" .. result .. "。记得每天浇水哦！")
                    else
                        GameState.showNotification(result)
                    end
                end,
            })
        end

        table.insert(choices, { text = "🔙 返回", target = "家_播种" })

        return {
            text = "要把 " .. (seedName or "种子") .. " 种在哪块地？",
            choices = choices,
        }
    end

    -- ==================== 浇水 ====================

    if passageName == "家_浇水" then
        local choices = {}
        local wateredAny = false

        for i, plot in ipairs(S.farmPlots) do
            if plot.crop and plot.stage > 0 and plot.stage < 4 and not plot.watered then
                table.insert(choices, {
                    text = "💧 浇第" .. i .. "块地 (" .. plot.crop .. ")",
                    target = "家_浇水",
                    action = function()
                        local ok = FarmingSystem.waterPlot(i)
                        if ok then
                            TimeSystem.addMinutes(5)
                            GameState.showNotification("给第" .. i .. "块地的" .. plot.crop .. "浇了水。")
                        end
                    end,
                })
            end
        end

        -- 一键全部浇水
        local unwateredCount = 0
        for _, plot in ipairs(S.farmPlots) do
            if plot.crop and plot.stage > 0 and plot.stage < 4 and not plot.watered then
                unwateredCount = unwateredCount + 1
            end
        end

        if unwateredCount > 1 then
            table.insert(choices, 1, {
                text = "💦 全部浇水 (" .. unwateredCount .. "块地)",
                target = "家_门口空地",
                action = function()
                    local count = 0
                    for i, plot in ipairs(S.farmPlots) do
                        if plot.crop and plot.stage > 0 and plot.stage < 4 and not plot.watered then
                            FarmingSystem.waterPlot(i)
                            count = count + 1
                        end
                    end
                    TimeSystem.addMinutes(5 * count)
                    GameState.showNotification("给" .. count .. "块地都浇了水。辛苦啦！")
                end,
            })
        end

        if #choices == 0 then
            return {
                text = "今天所有作物都已经浇过水了。",
                choices = { { text = "🔙 返回", target = "家_门口空地" } },
            }
        end

        table.insert(choices, { text = "🔙 返回", target = "家_门口空地" })

        return {
            text = "选择要浇水的地块:",
            choices = choices,
        }
    end

    -- ==================== 收获 ====================

    if passageName == "家_收获" then
        local choices = {}
        local totalHarvest = {}

        -- 一键收获
        local harvestableCount = 0
        for _, plot in ipairs(S.farmPlots) do
            if plot.stage >= 4 then
                harvestableCount = harvestableCount + 1
            end
        end

        if harvestableCount > 1 then
            table.insert(choices, {
                text = "🌾 全部收获 (" .. harvestableCount .. "块地)",
                target = "家_收获结果",
                action = function()
                    local results = {}
                    for i = 1, #S.farmPlots do
                        local result = FarmingSystem.harvest(i)
                        if result then
                            table.insert(results, result)
                        end
                    end
                    S._harvestResults = results
                    TimeSystem.addMinutes(10)
                end,
            })
        end

        for i, plot in ipairs(S.farmPlots) do
            if plot.stage >= 4 then
                table.insert(choices, {
                    text = "🌾 收获第" .. i .. "块地 (" .. plot.crop .. ")",
                    target = "家_收获结果",
                    action = function()
                        local result = FarmingSystem.harvest(i)
                        S._harvestResults = result and { result } or {}
                        TimeSystem.addMinutes(5)
                    end,
                })
            end
        end

        if #choices == 0 then
            return {
                text = "暂时没有成熟的作物。",
                choices = { { text = "🔙 返回", target = "家_门口空地" } },
            }
        end

        table.insert(choices, { text = "🔙 返回", target = "家_门口空地" })

        return {
            text = "有作物成熟了！选择要收获的地块:",
            choices = choices,
        }
    end

    -- ==================== 收获结果 ====================

    if passageName == "家_收获结果" then
        local results = S._harvestResults or {}
        S._harvestResults = nil

        if #results == 0 then
            return {
                text = "好像没收到什么。",
                choices = { { text = "🔙 返回", target = "家_门口空地" } },
            }
        end

        local lines = { "丰收啦！\n" }
        for _, r in ipairs(results) do
            table.insert(lines, "🌾 收获了 " .. r.crop .. " ×" .. r.amount)
        end
        table.insert(lines, "\n这些食材已经放进厨房了。可以用来做菜！")

        return {
            text = table.concat(lines, "\n"),
            choices = {
                { text = "🌱 继续种地", target = "家_门口空地" },
                { text = "🍳 去厨房做饭", target = "家_厨房" },
                { text = "🔙 回家", target = "家" },
            },
        }
    end

    return nil
end

return FarmingSystem
