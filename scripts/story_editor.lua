-- ============================================================================
-- story_editor.lua — 剧情编辑器主入口（响应式布局）
--
-- 三种布局模式（基于逻辑像素宽度自动切换）：
--   手机 (< 550px)  : 顶部 Tab 全屏切换 [段落列表 | 段落编辑 | 属性面板]
--   平板 (550-900px) : 左列表 240px + 右侧 Tab [编辑 | 属性]
--   PC   (>= 900px)  : 三栏并排 [列表 220px | 编辑 flex | 属性 280px]
--
-- 屏幕尺寸变化时自动检测并重建布局。
-- ============================================================================

local UI = require("urhox-libs/UI")
local EditorData = require("editor.EditorData")
local PassageList = require("editor.PassageList")
local PassageEditor = require("editor.PassageEditor")
local PropertyPanel = require("editor.PropertyPanel")
local PreviewPlayer = require("editor.PreviewPlayer")

-- ============================================================================
-- 布局常量与状态
-- ============================================================================

local LAYOUT_PHONE  = "phone"
local LAYOUT_TABLET = "tablet"
local LAYOUT_PC     = "pc"

local BP_TABLET = 550   -- 平板断点
local BP_PC     = 900   -- PC 断点

local uiRoot_ = nil
local currentLayout_ = nil

-- 各布局模式下记住的活跃 Tab
local activePhoneTab_  = "list"
local activeTabletTab_ = "editor"

-- 面板实例引用
local listPanel_   = nil
local editorPanel_ = nil
local propsPanel_  = nil

-- ============================================================================
-- 生命周期
-- ============================================================================

function Start()
    graphics.windowTitle = "剧情编辑器"

    EditorData.Init()
    InitUI()

    -- 尝试加载已有数据
    if fileSystem:FileExists("quest_data.json") then
        EditorData.Load("quest_data.json")
    end

    -- 首次构建响应式布局
    BuildResponsiveLayout()

    SubscribeToEvents()
    print("=== 剧情编辑器已启动 ===")
end

function Stop()
    UI.Shutdown()
end

function InitUI()
    UI.Init({
        fonts = {
            { family = "sans", weights = {
                normal = "Fonts/MiSans-Regular.ttf",
            } }
        },
        scale = UI.Scale.DEFAULT,
    })
end

-- ============================================================================
-- 响应式检测
-- ============================================================================

function DetectLayout()
    local physW = graphics:GetWidth()
    local dpr = graphics:GetDPR()
    local logicalW = physW / dpr

    if logicalW >= BP_PC then
        return LAYOUT_PC
    elseif logicalW >= BP_TABLET then
        return LAYOUT_TABLET
    else
        return LAYOUT_PHONE
    end
end

-- ============================================================================
-- 面板回调（所有布局共享）
-- ============================================================================

local function onPassageSelect(passageId)
    PassageEditor.LoadPassage(passageId)
    PropertyPanel.Refresh()
    PassageList.Refresh()

    -- 选中段落后，自动跳转到编辑面板
    if currentLayout_ == LAYOUT_PHONE then
        activePhoneTab_ = "editor"
        SwitchPhoneTab("editor")
        local tabs = uiRoot_ and uiRoot_:FindById("phoneTabs")
        if tabs then tabs:SetActiveTab("editor") end
    elseif currentLayout_ == LAYOUT_TABLET then
        activeTabletTab_ = "editor"
        SwitchTabletTab("editor")
        local tabs = uiRoot_ and uiRoot_:FindById("tabletTabs")
        if tabs then tabs:SetActiveTab("editor") end
    end
    -- PC 模式无需切换，三栏全可见
end

local function onChoiceSelect(passageId, choiceIdx)
    PropertyPanel.Refresh()
end

local function onPropertyRefresh()
    local pid = EditorData.GetSelectedPassageId()
    if pid then
        PassageEditor.LoadPassage(pid)
    end
end

-- ============================================================================
-- 响应式布局构建入口
-- ============================================================================

