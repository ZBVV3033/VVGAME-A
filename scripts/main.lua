-- 《雾海号》入口，基于标准 2D 脚手架的生命周期。
local UI = require("urhox-libs/UI")
local Game = require("FogSea.Game")
local View = require("FogSea.View")

---@class FogSeaApp
---@field state FogSeaState
---@field screen string
---@field modal table
---@field root Panel
---@field stage Panel
---@field pending table[]
---@field hasSave boolean
---@field hints boolean
---@field typewriter boolean
---@field journalTab string
---@field password string
---@field passwordError string
---@field challengeCount integer
---@field observeTime number
---@field observing boolean
---@field transitionTime number
---@field toast string
---@field toastTime number
---@field hoverText string
---@field pan number
---@field zoom number
---@field typed number
---@field idle number
---@field saveTime number
---@field dirty boolean
---@field returnPassword boolean
---@field width number
---@field height number
local App = {}
App.__index = App

function App:Init()
    self.state = Game.New()
    self.screen = "title"
    self.modal = { kind = "none" }
    self.root = UI.Panel {}
    self.stage = UI.Panel {}
    self.pending = {}
    self.hasSave = false
    self.hints = true
    self.typewriter = true
    self.journalTab = "线索"
    self.password = ""
    self.passwordError = ""
    self.challengeCount = 0
    self.observeTime = 0
    self.observing = false
    self.transitionTime = 0
    self.toast = ""
    self.toastTime = 0
    self.hoverText = ""
    self.pan = 0
    self.zoom = 1
    self.typed = 0
    self.idle = 0
    self.saveTime = 0
    self.dirty = true
    self.returnPassword = false
    self.width, self.height = UI.GetViewportSize()
    self.hasSave = self:ReadSave() ~= nil
    print("[雾海号] 初始化完成。单机模式；本地素材；未接入账号、内购或广告。")
end

function App:ReadSave()
    if not fileSystem:FileExists("fogsea_save.json") then return nil end
    local file = File("fogsea_save.json", FILE_READ)
    if not file or not file:IsOpen() then return nil end
    local text = file:ReadString()
    file:Close(); file:Dispose()
    local ok, data = pcall(cjson.decode, text)
    if ok and Game.Validate(data) then
        -- JSON数字可能解码为float，恢复integer，避免 shadow1 变成 shadow1.0。
        for _, key in ipairs({ "chapter", "persona", "maxChapter", "rests", "watches", "errors" }) do
            data[key] = math.tointeger(data[key])
        end
        for i, choice in pairs(data.writing) do data.writing[i] = math.tointeger(choice) end
        return data
    end
    print("[雾海号] 存档不兼容或已结束，不提供继续。")
    return nil
end

function App:Save()
    if self.state.ending ~= "" or self.screen ~= "game" then return end
    local file = File("fogsea_save.json", FILE_WRITE)
    if file and file:IsOpen() then
        file:WriteString(cjson.encode(self.state)); file:Close(); file:Dispose()
        self.hasSave = true
        print("[雾海号] 自动保存，章节=" .. self.state.chapter .. "，世界=" .. self.state.world)
    else print("[雾海号] 警告：当前环境未能写入本地存档。") end
end

