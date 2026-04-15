-- ============================================================================
-- UIConfig.lua - UI 配置数据（从 UIManager.lua 提取）
-- 包含：平台检测、布局尺寸、颜色定义、场景背景图映射
-- ============================================================================

local PlatformUtils = require("urhox-libs.Platform.PlatformUtils")

local M = {}

-- ==================== 平台检测 ====================
M.isMobile = PlatformUtils.IsMobilePlatform()

local isMobile = M.isMobile  -- 局部变量简化后续引用

M.LAYOUT = {
    -- 字体大小
    fontTitle     = isMobile and 22 or 18,
    fontBody      = isMobile and 20 or 17,
    fontSmall     = isMobile and 17 or 14,
    fontLabel     = isMobile and 19 or 16,
    fontStat      = isMobile and 16 or 13,
    -- 按钮高度
    btnHeight     = isMobile and 54 or 44,
    btnSmallH     = isMobile and 42 or 34,
    -- 状态栏高度
    statusBarH    = isMobile and 56 or 48,
    -- 侧边栏宽度（移动端使用全屏覆盖）
    sidebarWidth  = isMobile and "80%" or 200,
    -- 内边距
    padContent    = isMobile and 20 or 16,
    padChoicesV   = isMobile and 10 or 8,
    padChoicesH   = isMobile and 20 or 16,
    -- 选项间距
    choiceGap     = isMobile and 8 or 6,
}


M.COLORS = {
    bg = { 22, 22, 30, 255 },           -- 深色背景
    bgPanel = { 30, 30, 42, 240 },      -- 面板背景
    bgCard = { 38, 38, 52, 255 },       -- 卡片背景
    text = { 220, 218, 228, 255 },      -- 主文本
    textDim = { 140, 138, 155, 255 },   -- 次要文本
    textTitle = { 255, 255, 255, 255 }, -- 标题文本（纯白）
    textGold = { 210, 190, 140, 255 },  -- 暖金（用于金币等）
    accent = { 130, 120, 200, 255 },    -- 强调色（柔紫）
    accentSoft = { 100, 140, 200, 255 },-- 柔蓝强调
    accentHover = { 150, 140, 220, 255 },
    accentPress = { 110, 100, 180, 255 },
    danger = { 200, 85, 85, 255 },      -- 危险色
    success = { 90, 190, 120, 255 },    -- 成功色
    warning = { 220, 175, 70, 255 },    -- 警告色
    border = { 60, 58, 80, 180 },       -- 边框色
    statusBg = { 26, 26, 36, 250 },     -- 状态栏背景
    btnBg = { 44, 44, 62, 255 },        -- 按钮背景
    btnHover = { 58, 58, 82, 255 },     -- 按钮悬停
    btnPress = { 36, 36, 52, 255 },     -- 按钮按下
    inputBg = { 34, 34, 48, 255 },      -- 输入框背景
    notifyBg = { 50, 50, 72, 230 },     -- 通知背景
    divider = { 55, 55, 76, 120 },      -- 分隔线
}

M.SCENE_BACKGROUNDS = {
    ["十字路口"]     = "image/scene_crossroads_20260413084850.png",
    ["家"]           = "image/scene_home_20260413085014.png",
    ["渡劫森林"]     = "image/scene_forest_20260413084847.png",
    ["商业区"]       = "image/scene_commercial_20260413084855.png",
    ["花园小镇"]     = "image/scene_garden_town_20260413090228.png",
    ["贫民窟"]       = "image/scene_slums_20260413090805.png",
    ["港口"]         = "image/scene_port_20260413090850.png",
    ["主城区"]       = "image/scene_main_city_20260413090921.png",
    ["花街"]         = "image/scene_flower_street_20260413091017.png",
    ["白鸦书屋"]     = "image/scene_bookshop_20260413091047.png",
    ["大学校门"]     = "image/scene_university_20260413091121.png",
    -- 子场景继承父场景背景
    ["花园小镇_小巷"] = "image/scene_garden_town_20260413090228.png",
    ["贫民窟_黑帮据点"] = "image/scene_slums_20260413090805.png",
}


return M
