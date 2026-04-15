-- ============================================================================
-- ChatUI.lua - AI 自由对话 UI 模块（从 UIManager 提取）
-- 负责：AI 聊天覆盖层的构建、消息气泡、发送/接收、快捷话题
-- ============================================================================

local UI = require("urhox-libs/UI")
local GameState = require("systems.GameState")

local ChatUI = {}

-- ==================== 内部状态 ====================

local _chatClient = nil          -- ChatClient 模块引用
local _chatOverlay = nil         -- 聊天覆盖层
local _chatMessagesPanel = nil   -- 消息容器
local _chatScroll = nil          -- 消息滚动区
local _chatInput = nil           -- 输入框
local _chatSendBtn = nil         -- 发送按钮
local _chatThinking = nil        -- "思考中"提示
local _chatQuotaLabel = nil      -- 剩余次数标签
local _chatTitleLabel = nil      -- 标题标签（"与 X 对话"）
local _chatCharName = nil        -- 当前对话角色名
local _chatOpen = false          -- 聊天面板是否打开
local _chatBuilt = false         -- 聊天 UI 是否已预构建
local _chatMessages = {}         -- 当前对话消息列表 {role, text}
local _chatInputValue = ""       -- 输入框当前值
local _chatCharCountLabel = nil  -- 输入字数计数标签
local _chatQuickPanel = nil      -- 快捷话题面板
local _chatWelcomePanel = nil    -- 欢迎消息面板
local CHAT_MAX_CHARS = 100       -- 单条消息最大字数

-- 由 init() 注入的依赖
local LAYOUT = nil
local COLORS = nil
local isMobile = false
local _safeRoot = nil
local _showNotification = nil    -- function(msg) 显示通知的回调
local _getLocationName = nil     -- function() 获取当前地点名的回调

-- 角色 emoji / 颜色配置
local CHAR_CONFIG = {
    ["莱德"] = { emoji = "🗡️", color = { 100, 140, 180, 255 }, bubbleColor = { 40, 55, 75, 255 } },
    ["K"]    = { emoji = "🌿", color = { 140, 200, 160, 255 }, bubbleColor = { 40, 65, 50, 255 } },
    ["威廉"] = { emoji = "🎭", color = { 180, 140, 180, 255 }, bubbleColor = { 60, 45, 65, 255 } },
}

-- 角色快捷话题
local CHAR_QUICK_TOPICS = {
    ["莱德"] = {
        "今天在港口搬了多少货？",
        "你昨晚练剑练到几点？",
        "帐篷里冬天冷不冷？",
        "你来艾瑟顿镇之前在哪？",
    },
    ["K"] = {
        "今天调了什么新酒？",
        "你耳边那朵花是新摘的吗？",
        "精灵的世界是什么样的？",
        "辛奇老板对你好不好？",
    },
    ["威廉"] = {
        "书桌上那把匕首有什么来历？",
        "壁炉边的红茶还有吗？",
        "最近贫民窟太平吗？",
        "天台的烟抽完了没有？",
    },
}

-- 角色欢迎语
local CHAR_WELCOME = {
    ["莱德"] = "「有事？……没事也行，随便待着吧。」",
    ["K"]    = "「哇你来得正好！我刚想找人说话呢～」",
    ["威廉"] = "「说吧，什么事。」",
}

-- ==================== 初始化 ====================

--- 初始化 ChatUI 模块，注入必要的依赖
---@param deps table { layout, colors, isMobile, safeRoot, showNotification }
function ChatUI.init(deps)
    LAYOUT = deps.layout
    COLORS = deps.colors
    isMobile = deps.isMobile or false
    _safeRoot = deps.safeRoot
    _showNotification = deps.showNotification
    _getLocationName = deps.getLocationName
end

-- ==================== 公共接口 ====================

--- 注入 ChatClient 模块
---@param client table ChatClient 模块
function ChatUI.setChatClient(client)
    _chatClient = client
    client.onMessageReceived = function(charName, reply, remaining)
        ChatUI._onChatReply(charName, reply, remaining)
    end
    -- 预构建聊天 UI（隐藏状态），后续打开只需切换可见性
    if not _chatBuilt then
        ChatUI._buildChatOverlay()
    end
    log:Write(LOG_INFO, "[ChatUI] ChatClient injected, chat UI pre-built")
