-- ============================================================================
-- Client.lua - 客户端聊天网络模块
-- 负责：发送聊天消息到服务端、接收 LLM 回复
-- ============================================================================

require("network.Shared")

local ChatClient = {}

-- 状态
ChatClient.waiting = false           -- 是否正在等待 LLM 回复
ChatClient.connected = false         -- 是否已连接服务器
ChatClient.remaining = -1            -- 本周剩余对话次数（-1=未知）
ChatClient.onMessageReceived = nil   -- 收到回复的回调: function(charName, reply, remaining)
ChatClient.onConnected = nil         -- 连接成功的回调: function()

--- 初始化客户端网络
function ChatClient.init()
    SubscribeToEvent(E_CHAT_TO_CLIENT, "HandleChatReply")
    SubscribeToEvent("ClientConnected", "HandleChatClientConnected")
    SubscribeToEvent("ClientDisconnected", "HandleChatClientDisconnected")
    log:Write(LOG_INFO, "[ChatClient] Initialized, waiting for connection...")
end

--- 发送聊天消息到服务端
---@param charName string 角色名
---@param message string 用户消息
---@param contextJson string|nil 游戏上下文 JSON（好感度、位置等）
---@return boolean 是否发送成功
function ChatClient.sendMessage(charName, message, contextJson)
    local conn = network:GetServerConnection()
    if not conn then
        log:Write(LOG_ERROR, "[ChatClient] No server connection, cannot send")
        return false
    end

    local vm = VectorBuffer()
    vm:WriteString(message)
    vm:WriteString(charName)
    vm:WriteString(contextJson or "")
    conn:SendRemoteEvent(E_CHAT_TO_SERVER, true, vm)

    ChatClient.waiting = true
    log:Write(LOG_INFO, "[ChatClient] Sent: char=" .. charName .. " msg=" .. message:sub(1, 50))
    return true
end

--- 是否可以发送消息（已连接且不在等待中）
---@return boolean
function ChatClient.canSend()
    return ChatClient.connected and not ChatClient.waiting
end

-- ==================== 事件处理 ====================

--- 收到服务端回复
function HandleChatReply(eventType, eventData)
    local reply = eventData:ReadString()
    local charName = eventData:ReadString()
    local remaining = eventData:ReadInt()

    ChatClient.waiting = false
    ChatClient.remaining = remaining
    log:Write(LOG_INFO, "[ChatClient] Reply from " .. charName .. " remaining=" .. remaining .. ": " .. reply:sub(1, 50))

    if ChatClient.onMessageReceived then
        ChatClient.onMessageReceived(charName, reply, remaining)
    end
end

--- 客户端已连接服务器
function HandleChatClientConnected(eventType, eventData)
    ChatClient.connected = true
    log:Write(LOG_INFO, "[ChatClient] Connected to server")

    -- 发送 ClientReady
    local conn = network:GetServerConnection()
    if conn then
        ---@type Scene
        local scene = _G._networkScene
        if scene then
            conn.scene = scene
        end
        conn:SendRemoteEvent(E_CLIENT_READY, true)
        log:Write(LOG_INFO, "[ChatClient] ClientReady sent")
    end

    if ChatClient.onConnected then
        ChatClient.onConnected()
    end
end

--- 客户端断开连接
function HandleChatClientDisconnected(eventType, eventData)
    ChatClient.connected = false
    ChatClient.waiting = false
    log:Write(LOG_INFO, "[ChatClient] Disconnected from server")
end

return ChatClient
