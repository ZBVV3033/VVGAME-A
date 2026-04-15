-- ============================================================================
-- CharacterPortrait.lua - 角色头像 + 表情系统（美化版）
-- 在方形区域内绘制角色脸部近景，支持多种表情 + 发型切换
-- 渲染风格：柔和动漫/水彩，使用渐变和精细描边
-- ============================================================================

local GameState = require("systems.GameState")

local CharacterPortrait = {}

local ctx_ = nil
local currentExpression_ = "neutral"

-- ==================== 颜色映射 ====================

local HAIR_COLORS = {
    ["淡黄色"] = { 240, 220, 160 },
    ["黑色"]   = { 45, 40, 42 },
    ["棕色"]   = { 145, 95, 55 },
    ["白色"]   = { 240, 238, 245 },
    ["红色"]   = { 185, 65, 55 },
    ["蓝色"]   = { 75, 110, 185 },
    ["银色"]   = { 205, 205, 215 },
    ["粉色"]   = { 225, 155, 175 },
    ["绿色"]   = { 85, 155, 95 },
    ["紫色"]   = { 135, 85, 175 },
    ["金色"]   = { 220, 190, 100 },
    ["灰色"]   = { 140, 140, 150 },
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

local SKIN         = { 245, 225, 205 }
local SKIN_SHADOW  = { 230, 205, 185 }
local SKIN_LIGHT   = { 255, 240, 225 }
local OUTLINE_SOFT = { 120, 90, 75 }  -- 柔和描边色（替代黑色）

-- ==================== 表情定义 ====================

local EXPRESSIONS = {
    neutral = {
        eyebrowAngle = 0,
        eyebrowOffsetY = 0,
        eyeScaleY = 1.0,
        mouthType = "line",
        blushAlpha = 0,
    },
    happy = {
        eyebrowAngle = 3,
        eyebrowOffsetY = -1,
        eyeScaleY = 0.82,
        mouthType = "smile",
        blushAlpha = 50,
    },
    annoyed = {
        eyebrowAngle = -8,
        eyebrowOffsetY = 2,
        eyeScaleY = 0.68,
        mouthType = "frown",
        blushAlpha = 0,
    },
    sad = {
        eyebrowAngle = -4,
        eyebrowOffsetY = 1,
        eyeScaleY = 0.78,
        mouthType = "frown",
        blushAlpha = 0,
    },
    angry = {
        eyebrowAngle = -10,
        eyebrowOffsetY = 3,
        eyeScaleY = 0.62,
        mouthType = "open",
        blushAlpha = 0,
    },
    surprised = {
        eyebrowAngle = 6,
        eyebrowOffsetY = -3,
        eyeScaleY = 1.2,
        mouthType = "small_o",
        blushAlpha = 0,
    },
    shy = {
        eyebrowAngle = 2,
        eyebrowOffsetY = 0,
        eyeScaleY = 0.72,
        mouthType = "line",
        blushAlpha = 90,
    },
}

-- ==================== 初始化 ====================

function CharacterPortrait.init(nvgCtx)
    ctx_ = nvgCtx
end

-- ==================== 表情切换 ====================

function CharacterPortrait.setExpression(name)
    if EXPRESSIONS[name] then
        currentExpression_ = name
    end
end

function CharacterPortrait.getExpression()
    return currentExpression_
end

-- ==================== 工具函数 ====================

local function setFill(ctx, color, alpha)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha or 255))
end

local function setStroke(ctx, color, width)
    nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], 255))
    nvgStrokeWidth(ctx, width or 1.0)
end

-- 计算高光色（更亮）
local function lighten(color, amount)
    amount = amount or 40
    return {
        math.min(255, color[1] + amount),
        math.min(255, color[2] + amount),
        math.min(255, color[3] + amount),
    }
end

-- 计算阴影色（更暗）
local function darken(color, amount)
    amount = amount or 30
    return {
        math.max(0, color[1] - amount),
        math.max(0, color[2] - amount),
        math.max(0, color[3] - amount),
    }
end

-- ==================== 眼睛绘制（精细版） ====================

