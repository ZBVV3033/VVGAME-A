-- ============================================================================
-- PreviewPlayer.lua — 预览播放 Modal
-- 模拟剧情流程，显示段落文本和可选选项
-- ============================================================================

local UI = require("urhox-libs/UI")
local EditorData = require("editor.EditorData")

local PreviewPlayer = {}

local modal_ = nil
local contentContainer_ = nil
local stateVars_ = {}
local currentPassageId_ = nil
local history_ = {}

-- ============================================================================
-- 打开预览
-- ============================================================================

function PreviewPlayer.Open(startPassageId)
    -- 初始化变量状态
    stateVars_ = {}
    local vars = EditorData.GetVariables()
    for name, def in pairs(vars) do
        stateVars_[name] = def.default or 0
    end

    history_ = {}
    currentPassageId_ = startPassageId or "开始"

    -- 查找第一个段落
    if not EditorData.GetPassage(currentPassageId_) then
        local ids = EditorData.GetPassageIds()
        if #ids > 0 then
            currentPassageId_ = ids[1]
        else
            print("[Preview] 没有段落可以预览")
            return
        end
    end

    -- 创建 Modal
    if modal_ then
        modal_:Close()
    end

    modal_ = UI.Modal {
        id = "previewModal",
        title = "剧情预览",
        size = "lg",
        closeOnOverlay = true,
        closeOnEscape = true,
        showCloseButton = true,
        onClose = function(self)
            modal_ = nil
        end,
    }

    PreviewPlayer.ShowPassage(currentPassageId_)
    modal_:Open()
end

-- ============================================================================
-- 显示段落
-- ============================================================================

