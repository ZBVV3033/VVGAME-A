-- ============================================================================
-- PaperDollPortrait.lua - 纸娃娃头像系统（图片层合成版）
-- 使用分层 PNG 图片 + NanoVG 合成替代矢量绘制
-- 层序（由底到顶）：face_base → expression → hair_front (tinted)
-- API 与 CharacterPortrait.lua 完全兼容
-- ============================================================================

local GameState = require("systems.GameState")

local PaperDollPortrait = {}

local currentExpression_ = "neutral"

-- ==================== 颜色映射（与 CharacterPortrait 一致） ====================

local HAIR_COLORS = {
    ["淡黄色"] = { 240, 220, 160 },
    ["黑色"]   = { 55, 50, 52 },
    ["棕色"]   = { 165, 115, 75 },
    ["白色"]   = { 245, 243, 250 },
    ["红色"]   = { 200, 80, 70 },
    ["蓝色"]   = { 90, 130, 200 },
    ["银色"]   = { 210, 210, 220 },
    ["粉色"]   = { 235, 170, 190 },
    ["绿色"]   = { 100, 170, 110 },
    ["紫色"]   = { 150, 100, 190 },
    ["金色"]   = { 230, 200, 115 },
    ["灰色"]   = { 155, 155, 165 },
}

local EYE_COLORS = {
    ["赤色"]   = { 185, 45, 45 },
    ["蓝色"]   = { 65, 110, 210 },
    ["绿色"]   = { 55, 155, 85 },
    ["金色"]   = { 205, 175, 55 },
    ["紫色"]   = { 135, 75, 175 },
    ["黑色"]   = { 35, 30, 30 },
    ["灰色"]   = { 125, 125, 135 },
    ["琥珀色"] = { 195, 145, 55 },
    ["翠绿"]   = { 40, 175, 100 },
    ["银色"]   = { 180, 185, 200 },
}

-- ==================== 发型 → 文件名映射 ====================

local HAIRSTYLE_FILES = {
    ["短发"]     = "short",
    ["寸头"]     = "buzzcut",
    ["及肩长发"] = "shoulder",
    ["长发"]     = "long",
    ["披肩发"]   = "drape",
    ["马尾"]     = "ponytail",
    ["卷发"]     = "curly",
    ["编发"]     = "braided",
}

-- ==================== 表情列表 ====================

local EXPRESSION_NAMES = {
    "neutral", "happy", "annoyed", "sad", "angry", "surprised", "shy",
}

-- ==================== 图片缓存管理（每个 context 独立） ====================

-- key = NanoVG context userdata → { face_base = handle, hair_short = handle, ... }
local imageCache_ = {}

--- 确保指定 context 的图片已加载
---@param ctx userdata NanoVG context
---@return table handles
local function ensureImages(ctx)
    if imageCache_[ctx] then
        return imageCache_[ctx]
    end

    local handles = {}
    local basePath = "image/paperdoll/portrait/"

    -- 加载 face_base
    handles.face_base = nvgCreateImage(ctx, basePath .. "face_base.png", 0)

    -- 加载表情层
    for _, name in ipairs(EXPRESSION_NAMES) do
        handles["expr_" .. name] = nvgCreateImage(ctx, basePath .. "expr_" .. name .. ".png", 0)
    end

    -- 加载前发层
    for _, file in pairs(HAIRSTYLE_FILES) do
        handles["hair_" .. file] = nvgCreateImage(ctx, basePath .. "hair_front_" .. file .. ".png", 0)
    end

    imageCache_[ctx] = handles
    return handles
end

-- ==================== 初始化 ====================

function PaperDollPortrait.init(nvgCtx)
    -- 预加载默认 context 的图片
    ensureImages(nvgCtx)
end

-- ==================== 表情切换 ====================

function PaperDollPortrait.setExpression(name)
    for _, v in ipairs(EXPRESSION_NAMES) do
        if v == name then
            currentExpression_ = name
            return
        end
    end
end

function PaperDollPortrait.getExpression()
    return currentExpression_
end

-- ==================== 工具函数 ====================

--- 在指定区域绘制一张图片（无染色）
---@param ctx userdata
---@param handle integer NanoVG image handle
---@param x number 左上角 x
---@param y number 左上角 y
---@param w number 宽度
---@param h number 高度
---@param alpha number|nil 透明度 0-1，默认 1.0
local function drawImage(ctx, handle, x, y, w, h, alpha)
    if not handle or handle == 0 then return end
    alpha = alpha or 1.0
    local paint = nvgImagePattern(ctx, x, y, w, h, 0, handle, alpha)
    nvgBeginPath(ctx)
    nvgRect(ctx, x, y, w, h)
    nvgFillPaint(ctx, paint)
    nvgFill(ctx)
end

