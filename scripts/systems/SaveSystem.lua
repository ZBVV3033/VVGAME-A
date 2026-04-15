-- ============================================================================
-- SaveSystem.lua - 存档/读档系统（悠闲悠哉life）
-- 支持3个存档槽位，使用 File API + cjson 序列化
-- ============================================================================

---@diagnostic disable: undefined-global

local GameState = require("systems.GameState")

local SaveSystem = {}

--- 最大存档槽位数
SaveSystem.MAX_SLOTS = 3

--- 存档目录
local SAVE_DIR = "saves"

--- 获取存档文件路径
---@param slot number 1~3
---@return string
local function getSavePath(slot)
    return SAVE_DIR .. "/slot" .. slot .. ".json"
end

--- 需要序列化的状态键（排除运行时临时变量）
local SKIP_KEYS = {
    notifications = true,
    currentEvent = true,
    _settingsFrom = true,
    _changelogPage = true,
    _spoilerExpanded = true,
}

--- 深拷贝 table（用于序列化）
---@param t table
---@return table
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

--- 初始化存档目录
function SaveSystem.init()
    if not fileSystem:DirExists(SAVE_DIR) then
        fileSystem:CreateDir(SAVE_DIR)
    end
end

--- 保存游戏到指定槽位
---@param slot number 1~3
---@return boolean success
---@return string message
function SaveSystem.save(slot)
    if slot < 1 or slot > SaveSystem.MAX_SLOTS then
        return false, "无效的存档槽位"
    end

    SaveSystem.init()

    local S = GameState.state
    -- 构建存档数据
    local saveData = {}
    for k, v in pairs(S) do
        if not SKIP_KEYS[k] then
            if type(v) == "table" then
                saveData[k] = deepCopy(v)
            elseif type(v) ~= "function" then
                saveData[k] = v
            end
        end
    end

    -- 添加存档元信息
    saveData._saveInfo = {
        slot = slot,
        playerName = S.PNN ~= "" and S.PNN or "诺兰",
        date = S.year .. "年" .. S.month .. "月" .. S.day .. "日",
        time = GameState.getTimeStr(),
        money = S.money,
        lifeLevel = S.lifeLevel,
        location = S.currentPassage or "未知",
        savedAt = os.date("%Y-%m-%d %H:%M"),
    }

    local ok, jsonStr = pcall(cjson.encode, saveData)
    if not ok then
        return false, "序列化失败: " .. tostring(jsonStr)
    end

    local file = File(getSavePath(slot), FILE_WRITE)
    if not file or not file:IsOpen() then
        return false, "无法创建存档文件"
    end
    file:WriteString(jsonStr)
    file:Close()

    return true, "存档成功！"
end

--- 从指定槽位读取存档
---@param slot number 1~3
---@return boolean success
---@return string message
function SaveSystem.load(slot)
    if slot < 1 or slot > SaveSystem.MAX_SLOTS then
        return false, "无效的存档槽位"
    end

    local path = getSavePath(slot)
    if not fileSystem:FileExists(path) then
        return false, "该槽位没有存档"
    end

    local file = File(path, FILE_READ)
    if not file or not file:IsOpen() then
        return false, "无法读取存档文件"
    end
    local jsonStr = file:ReadString()
    file:Close()

    local ok, saveData = pcall(cjson.decode, jsonStr)
    if not ok then
        return false, "存档数据损坏"
    end

    -- 先初始化默认状态，再覆盖
    GameState.init()
    local S = GameState.state

    for k, v in pairs(saveData) do
        if k ~= "_saveInfo" and not SKIP_KEYS[k] then
            if type(v) == "table" then
                S[k] = deepCopy(v)
            else
                S[k] = v
            end
        end
    end

    -- 恢复运行时变量
    S.notifications = {}
    S._settingsFrom = nil
    S._changelogPage = 1
    S._spoilerExpanded = {}

    return true, "读档成功！"
end

--- 获取存档槽位信息（用于显示）
---@param slot number 1~3
---@return table|nil 存档信息，nil 表示空槽位
function SaveSystem.getSlotInfo(slot)
    local path = getSavePath(slot)
    if not fileSystem:FileExists(path) then
        return nil
    end

    local file = File(path, FILE_READ)
    if not file or not file:IsOpen() then
        return nil
    end
    local jsonStr = file:ReadString()
    file:Close()

    local ok, saveData = pcall(cjson.decode, jsonStr)
    if not ok then
        return nil
    end

    return saveData._saveInfo
end

--- 获取所有槽位信息
---@return table[] 每个槽位的信息（nil 表示空）
function SaveSystem.getAllSlotInfo()
    SaveSystem.init()
    local slots = {}
    for i = 1, SaveSystem.MAX_SLOTS do
        slots[i] = SaveSystem.getSlotInfo(i)
    end
    return slots
end

--- 删除指定槽位存档
---@param slot number 1~3
---@return boolean
function SaveSystem.delete(slot)
    local path = getSavePath(slot)
    if fileSystem:FileExists(path) then
        return fileSystem:Delete(path)
    end
    return true
end

return SaveSystem
