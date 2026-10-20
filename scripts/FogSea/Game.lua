-- 《雾海号》状态与规则；与显示层分离，便于验证分支和存档。
local Story = require("FogSea.Story")
local Game = {}

Game.chapters = { "序章 · 客舱", "第一章 · 甲板", "第二章 · 宴会厅", "第三章 · 驾驶台", "终章 · 出口" }
Game.personas = { "信者之我", "叛者之我", "观者之我" }
Game.evidence = {
    { "letter", "无寄件人的信", "客舱 · 枕边", "四个字：快想起来。字迹是我自己的。", "image/item_letter.png" },
    { "manuscript", "不会靠岸的航程", "客舱 · 手稿", "「雾海号永远不会靠岸。」我不记得写过。", "image/item_diary.png" },
    { "photo", "合照里多了一个人", "客舱 · 照片墙", "我、妈妈，还有……第三个人的脸，是糊的。", "image/item_old_photo.png" },
    { "ward", "糖罐上的第 7 疗养院", "病房 · 床头柜", "和客舱那罐一模一样。罐底刻着名字。", "image/item_sugar_jar.png" },
    { "sos", "求救信", "甲板 · 漂来的信", "「救救我。我们靠不了岸。」", "image/item_letter.png" },
    { "route", "循环的证据", "甲板 · 信件解法", "合照碎片 / 入院单据 / 航迹坐标。因回应而定。", "image/item_ticket.png" },
    { "waiter", "重复的台词", "走廊 · 服务员影", "「该吃药了。」同一句话，三遍。", "image/item_prescription.png" },
    { "corridor", "帽檐内侧的绣字", "走廊 · 衣架", "船长帽绣着：第 7 疗养院。", "image/item_captain_hat.png" },
    { "medicine", "药瓶当成餐牌", "宴会厅 · 餐车", "标签编号：2317。", "image/item_medicine.png" },
    { "prescription", "宴会的真相", "宴会厅 · 药瓶解法", "便签 / 针头 / 发药单。因解法而定。", "image/item_prescription.png" },
    { "cup", "杯底的药名", "治疗区 · 药台", "香槟杯底刻着：氯氮平。", "image/item_champagne.png" },
    { "ticket2317", "六位数的门", "驾驶台 · 密码锁", "2317。药瓶标签上的编号。", "image/item_medicine.png" },
    { "record", "我是病人", "驾驶台 · 航海日志", "患者程默。入院一年。主诉：妄想、解离。", "image/item_diary.png" },
    { "ticket", "出发港", "档案室 · 抽屉", "乘客：程默。出发港：第 7 疗养院。", "image/item_ticket.png" },
    { "diary", "日记里的钥匙", "驾驶台 · 船长室", "夹层里，是救生艇钥匙。", "image/item_diary.png" },
}

---@class FogSeaState
---@field version integer
---@field chapter integer
---@field world string
---@field lucidity number
---@field axes number[]
---@field persona integer
---@field flags table<string, boolean>
---@field clues table<string, boolean>
---@field writing integer[]
---@field items table<string, string>
---@field maxChapter integer
---@field asylumTime number
---@field elapsed number
---@field restAt number
---@field rests integer
---@field watches integer
---@field errors integer
---@field ending string

---@return FogSeaState
function Game.New()
    return {
        version = 1, chapter = 1, world = "cruise", lucidity = 100,
        axes = { 0, 0, 0 }, persona = 0, flags = {}, clues = {},
        writing = {}, items = {}, maxChapter = 1, asylumTime = 0,
        elapsed = 0, restAt = -300, rests = 0, watches = 2,
        errors = 0, ending = "",
    }
end