function BuildResponsiveLayout()
    local mode = DetectLayout()

    -- 模式没变且 UI 已存在，不重建
    if mode == currentLayout_ and uiRoot_ then return end
    currentLayout_ = mode

    -- 每次重建布局时重新创建面板实例
    -- （数据在 EditorData 中持久，面板只是视图层）
    listPanel_   = PassageList.Create(onPassageSelect)
    editorPanel_ = PassageEditor.Create(onChoiceSelect)
    propsPanel_  = PropertyPanel.Create(onPropertyRefresh)

    -- 按模式构建不同布局
    if mode == LAYOUT_PC then
        BuildPCLayout()
    elseif mode == LAYOUT_TABLET then
        BuildTabletLayout()
    else
        BuildPhoneLayout()
    end

    -- 刷新面板数据
    PassageList.Refresh()
    local pid = EditorData.GetSelectedPassageId()
    if pid then
        PassageEditor.LoadPassage(pid)
        PropertyPanel.Refresh()
    end

    SetStatus(mode == LAYOUT_PC and "PC 三栏模式" or
              mode == LAYOUT_TABLET and "平板双栏模式" or "手机模式")
end

-- ============================================================================
-- PC 布局：三栏并排
-- ┌──220px──┬───flex───┬──280px──┐
-- │ 段落列表 │ 段落编辑  │ 属性面板 │
-- │         │          │         │
-- ├─────────┴──────────┴─────────┤
-- │           工具栏              │
-- └──────────────────────────────┘
-- ============================================================================

function BuildPCLayout()
    uiRoot_ = UI.Panel {
        id = "editorRoot",
        width = "100%",
        height = "100%",
        flexDirection = "column",
        backgroundColor = { 20, 22, 28, 255 },
        children = {
            -- 三栏主体
            UI.Panel {
                id = "mainArea",
                flexDirection = "row",
                flexGrow = 1,
                flexBasis = 0,
                children = {
                    -- 左栏：段落列表
                    UI.Panel {
                        width = 220,
                        height = "100%",
                        borderRightWidth = 1,
                        borderRightColor = { 50, 54, 70, 255 },
                        children = { listPanel_ },
                    },
                    -- 中栏：段落编辑
                    UI.Panel {
                        flexGrow = 1,
                        flexShrink = 1,
                        height = "100%",
                        children = { editorPanel_ },
                    },
                    -- 右栏：属性面板
                    UI.Panel {
                        width = 280,
                        height = "100%",
                        borderLeftWidth = 1,
                        borderLeftColor = { 50, 54, 70, 255 },
                        children = { propsPanel_ },
                    },
                },
            },
            -- 底部工具栏
            CreateToolbar(),
        },
    }

    UI.SetRoot(uiRoot_)
end

-- ============================================================================
-- 平板布局：左列表 + 右侧编辑/属性 Tab
-- ┌──240px──┬────────flex────────┐
-- │ 段落列表 │ [段落编辑] [属性]   │
-- │         │                    │
-- │         │  编辑器 或 属性面板  │
-- │         │                    │
-- ├─────────┴────────────────────┤
-- │          工具栏               │
-- └──────────────────────────────┘
-- ============================================================================

function BuildTabletLayout()
    uiRoot_ = UI.Panel {
        id = "editorRoot",
        width = "100%",
        height = "100%",
        flexDirection = "column",
        backgroundColor = { 20, 22, 28, 255 },
        children = {
            -- 双栏主体
            UI.Panel {
                id = "mainArea",
                flexDirection = "row",
                flexGrow = 1,
                flexBasis = 0,
                children = {
                    -- 左侧：段落列表（固定宽度）
                    UI.Panel {
                        width = 240,
                        height = "100%",
                        borderRightWidth = 1,
                        borderRightColor = { 50, 54, 70, 255 },
                        children = { listPanel_ },
                    },
                    -- 右侧：Tab 切换编辑/属性
                    UI.Panel {
                        flexGrow = 1,
                        flexShrink = 1,
                        height = "100%",
                        flexDirection = "column",
                        children = {
                            UI.Tabs {
                                id = "tabletTabs",
                                tabs = {
                                    { id = "editor", label = "段落编辑" },
                                    { id = "props", label = "属性面板" },
                                },
                                activeTab = activeTabletTab_,
                                variant = "line",
                                onChange = function(self, tabId)
                                    activeTabletTab_ = tabId
                                    SwitchTabletTab(tabId)
                                end,
                            },
                            UI.Panel {
                                id = "tabletContent",
                                flexGrow = 1,
                                flexBasis = 0,
                                overflow = "hidden",
                                children = { editorPanel_, propsPanel_ },
                            },
                        },
                    },
                },
            },
            -- 底部工具栏
            CreateToolbar(),
        },
    }

    UI.SetRoot(uiRoot_)
    SwitchTabletTab(activeTabletTab_)
