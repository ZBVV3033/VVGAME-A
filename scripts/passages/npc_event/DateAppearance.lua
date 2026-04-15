-- passages/npc_event/DateAppearance.lua
-- Auto-split sub-module

return function(handlers, deps)

local GameState = deps.GameState
local TimeSystem = deps.TimeSystem
local WorkSystem = deps.WorkSystem
local CommonUtils = deps.CommonUtils
local PassageDeps = deps.PassageDeps
local addAffection = deps.addAffection
local addDateLog = deps.addDateLog
local addOamelAffection = deps.addOamelAffection
local addMeifeiAffection = deps.addMeifeiAffection
local addHistoryExp = deps.addHistoryExp
local dateScenes = deps.dateScenes
local banquetThemes = deps.banquetThemes
local readBook = deps.readBook
local handlers = deps.handlers

handlers["约会选择"] = function(S)
    return {
        text = "选择约会地点：",
        choices = {
            { text = "去港口看海", action = function() S.dateLocation = "港口" return "约会处理" end },
            { text = "去花园小镇", action = function() S.dateLocation = "花园" return "约会处理" end },
            { text = "去十字路口的咖啡店", action = function() S.dateLocation = "咖啡店" return "约会处理" end },
            { text = "随便走走", action = function() S.dateLocation = "漫步" return "约会处理" end },
        },
    }
end

---===================== 约会处理 =====================
--- Twine pid 28: 使用 dateScenes 数据


handlers["约会处理"] = function(S)
    if not S.dateTarget or not S.dateLocation then
        return { text = "", choices = {{ text = "返回", target = "十字路口" }} }
    end

    local targetScenes = dateScenes[S.dateTarget]
    local scene = targetScenes and targetScenes[S.dateLocation]
    if not scene then
        return { text = "约会场景未定义。", choices = {{ text = "返回", target = "十字路口" }} }
    end

    local name = S.dateTarget == "leiDe" and (S.initialName or "莱德") or "K"
    local desc = scene.desc(name)
    if S.dateTarget == "leiDe" and S.dateLocation == "在家" then
        desc = scene.desc(name, S.candles or 0)
    end

    local choices = {}
    for _, opt in ipairs(scene.options) do
        table.insert(choices, {
            text = opt.text,
            reply = opt.reply,
            affection = opt.affection,
            action = function()
                if S.dateTarget == "leiDe" then
                    addAffection("initialName", opt.affection)
                    S.lastDateLocation = S.dateLocation
                    addDateLog(S.initialName or "莱德", "约会", "和 " .. (S.initialName or "莱德") .. " 在 " .. S.dateLocation .. " 约会。")
                    S.leiDeDateAvailable = false
                else
                    addAffection("k", opt.affection)
                    addDateLog("K", "约会", "和K在 " .. S.dateLocation .. " 约会。")
                    S.kDateAvailable = false
                end
                return S.dateTarget == "leiDe" and "十字路口" or "商业区"
            end,
        })
    end

    return {
        text = desc,
        choices = choices,
        modal = true,
        modalTitle = "与" .. name .. "的约会",
    }
end

---===================== 属性 =====================
--- Twine pid 12
---===================== 自我审视 =====================


