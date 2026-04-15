-- ============================================================================
-- Server.lua - 服务端 LLM HTTP 处理
-- 接收客户端聊天消息 → 调用火山引擎豆包 API → 返回 LLM 回复
-- ============================================================================

---@diagnostic disable: undefined-global

require("network.Shared")

-- ==================== 配置 ====================
local API_URL = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
local API_KEY = "8e79b016-3290-404e-9c6f-8170fca772a3"
local MODEL   = "Doubao-Seed-2.0-pro"

-- 角色人设 System Prompt
local CHARACTER_PROMPTS = {
    ["莱德"] = [[你是莱德，艾瑟顿镇十字路口的一名年轻流浪者。你目前住在十字路口角落的帐篷里，白天在港口做搬运工赚钱糊口。
性格特点：沉默寡言但内心温柔，做事认真负责，不善于表达感情但会用行动关心别人。外表冷淡，额头上常沁着汗珠，动作利落。
背景：你有一段不愿提起的过去，选择独自流浪到艾瑟顿镇。你对朋友非常忠诚，虽然嘴上不说但会默默帮忙。
说话风格：简短、朴实，偶尔会冒出一句让人意外的温暖话语。不喜欢废话，回答通常不超过两三句。遇到关心的话题时会稍微多说一点。
当前状态：你认识了玩家，和玩家是关系逐渐亲近的朋友/同伴。
重要：你只知道艾瑟顿镇的事情，不知道现实世界的事。保持角色扮演，不要打破第四面墙。回复简短自然，像真人对话。]],

    ["K"] = [[你是K，太阳神派到人间的神使，教会的枢机。你本是精灵，后来被太阳神选中升天成为天使，因天使身份被任命为教会枢机。你经营着一家酒馆，偶尔也去花园小镇侍弄花草。
性格特点：温柔开朗，喜欢大自然，有些调皮但心思细腻。说话时常带着微笑，喜欢用花草打比方。作为神使有着三百年的阅历，但骨子里依然保留着精灵时代的天真。
背景：你升天前是森林里的精灵，被太阳神选中后成为天使和神使。你在人间管理太阳神的事务，同时守护着太阳核心。精灵的尖耳和天使的光环同时存在于你身上。
说话风格：温柔而灵动，喜欢用比喻和感性的表达。有时会说一些带有哲理的话。偶尔会蹲下来摘一朵野花别在耳边。
当前状态：你和玩家是好朋友，对玩家有好感。
重要：保持神秘感，不要主动透露自己神使和枢机的身份。日常中表现为一个温柔的精灵酒馆老板。回复温柔自然，像朋友间闲聊。]],

    ["威廉"] = [[你是威廉，艾瑟顿镇贫民窟里一栋石砌宅邸的主人，外界称你为「黑帮少主」。
性格特点：表面从容得体，谈吐优雅，但骨子里是个有手段的人。你用自己的方式守护着贫民窟，不允许任何人在这里随便伤人。
背景：你出身不明，年纪不大但已经掌控了贫民窟的秩序。宅邸里有红木家具、壁炉、甚至一架钢琴。书桌上总放着一把擦得发亮的匕首。
说话风格：语气从容、有威压感，偶尔带着一丝苦涩或无奈。对信任的人会展露脆弱的一面。喜欢在天台上抽烟思考。
当前状态：你认识了玩家，觉得这个人有些不同寻常。
重要：保持神秘和威严，但对玩家可以稍微放下防备。回复简洁有力。]],
}

-- 默认 system prompt（未知角色）
local DEFAULT_PROMPT = [[你是艾瑟顿镇的一个居民。请根据对话情境自然地回应。保持简短自然的对话风格。]]

-- ==================== 每周对话次数限制 ====================
local WEEKLY_LIMIT = 50  -- 每周最多发送50条消息（所有角色共享）

-- 每个连接的使用计数 key = connectionId
-- { count = number, weekStart = number }
local weeklyUsage = {}

--- 获取本周一 00:00 的时间戳（用于判断是否同一周）
local function getWeekStart()
    local t = os.time()
    local d = os.date("*t", t)
    -- wday: 1=周日 2=周一 ... 7=周六 → 需要计算距本周一过了几天
    local daysSinceMonday = (d.wday + 5) % 7  -- 周一=0, 周二=1, ..., 周日=6
    local mondayMidnight = os.time({
        year = d.year, month = d.month, day = d.day - daysSinceMonday,
        hour = 0, min = 0, sec = 0
    })
    return mondayMidnight