end

--- 检查聊天面板是否打开
---@return boolean
function ChatUI.isChatOpen()
    return _chatOpen
end

--- 检查是否可以使用 AI 对话（ChatClient 已注入且已连接）
---@return boolean
function ChatUI.canChat()
    return _chatClient ~= nil and _chatClient.connected
end

--- 打开 AI 对话面板
---@param charName string 角色名（莱德/K/威廉）
function ChatUI.openChat(charName)
    if not _chatClient then
        if _showNotification then
            _showNotification("AI 对话功能需要多人模式，当前为单机模式。")
        end
        return
    end
    if not _chatClient.connected then
        if _showNotification then
            _showNotification("服务器连接中，连接成功后会通知你～")
        end
        return
    end

    _chatCharName = charName
    _chatMessages = {}
    _chatInputValue = ""
    _chatOpen = true

    -- UI 已预构建，只需更新内容并显示
    if not _chatBuilt then
        ChatUI._buildChatOverlay()
    end

    local charCfg = CHAR_CONFIG[charName] or { emoji = "💬", color = COLORS.accent, bubbleColor = { 50, 50, 68, 255 } }

    -- 更新标题（带角色 emoji）
    if _chatTitleLabel then
        _chatTitleLabel:SetText(charCfg.emoji .. " 与 " .. charName .. " 对话")
    end

    -- 清空历史消息气泡
    if _chatMessagesPanel then
        _chatMessagesPanel:RemoveAllChildren()

        -- 添加欢迎消息
        local welcome = CHAR_WELCOME[charName]
        if welcome then
            _chatMessagesPanel:AddChild(UI.Panel {
                width = "100%",
                alignItems = "center",
                paddingVertical = 12,
                children = {
                    UI.Panel {
                        maxWidth = "90%",
                        backgroundColor = { 45, 45, 60, 200 },
                        borderRadius = 12,
                        padding = 12,
                        borderLeftWidth = 3,
                        borderLeftColor = charCfg.color,
                        children = {
                            UI.Label {
                                text = "🎬 " .. welcome,
                                fontSize = LAYOUT.fontSmall,
                                fontColor = COLORS.textDim,
                                whiteSpace = "normal",
                                width = "100%",
                                textAlign = "center",
                            },
                        },
                    },
                },
            })
        end
    end

    -- 显示快捷话题
    if _chatQuickPanel then
        _chatQuickPanel:RemoveAllChildren()
        local topics = CHAR_QUICK_TOPICS[charName] or {}
        for _, topic in ipairs(topics) do
            _chatQuickPanel:AddChild(UI.Button {
                text = topic,
                fontSize = LAYOUT.fontSmall,
                height = isMobile and 38 or 30,
                paddingHorizontal = 12,
                backgroundColor = { 50, 50, 70, 255 },
                textColor = charCfg.color,
                hoverBackgroundColor = { 65, 65, 85, 255 },
                pressedBackgroundColor = { 40, 40, 58, 255 },
                borderRadius = 15,
                borderWidth = 1,
                borderColor = { charCfg.color[1], charCfg.color[2], charCfg.color[3], 80 },
                onClick = function(self)
                    _chatInputValue = topic
                    if _chatInput then
                        _chatInput:SetValue(topic)
                    end
                    ChatUI._sendChatMessage()
                end,
            })
        end
        _chatQuickPanel:SetVisible(true)
    end

    -- 重置输入框
    if _chatInput then
        _chatInput:SetValue("")
        _chatInput:SetEnabled(true)
    end
    if _chatSendBtn then
        _chatSendBtn:SetEnabled(true)
    end
    if _chatCharCountLabel then
        _chatCharCountLabel:SetText("0/" .. CHAT_MAX_CHARS)
        _chatCharCountLabel:SetFontColor(COLORS.textDim)
    end

    -- 隐藏思考中
    if _chatThinking then
        _chatThinking:SetVisible(false)
    end

    -- 更新剩余次数
    if _chatQuotaLabel then
        local rc = (_chatClient and _chatClient.remaining >= 0) and _chatClient.remaining or "?"
        _chatQuotaLabel:SetText("本周剩余：" .. tostring(rc) .. "/50")
        if rc ~= "?" and rc <= 5 then
            _chatQuotaLabel:SetFontColor({ 255, 160, 120, 255 })
        else
            _chatQuotaLabel:SetFontColor({ 160, 190, 230, 255 })
        end
    end

    -- 显示覆盖层
    if _chatOverlay then
        _chatOverlay:SetVisible(true)
    end

    log:Write(LOG_INFO, "[ChatUI] Chat opened with: " .. charName)
