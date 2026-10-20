-- 基于 scaffold-2d.lua 的 UI 树构建：不使用原生 UI，不另建渲染上下文。
local UI = require("urhox-libs/UI")
local Game = require("FogSea.Game")
local Story = require("FogSea.Story")
local View = {}
local INK = { 223, 225, 214, 255 }
local MUTED = { 151, 165, 160, 255 }
local MINT = { 94, 200, 184, 255 }
local DARK = { 13, 23, 27, 244 }
local CLEAR = { 0, 0, 0, 0 }

local function Label(text, size, color, extra)
    local props = { text = text, fontSize = size or 14, fontColor = color or INK, whiteSpace = "normal", lineHeight = 1.55, flexShrink = 1 }
    for k, v in pairs(extra or {}) do props[k] = v end
    return UI.Label(props)
end

local function Button(text, click, extra)
    local props = {
        text = text, height = 42, fontSize = 13, textColor = INK,
        backgroundColor = { 22, 36, 40, 236 }, hoverBackgroundColor = { 35, 66, 65, 255 },
        pressedBackgroundColor = { 40, 80, 75, 255 }, borderWidth = 1,
        borderColor = { 105, 132, 126, 90 }, borderRadius = 2, boxShadow = false,
        transition = "backgroundColor 0.16s easeOut", onClick = click,
    }
    for k, v in pairs(extra or {}) do props[k] = v end
    return UI.Button(props)
end

local function Image(path, w, h, extra)
    local props = { width = w, height = h, backgroundImage = path, backgroundFit = "contain", pointerEvents = "none" }
    for k, v in pairs(extra or {}) do props[k] = v end
    return UI.Panel(props)
end

local function Rule()
    return UI.Panel { height = 1, width = "100%", backgroundColor = { 116, 143, 136, 65 }, pointerEvents = "none" }
end

function View.Init()
    UI.Init({ theme = "default-dark", scale = UI.Scale.DEFAULT })
end

local function Overlay(app, children, extra)
    local props = {
        position = "absolute", left = 0, right = 0, top = 0, bottom = 0,
        backgroundColor = { 4, 12, 16, 205 }, alignItems = "center", justifyContent = "center",
        pointerEvents = "auto", children = children,
    }
    for k, v in pairs(extra or {}) do props[k] = v end
    return UI.Panel(props)
end

-- 美术烘焙版标题：ui_title 自带全部菜单字，按钮只做透明热区，不再叠程序文字。
local function TitleHit(app, w, h, ax, ay, bw, bh, action, label)
    return UI.Panel {
        position = "absolute", left = (ax - bw / 2) * w, top = (ay - bh / 2) * h, width = bw * w, height = bh * h,
        borderRadius = 8, pointerEvents = "auto",
        onClick = function() app:Request(action) end,
        onPointerEnter = function(_, widget)
            widget:SetStyle({ borderWidth = 1, borderColor = { 94, 200, 184, 200 }, backgroundColor = { 94, 200, 184, 22 } })
            app:SetHover(label)
        end,
        onPointerLeave = function(_, widget)
            widget:SetStyle({ borderWidth = 0, backgroundColor = CLEAR })
            app:SetHover("")
        end,
    }
end

local function Title(app, w, h)
    local root = UI.Panel { width = "100%", height = "100%", backgroundColor = "#101c21", children = {
        Image("image/ui_title.png", "100%", "100%", { position = "absolute", top = 0, left = 0, backgroundFit = "cover" }),
    } }
    root:AddChild(TitleHit(app, w, h, .655, .812, .17, .105, "new", "开 始 新 的 一 次 航 程"))
    root:AddChild(TitleHit(app, w, h, .342, .752, .17, .105, "continue", app.hasSave and "续写上一次" or "暂 无 存 档"))
    root:AddChild(TitleHit(app, w, h, .585, .594, .14, .09, "settings", "设 置 与 操 作"))
    root:AddChild(TitleHit(app, w, h, .415, .502, .11, .075, "quit", "退 出 游 戏"))
    root:AddChild(Label(app.hoverText, 12, MINT, { id = "hoverText", position = "absolute", bottom = h * .055, left = 0, right = 0, textAlign = "center" }))
    root:AddChild(Label("客舱邮轮全景待补  ·  单机  ·  无内购", 9, MUTED, { position = "absolute", bottom = 10, left = "6%" }))
    root:AddChild(Label("包含心理悬疑与精神困境描写", 9, MUTED, { position = "absolute", bottom = 10, right = "6%" }))
    return root
