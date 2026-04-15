-- ============================================================================
-- UIManager.lua - UI 管理器（悠闲悠哉life）
-- 基于 UrhoX UI 系统（Yoga Flexbox + NanoVG）
-- 负责：初始化UI、渲染场景文本、选项按钮、状态栏、输入框、通知
-- ============================================================================

local UI = require("urhox-libs/UI")
local Modal = require("urhox-libs/UI/Widgets/Modal")
local GameState = require("systems.GameState")
local PassageData = require("systems.PassageData")
local TimeSystem = require("systems.TimeSystem")
local ChatUI = require("systems.ChatUI")
local UIConfig = require("data.UIConfig")

local UIManager = {}

-- 分组折叠状态（key=group名称, value=是否展开）
local _expandedGroups = {}

-- ==================== 从 UIConfig 导入 ====================
local isMobile = UIConfig.isMobile
local LAYOUT = UIConfig.LAYOUT
local COLORS = UIConfig.COLORS
local SCENE_BACKGROUNDS = UIConfig.SCENE_BACKGROUNDS

-- ==================== 内部状态 ====================
local root = nil               -- UI 根节点
local safeRoot = nil            -- SafeAreaView 包裹层
local statusBar = nil           -- 顶部状态栏
local contentScroll = nil       -- 中间内容滚动区
local contentPanel = nil        -- 滚动区内的内容面板
local choicesPanel = nil        -- 底部选项面板
local inputPanel = nil          -- 输入面板（命名时显示）
local sidebarPanel = nil        -- 侧边栏面板
local sidebarOverlay = nil      -- 移动端侧边栏遮罩层
local sidebarVisible = false    -- 侧边栏是否可见
local mainArea = nil            -- 主内容区（含content+choices）
local notificationLabel = nil   -- 通知文本
local notificationTimer = 0     -- 通知倒计时
local _notifModal = nil         -- 手机端通知弹窗引用
local _choiceModal = nil        -- 手机端选择弹窗引用
local _storyModal = nil         -- 事件内容弹窗引用
local _affectionModal = nil     -- 好感度互动弹窗引用

local currentPassage = ""       -- 当前场景名
local currentLocationName = nil -- 当前地点名（显示在状态栏标题）
local inputValue = ""           -- 输入框当前值
local inputTarget = ""          -- 输入目标变量名

-- 分页状态
local pageData = nil            -- { pages={}, currentPage=1, passage=nil }

-- ==================== 场景背景图 ====================
local bgImagePanel = nil        -- 背景图面板
local currentBgImage = nil      -- 当前背景图路径
local _sceneView = nil          -- SceneView 模块引用（骨骼角色+色块背景）

-- ==================== 初始化 ====================

--- 初始化 UI 系统
function UIManager.init()
    UI.Init({
        fonts = {
            { family = "sans", weights = {
                normal = "Fonts/MiSans-Regular.ttf",
            } },
        },
        scale = UI.Scale.DEFAULT,
    })

    UIManager.buildUI()

    -- 初始化聊天模块（依赖 safeRoot，必须在 buildUI 之后）
    ChatUI.init({
        layout = LAYOUT,
        colors = COLORS,
        isMobile = isMobile,
        safeRoot = safeRoot,
        showNotification = function(msg) UIManager.showNotification(msg) end,
        getLocationName = function() return currentLocationName end,
    })
end