end

--- 关闭 AI 对话面板
function ChatUI.closeChat()
    _chatOpen = false
    -- 只隐藏，不销毁（预构建复用）
    if _chatOverlay then
        _chatOverlay:SetVisible(false)
    end
    log:Write(LOG_INFO, "[ChatUI] Chat closed")
end

--- 清理聊天 UI 状态
function ChatUI.shutdown()
    if _chatOpen then
        ChatUI.closeChat()
    end
    _chatClient = nil
    _chatOverlay = nil
    _chatMessagesPanel = nil
    _chatScroll = nil
    _chatInput = nil
    _chatSendBtn = nil
    _chatThinking = nil
    _chatQuotaLabel = nil
    _chatTitleLabel = nil
    _chatCharCountLabel = nil
    _chatQuickPanel = nil
    _chatWelcomePanel = nil
    _chatBuilt = false
    _chatMessages = {}
    _chatCharName = nil
    _chatOpen = false
    _chatInputValue = ""
end

-- ==================== 内部方法 ====================

--- 构建当前游戏上下文 JSON（供发送消息时使用）
---@return string JSON 字符串
function ChatUI._buildGameContext()
    local S = GameState.state
    if not S then return "" end

    local ctx = {}

    -- 好感度等级
    if _chatCharName == "莱德" or _chatCharName == S.initialName then
        ctx.affectionLevel = S.initialNameLevel or 1
    elseif _chatCharName == "K" then
        ctx.affectionLevel = S.kLevel or 1
    elseif _chatCharName == "威廉" then
        ctx.affectionLevel = S.gangBossLevel or 1
    end

    -- 当前位置
    local locName = _getLocationName and _getLocationName()
    if locName then
        ctx.location = locName
    end

    -- 游戏时间
    if S.day then
        local timeStr = "第" .. S.day .. "天"
        if S.hour then
            timeStr = timeStr .. string.format(" %02d:%02d", S.hour, S.minute or 0)
        end
        ctx.dayTime = timeStr
    end

    -- 玩家名字（如果有）
    if S.PNN and S.PNN ~= "" then
        ctx.playerName = S.PNN
    end

    ---@diagnostic disable-next-line: undefined-global
    local ok, json = pcall(cjson.encode, ctx)
    return ok and json or ""
end