local function drawEye(ctx, ex, eyeY, eyeH, eyeColor, side, scale)
    local ec = eyeColor
    local ecDark = darken(ec, 40)
    local ecLight = lighten(ec, 60)

    -- 眼白
    nvgBeginPath(ctx)
    nvgEllipse(ctx, ex, eyeY, 5.2 * scale, eyeH * scale)
    nvgFillColor(ctx, nvgRGBA(250, 248, 252, 255))
    nvgFill(ctx)

    -- 虹膜（渐变：从上暗到下亮）
    local irisR = 4.0 * scale
    local irisPaint = nvgRadialGradient(ctx,
        ex, eyeY - irisR * 0.3,  -- 中心偏上
        irisR * 0.2, irisR,
        nvgRGBA(ecDark[1], ecDark[2], ecDark[3], 255),
        nvgRGBA(ec[1], ec[2], ec[3], 255)
    )
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex, eyeY, irisR)
    nvgFillPaint(ctx, irisPaint)
    nvgFill(ctx)

    -- 虹膜内环
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex, eyeY, irisR * 0.55)
    nvgFillColor(ctx, nvgRGBA(ecDark[1], ecDark[2], ecDark[3], 100))
    nvgFill(ctx)

    -- 瞳孔
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex, eyeY + 0.5 * scale, 1.8 * scale)
    nvgFillColor(ctx, nvgRGBA(10, 8, 8, 255))
    nvgFill(ctx)

    -- 主高光（左上大圆）
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex + side * 1.2 * scale, eyeY - 1.8 * scale, 1.5 * scale)
    nvgFillColor(ctx, nvgRGBA(255, 255, 255, 240))
    nvgFill(ctx)

    -- 副高光（右下小圆）
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex - side * 0.8 * scale, eyeY + 1.2 * scale, 0.8 * scale)
    nvgFillColor(ctx, nvgRGBA(255, 255, 255, 180))
    nvgFill(ctx)

    -- 上眼睑线（粗→细，模拟睫毛）
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, ex - 5.5 * scale, eyeY - eyeH * scale * 0.3)
    nvgBezierTo(ctx,
        ex - 2 * scale, eyeY - eyeH * scale * 0.95,
        ex + 2 * scale, eyeY - eyeH * scale * 0.95,
        ex + 5.5 * scale, eyeY - eyeH * scale * 0.3)
    nvgStrokeColor(ctx, nvgRGBA(OUTLINE_SOFT[1], OUTLINE_SOFT[2], OUTLINE_SOFT[3], 200))
    nvgStrokeWidth(ctx, 1.8 * scale)
    nvgStroke(ctx)

    -- 下眼睑线（细线）
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, ex - 4.5 * scale, eyeY + eyeH * scale * 0.5)
    nvgBezierTo(ctx,
        ex - 1.5 * scale, eyeY + eyeH * scale * 0.9,
        ex + 1.5 * scale, eyeY + eyeH * scale * 0.9,
        ex + 4.5 * scale, eyeY + eyeH * scale * 0.5)
    nvgStrokeColor(ctx, nvgRGBA(OUTLINE_SOFT[1], OUTLINE_SOFT[2], OUTLINE_SOFT[3], 80))
    nvgStrokeWidth(ctx, 0.8 * scale)
    nvgStroke(ctx)
end

-- ==================== 发型绘制函数 ====================

