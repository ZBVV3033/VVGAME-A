-- ============================================================================
-- UIModals.lua - 弹窗系统（从 UIManager.lua 提取）
-- install 模式：返回一个函数，调用时将方法注入 UIManager
-- 包含：事件弹窗、好感度互动弹窗、好感度回复弹窗
-- ============================================================================

---@param UIManager table  UIManager 模块表
---@param ctx table        共享上下文 { _storyModal, _affectionModal, ... }
---@param cfg table        UIConfig（LAYOUT, COLORS, isMobile）
return function(UIManager, ctx, cfg)

local UI = require("urhox-libs/UI")
local Modal = require("urhox-libs/UI/Widgets/Modal")
local GameState = require("systems.GameState")

local LAYOUT = cfg.LAYOUT
local COLORS = cfg.COLORS
local isMobile = cfg.isMobile

-- ==================== 事件弹窗 ====================

--- 弹窗显示事件内容，点击关闭后渲染选项
---@param paragraphs string[] 段落列表
---@param startIdx number 起始索引
---@param passage table 当前 passage
function UIManager._showStoryModal(paragraphs, startIdx, passage)
    if ctx._storyModal then ctx._storyModal:Close() end

    local choicesRendered = false
    local function renderChoicesOnce()
        if choicesRendered then return end
        choicesRendered = true
        if passage.inputField then
            ctx.inputTarget = passage.inputTarget or ""
            UIManager._showInput(true, "请输入名字...")
        else
            ctx.inputTarget = ""
            UIManager._showInput(false)
        end
        UIManager._renderChoices(passage.choices or {})
    end

    ctx._storyModal = Modal({
        title = ctx.currentLocationName or "事件",
        size = "md",
        closeOnOverlay = true,
        showCloseButton = false,
        onClose = function()
            ctx._storyModal = nil
            renderChoicesOnce()
        end,
    })

    -- 渲染段落内容
    for i = startIdx, #paragraphs do
        local para = paragraphs[i]
        if para:match("^【.+】") then
            ctx._storyModal:AddContent(UI.Label {
                text = para,
                fontSize = isMobile and 21 or 18,
                fontColor = COLORS.accent,
                fontWeight = "bold",
                whiteSpace = "normal",
                width = "100%",
                marginTop = 6,
            })
        elseif para:match("^\u{300c}") or para:match("^\u{201c}") or para:match("^\u{201d}") then
            ctx._storyModal:AddContent(UI.Panel {
                width = "100%",
                paddingLeft = isMobile and 12 or 8,
                borderLeftWidth = 2,
                borderLeftColor = COLORS.accent,
                marginVertical = 3,
                children = {
                    UI.Label {
                        text = "\u{3000}\u{3000}" .. para,
                        fontSize = LAYOUT.fontBody,
                        fontColor = { 200, 220, 255, 255 },
                        whiteSpace = "normal",
                        width = "100%",
                    },
                },
            })
        elseif para:match("^\u{ff08}.+\u{ff09}$") then
            ctx._storyModal:AddContent(UI.Label {
                text = para,
                fontSize = LAYOUT.fontSmall,
                fontColor = COLORS.success,
                textAlign = "center",
                width = "100%",
                marginVertical = 3,
            })
        elseif para:match("^━") then
            ctx._storyModal:AddContent(UI.Divider {
                orientation = "horizontal",
                color = COLORS.divider,
                spacing = 4,
            })
        else
            ctx._storyModal:AddContent(UI.Label {
                text = "\u{3000}\u{3000}" .. para,
                fontSize = LAYOUT.fontBody,
                fontColor = COLORS.text,
                whiteSpace = "normal",
                width = "100%",
                marginVertical = 2,
            })
        end
    end

    -- 底部继续按钮
    ctx._storyModal:AddContent(UI.Button {
        text = "继续",
        width = "100%",
        height = LAYOUT.btnHeight,
        fontSize = LAYOUT.fontLabel,
        backgroundColor = COLORS.accent,
        textColor = { 255, 255, 255, 255 },
        hoverBackgroundColor = COLORS.accentHover,
        pressedBackgroundColor = COLORS.accentPress,
        borderRadius = 8,
        marginTop = 12,
        onClick = function(self)
            ctx._storyModal:Close()
        end,
    })

    ctx._storyModal:Open()
end

-- ==================== 好感度互动弹窗 ====================