--- 预构建聊天覆盖层 UI（初始隐藏，后续 openChat 时只切换可见性）
function ChatUI._buildChatOverlay()
    -- 防止重复构建
    if _chatBuilt then return end

    -- 消息面板
    _chatMessagesPanel = UI.Panel {
        id = "chatMsgPanel",
        width = "100%",
        padding = 12,
        gap = 8,
    }

    -- 消息滚动区
    _chatScroll = UI.ScrollView {
        id = "chatScroll",
        width = "100%",
        flexGrow = 1,
        flexBasis = 0,
        scrollY = true,
        showScrollbar = true,
        bounces = true,
        children = { _chatMessagesPanel },
    }

    -- 快捷话题面板（水平滚动，openChat 时动态填充）
    _chatQuickPanel = UI.Panel {
        id = "chatQuickPanel",
        width = "100%",
        flexDirection = "row",
        flexWrap = "wrap",
        paddingHorizontal = 12,
        paddingVertical = 8,
        gap = 6,
        visible = false,
    }

    -- "思考中"提示（带动画效果）
    _chatThinking = UI.Panel {
        id = "chatThinking",
        width = "100%",
        paddingHorizontal = 16,
        paddingVertical = 8,
        visible = false,
        children = {
            UI.Panel {
                flexDirection = "row",
                alignItems = "center",
                gap = 8,
                children = {
                    UI.Panel {
                        width = 32, height = 32,
                        borderRadius = 16,
                        backgroundColor = { 50, 50, 68, 255 },
                        justifyContent = "center",
                        alignItems = "center",
                        children = {
                            UI.Label {
                                text = "💭",
                                fontSize = LAYOUT.fontSmall,
                            },
                        },
                    },
                    UI.Label {
                        text = "正在思考中...",
                        fontSize = LAYOUT.fontSmall,
                        fontColor = COLORS.textDim,
                    },
                },
            },
        },
    }

    -- 字数计数标签
    _chatCharCountLabel = UI.Label {
        text = "0/" .. CHAT_MAX_CHARS,
        fontSize = LAYOUT.fontStat,
        fontColor = COLORS.textDim,
        marginRight = 4,
    }

    -- 输入行
    _chatInput = UI.TextField {
        id = "chatInput",
        value = "",
        placeholder = "输入你想说的话...",
        flexGrow = 1,
        height = isMobile and 48 or 40,
        fontSize = LAYOUT.fontBody,
        onChange = function(self, value)
            -- 字数限制
            if utf8.len(value) and utf8.len(value) > CHAT_MAX_CHARS then
                -- 截断到最大字数
                local count = 0
                for p, c in utf8.codes(value) do
                    count = count + 1
                    if count > CHAT_MAX_CHARS then
                        value = value:sub(1, p - 1)
                        self:SetValue(value)
                        break
                    end
                end
            end
            _chatInputValue = value
            -- 更新字数显示
            local len = utf8.len(value) or 0
            if _chatCharCountLabel then
                _chatCharCountLabel:SetText(len .. "/" .. CHAT_MAX_CHARS)
                if len >= CHAT_MAX_CHARS then
                    _chatCharCountLabel:SetFontColor({ 255, 120, 100, 255 })
                elseif len > CHAT_MAX_CHARS * 0.8 then
                    _chatCharCountLabel:SetFontColor({ 255, 200, 120, 255 })
                else
                    _chatCharCountLabel:SetFontColor(COLORS.textDim)
                end
            end
        end,
        onSubmit = function(self, value)
            _chatInputValue = value
            ChatUI._sendChatMessage()
        end,
    }

    _chatSendBtn = UI.Button {
        id = "chatSendBtn",
        text = "发送",
        width = isMobile and 72 or 64,
        height = isMobile and 48 or 40,
        fontSize = LAYOUT.fontLabel,
        backgroundColor = COLORS.accent,
        textColor = { 255, 255, 255, 255 },
        hoverBackgroundColor = COLORS.accentHover,
        pressedBackgroundColor = COLORS.accentPress,
        borderRadius = 8,
        onClick = function(self)
            ChatUI._sendChatMessage()
        end,
    }

    local inputRow = UI.Panel {
        width = "100%",
        flexDirection = "column",
        backgroundColor = COLORS.statusBg,
        borderTopWidth = 1,
        borderTopColor = COLORS.divider,
        children = {
            -- 字数计数行
            UI.Panel {
                width = "100%",
                flexDirection = "row",
                justifyContent = "flex-end",
                paddingHorizontal = 12,
                paddingTop = 4,
                children = { _chatCharCountLabel },
            },
            -- 输入框 + 发送按钮
            UI.Panel {
                width = "100%",
                flexDirection = "row",
                alignItems = "center",
                paddingHorizontal = 8,
                paddingBottom = 8,
                gap = 8,
                children = { _chatInput, _chatSendBtn },
            },
        },
    }

    -- 关闭按钮
    local closeBtnSize = isMobile and 44 or 36
    local closeBtn = UI.Button {
        text = "✕",
        width = closeBtnSize,
        height = closeBtnSize,
        fontSize = isMobile and 22 or 18,
        backgroundColor = { 0, 0, 0, 0 },
        textColor = COLORS.textDim,
        hoverBackgroundColor = { 255, 255, 255, 20 },
        pressedBackgroundColor = { 255, 255, 255, 10 },
        borderRadius = closeBtnSize / 2,
        onClick = function(self)
            ChatUI.closeChat()
        end,
    }

    -- 头部标题（保留引用，openChat 时动态更新文本）
    _chatTitleLabel = UI.Label {
        text = "对话",
        fontSize = LAYOUT.fontTitle,
        fontColor = COLORS.textTitle,
        fontWeight = "bold",
    }

    local header = UI.Panel {
        width = "100%",
        flexDirection = "row",
        justifyContent = "space-between",
        alignItems = "center",
        paddingHorizontal = 16,
        paddingVertical = 10,
        backgroundColor = COLORS.statusBg,
        borderBottomWidth = 1,
        borderBottomColor = COLORS.divider,
        children = {
            _chatTitleLabel,
            closeBtn,
        },
    }

    -- 剩余次数显示
    local remainingCount = (_chatClient and _chatClient.remaining >= 0) and _chatClient.remaining or "?"
    _chatQuotaLabel = UI.Label {
        text = "本周剩余：" .. tostring(remainingCount) .. "/50",
        fontSize = LAYOUT.fontSmall,
        fontColor = (remainingCount ~= "?" and remainingCount <= 5) and { 255, 160, 120, 255 } or { 160, 190, 230, 255 },
    }

    -- 连接状态与配额提示
    local hintPanel = UI.Panel {
        width = "100%",
        paddingHorizontal = 16,
        paddingVertical = 6,
        backgroundColor = { 35, 40, 55, 230 },
        flexDirection = "row",
        justifyContent = "space-between",
        alignItems = "center",
        children = {
            UI.Label {
                text = "✨ AI 驱动 · 自由对话",
                fontSize = LAYOUT.fontStat,
                fontColor = { 140, 160, 200, 200 },
            },
            _chatQuotaLabel,
        },
    }

    -- 聊天容器（卡片式）
    local chatCard = UI.Panel {
        width = isMobile and "100%" or "75%",
        height = isMobile and "100%" or "85%",
        maxWidth = 600,
        backgroundColor = COLORS.bgPanel,
        borderRadius = isMobile and 0 or 12,
        flexDirection = "column",
        overflow = "hidden",
        children = {
            header,
            hintPanel,
            _chatScroll,
            _chatQuickPanel,
            _chatThinking,
            inputRow,
        },
    }

    -- 整体覆盖层（初始隐藏，openChat 时显示）
    _chatOverlay = UI.Panel {
        id = "chatOverlay",
        position = "absolute",
        left = 0, top = 0,
        width = "100%",
        height = "100%",
        backgroundColor = { 0, 0, 0, 160 },
        justifyContent = "center",
        alignItems = "center",
        zIndex = 80,
        visible = false,
        children = { chatCard },
    }

    -- 添加到 safeRoot
    if _safeRoot then
        _safeRoot:AddChild(_chatOverlay)
    end

    _chatBuilt = true
    log:Write(LOG_INFO, "[ChatUI] Chat UI pre-built (hidden)")
