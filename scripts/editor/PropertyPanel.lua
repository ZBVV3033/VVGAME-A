-- ============================================================================
-- PropertyPanel.lua — 属性/条件/效果面板（竖屏全宽版）
-- ============================================================================

local UI = require("urhox-libs/UI")
local EditorData = require("editor.EditorData")

local PropertyPanel = {}

local panelRoot_ = nil
local onRefreshCallback_ = nil

-- ============================================================================
-- 创建面板
-- ============================================================================

function PropertyPanel.Create(onRefresh)
    onRefreshCallback_ = onRefresh

    panelRoot_ = UI.Panel {
        id = "propertyPanel",
        width = "100%",
        height = "100%",
        flexDirection = "column",
        backgroundColor = { 24, 26, 33, 255 },
        children = {
            -- 子 Tabs
            UI.Tabs {
                id = "propertyTabs",
                tabs = {
                    { id = "choice", label = "选项属性" },
                    { id = "vars", label = "变量管理" },
                },
                activeTab = "choice",
                variant = "line",
                onChange = function(self, tabId)
                    PropertyPanel.RefreshTab(tabId)
                end,
            },
            -- 内容区域
            UI.ScrollView {
                id = "propertyContent",
                flexGrow = 1,
                flexBasis = 0,
                scrollY = true,
                padding = 12,
                children = {},
            },
        },
    }

    return panelRoot_
end

-- ============================================================================
-- 刷新标签页
-- ============================================================================

function PropertyPanel.RefreshTab(tabId)
    if not panelRoot_ then return end
    local content = panelRoot_:FindById("propertyContent")
    if not content then return end
    content:ClearChildren()

    if tabId == "choice" then
        PropertyPanel.BuildChoiceProperties(content)
    elseif tabId == "vars" then
        PropertyPanel.BuildVariableManager(content)
    end
end

function PropertyPanel.Refresh()
    if not panelRoot_ then return end
    local tabs = panelRoot_:FindById("propertyTabs")
    local activeTab = "choice"
    if tabs then
        activeTab = tabs:GetActiveTab() or "choice"
    end
    PropertyPanel.RefreshTab(activeTab)
end

-- ============================================================================
-- 选项属性面板
-- ============================================================================

