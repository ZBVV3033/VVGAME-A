-- ============================================================================
-- SceneView.lua - 场景视图总控（动态角色 + 浮动窗口 + 头像层）
-- Context 1: avatarCtx  (renderOrder 999998，始终可见，绘制状态栏头像)
-- Context 2: floatCtx   (renderOrder 999995，场景可见时绘制浮动窗口)
-- 角色外观从 GameState 读取，和换装系统联动
-- ============================================================================

local SceneBackground   = require("systems.SceneBackground")
local CharacterRenderer = require("systems.CharacterRenderer")
local CharacterPortrait = require("systems.PaperDollPortrait")
local GameState         = require("systems.GameState")

local SceneView = {}

-- ==================== NanoVG Contexts ====================
local floatCtx = nil      -- 浮动窗口 context（renderOrder 999995）
local avatarCtx = nil     -- 头像 context（renderOrder 999998，始终可见）
local fontFloat = nil
local fontAvatar = nil

-- ==================== 场景状态 ====================
local visible = false
local currentLocation = nil
local elapsedTime = 0

-- ==================== 浮动窗口状态 ====================
local floatWin = {
    x = 0, y = 0,
    w = 0, h = 0,
    expanded = false,
    dragging = false,
    dragOffX = 0,
    dragOffY = 0,
    titleH = 28,
    animProgress = 1.0,
    animFrom = {},
    animTo = {},
    inited = false,
}

-- ==================== 初始化 ====================

function SceneView.init()
    -- 浮动窗口层（在 UI 之上）
    floatCtx = nvgCreate(1)
    if not floatCtx then
        log:Write(LOG_ERROR, "[SceneView] Failed to create float NanoVG context")
        return
    end
    nvgSetRenderOrder(floatCtx, 999995)
    fontFloat = nvgCreateFont(floatCtx, "sans", "Fonts/MiSans-Regular.ttf")

    -- 头像层（始终可见，在 UI 之上）
    avatarCtx = nvgCreate(1)
    if avatarCtx then
        nvgSetRenderOrder(avatarCtx, 999998)
        fontAvatar = nvgCreateFont(avatarCtx, "sans", "Fonts/MiSans-Regular.ttf")
        SubscribeToEvent(avatarCtx, "NanoVGRender", "HandleAvatarRender")
    end

    -- 初始化角色渲染器
    CharacterRenderer.init(floatCtx)
    CharacterPortrait.init(avatarCtx)

    -- 初始化色块背景模块
    SceneBackground.init(nil)

    -- 订阅渲染事件
    SubscribeToEvent(floatCtx, "NanoVGRender", "HandleFloatWindowRender")

    -- 订阅鼠标事件（用于拖拽浮动窗口）
    SubscribeToEvent("MouseButtonDown", "HandleSceneMouseDown")
    SubscribeToEvent("MouseMove", "HandleSceneMouseMove")
    SubscribeToEvent("MouseButtonUp", "HandleSceneMouseUp")

    log:Write(LOG_INFO, "[SceneView] Initialized (float=999995, avatar=999998)")
end

-- ==================== 场景切换 ====================

function SceneView.setLocation(locationName)
    currentLocation = locationName
    visible = locationName ~= nil and SceneBackground.hasScene(locationName)
end

function SceneView.isVisible()
    return visible
end

-- ==================== 动画/表情代理 ====================

function SceneView.setAnimation(name)
    CharacterRenderer.setAnimation(name)
end

function SceneView.setExpression(name)
    CharacterPortrait.setExpression(name)
end

-- ==================== 浮动窗口尺寸计算 ====================

local function getScreenLogical()
    local physW = graphics:GetWidth()
    local physH = graphics:GetHeight()
    local dpr = graphics:GetDPR()
    return physW / dpr, physH / dpr, dpr
end

local function calcSmallRect(w, h)
    local area = w * h / 6
    local ratio = 3 / 4
    local fw = math.sqrt(area * ratio)
    local fh = fw / ratio
    local margin = 12
    return {
        x = w - fw - margin,
        y = margin,
        w = fw,
        h = fh,
    }
end

local function calcLargeRect(w, h)
    local area = w * h / 2
    local ratio = 3 / 4
    local fw = math.sqrt(area * ratio)
    local fh = fw / ratio
    return {
        x = (w - fw) / 2,
        y = (h - fh) / 2,
        w = fw,
        h = fh,
    }
end

local function initFloatWindow(w, h)
    if floatWin.inited then return end
    local r = calcSmallRect(w, h)
    floatWin.x = r.x
    floatWin.y = r.y
    floatWin.w = r.w
    floatWin.h = r.h
    floatWin.expanded = false
    floatWin.animProgress = 1.0
    floatWin.inited = true
