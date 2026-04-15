-- ============================================================================
-- SceneBackground.lua - 地点色块简化背景
-- 使用 NanoVG 为每个游戏地点绘制简化的色块风格背景
-- ============================================================================

local SceneBackground = {}

-- NanoVG context 引用
local ctx_ = nil

-- ==================== 初始化 ====================

function SceneBackground.init(nvgCtx)
    ctx_ = nvgCtx
end

-- ==================== 工具函数 ====================

--- 绘制填充矩形
local function fillRect(ctx, x, y, w, h, color, alpha)
    nvgBeginPath(ctx)
    nvgRect(ctx, x, y, w, h)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], alpha or 255))
    nvgFill(ctx)
end

--- 绘制渐变矩形（纵向）
local function gradientRect(ctx, x, y, w, h, topColor, bottomColor)
    local grad = nvgLinearGradient(ctx, x, y, x, y + h,
        nvgRGBA(topColor[1], topColor[2], topColor[3], 255),
        nvgRGBA(bottomColor[1], bottomColor[2], bottomColor[3], 255))
    nvgBeginPath(ctx)
    nvgRect(ctx, x, y, w, h)
    nvgFillPaint(ctx, grad)
    nvgFill(ctx)
end

--- 绘制简化建筑色块
local function drawBuilding(ctx, x, y, w, h, color, windowColor, windowRows)
    -- 建筑主体
    nvgBeginPath(ctx)
    nvgRect(ctx, x, y, w, h)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], 255))
    nvgFill(ctx)

    -- 窗户
    if windowColor and windowRows then
        local ww, wh = w * 0.15, h / (windowRows + 1) * 0.4
        local gap = h / (windowRows + 1)
        for row = 1, windowRows do
            local wy = y + gap * row - wh / 2
            nvgBeginPath(ctx)
            nvgRect(ctx, x + w * 0.2, wy, ww, wh)
            nvgRect(ctx, x + w * 0.55, wy, ww, wh)
            nvgFillColor(ctx, nvgRGBA(windowColor[1], windowColor[2], windowColor[3], 255))
            nvgFill(ctx)
        end
    end
end

--- 绘制简化树木
local function drawTree(ctx, x, y, trunkH, crownR, trunkColor, crownColor)
    -- 树干
    nvgBeginPath(ctx)
    nvgRect(ctx, x - 3, y, 6, trunkH)
    nvgFillColor(ctx, nvgRGBA(trunkColor[1], trunkColor[2], trunkColor[3], 255))
    nvgFill(ctx)
    -- 树冠
    nvgBeginPath(ctx)
    nvgCircle(ctx, x, y - crownR * 0.3, crownR)
    nvgFillColor(ctx, nvgRGBA(crownColor[1], crownColor[2], crownColor[3], 255))
    nvgFill(ctx)
end

--- 绘制山丘轮廓
local function drawHill(ctx, x, y, w, h, color)
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, x, y)
    nvgBezierTo(ctx, x + w * 0.3, y - h, x + w * 0.7, y - h, x + w, y)
    nvgLineTo(ctx, x + w, y + 10)
    nvgLineTo(ctx, x, y + 10)
    nvgClosePath(ctx)
    nvgFillColor(ctx, nvgRGBA(color[1], color[2], color[3], 255))
    nvgFill(ctx)
end

-- ==================== 各地点场景绘制 ====================

local SCENES = {}

-- 十字路口：开阔的街道交叉口
SCENES["十字路口"] = function(ctx, w, h)
    -- 天空
    gradientRect(ctx, 0, 0, w, h * 0.55, { 140, 180, 220 }, { 200, 215, 230 })
    -- 远山
    drawHill(ctx, 0, h * 0.5, w * 0.6, h * 0.08, { 160, 170, 180 })
    drawHill(ctx, w * 0.4, h * 0.52, w * 0.7, h * 0.06, { 170, 178, 185 })
    -- 地面
    fillRect(ctx, 0, h * 0.55, w, h * 0.45, { 180, 165, 130 })
    -- 交叉道路（横 + 竖）
    fillRect(ctx, 0, h * 0.68, w, h * 0.1, { 155, 145, 115 })
    fillRect(ctx, w * 0.42, h * 0.55, w * 0.16, h * 0.45, { 155, 145, 115 })
    -- 建筑剪影
    drawBuilding(ctx, w * 0.05, h * 0.32, w * 0.12, h * 0.23, { 165, 150, 130 }, { 200, 190, 150 }, 3)
    drawBuilding(ctx, w * 0.2, h * 0.38, w * 0.1, h * 0.17, { 175, 155, 135 }, { 210, 200, 160 }, 2)
    drawBuilding(ctx, w * 0.75, h * 0.35, w * 0.1, h * 0.2, { 160, 145, 125 }, { 195, 185, 145 }, 3)
