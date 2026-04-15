-- ============================================================================
-- CharacterRenderer.lua - NanoVG 骨骼角色绘制（美化版）
-- 偏中性少女角色，柔和渐变上色，支持发色/瞳色/发型/服装联动
-- 骨骼层级：hip → spine → head/arms/legs，sin 振荡 idle 动画
-- ============================================================================

local CharacterRenderer = {}

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

-- 服装颜色（中世纪幻想风格）
local OUTFIT = {
    tunic       = { 230, 220, 195 },
    tunicShadow = { 210, 200, 175 },
    tunicLight  = { 245, 238, 218 },
    belt        = { 110, 75, 45 },
    pouch       = { 95, 65, 40 },
    satchel     = { 120, 80, 50 },
    strap       = { 100, 70, 42 },
    bracer      = { 100, 70, 40 },
    pants       = { 70, 55, 40 },
    pantsShadow = { 55, 42, 30 },
    boots       = { 80, 60, 40 },
    bootsSole   = { 50, 38, 25 },
    skin        = { 245, 225, 205 },
    skinShadow  = { 225, 200, 180 },
    skinLight   = { 255, 240, 225 },
    outline     = { 120, 90, 75 },   -- 柔和描边
}

-- ==================== 工具函数 ====================

local function lighten(color, amount)
    amount = amount or 40
    return {
        math.min(255, color[1] + amount),
        math.min(255, color[2] + amount),
        math.min(255, color[3] + amount),
    }
end

local function darken(color, amount)
    amount = amount or 30
    return {
        math.max(0, color[1] - amount),
        math.max(0, color[2] - amount),
        math.max(0, color[3] - amount),
    }
end

-- ==================== 动画状态机 ====================

local currentAnim_ = "idle"
local prevAnim_ = "idle"
local blendAlpha_ = 1.0
local BLEND_SPEED = 4.0
local time_ = 0

local anim = {
    spineOffsetY = 0, spineRot = 0, headRot = 0,
    hairLRot = 0, hairRRot = 0,
    armLRot = 0, armRRot = 0,
    forearmLRot = 0, forearmRRot = 0,
    legLRot = 0, legRRot = 0,
    satchelRot = 0, tunicSwing = 0,
    bodyBob = 0, wavePhase = 0,
}

local prevFrame = {}
local ctx_ = nil

-- ==================== 初始化 ====================

function CharacterRenderer.init(nvgCtx)
    ctx_ = nvgCtx
end

-- ==================== 动画切换 ====================

function CharacterRenderer.setAnimation(name)
    if name == currentAnim_ then return end
    for k, v in pairs(anim) do prevFrame[k] = v end
    prevAnim_ = currentAnim_
    currentAnim_ = name
    blendAlpha_ = 0.0
end

function CharacterRenderer.getAnimation()
    return currentAnim_
end

-- ==================== 动画计算函数 ====================

local function calcIdle(t, a)
    a.spineOffsetY = math.sin(t * 1.8) * 1.2
    a.spineRot     = math.sin(t * 1.8) * 0.004
    a.headRot      = math.sin(t * 1.2 + 0.3) * 0.015
    a.hairLRot     = math.sin(t * 2.2 + 0.5) * 0.05
    a.hairRRot     = math.sin(t * 2.2) * -0.05
    a.armLRot      = math.sin(t * 1.5) * 0.03
    a.armRRot      = math.sin(t * 1.5 + math.pi) * 0.03
    a.forearmLRot  = math.sin(t * 1.8 + 0.5) * 0.02
    a.forearmRRot  = math.sin(t * 1.8 + math.pi + 0.5) * 0.02
    a.legLRot      = math.sin(t * 1.0) * 0.008
    a.legRRot      = math.sin(t * 1.0 + math.pi) * 0.008
    a.satchelRot   = math.sin(t * 1.8 + 0.2) * 0.02
    a.tunicSwing   = math.sin(t * 2.0) * 2
    a.bodyBob      = 0
    a.wavePhase    = 0
end