--- 构建完整 UI 树
function UIManager.buildUI()
    -- 通知标签（固定在顶部）
    notificationLabel = UI.Label {
        id = "notification",
        text = "",
        fontSize = LAYOUT.fontSmall,
        fontColor = { 255, 255, 255, 255 },
        textAlign = "center",
        verticalAlign = "middle",
        width = "100%",
        height = 36,
        backgroundColor = COLORS.notifyBg,
        borderRadius = { 0, 0, 8, 8 },
        visible = false,
        paddingVertical = 0, paddingHorizontal = 8,
    }

    -- 状态栏（带菜单按钮）
    statusBar = UIManager._buildStatusBar()

    -- 内容面板（放在 ScrollView 内）
    contentPanel = UI.Panel {
        id = "contentPanel",
        width = "100%",
        padding = LAYOUT.padContent,
        gap = 4,
    }

    -- 滚动区域
    contentScroll = UI.ScrollView {
        id = "contentScroll",
        width = "100%",
        flexGrow = 1,
        flexBasis = 0,
        scrollY = true,
        showScrollbar = true,
        bounces = true,
        children = { contentPanel },
    }

    -- 输入面板（默认隐藏）
    inputPanel = UIManager._buildInputPanel()

    -- 选项面板
    choicesPanel = UI.Panel {
        id = "choicesPanel",
        width = "100%",
        paddingVertical = LAYOUT.padChoicesV,
        paddingHorizontal = LAYOUT.padChoicesH,
        gap = LAYOUT.choiceGap,
        backgroundColor = COLORS.statusBg,
        borderTopWidth = 1,
        borderTopColor = COLORS.divider,
    }

    -- 侧边栏
    sidebarPanel = UIManager._buildSidebar()

    -- 场景背景图层（绝对定位，铺满 mainArea，zIndex 最低）
    bgImagePanel = UI.Panel {
        id = "bgImagePanel",
        position = "absolute",
        left = 0, top = 0,
        width = "100%",
        height = "100%",
        backgroundFit = "cover",
        visible = false,
        zIndex = -2,
    }

    -- 背景图上的半透明遮罩层（让文字可读）
    local bgOverlay = UI.Panel {
        id = "bgOverlay",
        position = "absolute",
        left = 0, top = 0,
        width = "100%",
        height = "100%",
        backgroundColor = { 0, 0, 0, 0 },  -- 初始全透明，有背景图时会变为半透明
        zIndex = -1,
    }

    -- 主内容区（右侧）
    mainArea = UI.Panel {
        id = "mainArea",
        flexGrow = 1,
        flexShrink = 1,
        flexDirection = "column",
        children = {
            bgImagePanel,   -- 绝对定位背景，zIndex=-2
            bgOverlay,      -- 绝对定位遮罩，zIndex=-1
            contentScroll,
            inputPanel,
            choicesPanel,
        },
    }

    -- 移动端：侧边栏遮罩层（点击遮罩关闭侧边栏）
    if isMobile then
        sidebarOverlay = UI.Panel {
            id = "sidebarOverlay",
            position = "absolute",
            left = 0, top = 0,
            width = "100%",
            height = "100%",
            backgroundColor = { 0, 0, 0, 120 },
            visible = false,
            onTap = function(event, widget)
                UIManager.toggleSidebar()
            end,
        }
    end

    -- 中间区域
    local bodyChildren
    if isMobile then
        -- 移动端：主内容区独立，侧边栏作为覆盖层
        bodyChildren = { mainArea }
    else
        -- 桌面端：侧边栏和主内容区并排
        bodyChildren = { sidebarPanel, mainArea }
    end

    local bodyArea = UI.Panel {
        id = "bodyArea",
        width = "100%",
        flexGrow = 1,
        flexBasis = 0,
        flexDirection = "row",
        children = bodyChildren,
    }

    -- 根布局
    local rootChildren = { notificationLabel, statusBar, bodyArea }

    root = UI.Panel {
        width = "100%",
        height = "100%",
        flexDirection = "column",
        backgroundColor = COLORS.bg,
        children = rootChildren,
    }

    -- 使用 SafeAreaView 包裹，适配刘海屏/圆角屏
    safeRoot = UI.SafeAreaView {
        width = "100%",
        height = "100%",
        edges = "all",
        mode = "padding",
        backgroundColor = COLORS.bg,
        children = { root },
    }

    UI.SetRoot(safeRoot)

    -- 移动端：将侧边栏遮罩和面板添加为覆盖层（绝对定位）
    if isMobile then
        safeRoot:AddChild(sidebarOverlay)
        safeRoot:AddChild(sidebarPanel)
    end
end

-- ==================== 侧边栏 & 状态栏（已提取到 ui/UISidebar.lua）====================
-- ==================== 输入面板 ====================

--- 构建输入面板
function UIManager._buildInputPanel()
    return UI.Panel {
        id = "inputPanel",
        width = "100%",
        flexDirection = "row",
        alignItems = "center",
        paddingVertical = 8, paddingHorizontal = 16,
        gap = 8,
        backgroundColor = COLORS.bgPanel,
        borderTopWidth = 1,
        borderTopColor = COLORS.divider,
        visible = false,
        children = {
            UI.TextField {
                id = "nameInput",
                value = "",
                placeholder = "请输入名字...",
                flexGrow = 1,
                height = isMobile and 50 or 40,
                fontSize = LAYOUT.fontBody,
                onChange = function(self, value)
                    inputValue = value
                end,
                onSubmit = function(self, value)
                    inputValue = value
                end,
            },
        },
    }
