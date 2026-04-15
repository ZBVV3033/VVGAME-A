-- ============================================================================
-- UIChoices.lua - 选项系统（从 UIManager.lua 提取）
-- install 模式：返回一个函数，调用时将方法注入 UIManager
-- 包含：选项过滤/分组/折叠、选项弹窗、选项按钮构建、选项点击处理
-- ============================================================================

---@param UIManager table  UIManager 模块表
---@param ctx table        共享上下文
---@param cfg table        UIConfig（LAYOUT, COLORS, isMobile）
return function(UIManager, ctx, cfg)

local UI = require("urhox-libs/UI")
local Modal = require("urhox-libs/UI/Widgets/Modal")
local GameState = require("systems.GameState")

local LAYOUT = cfg.LAYOUT
local COLORS = cfg.COLORS
local isMobile = cfg.isMobile

-- ==================== 辅助函数 ====================

--- 检测选项列表中是否存在长文本（utf8.len > 9）
---@param validChoices table[]
---@return boolean
function UIManager._hasLongChoice(validChoices)
    for _, c in ipairs(validChoices) do
        if c.group then
            for _, child in ipairs(c.children or {}) do
                if utf8.len(child.text or "") > 9 then return true end
            end
        else
            if utf8.len(c.text or "") > 9 then return true end
        end
    end
    return false
end

--- 获取选项按钮的颜色配置
---@param choice table
---@return table, table, table, table
function UIManager._getChoiceColors(choice)
    local btnColor = COLORS.btnBg
    local textColor = COLORS.text
    local hoverColor = COLORS.btnHover
    local pressColor = COLORS.btnPress

    local txt = choice.text or ""
    if txt:match("⚔️") or txt:match("迎战") then
        btnColor = { 150, 50, 50, 255 }
        hoverColor = { 180, 70, 70, 255 }
        pressColor = { 120, 40, 40, 255 }
    elseif txt:match("🔙") or txt:match("返回") or txt:match("离开") then
        btnColor = { 60, 55, 80, 255 }
        hoverColor = { 80, 75, 100, 255 }
    elseif txt:match("💰") or txt:match("买") then
        btnColor = { 100, 80, 30, 255 }
        hoverColor = { 130, 110, 50, 255 }
    end
    return btnColor, textColor, hoverColor, pressColor
end

-- ==================== 弹窗选择 ====================

--- 弹窗显示选项列表（手机端长选项时使用）
function UIManager._showChoiceModal(validChoices)
    if ctx._choiceModal then ctx._choiceModal:Close() end

    ctx._choiceModal = Modal({
        title = "请选择",
        size = "md",
        closeOnOverlay = false,
        showCloseButton = false,
    })

    for _, choice in ipairs(validChoices) do
        if choice.group then
            -- 分组标题
            ctx._choiceModal:AddContent(UI.Label {
                text = (choice.icon and (choice.icon .. " ") or "") .. choice.group
                    .. "（" .. #choice.children .. "）",
                fontSize = LAYOUT.fontLabel,
                fontColor = COLORS.textDim,
                marginTop = 8,
                marginBottom = 4,
            })
            -- 分组子选项
            for _, child in ipairs(choice.children) do
                local bc, tc, hc, pc = UIManager._getChoiceColors(child)
                ctx._choiceModal:AddContent(UI.Button {
                    text = child.text,
                    width = "100%",
                    height = "auto",
                    minHeight = LAYOUT.btnHeight,
                    fontSize = LAYOUT.fontLabel,
                    whiteSpace = "normal",
                    paddingVertical = 8,
                    backgroundColor = bc,
                    textColor = tc,
                    hoverBackgroundColor = hc,
                    pressedBackgroundColor = pc,
                    borderRadius = 6,
                    marginBottom = 4,
                    onClick = function(self)
                        ctx._choiceModal:Close()
                        ctx._choiceModal = nil
                        UIManager._onChoiceSelected(child)
                    end,
                })
            end
        else
            -- 普通选项
            local bc, tc, hc, pc = UIManager._getChoiceColors(choice)
            ctx._choiceModal:AddContent(UI.Button {
                text = choice.text,
                width = "100%",
                height = "auto",
                minHeight = LAYOUT.btnHeight,
                fontSize = LAYOUT.fontLabel,
                whiteSpace = "normal",
                paddingVertical = 8,
                backgroundColor = bc,
                textColor = tc,
                hoverBackgroundColor = hc,
                pressedBackgroundColor = pc,
                borderRadius = 8,
                marginBottom = 4,
                onClick = function(self)
                    ctx._choiceModal:Close()
                    ctx._choiceModal = nil
                    UIManager._onChoiceSelected(choice)
                end,
            })
        end
    end

    ctx._choiceModal:Open()
end

-- ==================== 选项渲染 ====================

