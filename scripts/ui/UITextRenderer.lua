-- ============================================================================
-- UITextRenderer.lua - 文本渲染 & 分页系统（从 UIManager.lua 提取）
-- install 模式：返回一个函数，调用时将方法注入 UIManager
-- 包含：文本分割、段落渲染、地点名检测、分页逻辑
-- ============================================================================

---@param UIManager table  UIManager 模块表
---@param ctx table        共享上下文
---@param cfg table        UIConfig（LAYOUT, COLORS, isMobile）
return function(UIManager, ctx, cfg)

local UI = require("urhox-libs/UI")

local LAYOUT = cfg.LAYOUT
local COLORS = cfg.COLORS
local isMobile = cfg.isMobile

-- ==================== 文本工具函数 ====================

--- 按换行分割文本
---@param text string
---@return string[]
function UIManager._splitText(text)
    local result = {}
    for line in text:gmatch("([^\n]*)\n?") do
        if line ~= "" then
            table.insert(result, line)
        end
    end
    return result
end

--- 判断一行文本是否为地点/场景名称（短行、无标点）
---@param line string
---@return boolean
function UIManager._isLocationName(line)
    if not line then return false end
    local len = utf8.len(line)
    if not len or len > 8 then return false end
    -- 包含叙述性标点就不是地名
    if line:match("[\u{ff0c}\u{3002}\u{ff1f}\u{ff01}\u{3001}\u{ff1b}\u{300c}\u{300d}]") then return false end
    -- "数字：xxx" 格式也算（如"0：序章"）
    if line:match("^%d+[\u{ff1a}:]") then return true end
    return true
end

--- 渲染地点名称标签（顶部小标签样式）
---@param name string
function UIManager._renderLocationTag(name)
    local contentPanel = ctx.contentPanel
    if not contentPanel or not name then return end
    contentPanel:AddChild(UI.Panel {
        width = "100%",
        flexDirection = "row",
        alignItems = "center",
        marginBottom = 6,
        children = {
            UI.Label {
                text = "📍",
                fontSize = LAYOUT.fontSmall,
                marginRight = 4,
            },
            UI.Label {
                text = name,
                fontSize = LAYOUT.fontSmall,
                fontColor = COLORS.textDim,
            },
        },
    })
end

-- ==================== 段落渲染 ====================

--- 渲染单个段落（根据格式自动选择样式）
---@param para string
function UIManager._renderParagraph(para)
    local contentPanel = ctx.contentPanel
    if not contentPanel then return end

    -- 中文首行缩进（2个全角空格）
    local textIndent = "\u{3000}\u{3000}"

    if para:match("^━+$") then
        -- 分隔线
        contentPanel:AddChild(UI.Divider {
            orientation = "horizontal",
            color = COLORS.divider,
            spacing = 4,
        })
    elseif para:match("^━━━ .+ ━━━$") then
        -- 装饰标题行（━━━ XXX ━━━）
        local title = para:match("^━━━ (.+) ━━━$")
        contentPanel:AddChild(UI.Panel {
            width = "100%",
            alignItems = "center",
            paddingVertical = 6,
            marginBottom = 4,
            children = {
                UI.Label {
                    text = title,
                    fontSize = isMobile and 24 or 20,
                    fontColor = COLORS.textTitle,
                    fontWeight = "bold",
                    textAlign = "center",
                },
                UI.Divider {
                    orientation = "horizontal",
                    color = COLORS.accent,
                    spacing = 4,
                    width = 60,
                },
            },
        })
    elseif para:match("^【.+】") then
        -- 角色名/标题
        contentPanel:AddChild(UI.Label {
            text = para,
            fontSize = isMobile and 21 or 18,
            fontColor = COLORS.accent,
            fontWeight = "bold",
            whiteSpace = "normal",
            width = "100%",
            marginTop = 6,
        })
    elseif para:match("^\u{300c}") or para:match("^\u{201c}") or para:match("^\u{201d}") then
        -- 对话文本（「」或 ""）
        contentPanel:AddChild(UI.Label {
            text = textIndent .. para,
            fontSize = LAYOUT.fontBody,
            fontColor = { 200, 220, 255, 255 },
            whiteSpace = "normal",
            width = "100%",
            paddingLeft = isMobile and 12 or 8,
            borderLeftWidth = 2,
            borderLeftColor = COLORS.accent,
            marginVertical = 4,
        })
    elseif para:match("^\u{ff08}.+\u{ff09}$") then
        -- 系统提示（全角括号内）
        contentPanel:AddChild(UI.Label {
            text = para,
            fontSize = LAYOUT.fontSmall,
            fontColor = COLORS.success,
            textAlign = "center",
            width = "100%",
            marginVertical = 4,
        })
    elseif para:match("^\u{1f4ac} ") then
        -- 战斗消息（💬）
        contentPanel:AddChild(UI.Panel {
            width = "100%",
            backgroundColor = { 50, 45, 75, 200 },
            borderRadius = 6,
            paddingVertical = 6, paddingHorizontal = 10,
            marginVertical = 4,
            children = {
                UI.Label {
                    text = para,
                    fontSize = LAYOUT.fontLabel,
                    fontColor = COLORS.warning,
                    whiteSpace = "normal",
                    width = "100%",
                },
            },
        })
    else
        -- 普通叙述文本：加首行缩进
        contentPanel:AddChild(UI.Label {
            text = textIndent .. para,
            fontSize = LAYOUT.fontBody,
            fontColor = COLORS.text,
            whiteSpace = "normal",
            width = "100%",
            marginVertical = 3,
        })
    end