end

--- 显示/隐藏输入面板
function UIManager._showInput(show, placeholder)
    if inputPanel then
        inputPanel:SetVisible(show)
        if show then
            local tf = inputPanel:FindById("nameInput")
            if tf then
                tf:SetPlaceholder(placeholder or "请输入...")
                tf:SetValue("")
                inputValue = ""
            end
        end
    end
end

-- ==================== 场景渲染 ====================

-- 侧边栏功能页面集合（进入时自动记录来源页面）
local SIDEBAR_PAGES = {
    ["属性"] = true, ["自我审视"] = true, ["社会关系"] = true,
    ["战斗面板"] = true, ["技能"] = true, ["日志"] = true, ["背包"] = true,
    ["存档"] = true, ["读档"] = true, ["设置"] = true,
    ["区域地图"] = true, ["世界地图"] = true,
}

--- 导航到指定场景
---@param passageName string
function UIManager.navigate(passageName)
    -- 进入侧边栏功能页时，自动记录来源（排除功能页之间的互跳）
    local S = GameState.state
    if SIDEBAR_PAGES[passageName] and not SIDEBAR_PAGES[S.currentPassage] then
        S._settingsFrom = S.currentPassage
    end

    currentPassage = passageName
    currentLocationName = nil   -- 重置，renderPassage 中若检测到地点名会重新设置
    _expandedGroups = {}        -- 重置分组折叠状态
    S.currentPassage = passageName

    local passage = PassageData.getPassage(passageName)
    if not passage then
        log:Write(LOG_WARNING, "UIManager: passage not found: " .. passageName)
        passage = {
            text = "场景未找到：" .. passageName,
            choices = { { text = "返回主页面", target = "主页面" } },
        }
    end

    -- 执行段落级别的 action（如序章设置 inPrologue 等）
    if passage.action then
        passage.action()
    end

    -- 更新场景背景图
    UIManager._updateBackground(passageName)

    -- 更新角色动画/表情（SceneView 集成）
    UIManager._syncSceneAnimation(passage)

    UIManager.renderPassage(passage)
    UIManager.updateStatusBar()
end

--- 根据对话内容自动切换角色动画和表情
---@param passage table
function UIManager._syncSceneAnimation(passage)
    if not _sceneView then return end
    if not _sceneView.setAnimation then return end

    local text = passage.text or ""
    local hasChoices = passage.choices and #passage.choices > 0

    -- 检测属性变化文本（事件结果）
    local lastLine = text:match("[^\n]*$") or ""
    local hasStatChange = lastLine:match("（.+[%+%-]%d+.+）%s*$")

    if hasStatChange then
        -- 事件结果：根据正负属性变化设置表情
        local hasPositive = lastLine:match("[%+]%d+")
        local hasNegative = lastLine:match("[%-]%d+")
        if hasPositive and not hasNegative then
            _sceneView.setExpression("happy")
        elseif hasNegative and not hasPositive then
            _sceneView.setExpression("sad")
        else
            _sceneView.setExpression("surprised")
        end
        _sceneView.setAnimation("idle")
    elseif text ~= "" and not hasChoices then
        -- 有文本且无选项 = 正在叙述/对话
        _sceneView.setAnimation("talk")
        _sceneView.setExpression("neutral")
    elseif hasChoices then
        -- 等待玩家选择
        _sceneView.setAnimation("idle")
        _sceneView.setExpression("neutral")
    else
        _sceneView.setAnimation("idle")
    end
end

