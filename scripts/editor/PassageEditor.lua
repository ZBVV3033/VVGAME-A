-- ============================================================================
-- PassageEditor.lua — 段落编辑面板（竖屏全宽版）
-- ============================================================================

local UI = require("urhox-libs/UI")
local EditorData = require("editor.EditorData")

local PassageEditor = {}

local editorPanel_ = nil
local onChoiceSelectCallback_ = nil
local TEXT_LINE_COUNT = 6

-- ============================================================================
-- 创建面板
-- ============================================================================

function PassageEditor.Create(onChoiceSelect)
    onChoiceSelectCallback_ = onChoiceSelect

    editorPanel_ = UI.Panel {
        id = "passageEditorPanel",
        width = "100%",
        height = "100%",
        flexDirection = "column",
        backgroundColor = { 24, 26, 33, 255 },
        children = {
            -- 顶部标题栏
            UI.Panel {
                id = "editorHeader",
                height = 40,
                flexDirection = "row",
                alignItems = "center",
                paddingHorizontal = 12,
                backgroundColor = { 30, 32, 40, 255 },
                borderBottomWidth = 1,
                borderBottomColor = { 50, 54, 70, 255 },
                children = {
                    UI.Label {
                        id = "editorTitle",
                        text = "请先在「段落列表」中选择一个段落",
                        fontSize = 13,
                        fontColor = { 140, 150, 180, 255 },
                        flexShrink = 1,
                    },
                },
            },
            -- 内容区
            UI.ScrollView {
                id = "editorContent",
                flexGrow = 1,
                flexBasis = 0,
                scrollY = true,
                padding = 12,
                children = {},
            },
        },
    }

    return editorPanel_
end

-- ============================================================================
-- 加载段落到编辑区
-- ============================================================================

