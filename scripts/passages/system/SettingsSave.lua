-- passages/system/SettingsSave.lua
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

handlers["测试面板"] = function(S)
    local text = "测试面板\n\n仅供调试使用，修改后请谨慎保存。\n\n"
        .. "五维属性\n"
        .. "力量: " .. (S.LL or 1) .. "  灵感: " .. (S.LG or 1) .. "  魅力: " .. (S.ML or 3) .. "  耐力: " .. (S.NL or 2) .. "  技巧: " .. (S.JQ or 1) .. "\n\n"
        .. "好感度\n"
        .. (S.initialName or "莱德") .. ": " .. (S.initialNameAffection or 0) .. "/100\n"
        .. "K: " .. (S.kAffection or 0) .. "/100\n"
        .. "罗斯巴特少爷: " .. (S.oamelAffection or 0) .. "\n"
        .. "梅菲斯: " .. (S.meifeiAffection or 0) .. "\n\n"
        .. "其他\n"
        .. "金币: " .. (S.money or 0) .. "  蜡烛: " .. (S.candles or 0) .. "\n"
        .. "莱德在家: " .. tostring(S.initialNameAtHome) .. "\n"
        .. "同床状态: " .. tostring(S.initialNameSleepTogether)

    local choices = {}
    -- 属性加减
    table.insert(choices, { text = "力量+1", action = function() S.LL = (S.LL or 1) + 1 return "测试面板" end })
    table.insert(choices, { text = "灵感+1", action = function() S.LG = (S.LG or 1) + 1 return "测试面板" end })
    table.insert(choices, { text = "魅力+1", action = function() S.ML = (S.ML or 3) + 1 return "测试面板" end })
    table.insert(choices, { text = "耐力+1", action = function() S.NL = (S.NL or 2) + 1 return "测试面板" end })
    table.insert(choices, { text = "技巧+1", action = function() S.JQ = (S.JQ or 1) + 1 return "测试面板" end })
    -- 好感度
    table.insert(choices, { text = (S.initialName or "莱德") .. " 好感+5", action = function() addAffection("initialName", 5) return "测试面板" end })
    table.insert(choices, { text = "K 好感+5", action = function() addAffection("k", 5) return "测试面板" end })
    table.insert(choices, { text = "罗斯巴特少爷 好感+5", action = function() addOamelAffection(5) return "测试面板" end })
    table.insert(choices, { text = "梅菲斯 好感+5", action = function() addMeifeiAffection(5) return "测试面板" end })
    -- 金币/蜡烛
    table.insert(choices, { text = "金币+100", action = function() S.money = (S.money or 0) + 100 return "测试面板" end })
    table.insert(choices, { text = "蜡烛+1", action = function() S.candles = (S.candles or 0) + 1 return "测试面板" end })
    -- 切换
    table.insert(choices, { text = "切换莱德在家", action = function() S.initialNameAtHome = not S.initialNameAtHome return "测试面板" end })
    table.insert(choices, { text = "切换同床状态", action = function() S.initialNameSleepTogether = not S.initialNameSleepTogether return "测试面板" end })

    table.insert(choices, { text = "返回", target = "家" })

    return { text = text, choices = choices }
end

---===================== 话题对话 =====================
--- Twine pid 38-40: 话题系统简化处理


handlers["话题对话"] = function(S)
    local topicId = S.currentTopic or ""
    local dialogue = topicDialogues[topicId]
    if not dialogue then
        return { text = "没有可聊的话题。", choices = {{ text = "返回", target = S.returnPassage or "十字路口" }} }
    end

    local node = S.dialogueNode or "start"
    local data = dialogue[node] or dialogue.start
    if not data then
        return { text = "对话结束。", choices = {{ text = "返回", target = S.returnPassage or "十字路口" }} }
    end

    local name = S.dialogueChar == "leiDe" and (S.initialName or "莱德") or "K"
    local textContent = type(data.text) == "function" and data.text(name) or data.text

    if data.options and #data.options > 0 then
        local choices = {}
        for _, opt in ipairs(data.options) do
            table.insert(choices, {
                text = opt.text,
                action = function()
                    S.dialogueNode = opt.next
                    return "话题对话"
                end,
            })
        end
        return { text = textContent, choices = choices }
    elseif data.next == "end" then
        -- 对话结束
        if S.dialogueChar == "leiDe" then
            addAffection("initialName", 20)
            addDateLog(S.initialName or "莱德", "话题", "和 " .. (S.initialName or "莱德") .. " 聊了 " .. (S.currentTopic or ""))
        else
            addAffection("k", 20)
            addDateLog("K", "话题", "和 K 聊了 " .. (S.currentTopic or ""))
        end
        S.currentTopic = ""
        S.dialogueNode = ""
        S.dialogueChar = ""
        return { text = textContent, choices = {{ text = "返回", target = S.returnPassage or "十字路口" }} }
    else
        S.dialogueNode = data.next
        return PassageData.getPassage("话题对话")
    end