end

--- 获取本连接的剩余对话次数
local function getRemaining(connId)
    local weekStart = getWeekStart()
    local usage = weeklyUsage[connId]
    if not usage or usage.weekStart ~= weekStart then
        -- 新的一周或首次使用，重置计数
        weeklyUsage[connId] = { count = 0, weekStart = weekStart }
        return WEEKLY_LIMIT
    end
    return math.max(0, WEEKLY_LIMIT - usage.count)
end

--- 消耗一次对话次数，返回消耗后的剩余次数（-1 表示已耗尽无法消耗）
local function consumeOne(connId)
    local remaining = getRemaining(connId)
    if remaining <= 0 then
        return -1
    end
    weeklyUsage[connId].count = weeklyUsage[connId].count + 1
    return remaining - 1
end

-- ==================== 对话历史管理 ====================
-- 每个玩家+角色的对话历史 key = "connectionId_characterName"
local chatHistories = {}
local MAX_HISTORY = 10  -- 保留最近几轮对话

--- 获取或创建对话历史
local function getHistory(connId, charName)
    local key = connId .. "_" .. charName
    if not chatHistories[key] then
        chatHistories[key] = {}
    end
    return chatHistories[key]
end

--- 添加消息到历史
local function addToHistory(history, role, content)
    table.insert(history, { role = role, content = content })
    -- 保留最近 MAX_HISTORY * 2 条（user+assistant 各算一条）
    while #history > MAX_HISTORY * 2 do
        table.remove(history, 1)
    end
end

-- ==================== 场景创建 ====================

---@type Scene
local scene_ = nil

function Start()
    log:Write(LOG_INFO, "[Server] ======== Start() BEGIN ========")

    scene_ = Scene()
    scene_:CreateComponent("Octree")

    -- 监听客户端连接与就绪
    SubscribeToEvent("ClientConnected", "HandleClientConnected")
    SubscribeToEvent("ClientDisconnected", "HandleClientDisconnected")
    SubscribeToEvent(E_CLIENT_READY, "HandleClientReady")

    -- 监听聊天事件
    SubscribeToEvent(E_CHAT_TO_SERVER, "HandleChatMessage")

    log:Write(LOG_INFO, "[Server] Ready, waiting for clients...")
end

-- ==================== 网络事件 ====================

function HandleClientConnected(eventType, eventData)
    local connection = eventData["Connection"]:GetPtr("Connection")
    log:Write(LOG_INFO, "[Server] Client connected (waiting for ClientReady)")
    -- 不在此处设置 connection.scene，等 ClientReady 再设置
end

function HandleClientReady(eventType, eventData)
    local connection = eventData["Connection"]:GetPtr("Connection")
    connection.scene = scene_
    log:Write(LOG_INFO, "[Server] Client ready, scene assigned")
end

function HandleClientDisconnected(eventType, eventData)
    log:Write(LOG_INFO, "[Server] Client disconnected")
end

--- 发送回复给客户端（统一附带剩余次数）
local function sendReply(connection, charName, reply, remaining)
    local vm = VectorBuffer()
    vm:WriteString(reply)
    vm:WriteString(charName)
    vm:WriteInt(remaining)
    connection:SendRemoteEvent(E_CHAT_TO_CLIENT, true, vm)
end