local function calcWalk(t, a)
    local ws = 4.0
    local st = math.sin(t * ws)
    a.spineOffsetY = math.sin(t * ws * 2) * 1.5
    a.spineRot     = math.sin(t * ws) * 0.015
    a.headRot      = math.sin(t * ws + 0.5) * 0.01
    a.hairLRot     = math.sin(t * ws * 1.5 + 0.5) * 0.08
    a.hairRRot     = math.sin(t * ws * 1.5) * -0.08
    a.armLRot      = st * 0.15
    a.armRRot      = -st * 0.15
    a.forearmLRot  = math.max(0, st) * 0.08
    a.forearmRRot  = math.max(0, -st) * 0.08
    a.legLRot      = st * 0.12
    a.legRRot      = -st * 0.12
    a.satchelRot   = math.sin(t * ws + 0.3) * 0.04
    a.tunicSwing   = math.sin(t * ws) * 4
    a.bodyBob      = math.sin(t * ws * 2) * 1.5
    a.wavePhase    = 0
end

local function calcWave(t, a)
    a.spineOffsetY = math.sin(t * 1.8) * 1.0
    a.spineRot     = math.sin(t * 1.8) * 0.003
    a.headRot      = math.sin(t * 1.5) * 0.02
    a.hairLRot     = math.sin(t * 2.2 + 0.5) * 0.04
    a.hairRRot     = math.sin(t * 2.2) * -0.04
    a.armLRot      = math.sin(t * 1.5) * 0.02
    a.forearmLRot  = math.sin(t * 1.8 + 0.5) * 0.015
    a.armRRot      = -0.55
    a.forearmRRot  = -0.3 + math.sin(t * 5.0) * 0.25
    a.legLRot      = math.sin(t * 1.0) * 0.005
    a.legRRot      = math.sin(t * 1.0 + math.pi) * 0.005
    a.satchelRot   = math.sin(t * 1.8 + 0.2) * 0.02
    a.tunicSwing   = math.sin(t * 2.0) * 1.5
    a.bodyBob      = 0
    a.wavePhase    = math.sin(t * 5.0)
end

local function calcTalk(t, a)
    a.spineOffsetY = math.sin(t * 1.8) * 1.0
    a.spineRot     = math.sin(t * 2.5) * 0.008
    a.headRot      = math.sin(t * 3.0) * 0.025 + math.sin(t * 1.0) * 0.01
    a.hairLRot     = math.sin(t * 2.5 + 0.5) * 0.05
    a.hairRRot     = math.sin(t * 2.5) * -0.05
    a.armLRot      = math.sin(t * 2.0) * 0.06
    a.armRRot      = math.sin(t * 2.0 + 1.0) * 0.05
    a.forearmLRot  = math.sin(t * 2.5 + 0.5) * 0.04
    a.forearmRRot  = math.sin(t * 2.5 + 1.5) * 0.03
    a.legLRot      = math.sin(t * 1.0) * 0.005
    a.legRRot      = math.sin(t * 1.0 + math.pi) * 0.005
    a.satchelRot   = math.sin(t * 2.0 + 0.2) * 0.02
    a.tunicSwing   = math.sin(t * 2.2) * 2
    a.bodyBob      = 0
    a.wavePhase    = 0
end

local ANIM_FUNCS = {
    idle = calcIdle, walk = calcWalk, wave = calcWave, talk = calcTalk,
}

-- ==================== 动画更新 ====================

function CharacterRenderer.update(dt)
    time_ = time_ + dt
    local fn = ANIM_FUNCS[currentAnim_] or calcIdle
    fn(time_, anim)
    if blendAlpha_ < 1.0 then
        blendAlpha_ = math.min(1.0, blendAlpha_ + dt * BLEND_SPEED)
        local a = blendAlpha_
        for k, v in pairs(anim) do
            local pv = prevFrame[k]
            if pv then anim[k] = pv + (v - pv) * a end
        end
    end
end

-- ==================== 绘制工具 ====================

local function setFill(ctx, color, alpha)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha or 255))
end

local function setStroke(ctx, color, width, alpha)
    nvgStrokeColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha or 255))
    nvgStrokeWidth(ctx, width or 1.0)
end

local function drawFilledPath(ctx, fillColor, outlineColor, outlineWidth)
    setFill(ctx, fillColor)
    nvgFill(ctx)
    if outlineColor then
        setStroke(ctx, outlineColor, outlineWidth or 1.2)
        nvgStroke(ctx)
    end