function Game.Validate(s)
    if type(s) ~= "table" or s.version ~= 1 then return false end
    if type(s.chapter) ~= "number" or s.chapter % 1 ~= 0 or s.chapter < 1 or s.chapter > 5 then return false end
    if s.world ~= "cruise" and s.world ~= "asylum" then return false end
    for _, k in ipairs({ "flags", "clues", "items", "axes", "writing" }) do
        if type(s[k]) ~= "table" then return false end
    end
    for i = 1, 3 do if type(s.axes[i]) ~= "number" or s.axes[i] < 0 or s.axes[i] > 100 then return false end end
    for _, k in ipairs({ "lucidity", "persona", "elapsed", "restAt", "rests", "watches", "errors", "asylumTime", "maxChapter" }) do
        if type(s[k]) ~= "number" then return false end
    end
    return s.lucidity > 0 and s.lucidity <= 100 and s.persona >= 0 and s.persona <= 3
        and s.persona % 1 == 0 and s.maxChapter >= s.chapter and s.maxChapter <= 5
        and s.ending == "" and (s.chapter < 4 or s.persona > 0)
end

function Game.Count(s)
    local count = 0
    for _, clue in ipairs(Game.evidence) do if s.clues[clue[1]] then count = count + 1 end end
    return count
end

function Game.AddClue(s, id)
    if s.clues[id] then return end
    s.clues[id] = true
    print("[雾海号] 新线索：" .. id .. "，证据 " .. Game.Count(s) .. "/15")
end

function Game.AddAxis(s, axis, amount)
    s.axes[axis] = s.axes[axis] + amount
    print("[雾海号] 倾向：" .. table.concat(s.axes, "/"))
end

function Game.Cost(s, amount)
    s.lucidity = math.max(0, math.min(100, s.lucidity - amount))
    if s.lucidity <= 0 then s.ending = "4-3-007" end
end

function Game.Switch(s, world)
    s.world = world
    Game.Cost(s, 8)
    print("[雾海号] 世界翻面：" .. world .. "，清醒度=" .. s.lucidity)
end

function Game.LockPersona(s)
    if s.persona ~= 0 then return end
    local maximum = math.max(table.unpack(s.axes))
    local winners, axis = 0, 3
    for i = 1, 3 do
        if s.axes[i] == maximum then winners = winners + 1; axis = i end
    end
    s.persona = winners == 1 and axis or 3
    print("[雾海号] 人格涌现：" .. Game.personas[s.persona])
end

local function Line(id)
    local node = Story.nodes[id]
    return node and node.text or "……"
end
Game.Line = Line

local function Say(text, speaker, image)
    return { kind = "dialogue", text = text, speaker = speaker or "程默", image = image or "" }
end
local function Choices(text, choices, action, speaker)
    return { kind = "choice", text = text, choices = choices, action = action, speaker = speaker or "程默" }
end
local function Change(text)
    return { kind = "transition", text = text, speaker = "程默" }
end

function Game.Objective(s)
    local f, c = s.flags, s.chapter
    if s.world == "asylum" then
        if not f["shadow" .. c] then return c == 4 and "读完航海日志，与镜中的自己交谈" or "调查梦影，回应那张熟悉的面孔" end
        return ({ "调查糖罐，寻找返回邮轮的锚点", "调查衣架上的船长帽", "触碰药台上的香槟杯", "调查抽屉中的船票" })[c] or "寻找出口"
    end
    if c == 1 then
        if not f.key then return "调查抽屉与花盆，找回客舱钥匙" end
        if not f.return1 then return "触碰合照上不对劲的地方" end
        if not f.write1 then return "回到书桌，续写第一章" end
        return "用钥匙打开客舱门，前往甲板"
    elseif c == 2 then
        if not f.rope then return "从桶中找钥匙，打开工具柜，剪断缆绳" end
        if not f.puzzle2 then return "读一读漂上甲板的求救信" end
        if not f.return2 then return "触碰航线图的微光，调查走廊" end
        if not f.write2 then return "在手稿上续写第二章" end
        return "进入宴会厅"
    elseif c == 3 then
        if not f.tower then return "拿走长桌桌布，清理堵门的香槟塔" end
        if not f.puzzle3 then return "调查餐车上伪装成餐牌的药瓶" end
        if not f.return3 then return "触碰餐车微光，调查治疗区" end
        if not f.write3 then return "续写第三章，再调查驾驶台门锁" end
        return "输入药瓶标签上的四位密码，进入驾驶台"
    elseif c == 4 then
        if not f.return4 then return "罗盘从不转动。触碰它，寻找航海日志" end
        if not f.boatkey then return "翻阅船长日记，从夹层取出救生艇钥匙" end
        return "前往船尾出口，决定是否靠岸"
    end
    if Game.Count(s) < 11 then return "证据不足：返回驾驶台，通过航程回访补齐线索" end
    return "钥匙已经在手里。还缺的，是你的意愿"