end

-- 家：温馨室内
SCENES["家"] = function(ctx, w, h)
    -- 墙壁（暖色）
    fillRect(ctx, 0, 0, w, h, { 200, 185, 165 })
    -- 地板
    fillRect(ctx, 0, h * 0.7, w, h * 0.3, { 160, 120, 80 })
    -- 地板线
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, 0, h * 0.7)
    nvgLineTo(ctx, w, h * 0.7)
    nvgStrokeColor(ctx, nvgRGBA(140, 100, 65, 255))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)
    -- 窗户（右侧）
    fillRect(ctx, w * 0.65, h * 0.15, w * 0.2, h * 0.3, { 170, 200, 220 })
    fillRect(ctx, w * 0.65, h * 0.15, w * 0.2, h * 0.3, { 220, 230, 240 })
    -- 窗框
    nvgBeginPath(ctx)
    nvgRect(ctx, w * 0.65, h * 0.15, w * 0.2, h * 0.3)
    nvgStrokeColor(ctx, nvgRGBA(140, 110, 75, 255))
    nvgStrokeWidth(ctx, 3)
    nvgStroke(ctx)
    -- 窗户十字
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, w * 0.75, h * 0.15)
    nvgLineTo(ctx, w * 0.75, h * 0.45)
    nvgMoveTo(ctx, w * 0.65, h * 0.3)
    nvgLineTo(ctx, w * 0.85, h * 0.3)
    nvgStroke(ctx)
    -- 暖光氛围（中心渐变）
    local glow = nvgRadialGradient(ctx, w * 0.4, h * 0.4, h * 0.1, h * 0.6,
        nvgRGBA(240, 220, 180, 40), nvgRGBA(240, 220, 180, 0))
    nvgBeginPath(ctx)
    nvgRect(ctx, 0, 0, w, h)
    nvgFillPaint(ctx, glow)
    nvgFill(ctx)
end

-- 渡劫森林：幽暗森林
SCENES["渡劫森林"] = function(ctx, w, h)
    -- 天空（暗绿）
    gradientRect(ctx, 0, 0, w, h * 0.5, { 40, 60, 50 }, { 60, 80, 60 })
    -- 地面
    fillRect(ctx, 0, h * 0.5, w, h * 0.5, { 45, 55, 35 })
    -- 落叶层
    fillRect(ctx, 0, h * 0.8, w, h * 0.2, { 60, 50, 30 })
    -- 树木（密集）
    local trunk = { 55, 40, 25 }
    local crown = { 35, 65, 40 }
    local crownLight = { 50, 80, 50 }
    drawTree(ctx, w * 0.08, h * 0.5, h * 0.2, h * 0.18, trunk, crown)
    drawTree(ctx, w * 0.22, h * 0.45, h * 0.25, h * 0.22, trunk, crownLight)
    drawTree(ctx, w * 0.38, h * 0.48, h * 0.22, h * 0.2, trunk, crown)
    drawTree(ctx, w * 0.55, h * 0.46, h * 0.24, h * 0.21, trunk, crownLight)
    drawTree(ctx, w * 0.72, h * 0.5, h * 0.2, h * 0.19, trunk, crown)
    drawTree(ctx, w * 0.88, h * 0.47, h * 0.23, h * 0.2, trunk, crownLight)
    -- 雾气
    local fog = nvgLinearGradient(ctx, 0, h * 0.4, 0, h * 0.7,
        nvgRGBA(80, 100, 80, 0), nvgRGBA(80, 100, 80, 60))
    nvgBeginPath(ctx)
    nvgRect(ctx, 0, h * 0.4, w, h * 0.3)
    nvgFillPaint(ctx, fog)
    nvgFill(ctx)
end