function PassageEditor.LoadPassage(passageId)
    if not editorPanel_ then return end

    local content = editorPanel_:FindById("editorContent")
    if not content then return end
    content:ClearChildren()

    if not passageId then
        local title = editorPanel_:FindById("editorTitle")
        if title then title:SetText("请先在「段落列表」中选择一个段落") end
        return
    end

    local passage = EditorData.GetPassage(passageId)
    if not passage then return end

    -- 更新标题
    local title = editorPanel_:FindById("editorTitle")
    if title then title:SetText("编辑: " .. passageId) end

    -- ========== 段落 ID 编辑 ==========
    content:AddChild(UI.Panel {
        flexDirection = "column",
        gap = 4,
        marginBottom = 12,
        children = {
            UI.Label {
                text = "段落 ID",
                fontSize = 12,
                fontColor = { 120, 130, 160, 255 },
                fontWeight = "bold",
            },
            UI.TextField {
                id = "passageIdField",
                value = passageId,
                fontSize = 14,
                height = 36,
                onSubmit = function(self, value)
                    if value ~= passageId and value ~= "" then
                        local ok, err = EditorData.RenamePassage(passageId, value)
                        if ok then
                            PassageEditor.LoadPassage(value)
                        else
                            print("[Editor] 重命名失败: " .. (err or ""))
                            self:SetValue(passageId)
                        end
                    end
                end,
            },
        },
    })

    -- ========== 段落文本编辑（多行模拟） ==========
    local textLines = PassageEditor.SplitLines(passage.text or "")
    local textSection = UI.Panel {
        id = "textSection",
        flexDirection = "column",
        gap = 3,
        marginBottom = 12,
        children = {
            UI.Label {
                text = "段落文本",
                fontSize = 12,
                fontColor = { 120, 130, 160, 255 },
                fontWeight = "bold",
                marginBottom = 2,
            },
        },
    }

    local lineCount = math.max(TEXT_LINE_COUNT, #textLines)
    for lineIdx = 1, lineCount do
        local lineText = textLines[lineIdx] or ""
        textSection:AddChild(UI.TextField {
            id = "textLine_" .. lineIdx,
            value = lineText,
            placeholder = (lineIdx == 1) and "输入段落文本..." or "",
            fontSize = 14,
            height = 32,
            onChange = function(self, value)
                PassageEditor.SaveTextFromFields(passageId)
            end,
        })
    end
    content:AddChild(textSection)

    -- 分隔线
    content:AddChild(UI.Divider { spacing = 6, color = { 50, 54, 70, 255 } })

    -- ========== 选项列表 ==========
    local choicesSection = UI.Panel {
        id = "choicesSection",
        flexDirection = "column",
        gap = 4,
        children = {
            UI.Panel {
                flexDirection = "row",
                alignItems = "center",
                marginBottom = 6,
                children = {
                    UI.Label {
                        text = "选项列表",
                        fontSize = 12,
                        fontColor = { 120, 130, 160, 255 },
                        fontWeight = "bold",
                        flexGrow = 1,
                    },
                    UI.Button {
                        text = "+ 添加选项",
                        fontSize = 12,
                        height = 30,
                        paddingHorizontal = 12,
                        backgroundColor = { 59, 130, 246, 200 },
                        textColor = { 255, 255, 255, 255 },
                        borderRadius = 6,
                        onClick = function(self)
                            EditorData.AddChoice(passageId)
                            PassageEditor.LoadPassage(passageId)
                        end,
                    },
                },
            },
        },
    }

    local choices = passage.choices or {}
    local selectedChoiceIdx = EditorData.GetSelectedChoiceIndex()
    local allPassageIds = EditorData.GetPassageIds()

    for ci, choice in ipairs(choices) do
        local choiceIdx = ci
        local isChoiceSelected = (ci == selectedChoiceIdx)

        local cardBg = isChoiceSelected
            and { 40, 60, 100, 200 }
            or { 36, 38, 48, 255 }
        local borderCol = isChoiceSelected
            and { 59, 130, 246, 200 }
            or { 50, 54, 70, 255 }

        -- target dropdown options
        local targetOptions = { { value = "", label = "(无目标)" } }
        for _, pid in ipairs(allPassageIds) do
            targetOptions[#targetOptions + 1] = { value = pid, label = pid }
        end

        local condCount = choice.conditions and #choice.conditions or 0
        local effCount = choice.effects and #choice.effects or 0
        local badgeText = ""
        if condCount > 0 then badgeText = badgeText .. "条件:" .. condCount .. " " end
        if effCount > 0 then badgeText = badgeText .. "效果:" .. effCount end

        local choiceCard = UI.Panel {
            flexDirection = "column",
            padding = 10,
            marginBottom = 6,
            backgroundColor = cardBg,
            borderWidth = 1,
            borderColor = borderCol,
            borderRadius = 8,
            gap = 6,
            onClick = function(self)
                EditorData.SetSelectedChoiceIndex(choiceIdx)
                if onChoiceSelectCallback_ then
                    onChoiceSelectCallback_(passageId, choiceIdx)
                end
                PassageEditor.LoadPassage(passageId)
            end,
            children = {
                -- 选项标题行
                UI.Panel {
                    flexDirection = "row",
                    alignItems = "center",
                    pointerEvents = "box-none",
                    children = {
                        UI.Label {
                            text = "选项 " .. ci,
                            fontSize = 12,
                            fontColor = { 100, 110, 140, 200 },
                            flexGrow = 1,
                        },
                        badgeText ~= "" and UI.Chip {
                            label = badgeText,
                            size = "sm",
                            color = "warning",
                        } or nil,
                        UI.Button {
                            text = "x",
                            fontSize = 11,
                            height = 24,
                            width = 24,
                            backgroundColor = { 200, 60, 60, 150 },
                            textColor = { 255, 255, 255, 255 },
                            borderRadius = 12,
                            onClick = function(self)
                                EditorData.RemoveChoice(passageId, choiceIdx)
                                PassageEditor.LoadPassage(passageId)
                            end,
                        },
                    },
                },
                -- 选项文本
                UI.TextField {
                    value = choice.text or "",
                    placeholder = "选项文本",
                    fontSize = 14,
                    height = 32,
                    onChange = function(self, value)
                        EditorData.SetChoiceText(passageId, choiceIdx, value)
                    end,
                },
                -- 目标段落
                UI.Panel {
                    flexDirection = "row",
                    alignItems = "center",
                    gap = 6,
                    pointerEvents = "box-none",
                    children = {
                        UI.Label {
                            text = "目标:",
                            fontSize = 12,
                            fontColor = { 100, 110, 140, 200 },
                            width = 40,
                        },
                        UI.Dropdown {
                            options = targetOptions,
                            value = choice.target or "",
                            placeholder = "选择目标段落",
                            fontSize = 12,
                            height = 30,
                            flexGrow = 1,
                            onChange = function(self, value)
                                EditorData.SetChoiceTarget(passageId, choiceIdx, value)
                            end,
                        },
                    },
                },
            },
        }
        choicesSection:AddChild(choiceCard)
    end

    if #choices == 0 then
        choicesSection:AddChild(UI.Label {
            text = "暂无选项，点击上方按钮添加",
            fontSize = 13,
            fontColor = { 80, 90, 110, 200 },
            textAlign = "center",
            paddingVertical = 24,
        })
    end

    content:AddChild(choicesSection)
end

-- ============================================================================
-- 辅助函数
-- ============================================================================

function PassageEditor.SplitLines(text)
    local lines = {}
    if not text or text == "" then
        return { "" }
    end
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line
    end
    if #lines == 0 then
        lines[1] = text
    end
    return lines
end

function PassageEditor.SaveTextFromFields(passageId)
    if not editorPanel_ then return end
    local lines = {}
    for i = 1, 20 do
        local field = editorPanel_:FindById("textLine_" .. i)
        if field then
            lines[#lines + 1] = field:GetValue() or ""
        else
            break
        end
    end
    -- 去除末尾空行
    while #lines > 1 and lines[#lines] == "" do
        lines[#lines] = nil
    end
    local fullText = table.concat(lines, "\n")
    EditorData.SetPassageText(passageId, fullText)
end

return PassageEditor