end

-- ==================== 分页系统 ====================

--- 将长文本按段落分页，每页约 TARGET_CHARS 字
---@param text string 全文内容
---@return string[]|nil 分好的页面列表，文本短则返回 nil
function UIManager._paginateText(text)
    local TARGET_CHARS = 350
    local MIN_TOTAL = 300  -- 低于此长度不分页

    -- 纯字符长度（去除空白）粗略判断（使用 utf8.len 正确计算中文字符数）
    local plainText = text:gsub("%s+", "")
    local plainLen = utf8.len(plainText) or #plainText
    if plainLen <= MIN_TOTAL then return nil end

    -- 按双换行分段（保留原段落结构）
    local paragraphs = {}
    for block in (text .. "\n\n"):gmatch("(.-)\n\n") do
        local trimmed = block:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            table.insert(paragraphs, trimmed)
        end
    end

    -- 段落不足2段时，改用单换行分段
    if #paragraphs < 2 then
        paragraphs = {}
        for line in text:gmatch("([^\n]+)") do
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed and trimmed ~= "" then
                table.insert(paragraphs, trimmed)
            end
        end
    end

    if #paragraphs <= 1 then return nil end

    -- 贪心合并段落到页面
    local pages = {}
    local curPage = ""
    local curLen = 0

    for _, para in ipairs(paragraphs) do
        local paraPlain = para:gsub("%s+", "")
        local paraLen = utf8.len(paraPlain) or #paraPlain
        if curLen > 0 and curLen + paraLen > TARGET_CHARS then
            -- 当前页已够长，存入并开新页
            table.insert(pages, curPage)
            curPage = para
            curLen = paraLen
        else
            if curPage == "" then
                curPage = para
            else
                curPage = curPage .. "\n\n" .. para
            end
            curLen = curLen + paraLen
        end
    end
    -- 最后一页
    if curPage ~= "" then
        table.insert(pages, curPage)
    end

    -- 只分出1页说明不需要分页
    if #pages <= 1 then return nil end

    return pages
end

--- 渲染指定页面
---@param pageIndex number 页码（1-based）
function UIManager._renderPage(pageIndex)
    local pageData = ctx.pageData
    if not pageData then return end

    local contentPanel = ctx.contentPanel
    local choicesPanel = ctx.choicesPanel
    local contentScroll = ctx.contentScroll

    local pages = pageData.pages
    local passage = pageData.passage
    pageData.currentPage = pageIndex

    -- 清空面板
    if contentPanel then contentPanel:ClearChildren() end
    if choicesPanel then choicesPanel:ClearChildren() end

    -- 渲染当前页文本
    local pageText = pages[pageIndex] or ""
    local paragraphs = UIManager._splitText(pageText)

    -- 第一页：提取首行地点名 → 显示在状态栏
    local startIdx = 1
    if pageIndex == 1 and #paragraphs > 0 and UIManager._isLocationName(paragraphs[1]) then
        ctx.currentLocationName = paragraphs[1]
        UIManager._syncStatusTitle()
        startIdx = 2
    end

    -- 顶部页码（多页时显示）
    local totalPages = #pages
    if totalPages > 1 then
        contentPanel:AddChild(UI.Panel {
            width = "100%",
            flexDirection = "row",
            justifyContent = "flex-end",
            alignItems = "center",
            marginBottom = 6,
            children = {
                UI.Label {
                    text = "（" .. pageIndex .. " / " .. totalPages .. "）",
                    fontSize = LAYOUT.fontSmall,
                    fontColor = COLORS.textDim,
                },
            },
        })
    end

    for i = startIdx, #paragraphs do
        UIManager._renderParagraph(paragraphs[i])
    end

    -- 底部按钮
    if pageIndex < totalPages then
        -- 非末页：显示"继续"按钮
        choicesPanel:AddChild(UI.Button {
            text = "▶ 继续",
            width = "100%",
            height = LAYOUT.btnHeight,
            fontSize = LAYOUT.fontLabel,
            backgroundColor = COLORS.accent,
            textColor = { 255, 255, 255, 255 },
            hoverBackgroundColor = COLORS.accentHover,
            pressedBackgroundColor = COLORS.accentPress,
            borderRadius = 8,
            onClick = function(self)
                UIManager._renderPage(pageIndex + 1)
                if contentScroll then contentScroll:ScrollToTop() end
            end,
        })
    else
        -- 末页：显示原始选项
        if passage.inputField then
            ctx.inputTarget = passage.inputTarget or ""
            UIManager._showInput(true, "请输入名字...")
        else
            ctx.inputTarget = ""
            UIManager._showInput(false)
        end
        UIManager._renderChoices(passage.choices or {})
    end

    -- 滚动到顶部
    if contentScroll then contentScroll:ScrollToTop() end
end

end -- installer