-- 商业区：繁华商铺街
SCENES["商业区"] = function(ctx, w, h)
    -- 天空
    gradientRect(ctx, 0, 0, w, h * 0.45, { 150, 185, 220 }, { 200, 210, 225 })
    -- 地面（石板路）
    fillRect(ctx, 0, h * 0.55, w, h * 0.45, { 160, 155, 145 })
    -- 商铺建筑
    drawBuilding(ctx, w * 0.02, h * 0.2, w * 0.18, h * 0.35, { 180, 160, 140 }, { 220, 210, 170 }, 3)
    drawBuilding(ctx, w * 0.22, h * 0.25, w * 0.15, h * 0.3, { 170, 150, 130 }, { 210, 200, 160 }, 2)
    drawBuilding(ctx, w * 0.4, h * 0.18, w * 0.16, h * 0.37, { 185, 165, 145 }, { 225, 215, 175 }, 4)
    -- 招牌色块
    fillRect(ctx, w * 0.05, h * 0.48, w * 0.12, h * 0.05, { 180, 70, 60 })
    fillRect(ctx, w * 0.42, h * 0.48, w * 0.12, h * 0.05, { 70, 120, 170 })
end

-- 花园小镇：明亮田园
SCENES["花园小镇"] = function(ctx, w, h)
    -- 明亮天空
    gradientRect(ctx, 0, 0, w, h * 0.5, { 160, 200, 240 }, { 210, 225, 240 })
    -- 草地
    fillRect(ctx, 0, h * 0.5, w, h * 0.5, { 120, 170, 90 })
    -- 小路
    fillRect(ctx, w * 0.35, h * 0.5, w * 0.15, h * 0.5, { 190, 175, 140 })
    -- 小房子
    drawBuilding(ctx, w * 0.1, h * 0.3, w * 0.12, h * 0.2, { 210, 190, 160 }, { 180, 210, 230 }, 2)
    -- 屋顶（三角形）
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, w * 0.08, h * 0.3)
    nvgLineTo(ctx, w * 0.16, h * 0.2)
    nvgLineTo(ctx, w * 0.24, h * 0.3)
    nvgClosePath(ctx)
    nvgFillColor(ctx, nvgRGBA(160, 80, 60, 255))
    nvgFill(ctx)
    -- 花朵点缀
    local flowerColors = { { 220, 100, 120 }, { 240, 200, 80 }, { 180, 120, 200 }, { 255, 180, 100 } }
    for i = 1, 8 do
        local fx = w * (0.05 + (i - 1) * 0.12)
        local fy = h * (0.6 + math.sin(i * 1.7) * 0.1)
        local fc = flowerColors[(i - 1) % #flowerColors + 1]
        nvgBeginPath(ctx)
        nvgCircle(ctx, fx, fy, 4)
        nvgFillColor(ctx, nvgRGBA(fc[1], fc[2], fc[3], 255))
        nvgFill(ctx)
    end
    -- 树
    drawTree(ctx, w * 0.82, h * 0.5, h * 0.15, h * 0.12, { 100, 75, 50 }, { 90, 150, 70 })
end

-- 贫民窟：灰暗破旧
SCENES["贫民窟"] = function(ctx, w, h)
    -- 灰暗天空
    gradientRect(ctx, 0, 0, w, h * 0.5, { 100, 100, 105 }, { 130, 128, 125 })
    -- 泥地
    fillRect(ctx, 0, h * 0.5, w, h * 0.5, { 110, 95, 75 })
    -- 破旧建筑
    drawBuilding(ctx, w * 0.05, h * 0.28, w * 0.15, h * 0.22, { 120, 110, 100 }, { 90, 85, 75 }, 2)
    drawBuilding(ctx, w * 0.25, h * 0.32, w * 0.12, h * 0.18, { 115, 105, 95 }, nil, 0)
    drawBuilding(ctx, w * 0.42, h * 0.3, w * 0.14, h * 0.2, { 125, 115, 105 }, { 85, 80, 70 }, 2)
    -- 裂缝线条
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, w * 0.3, h * 0.35)
    nvgLineTo(ctx, w * 0.32, h * 0.42)
    nvgLineTo(ctx, w * 0.29, h * 0.48)
    nvgStrokeColor(ctx, nvgRGBA(80, 70, 60, 150))
    nvgStrokeWidth(ctx, 1)
    nvgStroke(ctx)
end

