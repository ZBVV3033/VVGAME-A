-- ============================================================================
-- UISidebar.lua - 侧边栏 & 状态栏（从 UIManager.lua 提取）
-- install 模式：返回一个函数，调用时将方法注入 UIManager
-- ============================================================================

---@param UIManager table  UIManager 模块表
---@param ctx table        共享上下文 { statusBar, sidebarPanel, sidebarOverlay, sidebarVisible, ... }
---@param cfg table        UIConfig（LAYOUT, COLORS, isMobile）
return function(UIManager, ctx, cfg)

local UI = require("urhox-libs/UI")
local GameState = require("systems.GameState")

local LAYOUT = cfg.LAYOUT
local COLORS = cfg.COLORS
local isMobile = cfg.isMobile

-- ==================== 状态栏 ====================

--- 构建状态栏
function UIManager._buildStatusBar()
    local menuBtnSize = isMobile and 53 or 43
    return UI.Panel {
        id = "statusBar",
        width = "100%",
        height = LAYOUT.statusBarH,
        flexDirection = "row",
        alignItems = "center",
        justifyContent = "space-between",
        paddingHorizontal = isMobile and 16 or 12,
        paddingVertical = 4,
        backgroundColor = COLORS.statusBg,
        borderBottomWidth = 1,
        borderBottomColor = COLORS.divider,
        children = {
            -- 左侧：头像 + 菜单按钮 + 日期时间
            UI.Panel {
                flexDirection = "row",
                alignItems = "center",
                gap = 6,
                children = {
                    -- 角色头像占位（实际由 SceneView 的 NanoVG 层绘制，支持换装联动）
                    UI.Panel {
                        id = "statusAvatar",
                        width = menuBtnSize - 4,
                        height = menuBtnSize - 4,
                    },
                    UI.Button {
                        id = "menuBtn",
                        text = "=",
                        width = menuBtnSize,
                        height = menuBtnSize,
                        fontSize = isMobile and 26 or 23,
                        backgroundColor = COLORS.btnBg,
                        textColor = COLORS.text,
                        hoverBackgroundColor = COLORS.btnHover,
                        pressedBackgroundColor = COLORS.btnPress,
                        borderRadius = 6,
                        onClick = function(self)
                            UIManager.toggleSidebar()
                        end,
                    },
                    UI.Label {
                        id = "statusDate",
                        text = "499年1月1日",
                        fontSize = LAYOUT.fontSmall,
                        fontColor = COLORS.textDim,
                    },
                },
            },
            -- 中间：标题
            UI.Label {
                id = "statusTitle",
                text = "悠闲悠哉life",
                fontSize = LAYOUT.fontTitle,
                fontColor = COLORS.textTitle,
                fontWeight = "bold",
            },
            -- 右侧：金币
            UI.Label {
                id = "statusMoney",
                text = "0 金币",
                fontSize = LAYOUT.fontSmall,
                fontColor = COLORS.textGold,
            },
        },
    }
end

-- ==================== 侧边栏 ====================