local function drawHair_short(ctx, hairColor, scale)
    local hc = hairColor
    local hcLight = lighten(hc, 35)
    local hcDark = darken(hc, 25)
    local s = scale

    -- 头顶
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -28 * s, 2 * s)
    nvgBezierTo(ctx, -30 * s, -14 * s, -22 * s, -34 * s, 0, -36 * s)
    nvgBezierTo(ctx, 22 * s, -34 * s, 30 * s, -14 * s, 28 * s, 2 * s)
    nvgLineTo(ctx, 22 * s, -4 * s)
    nvgBezierTo(ctx, 22 * s, -20 * s, 16 * s, -28 * s, 0, -30 * s)
    nvgBezierTo(ctx, -16 * s, -28 * s, -22 * s, -20 * s, -22 * s, -4 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2 * s)
    nvgStroke(ctx)

    -- 高光线
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -6 * s, -32 * s)
    nvgBezierTo(ctx, -4 * s, -22 * s, 2 * s, -20 * s, 8 * s, -28 * s)
    nvgStrokeColor(ctx, nvgRGBA(hcLight[1], hcLight[2], hcLight[3], 120))
    nvgStrokeWidth(ctx, 2.5 * s)
    nvgStroke(ctx)

    -- 短碎发两侧
    for _, side in ipairs({ -1, 1 }) do
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 24 * s, -2 * s)
        nvgBezierTo(ctx, side * 28 * s, 6 * s, side * 29 * s, 14 * s, side * 25 * s, 20 * s)
        nvgLineTo(ctx, side * 20 * s, 18 * s)
        nvgBezierTo(ctx, side * 22 * s, 10 * s, side * 22 * s, 4 * s, side * 20 * s, -1 * s)
        nvgClosePath(ctx)
        setFill(ctx, hc)
        nvgFill(ctx)
        setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
        nvgStroke(ctx)
    end

    -- 前刘海
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -16 * s, -24 * s)
    nvgBezierTo(ctx, -10 * s, -14 * s, -4 * s, -14 * s, 0, -18 * s)
    nvgBezierTo(ctx, 4 * s, -14 * s, 10 * s, -14 * s, 16 * s, -24 * s)
    nvgBezierTo(ctx, 12 * s, -28 * s, -12 * s, -28 * s, -16 * s, -24 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
    nvgStroke(ctx)
end

local function drawHair_shoulder(ctx, hairColor, scale)
    local hc = hairColor
    local hcLight = lighten(hc, 35)
    local s = scale

    -- 头顶
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -30 * s, 0)
    nvgBezierTo(ctx, -32 * s, -16 * s, -24 * s, -36 * s, 0, -38 * s)
    nvgBezierTo(ctx, 24 * s, -36 * s, 32 * s, -16 * s, 30 * s, 0)
    nvgLineTo(ctx, 24 * s, -4 * s)
    nvgBezierTo(ctx, 24 * s, -22 * s, 18 * s, -30 * s, 0, -32 * s)
    nvgBezierTo(ctx, -18 * s, -30 * s, -24 * s, -22 * s, -24 * s, -4 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2 * s)
    nvgStroke(ctx)

    -- 高光
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -8 * s, -34 * s)
    nvgBezierTo(ctx, -4 * s, -24 * s, 4 * s, -22 * s, 10 * s, -30 * s)
    nvgStrokeColor(ctx, nvgRGBA(hcLight[1], hcLight[2], hcLight[3], 110))
    nvgStrokeWidth(ctx, 3 * s)
    nvgStroke(ctx)

    -- 左右发束（及肩长度）
    for _, side in ipairs({ -1, 1 }) do
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 26 * s, -4 * s)
        nvgBezierTo(ctx, side * 32 * s, 10 * s, side * 34 * s, 24 * s, side * 28 * s, 38 * s)
        nvgLineTo(ctx, side * 22 * s, 36 * s)
        nvgBezierTo(ctx, side * 26 * s, 20 * s, side * 24 * s, 8 * s, side * 22 * s, -2 * s)
        nvgClosePath(ctx)
        setFill(ctx, hc)
        nvgFill(ctx)
        setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
        nvgStroke(ctx)

        -- 发束高光
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 24 * s, 2 * s)
        nvgBezierTo(ctx, side * 26 * s, 14 * s, side * 25 * s, 26 * s, side * 24 * s, 32 * s)
        nvgStrokeColor(ctx, nvgRGBA(hcLight[1], hcLight[2], hcLight[3], 80))
        nvgStrokeWidth(ctx, 2 * s)
        nvgStroke(ctx)
    end

    -- 前刘海
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -18 * s, -26 * s)
    nvgBezierTo(ctx, -10 * s, -16 * s, -4 * s, -16 * s, 0, -20 * s)
    nvgBezierTo(ctx, 4 * s, -16 * s, 10 * s, -16 * s, 18 * s, -26 * s)
    nvgBezierTo(ctx, 14 * s, -30 * s, -14 * s, -30 * s, -18 * s, -26 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
    nvgStroke(ctx)
end

local function drawHair_long(ctx, hairColor, scale)
    local hc = hairColor
    local hcLight = lighten(hc, 35)
    local s = scale

    -- 头顶（和及肩一样）
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -30 * s, 0)
    nvgBezierTo(ctx, -32 * s, -16 * s, -24 * s, -36 * s, 0, -38 * s)
    nvgBezierTo(ctx, 24 * s, -36 * s, 32 * s, -16 * s, 30 * s, 0)
    nvgLineTo(ctx, 24 * s, -4 * s)
    nvgBezierTo(ctx, 24 * s, -22 * s, 18 * s, -30 * s, 0, -32 * s)
    nvgBezierTo(ctx, -18 * s, -30 * s, -24 * s, -22 * s, -24 * s, -4 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2 * s)
    nvgStroke(ctx)

    -- 高光
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -8 * s, -34 * s)
    nvgBezierTo(ctx, -4 * s, -24 * s, 4 * s, -22 * s, 10 * s, -30 * s)
    nvgStrokeColor(ctx, nvgRGBA(hcLight[1], hcLight[2], hcLight[3], 110))
    nvgStrokeWidth(ctx, 3 * s)
    nvgStroke(ctx)

    -- 左右发束（长发，一直到画布下方）
    for _, side in ipairs({ -1, 1 }) do
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 26 * s, -4 * s)
        nvgBezierTo(ctx, side * 34 * s, 12 * s, side * 36 * s, 30 * s, side * 30 * s, 48 * s)
        nvgLineTo(ctx, side * 22 * s, 46 * s)
        nvgBezierTo(ctx, side * 28 * s, 26 * s, side * 26 * s, 10 * s, side * 22 * s, -2 * s)
        nvgClosePath(ctx)
        setFill(ctx, hc)
        nvgFill(ctx)
        setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
        nvgStroke(ctx)
    end

    -- 前刘海
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -18 * s, -26 * s)
    nvgBezierTo(ctx, -10 * s, -16 * s, -4 * s, -16 * s, 0, -20 * s)
    nvgBezierTo(ctx, 4 * s, -16 * s, 10 * s, -16 * s, 18 * s, -26 * s)
    nvgBezierTo(ctx, 14 * s, -30 * s, -14 * s, -30 * s, -18 * s, -26 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
    nvgStroke(ctx)
end

local function drawHair_ponytail(ctx, hairColor, scale)
    local hc = hairColor
    local hcLight = lighten(hc, 35)
    local s = scale

    -- 头顶（紧贴）
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -28 * s, 0)
    nvgBezierTo(ctx, -30 * s, -14 * s, -22 * s, -34 * s, 0, -36 * s)
    nvgBezierTo(ctx, 22 * s, -34 * s, 30 * s, -14 * s, 28 * s, 0)
    nvgLineTo(ctx, 22 * s, -4 * s)
    nvgBezierTo(ctx, 22 * s, -20 * s, 16 * s, -28 * s, 0, -30 * s)
    nvgBezierTo(ctx, -16 * s, -28 * s, -22 * s, -20 * s, -22 * s, -4 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2 * s)
    nvgStroke(ctx)

    -- 马尾（从后脑勺向右下方延伸）
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, 14 * s, -26 * s)
    nvgBezierTo(ctx, 24 * s, -22 * s, 32 * s, -10 * s, 34 * s, 6 * s)
    nvgBezierTo(ctx, 36 * s, 20 * s, 32 * s, 36 * s, 26 * s, 44 * s)
    nvgLineTo(ctx, 20 * s, 40 * s)
    nvgBezierTo(ctx, 26 * s, 32 * s, 28 * s, 18 * s, 26 * s, 4 * s)
    nvgBezierTo(ctx, 24 * s, -8 * s, 18 * s, -18 * s, 10 * s, -22 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
    nvgStroke(ctx)

    -- 扎发皮筋
    nvgBeginPath(ctx)
    nvgCircle(ctx, 16 * s, -24 * s, 3 * s)
    nvgFillColor(ctx, nvgRGBA(180, 60, 60, 200))
    nvgFill(ctx)

    -- 前刘海
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -16 * s, -24 * s)
    nvgBezierTo(ctx, -10 * s, -14 * s, -4 * s, -14 * s, 0, -18 * s)
    nvgBezierTo(ctx, 4 * s, -14 * s, 8 * s, -16 * s, 12 * s, -24 * s)
    nvgBezierTo(ctx, 8 * s, -28 * s, -12 * s, -28 * s, -16 * s, -24 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
    nvgStroke(ctx)
end

local function drawHair_buzzcut(ctx, hairColor, scale)
    local hc = hairColor
    local s = scale

    -- 寸头：紧贴头皮的薄层
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -24 * s, 2 * s)
    nvgBezierTo(ctx, -26 * s, -12 * s, -20 * s, -30 * s, 0, -32 * s)
    nvgBezierTo(ctx, 20 * s, -30 * s, 26 * s, -12 * s, 24 * s, 2 * s)
    nvgLineTo(ctx, 20 * s, -2 * s)
    nvgBezierTo(ctx, 20 * s, -16 * s, 15 * s, -24 * s, 0, -26 * s)
    nvgBezierTo(ctx, -15 * s, -24 * s, -20 * s, -16 * s, -20 * s, -2 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.0 * s)
    nvgStroke(ctx)