end

-- ==================== 身体部位绘制 ====================

local function drawBoot(ctx, x, y, flipX)
    local sx = flipX and -1 or 1
    nvgSave(ctx)
    nvgTranslate(ctx, x, y)
    nvgScale(ctx, sx, 1)

    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -8, 0)
    nvgLineTo(ctx, -8, 18)
    nvgLineTo(ctx, 14, 18)
    nvgLineTo(ctx, 14, 12)
    nvgLineTo(ctx, 8, 0)
    nvgClosePath(ctx)
    drawFilledPath(ctx, OUTFIT.boots, OUTFIT.outline)

    nvgBeginPath(ctx)
    nvgRect(ctx, -10, 16, 26, 4)
    drawFilledPath(ctx, OUTFIT.bootsSole, OUTFIT.outline)

    nvgRestore(ctx)
end

local function drawLeg(ctx, x, y, rot, flipX)
    local sx = flipX and -1 or 1
    nvgSave(ctx)
    nvgTranslate(ctx, x, y)
    nvgRotate(ctx, rot)

    -- 大腿（渐变裤子）
    local pantsPaint = nvgLinearGradient(ctx, -10 * sx, 0, 10 * sx, 50,
        nvgRGBA(OUTFIT.pants[1], OUTFIT.pants[2], OUTFIT.pants[3], 255),
        nvgRGBA(OUTFIT.pantsShadow[1], OUTFIT.pantsShadow[2], OUTFIT.pantsShadow[3], 255))
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -10 * sx, 0)
    nvgLineTo(ctx, -9 * sx, 50)
    nvgLineTo(ctx, 9 * sx, 50)
    nvgLineTo(ctx, 10 * sx, 0)
    nvgClosePath(ctx)
    nvgFillPaint(ctx, pantsPaint)
    nvgFill(ctx)
    setStroke(ctx, OUTFIT.outline, 1.0)
    nvgStroke(ctx)

    -- 小腿
    nvgSave(ctx)
    nvgTranslate(ctx, 0, 50)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -8 * sx, 0)
    nvgLineTo(ctx, -7 * sx, 45)
    nvgLineTo(ctx, 7 * sx, 45)
    nvgLineTo(ctx, 8 * sx, 0)
    nvgClosePath(ctx)
    drawFilledPath(ctx, OUTFIT.pants, OUTFIT.outline)
    drawBoot(ctx, 0, 42, flipX)
    nvgRestore(ctx)

    nvgRestore(ctx)
end

local function drawArm(ctx, x, y, upperRot, forearmRot, flipX)
    nvgSave(ctx)
    nvgTranslate(ctx, x, y)
    nvgRotate(ctx, upperRot)

    -- 上臂袖子（渐变）
    local sleevePaint = nvgLinearGradient(ctx, -7, 0, 7, 55,
        nvgRGBA(OUTFIT.tunicLight[1], OUTFIT.tunicLight[2], OUTFIT.tunicLight[3], 255),
        nvgRGBA(OUTFIT.tunicShadow[1], OUTFIT.tunicShadow[2], OUTFIT.tunicShadow[3], 255))
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -7, 0)
    nvgBezierTo(ctx, -8, 20, -7, 40, -6, 55)
    nvgLineTo(ctx, 6, 55)
    nvgBezierTo(ctx, 7, 40, 8, 20, 7, 0)
    nvgClosePath(ctx)
    nvgFillPaint(ctx, sleevePaint)
    nvgFill(ctx)
    setStroke(ctx, OUTFIT.outline, 1.0)
    nvgStroke(ctx)

    -- 前臂
    nvgSave(ctx)
    nvgTranslate(ctx, 0, 55)
    nvgRotate(ctx, forearmRot)

    -- 肤色前臂（渐变）
    local armPaint = nvgLinearGradient(ctx, 0, 0, 0, 38,
        nvgRGBA(OUTFIT.skin[1], OUTFIT.skin[2], OUTFIT.skin[3], 255),
        nvgRGBA(OUTFIT.skinShadow[1], OUTFIT.skinShadow[2], OUTFIT.skinShadow[3], 255))
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -5, 0)
    nvgLineTo(ctx, -4, 38)
    nvgLineTo(ctx, 4, 38)
    nvgLineTo(ctx, 5, 0)
    nvgClosePath(ctx)
    nvgFillPaint(ctx, armPaint)
    nvgFill(ctx)
    setStroke(ctx, OUTFIT.outline, 1.0)
    nvgStroke(ctx)

    -- 护腕
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, -6, 22, 12, 14, 2)
    drawFilledPath(ctx, OUTFIT.bracer, OUTFIT.outline)

    -- 手
    nvgBeginPath(ctx)
    nvgEllipse(ctx, 0, 42, 5, 6)
    drawFilledPath(ctx, OUTFIT.skin, OUTFIT.outline, 0.8)

    nvgRestore(ctx)
    nvgRestore(ctx)