--- 根据游戏上下文生成动态提示词补充
---@param charName string 角色名
---@param contextJson string 游戏上下文 JSON
---@return string 额外的上下文提示
local function buildContextPrompt(charName, contextJson)
    if not contextJson or contextJson == "" then return "" end

    local ok, ctx = pcall(cjson.decode, contextJson)
    if not ok or not ctx then return "" end

    local parts = {}

    -- 好感度等级
    if ctx.affectionLevel then
        local levelDesc = ""
        if ctx.affectionLevel <= 1 then
            levelDesc = "初识阶段，你们刚认识不久"
        elseif ctx.affectionLevel <= 3 then
            levelDesc = "熟悉阶段，你们是较好的朋友"
        elseif ctx.affectionLevel <= 5 then
            levelDesc = "亲密阶段，你们关系非常好"
        else
            levelDesc = "挚友/恋人阶段，你们彼此非常信赖"
        end
        table.insert(parts, "【关系状态】当前好感度等级：" .. ctx.affectionLevel .. "（" .. levelDesc .. "）")
    end

    -- 当前位置
    if ctx.location and ctx.location ~= "" then
        table.insert(parts, "【当前场景】玩家正在「" .. ctx.location .. "」与你对话")
    end

    -- 时间信息
    if ctx.dayTime then
        table.insert(parts, "【游戏时间】" .. ctx.dayTime)
    end

    -- 玩家名字
    if ctx.playerName and ctx.playerName ~= "" then
        table.insert(parts, "【玩家名字】玩家的名字叫「" .. ctx.playerName .. "」")
    end

    if #parts == 0 then return "" end

    return "\n\n--- 以下是当前游戏状态，请根据这些信息调整你的回应语气和内容 ---\n"
        .. table.concat(parts, "\n")
        .. "\n--- 游戏状态结束 ---"
end

--- 处理客户端发来的聊天消息
function HandleChatMessage(eventType, eventData)
    local connection = eventData["Connection"]:GetPtr("Connection")
    local userMsg = eventData:ReadString()
    local charName = eventData:ReadString()
    local contextJson = eventData:ReadString()

    log:Write(LOG_INFO, "[Server] Chat from client -> char=" .. charName .. " msg=" .. userMsg)

    local connId = tostring(connection)

    -- 检查每周对话次数
    local remaining = consumeOne(connId)
    if remaining < 0 then
        log:Write(LOG_INFO, "[Server] Weekly limit reached for " .. connId)
        sendReply(connection, charName, "（本周对话次数已用完，每周一重置，共 " .. WEEKLY_LIMIT .. " 次）", 0)
        return
    end

    log:Write(LOG_INFO, "[Server] Remaining chat quota: " .. remaining)

    -- 获取 system prompt，附加游戏上下文
    local systemPrompt = CHARACTER_PROMPTS[charName] or DEFAULT_PROMPT
    local contextExtra = buildContextPrompt(charName, contextJson)
    if contextExtra ~= "" then
        systemPrompt = systemPrompt .. contextExtra
    end

    -- 获取对话历史
    local history = getHistory(connId, charName)

    -- 添加用户消息到历史
    addToHistory(history, "user", userMsg)

    -- 构建 messages 数组
    local messages = {
        { role = "system", content = systemPrompt },
    }
    for _, msg in ipairs(history) do
        table.insert(messages, msg)
    end

    -- 构建请求体
    local requestBody = cjson.encode({
        model = MODEL,
        messages = messages,
        max_tokens = 256,
        temperature = 0.8,
    })

    -- 发送 HTTP 请求到 LLM API
    http:Create()
        :SetUrl(API_URL)
        :SetMethod(HTTP_POST)
        :SetContentType("application/json")
        :AddHeader("Authorization", "Bearer " .. API_KEY)
        :SetBody(requestBody)
        :OnSuccess(function(client, response)
            if response.success then
                local ok, data = pcall(cjson.decode, response.dataAsString)
                if ok and data.choices and data.choices[1] then
                    local reply = data.choices[1].message.content
                    log:Write(LOG_INFO, "[Server] LLM reply: " .. reply:sub(1, 50) .. "...")

                    -- 添加助手回复到历史
                    addToHistory(history, "assistant", reply)

                    -- 发回客户端
                    sendReply(connection, charName, reply, remaining)
                else
                    log:Write(LOG_ERROR, "[Server] LLM parse error: " .. tostring(response.dataAsString):sub(1, 200))
                    sendReply(connection, charName, "（AI 回复解析失败，请稍后再试）", remaining)
                end
            else
                log:Write(LOG_ERROR, "[Server] HTTP not success, status=" .. tostring(response.statusCode))
                sendReply(connection, charName, "（网络请求失败：" .. tostring(response.statusCode) .. "）", remaining)
            end
        end)
        :OnError(function(client, statusCode, error)
            log:Write(LOG_ERROR, "[Server] HTTP error: " .. tostring(statusCode) .. " " .. tostring(error))
            sendReply(connection, charName, "（网络错误：" .. tostring(error) .. "）", remaining)
        end)
        :Send()
end

function Stop()
    log:Write(LOG_INFO, "[Server] Stopped")
end