-- 港口：海边码头
SCENES["港口"] = function(ctx, w, h)
    -- 天空
    gradientRect(ctx, 0, 0, w, h * 0.4, { 150, 190, 230 }, { 190, 210, 230 })
    -- 海面
    gradientRect(ctx, 0, h * 0.4, w, h * 0.25, { 80, 140, 190 }, { 60, 120, 170 })
    -- 码头（木色）
    fillRect(ctx, 0, h * 0.65, w, h * 0.35, { 140, 110, 75 })
    -- 码头栏杆
    for i = 0, 6 do
        local px = w * 0.1 + i * w * 0.12
        nvgBeginPath(ctx)
        nvgRect(ctx, px, h * 0.58, 4, h * 0.1)
        nvgFillColor(ctx, nvgRGBA(120, 90, 60, 255))
        nvgFill(ctx)
    end
    -- 横杆
    fillRect(ctx, w * 0.08, h * 0.6, w * 0.8, 3, { 120, 90, 60 })
    -- 船只剪影
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, w * 0.6, h * 0.42)
    nvgLineTo(ctx, w * 0.72, h * 0.52)
    nvgLineTo(ctx, w * 0.56, h * 0.52)
    nvgClosePath(ctx)
    nvgFillColor(ctx, nvgRGBA(100, 80, 60, 200))
    nvgFill(ctx)
    -- 桅杆
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, w * 0.64, h * 0.3)
    nvgLineTo(ctx, w * 0.64, h * 0.52)
    nvgStrokeColor(ctx, nvgRGBA(90, 70, 50, 200))
    nvgStrokeWidth(ctx, 2)
    nvgStroke(ctx)
end

-- 主城区：宏伟城墙
SCENES["主城区"] = function(ctx, w, h)
    -- 天空
    gradientRect(ctx, 0, 0, w, h * 0.45, { 145, 180, 215 }, { 195, 210, 225 })
    -- 地面（石板）
    fillRect(ctx, 0, h * 0.55, w, h * 0.45, { 150, 145, 135 })
    -- 城墙
    fillRect(ctx, 0, h * 0.2, w * 0.25, h * 0.35, { 160, 150, 135 })
    -- 城门
    nvgBeginPath(ctx)
    nvgMoveTo(ctx, w * 0.08, h * 0.55)
    nvgLineTo(ctx, w * 0.08, h * 0.35)
    nvgBezierTo(ctx, w * 0.08, h * 0.28, w * 0.18, h * 0.28, w * 0.18, h * 0.35)
    nvgLineTo(ctx, w * 0.18, h * 0.55)
    nvgClosePath(ctx)
    nvgFillColor(ctx, nvgRGBA(80, 65, 50, 255))
    nvgFill(ctx)
    -- 高建筑
    drawBuilding(ctx, w * 0.55, h * 0.15, w * 0.14, h * 0.4, { 170, 158, 140 }, { 210, 200, 165 }, 4)
    drawBuilding(ctx, w * 0.75, h * 0.22, w * 0.12, h * 0.33, { 165, 152, 135 }, { 205, 195, 160 }, 3)
end