--- 构建侧边栏
function UIManager._buildSidebar()
    -- 移动端：绝对定位覆盖式侧边栏
    local sidebarProps = {
        id = "sidebar",
        width = LAYOUT.sidebarWidth,
        flexShrink = 0,
        flexDirection = "column",
        backgroundColor = { 26, 26, 38, 250 },
        borderRightWidth = 1,
        borderRightColor = COLORS.divider,
        padding = isMobile and 16 or 12,
        gap = isMobile and 8 or 6,
        visible = false,
    }
    if isMobile then
        sidebarProps.position = "absolute"
        sidebarProps.left = 0
        sidebarProps.top = 0
        sidebarProps.height = "100%"
        sidebarProps.zIndex = 100
    end

    local navBtnH = LAYOUT.btnSmallH
    local navFontSize = LAYOUT.fontStat

    sidebarProps.children = {
        -- 角色名
        UI.Label {
            id = "sidebarName",
            text = "诺兰",
            fontSize = isMobile and 22 or 19,
            fontColor = COLORS.textTitle,
            fontWeight = "bold",
            textAlign = "center",
            width = "100%",
            marginBottom = 4,
        },
        -- 分隔线
        UI.Divider { orientation = "horizontal", color = COLORS.divider, spacing = 2 },
        -- 时间日期（上下两行）
        UI.Panel {
            width = "100%",
            alignItems = "center",
            gap = 2,
            children = {
                UI.Label {
                    id = "sidebarDate",
                    text = "499年1月1日",
                    fontSize = LAYOUT.fontStat,
                    fontColor = COLORS.textDim,
                    textAlign = "center",
                    width = "100%",
                },
                UI.Label {
                    id = "sidebarTime",
                    text = "星期一 08:00",
                    fontSize = LAYOUT.fontStat,
                    fontColor = COLORS.textDim,
                    textAlign = "center",
                    width = "100%",
                },
            },
        },
        -- 金币
        UI.Label {
            id = "sidebarMoney",
            text = "金币: 0",
            fontSize = LAYOUT.fontSmall,
            fontColor = COLORS.textGold,
            textAlign = "center",
            width = "100%",
            marginBottom = 4,
        },
        -- 分隔线
        UI.Divider { orientation = "horizontal", color = COLORS.divider, spacing = 2 },
        -- 生存状态标题
        UI.Label {
            text = "状态",
            fontSize = LAYOUT.fontSmall,
            fontColor = COLORS.accent,
            fontWeight = "bold",
            width = "100%",
            marginBottom = 2,
        },
        -- 疲劳条
        UIManager._buildStatBar("sidebarFatigue", "疲劳", 0, {80, 210, 120, 255}),
        -- 压力条
        UIManager._buildStatBar("sidebarStress", "压力", 0, {80, 210, 120, 255}),
        -- 饱食度条
        UIManager._buildStatBar("sidebarSatiety", "饱食", 80, {80, 210, 120, 255}),
        -- 清洁条
        UIManager._buildStatBar("sidebarClean", "清洁", 90, {120, 180, 220, 255}),
        -- 分隔线
        UI.Divider { orientation = "horizontal", color = COLORS.divider, spacing = 2 },
        -- 属性标题
        UI.Label {
            text = "属性",
            fontSize = LAYOUT.fontSmall,
            fontColor = COLORS.accent,
            fontWeight = "bold",
            width = "100%",
            marginBottom = 2,
        },
        -- 状态描述（第三人称）
        UI.Label { id = "sidebarDesc", text = "", fontSize = LAYOUT.fontStat, fontColor = COLORS.textDim, width = "100%", marginBottom = 4 },
        -- 五维属性（一行）
        UI.Label { id = "sidebarAttrs", text = "力1 灵1 魅3 耐2 技1", fontSize = LAYOUT.fontStat, fontColor = COLORS.text, width = "100%" },
        -- 分隔线
        UI.Divider { orientation = "horizontal", color = COLORS.divider, spacing = 4 },
        -- 快捷导航标题
        UI.Label {
            text = "导航",
            fontSize = LAYOUT.fontSmall,
            fontColor = COLORS.accent,
            fontWeight = "bold",
            width = "100%",
            marginBottom = 2,
        },
        -- 导航按钮
        UI.Button {
            text = "地图",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                S._viewMapArea = nil
                UIManager.navigate("区域地图")
            end,
        },
        UI.Button {
            text = "查看属性",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                UIManager.navigate("属性")
            end,
        },
        UI.Button {
            text = "社会关系",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                UIManager.navigate("社会关系")
            end,
        },
        UI.Button {
            text = "战斗",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                UIManager.navigate("战斗面板")
            end,
        },
        UI.Button {
            text = "技能",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                UIManager.navigate("技能")
            end,
        },
        UI.Button {
            text = "日志",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                UIManager.navigate("日志")
            end,
        },
        UI.Button {
            text = "背包",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                UIManager.navigate("背包")
            end,
        },
        -- 分隔线
        UI.Divider { orientation = "horizontal", color = COLORS.divider, spacing = 4 },
        -- 存档/读档
        UI.Button {
            text = "存档",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                UIManager.navigate("存档")
            end,
        },
        UI.Button {
            text = "读档",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.text,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                UIManager.navigate("读档")
            end,
        },
        -- 分隔线
        UI.Divider { orientation = "horizontal", color = COLORS.divider, spacing = 4 },
        -- 设置按钮
        UI.Button {
            text = "设置",
            width = "100%",
            height = navBtnH,
            fontSize = navFontSize,
            backgroundColor = COLORS.btnBg,
            textColor = COLORS.textDim,
            hoverBackgroundColor = COLORS.btnHover,
            pressedBackgroundColor = COLORS.btnPress,
            borderRadius = 4,
            onClick = function(self)
                if isMobile then UIManager.toggleSidebar() end
                local S = GameState.state
                S._settingsFrom = S.currentPassage
                UIManager.navigate("设置")
            end,
        },
    }

    return UI.Panel(sidebarProps)
end

-- ==================== 状态条 ====================