end

local function drawTorso(ctx)
    nvgSave(ctx)
    nvgTranslate(ctx, 0, anim.spineOffsetY)
    nvgRotate(ctx, anim.spineRot)

    -- 上衣主体（渐变）
    local tunicPaint = nvgLinearGradient(ctx, -28, -60, 28, 30,
        nvgRGBA(OUTFIT.tunicLight[1], OUTFIT.tunicLight[2], OUTFIT.tunicLight[3], 255),
        nvgRGBA(OUTFIT.tunicShadow[1], OUTFIT.tunicShadow[2], OUTFIT.tunicShadow[3], 255))
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -28, -60)
    nvgLineTo(ctx, 28, -60)
    nvgBezierTo(ctx, 30, -30, 28, 0, 26 + anim.tunicSwing, 30)
    nvgLineTo(ctx, -26 - anim.tunicSwing, 30)
    nvgBezierTo(ctx, -28, 0, -30, -30, -28, -60)
    nvgClosePath(ctx)
    nvgFillPaint(ctx, tunicPaint)
    nvgFill(ctx)
    setStroke(ctx, OUTFIT.outline, 1.2)
    nvgStroke(ctx)

    -- V领
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -8, -60)
    nvgLineTo(ctx, 0, -42)
    nvgLineTo(ctx, 8, -60)
    setStroke(ctx, OUTFIT.outline, 1.2)
    nvgStroke(ctx)

    -- 衣服阴影线
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -18, -55)
    nvgBezierTo(ctx, -20, -30, -19, 0, -17, 25)
    nvgStrokeColor(ctx, nvgRGBA(OUTFIT.tunicShadow[1], OUTFIT.tunicShadow[2], OUTFIT.tunicShadow[3], 60))
    nvgStrokeWidth(ctx, 2.5)
    nvgStroke(ctx)

    -- 斜挎带+包
    nvgSave(ctx)
    nvgRotate(ctx, anim.satchelRot)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -22, -58)
    nvgLineTo(ctx, 22, 20)
    setStroke(ctx, OUTFIT.strap, 4)
    nvgStroke(ctx)

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, 14, 12, 18, 22, 3)
    drawFilledPath(ctx, OUTFIT.satchel, OUTFIT.outline)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, 13, 10, 20, 10, 3)
    drawFilledPath(ctx, OUTFIT.strap, OUTFIT.outline)
    nvgRestore(ctx)

    -- 腰带
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, -27, 15, 54, 8, 2)
    drawFilledPath(ctx, OUTFIT.belt, OUTFIT.outline)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, -4, 14, 8, 10, 2)
    nvgStrokeColor(ctx, nvgRGBA(150, 130, 80, 255))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)

    -- 左腰包
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, -24, 20, 14, 16, 2)
    drawFilledPath(ctx, OUTFIT.pouch, OUTFIT.outline)

    nvgRestore(ctx)
end

local function drawNeck(ctx)
    local neckPaint = nvgLinearGradient(ctx, 0, -68, 0, -56,
        nvgRGBA(OUTFIT.skin[1], OUTFIT.skin[2], OUTFIT.skin[3], 255),
        nvgRGBA(OUTFIT.skinShadow[1], OUTFIT.skinShadow[2], OUTFIT.skinShadow[3], 255))
    nvgBeginPath(ctx)
    nvgRect(ctx, -5, -68 + anim.spineOffsetY, 10, 12)
    nvgFillPaint(ctx, neckPaint)
    nvgFill(ctx)
    setStroke(ctx, OUTFIT.outline, 1.0)
    nvgStroke(ctx)