end

local function drawHair_curly(ctx, hairColor, scale)
    local hc = hairColor
    local hcLight = lighten(hc, 35)
    local s = scale

    -- 卷发：蓬松的轮廓
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -32 * s, 4 * s)
    nvgBezierTo(ctx, -36 * s, -8 * s, -28 * s, -36 * s, 0, -40 * s)
    nvgBezierTo(ctx, 28 * s, -36 * s, 36 * s, -8 * s, 32 * s, 4 * s)
    nvgLineTo(ctx, 24 * s, -2 * s)
    nvgBezierTo(ctx, 26 * s, -18 * s, 20 * s, -28 * s, 0, -30 * s)
    nvgBezierTo(ctx, -20 * s, -28 * s, -26 * s, -18 * s, -24 * s, -2 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2 * s)
    nvgStroke(ctx)

    -- 卷曲纹理（几条弧线）
    for i = -2, 2 do
        local ox = i * 8 * s
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, ox - 4 * s, -30 * s + math.abs(i) * 4 * s)
        nvgBezierTo(ctx, ox - 2 * s, -24 * s + math.abs(i) * 4 * s,
            ox + 2 * s, -28 * s + math.abs(i) * 4 * s,
            ox + 4 * s, -22 * s + math.abs(i) * 4 * s)
        nvgStrokeColor(ctx, nvgRGBA(hcLight[1], hcLight[2], hcLight[3], 90))
        nvgStrokeWidth(ctx, 1.5 * s)
        nvgStroke(ctx)
    end

    -- 两侧蓬松卷发
    for _, side in ipairs({ -1, 1 }) do
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 28 * s, -2 * s)
        nvgBezierTo(ctx, side * 36 * s, 8 * s, side * 38 * s, 22 * s, side * 32 * s, 34 * s)
        nvgLineTo(ctx, side * 24 * s, 30 * s)
        nvgBezierTo(ctx, side * 28 * s, 18 * s, side * 28 * s, 6 * s, side * 24 * s, -1 * s)
        nvgClosePath(ctx)
        setFill(ctx, hc)
        nvgFill(ctx)
    end

    -- 前刘海（蓬松）
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -20 * s, -26 * s)
    nvgBezierTo(ctx, -14 * s, -14 * s, -6 * s, -12 * s, 0, -18 * s)
    nvgBezierTo(ctx, 6 * s, -12 * s, 14 * s, -14 * s, 20 * s, -26 * s)
    nvgBezierTo(ctx, 14 * s, -32 * s, -14 * s, -32 * s, -20 * s, -26 * s)
    nvgClosePath(ctx)
    setFill(ctx, hc)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 0.8 * s)
    nvgStroke(ctx)