end

local function Background(app, root, w, h)
    local s = app.state
    local name, path = Game.Scene(s)
    local width = math.max(w, h * 2) * app.zoom
    local height = width / 2
    local minX = w - width
    app.pan = math.max(minX / 2, math.min(-minX / 2, app.pan))
    local left = (w - width) / 2 + app.pan
    local top = (h - height) / 2
    local stage = UI.Panel { position = "absolute", left = left, top = top, width = width, height = height, backgroundImage = path, backgroundFit = "fill", pointerEvents = "auto" }
    app.stage = stage
    local function Pan(event)
        if app.modal.kind ~= "none" or app.transitionTime > 0 then return end
        local nextPan = math.max(minX / 2, math.min(-minX / 2, app.pan + event.deltaX))
        app.pan = nextPan
        stage:SetStyle({ left = (w - width) / 2 + nextPan })
    end
    stage.props.onPanStart = function() return app.modal.kind == "none" end
    stage.props.onPanMove = function(event) Pan(event) end
    stage.props.onPanEnd = function() end
    if s.world == "cruise" and s.chapter <= 2 then
        stage:AddChild(UI.Panel { position = "absolute", top = 0, bottom = 0, left = 0, right = 0, backgroundColor = { 85, 58, 27, 65 }, pointerEvents = "none" })
    end
    for _, spot in ipairs(Game.Spots(s)) do
        local x, y = spot.x * width, spot.y * height
        local sw, sh = math.max(40, spot.w * width), math.max(40, spot.h * height)
        local zone = UI.Panel {
            position = "absolute", left = x, top = y, width = sw, height = sh,
            borderWidth = spot.anchor and 1 or 0, borderRadius = 3,
            borderColor = spot.anchor and { 94, 200, 184, 140 } or CLEAR,
            backgroundColor = CLEAR, pointerEvents = "auto",
            onClick = function() app:Request("spot", spot.id) end,
            onPointerEnter = function(_, widget)
                widget:SetStyle({ borderWidth = 1, borderColor = MINT, backgroundColor = { 94, 200, 184, 22 } })
                app:SetHover(spot.name)
            end,
            onPointerLeave = function(_, widget)
                widget:SetStyle({ borderWidth = spot.anchor and 1 or 0, borderColor = { 94, 200, 184, 140 }, backgroundColor = CLEAR })
                app:SetHover("")
            end,
        }
        if spot.item ~= "" then
            zone:AddChild(Image(spot.item, "100%", "100%", { opacity = .9 }))
        end
        if spot.anchor then
            local dot = UI.Panel { position = "absolute", left = "50%", top = -6, width = 8, height = 8, borderRadius = 4, backgroundColor = MINT, pointerEvents = "none" }
            dot:Animate({ keyframes = { [0] = { opacity = .35, scale = .7 }, [1] = { opacity = 1, scale = 1.25 } }, duration = 1.6, loop = true, direction = "alternate" })
            zone:AddChild(dot)
        end
        if app.hints then
            zone:AddChild(Label(spot.name, 10, INK, { position = "absolute", top = "100%", left = 0, backgroundColor = { 6, 16, 20, 200 }, padding = 3 }))
        end
        stage:AddChild(zone)
    end
    root:AddChild(stage)
    root:AddChild(UI.Panel { position = "absolute", left = 0, right = 0, bottom = 0, height = "28%", backgroundGradient = { direction = "to-bottom", from = CLEAR, to = { 7, 16, 21, 235 } }, pointerEvents = "none" })
    root:AddChild(UI.Panel { position = "absolute", left = 0, right = 0, top = 0, height = 180, backgroundGradient = { direction = "to-bottom", from = { 7, 16, 21, 245 }, to = CLEAR }, pointerEvents = "none" })
    if s.lucidity < 60 then
        root:AddChild(UI.Panel { position = "absolute", left = 0, right = 0, top = 0, bottom = 0, borderWidth = 9, borderColor = { 94, 130, 126, 60 }, pointerEvents = "none" })
    end
    return name