end

-- ==================== 每帧更新 ====================

function SceneView.update(dt)
    elapsedTime = elapsedTime + dt

    -- 角色动画始终更新（头像也需要呼吸动画感）
    CharacterRenderer.update(dt)

    if not visible then return end

    -- 缩放动画
    if floatWin.animProgress < 1.0 then
        floatWin.animProgress = math.min(1.0, floatWin.animProgress + dt * 4.0)
        local t = floatWin.animProgress
        local ease = 1 - (1 - t) * (1 - t) * (1 - t)
        local from = floatWin.animFrom
        local to = floatWin.animTo
        floatWin.x = from.x + (to.x - from.x) * ease
        floatWin.y = from.y + (to.y - from.y) * ease
        floatWin.w = from.w + (to.w - from.w) * ease
        floatWin.h = from.h + (to.h - from.h) * ease
    end
end

-- ==================== 清理 ====================

function SceneView.shutdown()
    if floatCtx then nvgDelete(floatCtx); floatCtx = nil end
    if avatarCtx then nvgDelete(avatarCtx); avatarCtx = nil end
    log:Write(LOG_INFO, "[SceneView] Shutdown")
end

-- ==================== 浮动窗口交互 ====================

local function isInRect(mx, my, rx, ry, rw, rh)
    return mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh
end

local function toggleExpand()
    local w, h = getScreenLogical()
    floatWin.animFrom = { x = floatWin.x, y = floatWin.y, w = floatWin.w, h = floatWin.h }
    if floatWin.expanded then
        floatWin.animTo = calcSmallRect(w, h)
        floatWin.expanded = false
    else
        floatWin.animTo = calcLargeRect(w, h)
        floatWin.expanded = true
    end
    floatWin.animProgress = 0.0
end

function HandleSceneMouseDown(eventType, eventData)
    if not visible or not floatCtx then return end
    local button = eventData:GetInt("Button")
    if button ~= MOUSEB_LEFT then return end

    local physX = eventData:GetInt("X")
    local physY = eventData:GetInt("Y")
    local _, _, dpr = getScreenLogical()
    local mx = physX / dpr
    local my = physY / dpr
    local fw = floatWin

    if isInRect(mx, my, fw.x, fw.y, fw.w, fw.titleH) then
        local btnX = fw.x + fw.w - 52
        if mx >= btnX then
            if mx >= fw.x + fw.w - 26 then
                if fw.expanded then toggleExpand() end
            else
                toggleExpand()
            end
            return
        end
        fw.dragging = true
        fw.dragOffX = mx - fw.x
        fw.dragOffY = my - fw.y
    end
end

function HandleSceneMouseMove(eventType, eventData)
    if not floatWin.dragging then return end
    local physX = eventData:GetInt("X")
    local physY = eventData:GetInt("Y")
    local w, h, dpr = getScreenLogical()
    local mx = physX / dpr
    local my = physY / dpr
    floatWin.x = math.max(0, math.min(w - floatWin.w, mx - floatWin.dragOffX))
    floatWin.y = math.max(0, math.min(h - floatWin.h, my - floatWin.dragOffY))
end

function HandleSceneMouseUp(eventType, eventData)
    floatWin.dragging = false
end

-- ==================== 渲染回调：头像层（始终可见） ====================

function HandleAvatarRender(eventType, eventData)
    if not avatarCtx then return end

    local w, h, dpr = getScreenLogical()
    nvgBeginFrame(avatarCtx, w, h, dpr)

    -- 计算状态栏头像位置（与 UISidebar 布局对应）
    local isMobile = w < 600
    local statusBarH = isMobile and 56 or 48
    local menuBtnSize = isMobile and 53 or 43
    local avatarSize = menuBtnSize - 4
    local padLeft = 8
    local avatarX = padLeft
    local avatarY = (statusBarH - avatarSize) / 2

    -- 绘制圆形裁剪的头像
    local S = GameState.state
    local ctx = avatarCtx

    nvgSave(ctx)

    -- 圆形裁剪
    local cx = avatarX + avatarSize / 2
    local cy = avatarY + avatarSize / 2
    local radius = avatarSize / 2

    -- 外圈描边（金色边框）
    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, cy, radius + 1.5)
    nvgStrokeColor(ctx, nvgRGBA(180, 160, 120, 200))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)

    -- 裁剪为圆形后绘制头像
    nvgSave(ctx)
    nvgBeginPath(ctx)
    nvgCircle(ctx, cx, cy, radius)
    nvgPathWinding(ctx, NVG_SOLID)
    nvgClip(ctx)

    -- 使用 CharacterPortrait 绘制（它会读取 GameState 的发色/瞳色）
    CharacterPortrait.draw(ctx, avatarX, avatarY, avatarSize)

    nvgRestore(ctx) -- clip

    nvgRestore(ctx)

    nvgEndFrame(ctx)