function App:Request(action, value)
    -- 输入回调中只入队，下一次 Update 再重建 UI，避免销毁仍在派发事件的控件。
    if self.transitionTime > 0 then return end
    self.pending[#self.pending + 1] = { action, value }
end

function App:SetHover(text)
    self.hoverText = text
    local label = self.root:FindById("hoverText") --[[@as Label?]]
    if label then label:SetText(text) end
end

function App:Notify(text)
    self.toast = text; self.toastTime = 3; self.dirty = true
end

function App:IsTyped()
    local text = self.modal.text or ""
    return self.typed >= (utf8.len(text) or #text) or not self.typewriter
end

function App:VisibleText()
    local text = self.modal.text or ""
    if not self.typewriter then return text end
    local count = math.floor(self.typed)
    if count <= 0 then return " " end
    local length = utf8.len(text) or #text
    if count >= length then return text end
    local offset = utf8.offset(text, count + 1)
    return offset and text:sub(1, offset - 1) or text
end

function App:Present(result)
    if self.state.ending ~= "" or result.kind == "ending" then
        self.screen = "ending"; self.modal = { kind = "none" }
        -- 让完成/失败状态覆盖单档，不能从惊醒前的存档继续。
        local file = File("fogsea_save.json", FILE_WRITE)
        if file and file:IsOpen() then file:WriteString(cjson.encode(self.state)); file:Close(); file:Dispose() end
        self.hasSave = false
        print("[雾海号] 航程结局：" .. self.state.ending)
    elseif result.kind == "transition" then
        self.transitionTime = 1
        self.modal = { kind = "dialogue", text = result.text, speaker = result.speaker or "程默" }
        self.pan = 0; self.zoom = 1; self.hoverText = ""
    else self.modal = result end
    if result.kind == "writing" then self.modal.action = "writing" end
    self.typed = 0; self.idle = 0; self.dirty = true
    self:Save()
end

function App:Execute(action, value)
    if action == "new" then
        if self.hasSave and value ~= "confirmed" then
            self.modal = { kind = "choice", text = "开始新航程会覆盖当前唯一存档。", choices = { "确认开始新航程", "保留存档，返回" }, action = "confirmNew" }; self.dirty = true; return
        end
        self.state = Game.New(); self.screen = "game"; self.pan = 0; self.zoom = 1
        self:Present({ kind = "dialogue", speaker = "程默", text = Game.Line("0-1-001") .. "\n\n" .. Game.Line("0-1-002") })
    elseif action == "continue" then
        local data = self:ReadSave()
        if data then self.state = data; self.screen = "game"; self.modal = { kind = "none" }; self.dirty = true
        else self:Notify("未找到可继续的存档。网页预览刷新可能会清除本地数据。") end
    elseif action == "spot" then
        if self.screen ~= "game" or self.modal.kind ~= "none" then return end
        self.challengeCount = 0; self.observeTime = 0; self.observing = false
        self:Present(Game.Interact(self.state, value))
    elseif action == "choose" then
        if self.modal.action == "confirmNew" then
            if value == 1 then self.hasSave = false; self:Execute("new", "confirmed")
            else self.modal = { kind = "none" }; self.dirty = true end
            return
        end
        local result = Game.Choose(self.state, self.modal.action, value)
        self:Present(result)
    elseif action == "dismiss" then
        if self.modal.kind ~= "dialogue" then return end
        if not self:IsTyped() then self.typed = 10000; self.dirty = true
        else self.modal = { kind = "none" }; self.dirty = true end
    elseif action == "close" then
        if self.returnPassword then self.modal = { kind = "password" }; self.returnPassword = false
        else self.modal = { kind = "none" } end
        self.dirty = true
    elseif action == "settings" then
        if self.modal.kind == "none" then self.modal = { kind = "settings" }; self.dirty = true end
    elseif action == "title" then
        self:Save(); self.screen = "title"; self.modal = { kind = "none" }; self.dirty = true
    elseif action == "quit" then
        if self.hasSave then self:Save() end
        if engine then engine:Exit() end
    elseif action == "journal" or action == "journalPassword" then
        if action == "journalPassword" then self.returnPassword = true end
        self.modal = { kind = "journal" }; self.dirty = true
    elseif action == "journalTab" then self.journalTab = value; self.dirty = true
    elseif action == "hints" then self.hints = not self.hints; self.dirty = true
    elseif action == "typewriter" then self.typewriter = not self.typewriter; self.dirty = true
    elseif action == "rest" then
        local s = self.state
        if s.world ~= "cruise" then self:Notify("疗养院不是安全点。先找到信物返回。")
        else
            local text = Game.Rest(s)
            self:Notify(text); self:Save()
        end
    elseif action == "watch" then self:Notify(Game.Watch(self.state)); self:Save()
    elseif action == "digit" then
        if self.modal.kind ~= "password" then return end
        if value == "clear" then self.password = ""
        elseif #self.password < 4 then self.password = self.password .. value end
        self.passwordError = ""; self.dirty = true
    elseif action == "unlock" then
        if self.modal.kind ~= "password" then return end
        if Game.Password(self.state, self.password) then
            self.password = ""; self.passwordError = ""
            -- 制作说明6.4：锁定演出用称呼台词，不依赖Story节点文本。
            local lines = { "心软的那位。我们，该靠岸了。", "掀桌的那位。这船，从现在起听你的。", "看戏的那位。你还要，看到什么时候。" }
            self:Present({ kind = "transition", text = lines[self.state.persona], speaker = "船长影" })
        else self.passwordError = self.state.errors % 3 == 0 and "门后低语：你又来了。" or "锁芯没有转动。再看一眼药瓶标签。"; self.password = ""; self.dirty = true; self:Save() end
    elseif action == "break" then
        if self.modal.kind ~= "challenge" then return end
        self.challengeCount = self.challengeCount + 1
        if self.challengeCount >= 3 then self:Present(Game.Choose(self.state, "log", 1)) else self.dirty = true end
    elseif action == "travel" then
        if self.state.world == "asylum" then self:Notify("找回当前场景的信物，才能离开疗养院。")
        else self.modal = { kind = "travel" }; self.dirty = true end
    elseif action == "travelTo" then
        if self.state.world ~= "cruise" or value > self.state.maxChapter then return end
        self.state.chapter = value; self.pan = 0; self.zoom = 1
        self:Present({ kind = "transition", text = "我沿着记忆，再走一遍。" })
    elseif action == "zoom" then
        if self.screen ~= "game" or self.modal.kind ~= "none" then return end
        self.zoom = math.max(1, math.min(1.7, self.zoom + value * .08)); self.dirty = true
    elseif action == "escape" then
        -- 叙事选择不能通过Esc跳过；世界翻面后的关键状态始终保存在state里。
        if self.modal.kind == "none" then self:Execute("settings")
        elseif self.modal.kind == "dialogue" then self:Execute("dismiss")
        elseif self.modal.kind ~= "choice" and self.modal.kind ~= "writing" then self:Execute("close") end
    end
end

function App:Update(dt)
    local request = table.remove(self.pending, 1)
    if request then self:Execute(request[1], request[2]) end
    if self.transitionTime > 0 then
        self.transitionTime = math.max(0, self.transitionTime - dt)
        if self.transitionTime == 0 then self.dirty = true end
    end
    if self.toastTime > 0 then
        self.toastTime = self.toastTime - dt
        if self.toastTime <= 0 then self.toast = ""; self.dirty = true end
    end
    if self.modal.kind == "dialogue" or self.modal.kind == "choice" then
        if not self:IsTyped() and self.transitionTime == 0 then
            self.typed = self.typed + dt * 36
            local label = self.root:FindById("dialogText") --[[@as Label?]]
            if label then label:SetText(self:VisibleText()) end
            if self:IsTyped() then self.dirty = true end
        end
    end
    if self.modal.kind == "challenge" and self.modal.mode == "observe" then
        if self.observing then self.observeTime = self.observeTime + dt end
        local bar = self.root:FindById("observeBar") --[[@as ProgressBar?]]
        if bar then bar:SetValue(math.min(1, self.observeTime / 3)) end
        if self.observeTime >= 3 then self.observing = false; self:Present(Game.Choose(self.state, "log", 1)) end
    end
    if self.screen == "game" and self.transitionTime == 0 and (self.modal.kind == "none" or self.modal.kind == "dialogue" or self.modal.kind == "choice" or self.modal.kind == "challenge") then
        local before = self.state.lucidity
        Game.Tick(self.state, dt)
        if self.state.ending ~= "" then self:Present({ kind = "ending" })
        elseif before ~= self.state.lucidity then self.dirty = true end
        self.idle = self.idle + dt
        if self.idle >= 60 and self.hints and self.modal.kind == "none" then self:Notify(Game.Objective(self.state)); self.idle = 0 end
        self.saveTime = self.saveTime + dt
        if self.saveTime >= 30 then self.saveTime = 0; self:Save() end
    end
    local w, h = UI.GetViewportSize()
    if w ~= self.width or h ~= self.height then self.width, self.height = w, h; self.dirty = true end
    if self.dirty then self.dirty = false; View.Build(self) end
end

local app = setmetatable({}, App)
function Start()
    graphics.windowTitle = "雾海号 · The Last Voyage"
    input.mouseMode = MM_ABSOLUTE
    View.Init(); app:Init(); View.Build(app)
    SubscribeToEvent("Update", "HandleFogSeaUpdate")
    SubscribeToEvent("KeyDown", "HandleFogSeaKeyDown")
    SubscribeToEvent("MouseWheel", "HandleFogSeaWheel")
end

---@param eventType string
---@param eventData UpdateEventData
function HandleFogSeaUpdate(eventType, eventData)
    app:Update(math.min(eventData:GetFloat("TimeStep"), .1))
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleFogSeaKeyDown(eventType, eventData)
    local key = eventData:GetInt("Key")
    if key == KEY_ESCAPE then app:Request("escape")
    elseif key == KEY_J and app.screen == "game" and app.modal.kind == "none" then app:Request("journal")
    elseif key == KEY_H then app:Request("hints")
    elseif key == KEY_SPACE or key == KEY_RETURN then
        if app.modal.kind == "dialogue" then app:Request("dismiss")
        elseif app.modal.kind == "password" then app:Request("unlock") end
    end
end

---@param eventType string
---@param eventData MouseWheelEventData
function HandleFogSeaWheel(eventType, eventData)
    app:Request("zoom", eventData:GetInt("Wheel"))
end

function Stop()
    app:Save(); UI.Shutdown()
end
