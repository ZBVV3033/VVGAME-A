# Skill 08 - 多人与 AI 集成

## 涉及模块

| 模块 | 文件 | 行数 | 职责 |
|------|------|------|------|
| Client | `network/Client.lua` | 100 | 聊天消息客户端 |
| Server | `network/Server.lua` | 292 | LLM 代理服务端 |
| Shared | `network/Shared.lua` | 16 | 共享常量 |
| ChatUI | `systems/ChatUI.lua` | 790 | AI 聊天界面 |

---

## 架构概述

```
┌─────────────┐     RemoteEvent     ┌─────────────┐     HTTP     ┌──────────────┐
│   客户端     │ ◄──────────────────► │   服务端     │ ◄──────────► │ 火山引擎豆包  │
│ Client.lua  │                     │ Server.lua  │             │ Doubao API   │
│ ChatUI.lua  │                     │ (LLM Proxy) │             │              │
└─────────────┘                     └─────────────┘             └──────────────┘
```

### 模式判断

读取 `.project/settings.json`：

```json
{
  "@runtime": {
    "multiplayer": {
      "enabled": true  // true = 多人模式, false = 单机模式
    }
  }
}
```

- **单机模式**：使用 `main.lua` 入口，无网络功能，AI 聊天不可用
- **多人模式**：使用 `client_main.lua` + `server_main.lua`，AI 聊天可用

---

## Client.lua - 聊天客户端

### 功能

- 通过 RemoteEvent 向服务端发送聊天消息
- 携带角色名 + 上下文 JSON
- 管理等待状态（发送后等待服务端响应）
- 接收服务端回复并触发回调
- 追踪剩余配额

### 核心接口

```lua
ChatClient.sendMessage(characterName, message, context, callback)
-- characterName: NPC 名字 ("莱德"/"K"/"威廉")
-- message: 玩家输入的文本
-- context: 上下文 JSON (好感度/位置/时间/关键词)
-- callback: 收到回复后的回调函数
```

---

## Server.lua - LLM 代理服务端

### 模型

**豆包 Seed-2.0-pro**（火山引擎 Volcano Engine）

### 角色人设

每个 NPC 有预设的 system prompt，定义其性格和说话风格：

| NPC | 性格特征 |
|------|---------|
| 莱德 | 阳光开朗，冒险者，略带莽撞 |
| K | 神秘优雅，知识渊博，说话含蓄 |
| 威廉 | 老练世故，幽默风趣 |

### 上下文注入

服务端在构建 LLM 请求时，自动注入：

```lua
{
    affection_level = "亲密",       -- 当前好感度描述
    location = "花园",             -- 当前位置
    time = "499年1月5日 下午3点",   -- 当前时间
    player_name = "玩家名",        -- 玩家名字
    recent_events = "...",         -- 最近的关系事件
    keywords = { "冒险", "港口" }, -- 玩家收集的关键词
}
```

### 配额系统

```lua
-- 每周 50 条消息/连接
weeklyQuota = 50

-- 每周一 00:00 重置
-- 在 TimeSystem 的每周回调中触发重置
```

### 响应方式

- 流式传输已禁用（为了稳定性）
- 完整回复一次性返回

---

## ChatUI.lua - AI 聊天界面

### 界面结构

```
┌──────────────────────────────┐
│  角色选择栏 (莱德/K/威廉)     │
├──────────────────────────────┤
│  快捷话题按钮 ×6              │
│  (每个角色有不同的预设话题)     │
├──────────────────────────────┤
│                              │
│  聊天消息记录（可滚动）        │
│  - 玩家消息（靠右）           │
│  - NPC 回复（靠左 + 头像）    │
│                              │
├──────────────────────────────┤
│  输入框 (100字限制) + 发送按钮 │
├──────────────────────────────┤
│  剩余配额: 48/50             │
└──────────────────────────────┘
```

### 快捷话题

每个角色 6 个预设对话开场白，例如：
- 莱德：聊聊冒险、最近的打工、森林探索
- K：讨论文化、分享烹饪心得、花园的花
- 威廉：商业八卦、城镇传闻

### 上下文构建

ChatUI 从 GameState 自动收集上下文：

```lua
local context = {
    affection = NPCSystem.getAffectionLevel(characterName),
    location = GameState.state.currentArea,
    time = TimeSystem.getFormattedTime(),
    keywords = KeywordSystem.getCollectedKeywords(),
    -- ... 更多
}
```

### 与 UIManager 集成

- 作为覆盖层（overlay）激活
- 在 UIManager 的侧边栏中有"AI 聊天"入口按钮
- 聊天窗口可关闭，回到主游戏界面

---

## 安全与限制

| 限制 | 值 | 说明 |
|------|-----|------|
| 每周消息数 | 50 | 防止 API 成本失控 |
| 单条消息长度 | 100 字 | 输入限制 |
| 流式传输 | 禁用 | 稳定性考虑 |
| NPC 数量 | 3 | 仅莱德/K/威廉支持 AI 对话 |

---

## 不使用多人模式时

如果 `multiplayer.enabled = false`：
- AI 聊天功能完全不可用
- ChatUI 不初始化
- 侧边栏中不显示"AI 聊天"按钮
- 所有 NPC 对话通过 PassageData 的固定文本提供
