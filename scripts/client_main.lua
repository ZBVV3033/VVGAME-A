-- ============================================================================
-- client_main.lua - 多人模式客户端入口
-- 基于 main.lua，增加网络连接与 LLM 聊天功能
-- ============================================================================

---@diagnostic disable: undefined-global

local UI = require("urhox-libs/UI")

-- 网络场景（用于 RemoteEvent 通信）
---@type Scene
local networkScene_ = nil

-- 聊天客户端模块
local ChatClient = nil

-- 延迟声明模块引用（在 Start() 中加载）
local GameState, TimeSystem, NPCSystem, WorkSystem, BattleSystem, PassageData, UIManager
local SceneView

--- 安全加载模块
local function safeRequire(name)
    local ok, mod = pcall(require, name)
    if not ok then
        local err = tostring(mod)
        log:Write(LOG_ERROR, "[ClientMain] REQUIRE FAILED: " .. name .. " -> " .. err)
        return nil, err
    end
    log:Write(LOG_INFO, "[ClientMain] Loaded OK: " .. name)
    return mod, nil
end

-- ============================================================================
-- 生命周期
-- ============================================================================

function Start()
    log:Write(LOG_INFO, "[ClientMain] ======== Start() BEGIN ========")
    graphics.windowTitle = "悠闲悠哉life"

    -- 创建网络场景（用于 RemoteEvent 通信，不含实际游戏对象）
    networkScene_ = Scene()
    networkScene_:CreateComponent("Octree")
    _G._networkScene = networkScene_  -- 供 ChatClient 使用

    -- 加载游戏模块
    local loadErrors = {}
    local modules = {
        { "systems.GameState",    "GameState" },
        { "systems.TimeSystem",   "TimeSystem" },
        { "systems.NPCSystem",    "NPCSystem" },
        { "systems.WorkSystem",   "WorkSystem" },
        { "systems.BattleSystem", "BattleSystem" },
        { "systems.PassageData",  "PassageData" },
        { "systems.UIManager",    "UIManager" },
        { "systems.SceneView",    "SceneView" },
    }

    local loaded = {}
    for _, m in ipairs(modules) do
        local mod, err = safeRequire(m[1])
        loaded[m[2]] = mod
        if err then
            table.insert(loadErrors, m[2] .. ": " .. err)
        end
    end

    GameState  = loaded.GameState
    TimeSystem = loaded.TimeSystem
    NPCSystem  = loaded.NPCSystem
    WorkSystem = loaded.WorkSystem
    BattleSystem = loaded.BattleSystem
    PassageData  = loaded.PassageData
    UIManager    = loaded.UIManager
    SceneView    = loaded.SceneView

    -- 加载聊天客户端
    local chatMod, chatErr = safeRequire("network.Client")
    if chatMod then
        ChatClient = chatMod
    else
        table.insert(loadErrors, "ChatClient: " .. tostring(chatErr))
    end

    -- 如果有加载错误，显示
    if #loadErrors > 0 then
        log:Write(LOG_ERROR, "[ClientMain] MODULE LOAD ERRORS:\n" .. table.concat(loadErrors, "\n"))
        local errText = "MODULE LOAD ERRORS:\n" .. table.concat(loadErrors, "\n")
        _G._fatalError = errText
        SubscribeToEvent("NanoVGRender", "HandleFatalError")
        return
    end

    if not GameState then log:Write(LOG_ERROR, "[ClientMain] GameState is nil!") return end
    if not UIManager then log:Write(LOG_ERROR, "[ClientMain] UIManager is nil!") return end

    -- 1. 初始化游戏状态
    local ok1, err1 = pcall(GameState.init)
    if not ok1 then
        log:Write(LOG_ERROR, "[ClientMain] GameState.init() FAILED: " .. tostring(err1))
        _G._fatalError = "GameState.init() FAILED:\n" .. tostring(err1)
        SubscribeToEvent("NanoVGRender", "HandleFatalError")
        return
    end
    log:Write(LOG_INFO, "[ClientMain] GameState initialized")

    -- 2. 初始化 UI
    local ok2, err2 = pcall(UIManager.init)
    if not ok2 then
        log:Write(LOG_ERROR, "[ClientMain] UIManager.init() FAILED: " .. tostring(err2))
        _G._fatalError = "UIManager.init() FAILED:\n" .. tostring(err2)
        SubscribeToEvent("NanoVGRender", "HandleFatalError")
        return
    end
    log:Write(LOG_INFO, "[ClientMain] UIManager initialized")

    -- 2.5 初始化场景视图（骨骼角色 + 色块背景）
    if SceneView then
        local ok2b, err2b = pcall(SceneView.init)
        if not ok2b then
            log:Write(LOG_ERROR, "[ClientMain] SceneView.init() FAILED: " .. tostring(err2b))
        else
            log:Write(LOG_INFO, "[ClientMain] SceneView initialized")
            -- 注入 SceneView 到 UIManager
            if UIManager.setSceneView then
                UIManager.setSceneView(SceneView)
            end
        end
    end

    -- 3. 初始化聊天客户端 & 注入 UIManager
    if ChatClient then
        ChatClient.init()
        ChatClient.onConnected = function()
            if UIManager and UIManager.showNotification then
                UIManager.showNotification("🤖 服务器已连接，可以自由对话了！")
            end
        end
        UIManager.setChatClient(ChatClient)
        log:Write(LOG_INFO, "[ClientMain] ChatClient initialized and injected into UIManager")
    end

    -- 4. 订阅引擎事件
    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")

    -- 5. 导航到初始场景
    local ok3, err3 = pcall(UIManager.navigate, "主页面")
    if not ok3 then
        log:Write(LOG_ERROR, "[ClientMain] navigate('主页面') FAILED: " .. tostring(err3))
    end

    log:Write(LOG_INFO, "=== 悠闲悠哉life (Multiplayer Client) Started ===")
