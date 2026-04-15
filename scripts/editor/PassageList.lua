-- ============================================================================
-- PassageList.lua — 段落列表面板（竖屏全宽版）
-- ============================================================================

local UI = require("urhox-libs/UI")
local EditorData = require("editor.EditorData")

local PassageList = {}

local listContainer_ = nil
local searchText_ = ""
local onSelectCallback_ = nil

-- ============================================================================
-- 创建面板
-- ============================================================================

function PassageList.Create(onSelect)
    onSelectCallback_ = onSelect

    listContainer_ = UI.Panel {
        id = "passageListPanel",
        width = "100%",
        height = "100%",
        flexDirection = "column",
        backgroundColor = { 24, 26, 33, 255 },
        children = {
            -- 搜索框
            UI.Panel {
                paddingHorizontal = 12,
                paddingVertical = 8,
                backgroundColor = { 30, 32, 40, 255 },
                borderBottomWidth = 1,
                borderBottomColor = { 50, 54, 70, 255 },
                children = {
                    UI.TextField {
                        id = "passageSearch",
                        placeholder = "搜索段落...",
                        fontSize = 14,
                        height = 36,
                        onChange = function(self, value)
                            searchText_ = value or ""
                            PassageList.Refresh()
                        end,
                    },
                },
            },
            -- 段落计数
            UI.Panel {
                paddingHorizontal = 12,
                paddingVertical = 6,
                children = {
                    UI.Label {
                        id = "passageCount",
                        text = "共 0 个段落",
                        fontSize = 12,
                        fontColor = { 100, 110, 140, 200 },
                    },
                },
            },
            -- 段落列表
            UI.ScrollView {
                id = "passageScrollView",
                flexGrow = 1,
                flexBasis = 0,
                scrollY = true,
                paddingHorizontal = 8,
                paddingBottom = 8,
                children = {},
            },
        },
    }

    return listContainer_
end

-- ============================================================================
-- 刷新列表
-- ============================================================================

function PassageList.Refresh()
    if not listContainer_ then return end

    local scrollView = listContainer_:FindById("passageScrollView")
    if not scrollView then return end

    scrollView:ClearChildren()

    local ids = EditorData.GetPassageIds()
    local selectedId = EditorData.GetSelectedPassageId()
    local matchCount = 0

    for i, id in ipairs(ids) do
        -- 搜索过滤
        if searchText_ == "" or string.find(id, searchText_, 1, true) then
            matchCount = matchCount + 1
            local isSelected = (id == selectedId)

            local passage = EditorData.GetPassage(id)
            local choiceCount = passage and passage.choices and #passage.choices or 0
            local previewText = ""
            if passage and passage.text and passage.text ~= "" then
                previewText = string.sub(passage.text, 1, 40)
                if #passage.text > 40 then previewText = previewText .. "..." end
                -- 替换换行为空格
                previewText = string.gsub(previewText, "\n", " ")
            end

            local itemBg = isSelected
                and { 59, 130, 246, 40 }
                or { 36, 38, 48, 255 }
            local borderCol = isSelected
                and { 59, 130, 246, 200 }
                or { 50, 54, 70, 255 }
            local titleColor = isSelected
                and { 140, 180, 255, 255 }
                or { 210, 215, 230, 255 }

            local passageId = id  -- 闭包捕获
            local item = UI.Panel {
                flexDirection = "column",
                padding = 12,
                marginBottom = 4,
                backgroundColor = itemBg,
                borderWidth = 1,
                borderColor = borderCol,
                borderRadius = 8,
                cursor = "pointer",
                onClick = function(self)
                    EditorData.SetSelectedPassageId(passageId)
                    if onSelectCallback_ then
                        onSelectCallback_(passageId)
                    end
                end,
                children = {
                    -- 第一行：段落名 + 选项数
                    UI.Panel {
                        flexDirection = "row",
                        alignItems = "center",
                        pointerEvents = "none",
                        children = {
                            UI.Label {
                                text = id,
                                fontSize = 15,
                                fontColor = titleColor,
                                fontWeight = "bold",
                                flexGrow = 1,
                                flexShrink = 1,
                            },
                            UI.Chip {
                                label = choiceCount .. " 选项",
                                size = "sm",
                                color = choiceCount > 0 and "primary" or "default",
                            },
                        },
                    },
                    -- 第二行：预览文本
                    previewText ~= "" and UI.Label {
                        text = previewText,
                        fontSize = 12,
                        fontColor = { 120, 130, 160, 200 },
                        marginTop = 4,
                        pointerEvents = "none",
                    } or nil,
                },
            }
            scrollView:AddChild(item)
        end
    end

    -- 更新计数
    local countLabel = listContainer_:FindById("passageCount")
    if countLabel then
        countLabel:SetText("共 " .. matchCount .. " 个段落")
    end
end

return PassageList
