# Skill 02 - 游戏状态与存档

## 涉及模块

| 模块 | 文件 | 行数 | 职责 |
|------|------|------|------|
| GameState | `systems/GameState.lua` | 628 | 中央状态容器 |
| TimeSystem | `systems/TimeSystem.lua` | 204 | 时间推进与周期事件 |
| SaveSystem | `systems/SaveSystem.lua` | 203 | 3 槽位存档/读档 |

---

## GameState - 中央状态

### 核心概念

`GameState.state` 是一个巨大的 Lua table，包含游戏的**全部**变量。所有系统都通过 `require("systems.GameState")` 获取引用，直接读写 `GameState.state.xxx`。

### 状态变量分类

#### 1. 玩家基础

| 变量 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `PNN` | string | "" | 玩家名字 |
| `money` | number | 0 | 金币 |
| `currentPassage` | string | "命名" | 当前段落 |
| `currentArea` | string | "square" | 当前区域 |
| `currentRoom` | string | "客厅" | 家中当前房间 |

#### 2. 五维属性

| 变量 | 名称 | 默认值 | 说明 |
|------|------|--------|------|
| `LL` | 力量 | 1 | 物理战斗、体力活 |
| `LG` | 灵感 | 1 | 魔法、创造力 |
| `ML` | 魅力 | 3 | 社交、说服 |
| `NL` | 耐力 | 2 | 持久力、防御 |
| `JQ` | 技巧 | 1 | 精细操作、烹饪 |

#### 3. 个性四维

| 变量 | 名称 | 默认值 | 说明 |
|------|------|--------|------|
| `YG` | 勇敢 | 0 | 影响对话选项 |
| `LJ` | 冷静 | 0 | 影响判断结果 |
| `BZ` | 暴躁 | 0 | 影响冲突选项 |
| `ZL` | 智力 | 0 | 影响解谜/学习 |

#### 4. 生存指标

| 变量 | 范围 | 衰减速率 | 说明 |
|------|------|----------|------|
| `satiety`（饱腹度） | 0-100 | -2/小时 | ≤25 触发饥饿事件 |
| `fatigue`（疲劳度） | 0-100 | +1/小时(日), +2/小时(夜) | ≥70 触发疲劳事件 |
| `stress`（压力） | 0-100 | 饿/累/脏时增加 | ≥70 触发压力事件 |
| `cleanliness`（清洁度） | 0-100 | -1/小时 | ≤30 触发清洁事件 |

#### 5. 时间

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `year` | 499 | 年份 |
| `month` | 1 | 月份 |
| `day` | 1 | 日期 |
| `hour` | 8 | 小时 |
| `minute` | 0 | 分钟 |
| `inPrologue` | false | 序章期间不显示具体日期 |

#### 6. 外观

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `hairstyle` | "及肩长发" | 发型 |
| `hairColor` | "淡黄色" | 发色（10 种可选） |
| `eyeColor` | "赤色" | 瞳色（8 种可选） |

#### 7. NPC 关系（主要 NPC）

每个主要 NPC 有一组变量：

```lua
-- 莱德
S.initialNameAffection = 0       -- 好感度 (0-100)
S.initialNameLevel = 1           -- 好感等级 (1-5)
S.initialNameAtHome = false      -- 是否住在一起
S.initialNameInParty = false     -- 是否在战斗队伍中

-- K
S.kAffection = 0
S.kLevel = 1
S.kMet = false                   -- 是否已初次相遇

-- 奥梅尔
S.oamelAffection = 0
S.oamelLevel = 1
```

#### 8. 战斗相关

```lua
S.playerCombat = {
    level = 1, exp = 0,
    hp = 100, maxHp = 100,
    mp = 30, maxMp = 30,
    power = 5, insight = 3,
    speed = 5, def = 3,
    heroClass = nil,  -- "warrior" 或 "mage"
}
S.forestLayer = 1       -- 当前森林层数 (1-10)
S.forestExplored = {}   -- 已探索过的层
```

#### 9. 任务进度

```lua
S.mqStage = 0       -- 主线第一章阶段 (0-5)
S.mq2Stage = 0      -- 主线第二章阶段
S.mq2Route = 0      -- 第二章路线选择 (1/2/3)
S.mq3Stage = 0      -- 主线第三章阶段
S.mq3Ending = 0     -- 结局类型 (1-5)
```

### 工具方法

```lua
GameState.addNotification(text)   -- 添加通知消息
GameState.modifyStat(key, delta)  -- 安全修改状态值（带边界检查）
GameState.logDate(text)           -- 记录约会日志
```

---

## TimeSystem - 时间推进

### 核心函数

```lua
TimeSystem.addMinutes(minutes)  -- 推进分钟，触发逐小时回调
TimeSystem.addHours(hours)      -- 推进小时，触发衰减和事件
```

### 每小时回调

- 饱腹度 -2
- 疲劳度 +1（白天）/ +2（夜间 22:00-6:00）
- 清洁度 -1
- 压力：当饿/累/脏时额外增加

### 每日回调（跨天时触发）

- 重置：猫喂食状态、约会可用性、城镇事件计数
- 调用 `FarmingSystem.onDayChange()` 推进作物生长

### 每周回调（第 8 天触发）

- 扣除房租
- 重置宴会参加次数
- 重置 LLM 聊天配额

---

## SaveSystem - 存档系统

### 功能

- **3 个存档槽位**：`saves/slot_1.json` ~ `saves/slot_3.json`
- **JSON 序列化**：保存完整的 `GameState.state`
- **排除运行时变量**：通知队列、当前事件等临时数据不保存
- **存档预览**：名字、日期、金钱、当前位置

### 使用方式

```lua
SaveSystem.save(slotIndex)   -- 保存到指定槽位
SaveSystem.load(slotIndex)   -- 从指定槽位加载
SaveSystem.getPreview(slot)  -- 获取槽位预览信息
```

### 存档时机

- 手动存档：侧边栏 → 存档/读档面板
- 自动存档：退出游戏时