end

---===================== 区域地图 =====================


handlers["设置"] = function(S)
    local ver = ChangelogData and ChangelogData.getVersion() or "1.00"
    return {
        text = "设置\n\n版本：悠闲悠哉life v" .. ver .. "\n\n感谢您的游玩。",
        choices = {
            { text = "版本日志", target = "版本日志" },
            { text = "返回", target = "家" },
        },
    }
end

---===================== 版本日志 =====================


handlers["版本日志"] = function(S)
    -- 初始化 spoiler 展开状态表
    if not S._spoilerExpanded then
        S._spoilerExpanded = {}
    end
    -- 当前查看的版本页（每页1个版本）
    local page = S._changelogPage or 1
    local entries = ChangelogData and ChangelogData.getAll() or {}
    local totalPages = #entries

    if totalPages == 0 then
        return {
            text = "版本日志\n\n暂无更新记录。",
            choices = { { text = "返回", target = "设置" } },
        }
    end

    -- 确保页码有效
    if page < 1 then page = 1 end
    if page > totalPages then page = totalPages end
    S._changelogPage = page

    local entry = entries[page]
    local text = "版本日志  (" .. page .. "/" .. totalPages .. ")\n\n"
    text = text .. "【v" .. entry.version .. "】" .. entry.title .. "\n"
    text = text .. "  " .. entry.date .. "\n\n"

    for ci, change in ipairs(entry.changes) do
        if type(change) == "string" then
            text = text .. "  · " .. change .. "\n"
        elseif type(change) == "table" then
            if change.header then
                -- 段落标题：前面加空行隔开上一段，不加 · 前缀
                if ci > 1 then text = text .. "\n" end
                text = text .. "  " .. change.header .. "\n"
            elseif change.spoilerTitle then
                -- 剧透折叠条目
                local spoilerKey = entry.version .. "_" .. ci
                if S._spoilerExpanded[spoilerKey] then
                    text = text .. "  ▼ " .. change.spoilerTitle .. "\n"
                    for _, line in ipairs(change.spoilerContent or {}) do
                        text = text .. "     " .. line .. "\n"
                    end
                else
                    text = text .. "  ▶ " .. change.spoilerTitle .. "\n"
                end
            end
        end
    end

    -- 构建选项
    local choices = {}

    -- 剧透折叠切换按钮
    for ci, change in ipairs(entry.changes) do
        if type(change) == "table" and change.spoilerTitle then
            local spoilerKey = entry.version .. "_" .. ci
            local isExpanded = S._spoilerExpanded[spoilerKey]
            local btnText = isExpanded
                and ("收起：" .. change.spoilerTitle:gsub("📖 ", ""):gsub("（点击展开/收起剧情详情）", ""))
                or ("展开：" .. change.spoilerTitle:gsub("📖 ", ""):gsub("（点击展开/收起剧情详情）", ""))
            local capturedKey = spoilerKey
            table.insert(choices, {
                text = btnText,
                action = function()
                    S._spoilerExpanded[capturedKey] = not S._spoilerExpanded[capturedKey]
                    return "版本日志"
                end,
            })
        end
    end

    -- 翻页按钮
    if page > 1 then
        table.insert(choices, {
            text = "上一版本",
            action = function()
                S._changelogPage = page - 1
                S._spoilerExpanded = {}
                return "版本日志"
            end,
        })
    end
    if page < totalPages then
        table.insert(choices, {
            text = "下一版本",
            action = function()
                S._changelogPage = page + 1
                S._spoilerExpanded = {}
                return "版本日志"
            end,
        })
    end

    table.insert(choices, { text = "返回", target = "设置" })

    return {
        text = text,
        choices = choices,
    }
end

---===================== 存档 =====================


handlers["存档"] = function(S)
    return {
        text = "存档\n\n确定要保存当前进度吗？",
        choices = {
            { text = "确认保存", action = function()
                if SaveSystem and SaveSystem.save then
                    SaveSystem.save(1)
                end
                return "家"
            end },
            { text = "取消", target = "家" },
        },
    }
end

---===================== 读档 =====================


handlers["读档"] = function(S)
    return {
        text = "读档\n\n确定要读取存档吗？当前进度将丢失。",
        choices = {
            { text = "确认读取", action = function()
                if SaveSystem and SaveSystem.load then
                    SaveSystem.load(1)
                end
                return "家"
            end },
            { text = "取消", target = "家" },
        },
    }
end


end