end

local function HUD(app, root, w)
    local s = app.state
    local name = Game.Scene(s)
    local top = UI.SafeAreaView { position = "absolute", top = 0, left = 0, right = 0, nativeMenuInset = true, paddingHorizontal = 24, paddingTop = 16, pointerEvents = "box-none" }
    top:AddChild(UI.Panel { flexDirection = "row", alignItems = "center", justifyContent = "space-between", pointerEvents = "box-none", children = {
        UI.Panel { pointerEvents = "none", children = {
            Label("雾海号   /   THE LAST VOYAGE", 11, MUTED, { letterSpacing = 2 }),
            Label(name .. "  /  " .. (s.world == "cruise" and "梦的表面" or "世界背面"), 23, INK),
        } },
        UI.Panel { flexDirection = "row", gap = 8, alignItems = "center", children = {
            Label(w < 1000 and "" or (s.persona > 0 and Game.personas[s.persona] or "尚未成形的自己"), 11, MUTED),
            Button("航程", function() app:Request("travel") end, { width = 58 }),
            Button("线索 " .. Game.Count(s) .. "/15", function() app:Request("journal") end, { width = 100 }),
            Button("暂停", function() app:Request("settings") end, { width = 58 }),
        } },
    } })
    top:AddChild(UI.Panel { height = 10 })
    top:AddChild(Rule())
    top:AddChild(UI.Panel { height = 8 })
    top:AddChild(Label(Game.Objective(s), 12, MINT))
    local reused = s.world == "cruise" and s.chapter == 1
    if reused then top:AddChild(Label("客舱邮轮全景待补 · 暂用病房底图", 9, MUTED)) end
    root:AddChild(top)
    local bottom = UI.SafeAreaView { position = "absolute", left = 0, bottom = 12, right = 0, paddingHorizontal = 24, pointerEvents = "box-none" }
    bottom:AddChild(UI.Panel { flexDirection = "row", alignItems = "flex-end", justifyContent = "space-between", pointerEvents = "box-none", children = {
        UI.Panel { width = math.min(240, w * .22), gap = 5, pointerEvents = "none", children = {
            Label("自 我 的 潮 汐", 9, MUTED, { letterSpacing = 2 }),
            Label("锚  " .. s.axes[1] .. "     浪  " .. s.axes[2] .. "     雾  " .. s.axes[3], 12, INK),
            UI.Panel { flexDirection = "row", gap = 4, children = {
                UI.ProgressBar { width = 60, height = 3, value = math.min(s.axes[1] / 15, 1), fillColor = MINT, backgroundColor = "#34443e", showLabel = false },
                UI.ProgressBar { width = 60, height = 3, value = math.min(s.axes[2] / 15, 1), fillColor = MINT, backgroundColor = "#34443e", showLabel = false },
                UI.ProgressBar { width = 60, height = 3, value = math.min(s.axes[3] / 15, 1), fillColor = "#a6b6ae", backgroundColor = "#34443e", showLabel = false },
            } },
        } },
        UI.Panel { alignItems = "center", gap = 5, pointerEvents = "none", children = {
            Label(app.hoverText, 13, MINT, { id = "hoverText", textAlign = "center" }),
            Label(w < 1100 and "点击调查 · 拖动环顾" or "拖动环顾  ·  滚轮缩放  ·  点击调查  ·  J 线索  ·  Esc 暂停", 10, MUTED),
        } },
        UI.Panel { flexDirection = "row", gap = 7, children = {
            Button(app.hints and "隐藏热区 H" or "显示热区 H", function() app:Request("hints") end, { width = 104, fontSize = 11 }),
            Button("怀表 ×" .. s.watches, function() app:Request("watch") end, { width = 88, fontSize = 11 }),
        } },
    } })
    root:AddChild(bottom)
    local luc = s.lucidity > 79 and "清明" or (s.lucidity > 59 and "微雾" or (s.lucidity > 39 and "渗入" or (s.lucidity > 19 and "失真" or "将醒")))
    local watch = UI.Panel { position = "absolute", top = 135, right = 25, width = 62, height = 62, borderWidth = 1, borderColor = MINT, borderRadius = 31, backgroundColor = { 12, 26, 29, 180 }, alignItems = "center", justifyContent = "center", pointerEvents = "none", children = { Label("清醒", 8, MUTED), Label(luc, 13, MINT) } }
    root:AddChild(watch)