--- 渲染场景内容
---@param passage table {text, choices, inputField?, inputTarget?}
function UIManager.renderPassage(passage)
    -- 清空内容
    if contentPanel then
        contentPanel:ClearChildren()
    end
    if choicesPanel then
        choicesPanel:ClearChildren()
    end

    -- 好感度互动弹窗（passage.modal = true）
    if passage.modal then
        UIManager._showAffectionModal(passage)
        return
    end

    -- 尝试分页
    local text = passage.text or ""
    local pages = UIManager._paginateText(text)

    if pages then
        -- 长文本：启用分页模式
        pageData = {
            pages = pages,
            currentPage = 1,
            passage = passage,
        }
        UIManager._renderPage(1)
        return
    end

    -- 短文本：不分页，直接渲染全部
    pageData = nil
    local paragraphs = UIManager._splitText(text)

    -- 提取首行地点名 → 显示在状态栏标题位置
    local startIdx = 1
    if #paragraphs > 0 and UIManager._isLocationName(paragraphs[1]) then
        currentLocationName = paragraphs[1]
        UIManager._syncStatusTitle()
        startIdx = 2
    end

    -- 判断是否有实际内容段落（除去地点名以外）
    local hasContent = (startIdx <= #paragraphs)
    local hasChoices = passage.choices and #passage.choices > 0

    -- 判断是否为"特殊事件"结果段落：文本末尾含属性变化（如"（灵感+3，勇敢+1）"）
    local isEventResult = false
    if hasContent then
        local lastPara = paragraphs[#paragraphs] or ""
        -- 匹配全角括号包裹的属性变化：（xxx+数字...）
        if lastPara:match("（.+[%+%-]%d+.+）%s*$") then
            isEventResult = true
        end
    end

    -- 特殊事件结果 → 弹窗显示；普通剧情 → 内嵌显示
    if hasContent and isEventResult then
        UIManager._showStoryModal(paragraphs, startIdx, passage)
    else
        for i = startIdx, #paragraphs do
            UIManager._renderParagraph(paragraphs[i])
        end

        -- 处理输入框
        if passage.inputField then
            inputTarget = passage.inputTarget or ""
            UIManager._showInput(true, "请输入名字...")
        else
            inputTarget = ""
            UIManager._showInput(false)
        end

        -- 处理选项
        UIManager._renderChoices(passage.choices or {})
    end

    -- 滚动到顶部
    if contentScroll then
        contentScroll:ScrollToTop()
    end
end

-- ==================== 选项系统（已提取到 ui/UIChoices.lua）====================

-- ==================== 通知系统 ====================

--- 显示通知
---@param msg string
---@param duration number|nil
function UIManager.showNotification(msg, duration)
    -- 统一弹窗显示，避免 PC 端顶部单行截断长文本
    if _notifModal then _notifModal:Close() end
    _notifModal = Modal.Alert({
        title = "提示",
        message = msg,
        buttonText = "确定",
        onClose = function()
            _notifModal = nil
        end,
    })
end

--- 更新通知（每帧调用）
---@param dt number
function UIManager.updateNotifications(dt)
    -- 检查 GameState 中的通知队列
    -- 等上一条弹窗关闭后再弹下一条
    local S = GameState.state
    if S.notifications and #S.notifications > 0 then
        if _notifModal then return end
        local notif = table.remove(S.notifications, 1)
        UIManager.showNotification(notif.text, notif.time or 3.0)
    end
end

-- ==================== 文本渲染 & 分页（已提取到 ui/UITextRenderer.lua）====================

--- 更新场景背景图
---@param passageName string 当前场景名
function UIManager._updateBackground(passageName)
    if not bgImagePanel then return end

    -- 通知 SceneView 切换场景（骨骼角色+色块背景）
    if _sceneView then
        _sceneView.setLocation(passageName)
    end

    local bgPath = SCENE_BACKGROUNDS[passageName]
    local sceneViewActive = _sceneView and _sceneView.isVisible and _sceneView.isVisible()

    if bgPath and bgPath ~= currentBgImage then
        -- 切换到新背景图
        bgImagePanel:SetStyle({ backgroundImage = bgPath })
        bgImagePanel:SetVisible(not sceneViewActive)  -- SceneView 可见时隐藏静态背景
        currentBgImage = bgPath
        -- 设置遮罩让文字可读（SceneView 可见时增加透明度让角色可见）
        local overlay = mainArea:FindById("bgOverlay")
        if overlay then
            local overlayAlpha = sceneViewActive and 100 or 140
            overlay:SetStyle({ backgroundColor = { 0, 0, 0, overlayAlpha } })
        end
    elseif not bgPath then
        -- 没有背景图的场景，隐藏
        bgImagePanel:SetVisible(false)
        currentBgImage = nil
        local overlay = mainArea:FindById("bgOverlay")
        if overlay then
            overlay:SetStyle({ backgroundColor = { 0, 0, 0, 0 } })
        end
    else
        -- bgPath == currentBgImage，仅更新可见性
        if sceneViewActive then
            bgImagePanel:SetVisible(false)
            local overlay = mainArea:FindById("bgOverlay")
            if overlay then
                overlay:SetStyle({ backgroundColor = { 0, 0, 0, 100 } })
            end
        end
    end
end

function UIManager._syncStatusTitle()
    if not statusBar then return end
    local titleLabel = statusBar:FindById("statusTitle")
    if titleLabel then
        titleLabel:SetText(currentLocationName or "悠闲悠哉life")
    end
end

-- ==================== 场景视图（骨骼角色+色块背景） ====================

--- 注入 SceneView 模块（由 client_main.lua 调用）
function UIManager.setSceneView(sv)
    _sceneView = sv
end

-- ==================== AI 聊天委托（转发至 ChatUI 模块） ====================

function UIManager.setChatClient(client) ChatUI.setChatClient(client) end
function UIManager.isChatOpen()          return ChatUI.isChatOpen() end
function UIManager.canChat()             return ChatUI.canChat() end
function UIManager.openChat(charName)    ChatUI.openChat(charName) end
function UIManager.closeChat()           ChatUI.closeChat() end

-- ==================== 更新 ====================

--- 每帧更新（由 main.lua 调用）
---@param dt number
function UIManager.update(dt)
    UIManager.updateNotifications(dt)
end

--- 清理 UI
function UIManager.shutdown()
    -- 清理聊天模块
    ChatUI.shutdown()
    UI.Shutdown()
    root = nil
    safeRoot = nil
    statusBar = nil
    contentScroll = nil
    contentPanel = nil
    choicesPanel = nil
    inputPanel = nil
    sidebarPanel = nil
    sidebarOverlay = nil
    mainArea = nil
    notificationLabel = nil
    sidebarVisible = false
    -- 清理弹窗引用
    _storyModal = nil
    _affectionModal = nil
    _choiceModal = nil
    _notifModal = nil
end

-- ==================== 共享上下文 & 子模块安装 ====================
-- ctx 表用 __index/__newindex 代理局部变量，供子模块读写
local ctx = setmetatable({}, {
    __index = function(_, k)
        if k == "statusBar" then return statusBar
        elseif k == "sidebarPanel" then return sidebarPanel
        elseif k == "sidebarOverlay" then return sidebarOverlay
        elseif k == "sidebarVisible" then return sidebarVisible
        elseif k == "_storyModal" then return _storyModal
        elseif k == "_affectionModal" then return _affectionModal
        elseif k == "_choiceModal" then return _choiceModal
        elseif k == "currentLocationName" then return currentLocationName
        elseif k == "inputTarget" then return inputTarget
        elseif k == "inputValue" then return inputValue
        elseif k == "choicesPanel" then return choicesPanel
        elseif k == "contentPanel" then return contentPanel
        elseif k == "contentScroll" then return contentScroll
        elseif k == "expandedGroups" then return _expandedGroups
        elseif k == "pageData" then return pageData
        end
    end,
    __newindex = function(_, k, v)
        if k == "statusBar" then statusBar = v
        elseif k == "sidebarPanel" then sidebarPanel = v
        elseif k == "sidebarOverlay" then sidebarOverlay = v
        elseif k == "sidebarVisible" then sidebarVisible = v
        elseif k == "_storyModal" then _storyModal = v
        elseif k == "_affectionModal" then _affectionModal = v
        elseif k == "_choiceModal" then _choiceModal = v
        elseif k == "currentLocationName" then currentLocationName = v
        elseif k == "inputTarget" then inputTarget = v
        elseif k == "inputValue" then inputValue = v
        elseif k == "pageData" then pageData = v
        end
    end,
})

-- 安装侧边栏子模块
require("ui.UISidebar")(UIManager, ctx, UIConfig)
-- 安装弹窗子模块
require("ui.UIModals")(UIManager, ctx, UIConfig)
-- 安装选项系统子模块
require("ui.UIChoices")(UIManager, ctx, UIConfig)
-- 安装文本渲染 & 分页子模块
require("ui.UITextRenderer")(UIManager, ctx, UIConfig)

return UIManager