--- 好感度互动弹窗（约会等场景）
---@param passage table 包含 text, choices(含reply/affection), modalTitle
function UIManager._showAffectionModal(passage)
    if ctx._affectionModal then ctx._affectionModal:Close() end

    local title = passage.modalTitle or "互动"
    local text = passage.text or ""
    local paragraphs = UIManager._splitText(text)

    ctx._affectionModal = Modal({
        title = title,
        size = "md",
        closeOnOverlay = false,
        showCloseButton = false,
        onClose = function()
            ctx._affectionModal = nil
        end,
    })

    -- 渲染场景描述段落
    for _, para in ipairs(paragraphs) do
        if para:match("^【.+】") then
            ctx._affectionModal:AddContent(UI.Label {
                text = para,
                fontSize = isMobile and 21 or 18,
                fontColor = COLORS.accent,
                fontWeight = "bold",
                whiteSpace = "normal",
                width = "100%",
                marginTop = 6,
            })
        elseif para:match("^\u{300c}") or para:match("^\u{201c}") then
            ctx._affectionModal:AddContent(UI.Panel {
                width = "100%",
                paddingLeft = isMobile and 12 or 8,
                borderLeftWidth = 2,
                borderLeftColor = COLORS.accent,
                marginVertical = 3,
                children = {
                    UI.Label {
                        text = "\u{3000}\u{3000}" .. para,
                        fontSize = LAYOUT.fontBody,
                        fontColor = { 200, 220, 255, 255 },
                        whiteSpace = "normal",
                        width = "100%",
                    },
                },
            })
        else
            ctx._affectionModal:AddContent(UI.Label {
                text = "\u{3000}\u{3000}" .. para,
                fontSize = LAYOUT.fontBody,
                fontColor = COLORS.text,
                whiteSpace = "normal",
                width = "100%",
                marginVertical = 2,
            })
        end
    end

    -- 分隔线
    ctx._affectionModal:AddContent(UI.Divider {
        orientation = "horizontal",
        color = COLORS.divider,
        spacing = 8,
    })

    -- 提示文字
    ctx._affectionModal:AddContent(UI.Label {
        text = "你想说什么？",
        fontSize = LAYOUT.fontSmall,
        fontColor = COLORS.textDim,
        textAlign = "center",
        width = "100%",
        marginBottom = 6,
    })

    -- 渲染互动选项按钮
    for _, choice in ipairs(passage.choices or {}) do
        local affLabel = ""
        if choice.affection then
            affLabel = "  ❤️+" .. choice.affection
        end

        ctx._affectionModal:AddContent(UI.Button {
            text = choice.text .. affLabel,
            width = "100%",
            height = "auto",
            minHeight = LAYOUT.btnHeight,
            fontSize = LAYOUT.fontLabel,
            whiteSpace = "normal",
            paddingVertical = 8,
            backgroundColor = { 80, 50, 70, 255 },
            textColor = COLORS.text,
            hoverBackgroundColor = { 110, 70, 90, 255 },
            pressedBackgroundColor = { 65, 40, 55, 255 },
            borderRadius = 8,
            marginBottom = 6,
            onClick = function(self)
                ctx._affectionModal:Close()
                ctx._affectionModal = nil

                if choice.reply then
                    UIManager._showAffectionReply(passage.modalTitle or "互动", choice)
                else
                    UIManager._onChoiceSelected(choice)
                end
            end,
        })
    end

    ctx._affectionModal:Open()
end

-- ==================== 好感度回复弹窗 ====================

--- 好感度互动回复弹窗（展示角色回复后执行 action）
---@param title string 弹窗标题
---@param choice table 选项数据（含 reply, action 等）
function UIManager._showAffectionReply(title, choice)
    local replyModal = Modal({
        title = title,
        size = "sm",
        closeOnOverlay = true,
        showCloseButton = false,
        onClose = function()
            UIManager._onChoiceSelected(choice)
        end,
    })

    -- 角色回复内容
    replyModal:AddContent(UI.Panel {
        width = "100%",
        paddingLeft = isMobile and 12 or 8,
        borderLeftWidth = 2,
        borderLeftColor = { 255, 180, 200, 255 },
        marginVertical = 6,
        children = {
            UI.Label {
                text = "\u{3000}\u{3000}" .. choice.reply,
                fontSize = LAYOUT.fontBody,
                fontColor = { 255, 220, 230, 255 },
                whiteSpace = "normal",
                width = "100%",
            },
        },
    })

    -- 好感度变化提示
    if choice.affection then
        replyModal:AddContent(UI.Label {
            text = "❤️ 好感度 +" .. choice.affection,
            fontSize = LAYOUT.fontSmall,
            fontColor = { 255, 150, 180, 255 },
            textAlign = "center",
            width = "100%",
            marginTop = 8,
        })
    end

    -- 继续按钮
    replyModal:AddContent(UI.Button {
        text = "继续",
        width = "100%",
        height = LAYOUT.btnHeight,
        fontSize = LAYOUT.fontLabel,
        backgroundColor = { 120, 70, 100, 255 },
        textColor = { 255, 255, 255, 255 },
        hoverBackgroundColor = { 150, 90, 120, 255 },
        pressedBackgroundColor = { 100, 55, 80, 255 },
        borderRadius = 8,
        marginTop = 10,
        onClick = function(self)
            replyModal:Close()
        end,
    })

    replyModal:Open()
end

end -- install function
