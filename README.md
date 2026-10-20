# 雾海号 · The Last Voyage（TapTap 制造迁移包）

- 引擎：UrhoX（星火编辑器）
- 入口：.project/project.json 的 entry=main.lua；脚本在 scripts/
- 素材：assets/image/，脚本按 image/... 引用（assets 为资源根，无目录前缀）
- 单机：multiplayer.enabled=false；单档本地存档 fogsea_save.json

## 迁移到新项目
1. 将 scripts/、assets/、.project/ 放入新项目根目录。
2. 新项目首次 build 会自动获取 project_id / developer_id；本包已剔除原项目的平台身份，不含任何账号、密钥或令牌。
3. 白底立绘使用 assets/image/processed/ 下的抠图版本（脚本已引用）。

## 操作
标题：点烘焙文字「开始/继续/设置/退出」（透明热区，悬停有描边）。
游戏内：点击物件调查，拖动背景环顾，滚轮缩放；J 线索册，H 热区标签，Esc 暂停。