end

-- ==================== 渲染回调：浮动窗口层 ====================

function HandleFloatWindowRender(eventType, eventData)
    if not visible or not floatCtx then return end

    local w, h, dpr = getScreenLogical()
    initFloatWindow(w, h)

    nvgBeginFrame(floatCtx, w, h, dpr)

    local fw = floatWin
    local ctx = floatCtx

    -- ===== 窗口阴影 =====
    nvgSave(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, fw.x - 2, fw.y - 2, fw.w + 4, fw.h + 4, 8)
    nvgFillColor(ctx, nvgRGBA(0, 0, 0, 40))
    nvgFill(ctx)
    nvgRestore(ctx)

    -- ===== 窗口裁剪 =====
    nvgSave(ctx)
    nvgIntersectScissor(ctx, fw.x, fw.y, fw.w, fw.h)

    -- ===== 背景 =====
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, fw.x, fw.y, fw.w, fw.h, 6)
    nvgFillColor(ctx, nvgRGBA(30, 30, 40, 230))
    nvgFill(ctx)

    -- ===== 绘制场景内容（背景+角色）=====
    local contentY = fw.y + fw.titleH
    local contentH = fw.h - fw.titleH

    nvgSave(ctx)
    nvgIntersectScissor(ctx, fw.x, contentY, fw.w, contentH)

    nvgSave(ctx)
    nvgTranslate(ctx, fw.x, contentY)

    -- 绘制色块背景
    SceneBackground.draw(ctx, fw.w, contentH, currentLocation)

    -- 绘制角色（从 GameState 读取外观，和换装系统联动）
    local S = GameState.state
    CharacterRenderer.draw(ctx, fw.w, contentH, {
        hairColor = S and S.hairColor or "淡黄色",
        eyeColor  = S and S.eyeColor or "赤色",
        hairstyle = S and S.hairstyle or "及肩长发",
        outfit    = S and S.outfit or "casual",
    })

    nvgRestore(ctx) -- translate
    nvgRestore(ctx) -- content scissor

    -- ===== 标题栏 =====
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, fw.x, fw.y, fw.w, fw.titleH, 6)
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRect(ctx, fw.x, fw.y + fw.titleH - 6, fw.w, 6)
    nvgFillColor(ctx, nvgRGBA(45, 40, 55, 240))
    nvgFill(ctx)
    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, fw.x, fw.y, fw.w, fw.titleH, 6)
    nvgFillColor(ctx, nvgRGBA(45, 40, 55, 240))
    nvgFill(ctx)

    nvgFontFace(ctx, "sans")
    nvgFontSize(ctx, 14)
    nvgFillColor(ctx, nvgRGBA(220, 215, 230, 255))
    nvgTextAlign(ctx, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
    local titleText = currentLocation or "场景"
    nvgText(ctx, fw.x + 10, fw.y + fw.titleH / 2, titleText)

    local btnSize = 14
    local btnY = fw.y + (fw.titleH - btnSize) / 2
    local expandBtnX = fw.x + fw.w - 50

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, expandBtnX, btnY, btnSize, btnSize, 2)
    nvgStrokeColor(ctx, nvgRGBA(180, 175, 195, 200))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)
    if fw.expanded then
        nvgBeginPath(ctx)
        nvgRoundedRect(ctx, expandBtnX + 3, btnY - 2, btnSize - 3, btnSize - 3, 1)
        nvgStroke(ctx)
    end

    local minBtnX = fw.x + fw.w - 28
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, minBtnX, fw.y + fw.titleH / 2)
    nvgLineTo(ctx, minBtnX + btnSize, fw.y + fw.titleH / 2)
    nvgStrokeColor(ctx, nvgRGBA(180, 175, 195, 200))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)

    -- ===== 窗口边框 =====
    nvgRestore(ctx) -- 窗口 scissor

    nvgBeginPath(ctx)
    nvgRoundedRect(ctx, fw.x, fw.y, fw.w, fw.h, 6)
    nvgStrokeColor(ctx, nvgRGBA(80, 75, 100, 180))
    nvgStrokeWidth(ctx, 1.5)
    nvgStroke(ctx)

    nvgEndFrame(ctx)
end

return SceneView