end

function SwitchTabletTab(tabId)
    if editorPanel_ then editorPanel_:SetVisible(tabId == "editor") end
    if propsPanel_  then propsPanel_:SetVisible(tabId == "props") end
end

-- ============================================================================
-- 手机布局：顶部 Tab 全屏切换
-- ┌─[段落列表]─[段落编辑]─[属性]──┐
-- │                               │
-- │    当前面板（全屏占满）         │
-- │                               │
-- ├───────────────────────────────┤
-- │           工具栏               │
-- └───────────────────────────────┘
-- ============================================================================

function BuildPhoneLayout()
    uiRoot_ = UI.Panel {
        id = "editorRoot",
        width = "100%",
        height = "100%",
        flexDirection = "column",
        backgroundColor = { 20, 22, 28, 255 },
        children = {
            -- 顶部 Tab 切换
            UI.Tabs {
                id = "phoneTabs",
                tabs = {
                    { id = "list", label = "段落列表" },
                    { id = "editor", label = "段落编辑" },
                    { id = "props", label = "属性面板" },
                },
                activeTab = activePhoneTab_,
                variant = "pill",
                onChange = function(self, tabId)
                    activePhoneTab_ = tabId
                    SwitchPhoneTab(tabId)
                end,
            },
            -- 内容区（三面板叠放，visible 切换）
            UI.Panel {
                id = "phoneContent",
                flexGrow = 1,
                flexBasis = 0,
                overflow = "hidden",
                children = { listPanel_, editorPanel_, propsPanel_ },
            },
            -- 底部工具栏
            CreateToolbar(),
        },
    }

    UI.SetRoot(uiRoot_)
    SwitchPhoneTab(activePhoneTab_)
end

function SwitchPhoneTab(tabId)
    if listPanel_   then listPanel_:SetVisible(tabId == "list") end
    if editorPanel_ then editorPanel_:SetVisible(tabId == "editor") end
    if propsPanel_  then propsPanel_:SetVisible(tabId == "props") end
end

-- ============================================================================
-- 底部工具栏（flexWrap 自适应宽度）
-- ============================================================================

function CreateToolbar()
    return UI.Panel {
        id = "toolbar",
        flexDirection = "row",
        flexWrap = "wrap",
        alignItems = "center",
        paddingHorizontal = 8,
        paddingVertical = 6,
        gap = 6,
        backgroundColor = { 30, 32, 40, 255 },
        borderTopWidth = 1,
        borderTopColor = { 60, 64, 80, 255 },
        children = {
            -- 保存
            UI.Button {
                text = "保存",
                fontSize = 12,
                height = 32,
                paddingHorizontal = 14,
                backgroundColor = { 59, 130, 246, 220 },
                textColor = { 255, 255, 255, 255 },
                borderRadius = 6,
                onClick = function()
                    if EditorData.Save("quest_data.json") then
                        SetStatus("已保存")
                    else
                        SetStatus("保存失败!")
                    end
                end,
            },
            -- 加载
            UI.Button {
                text = "加载",
                fontSize = 12,
                height = 32,
                paddingHorizontal = 14,
                backgroundColor = { 80, 80, 100, 220 },
                textColor = { 200, 210, 230, 255 },
                borderRadius = 6,
                onClick = function()
                    if EditorData.Load("quest_data.json") then
                        SetStatus("已加载")
                        RefreshAll()
                    else
                        SetStatus("加载失败")
                    end
                end,
            },
            -- 新建段落
            UI.Button {
                text = "+ 新段落",
                fontSize = 12,
                height = 32,
                paddingHorizontal = 14,
                backgroundColor = { 50, 160, 80, 220 },
                textColor = { 255, 255, 255, 255 },
                borderRadius = 6,
                onClick = function()
                    ShowNewPassageDialog()
                end,
            },
            -- 删除
            UI.Button {
                text = "删除",
                fontSize = 12,
                height = 32,
                paddingHorizontal = 14,
                backgroundColor = { 200, 60, 60, 200 },
                textColor = { 255, 255, 255, 255 },
                borderRadius = 6,
                onClick = function()
                    local pid = EditorData.GetSelectedPassageId()
                    if pid then
                        ShowDeleteConfirmDialog(pid)
                    else
                        SetStatus("请先选择段落")
                    end
                end,
            },
            -- 预览
            UI.Button {
                text = "预览",
                fontSize = 12,
                height = 32,
                paddingHorizontal = 14,
                backgroundColor = { 160, 100, 220, 220 },
                textColor = { 255, 255, 255, 255 },
                borderRadius = 6,
                onClick = function()
                    local startId = EditorData.GetSelectedPassageId()
                    PreviewPlayer.Open(startId)
                    SetStatus("预览模式")
                end,
            },
            -- 弹性占位
            UI.Panel {
                flexGrow = 1,
                height = 1,
                pointerEvents = "none",
            },
            -- 状态文字
            UI.Label {
                id = "statusLabel",
                text = "",
                fontSize = 11,
                fontColor = { 100, 110, 140, 200 },
                flexShrink = 1,
            },
        },
    }