handlers["自我审视"] = function(S)
    local pName = (S.PNN ~= "" and S.PNN) or "诺兰"
    local from = S._settingsFrom or S.currentPassage or "家"

    -- ── 服装描述 ──
    local outfitDesc = ""
    local o = S.outfit or "casual"
    if string.find(o, "^uniform_") then
        local info = WorkSystem.getUniformInfo and WorkSystem.getUniformInfo(o)
        outfitDesc = info and info.desc or "一身工作服，袖口卷起，上面沾着些许灰尘。"
    elseif o == "work" then outfitDesc = "一身工作服，袖口卷起，上面沾着些许灰尘。"
    elseif o == "formal" then outfitDesc = "穿着一套整洁的正装，虽然不算新，但熨得笔挺。"
    elseif o == "pajamas" then outfitDesc = "穿着宽松的睡衣，看起来还没换。"
    else outfitDesc = "穿着朴素的便装——棉质衬衫搭配粗布长裤，不显眼但还算干净。" end

    -- ── 发型与瞳色 ──
    local hair = S.hairstyle or "及肩长发"
    local hairColor = S.hairColor or "淡黄色"
    local eyeColor = S.eyeColor or "赤色"
    local hairDesc = hairColor .. hair

    -- ── 身体状态 ──
    local bodyDesc = ""
    local fat = S.fatigue or 0
    local str = S.stress or 0
    local sat = S.satiety or 80
    local cln = S.cleanliness or 90
    if fat >= 80 then bodyDesc = "眼下挂着浓重的黑眼圈，脸色发灰，整个人萎靡不振。"
    elseif fat >= 60 then bodyDesc = "眼下有淡淡青黑，精神略显不济。"
    elseif str >= 80 then bodyDesc = "眉头紧锁，嘴角向下绷着，整个人像一根绷紧的弦。"
    elseif str >= 60 then bodyDesc = "神色焦虑，目光不安地游移。"
    elseif sat <= 15 then bodyDesc = "面色发白，嘴唇干裂，看起来好几顿没吃了。"
    elseif sat <= 30 then bodyDesc = "脸颊微微凹陷，肚子隐约在叫。"
    elseif cln <= 20 then bodyDesc = "浑身脏兮兮的，头发打结，衣服上有可疑的污渍。"
    elseif cln <= 40 then bodyDesc = "身上有些汗味，头发有点油。"
    elseif fat <= 10 and str <= 10 and sat >= 70 and cln >= 80 then bodyDesc = "精神饱满，面色红润，目光清亮。"
    elseif fat <= 30 then bodyDesc = "状态不错，面容平和。"
    else bodyDesc = "神情平淡，说不上好也说不上差。" end

    -- ── 魅力与容貌评价 ──
    local charm = S.ML or 3
    local charmDesc = ""
    if charm >= 10 then charmDesc = "五官精致，气质出众，走在路上会引来不少回头率。"
    elseif charm >= 7 then charmDesc = "长相清秀，略带几分文雅气质。"
    elseif charm >= 5 then charmDesc = "算是端正，不会让人多看，也不会让人移开目光。"
    elseif charm >= 3 then charmDesc = "相貌平平，不太引人注目。"
    else charmDesc = "样貌…嗯，有自己独特的风格。" end

    -- ── 他人看法 ──
    local rep = S.reputation or 0
    local evil = S.evilness or 0
    local othersView = ""
    if evil >= 30 then
        othersView = "镇上的人对你避之不及，背后窃窃私语。有些人看到你会本能地缩紧肩膀。"
    elseif evil >= 15 then
        othersView = "一些人对你心存警惕，你在某些人眼里不太值得信任。"
    elseif rep >= 50 then
        othersView = "你在镇上颇有名望，不少人见面会主动打招呼。商人会给你更好的价格，邻居会在你困难时伸出援手。"
    elseif rep >= 25 then
        othersView = "镇上有些人认识你了，偶尔有人会提起你的名字。你开始在这片土地上留下自己的印记。"
    elseif rep >= 10 then
        othersView = "你在附近已经不算完全的陌生人了。几个常去的店铺老板能叫出你的名字。"
    else
        othersView = "对大多数镇民来说，你只是又一个不知从哪来的陌生面孔。没人特别在意你。"
    end

    -- 构建文本
    local text = "自我审视\n\n"
    text = text .. "── 外貌 ──\n"
    text = text .. hairDesc .. "，" .. eyeColor .. "的瞳眸，" .. charmDesc .. "\n\n"
    text = text .. "── 着装 ──\n"
    text = text .. outfitDesc .. "\n\n"
    text = text .. "── 状态 ──\n"
    text = text .. bodyDesc .. "\n\n"
    text = text .. "── 他人的看法 ──\n"
    text = text .. othersView .. "\n"

    -- 声望/邪恶指标
    if rep > 0 or evil > 0 then
        text = text .. "\n"
        if rep > 0 then
            local repTitle = "无名之辈"
            if rep >= 50 then repTitle = "名声远扬"
            elseif rep >= 25 then repTitle = "小有名气"
            elseif rep >= 10 then repTitle = "略有耳闻"
            end
            text = text .. "⭐ 声望：" .. rep .. "（" .. repTitle .. "）\n"
        end
        if evil > 0 then
            local evilTitle = "清白"
            if evil >= 30 then evilTitle = "恶名昭彰"
            elseif evil >= 15 then evilTitle = "劣迹斑斑"
            elseif evil >= 5 then evilTitle = "有些污点"
            end
            text = text .. "💀 邪恶：" .. evil .. "（" .. evilTitle .. "）\n"
        end
    end

    -- ── 打工指引（非序章时显示） ──
    if not S.inPrologue then
        local hasAnyJob = S.unlockWaiter or S.unlockCleric or S.unlockBlacksmith or S.unlockLaborer
        if not hasAnyJob then
            text = text .. "\n── 生存指引 ──\n"
            text = text .. "💡 你需要赚钱维持生计。前往「十字路口」，探索酒馆、教堂、铁匠铺、港口等建筑，和那里的人交谈就能获得打工机会。\n"
        else
            -- 已解锁至少一项工作，显示简要提示
            local jobs = {}
            if S.unlockWaiter then table.insert(jobs, "酒馆服务员") end
            if S.unlockCleric then table.insert(jobs, "教堂杂务") end
            if S.unlockBlacksmith then table.insert(jobs, "铁匠帮工") end
            if S.unlockLaborer then table.insert(jobs, "码头搬运") end
            text = text .. "\n── 工作 ──\n"
            text = text .. "🔨 已解锁：" .. table.concat(jobs, "、") .. "\n"
            text = text .. "前往十字路口对应地点即可打工。\n"
        end
    end

    local choices = {}

    if S.inPrologue then
        -- 序章角色创建模式：可重新选择或确定
        table.insert(choices, { text = "🔄 重新选择外观", target = "命名" })
        table.insert(choices, { text = "✅ 确定，开始旅程", target = "序章" })
    else
        table.insert(choices, { text = "🔙 返回", target = from })
    end

    return { text = text, choices = choices }
