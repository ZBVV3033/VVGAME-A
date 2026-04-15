-- ============================================================================
-- main.lua - 悠闲悠哉life（文字冒险RPG）
-- 入口文件，负责初始化所有系统模块并启动游戏
-- 基于 UrhoX scaffold-2d 模板
-- ============================================================================

local UI = require("urhox-libs/UI")

-- 延迟声明模块引用（在 Start() 中加载）
local GameState, TimeSystem, NPCSystem, WorkSystem, BattleSystem, PassageData, UIManager

--- 安全加载模块，失败时记录详细错误并在屏幕上显示
local function safeRequire(name)
    local ok, mod = pcall(require, name)
    if not ok then
        local err = tostring(mod)
        log:Write(LOG_ERROR, "[Main] REQUIRE FAILED: " .. name .. " -> " .. err)
        return nil, err
    end
    log:Write(LOG_INFO, "[Main] Loaded OK: " .. name)
    return mod, nil
end

-- ============================================================================
-- 生命周期
-- ============================================================================

function Start()
    log:Write(LOG_INFO, "[Main] ======== Start() BEGIN ========")
    graphics.windowTitle = "悠闲悠哉life"

    -- 逐个加载模块，记录每一步
    local loadErrors = {}

    local modules = {
        { "systems.GameState",      "GameState" },
        { "systems.TimeSystem",     "TimeSystem" },
        { "systems.NPCSystem",      "NPCSystem" },
        { "systems.WorkSystem",     "WorkSystem" },
        { "systems.BattleSystem",   "BattleSystem" },
        { "systems.PassageData",    "PassageData" },
        { "systems.UIManager",      "UIManager" },
    }

    local loaded = {}
    for _, m in ipairs(modules) do
        local mod, err = safeRequire(m[1])
        loaded[m[2]] = mod
        if err then
            table.insert(loadErrors, m[2] .. ": " .. err)
        end
    end

    GameState = loaded.GameState
    TimeSystem = loaded.TimeSystem
    NPCSystem = loaded.NPCSystem
    WorkSystem = loaded.WorkSystem
    BattleSystem = loaded.BattleSystem
    PassageData = loaded.PassageData
    UIManager = loaded.UIManager

    -- 如果有加载错误，在屏幕上显示
    if #loadErrors > 0 then
        log:Write(LOG_ERROR, "[Main] MODULE LOAD ERRORS:\n" .. table.concat(loadErrors, "\n"))
        -- 用 NanoVG 在屏幕上显示错误
        local errText = "MODULE LOAD ERRORS:\n" .. table.concat(loadErrors, "\n")
        _G._fatalError = errText
        SubscribeToEvent("NanoVGRender", "HandleFatalError")
        return
    end

    -- 检查关键模块
    if not GameState then log:Write(LOG_ERROR, "[Main] GameState is nil!") return end
    if not UIManager then log:Write(LOG_ERROR, "[Main] UIManager is nil!") return end

    -- 1. 初始化游戏状态
    local ok1, err1 = pcall(GameState.init)
    if not ok1 then
        log:Write(LOG_ERROR, "[Main] GameState.init() FAILED: " .. tostring(err1))
        _G._fatalError = "GameState.init() FAILED:\n" .. tostring(err1)
        SubscribeToEvent("NanoVGRender", "HandleFatalError")
        return
    end
    log:Write(LOG_INFO, "[Main] GameState initialized")

    -- 2. 初始化 UI
    local ok2, err2 = pcall(UIManager.init)
    if not ok2 then
        log:Write(LOG_ERROR, "[Main] UIManager.init() FAILED: " .. tostring(err2))
        _G._fatalError = "UIManager.init() FAILED:\n" .. tostring(err2)
        SubscribeToEvent("NanoVGRender", "HandleFatalError")
        return
    end
    log:Write(LOG_INFO, "[Main] UIManager initialized")

    -- 3. 订阅引擎事件
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")

    -- 4. 导航到初始场景（先命名，再进序章）
    local ok3, err3 = pcall(UIManager.navigate, "主页面")
    if not ok3 then
        log:Write(LOG_ERROR, "[Main] navigate('主页面') FAILED: " .. tostring(err3))
    end

    log:Write(LOG_INFO, "=== 悠闲悠哉life Started ===")
end

--- 致命错误屏幕显示
local _errorFontCreated = false
function HandleFatalError(eventType, eventData)
    ---@diagnostic disable-next-line: undefined-global
    local _vg = vg  -- 在渲染事件中获取，此时引擎已准备好
    if not _vg then return end
    local w = graphics:GetWidth()
    local h = graphics:GetHeight()
    local dpr = graphics:GetDPR()
    if not _errorFontCreated then
        nvgCreateFont(_vg, "errsans", "Fonts/MiSans-Regular.ttf")
        _errorFontCreated = true
    end
    nvgBeginFrame(_vg, w, h, 1.0)
    -- 红色背景
    nvgBeginPath(_vg)
    nvgRect(_vg, 0, 0, w, h)
    nvgFillColor(_vg, nvgRGBA(40, 0, 0, 255))
    nvgFill(_vg)
    -- 错误文字
    nvgFontSize(_vg, 16 * dpr)
    nvgFontFace(_vg, "errsans")
    nvgFillColor(_vg, nvgRGBA(255, 100, 100, 255))
    nvgTextAlign(_vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    local errMsg = _G._fatalError or "Unknown error"
    -- 逐行绘制
    local y = 20 * dpr
    for line in errMsg:gmatch("[^\n]+") do
        nvgText(_vg, 20 * dpr, y, line)
        y = y + 22 * dpr
    end
    nvgEndFrame(_vg)
end

function Stop()
    if UIManager and UIManager.shutdown then
        UIManager.shutdown()
    end
    log:Write(LOG_INFO, "=== 悠闲悠哉life Stopped ===")
end

-- ============================================================================
-- 事件处理
-- ============================================================================

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    if not UIManager then return end
    local dt = eventData["TimeStep"]:GetFloat()
    UIManager.update(dt)
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    if not UIManager or not GameState then return end
    local key = eventData["Key"]:GetInt()

    -- ESC 键返回主页面
    if key == KEY_ESCAPE then
        local S = GameState.state
        if S and S.currentPassage ~= "主页面" and S.currentPassage ~= "命名" then
            UIManager.navigate("主页面")
        end
    end
end