end

-- ==================== 精细眼睛绘制 ====================

local function drawEye(ctx, ex, eyeY, eyeColor, side)
    local ec = eyeColor
    local ecDark = darken(ec, 40)

    -- 眼白
    nvgBeginPath(ctx)
    nvgEllipse(ctx, ex, eyeY, 4.2, 4.5)
    nvgFillColor(ctx, nvgRGBA(250, 248, 252, 255))
    nvgFill(ctx)

    -- 虹膜（渐变）
    local irisR = 3.2
    local irisPaint = nvgRadialGradient(ctx, ex, eyeY - irisR * 0.3, irisR * 0.2, irisR,
        nvgRGBA(ecDark[1], ecDark[2], ecDark[3], 255),
        nvgRGBA(ec[1], ec[2], ec[3], 255))
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex, eyeY, irisR)
    nvgFillPaint(ctx, irisPaint)
    nvgFill(ctx)

    -- 瞳孔
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex, eyeY + 0.3, 1.5)
    nvgFillColor(ctx, nvgRGBA(10, 8, 8, 255))
    nvgFill(ctx)

    -- 主高光
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex + side * 1, eyeY - 1.5, 1.2)
    nvgFillColor(ctx, nvgRGBA(255, 255, 255, 240))
    nvgFill(ctx)

    -- 副高光
    nvgBeginPath(ctx)
    nvgCircle(ctx, ex - side * 0.5, eyeY + 1.0, 0.6)
    nvgFillColor(ctx, nvgRGBA(255, 255, 255, 160))
    nvgFill(ctx)

    -- 上眼睑线
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, ex - 4.5, eyeY - 1)
    nvgBezierTo(ctx, ex - 1.5, eyeY - 4.5, ex + 1.5, eyeY - 4.5, ex + 4.5, eyeY - 1)
    nvgStrokeColor(ctx, nvgRGBA(OUTFIT.outline[1], OUTFIT.outline[2], OUTFIT.outline[3], 200))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)
end

-- ==================== 头发绘制（根据发型） ====================

local function drawHairBase(ctx, hairColor)
    -- 头顶基础形状（所有发型共享）
    local hc = hairColor
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -24, -2)
    nvgBezierTo(ctx, -26, -18, -18, -30, 0, -32)
    nvgBezierTo(ctx, 18, -30, 26, -18, 24, -2)
    nvgLineTo(ctx, 20, -6)
    nvgBezierTo(ctx, 20, -20, 14, -26, 0, -28)
    nvgBezierTo(ctx, -14, -26, -20, -20, -20, -6)
    nvgClosePath(ctx)
    drawFilledPath(ctx, hc, OUTFIT.outline, 1.2)
end

local function drawHairBangs(ctx, hairColor)
    local hc = hairColor
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -14, -22)
    nvgBezierTo(ctx, -8, -14, -4, -14, 0, -18)
    nvgBezierTo(ctx, 4, -14, 8, -14, 14, -22)
    nvgBezierTo(ctx, 10, -26, -10, -26, -14, -22)
    nvgClosePath(ctx)
    drawFilledPath(ctx, hc, OUTFIT.outline, 0.8)
end

local function drawHairHighlight(ctx, hairColor)
    local hcLight = lighten(hairColor, 35)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -5, -28)
    nvgBezierTo(ctx, -3, -20, 2, -18, 7, -24)
    nvgStrokeColor(ctx, nvgRGBA(hcLight[1], hcLight[2], hcLight[3], 100))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)
end

local function drawHairSides_short(ctx, hairColor)
    local hc = hairColor
    for _, side in ipairs({ -1, 1 }) do
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 22, -4)
        nvgBezierTo(ctx, side * 26, 4, side * 27, 12, side * 23, 20)
        nvgLineTo(ctx, side * 18, 18)
        nvgBezierTo(ctx, side * 20, 10, side * 20, 2, side * 18, -2)
        nvgClosePath(ctx)
        drawFilledPath(ctx, hc, OUTFIT.outline, 0.8)
    end
