# Skill 03 - UI 与渲染

## 涉及模块

| 模块 | 文件 | 行数 | 职责 |
|------|------|------|------|
| UIManager | `systems/UIManager.lua` | 2218 | UI 布局、导航、事件处理 |
| SceneView | `systems/SceneView.lua` | 402 | 双 NanoVG 上下文管理 |
| SceneBackground | `systems/SceneBackground.lua` | 416 | 程序化场景背景 |
| CharacterRenderer | `systems/CharacterRenderer.lua` | 596 | 骨骼角色动画 |
| CharacterPortrait | `systems/CharacterPortrait.lua` | 558 | 角色肖像与表情 |

---

## UIManager - 界面核心

### 技术栈

- **布局**：urhox-libs/UI（Yoga Flexbox）
- **渲染**：NanoVG
- **主题**：暗黑奇幻风格

### 颜色方案

```lua
背景色:   #16161E
强调色:   #8278C8
危险色:   #C85555
文本色:   白色/浅灰
```

### 界面结构

```
SafeAreaView (root)
├── 通知栏 (固定顶部)
├── 状态栏 (日期/时间/金钱)
└── Body 区域
    ├── 侧边栏 (桌面: 内嵌 200px, 手机: 覆盖层 80%)
    │   ├── 角色信息 (名字/日期/时间/金钱)
    │   ├── 生存指标条 ×4
    │   ├── 五维属性
    │   └── 导航按钮 ×9
    └── 主内容区
        ├── 背景图面板
        ├── 内容滚动区 (故事文本)
        ├── 输入面板 (命名时)
        └── 选项面板 (行动按钮)
```

### 平台自适应

```lua
local isMobile = PlatformUtils.IsMobilePlatform()

-- 字体大小
fontBody:   手机 20px / 桌面 17px
fontTitle:  手机 22px / 桌面 18px

-- 按钮高度
btnHeight:  手机 54px / 桌面 44px

-- 侧边栏
手机: 覆盖层 80% 宽度 + 遮罩
桌面: 内嵌 200px 固定宽度
```

### 核心函数

```lua
UIManager.init(sceneView)           -- 初始化 UI 系统
UIManager.navigate(passageName)     -- 导航到指定段落
UIManager.showNotification(text)    -- 显示通知
UIManager.refreshUI()               -- 刷新当前界面
```

### 段落路由机制

`navigate()` 内部流程：

1. 保存段落名到 `GameState.state.currentPassage`
2. 查询 `PassageData.getPassage(name)` 获取段落数据
3. 特殊段落检测（战斗、约会等）→ 调用对应系统
4. 渲染文本（支持分页，每页约 500 字符）
5. 渲染选项按钮（过滤 `condition` 为 false 的选项）
6. 更新状态栏和背景图

### 侧边栏弹窗（9 个导航入口）

| 入口 | 内容 |
|------|------|
| 属性 | 五维属性 + 个性四维 |
| 人际 | NPC 好感度列表 |
| 战斗 | 等级/经验/HP/MP/技能 |
| 技能树 | 已解锁技能列表 |
| 背包 | 物品/食材/种子库存 |
| 存档 | 3 槽位存/读档 |
| 设置 | 音量/显示设置 |
| 更新日志 | 版本历史 |
| AI 聊天 | LLM 对话界面 |

### 文本分页

长文本（>500 字符）自动分页显示：

```lua
pageData = {
    pages = { "第1页文本...", "第2页文本..." },
    currentPage = 1,
    passage = "段落名",
}
-- 显示"下一页"/"上一页"按钮
```

### 弹窗系统

| 类型 | 用途 |
|------|------|
| `_storyModal` | 事件内容弹窗（含"继续"按钮） |
| `_affectionModal` | 好感度互动弹窗（约会场景） |
| `_choiceModal` | 手机端选择弹窗 |
| `_notifModal` | 手机端通知弹窗 |

---

## SceneView - 双上下文渲染

### 设计目标

将角色渲染和浮窗渲染分离到两个 NanoVG 上下文，控制层级关系：

```
渲染顺序 (renderOrder):
  Context 1 (999975): 角色肖像层 → UI 下方
  Context 2 (999995): 浮窗层 → UI 上方
```

### 功能

- 角色窗口可展开（1/6 屏幕 ↔ 1/2 屏幕）
- 支持拖拽移动
- 管理角色渲染位置

---

## SceneBackground - 场景背景

### 实现方式

使用 NanoVG 程序化绘制各地点的背景，包含：

- 渐变天空
- 建筑物剪影
- 树木、地面色块

### 支持场景

十字路口、商业区、港口、花园小镇、主城区、花街、渡劫森林、贫民窟、家

另外也支持加载预渲染的背景图片：

```lua
SCENE_BACKGROUNDS = {
    ["十字路口"] = "image/scene_crossroads_xxx.png",
    -- ...
}
```

---

## CharacterRenderer - 骨骼动画

### 技术

NanoVG 矢量绘制，非 3D 模型。

### 骨骼层级

```
hip (臀部)
├── spine (脊柱)
│   ├── head (头部)
│   │   └── hair (头发)
│   ├── left_arm (左臂)
│   │   └── left_hand (左手)
│   └── right_arm (右臂)
│       └── right_hand (右手)
├── left_leg (左腿)
│   └── left_foot (左脚)
└── right_leg (右腿)
    └── right_foot (右脚)
```

### 动画状态

| 状态 | 描述 | 触发 |
|------|------|------|
| idle | 呼吸微动、头部微转、头发飘动 | 默认 |
| walk | 身体起伏、腿部摆动、挎包晃动 | 移动时 |
| wave | 手臂抬起 + 挥手 | 打招呼 |
| talk | 头部微点 | 对话时 |

### 外观自定义

从 GameState 读取：
- 10 种发色
- 8 种瞳色
- 动画过渡混合时间：4 秒

---

## CharacterPortrait - 肖像与表情

### 表情系统

| 表情 | 眉毛 | 眼睛 | 嘴巴 | 腮红 |
|------|------|------|------|------|
| neutral | 平直 | 正常 | 直线 | 无 |
| happy | 上挑 | 微眯 | 微笑 | 轻微 |
| annoyed | 皱眉 | 窄眼 | 撇嘴 | 无 |
| sad | 下垂 | 正常 | 下弯 | 无 |
| angry | 内聚 | 瞪眼 | 咬牙 | 无 |
| surprised | 高挑 | 睁大 | 张嘴 | 无 |
| shy | 微斜 | 侧视 | 微笑 | 明显 |

### 使用场景

- 约会场景中显示 NPC 表情
- 重要剧情对话