--- 构建状态条（条形百分比进度条）
---@param id string 组件ID
---@param label string 标签文本
---@param value number 当前值（0-100）
---@param color table 进度条颜色 {r,g,b}
---@return table UI组件
function UIManager._buildStatBar(id, label, value, color)
    local barH = isMobile and 14 or 12
    local sidebarContentW = isMobile and 280 or (200 - 12 * 2)
    local pct = math.max(0, math.min(100, value))
    local fillW = math.floor(sidebarContentW * pct / 100)
    return UI.Panel {
        id = id,
        width = "100%",
        flexDirection = "column",
        gap = 1,
        marginBottom = 4,
        children = {
            -- 标签行：名称 + 数值
            UI.Panel {
                width = "100%",
                flexDirection = "row",
                justifyContent = "space-between",
                alignItems = "center",
                children = {
                    UI.Label {
                        id = id .. "_label",
                        text = label,
                        fontSize = LAYOUT.fontStat,
                        fontColor = COLORS.textDim,
                    },
                    UI.Label {
                        id = id .. "_value",
                        text = tostring(value),
                        fontSize = LAYOUT.fontStat,
                        fontColor = color,
                    },
                },
            },
            -- 进度条背景
            UI.Panel {
                id = id .. "_bg",
                width = "100%",
                height = barH,
                borderRadius = barH / 2,
                backgroundColor = { 50, 50, 68, 255 },
                children = {
                    -- 进度条填充（使用绝对像素宽度）
                    UI.Panel {
                        id = id .. "_fill",
                        width = fillW,
                        height = barH,
                        borderRadius = barH / 2,
                        backgroundColor = color,
                    },
                },
            },
        },
    }
end

-- ==================== 切换 & 更新 ====================

--- 切换侧边栏显示/隐藏
function UIManager.toggleSidebar()
    ctx.sidebarVisible = not ctx.sidebarVisible
    if ctx.sidebarPanel then
        ctx.sidebarPanel:SetVisible(ctx.sidebarVisible)
        if ctx.sidebarVisible then
            UIManager.updateSidebar()
        end
    end
    -- 移动端：同步遮罩层
    if isMobile and ctx.sidebarOverlay then
        ctx.sidebarOverlay:SetVisible(ctx.sidebarVisible)
    end
end

--- 更新侧边栏数据
function UIManager.updateSidebar()
    local S = GameState.state
    if not ctx.sidebarPanel or not ctx.sidebarVisible then return end

    local nameLabel = ctx.sidebarPanel:FindById("sidebarName")
    if nameLabel then
        nameLabel:SetText(S.PNN ~= "" and S.PNN or "诺兰")
    end

    local dateLabel2 = ctx.sidebarPanel:FindById("sidebarDate")
    local timeLabel = ctx.sidebarPanel:FindById("sidebarTime")
    if dateLabel2 and timeLabel then
        if S.inPrologue then
            dateLabel2:SetText("序章")
            timeLabel:SetText("过去的回忆")
        else
            dateLabel2:SetText(S.year .. "年" .. S.month .. "月" .. S.day .. "日")
            timeLabel:SetText(GameState.getDayOfWeek() .. " " .. GameState.getTimeStr())
        end
    end

    local moneyLabel = ctx.sidebarPanel:FindById("sidebarMoney")
    if moneyLabel then
        moneyLabel:SetText(S.inPrologue and "金币: --" or ("金币: " .. S.money))
    end

    -- 五维属性（一行）
    local attrsLabel = ctx.sidebarPanel:FindById("sidebarAttrs")
    if attrsLabel then
        attrsLabel:SetText("力" .. (S.LL or 1) .. " 灵" .. (S.LG or 1) .. " 魅" .. (S.ML or 3) .. " 耐" .. (S.NL or 2) .. " 技" .. (S.JQ or 1))
    end

    -- 第三人称状态描述
    local descLabel = ctx.sidebarPanel:FindById("sidebarDesc")
    if descLabel then
        descLabel:SetText(UIManager._buildStatusDesc(S))
    end

    -- 生存状态条
    UIManager._updateStatBar("sidebarSatiety", S.satiety or 80, "satiety")
    UIManager._updateStatBar("sidebarFatigue", S.fatigue or 0, "fatigue")
    UIManager._updateStatBar("sidebarClean", S.cleanliness or 90, "cleanliness")
    UIManager._updateStatBar("sidebarStress", S.stress or 0, "stress")
end