end

--- 发送聊天消息
function ChatUI._sendChatMessage()
    if not _chatClient or not _chatCharName then return end
    local msg = _chatInputValue
    if not msg or msg == "" then return end

    -- 防止重复发送（等待回复中）
    if _chatClient.waiting then return end

    -- 清空输入框
    if _chatInput then
        _chatInput:SetValue("")
    end
    _chatInputValue = ""
    if _chatCharCountLabel then
        _chatCharCountLabel:SetText("0/" .. CHAT_MAX_CHARS)
        _chatCharCountLabel:SetFontColor(COLORS.textDim)
    end

    -- 隐藏快捷话题（已开始对话）
    if _chatQuickPanel then
        _chatQuickPanel:SetVisible(false)
    end

    -- 添加用户消息气泡
    table.insert(_chatMessages, { role = "user", text = msg })
    ChatUI._addChatBubble("user", msg)

    -- 显示"思考中"
    if _chatThinking then
        _chatThinking:SetVisible(true)
    end

    -- 禁用发送按钮和输入框
    if _chatSendBtn then
        _chatSendBtn:SetEnabled(false)
    end
    if _chatInput then
        _chatInput:SetEnabled(false)
    end

    -- 构建游戏上下文
    local contextJson = ChatUI._buildGameContext()

    -- 发送到服务端（附带游戏上下文）
    local ok = _chatClient.sendMessage(_chatCharName, msg, contextJson)
    if not ok then
        ChatUI._addChatBubble("system", "（发送失败，请检查网络连接）")
        if _chatThinking then _chatThinking:SetVisible(false) end
        if _chatSendBtn then _chatSendBtn:SetEnabled(true) end
        if _chatInput then _chatInput:SetEnabled(true) end
    end

    -- 滚动到底部
    if _chatScroll then
        _chatScroll:ScrollToBottom()
    end