end

---===================== 改变发型 =====================


handlers["改变发型"] = function(S)
    local curStyle = S.hairstyle or "及肩长发"
    local curColor = S.hairColor or "淡黄色"
    local curEye   = S.eyeColor  or "赤色"

    local text = "🪞 镜子前\n\n"
        .. "你站在镜子前打量着自己。\n"
        .. "当前外观：" .. curColor .. curStyle .. "，" .. curEye .. "瞳\n\n"
        .. "你想换个什么样的发型？"

    local hairstyles = { "短发", "长发", "及肩长发", "马尾", "寸头", "卷发", "编发", "披肩发" }

    local choices = {}

    -- 发型选择
    for _, style in ipairs(hairstyles) do
        if style ~= curStyle then
            table.insert(choices, {
                text = "换成" .. style,
                action = function()
                    S.hairstyle = style
                    TimeSystem.addMinutes(10)
                    GameState.showNotification("你对着镜子把头发梳成了" .. (S.hairColor or "淡黄色") .. style .. "的样子。看起来不错。")
                    return "改变发型"
                end,
            })
        end
    end

    -- 发色/瞳色子菜单
    table.insert(choices, { text = "── 换发色 ──", action = function() return "改变发色" end })
    table.insert(choices, { text = "── 换瞳色 ──", action = function() return "改变瞳色" end })

    table.insert(choices, { text = "🔙 回到卧室", target = "家_卧室" })

    return { text = text, choices = choices }
end


handlers["改变发色"] = function(S)
    local curColor = S.hairColor or "淡黄色"
    local curStyle = S.hairstyle or "及肩长发"

    local text = "🪞 镜子前\n\n"
        .. "当前发色：" .. curColor .. "\n"
        .. "你想换什么发色？\n"
        .. "（注意：染发需要去花园小镇的商店购买染料，目前先随便换换看吧）"

    local hairColors = { "黑色", "棕色", "金色", "淡黄色", "红色", "白色", "灰色", "蓝色" }
    local choices = {}

    for _, color in ipairs(hairColors) do
        if color ~= curColor then
            table.insert(choices, {
                text = color,
                action = function()
                    S.hairColor = color
                    TimeSystem.addMinutes(5)
                    GameState.showNotification("你想象着自己拥有" .. color .. "头发的样子……嗯，" .. color .. curStyle .. "，还不赖。")
                    return "改变发型"
                end,
            })
        end
    end

    table.insert(choices, { text = "🔙 返回", target = "改变发型" })

    return { text = text, choices = choices }
end


handlers["改变瞳色"] = function(S)
    local curEye = S.eyeColor or "赤色"

    local text = "🪞 镜子前\n\n"
        .. "当前瞳色：" .. curEye .. "\n"
        .. "你凝视着镜中的双眼……"

    local eyeColors = { "赤色", "蓝色", "金色", "翠绿", "紫色", "银色", "琥珀", "黑色" }
    local choices = {}

    for _, ec in ipairs(eyeColors) do
        if ec ~= curEye then
            table.insert(choices, {
                text = ec,
                action = function()
                    S.eyeColor = ec
                    TimeSystem.addMinutes(1)
                    GameState.showNotification("你的瞳孔泛起" .. ec .. "的光泽——这大概是某种魔法体质的表现。")
                    return "改变发型"
                end,
            })
        end
    end

    table.insert(choices, { text = "🔙 返回", target = "改变发型" })

    return { text = text, choices = choices }
end


end