end

local INKD = { 43, 58, 54, 255 }
local MINTD = { 47, 138, 124, 255 }

local function Dialogue(app, root, w, h)
    local m = app.modal
    local panelWidth = math.min(w - 48, 940)
    local panel = UI.Panel {
        width = panelWidth, paddingHorizontal = 26, paddingVertical = 16, gap = 10,
        backgroundImage = "image/ui_textbox.png", backgroundFit = "fill",
    }
    panel:AddChild(Label(m.speaker or "程默", 12, MINTD, { letterSpacing = 3 }))
    if m.image and m.image ~= "" then panel:AddChild(Image(m.image, "100%", math.min(96, h * .13))) end
    local portrait = ""
    if m.speaker == "船长影" or m.speaker == "梦影" then portrait = "image/processed/char_captain_asylum.png"
    elseif m.speaker == "船客影" then portrait = "image/char_passenger_asylum.png"
    elseif m.speaker == "自己的镜像" then portrait = "image/char_mirror.png"
    elseif m.speaker == "服务员" then portrait = "image/processed/char_waiter_cruise.png" end
    if portrait ~= "" and w >= 800 and h >= 550 then
        root:AddChild(Image(portrait, 240, h * .62, { position = "absolute", right = "4%", bottom = 120, opacity = .92 }))
    end
    panel:AddChild(Label(app:VisibleText(), w < 700 and 13 or 16, INKD, { id = "dialogText", minHeight = 65, width = "100%" }))
    if m.kind == "choice" then
        for i, text in ipairs(m.choices) do
            panel:AddChild(Button(string.format("%02d   %s", i, text), function() app:Request("choose", i) end, {
                width = "100%", height = 44, fontSize = 13,
                backgroundImage = "image/ui_textbox.png", backgroundFit = "fill", backgroundColor = false,
                hoverBackgroundColor = { 245, 238, 220, 255 }, pressedBackgroundColor = { 210, 200, 175, 255 },
                textColor = INKD, borderWidth = 0, borderRadius = 0,
            }))
        end
    else
        panel:AddChild(Button(app:IsTyped() and "继续  →" or "显示全文", function() app:Request("dismiss") end, {
            width = 150, height = 40, alignSelf = "flex-end", fontSize = 13,
            backgroundImage = "image/ui_textbox.png", backgroundFit = "fill", backgroundColor = false,
            hoverBackgroundColor = { 245, 238, 220, 255 }, pressedBackgroundColor = { 210, 200, 175, 255 },
            textColor = INKD, borderWidth = 0, borderRadius = 0,
        }))
    end
    local maxBodyHeight = math.max(150, h - math.min(90, h * .12) - 55)
    local scroll = UI.ScrollView { width = panelWidth, height = math.min(maxBodyHeight, m.kind == "choice" and 410 or (m.image and m.image ~= "" and 365 or 285)), padding = 2, children = { panel } }
    panel:SetStyle({ width = "100%", flexShrink = 0 })
    root:AddChild(Overlay(app, { scroll }, { justifyContent = "flex-end", paddingBottom = math.min(90, h * .12), backgroundColor = { 3, 9, 12, 75 } }))
end