end

--- 收到 AI 回复
---@param charName string
---@param reply string
---@param remaining number 本周剩余对话次数
function ChatUI._onChatReply(charName, reply, remaining)
    if not _chatOpen then return end

    -- 隐藏"思考中"
    if _chatThinking then
        _chatThinking:SetVisible(false)
    end

    -- 更新剩余次数显示
    if _chatQuotaLabel and remaining then
        _chatQuotaLabel:SetText("本周剩余对话：" .. remaining .. " / 50")
        if remaining <= 5 then
            _chatQuotaLabel:SetFontColor({ 255, 160, 120, 255 })
        end
    end

    -- 根据剩余次数决定是否禁用输入
    if remaining and remaining <= 0 then
        -- 次数耗尽，禁用输入
        if _chatInput then _chatInput:SetEnabled(false) end
        if _chatSendBtn then _chatSendBtn:SetEnabled(false) end
    else
        -- 启用发送按钮和输入框
        if _chatSendBtn then _chatSendBtn:SetEnabled(true) end
        if _chatInput then _chatInput:SetEnabled(true) end
    end

    -- 添加 AI 回复气泡
    table.insert(_chatMessages, { role = "assistant", text = reply })
    ChatUI._addChatBubble("assistant", reply)

    -- 滚动到底部
    if _chatScroll then
        _chatScroll:ScrollToBottom()
    end
end

--- 添加一个聊天气泡到消息面板
---@param role string "user" | "assistant" | "system"
---@param text string
function ChatUI._addChatBubble(role, text)
    if not _chatMessagesPanel then return end

    local isUser = (role == "user")
    local isSystem = (role == "system")

    local charCfg = CHAR_CONFIG[_chatCharName] or { emoji = "💬", color = COLORS.accent, bubbleColor = { 50, 50, 68, 255 } }

    local bubbleColor, textColor, align, labelColor
    if isUser then
        bubbleColor = { 70, 85, 150, 255 }
        textColor = { 240, 240, 255, 255 }
        labelColor = { 180, 200, 255, 200 }
        align = "flex-end"
    elseif isSystem then
        bubbleColor = { 70, 50, 50, 255 }
        textColor = { 255, 180, 180, 255 }
        labelColor = COLORS.textDim
        align = "center"
    else
        bubbleColor = charCfg.bubbleColor
        textColor = COLORS.text
        labelColor = charCfg.color
        align = "flex-start"
    end

    -- 角色标签（带 emoji）
    local labelText
    if isUser then
        labelText = "🧑 你"
    elseif isSystem then
        labelText = ""
    else
        labelText = charCfg.emoji .. " " .. (_chatCharName or "AI")
    end

    local bubbleChildren = {}
    if labelText ~= "" then
        table.insert(bubbleChildren, UI.Label {
            text = labelText,
            fontSize = LAYOUT.fontSmall,
            fontColor = labelColor,
            fontWeight = "bold",
            marginBottom = 3,
        })
    end
    table.insert(bubbleChildren, UI.Label {
        text = text,
        fontSize = LAYOUT.fontBody,
        fontColor = textColor,
        whiteSpace = "normal",
        width = "100%",
        lineHeight = 1.5,
    })

    -- 气泡外层（带角色色彩条）
    local isAI = not isUser and not isSystem
    local bubbleInner = UI.Panel {
        maxWidth = "82%",
        backgroundColor = bubbleColor,
        borderRadius = 12,
        padding = 10,
        borderLeftWidth = isAI and 3 or nil,
        borderLeftColor = isAI and charCfg.color or nil,
        borderRightWidth = isUser and 3 or nil,
        borderRightColor = isUser and { 130, 150, 220, 255 } or nil,
        children = bubbleChildren,
    }

    local bubble = UI.Panel {
        width = "100%",
        alignItems = align,
        marginBottom = 2,
        children = { bubbleInner },
    }

    _chatMessagesPanel:AddChild(bubble)
end

return ChatUI