--- 构建第三人称状态描述（约30字）
---@param S table GameState.state
---@return string
function UIManager._buildStatusDesc(S)
    local name = S.PNN ~= "" and S.PNN or "诺兰"

    -- 着装描述
    local outfitDesc = ""
    local outfit = S.outfit or "casual"
    if string.find(outfit, "^uniform_") then
        local wsOk, WS = pcall(require, "systems.WorkSystem")
        local info = wsOk and WS.getUniformInfo and WS.getUniformInfo(outfit)
        outfitDesc = info and info.shortDesc or "穿着工作服"
    elseif outfit == "work" then
        outfitDesc = "穿着工作服"
    elseif outfit == "formal" then
        outfitDesc = "衣着整洁"
    elseif outfit == "pajamas" then
        outfitDesc = "穿着睡衣"
    else
        outfitDesc = "穿着便装"
    end

    -- 身体状态（取最突出的一项）
    local bodyDesc = ""
    local fatigue = S.fatigue or 0
    local stress = S.stress or 0
    local satiety = S.satiety or 80
    local clean = S.cleanliness or 90

    if fatigue >= 80 then
        bodyDesc = "，顶着浓重的黑眼圈"
    elseif fatigue >= 60 then
        bodyDesc = "，眼下挂着淡淡青黑"
    elseif stress >= 80 then
        bodyDesc = "，面目狰狞情绪暴躁"
    elseif stress >= 60 then
        bodyDesc = "，眉头紧锁满脸焦虑"
    elseif satiety <= 15 then
        bodyDesc = "，饿得面色发白"
    elseif satiety <= 30 then
        bodyDesc = "，肚子咕咕叫"
    elseif clean <= 20 then
        bodyDesc = "，浑身脏兮兮的"
    elseif clean <= 40 then
        bodyDesc = "，身上有些汗味"
    else
        if fatigue <= 10 and stress <= 10 and satiety >= 70 and clean >= 80 then
            bodyDesc = "，精神饱满容光焕发"
        elseif fatigue <= 30 then
            bodyDesc = "，看起来状态不错"
        else
            bodyDesc = "，神情平淡"
        end
    end

    return name .. outfitDesc .. bodyDesc .. "。"
end

--- 更新状态条的值和颜色
---@param id string 组件ID
---@param value number 当前值（0-100）
---@param statType string 状态类型：satiety/fatigue/stress/cleanliness
function UIManager._updateStatBar(id, value, statType)
    if not ctx.sidebarPanel then return end

    -- 根据状态类型和值计算颜色
    local color
    if statType == "satiety" then
        if value <= 20 then
            color = {255, 80, 80, 255}
        elseif value <= 50 then
            color = {220, 190, 80, 255}
        else
            color = {80, 210, 120, 255}
        end
    elseif statType == "fatigue" then
        if value >= 70 then
            color = {255, 80, 80, 255}
        elseif value >= 40 then
            color = {220, 190, 80, 255}
        else
            color = {80, 210, 120, 255}
        end
    elseif statType == "stress" then
        if value >= 70 then
            color = {255, 80, 80, 255}
        elseif value >= 40 then
            color = {220, 190, 80, 255}
        else
            color = {80, 210, 120, 255}
        end
    elseif statType == "cleanliness" then
        if value <= 20 then
            color = {255, 80, 80, 255}
        elseif value <= 50 then
            color = {200, 180, 100, 255}
        else
            color = {120, 180, 220, 255}
        end
    end

    -- 更新数值文本
    local valueLabel = ctx.sidebarPanel:FindById(id .. "_value")
    if valueLabel then
        valueLabel:SetText(tostring(math.floor(value)))
        valueLabel:SetFontColor(color)
    end

    -- 更新进度条宽度（绝对像素）
    local fillBar = ctx.sidebarPanel:FindById(id .. "_fill")
    if fillBar then
        local sidebarContentW = isMobile and 280 or (200 - 12 * 2)
        local pct = math.max(0, math.min(100, value))
        local fillW = math.floor(sidebarContentW * pct / 100)
        fillBar:SetWidth(fillW)
        fillBar:SetStyle({ backgroundColor = color })
    end
end

--- 更新状态栏
function UIManager.updateStatusBar()
    local S = GameState.state
    if not ctx.statusBar then return end

    local dateLabel = ctx.statusBar:FindById("statusDate")
    local moneyLabel = ctx.statusBar:FindById("statusMoney")

    if dateLabel then
        if S.inPrologue then
            dateLabel:SetText("序章")
        else
            dateLabel:SetText(S.year .. "年" .. S.month .. "月" .. S.day .. "日 "
                .. GameState.getDayOfWeek() .. " " .. GameState.getTimeStr())
        end
    end
    if moneyLabel then
        moneyLabel:SetText(S.inPrologue and "--" or (S.money .. " 金币"))
    end

    -- 同步状态栏标题（地点名 / 游戏标题）
    UIManager._syncStatusTitle()

    -- 同步更新侧边栏
    UIManager.updateSidebar()
end

end -- install function