end

-- 发型名 → 绘制函数映射
local HAIR_DRAW_FUNCS = {
    ["短发"]     = drawHair_short,
    ["寸头"]     = drawHair_buzzcut,
    ["及肩长发"] = drawHair_shoulder,
    ["长发"]     = drawHair_long,
    ["披肩发"]   = drawHair_long,
    ["马尾"]     = drawHair_ponytail,
    ["卷发"]     = drawHair_curly,
    ["编发"]     = drawHair_ponytail,   -- 编发用马尾变体
}

-- ==================== 主绘制函数 ====================

--- 绘制角色头像
---@param ctx userdata NanoVG context
---@param x number 左上角 x
---@param y number 左上角 y
---@param size number 头像尺寸（正方形边长）
function CharacterPortrait.draw(ctx, x, y, size)
    local S = GameState.state
    local hairColorStr = S and S.hairColor or "淡黄色"
    local eyeColorStr  = S and S.eyeColor or "赤色"
    local hairstyleStr = S and S.hairstyle or "及肩长发"
    local hairColor = HAIR_COLORS[hairColorStr] or HAIR_COLORS["淡黄色"]
    local eyeColor  = EYE_COLORS[eyeColorStr] or EYE_COLORS["赤色"]

    local expr = EXPRESSIONS[currentExpression_] or EXPRESSIONS.neutral
    local scale = size / 100

    nvgSave(ctx)
    nvgTranslate(ctx, x + size / 2, y + size / 2)
    nvgScale(ctx, scale, scale)

    -- 头像背景框（柔和暗色）
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, -48, -48, 96, 96, 8)
    local bgPaint = nvgRadialGradient(ctx, 0, -10, 10, 60,
        nvgRGBA(50, 45, 60, 230),
        nvgRGBA(25, 22, 35, 240))
    nvgFillPaint(ctx, bgPaint)
    nvgFill(ctx)
    nvgStrokeColor(ctx, nvgRGBA(100, 95, 120, 160))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)

    -- 脸部（带渐变的椭圆）
    local facePaint = nvgRadialGradient(ctx, 0, -4, 8, 32,
        nvgRGBA(SKIN_LIGHT[1], SKIN_LIGHT[2], SKIN_LIGHT[3], 255),
        nvgRGBA(SKIN_SHADOW[1], SKIN_SHADOW[2], SKIN_SHADOW[3], 255))
    nvgBeginPath(ctx)
    nvgEllipse(ctx, 0, 4, 28, 30)
    nvgFillPaint(ctx, facePaint)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2)
    nvgStroke(ctx)

    -- 腮红
    if expr.blushAlpha > 0 then
        for _, side in ipairs({ -1, 1 }) do
            nvgBeginPath(ctx)
            nvgEllipse(ctx, side * 15, 12, 8, 4.5)
            nvgFillColor(ctx, nvgRGBA(230, 145, 145, expr.blushAlpha))
            nvgFill(ctx)
        end
    end

    -- 眼睛
    local eyeY = 2
    local eyeH = 5.5 * expr.eyeScaleY
    drawEye(ctx, -10, eyeY, eyeH, eyeColor, -1, 1.0)
    drawEye(ctx, 10, eyeY, eyeH, eyeColor, 1, 1.0)

    -- 眉毛
    local brow = expr.eyebrowAngle
    local browY = eyeY - 10 + expr.eyebrowOffsetY
    for _, side in ipairs({ -1, 1 }) do
        nvgSave(ctx)
        nvgTranslate(ctx, side * 10, browY)
        nvgRotate(ctx, math.rad(brow * side))
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -5, 0)
        nvgBezierTo(ctx, -2, -1.5, 2, -1.5, 5, 0)
        nvgStrokeColor(ctx, nvgRGBA(OUTLINE_SOFT[1], OUTLINE_SOFT[2], OUTLINE_SOFT[3], 200))
        nvgStrokeWidth(ctx, 2.0)
        nvgStroke(ctx)
        nvgRestore(ctx)
    end

    -- 嘴巴
    local mouthY = 16
    nvgStrokeColor(ctx, nvgRGBA(OUTLINE_SOFT[1], OUTLINE_SOFT[2], OUTLINE_SOFT[3], 180))
    if expr.mouthType == "line" then
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -4, mouthY)
        nvgBezierTo(ctx, -1, mouthY + 0.8, 1, mouthY + 0.8, 4, mouthY)
        nvgStrokeWidth(ctx, 1.2)
        nvgStroke(ctx)
    elseif expr.mouthType == "smile" then
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -5, mouthY)
        nvgBezierTo(ctx, -3, mouthY + 5, 3, mouthY + 5, 5, mouthY)
        nvgStrokeWidth(ctx, 1.3)
        nvgStroke(ctx)
    elseif expr.mouthType == "frown" then
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -5, mouthY + 2)
        nvgBezierTo(ctx, -3, mouthY - 1, 3, mouthY - 1, 5, mouthY + 2)
        nvgStrokeWidth(ctx, 1.3)
        nvgStroke(ctx)
    elseif expr.mouthType == "open" then
        nvgBeginPath(ctx)
        nvgEllipse(ctx, 0, mouthY + 1, 4, 3)
        nvgFillColor(ctx, nvgRGBA(80, 40, 40, 255))
        nvgFill(ctx)
        setStroke(ctx, OUTLINE_SOFT, 1)
        nvgStroke(ctx)
    elseif expr.mouthType == "small_o" then
        nvgBeginPath(ctx)
        nvgCircle(ctx, 0, mouthY + 1, 3)
        nvgFillColor(ctx, nvgRGBA(80, 40, 40, 255))
        nvgFill(ctx)
        setStroke(ctx, OUTLINE_SOFT, 1)
        nvgStroke(ctx)
    end

    -- 鼻子（微妙的小点）
    nvgBeginPath(ctx)
    nvgCircle(ctx, 0, 9, 1.2)
    nvgFillColor(ctx, nvgRGBA(SKIN_SHADOW[1], SKIN_SHADOW[2], SKIN_SHADOW[3], 120))
    nvgFill(ctx)

    -- 头发（根据发型绘制）
    local drawFunc = HAIR_DRAW_FUNCS[hairstyleStr] or drawHair_shoulder
    drawFunc(ctx, hairColor, 1.0)

    nvgRestore(ctx)