function PropertyPanel.BuildChoiceProperties(container)
    local passageId = EditorData.GetSelectedPassageId()
    local choiceIdx = EditorData.GetSelectedChoiceIndex()

    if not passageId or not choiceIdx then
        container:AddChild(UI.Label {
            text = "请先在「段落编辑」中选择一个选项",
            fontSize = 13,
            fontColor = { 100, 110, 140, 200 },
            textAlign = "center",
            paddingVertical = 40,
        })
        return
    end

    local choices = EditorData.GetChoices(passageId)
    local choice = choices[choiceIdx]
    if not choice then
        container:AddChild(UI.Label {
            text = "选项不存在",
            fontSize = 13,
            fontColor = { 200, 80, 80, 200 },
        })
        return
    end

    -- 选项信息
    container:AddChild(UI.Panel {
        flexDirection = "row",
        alignItems = "center",
        gap = 8,
        marginBottom = 12,
        children = {
            UI.Chip {
                label = passageId,
                color = "primary",
                size = "sm",
            },
            UI.Label {
                text = "选项 " .. choiceIdx,
                fontSize = 12,
                fontColor = { 160, 170, 200, 255 },
            },
        },
    })

    -- ---- 条件列表 ----
    container:AddChild(UI.Panel {
        flexDirection = "row",
        alignItems = "center",
        marginBottom = 8,
        children = {
            UI.Label {
                text = "条件",
                fontSize = 13,
                fontColor = { 180, 190, 210, 255 },
                fontWeight = "bold",
                flexGrow = 1,
            },
            UI.Button {
                text = "+ 条件",
                fontSize = 11,
                height = 26,
                paddingHorizontal = 10,
                backgroundColor = { 60, 160, 60, 200 },
                textColor = { 255, 255, 255, 255 },
                borderRadius = 4,
                onClick = function()
                    EditorData.AddCondition(passageId, choiceIdx)
                    PropertyPanel.Refresh()
                end,
            },
        },
    })

    local conditions = choice.conditions or {}
    local varNames = EditorData.GetVariableNames()
    local varOptions = {}
    for _, vn in ipairs(varNames) do
        varOptions[#varOptions + 1] = { value = vn, label = vn }
    end
    local opOptions = {
        { value = ">=", label = ">=" },
        { value = "<=", label = "<=" },
        { value = "==", label = "==" },
        { value = ">", label = ">" },
        { value = "<", label = "<" },
        { value = "!=", label = "!=" },
    }

    for ci, cond in ipairs(conditions) do
        local condIdx = ci
        container:AddChild(UI.Panel {
            flexDirection = "row",
            alignItems = "center",
            gap = 4,
            marginBottom = 6,
            height = 32,
            children = {
                UI.Dropdown {
                    options = varOptions,
                    value = cond.var or "",
                    fontSize = 12,
                    height = 28,
                    flexGrow = 1,
                    onChange = function(self, value)
                        EditorData.UpdateCondition(passageId, choiceIdx, condIdx, "var", value)
                    end,
                },
                UI.Dropdown {
                    options = opOptions,
                    value = cond.op or ">=",
                    fontSize = 12,
                    height = 28,
                    width = 56,
                    onChange = function(self, value)
                        EditorData.UpdateCondition(passageId, choiceIdx, condIdx, "op", value)
                    end,
                },
                UI.TextField {
                    value = tostring(cond.value or 0),
                    fontSize = 12,
                    height = 28,
                    width = 50,
                    onChange = function(self, value)
                        local num = tonumber(value)
                        if num then
                            EditorData.UpdateCondition(passageId, choiceIdx, condIdx, "value", num)
                        end
                    end,
                },
                UI.Button {
                    text = "x",
                    fontSize = 10,
                    height = 24,
                    width = 24,
                    backgroundColor = { 180, 50, 50, 180 },
                    textColor = { 255, 255, 255, 255 },
                    borderRadius = 12,
                    onClick = function()
                        EditorData.RemoveCondition(passageId, choiceIdx, condIdx)
                        PropertyPanel.Refresh()
                    end,
                },
            },
        })
    end

    if #conditions == 0 then
        container:AddChild(UI.Label {
            text = "无条件限制",
            fontSize = 12,
            fontColor = { 80, 90, 110, 180 },
            marginBottom = 8,
        })
    end

    -- 分隔
    container:AddChild(UI.Divider {
        spacing = 10,
        color = { 50, 54, 70, 255 },
    })

    -- ---- 效果列表 ----
    container:AddChild(UI.Panel {
        flexDirection = "row",
        alignItems = "center",
        marginBottom = 8,
        children = {
            UI.Label {
                text = "效果",
                fontSize = 13,
                fontColor = { 180, 190, 210, 255 },
                fontWeight = "bold",
                flexGrow = 1,
            },
            UI.Button {
                text = "+ 效果",
                fontSize = 11,
                height = 26,
                paddingHorizontal = 10,
                backgroundColor = { 60, 160, 60, 200 },
                textColor = { 255, 255, 255, 255 },
                borderRadius = 4,
                onClick = function()
                    EditorData.AddEffect(passageId, choiceIdx)
                    PropertyPanel.Refresh()
                end,
            },
        },
    })

    local effectTypeOptions = {
        { value = "set", label = "设置" },
        { value = "add", label = "增加" },
        { value = "sub", label = "减少" },
    }

    local effects = choice.effects or {}
    for ei, eff in ipairs(effects) do
        local effIdx = ei
        container:AddChild(UI.Panel {
            flexDirection = "row",
            alignItems = "center",
            gap = 4,
            marginBottom = 6,
            height = 32,
            children = {
                UI.Dropdown {
                    options = effectTypeOptions,
                    value = eff.type or "set",
                    fontSize = 12,
                    height = 28,
                    width = 60,
                    onChange = function(self, value)
                        EditorData.UpdateEffect(passageId, choiceIdx, effIdx, "type", value)
                    end,
                },
                UI.Dropdown {
                    options = varOptions,
                    value = eff.var or "",
                    fontSize = 12,
                    height = 28,
                    flexGrow = 1,
                    onChange = function(self, value)
                        EditorData.UpdateEffect(passageId, choiceIdx, effIdx, "var", value)
                    end,
                },
                UI.TextField {
                    value = tostring(eff.value or 0),
                    fontSize = 12,
                    height = 28,
                    width = 50,
                    onChange = function(self, value)
                        local num = tonumber(value)
                        if num then
                            EditorData.UpdateEffect(passageId, choiceIdx, effIdx, "value", num)
                        end
                    end,
                },
                UI.Button {
                    text = "x",
                    fontSize = 10,
                    height = 24,
                    width = 24,
                    backgroundColor = { 180, 50, 50, 180 },
                    textColor = { 255, 255, 255, 255 },
                    borderRadius = 12,
                    onClick = function()
                        EditorData.RemoveEffect(passageId, choiceIdx, effIdx)
                        PropertyPanel.Refresh()
                    end,
                },
            },
        })
    end

    if #effects == 0 then
        container:AddChild(UI.Label {
            text = "无效果",
            fontSize = 12,
            fontColor = { 80, 90, 110, 180 },
        })
    end
end

-- ============================================================================
-- 变量管理面板
-- ============================================================================

function PropertyPanel.BuildVariableManager(container)
    -- 添加变量按钮
    container:AddChild(UI.Panel {
        flexDirection = "row",
        alignItems = "center",
        marginBottom = 12,
        children = {
            UI.Label {
                text = "游戏变量",
                fontSize = 13,
                fontColor = { 180, 190, 210, 255 },
                fontWeight = "bold",
                flexGrow = 1,
            },
            UI.Button {
                text = "+ 新变量",
                fontSize = 12,
                height = 28,
                paddingHorizontal = 12,
                backgroundColor = { 60, 160, 60, 200 },
                textColor = { 255, 255, 255, 255 },
                borderRadius = 6,
                onClick = function()
                    local varNum = #EditorData.GetVariableNames() + 1
                    local newName = "var_" .. varNum
                    EditorData.AddVariable(newName, "int", 0, "新变量")
                    PropertyPanel.Refresh()
                end,
            },
        },
    })

    local varNames = EditorData.GetVariableNames()
    local vars = EditorData.GetVariables()

    for _, name in ipairs(varNames) do
        local varDef = vars[name]
        local varName = name  -- 闭包捕获

        container:AddChild(UI.Panel {
            flexDirection = "column",
            gap = 6,
            padding = 10,
            marginBottom = 8,
            backgroundColor = { 36, 38, 48, 255 },
            borderRadius = 8,
            borderWidth = 1,
            borderColor = { 50, 54, 70, 255 },
            children = {
                -- 变量名和删除按钮
                UI.Panel {
                    flexDirection = "row",
                    alignItems = "center",
                    children = {
                        UI.Label {
                            text = name,
                            fontSize = 14,
                            fontColor = { 140, 180, 255, 255 },
                            fontWeight = "bold",
                            flexGrow = 1,
                        },
                        UI.Button {
                            text = "x",
                            fontSize = 10,
                            height = 22,
                            width = 22,
                            backgroundColor = { 180, 50, 50, 150 },
                            textColor = { 255, 255, 255, 255 },
                            borderRadius = 11,
                            onClick = function()
                                EditorData.RemoveVariable(varName)
                                PropertyPanel.Refresh()
                            end,
                        },
                    },
                },
                -- 描述
                UI.Panel {
                    flexDirection = "row",
                    alignItems = "center",
                    gap = 6,
                    children = {
                        UI.Label {
                            text = "描述:",
                            fontSize = 12,
                            fontColor = { 100, 110, 140, 200 },
                            width = 40,
                        },
                        UI.TextField {
                            value = varDef.desc or "",
                            fontSize = 12,
                            height = 28,
                            flexGrow = 1,
                            onChange = function(self, value)
                                EditorData.UpdateVariable(varName, "desc", value)
                            end,
                        },
                    },
                },
                -- 默认值
                UI.Panel {
                    flexDirection = "row",
                    alignItems = "center",
                    gap = 6,
                    children = {
                        UI.Label {
                            text = "默认:",
                            fontSize = 12,
                            fontColor = { 100, 110, 140, 200 },
                            width = 40,
                        },
                        UI.TextField {
                            value = tostring(varDef.default or 0),
                            fontSize = 12,
                            height = 28,
                            width = 80,
                            onChange = function(self, value)
                                local num = tonumber(value)
                                if num then
                                    EditorData.UpdateVariable(varName, "default", num)
                                end
                            end,
                        },
                    },
                },
            },
        })
    end

    if #varNames == 0 then
        container:AddChild(UI.Label {
            text = "暂无变量",
            fontSize = 13,
            fontColor = { 80, 90, 110, 180 },
            textAlign = "center",
            paddingVertical = 24,
        })
    end
end

return PropertyPanel