function PreviewPlayer.ShowPassage(passageId)
    if not modal_ then return end

    currentPassageId_ = passageId
    history_[#history_ + 1] = passageId

    modal_:ClearContent()

    local passage = EditorData.GetPassage(passageId)
    if not passage then
        modal_:AddContent(UI.Label {
            text = "段落不存在: " .. passageId,
            fontSize = 14,
            fontColor = { 200, 80, 80, 255 },
        })
        return
    end

    -- 主容器
    local mainContent = UI.Panel {
        flexDirection = "column",
        gap = 16,
        width = "100%",
        children = {},
    }

    -- 当前段落标识
    mainContent:AddChild(UI.Panel {
        flexDirection = "row",
        alignItems = "center",
        gap = 8,
        children = {
            UI.Chip {
                label = passageId,
                color = "primary",
                size = "sm",
            },
            UI.Label {
                text = "步骤 " .. #history_,
                fontSize = 11,
                fontColor = { 120, 130, 160, 200 },
            },
        },
    })

    -- 段落文本
    mainContent:AddChild(UI.Panel {
        padding = 16,
        backgroundColor = { 40, 42, 55, 255 },
        borderRadius = 8,
        borderWidth = 1,
        borderColor = { 60, 64, 80, 255 },
        children = {
            UI.Label {
                text = passage.text or "(空段落)",
                fontSize = 14,
                fontColor = { 220, 225, 240, 255 },
                whiteSpace = "normal",
                lineHeight = 1.6,
            },
        },
    })

    -- 变量状态
    local varDisplay = PreviewPlayer.BuildVarDisplay()
    if varDisplay then
        mainContent:AddChild(varDisplay)
    end

    -- 选项按钮
    local choices = passage.choices or {}
    if #choices > 0 then
        mainContent:AddChild(UI.Divider {
            spacing = 4,
            color = { 50, 54, 70, 255 },
        })
        mainContent:AddChild(UI.Label {
            text = "选择:",
            fontSize = 12,
            fontColor = { 120, 130, 160, 200 },
        })

        for ci, choice in ipairs(choices) do
            local available = PreviewPlayer.CheckConditions(choice.conditions)
            local condText = PreviewPlayer.DescribeConditions(choice.conditions)

            local btnBg = available
                and { 59, 130, 246, 200 }
                or { 80, 80, 90, 200 }
            local btnTextColor = available
                and { 255, 255, 255, 255 }
                or { 120, 120, 130, 200 }

            local target = choice.target or ""
            local choicePanel = UI.Panel {
                flexDirection = "column",
                gap = 2,
                marginBottom = 4,
                children = {
                    UI.Button {
                        text = choice.text or "...",
                        fontSize = 13,
                        height = 36,
                        backgroundColor = btnBg,
                        textColor = btnTextColor,
                        borderRadius = 6,
                        disabled = not available,
                        onClick = function()
                            if available and target ~= "" then
                                -- 应用效果
                                PreviewPlayer.ApplyEffects(choice.effects)
                                -- 跳转
                                PreviewPlayer.ShowPassage(target)
                            end
                        end,
                    },
                },
            }

            -- 条件提示
            if condText ~= "" then
                choicePanel:AddChild(UI.Label {
                    text = (available and "✓ " or "✗ ") .. condText,
                    fontSize = 10,
                    fontColor = available
                        and { 80, 200, 80, 200 }
                        or { 200, 80, 80, 200 },
                    paddingLeft = 8,
                })
            end

            -- 目标提示
            if target == "" then
                choicePanel:AddChild(UI.Label {
                    text = "(无目标段落)",
                    fontSize = 10,
                    fontColor = { 200, 160, 60, 180 },
                    paddingLeft = 8,
                })
            end

            mainContent:AddChild(choicePanel)
        end
    else
        mainContent:AddChild(UI.Panel {
            padding = 16,
            alignItems = "center",
            children = {
                UI.Label {
                    text = "— 剧情结束 —",
                    fontSize = 14,
                    fontColor = { 160, 170, 200, 200 },
                },
            },
        })
    end

    -- 底部导航
    local navPanel = UI.Panel {
        flexDirection = "row",
        gap = 8,
        marginTop = 8,
        children = {},
    }
    if #history_ > 1 then
        navPanel:AddChild(UI.Button {
            text = "返回上一步",
            fontSize = 11,
            height = 28,
            backgroundColor = { 80, 80, 100, 200 },
            textColor = { 200, 200, 210, 255 },
            borderRadius = 4,
            onClick = function()
                if #history_ > 1 then
                    table.remove(history_)
                    local prevId = history_[#history_]
                    table.remove(history_)  -- ShowPassage 会再次添加
                    PreviewPlayer.ShowPassage(prevId)
                end
            end,
        })
    end
    navPanel:AddChild(UI.Button {
        text = "重新开始",
        fontSize = 11,
        height = 28,
        backgroundColor = { 80, 80, 100, 200 },
        textColor = { 200, 200, 210, 255 },
        borderRadius = 4,
        onClick = function()
            PreviewPlayer.Open(nil)
        end,
    })
    mainContent:AddChild(navPanel)

    modal_:AddContent(mainContent)
end

-- ============================================================================
-- 变量状态显示
-- ============================================================================

function PreviewPlayer.BuildVarDisplay()
    local vars = EditorData.GetVariables()
    local varNames = EditorData.GetVariableNames()

    -- 只显示非默认值的变量
    local changedVars = {}
    for _, name in ipairs(varNames) do
        local def = vars[name]
        local current = stateVars_[name] or 0
        local default = def and def.default or 0
        if current ~= default then
            changedVars[#changedVars + 1] = {
                name = name,
                desc = def and def.desc or name,
                value = current,
            }
        end
    end

    if #changedVars == 0 then return nil end

    local chips = {}
    for _, v in ipairs(changedVars) do
        chips[#chips + 1] = UI.Chip {
            label = (v.desc or v.name) .. ": " .. v.value,
            color = "secondary",
            size = "sm",
        }
    end

    return UI.Panel {
        flexDirection = "row",
        flexWrap = "wrap",
        gap = 4,
        children = chips,
    }
end

-- ============================================================================
-- 条件检查
-- ============================================================================

function PreviewPlayer.CheckConditions(conditions)
    if not conditions or #conditions == 0 then return true end

    for _, cond in ipairs(conditions) do
        local val = stateVars_[cond.var] or 0
        local target = cond.value or 0
        local op = cond.op or ">="

        local pass = false
        if op == ">=" then pass = (val >= target)
        elseif op == "<=" then pass = (val <= target)
        elseif op == "==" then pass = (val == target)
        elseif op == ">" then pass = (val > target)
        elseif op == "<" then pass = (val < target)
        elseif op == "!=" then pass = (val ~= target)
        end

        if not pass then return false end
    end
    return true
end

function PreviewPlayer.DescribeConditions(conditions)
    if not conditions or #conditions == 0 then return "" end
    local parts = {}
    local vars = EditorData.GetVariables()
    for _, cond in ipairs(conditions) do
        local varDef = vars[cond.var]
        local varLabel = varDef and varDef.desc or cond.var
        parts[#parts + 1] = varLabel .. " " .. (cond.op or ">=") .. " " .. tostring(cond.value or 0)
    end
    return table.concat(parts, ", ")
end

-- ============================================================================
-- 效果应用
-- ============================================================================

function PreviewPlayer.ApplyEffects(effects)
    if not effects then return end
    for _, eff in ipairs(effects) do
        local current = stateVars_[eff.var] or 0
        if eff.type == "set" then
            stateVars_[eff.var] = eff.value or 0
        elseif eff.type == "add" then
            stateVars_[eff.var] = current + (eff.value or 0)
        elseif eff.type == "sub" then
            stateVars_[eff.var] = current - (eff.value or 0)
        end
    end
end

return PreviewPlayer