local function Writing(app, root, w, h)
    local c = app.state.chapter
    local panel = UI.Panel { width = math.min(780, w - 48), padding = 30, gap = 16, backgroundImage = "image/ui_book_bg.png", backgroundFit = "fill",
        children = {
            Label("第 " .. c .. " 章   /   手稿", 11, { 150, 210, 195, 255 }, { letterSpacing = 3 }),
            Label("下一句，得我自己写。", 27, { 232, 236, 226, 255 }),
            Label("你写下的句子，就是雾海号接下来的航程。", 13, { 198, 206, 196, 255 }),
        } }
    for i, text in ipairs(Story.writing[c]) do
        panel:AddChild(Button(text, function() app:Request("choose", i) end, {
            width = "100%", height = math.max(50, math.min(70, h * .10)), fontSize = 15,
            backgroundImage = "image/ui_textbox.png", backgroundFit = "fill", backgroundColor = false,
            hoverBackgroundColor = { 245, 238, 220, 235 }, pressedBackgroundColor = { 210, 200, 175, 235 },
            textColor = INKD, borderWidth = 0, borderRadius = 0,
        }))
    end
    root:AddChild(Overlay(app, { panel }))
end

local function Journal(app, root, w, h)
    local tabs = UI.Panel { flexDirection = "row", gap = 6 }
    for _, tab in ipairs({ "线索", "关系", "写作" }) do
        tabs:AddChild(Button(tab, function() app:Request("journalTab", tab) end, { width = 80, textColor = app.journalTab == tab and MINT or INK }))
    end
    local scroll = UI.ScrollView { flexGrow = 1, flexBasis = 0, width = "100%", gap = 12, paddingRight = 8 }
    if app.journalTab == "线索" then
        for _, clue in ipairs(Game.evidence) do
            local known = app.state.clues[clue[1]]
            local card = UI.Panel { width = "100%", padding = 12, gap = 5, backgroundColor = { 30, 44, 46, 255 }, borderRadius = 2 }
            card:AddChild(Label(known and clue[2] or "尚未发现", 16, known and INK or MUTED))
            card:AddChild(Label(clue[3], 10, MUTED))
            if known then card:AddChild(Label(clue[4], 13, INK)) end
            scroll:AddChild(card)
        end
    elseif app.journalTab == "关系" then
        local lines = {
            { "程默 ── 船长影 ── 主治医生", "record", "黑皮夹，留观记录，同一张脸。" },
            { "程默 ── 服务员 ── 值班护士", "medicine", "宴会就是服药时间。" },
            { "程默 ── 船客影 ── 病友", "cup", "有人和我一样，把这里当作邮轮。" },
            { "程默 ── 镜像 ── 清醒意识", "ticket", "你写的那艘船，是雾海号。你写的那个人，是你。" },
            { "程默 ── 母亲 ── 合照与信", "photo", "涂去的脸，未写完的信。" },
        }
        for _, row in ipairs(lines) do
            scroll:AddChild(Label(row[1], 16, app.state.clues[row[2]] and MINT or MUTED))
            scroll:AddChild(Label(app.state.clues[row[2]] and row[3] or "证据尚未连接。", 13, MUTED))
            scroll:AddChild(UI.Panel { height = 16 })
        end
    else
        for i = 1, 3 do
            local choice = app.state.writing[i]
            scroll:AddChild(Label("第 " .. i .. " 章", 12, MINT))
            scroll:AddChild(Label(choice and Story.writing[i][choice] or "这一页还空着。", 18, INK))
            scroll:AddChild(UI.Panel { height = 16 })
        end
    end
    local panel = UI.Panel { width = math.min(510, w - 24), height = h - 28, padding = 22, gap = 12, backgroundColor = DARK, borderWidth = 1, borderColor = { 94, 200, 184, 100 }, children = {
        UI.Panel { flexDirection = "row", justifyContent = "space-between", children = { Label("航 程 线 索 册", 22), Button("关闭", function() app:Request("close") end, { width = 64 }) } },
        Label("证据 " .. Game.Count(app.state) .. " / 15   ·   靠岸至少需要 11 条", 12, MINT),
        UI.ProgressBar { width = "100%", height = 3, value = Game.Count(app.state) / 15, fillColor = MINT, showLabel = false }, tabs, scroll,
    } }
    root:AddChild(Overlay(app, { panel }, { alignItems = "flex-end", padding = 14 }))
end