-- 花街：灯笼暖光
SCENES["花街"] = function(ctx, w, h)
    -- 暖色夜空
    gradientRect(ctx, 0, 0, w, h * 0.45, { 50, 35, 60 }, { 80, 50, 70 })
    -- 地面
    fillRect(ctx, 0, h * 0.55, w, h * 0.45, { 140, 120, 100 })
    -- 建筑
    drawBuilding(ctx, w * 0.05, h * 0.25, w * 0.18, h * 0.3, { 150, 130, 110 }, { 220, 180, 100 }, 3)
    drawBuilding(ctx, w * 0.3, h * 0.2, w * 0.15, h * 0.35, { 145, 125, 105 }, { 215, 175, 95 }, 3)
    -- 灯笼
    local lanternColors = { { 220, 60, 50 }, { 230, 180, 60 }, { 220, 80, 60 } }
    for i = 1, 5 do
        local lx = w * (0.1 + (i - 1) * 0.18)
        local ly = h * 0.38
        local lc = lanternColors[(i - 1) % #lanternColors + 1]
        -- 灯笼体
        nvgBeginPath(ctx)
        nvgEllipse(ctx, lx, ly, 8, 12)
        nvgFillColor(ctx, nvgRGBA(lc[1], lc[2], lc[3], 220))
        nvgFill(ctx)
        -- 灯光晕
        local glow = nvgRadialGradient(ctx, lx, ly, 5, 30,
            nvgRGBA(lc[1], lc[2], lc[3], 50), nvgRGBA(lc[1], lc[2], lc[3], 0))
        nvgBeginPath(ctx)
        nvgCircle(ctx, lx, ly, 30)
        nvgFillPaint(ctx, glow)
        nvgFill(ctx)
    end
end

-- 白鸦书屋：室内书架
SCENES["白鸦书屋"] = function(ctx, w, h)
    -- 室内墙壁（暗木色）
    fillRect(ctx, 0, 0, w, h, { 170, 145, 115 })
    -- 地板
    fillRect(ctx, 0, h * 0.75, w, h * 0.25, { 130, 95, 60 })
    -- 书架（左侧大书架）
    fillRect(ctx, w * 0.03, h * 0.1, w * 0.25, h * 0.6, { 110, 75, 45 })
    -- 书本色块（几排）
    local bookColors = {
        { 150, 50, 50 }, { 50, 80, 130 }, { 60, 120, 60 }, { 180, 140, 50 },
        { 100, 60, 120 }, { 50, 100, 100 }, { 170, 100, 60 }, { 80, 80, 130 },
    }
    for row = 0, 3 do
        local ry = h * 0.14 + row * h * 0.14
        for col = 0, 5 do
            local bx = w * 0.05 + col * w * 0.035
            local bc = bookColors[(row * 6 + col) % #bookColors + 1]
            local bw = w * 0.028
            local bh = h * 0.1
            nvgBeginPath(ctx)
            nvgRect(ctx, bx, ry, bw, bh)
            nvgFillColor(ctx, nvgRGBA(bc[1], bc[2], bc[3], 255))
            nvgFill(ctx)
        end
    end
    -- 暖光
    local glow = nvgRadialGradient(ctx, w * 0.5, h * 0.35, h * 0.05, h * 0.4,
        nvgRGBA(240, 210, 160, 35), nvgRGBA(240, 210, 160, 0))
    nvgBeginPath(ctx)
    nvgRect(ctx, 0, 0, w, h)
    nvgFillPaint(ctx, glow)
    nvgFill(ctx)
end

-- 大学校门：石造门楼
SCENES["大学校门"] = function(ctx, w, h)
    -- 天空
    gradientRect(ctx, 0, 0, w, h * 0.5, { 155, 190, 225 }, { 205, 218, 232 })
    -- 草地
    fillRect(ctx, 0, h * 0.55, w, h * 0.45, { 110, 160, 80 })
    -- 石板路
    fillRect(ctx, w * 0.3, h * 0.55, w * 0.25, h * 0.45, { 170, 165, 155 })
    -- 门楼（两个石柱 + 横梁）
    fillRect(ctx, w * 0.25, h * 0.15, w * 0.08, h * 0.4, { 160, 155, 145 })
    fillRect(ctx, w * 0.52, h * 0.15, w * 0.08, h * 0.4, { 160, 155, 145 })
    fillRect(ctx, w * 0.23, h * 0.12, w * 0.4, h * 0.06, { 150, 145, 135 })
    -- 石阶
    for i = 0, 2 do
        local sx = w * 0.28 - i * w * 0.02
        local sy = h * 0.55 + i * h * 0.04
        local sw = w * 0.3 + i * w * 0.04
        fillRect(ctx, sx, sy, sw, h * 0.035, { 165, 160, 150 })
    end
    -- 树
    drawTree(ctx, w * 0.1, h * 0.55, h * 0.18, h * 0.14, { 95, 70, 45 }, { 80, 140, 65 })
    drawTree(ctx, w * 0.85, h * 0.55, h * 0.16, h * 0.12, { 95, 70, 45 }, { 85, 145, 70 })
end

-- 子场景继承
SCENES["花园小镇_小巷"] = SCENES["花园小镇"]
SCENES["贫民窟_黑帮据点"] = SCENES["贫民窟"]

-- ==================== 公共 API ====================

--- 检查某个地点是否有色块背景
---@param locationName string
---@return boolean
function SceneBackground.hasScene(locationName)
    return SCENES[locationName] ~= nil
end

--- 绘制指定地点的色块背景
---@param ctx userdata NanoVG context
---@param w number 逻辑宽度
---@param h number 逻辑高度
---@param locationName string 地点名
function SceneBackground.draw(ctx, w, h, locationName)
    local drawFn = SCENES[locationName]
    if drawFn then
        drawFn(ctx, w, h)
    else
        -- 默认背景（简单渐变）
        gradientRect(ctx, 0, 0, w, h, { 80, 90, 110 }, { 50, 55, 65 })
    end
end

return SceneBackground