--- 在指定区域绘制一张染色图片
---@param ctx userdata
---@param handle integer NanoVG image handle
---@param x number 左上角 x
---@param y number 左上角 y
---@param w number 宽度
---@param h number 高度
---@param r number 红 0-255
---@param g number 绿 0-255
---@param b number 蓝 0-255
---@param a number|nil 透明度 0-255，默认 255
local function drawImageTinted(ctx, handle, x, y, w, h, r, g, b, a)
    if not handle or handle == 0 then return end
    a = a or 255
    local color = nvgRGBA(r, g, b, a)
    local paint = nvgImagePatternTinted(ctx, x, y, w, h, 0, handle, color)
    nvgBeginPath(ctx)
    nvgRect(ctx, x, y, w, h)
    nvgFillPaint(ctx, paint)
    nvgFill(ctx)
end

-- ==================== 主绘制函数 ====================

--- 绘制角色头像（方形区域内，与 CharacterPortrait.draw 接口一致）
---@param ctx userdata NanoVG context
---@param x number 左上角 x
---@param y number 左上角 y
---@param size number 头像尺寸（正方形边长）
function PaperDollPortrait.draw(ctx, x, y, size)
    local handles = ensureImages(ctx)

    -- 读取外观数据
    local S = GameState.state
    local hairColorStr = S and S.hairColor or "淡黄色"
    local hairstyleStr = S and S.hairstyle or "及肩长发"

    local hairColor = HAIR_COLORS[hairColorStr] or HAIR_COLORS["淡黄色"]
    local hairFile  = HAIRSTYLE_FILES[hairstyleStr] or "shoulder"

    -- 头像背景框（与原版一致的暗色圆角矩形）
    nvgSave(ctx)

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, x, y, size, size, size * 0.08)
    local bgPaint = nvgRadialGradient(ctx,
        x + size / 2, y + size * 0.4,
        size * 0.1, size * 0.6,
        nvgRGBA(50, 45, 60, 230),
        nvgRGBA(25, 22, 35, 240))
    nvgFillPaint(ctx, bgPaint)
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(100, 95, 120, 160))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)

    -- 裁剪到头像区域
    nvgSave(ctx)
    nvgIntersectScissor(ctx, x, y, size, size)

    -- 图片绘制区域（稍微放大让人物填满头像框）
    local imgScale = 1.15
    local imgW = size * imgScale
    local imgH = size * imgScale
    local imgX = x + (size - imgW) / 2
    local imgY = y + (size - imgH) / 2 - size * 0.02  -- 略微上移

    -- 层 1: face_base（光头 + 身体底）
    drawImage(ctx, handles.face_base, imgX, imgY, imgW, imgH)

    -- 层 2: 表情覆盖层（眼睛、鼻子、嘴巴）
    local exprHandle = handles["expr_" .. currentExpression_]
    if exprHandle and exprHandle ~= 0 then
        drawImage(ctx, exprHandle, imgX, imgY, imgW, imgH)
    end

    -- 层 3: 前发层（用发色染色）
    local hairHandle = handles["hair_" .. hairFile]
    if hairHandle and hairHandle ~= 0 then
        drawImageTinted(ctx, hairHandle, imgX, imgY, imgW, imgH,
            hairColor[1], hairColor[2], hairColor[3], 255)
    end

    nvgRestore(ctx) -- scissor

    nvgRestore(ctx)
end

-- ==================== Galgame 立绘（drawStanding） ====================

--- 绘制 galgame 风格的半身立绘
--- 使用纸娃娃图层合成，与 CharacterPortrait.drawStanding 接口一致
---@param ctx userdata NanoVG context
---@param w number 逻辑宽度
---@param h number 逻辑高度
---@param opts table|nil { hairColor, eyeColor, hairstyle, alpha }
function PaperDollPortrait.drawStanding(ctx, w, h, opts)
    opts = opts or {}
    local handles = ensureImages(ctx)

    local S = GameState.state
    local hairColorStr = opts.hairColor or (S and S.hairColor) or "淡黄色"
    local hairstyleStr = opts.hairstyle or (S and S.hairstyle) or "及肩长发"
    local alpha = opts.alpha or 255

    local hairColor = HAIR_COLORS[hairColorStr] or HAIR_COLORS["淡黄色"]
    local hairFile  = HAIRSTYLE_FILES[hairstyleStr] or "shoulder"

    -- 立绘区域计算（左侧偏下，与原版布局一致）
    local standH = h * 0.7
    local standW = standH  -- 1:1 正方形图片
    local posX = w * 0.18 - standW / 2
    local posY = h - standH + standH * 0.08

    nvgSave(ctx)
    nvgGlobalAlpha(ctx, alpha / 255)

    -- 层 1: face_base
    drawImage(ctx, handles.face_base, posX, posY, standW, standH)

    -- 层 2: 表情
    local exprHandle = handles["expr_" .. currentExpression_]
    if exprHandle and exprHandle ~= 0 then
        drawImage(ctx, exprHandle, posX, posY, standW, standH)
    end

    -- 层 3: 前发（染色）
    local hairHandle = handles["hair_" .. hairFile]
    if hairHandle and hairHandle ~= 0 then
        drawImageTinted(ctx, hairHandle, posX, posY, standW, standH,
            hairColor[1], hairColor[2], hairColor[3], alpha)
    end

    nvgRestore(ctx)
end

return PaperDollPortrait