end

function Game.Scene(s)
    local names = s.world == "cruise" and { "客舱", "甲板", "宴会厅", "驾驶台", "船尾出口" }
        or { "病房", "病房走廊", "治疗区", "档案室", "病房出口" }
    local paths = s.world == "cruise" and { "image/scene_ward.png", "image/scene_deck.png", "image/scene_banquet.png", "image/scene_bridge.png", "image/scene_exit_cruise.png" }
        or { "image/scene_ward.png", "image/scene_corridor.png", "image/scene_treatment.png", "image/scene_archive.png", "image/scene_exit_asylum.png" }
    return names[s.chapter], paths[s.chapter]
end

-- 热区为原图归一化矩形：显示层使用同一组变换完成绘制和命中。
--       x,y ┌──── w ────┐  点击落在框内 → 调查；拖动超过阈值 → 平移，不调查。
--           │    ●     │ h  边界包含；重叠热区按较小区域优先；UI浮层阻止场景点击。
--           └──────────┘  道具最小点击尺寸在显示层扩充到40逻辑像素。
function Game.Spots(s)
    local function Spot(id, name, x, y, w, h, anchor, item)
        return { id = id, name = name, x = x, y = y, w = w, h = h, anchor = anchor or false, item = item or "" }
    end
    local c, f = s.chapter, s.flags
    if s.world == "asylum" then
        if c == 1 then return {
            Spot("shadow", "船长影", .57, .31, .13, .37), Spot("sugar", "床头柜 · 糖罐", .34, .53, .12, .14, true, "image/item_sugar_jar.png"),
            Spot("wall", "病历墙", .2, .3, .12, .17),
        } elseif c == 2 then return {
            Spot("shadow", "查房的人", .5, .28, .13, .4), Spot("hat", "衣架 · 船长帽", .81, .38, .12, .13, true, "image/item_captain_hat.png"),
            Spot("wall", "医嘱板", .18, .3, .16, .2),
        } elseif c == 3 then return {
            Spot("shadow", "船客影与护士", .42, .38, .22, .42), Spot("cup", "药柜 · 香槟杯", .78, .5, .14, .16, true, "image/item_champagne.png"),
            Spot("wall", "治疗记录", .08, .34, .14, .3),
        } else return {
            Spot("log", "档案柜 · 航海日志", .76, .42, .18, .3, false, "image/item_diary.png"),
            Spot("shadow", "玻璃中的自己", .08, .3, .16, .32), Spot("ticket", "控制台抽屉 · 船票", .28, .58, .14, .14, true, "image/item_ticket.png"),
        } end
    end
    if c == 1 then return {
        Spot("photo", "墙上的合照", .07, .30, .10, .16, true, "image/item_old_photo.png"),
        Spot("letter", "枕边的半封信", .28, .58, .12, .12, false, "image/item_letter.png"),
        Spot("desk", "书桌 · 手稿", .78, .46, .16, .22, false, "image/item_diary.png"),
        Spot("drawer", "书桌抽屉", .78, .68, .16, .14),
        Spot("pot", "窗台花盆", .46, .52, .12, .16, false, "image/item_flower_pot.png"),
        Spot("door", "客舱门", .0, .42, .06, .4),
    } elseif c == 2 then return {
        Spot("bucket", "缆绳卷 · 桶底", .05, .7, .18, .25),
        Spot("cabinet", "船员室 · 桥舱门", .14, .3, .13, .3),
        Spot("rope", "缆绳与门把", .52, .42, .1, .28, false, f.shears and "image/item_shears.png" or ""),
        Spot("sos", "漂来的求救信", .42, .82, .1, .12, false, "image/item_letter.png"),
        Spot("route", "栏杆与救生圈", .55, .35, .2, .32, true),
        Spot("desk", "随身手稿", .68, .74, .12, .14, false, "image/item_diary.png"),
        Spot("door", "宴会厅入口", .2, .4, .07, .18),
    } elseif c == 3 then return {
        Spot("cloth", "长桌桌布", .29, .49, .25, .23),
        Spot("tower", "堵门的香槟塔", .76, .39, .17, .34),
        Spot("medicine", "餐车 · 药瓶", .62, .57, .11, .15, f.puzzle3, "image/item_medicine.png"),
        Spot("waiter", "服务员", .63, .29, .1, .25),
        Spot("desk", "随身手稿", .17, .76, .12, .12, false, "image/item_diary.png"),
        Spot("door", "驾驶台密码锁", .86, .21, .1, .14),
    } elseif c == 4 then return {
        Spot("compass", "永远同向的罗盘", .47, .54, .13, .15, true),
        Spot("chart", "海图桌", .68, .62, .16, .18),
        Spot("diary", "船长室 · 日记", .19, .68, .13, .14, false, "image/item_diary.png"),
        Spot("door", "船尾出口", .86, .31, .11, .38),
    } end
    return { Spot("final", "出口门 · 靠岸", .44, .25, .15, .44, true), Spot("back", "返回驾驶台", .1, .63, .13, .18) }