end

local function drawHairSides_shoulder(ctx, hairColor)
    local hc = hairColor
    local hcLight = lighten(hc, 35)
    for _, side in ipairs({ -1, 1 }) do
        nvgSave(ctx)
        nvgTranslate(ctx, side * 18, -8)
        nvgRotate(ctx, side < 0 and anim.hairLRot or anim.hairRRot)
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 4, -6)
        nvgBezierTo(ctx, side * 10, 4, side * 12, 16, side * 8, 32)
        nvgLineTo(ctx, side * 2, 30)
        nvgBezierTo(ctx, side * 4, 14, side * 2, 2, -side * 2, -4)
        nvgClosePath(ctx)
        drawFilledPath(ctx, hc, OUTFIT.outline, 0.8)
        -- 高光线
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 4, 0)
        nvgBezierTo(ctx, side * 6, 10, side * 5, 20, side * 4, 26)
        nvgStrokeColor(ctx, nvgRGBA(hcLight[1], hcLight[2], hcLight[3], 70))
        nvgStrokeWidth(ctx, 1.5)
        nvgStroke(ctx)
        nvgRestore(ctx)
    end
end

local function drawHairSides_long(ctx, hairColor)
    local hc = hairColor
    local hcLight = lighten(hc, 35)
    for _, side in ipairs({ -1, 1 }) do
        nvgSave(ctx)
        nvgTranslate(ctx, side * 18, -8)
        nvgRotate(ctx, side < 0 and anim.hairLRot or anim.hairRRot)
        nvgBeginPath(ctx)
        nvgMoveTo(ctx, side * 4, -6)
        nvgBezierTo(ctx, side * 12, 8, side * 14, 26, side * 10, 48)
        nvgLineTo(ctx, side * 2, 44)
        nvgBezierTo(ctx, side * 6, 22, side * 4, 6, -side * 2, -4)
        nvgClosePath(ctx)
        drawFilledPath(ctx, hc, OUTFIT.outline, 0.8)
        nvgRestore(ctx)
    end
end

local function drawHairPonytail(ctx, hairColor)
    local hc = hairColor
    -- 马尾从后脑延伸
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, 12, -22)
    nvgBezierTo(ctx, 22, -18, 28, -8, 30, 4)
    nvgBezierTo(ctx, 32, 16, 28, 30, 22, 40)
    nvgLineTo(ctx, 16, 36)
    nvgBezierTo(ctx, 22, 26, 24, 14, 22, 2)
    nvgBezierTo(ctx, 20, -6, 14, -14, 8, -18)
    nvgClosePath(ctx)
    drawFilledPath(ctx, hc, OUTFIT.outline, 0.8)

    -- 扎发皮筋
    nvgBeginPath(ctx)
    nvgCircle(ctx, 14, -20, 2.5)
    nvgFillColor(ctx, nvgRGBA(180, 60, 60, 200))
    nvgFill(ctx)
end

-- 发型 → 绘制函数
local HAIRSTYLE_MAP = {
    ["短发"]     = function(ctx, hc) drawHairBase(ctx, hc); drawHairSides_short(ctx, hc); drawHairBangs(ctx, hc); drawHairHighlight(ctx, hc) end,
    ["寸头"]     = function(ctx, hc) drawHairBase(ctx, hc) end,
    ["及肩长发"] = function(ctx, hc) drawHairBase(ctx, hc); drawHairSides_shoulder(ctx, hc); drawHairBangs(ctx, hc); drawHairHighlight(ctx, hc) end,
    ["长发"]     = function(ctx, hc) drawHairBase(ctx, hc); drawHairSides_long(ctx, hc); drawHairBangs(ctx, hc); drawHairHighlight(ctx, hc) end,
    ["披肩发"]   = function(ctx, hc) drawHairBase(ctx, hc); drawHairSides_long(ctx, hc); drawHairBangs(ctx, hc); drawHairHighlight(ctx, hc) end,
    ["马尾"]     = function(ctx, hc) drawHairBase(ctx, hc); drawHairPonytail(ctx, hc); drawHairBangs(ctx, hc); drawHairHighlight(ctx, hc) end,
    ["卷发"]     = function(ctx, hc) drawHairBase(ctx, hc); drawHairSides_shoulder(ctx, hc); drawHairBangs(ctx, hc); drawHairHighlight(ctx, hc) end,
    ["编发"]     = function(ctx, hc) drawHairBase(ctx, hc); drawHairPonytail(ctx, hc); drawHairBangs(ctx, hc); drawHairHighlight(ctx, hc) end,
}

