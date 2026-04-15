-- ============================================================================
-- EditorData.lua — 剧情编辑器数据层
-- 负责段落/选项/条件/效果/变量的 CRUD 操作和 JSON 序列化
-- ============================================================================

---@diagnostic disable: undefined-global

local EditorData = {}

-- 当前编辑中的数据
local data_ = nil

-- 选中状态
local selectedPassageId_ = nil
local selectedChoiceIndex_ = nil

-- 脏标记
local dirty_ = false

-- ============================================================================
-- 默认示例数据
-- ============================================================================

local DEFAULT_DATA = {
    passages = {
        ["开始"] = {
            text = "你来到了一座古老的城镇。\n远处传来钟声，街道上行人稀少。",
            choices = {
                {
                    text = "前往酒馆",
                    target = "酒馆",
                    conditions = {},
                    effects = { { type = "set", var = "visited_start", value = 1 } },
                },
                {
                    text = "查看公告板",
                    target = "公告板",
                    conditions = {},
                    effects = {},
                },
                {
                    text = "和路人交谈",
                    target = "路人对话",
                    conditions = { { type = "attribute", var = "ML", op = ">=", value = 3 } },
                    effects = { { type = "add", var = "ML", value = 1 } },
                },
            },
        },
        ["酒馆"] = {
            text = "酒馆里光线昏暗，空气中弥漫着酒香。\n几个人在角落低声交谈。",
            choices = {
                {
                    text = "和酒保交谈",
                    target = "酒保对话",
                    conditions = {},
                    effects = {},
                },
                {
                    text = "离开酒馆",
                    target = "开始",
                    conditions = {},
                    effects = {},
                },
            },
        },
        ["公告板"] = {
            text = "公告板上贴满了各种告示。\n其中一张特别醒目——悬赏通缉令。",
            choices = {
                {
                    text = "仔细阅读悬赏令",
                    target = "悬赏详情",
                    conditions = {},
                    effects = { { type = "set", var = "know_bounty", value = 1 } },
                },
                {
                    text = "返回",
                    target = "开始",
                    conditions = {},
                    effects = {},
                },
            },
        },
    },
    variables = {
        ML = { type = "int", default = 0, desc = "魅力" },
        JQ = { type = "int", default = 0, desc = "技巧" },
        NL = { type = "int", default = 0, desc = "耐力" },
        LL = { type = "int", default = 0, desc = "力量" },
        visited_start = { type = "int", default = 0, desc = "已访问起点" },
        know_bounty = { type = "int", default = 0, desc = "知道悬赏" },
    },
    passageOrder = { "开始", "酒馆", "公告板" },
}

-- ============================================================================
-- 初始化
-- ============================================================================

function EditorData.Init()
    data_ = EditorData.DeepCopy(DEFAULT_DATA)
    selectedPassageId_ = nil
    selectedChoiceIndex_ = nil
    dirty_ = false
end

function EditorData.GetData()
    return data_
end

function EditorData.IsDirty()
    return dirty_
end

function EditorData.ClearDirty()
    dirty_ = false
end

-- ============================================================================
-- 段落 CRUD
-- ============================================================================

function EditorData.GetPassageIds()
    if data_.passageOrder and #data_.passageOrder > 0 then
        return data_.passageOrder
    end
    local ids = {}
    for id, _ in pairs(data_.passages) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return ids
end

function EditorData.GetPassage(id)
    return data_.passages[id]
end