--- 渲染选项按钮
---@param choices table[]
function UIManager._renderChoices(choices)
    local choicesPanel = ctx.choicesPanel
    if not choicesPanel then return end
    choicesPanel:ClearChildren()

    local validChoices = {}
    for _, choice in ipairs(choices) do
        if choice.group then
            -- 分组：过滤子选项
            local validChildren = {}
            for _, child in ipairs(choice.children or {}) do
                if not child.condition or child.condition() then
                    table.insert(validChildren, child)
                end
            end
            if #validChildren > 0 then
                table.insert(validChoices, {
                    group = choice.group,
                    children = validChildren,
                    expanded = choice.expanded,
                    icon = choice.icon,
                })
            end
        else
            -- 普通选项
            if not choice.condition or choice.condition() then
                table.insert(validChoices, choice)
            end
        end
    end

    if #validChoices == 0 then
        return
    end

    -- 手机端：有长选项时改用弹窗选择
    if isMobile and UIManager._hasLongChoice(validChoices) then
        local openBtn = UI.Button {
            text = "📋 查看选项",
            width = "100%",
            height = LAYOUT.btnHeight,
            fontSize = LAYOUT.fontLabel,
            backgroundColor = COLORS.accent,
            textColor = { 255, 255, 255, 255 },
            hoverBackgroundColor = COLORS.accentHover,
            pressedBackgroundColor = COLORS.accentPress,
            borderRadius = 8,
            onClick = function(self)
                UIManager._showChoiceModal(validChoices)
            end,
        }
        choicesPanel:AddChild(openBtn)
        -- 首次自动弹出
        UIManager._showChoiceModal(validChoices)
        return
    end

    local expandedGroups = ctx.expandedGroups
    for i, choice in ipairs(validChoices) do
        if choice.group then
            -- ===== 渲染分组标题 =====
            local groupKey = choice.group
            -- 初始化展开状态（默认用 choice.expanded，若未指定则折叠）
            if expandedGroups[groupKey] == nil then
                expandedGroups[groupKey] = choice.expanded or false
            end
            local isExpanded = expandedGroups[groupKey]
            local arrow = isExpanded and "▼ " or "▶ "
            local icon = choice.icon and (choice.icon .. " ") or ""
            local groupText = arrow .. icon .. groupKey
                .. "（" .. #choice.children .. "）"

            local groupBtn = UI.Button {
                text = groupText,
                width = "100%",
                height = LAYOUT.btnHeight,
                fontSize = LAYOUT.fontLabel,
                backgroundColor = { 55, 50, 75, 255 },
                textColor = { 200, 195, 220, 255 },
                hoverBackgroundColor = { 70, 65, 90, 255 },
                pressedBackgroundColor = { 45, 40, 65, 255 },
                borderRadius = 8,
                onClick = function(self)
                    expandedGroups[groupKey] = not expandedGroups[groupKey]
                    UIManager._renderChoices(choices)
                end,
            }
            choicesPanel:AddChild(groupBtn)

            -- ===== 展开时渲染子选项 =====
            if isExpanded then
                for _, child in ipairs(choice.children) do
                    local btn = UIManager._buildChoiceButton(child, true)
                    choicesPanel:AddChild(btn)
                end
            end
        else
            -- ===== 渲染普通选项 =====
            local btn = UIManager._buildChoiceButton(choice, false)
            choicesPanel:AddChild(btn)
        end
    end
end

--- 构建单个选项按钮
---@param choice table 选项数据
---@param indented boolean 是否为子选项（缩进显示）
---@return table UI按钮组件
function UIManager._buildChoiceButton(choice, indented)
    local btnColor = COLORS.btnBg
    local textColor = COLORS.text
    local hoverColor = COLORS.btnHover
    local pressColor = COLORS.btnPress

    local txt = choice.text
    if txt:match("⚔️") or txt:match("迎战") then
        btnColor = { 150, 50, 50, 255 }
        hoverColor = { 180, 70, 70, 255 }
        pressColor = { 120, 40, 40, 255 }
    elseif txt:match("🔙") or txt:match("返回") or txt:match("离开") then
        btnColor = { 60, 55, 80, 255 }
        hoverColor = { 80, 75, 100, 255 }
    elseif txt:match("💰") or txt:match("买") then
        btnColor = { 100, 80, 30, 255 }
        hoverColor = { 130, 110, 50, 255 }
    end

    -- 子选项用略深的底色 + 左侧缩进
    if indented then
        btnColor = { btnColor[1] - 5, btnColor[2] - 5, btnColor[3] - 5, btnColor[4] or 255 }
        txt = "  " .. txt
    end

    return UI.Button {
        text = txt,
        width = "100%",
        height = "auto",
        minHeight = LAYOUT.btnHeight,
        fontSize = LAYOUT.fontLabel,
        whiteSpace = "normal",
        paddingVertical = 8,
        backgroundColor = btnColor,
        textColor = textColor,
        hoverBackgroundColor = hoverColor,
        pressedBackgroundColor = pressColor,
        borderRadius = indented and 6 or 8,
        marginLeft = indented and 12 or 0,
        onClick = function(self)
            UIManager._onChoiceSelected(choice)
        end,
    }
end

-- ==================== 选项点击处理 ====================

--- 选项点击处理
---@param choice table
function UIManager._onChoiceSelected(choice)
    -- 如果有输入框，先保存输入
    if ctx.inputTarget ~= "" and ctx.inputValue ~= "" then
        local S = GameState.state
        S[ctx.inputTarget] = ctx.inputValue
        ctx.inputTarget = ""
    end

    -- 执行 action（返回值可作为导航目标）
    local actionTarget = nil
    if choice.action then
        actionTarget = choice.action()
    end

    -- 导航到目标：优先使用 action 返回值（动态），其次使用 choice.target（静态）
    local navTarget = actionTarget or choice.target
    if navTarget then
        UIManager.navigate(navTarget)
    end
end

end -- installer