-- ==================== 头部绘制 ====================

local function drawHead(ctx, hairColor, eyeColor, hairstyle)
    nvgSave(ctx)
    nvgTranslate(ctx, 0, -78 + anim.spineOffsetY)
    nvgRotate(ctx, anim.headRot)

    -- 脸部（渐变皮肤）
    local facePaint = nvgRadialGradient(ctx, 0, -4, 6, 26,
        nvgRGBA(OUTFIT.skinLight[1], OUTFIT.skinLight[2], OUTFIT.skinLight[3], 255),
        nvgRGBA(OUTFIT.skinShadow[1], OUTFIT.skinShadow[2], OUTFIT.skinShadow[3], 255))
    nvgBeginPath(ctx)
    nvgEllipse(ctx, 0, 0, 22, 24)
    nvgFillPaint(ctx, facePaint)
    nvgFill(ctx)
    setStroke(ctx, OUTFIT.outline, 1.2)
    nvgStroke(ctx)

    -- 眼睛
    drawEye(ctx, -8, -2, eyeColor, -1)
    drawEye(ctx, 8, -2, eyeColor, 1)

    -- 鼻子
    nvgBeginPath(ctx)
    nvgCircle(ctx, 0, 5, 1)
    nvgFillColor(ctx, nvgRGBA(OUTFIT.skinShadow[1], OUTFIT.skinShadow[2], OUTFIT.skinShadow[3], 100))
    nvgFill(ctx)

    -- 嘴巴
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, -3, 8)
    nvgBezierTo(ctx, -1, 9, 1, 9, 3, 8)
    nvgStrokeColor(ctx, nvgRGBA(OUTFIT.outline[1], OUTFIT.outline[2], OUTFIT.outline[3], 160))
    nvgStrokeWidth(ctx, 1.2)
    nvgStroke(ctx)

    -- 头发（根据发型选择绘制函数）
    local drawFunc = HAIRSTYLE_MAP[hairstyle] or HAIRSTYLE_MAP["及肩长发"]
    drawFunc(ctx, hairColor)

    nvgRestore(ctx)
end

-- ==================== 主绘制函数 ====================

--- 绘制完整角色
---@param ctx userdata NanoVG context
---@param w number 逻辑宽度
---@param h number 逻辑高度
---@param opts table { hairColor, eyeColor, hairstyle, outfit }
function CharacterRenderer.draw(ctx, w, h, opts)
    local hairColorStr = opts.hairColor or "淡黄色"
    local eyeColorStr  = opts.eyeColor or "赤色"
    local hairstyleStr = opts.hairstyle or "及肩长发"

    local hairColor = HAIR_COLORS[hairColorStr] or HAIR_COLORS["淡黄色"]
    local eyeColor  = EYE_COLORS[eyeColorStr] or EYE_COLORS["赤色"]

    -- 角色定位：画面右侧
    local cx = w * 0.7
    local cy = h * 0.82
    local scale = math.min(h / 550, w / 400) * 0.85

    nvgSave(ctx)
    nvgTranslate(ctx, cx, cy)
    nvgScale(ctx, scale, scale)

    -- 绘制顺序：后层 → 前层
    drawLeg(ctx, 10, 28, anim.legRRot, false)
    drawArm(ctx, -30, -55 + anim.spineOffsetY, anim.armLRot, anim.forearmLRot, true)
    drawTorso(ctx)
    drawLeg(ctx, -10, 28, anim.legLRot, true)
    drawArm(ctx, 30, -55 + anim.spineOffsetY, anim.armRRot, anim.forearmRRot, false)
    drawNeck(ctx)
    drawHead(ctx, hairColor, eyeColor, hairstyleStr)

    nvgRestore(ctx)
end

return CharacterRenderer