local function Settings(app, root, w, h)
    local body = UI.Panel { width = "100%", gap = 13 }
    body:AddChild(Label("操作", 14, MINT))
    body:AddChild(Label("点击物件调查；拖动背景环顾，滚轮缩放。\nJ 打开线索册；H 显示或隐藏热区；Esc 暂停。\n锚点有薄荷色微光，触碰后切换世界，每次消耗清醒度。", 13, INK))
    body:AddChild(Rule())
    body:AddChild(Button(app.hints and "热区标记：开" or "热区标记：关", function() app:Request("hints") end, { width = "100%" }))
    body:AddChild(Button(app.typewriter and "逐字显示：开" or "逐字显示：关", function() app:Request("typewriter") end, { width = "100%" }))
    body:AddChild(Label("画面不使用程序额外频闪。原始病房和走廊图片自带静态故障纹理。\n本地存档：原生客户端可保留；当前网页预览刷新后可能丢失。", 11, MUTED))
    if app.screen == "game" then
        body:AddChild(Button("回客舱休息 · 恢复清醒度", function() app:Request("rest") end, { width = "100%" }))
        body:AddChild(Button("保存并返回标题", function() app:Request("title") end, { width = "100%" }))
    end
    body:AddChild(Button("返回", function() app:Request("close") end, { width = "100%", borderColor = MINT }))
    local scroll = UI.ScrollView { width = "100%", flexGrow = 1, flexBasis = 0, children = { body } }
    root:AddChild(Overlay(app, { UI.Panel { width = math.min(540, w - 36), height = math.min(650, h - 36), backgroundColor = DARK, borderWidth = 1, borderColor = MINT, padding = 24, gap = 14, children = { Label("航程暂停", 26), Rule(), scroll } } }))
end

local function Password(app, root, w)
    local panel = UI.Panel { width = math.min(380, w - 32), padding = 24, gap = 13, backgroundColor = DARK, borderWidth = 1, borderColor = MINT, children = {
        Label("驾驶台 · 密码锁", 22), Label("四位数字。我一定在哪里见过……", 12, MUTED),
        Label(app.password == "" and "— — — —" or app.password, 32, MINT, { textAlign = "center", letterSpacing = 8 }),
        Label(app.passwordError, 12, MUTED),
    } }
    for row = 1, 3 do
        local keys = UI.Panel { flexDirection = "row", gap = 8 }
        for col = 1, 3 do
            local number = tostring((row - 1) * 3 + col)
            keys:AddChild(Button(number, function() app:Request("digit", number) end, { flexGrow = 1, flexBasis = 0, fontSize = 18 }))
        end
        panel:AddChild(keys)
    end
    panel:AddChild(UI.Panel { flexDirection = "row", gap = 8, children = {
        Button("清除", function() app:Request("digit", "clear") end, { flexGrow = 1, flexBasis = 0 }),
        Button("0", function() app:Request("digit", "0") end, { flexGrow = 1, flexBasis = 0 }),
        Button("解锁", function() app:Request("unlock") end, { flexGrow = 1, flexBasis = 0, textColor = MINT }),
    } })
    panel:AddChild(Button("查看线索册", function() app:Request("journalPassword") end, { width = "100%" }))
    panel:AddChild(Button("返回", function() app:Request("close") end, { width = "100%" }))
    root:AddChild(Overlay(app, { panel }))
end

local function Challenge(app, root, w)
    local observe = app.modal.mode == "observe"
    local button = Button(observe and "凝视倒影 · 保持三秒" or ("砸碎玻璃 · " .. app.challengeCount .. "/3"), function() if not observe then app:Request("break") end end, { width = "100%", height = 70, textColor = MINT })
    button.props.onPointerEnter = function() app.observing = true end
    button.props.onPointerLeave = function() app.observing = false; app.observeTime = 0 end
    local panel = UI.Panel { width = math.min(470, w - 36), padding = 28, gap = 18, backgroundColor = DARK, borderWidth = 1, borderColor = MINT, children = {
        Label(Game.personas[app.state.persona], 23), Label(app.modal.text, 15, INK), button,
        UI.ProgressBar { id = "observeBar", width = "100%", height = 4, value = app.observeTime / 3, fillColor = MINT, showLabel = false },
        Button("稍后再看", function() app:Request("close") end, { width = "100%" }),
    } }
    root:AddChild(Overlay(app, { panel }))
