# 悠闲悠哉life - 项目总览

## 游戏简介

**悠闲悠哉life** 是一款中文文字冒险 RPG，融合了以下玩法：
- **生活模拟**：管理饥饿、疲劳、压力、清洁度四项生存指标
- **文字冒险**：Twine 风格的段落导航，玩家通过选项推进剧情
- **恋爱养成**：与 NPC 发展关系，提升好感度，触发约会事件
- **回合制战斗**：10 层森林地牢探索，队伍编成，技能升级
- **经营管理**：打工赚钱、种菜、烹饪、上大学

## 世界观

中世纪奇幻港口城镇，存在阶级冲突、神秘黑暗教团。玩家以外来者身份在镇上生活，通过日常活动和人际交往逐步揭开主线剧情。

## 技术栈

| 项目 | 技术 |
|------|------|
| 引擎 | UrhoX (Lua 5.4) |
| UI 系统 | urhox-libs/UI (Yoga Flexbox + NanoVG) |
| 渲染 | NanoVG 矢量绘图（角色骨骼动画、场景背景、肖像） |
| 网络 | C/S 架构（可选多人，用于 LLM 聊天） |
| AI 集成 | 火山引擎豆包 API（NPC 智能对话） |

## 代码规模

| 分类 | 文件数 | 总行数 |
|------|--------|--------|
| 核心入口 | 3 | ~410 |
| 网络模块 | 3 | ~410 |
| 系统模块 | 25 | ~30,600 |
| **合计** | **31** | **~31,400** |

## 文件结构

```
scripts/
├── main.lua                  # 单机模式入口
├── client_main.lua           # 多人模式客户端入口
├── server_main.lua           # 多人模式服务端入口
├── network/
│   ├── Client.lua            # 聊天客户端
│   ├── Server.lua            # LLM 代理服务端
│   └── Shared.lua            # 共享常量
├── systems/
│   ├── GameState.lua         # 中央状态管理
│   ├── UIManager.lua         # UI 渲染与导航
│   ├── PassageData.lua       # 段落/场景内容数据库
│   ├── BattleSystem.lua      # 回合制战斗
│   ├── TownLife.lua          # 城镇区域随机事件
│   ├── HomeSystem.lua        # 家庭系统
│   ├── WorkSystem.lua        # 打工系统
│   ├── RandomEvents.lua      # 生存触发随机事件
│   ├── MainQuest.lua         # 主线第一章
│   ├── MainQuestCh2.lua      # 主线第二章
│   ├── MainQuestCh3.lua      # 主线第三章
│   ├── SideQuests.lua        # 支线任务
│   ├── UniversitySystem.lua  # 大学系统
│   ├── CookingSystem.lua     # 烹饪系统
│   ├── FarmingSystem.lua     # 种植系统
│   ├── NPCSystem.lua         # NPC 关系管理
│   ├── ChatUI.lua            # AI 聊天界面
│   ├── CharacterPortrait.lua # 角色肖像（表情系统）
│   ├── CharacterRenderer.lua # 角色骨骼动画
│   ├── SceneBackground.lua   # 场景背景绘制
│   ├── SceneView.lua         # 双 NanoVG 上下文管理
│   ├── TimeSystem.lua        # 时间系统
│   ├── SaveSystem.lua        # 存档系统
│   ├── KeywordSystem.lua     # 关键词收集系统
│   └── ChangelogData.lua     # 更新日志
├── data/                     # 数据文件
└── ui/                       # UI 相关
```

## Skill 文档索引

| 编号 | Skill | 覆盖模块 | 说明 |
|------|-------|---------|------|
| 01 | [核心架构](01-architecture.md) | 整体设计模式、数据流、模块依赖 | 了解项目如何运转 |
| 02 | [游戏状态与存档](02-game-state.md) | GameState, SaveSystem, TimeSystem | 中央数据、时间、持久化 |
| 03 | [UI 与渲染](03-ui-rendering.md) | UIManager, SceneView, SceneBackground, CharacterRenderer, CharacterPortrait | 界面与视觉 |
| 04 | [战斗系统](04-battle-system.md) | BattleSystem | 回合制战斗、敌人、技能、森林探索 |
| 05 | [生活系统](05-life-systems.md) | WorkSystem, CookingSystem, FarmingSystem, UniversitySystem | 打工、烹饪、种植、大学 |
| 06 | [剧情与任务](06-quests-story.md) | MainQuest, MainQuestCh2, MainQuestCh3, SideQuests | 主线三章、支线、5种结局 |
| 07 | [NPC 与社交](07-npc-social.md) | NPCSystem, KeywordSystem | 好感度、约会、礼物、关键词 |
| 08 | [多人与 AI 集成](08-multiplayer-ai.md) | Client, Server, ChatUI, Shared | 网络架构、LLM 对话 |
| 09 | [内容数据](09-content-data.md) | PassageData, TownLife, RandomEvents, HomeSystem, ChangelogData | 场景段落、随机事件、家庭 |