end

-- ==================== Galgame 立绘 ====================

--- 绘制 galgame 风格的半身立绘
---@param ctx userdata NanoVG context
---@param w number 逻辑宽度
---@param h number 逻辑高度
---@param opts table|nil { hairColor, eyeColor, hairstyle, alpha }
function CharacterPortrait.drawStanding(ctx, w, h, opts)
    opts = opts or {}
    local S = GameState.state
    local hairColorStr = opts.hairColor or (S and S.hairColor) or "淡黄色"
    local eyeColorStr  = opts.eyeColor or (S and S.eyeColor) or "赤色"
    local hairstyleStr = opts.hairstyle or (S and S.hairstyle) or "及肩长发"
    local hairColor = HAIR_COLORS[hairColorStr] or HAIR_COLORS["淡黄色"]
    local eyeColor  = EYE_COLORS[eyeColorStr] or EYE_COLORS["赤色"]
    local alpha = opts.alpha or 255

    local expr = EXPRESSIONS[currentExpression_] or EXPRESSIONS.neutral

    local standH = h * 0.45
    local scale = standH / 200
    local cx = w * 0.18
    local cy = h - standH * 0.08

    nvgSave(ctx)
    nvgTranslate(ctx, cx, cy)
    nvgScale(ctx, scale, scale)
    nvgGlobalAlpha(ctx, alpha / 255)

    -- === 身体（上衣部分） ===
    local tunicColor = { 230, 220, 195 }

    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -55, -50)
    nvgLineTo(ctx, 55, -50)
    nvgBezierTo(ctx, 58, 0, 55, 40, 50, 80)
    nvgLineTo(ctx, -50, 80)
    nvgBezierTo(ctx, -55, 40, -58, 0, -55, -50)
    nvgClosePath(ctx)
    setFill(ctx, tunicColor, alpha)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2)
    nvgStroke(ctx)

    -- V领
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -12, -50)
    nvgLineTo(ctx, 0, -25)
    nvgLineTo(ctx, 12, -50)
    setStroke(ctx, OUTLINE_SOFT, 1.2)
    nvgStroke(ctx)

    -- 斜挎带
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -40, -48)
    nvgLineTo(ctx, 40, 30)
    nvgStrokeColor(ctx, nvgRGBA(100, 70, 42, alpha))
    nvgStrokeWidth(ctx, 5)
    nvgStroke(ctx)

    -- === 颈部 ===
    local neckPaint = nvgLinearGradient(ctx, 0, -65, 0, -50,
        nvgRGBA(SKIN[1], SKIN[2], SKIN[3], alpha),
        nvgRGBA(SKIN_SHADOW[1], SKIN_SHADOW[2], SKIN_SHADOW[3], alpha))
    nvgBeginPath(ctx)
    nvgRect(ctx, -8, -65, 16, 18)
    nvgFillPaint(ctx, neckPaint)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2)
    nvgStroke(ctx)

    -- === 头部 ===
    nvgSave(ctx)
    nvgTranslate(ctx, 0, -95)

    -- 脸部轮廓（渐变）
    local facePaint = nvgRadialGradient(ctx, 0, -6, 10, 40,
        nvgRGBA(SKIN_LIGHT[1], SKIN_LIGHT[2], SKIN_LIGHT[3], alpha),
        nvgRGBA(SKIN_SHADOW[1], SKIN_SHADOW[2], SKIN_SHADOW[3], alpha))
    nvgBeginPath(ctx)
    nvgEllipse(ctx, 0, 0, 35, 38)
    nvgFillPaint(ctx, facePaint)
    nvgFill(ctx)
    setStroke(ctx, OUTLINE_SOFT, 1.2)
    nvgStroke(ctx)

    -- 腮红
    if expr.blushAlpha > 0 then
        for _, side in ipairs({ -1, 1 }) do
            nvgBeginPath(ctx)
            nvgEllipse(ctx, side * 18, 10, 9, 5)
            nvgFillColor(ctx, nvgRGBA(230, 145, 145, math.floor(expr.blushAlpha * alpha / 255)))
            nvgFill(ctx)
        end
    end

    -- 眼睛
    local eyeY = -2
    local eyeH = 7 * expr.eyeScaleY
    drawEye(ctx, -13, eyeY, eyeH / 7, eyeColor, -1, 1.3)
    drawEye(ctx, 13, eyeY, eyeH / 7, eyeColor, 1, 1.3)

    -- 眉毛
    local brow = expr.eyebrowAngle
    local browY = eyeY - 12 + expr.eyebrowOffsetY
    for _, side in ipairs({ -1, 1 }) do
        nvgSave(ctx)
        nvgTranslate(ctx, side * 13, browY)
        nvgRotate(ctx, math.rad(brow * side))
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -6, 0)
        nvgBezierTo(ctx, -3, -2, 3, -2, 6, 0)
        nvgStrokeColor(ctx, nvgRGBA(OUTLINE_SOFT[1], OUTLINE_SOFT[2], OUTLINE_SOFT[3], 200))
        nvgStrokeWidth(ctx, 2.5)
        nvgStroke(ctx)
        nvgRestore(ctx)
    end

    -- 鼻子
    nvgBeginPath(ctx)
    nvgCircle(ctx, 0, 8, 1.5)
    nvgFillColor(ctx, nvgRGBA(SKIN_SHADOW[1], SKIN_SHADOW[2], SKIN_SHADOW[3], 100))
    nvgFill(ctx)

    -- 嘴巴
    local mouthY = 16
    nvgStrokeColor(ctx, nvgRGBA(OUTLINE_SOFT[1], OUTLINE_SOFT[2], OUTLINE_SOFT[3], 180))
    if expr.mouthType == "line" then
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -5, mouthY)
        nvgBezierTo(ctx, -2, mouthY + 1, 2, mouthY + 1, 5, mouthY)
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
    elseif expr.mouthType == "smile" then
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -6, mouthY)
        nvgBezierTo(ctx, -4, mouthY + 5, 4, mouthY + 5, 6, mouthY)
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
    elseif expr.mouthType == "frown" then
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, -6, mouthY + 2)
        nvgBezierTo(ctx, -4, mouthY - 1, 4, mouthY - 1, 6, mouthY + 2)
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
    elseif expr.mouthType == "open" then
        nvgBeginPath(ctx)
        nvgEllipse(ctx, 0, mouthY + 1, 5, 4)
        nvgFillColor(ctx, nvgRGBA(80, 40, 40, alpha))
        nvgFill(ctx)
        setStroke(ctx, OUTLINE_SOFT, 1)
        nvgStroke(ctx)
    elseif expr.mouthType == "small_o" then
        nvgBeginPath(ctx)
        nvgCircle(ctx, 0, mouthY + 1, 4)
        nvgFillColor(ctx, nvgRGBA(80, 40, 40, alpha))
        nvgFill(ctx)
        setStroke(ctx, OUTLINE_SOFT, 1)
        nvgStroke(ctx)
    end

    -- 头发
    local drawFunc = HAIR_DRAW_FUNCS[hairstyleStr]
    if drawFunc then
        drawFunc(ctx, hairColor, 1.3)  -- 立绘用更大的 scale
    else
        drawHair_shoulder(ctx, hairColor, 1.3)
    end

    nvgRestore(ctx) -- 头部

    nvgRestore(ctx) -- 全局
end

return CharacterPortrait