end

local function Travel(app, root, w)
    local panel = UI.Panel { width = math.min(460, w - 36), padding = 26, gap = 12, backgroundColor = DARK, borderWidth = 1, borderColor = MINT, children = { Label("航程回访", 24), Label("只能回访已经抵达的邮轮区域。疗养院必须通过信物离开。", 12, MUTED) } }
    for i = 1, app.state.maxChapter do
        panel:AddChild(Button(Game.chapters[i], function() app:Request("travelTo", i) end, { width = "100%" }))
    end
    panel:AddChild(Button("返回", function() app:Request("close") end, { width = "100%" }))
    root:AddChild(Overlay(app, { panel }))
end

local function Ending(app, w, h)
    local s = app.state
    local ending = Story.nodes[s.ending]
    local names = { ["4-3-001"] = "醒来", ["4-3-002"] = "不甘", ["4-3-003"] = "清醒地醒来", ["4-3-004"] = "循环", ["4-3-005"] = "永眠", ["4-3-006"] = "消散", ["4-3-007"] = "惊醒" }
    local root = UI.Panel { width = "100%", height = "100%", backgroundColor = "#111e22", children = {
        Image("image/scene_exit_asylum.png", "100%", "100%", { position = "absolute", top = 0, left = 0, backgroundFit = "cover", opacity = .18 }),
    } }
    local panel = UI.Panel { width = math.min(780, w - 60), gap = 20 }
    panel:AddChild(Label("THE LAST VOYAGE   /   航程结束", 11, MINT, { letterSpacing = 3 }))
    panel:AddChild(Label(names[s.ending] or "篇终", 44, INK))
    panel:AddChild(Rule())
    panel:AddChild(Label(ending and ending.text or "雾散了。", 17, INK))
    panel:AddChild(Label("证据 " .. Game.Count(s) .. "/15  ·  " .. (s.persona > 0 and Game.personas[s.persona] or "尚未成形") .. "\n剧本与美术：项目提供素材   /   UrhoX 原型实现", 11, MUTED))
    panel:AddChild(Button("返回标题 · 再一次启航", function() app:Request("title") end, { width = 230, borderColor = MINT }))
    local scroll = UI.ScrollView { width = "100%", height = "100%", padding = 30, alignItems = "center", children = { panel } }
    root:AddChild(scroll)
    return root
end

function View.Build(app)
    local w, h = UI.GetViewportSize()
    w, h = math.max(480, w), math.max(320, h)
    local root
    if app.screen == "ending" then root = Ending(app, w, h)
    elseif app.screen == "title" then root = Title(app, w, h)
    else
        root = UI.Panel { width = "100%", height = "100%", backgroundColor = "#112027", overflow = "hidden" }
        Background(app, root, w, h); HUD(app, root, w)
    end
    local kind = app.modal.kind
    if kind == "dialogue" or kind == "choice" then Dialogue(app, root, w, h)
    elseif kind == "writing" then Writing(app, root, w, h)
    elseif kind == "journal" then Journal(app, root, w, h)
    elseif kind == "settings" then Settings(app, root, w, h)
    elseif kind == "password" then Password(app, root, w)
    elseif kind == "challenge" then Challenge(app, root, w)
    elseif kind == "travel" then Travel(app, root, w) end
    if app.transitionTime > 0 then
        root:AddChild(Overlay(app, { Label("雾 正 在 翻 面", 22, MINT, { letterSpacing = 4 }) }, { backgroundColor = { 18, 35, 39, 250 } }))
    end
    if app.toast ~= "" then
        root:AddChild(UI.Panel { position = "absolute", top = "21%", left = "20%", right = "20%", padding = 12, backgroundColor = DARK, borderWidth = 1, borderColor = MINT, pointerEvents = "none", children = { Label(app.toast, 12, MINT, { textAlign = "center" }) } })
    end
    UI.SetRoot(root, true)
    app.root = root
end

return View