end

-- ============================================================================
-- 对话框
-- ============================================================================

function ShowNewPassageDialog()
    local count = EditorData.GetPassageCount() + 1
    local newId = "新段落_" .. count
    local ok, err = EditorData.AddPassage(newId)
    if ok then
        EditorData.SetSelectedPassageId(newId)
        RefreshAll()
        SetStatus("已创建: " .. newId)

        -- 自动跳转到编辑面板
        if currentLayout_ == LAYOUT_PHONE then
            activePhoneTab_ = "editor"
            SwitchPhoneTab("editor")
            local tabs = uiRoot_ and uiRoot_:FindById("phoneTabs")
            if tabs then tabs:SetActiveTab("editor") end
        elseif currentLayout_ == LAYOUT_TABLET then
            activeTabletTab_ = "editor"
            SwitchTabletTab("editor")
            local tabs = uiRoot_ and uiRoot_:FindById("tabletTabs")
            if tabs then tabs:SetActiveTab("editor") end
        end
    else
        SetStatus("创建失败: " .. (err or ""))
    end
end

function ShowDeleteConfirmDialog(passageId)
    UI.Modal.Confirm({
        title = "删除确认",
        message = "确定删除段落「" .. passageId .. "」吗？\n此操作不可撤销。",
        confirmText = "删除",
        cancelText = "取消",
        onConfirm = function()
            EditorData.RemovePassage(passageId)
            RefreshAll()
            SetStatus("已删除: " .. passageId)
        end,
    })
end

-- ============================================================================
-- 刷新所有面板
-- ============================================================================

function RefreshAll()
    PassageList.Refresh()
    local pid = EditorData.GetSelectedPassageId()
    PassageEditor.LoadPassage(pid)
    PropertyPanel.Refresh()
end

-- ============================================================================
-- 状态栏
-- ============================================================================

function SetStatus(text)
    if not uiRoot_ then return end
    local label = uiRoot_:FindById("statusLabel")
    if label then
        label:SetText(text)
    end
    print("[Status] " .. text)
end

-- ============================================================================
-- 事件
-- ============================================================================

function SubscribeToEvents()
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent("ScreenMode", "HandleScreenMode")
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()

    -- Ctrl+S 保存
    if key == KEY_S and input:GetQualifierDown(QUAL_CTRL) then
        if EditorData.Save("quest_data.json") then
            SetStatus("已保存 (Ctrl+S)")
        end
    end

    -- Escape 取消选择
    if key == KEY_ESCAPE then
        EditorData.SetSelectedPassageId(nil)
        RefreshAll()
    end
end

---@param eventType string
---@param eventData ScreenModeEventData
function HandleScreenMode(eventType, eventData)
    -- 屏幕尺寸变化时，检测是否需要切换布局模式
    local newMode = DetectLayout()
    if newMode ~= currentLayout_ then
        print("[Layout] 模式切换: " .. (currentLayout_ or "nil") .. " -> " .. newMode)
        currentLayout_ = nil  -- 强制重建
        BuildResponsiveLayout()
    end
end