end

-- ==================== 致命错误显示 ====================

local _errorFontCreated = false
function HandleFatalError(eventType, eventData)
    local _vg = vg
    if not _vg then return end
    local w = graphics:GetWidth()
    local h = graphics:GetHeight()
    local dpr = graphics:GetDPR()
    if not _errorFontCreated then
        nvgCreateFont(_vg, "errsans", "Fonts/MiSans-Regular.ttf")
        _errorFontCreated = true
    end
    nvgBeginFrame(_vg, w, h, 1.0)
    nvgBeginPath(_vg)
    nvgRect(_vg, 0, 0, w, h)
    nvgFillColor(_vg, nvgRGBA(40, 0, 0, 255))
    nvgFill(_vg)
    nvgFontSize(_vg, 16 * dpr)
    nvgFontFace(_vg, "errsans")
    nvgFillColor(_vg, nvgRGBA(255, 100, 100, 255))
    nvgTextAlign(_vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    local errMsg = _G._fatalError or "Unknown error"
    local y = 20 * dpr
    for line in errMsg:gmatch("[^\n]+") do
        nvgText(_vg, 20 * dpr, y, line)
        y = y + 22 * dpr
    end
    nvgEndFrame(_vg)
end

function Stop()
    if SceneView and SceneView.shutdown then
        SceneView.shutdown()
    end
    if UIManager and UIManager.shutdown then
        UIManager.shutdown()
    end
    log:Write(LOG_INFO, "=== 悠闲悠哉life (Multiplayer Client) Stopped ===")
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
    if SceneView then
        SceneView.update(dt)
    end
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    if not UIManager or not GameState then return end
    local key = eventData["Key"]:GetInt()

    if key == KEY_ESCAPE then
        -- 如果聊天面板打开，先关闭聊天
        if UIManager.isChatOpen and UIManager.isChatOpen() then
            UIManager.closeChat()
            return
        end
        local S = GameState.state
        if S and S.currentPassage ~= "主页面" and S.currentPassage ~= "命名" then
            UIManager.navigate("主页面")
        end
    end
end
