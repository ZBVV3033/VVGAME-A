-- ============================================================================
-- Shared.lua - 共享事件名定义
-- 客户端和服务端都需要加载此文件
-- ============================================================================

-- 远程事件名
E_CHAT_TO_SERVER = "ChatToServer"     -- 客户端 → 服务端：发送聊天消息
E_CHAT_TO_CLIENT = "ChatToClient"     -- 服务端 → 客户端：返回 LLM 回复
E_CLIENT_READY   = "ClientReady"      -- 客户端 → 服务端：客户端就绪

-- 注册远程事件（双端都需要调用）
network:RegisterRemoteEvent(E_CHAT_TO_SERVER)
network:RegisterRemoteEvent(E_CHAT_TO_CLIENT)
network:RegisterRemoteEvent(E_CLIENT_READY)

log:Write(LOG_INFO, "[Shared] Remote events registered")