end

function Game.Interact(s, id)
    local f, c = s.flags, s.chapter
    print("[雾海号] 调查 " .. c .. "/" .. s.world .. "/" .. id)
    if s.ending ~= "" then return { kind = "ending" } end
    if id == "shadow" then
        if c == 4 and not f.log then return Say("镜中人把手指抵在嘴边。先看看档案柜里的日志。", "自己的镜像") end
        if f["shadow" .. c] then return Say("我们已经说过了。找到那件带微光的信物，才能回到海上。", c == 4 and "自己的镜像" or "梦影") end
        local roots = { "0-4-002", "1-3-001", "2-3-001", "3-4-001" }
        local ids = { { "0-4-003", "0-4-005", "0-4-007" }, { "1-3-003", "1-3-004", "1-3-005" }, { "2-3-003", "2-3-004", "2-3-005" }, { "3-4-003", "3-4-005", "3-4-007" } }
        local opts = {}
        for _, key in ipairs(ids[c]) do opts[#opts + 1] = Story.nodes[key].option end
        return Choices(Line(roots[c]), opts, "shadow", c == 4 and "自己的镜像" or (c == 3 and "船客影" or "船长影"))
    end
    if s.world == "asylum" then
        local ret = { sugar = 1, hat = 2, cup = 3, ticket = 4 }
        if ret[id] then
            if not f["shadow" .. c] then return Say("那件信物尚未回应我。先听完梦影想说的话。") end
            local clue = ({ "ward", "corridor", "cup", "ticket" })[c]
            Game.AddClue(s, clue); f["return" .. c] = true
            Game.Switch(s, "cruise")
            return Change(Line(({ "0-5-001", "1-4-001", "2-4-001", "3-5-001" })[c]))
        elseif id == "log" then
            if f.log then return Say(Line(({ "3-3-001", "3-3-002", "3-3-003" })[s.persona])) end
            if s.persona == 2 then return { kind = "challenge", mode = "break", text = "砸碎罗盘与日志柜。连续确认三次。" }
            elseif s.persona == 3 then return { kind = "challenge", mode = "observe", text = "不触碰任何东西，凝视倒影三秒。" } end
            return Choices("钥匙插进档案柜。你准备好看见自己的名字了吗？", { "打开档案柜，读完日志" }, "log")
        elseif id == "wall" then return Say("墙上的记录停在六点。汽笛，原来是查房铃。") end
    elseif c == 1 then
        if id == "letter" then
            Game.AddClue(s, "letter"); f.letter = true
            if not f.order1 then Game.AddAxis(s, 1, 1); f.order1 = true end
            return Say(Line("0-2-002"), nil, "image/item_letter.png")
        elseif id == "drawer" then
            f.drawer = true
            if not f.order2 then Game.AddAxis(s, 2, 1); f.order2 = true end
            return Say(Line("0-3-003"), nil, "image/item_old_photo.png")
        elseif id == "pot" then
            if not f.drawer then return Say("花盆很沉。我为什么要挪动它？也许抽屉里的东西能让我想起来。") end
            f.key = true; s.items.key = "cruise"; return Say(Line("0-3-004"), nil, "image/item_cabin_key.png")
        elseif id == "photo" then
            Game.AddClue(s, "photo")
            if not f.order1 then Game.AddAxis(s, 3, 1); f.order1 = true end
            if f.return1 then return Say(Line("0-2-004"), nil, "image/item_old_photo.png") end
            Game.Switch(s, "asylum"); return Change(Line("0-2-004"))
        elseif id == "desk" then
            Game.AddClue(s, "manuscript")
            if not f.order2 then Game.AddAxis(s, 3, 1); f.order2 = true end
            if not f.return1 then return Say(Line("0-2-003")) end
            if f.write1 then return Say("第一章已经写下。接下来，去看看那片海。") end
            return { kind = "writing", chapter = 1 }
        elseif id == "door" then
            if not f.key then return Say(Line("0-3-001")) end
            if not f.write1 then return Say("门锁开了。可那张合照、还有没写完的稿纸，仍让我无法离开。") end
            f.door1 = true; s.chapter = 2; s.maxChapter = math.max(2, s.maxChapter)
            return Change(Line("0-3-005"))
        end
    elseif c == 2 then
        if id == "bucket" then f.toolkey = true; s.items.toolkey = "cruise"; return Say(Line("1-1-003"), nil, "image/item_cabin_key.png")
        elseif id == "cabinet" then
            if not f.toolkey then return Say(Line("1-1-002")) end
            f.shears = true; s.items.shears = "cruise"; return Say("旧锁开了。我取出剪钳，齿口还沾着海盐。", nil, "image/item_shears.png")
        elseif id == "rope" then
            if not f.shears then return Say(Line("1-1-001")) end
            f.rope = true; return Say("缆绳断了。风没有来，走廊深处却响起了查房铃。")
        elseif id == "sos" then
            if not f.rope then return Say("信在缆绳门后。先想办法打开门。") end
            Game.AddClue(s, "sos")
            if f.puzzle2 then return Say("纸上的求救已经有了回应。航线图还在泛光。") end
            return Choices(Line("1-2-001"), { Story.nodes["1-2-002"].option, Story.nodes["1-2-004"].option, Story.nodes["1-2-006"].option }, "letter")
        elseif id == "route" then
            if not f.puzzle2 then return Say("海图上的航线回到了原点。我得先读一读那封信。") end
            if f.return2 then return Say("航迹连成了一个圈。没有终点。") end
            Game.Switch(s, "asylum"); return Change("海图上泛起微光。甲板的栏杆，变成了病房的护栏。")
        elseif id == "desk" then
            if not f.return2 then return Say("这一章还没有结尾。先从走廊找回那件信物。") end
            if f.write2 then return Say("第二章的墨已经干了。") end
            return { kind = "writing", chapter = 2 }
        elseif id == "door" then
            if not f.write2 then return Say("还不能离开。" .. Game.Objective(s)) end
            s.chapter = 3; s.maxChapter = math.max(3, s.maxChapter); return Change("宴会厅的门开了。所有人，正好同时举杯。")
        end
    elseif c == 3 then
        if id == "cloth" then f.cloth = true; s.items.cloth = "cruise"; return Say("我攥住了桌布的一角。先铺好它，再挪走堵门的杯塔。", nil, "image/item_tablecloth.png")
        elseif id == "tower" then
            if not f.cloth then return Say(Line("2-1-001")) end
            f.tower = true; return Say("桌布抽走了，杯塔倒在布上。没有酒味。只有消毒水的味道。")
        elseif id == "waiter" then return Say("开席了。开席了。开席了。", "服务员")
        elseif id == "medicine" then
            if not f.tower then return Say("餐车被杯塔挡住了。先想办法清出一条路。") end
            Game.AddClue(s, "medicine"); s.items.medicine = "cruise"
            if f.puzzle3 and not f.return3 then Game.Switch(s, "asylum"); return Change("餐牌上的菜名消失了。发药时间：六点整。") end
            if f.return3 then return Say("2317。药瓶标签上的编号。", nil, "image/item_medicine.png") end
            return Choices(Line("2-2-001") .. "\n标签编号：2317。", { Story.nodes["2-2-002"].option, Story.nodes["2-2-004"].option, Story.nodes["2-2-006"].option }, "medicine")
        elseif id == "desk" then
            if not f.return3 then return Say("先听完宴会背面的声音，再写这一章。") end
            if f.write3 then return Say("第三章已落笔。药瓶上的数字还印在脑海里。") end
            return { kind = "writing", chapter = 3 }
        elseif id == "door" then
            if not f.write3 then return Say("还不能离开。" .. Game.Objective(s)) end
            return { kind = "password", text = Line("3-1-001") }
        end
    elseif c == 4 then
        if id == "compass" then
            if f.return4 then return Say("罗盘终于停下了——不，它一直没动过。") end
            Game.Switch(s, "asylum"); return Change("罗盘的玻璃里映出一个档案柜。舵轮消失了。")
        elseif id == "chart" then return Say("海图上没有港口。只有一个被擦了又写的名字：程默。")
        elseif id == "diary" then
            if not f.return4 then return Say("抽屉锁着。先从航海日志里，找回失去的那一年。") end
            if not f.boatkey then return Choices(Line("4-1-002"), { s.persona == 2 and "砸开抽屉，取出钥匙" or "读完日记，从夹层取出钥匙" }, "diary") end
            return Say("钥匙在口袋里。现在，去出口。", nil, "image/item_cabin_key.png")
        elseif id == "door" then
            if not f.boatkey then return Say("出口需要救生艇钥匙。" .. Game.Objective(s)) end
            s.chapter = 5; s.maxChapter = 5; return Change("雾散了。门那边，第一次有了岸的轮廓。")
        end
    elseif c == 5 then
        if id == "back" then s.chapter = 4; return Change("我还想再确认一次。") end
        if id == "final" then
            if not f.boatkey or Game.Count(s) < 11 then return Say("门没有回应。需要救生艇钥匙，以及至少 11 / 15 条证据。可以从航程回访补齐遗漏。") end
            return Choices(Line("4-2-001"), { "靠岸 · 亲手推开门", "留下 · 转身回到海上" }, "final")
        end
    end
    return Say("没有更多发现。")
end

function Game.Choose(s, action, index)
    local f, c = s.flags, s.chapter
    if action == "shadow" then
        if f["shadow" .. c] then return Say("这段回应已经说过了。") end
        f["shadow" .. c] = true; Game.AddAxis(s, index, 2)
        if c == 2 then Game.AddClue(s, "waiter") end
        local responses = { { "0-4-004", "0-4-006", "0-4-008" }, {}, {}, { "3-4-004", "3-4-006", "3-4-008" } }
        local response = responses[c][index]
        return Say(response and Line(response) or (index == 1 and "那个人沉默了。我们都想起了一点，又都没有说破。" or "查房的人收起夹子。铃声停了。"), c == 4 and "自己的镜像" or "梦影")
    elseif action == "letter" then
        if f.puzzle2 then return Say("信件已经有了回答。") end
        f.puzzle2 = true; Game.AddAxis(s, index, 2); Game.AddClue(s, "route")
        return Say(Line(({ "1-2-003", "1-2-005", "1-2-007" })[index]))
    elseif action == "medicine" then
        if f.puzzle3 then return Say("药瓶已经处理好了。") end
        f.puzzle3 = true; Game.AddAxis(s, index, 2); Game.AddClue(s, "prescription")
        return Say(Line(({ "2-2-003", "2-2-005", "2-2-007" })[index]) .. "\n餐车边缘泛起微光。再触碰一次，看看宴会的背面。")
    elseif action == "writing" then
        if f["write" .. c] then return Say("这一章已经写下了。") end
        f["write" .. c] = true; s.writing[c] = index; Game.AddAxis(s, index, 2)
        return Say("墨迹慢慢渗开。\n\n“" .. Story.writing[c][index] .. "”\n\n你写下的故事，正在写你。", "第 " .. c .. " 章 · 已落笔")
    elseif action == "log" then
        if not f.log then
            f.log = true; Game.AddClue(s, "record"); Game.AddAxis(s, s.persona, 2); Game.Cost(s, 6)
        end
        return Say(Line(({ "3-3-001", "3-3-002", "3-3-003" })[s.persona]))
    elseif action == "diary" then
        f.boatkey = true; s.items.boatkey = "cruise"; Game.AddClue(s, "diary")
        return Say(Line(({ "4-1-003", "4-1-005", "4-1-004" })[s.persona]), nil, "image/item_cabin_key.png")
    elseif action == "final" then
        if not f.boatkey or Game.Count(s) < 11 then return Say("门仍锁着。") end
        local n = (index == 1 and 0 or 3) + s.persona
        s.ending = string.format("4-3-%03d", n)
        return { kind = "ending" }
    end
    return Say("……")
end

function Game.Password(s, value)
    if value ~= "2317" then
        s.errors = s.errors + 1
        if s.errors % 3 == 0 then s.lucidity = math.max(1, s.lucidity - 2) end
        return false
    end
    s.chapter = 4; s.maxChapter = math.max(4, s.maxChapter); Game.AddClue(s, "ticket2317"); Game.LockPersona(s)
    return true
end

function Game.Tick(s, dt)
    s.elapsed = s.elapsed + dt
    if s.world == "asylum" then
        s.asylumTime = s.asylumTime + dt
        if s.asylumTime >= 90 then s.asylumTime = s.asylumTime - 90; Game.Cost(s, 4) end
    end
end

function Game.Rest(s)
    if s.world ~= "cruise" or s.chapter ~= 1 then return "需要回到客舱安全点才能休息，可通过航程回访返回。" end
    if s.lucidity >= 100 then return "已经足够清醒，不需要休息。" end
    if s.rests >= 2 then return "本次航程的两次休息已经用完。" end
    if s.elapsed - s.restAt < 300 then return "思绪还没平静。休息需要间隔五分钟。" end
    s.rests = s.rests + 1; s.restAt = s.elapsed; Game.Cost(s, -25)
    return "闭上眼，听海浪。清醒度恢复了。"
end

function Game.Watch(s)
    if s.watches <= 0 then return "怀表里没有余下的记忆了。" end
    if s.lucidity >= 100 then return "此刻已经足够清醒，不需要使用怀表。" end
    s.watches = s.watches - 1; Game.Cost(s, -15)
    return "表针走过六点。你想起了此刻的自己。"
end

return Game