function EditorData.AddPassage(id)
    if data_.passages[id] then
        return false, "段落已存在: " .. id
    end
    data_.passages[id] = {
        text = "",
        choices = {},
    }
    if not data_.passageOrder then
        data_.passageOrder = {}
    end
    data_.passageOrder[#data_.passageOrder + 1] = id
    dirty_ = true
    return true
end

function EditorData.RemovePassage(id)
    if not data_.passages[id] then
        return false
    end
    data_.passages[id] = nil
    -- 从排序列表移除
    if data_.passageOrder then
        for i = #data_.passageOrder, 1, -1 do
            if data_.passageOrder[i] == id then
                table.remove(data_.passageOrder, i)
                break
            end
        end
    end
    -- 如果删除的是当前选中的段落
    if selectedPassageId_ == id then
        selectedPassageId_ = nil
        selectedChoiceIndex_ = nil
    end
    dirty_ = true
    return true
end

function EditorData.RenamePassage(oldId, newId)
    if not data_.passages[oldId] then return false, "原段落不存在" end
    if data_.passages[newId] then return false, "新名称已存在" end

    data_.passages[newId] = data_.passages[oldId]
    data_.passages[oldId] = nil

    -- 更新排序列表
    if data_.passageOrder then
        for i, v in ipairs(data_.passageOrder) do
            if v == oldId then
                data_.passageOrder[i] = newId
                break
            end
        end
    end

    -- 更新所有选项的 target 引用
    for _, passage in pairs(data_.passages) do
        for _, choice in ipairs(passage.choices or {}) do
            if choice.target == oldId then
                choice.target = newId
            end
        end
    end

    if selectedPassageId_ == oldId then
        selectedPassageId_ = newId
    end

    dirty_ = true
    return true
end

function EditorData.SetPassageText(id, text)
    local p = data_.passages[id]
    if p then
        p.text = text
        dirty_ = true
    end
end

-- ============================================================================
-- 选项 CRUD
-- ============================================================================

function EditorData.GetChoices(passageId)
    local p = data_.passages[passageId]
    if p then return p.choices or {} end
    return {}
end

function EditorData.AddChoice(passageId)
    local p = data_.passages[passageId]
    if not p then return false end
    if not p.choices then p.choices = {} end
    p.choices[#p.choices + 1] = {
        text = "新选项",
        target = "",
        conditions = {},
        effects = {},
    }
    dirty_ = true
    return true
end

function EditorData.RemoveChoice(passageId, index)
    local p = data_.passages[passageId]
    if not p or not p.choices then return false end
    if index < 1 or index > #p.choices then return false end
    table.remove(p.choices, index)
    if selectedChoiceIndex_ == index then
        selectedChoiceIndex_ = nil
    elseif selectedChoiceIndex_ and selectedChoiceIndex_ > index then
        selectedChoiceIndex_ = selectedChoiceIndex_ - 1
    end
    dirty_ = true
    return true
end

function EditorData.SetChoiceText(passageId, index, text)
    local p = data_.passages[passageId]
    if p and p.choices and p.choices[index] then
        p.choices[index].text = text
        dirty_ = true
    end
end

function EditorData.SetChoiceTarget(passageId, index, target)
    local p = data_.passages[passageId]
    if p and p.choices and p.choices[index] then
        p.choices[index].target = target
        dirty_ = true
    end
end

-- ============================================================================
-- 条件/效果 CRUD
-- ============================================================================

function EditorData.AddCondition(passageId, choiceIndex)
    local p = data_.passages[passageId]
    if not p or not p.choices or not p.choices[choiceIndex] then return false end
    local c = p.choices[choiceIndex]
    if not c.conditions then c.conditions = {} end
    c.conditions[#c.conditions + 1] = {
        type = "attribute",
        var = "ML",
        op = ">=",
        value = 0,
    }
    dirty_ = true
    return true
end

function EditorData.RemoveCondition(passageId, choiceIndex, condIndex)
    local p = data_.passages[passageId]
    if not p or not p.choices or not p.choices[choiceIndex] then return false end
    local conds = p.choices[choiceIndex].conditions
    if not conds or condIndex < 1 or condIndex > #conds then return false end
    table.remove(conds, condIndex)
    dirty_ = true
    return true
end

function EditorData.UpdateCondition(passageId, choiceIndex, condIndex, field, value)
    local p = data_.passages[passageId]
    if not p or not p.choices or not p.choices[choiceIndex] then return false end
    local conds = p.choices[choiceIndex].conditions
    if not conds or not conds[condIndex] then return false end
    conds[condIndex][field] = value
    dirty_ = true
    return true
end

function EditorData.AddEffect(passageId, choiceIndex)
    local p = data_.passages[passageId]
    if not p or not p.choices or not p.choices[choiceIndex] then return false end
    local c = p.choices[choiceIndex]
    if not c.effects then c.effects = {} end
    c.effects[#c.effects + 1] = {
        type = "set",
        var = "ML",
        value = 0,
    }
    dirty_ = true
    return true
end

function EditorData.RemoveEffect(passageId, choiceIndex, effIndex)
    local p = data_.passages[passageId]
    if not p or not p.choices or not p.choices[choiceIndex] then return false end
    local effs = p.choices[choiceIndex].effects
    if not effs or effIndex < 1 or effIndex > #effs then return false end
    table.remove(effs, effIndex)
    dirty_ = true
    return true
end

function EditorData.UpdateEffect(passageId, choiceIndex, effIndex, field, value)
    local p = data_.passages[passageId]
    if not p or not p.choices or not p.choices[choiceIndex] then return false end
    local effs = p.choices[choiceIndex].effects
    if not effs or not effs[effIndex] then return false end
    effs[effIndex][field] = value
    dirty_ = true
    return true
end

-- ============================================================================
-- 变量管理
-- ============================================================================

function EditorData.GetVariables()
    return data_.variables or {}
end

function EditorData.GetVariableNames()
    local names = {}
    for name, _ in pairs(data_.variables or {}) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function EditorData.AddVariable(name, varType, default, desc)
    if not data_.variables then data_.variables = {} end
    if data_.variables[name] then return false, "变量已存在" end
    data_.variables[name] = {
        type = varType or "int",
        default = default or 0,
        desc = desc or "",
    }
    dirty_ = true
    return true
end

function EditorData.RemoveVariable(name)
    if not data_.variables or not data_.variables[name] then return false end
    data_.variables[name] = nil
    dirty_ = true
    return true
end

function EditorData.UpdateVariable(name, field, value)
    if not data_.variables or not data_.variables[name] then return false end
    data_.variables[name][field] = value
    dirty_ = true
    return true
end

-- ============================================================================
-- 选中状态
-- ============================================================================

function EditorData.GetSelectedPassageId()
    return selectedPassageId_
end

function EditorData.SetSelectedPassageId(id)
    selectedPassageId_ = id
    selectedChoiceIndex_ = nil
end

function EditorData.GetSelectedChoiceIndex()
    return selectedChoiceIndex_
end

function EditorData.SetSelectedChoiceIndex(index)
    selectedChoiceIndex_ = index
end

-- ============================================================================
-- JSON 序列化
-- ============================================================================

function EditorData.Save(filename)
    filename = filename or "quest_data.json"
    local jsonStr = cjson.encode(data_)
    local file = File(filename, FILE_WRITE)
    if file then
        file:WriteString(jsonStr)
        file:Close()
        dirty_ = false
        print("[EditorData] 已保存: " .. filename)
        return true
    end
    print("[EditorData] 保存失败: " .. filename)
    return false
end

function EditorData.Load(filename)
    filename = filename or "quest_data.json"
    if not fileSystem:FileExists(filename) then
        print("[EditorData] 文件不存在: " .. filename)
        return false
    end
    local file = File(filename, FILE_READ)
    if not file then
        print("[EditorData] 打开失败: " .. filename)
        return false
    end
    local jsonStr = file:ReadString()
    file:Close()

    local ok, decoded = pcall(cjson.decode, jsonStr)
    if not ok then
        print("[EditorData] JSON 解析失败")
        return false
    end

    data_ = decoded
    if not data_.passages then data_.passages = {} end
    if not data_.variables then data_.variables = {} end
    if not data_.passageOrder then
        data_.passageOrder = {}
        for id, _ in pairs(data_.passages) do
            data_.passageOrder[#data_.passageOrder + 1] = id
        end
        table.sort(data_.passageOrder)
    end

    selectedPassageId_ = nil
    selectedChoiceIndex_ = nil
    dirty_ = false
    print("[EditorData] 已加载: " .. filename)
    return true
end

-- ============================================================================
-- 工具函数
-- ============================================================================

function EditorData.DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = EditorData.DeepCopy(v)
    end
    return copy
end

function EditorData.GetPassageCount()
    local count = 0
    for _ in pairs(data_.passages) do
        count = count + 1
    end
    return count
end

return EditorData
