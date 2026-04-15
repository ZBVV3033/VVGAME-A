# Skill 01 - 核心架构

## 设计模式

**事件驱动状态机 + 段落导航（Twine-like Passage System）**

### 核心原则

1. **中央状态（GameState.lua）**：所有游戏变量的单一数据源，各系统读写共享状态
2. **段落导航**：每个画面是一个"段落"(passage)，包含文本描述 + 选项列表
3. **系统模块化**：每个系统自包含，暴露函数接口，不持有持久状态
4. **时间驱动**：TimeSystem 作为游戏时钟，驱动生存衰减、每日/每周事件
5. **动态内容注入**：主线/支线/随机事件在条件满足时将选项注入到地点段落中

## 架构分层

```
┌──────────────────────────────────────────────┐
│              表现层 (Presentation)              │
│  UIManager / SceneView / CharacterRenderer   │
│  CharacterPortrait / SceneBackground          │
└─────────────────┬────────────────────────────┘
                  │ 调用
┌─────────────────▼────────────────────────────┐
│              内容层 (Content)                   │
│  PassageData / TownLife / RandomEvents        │
│  HomeSystem / MainQuest / SideQuests          │
└─────────────────┬────────────────────────────┘
                  │ 读写
┌─────────────────▼────────────────────────────┐
│              逻辑层 (Logic)                     │
│  BattleSystem / WorkSystem / CookingSystem   │
│  FarmingSystem / UniversitySystem / NPCSystem │
│  TimeSystem / KeywordSystem                   │
└─────────────────┬────────────────────────────┘
                  │ 读写
┌─────────────────▼────────────────────────────┐
│              数据层 (Data)                      │
│  GameState（中央状态容器）                       │
│  SaveSystem（持久化）                           │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│              网络层 (Network, 可选)              │
│  Client.lua / Server.lua / ChatUI.lua        │
└──────────────────────────────────────────────┘
```

## 数据流

### 典型交互流程（以"去打工"为例）

```
1. 玩家点击"去打工"选项
   ↓
2. UIManager.navigate("酒馆_打工")
   ↓
3. PassageData.getPassage("酒馆_打工") → 调用 WorkSystem.work("waiter")
   ↓
4. WorkSystem:
   ├── TimeSystem.addHours(2)     → 触发逐小时衰减
   ├── GameState.money += wage    → 修改金钱
   ├── GameState.fatigue += 15    → 增加疲劳
   └── 返回结果文本 + 下一段落
   ↓
5. UIManager 渲染更新后的 UI（状态栏、文本、选项）
```

### 选项结构

```lua
{
    text = "选项显示文本",
    target = "目标段落名",            -- 静态跳转
    action = function() ... end,     -- 动态操作（修改状态，返回下一段落）
    condition = function() ... end,  -- 条件函数（返回 true 才显示此选项）
    modal = true,                    -- 是否以弹窗形式展示
}
```

## 模块依赖图

```
UIManager ──→ PassageData ──→ 所有逻辑系统
   │              │
   │              ├──→ BattleSystem ──→ GameState
   │              ├──→ WorkSystem ──→ GameState, TimeSystem
   │              ├──→ MainQuest/Ch2/Ch3 ──→ GameState
   │              ├──→ TownLife ──→ GameState, NPCSystem
   │              ├──→ RandomEvents ──→ GameState
   │              └──→ HomeSystem ──→ GameState, CookingSystem, FarmingSystem
   │
   ├──→ GameState（直接读取状态栏数据）
   ├──→ TimeSystem（格式化时间显示）
   ├──→ ChatUI（AI 聊天覆盖层）
   └──→ SceneView / CharacterRenderer / SceneBackground（渲染层）
```

## 入口文件

| 文件 | 模式 | 说明 |
|------|------|------|
| `main.lua` | 单机 | 加载所有系统模块，初始化 UI，启动游戏循环 |
| `client_main.lua` | 多人客户端 | 在 main.lua 基础上增加网络连接和 ChatClient |
| `server_main.lua` | 多人服务端 | 仅加载 Server.lua，处理 LLM 代理请求 |

**判断当前模式**：读取 `.project/settings.json` 中的 `@runtime.multiplayer.enabled`

## 扩展指南

### 添加新系统模块

1. 在 `scripts/systems/` 下创建 `NewSystem.lua`
2. 模块返回 table：`local NewSystem = {} ... return NewSystem`
3. 在 `GameState.init()` 中添加所需状态变量
4. 在 `PassageData.lua` 中集成段落和选项
5. 如需 UI 入口，在 `UIManager` 的侧边栏添加导航按钮

### 添加新段落内容

1. 在 `PassageData.lua` 的对应区域添加段落定义
2. 确保 `text`、`choices` 字段完整
3. 选项的 `action` 函数修改 `GameState.state` 并返回下一段落名
4. 如有条件显示，添加 `condition` 函数
