-- ============================================================================
-- CookingSystem.lua - 烹饪系统（悠闲悠哉life）
-- 食材管理 / 食谱 / 烹饪 / 小摊经营
-- ============================================================================

---@diagnostic disable: undefined-global, unicode-name

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")

local CookingSystem = {}

-- ==================== 食材定义 ====================

CookingSystem.INGREDIENTS = {
    -- 蔬菜（种植/超市）
    { name = "土豆",   price = 5,  category = "蔬菜" },
    { name = "胡萝卜", price = 4,  category = "蔬菜" },
    { name = "白菜",   price = 3,  category = "蔬菜" },
    { name = "番茄",   price = 5,  category = "蔬菜" },
    { name = "洋葱",   price = 4,  category = "蔬菜" },
    { name = "小麦",   price = 6,  category = "谷物" },
    -- 肉蛋奶（超市）
    { name = "鸡蛋",   price = 3,  category = "蛋类" },
    { name = "鸡肉",   price = 12, category = "肉类" },
    { name = "猪肉",   price = 15, category = "肉类" },
    { name = "鱼肉",   price = 10, category = "肉类" },
    { name = "牛奶",   price = 6,  category = "奶类" },
    { name = "黄油",   price = 8,  category = "奶类" },
    -- 调味（超市）
    { name = "盐",     price = 2,  category = "调味" },
    { name = "糖",     price = 3,  category = "调味" },
    { name = "香料",   price = 8,  category = "调味" },
}

-- ==================== 食谱定义 ====================

CookingSystem.RECIPES = {
    {
        name = "烤土豆",
        levelReq = 0,  -- 入门即可
        ingredients = { { "土豆", 2 }, { "盐", 1 } },
        satiety = 20,
        sellPrice = 12,
        desc = "简单朴素的烤土豆，撒上盐就很好吃。",
    },
    {
        name = "蔬菜汤",
        levelReq = 0,
        ingredients = { { "白菜", 1 }, { "胡萝卜", 1 }, { "盐", 1 } },
        satiety = 25,
        sellPrice = 15,
        desc = "暖呼呼的蔬菜汤，冬天喝最好了。",
    },
    {
        name = "煎蛋",
        levelReq = 0,
        ingredients = { { "鸡蛋", 2 }, { "盐", 1 } },
        satiety = 18,
        sellPrice = 10,
        desc = "金黄焦香的煎蛋，做早餐刚好。",
    },
    {
        name = "番茄炒蛋",
        levelReq = 1,
        ingredients = { { "番茄", 2 }, { "鸡蛋", 2 }, { "盐", 1 } },
        satiety = 30,
        sellPrice = 20,
        desc = "酸甜可口的番茄炒蛋，下饭一绝。",
    },
    {
        name = "洋葱鸡肉卷",
        levelReq = 1,
        ingredients = { { "鸡肉", 1 }, { "洋葱", 1 }, { "小麦", 1 } },
        satiety = 35,
        sellPrice = 25,
        desc = "用面饼卷着鸡肉和洋葱，香气扑鼻。",
    },
    {
        name = "奶油蘑菇汤",
        levelReq = 2,
        ingredients = { { "牛奶", 1 }, { "黄油", 1 }, { "盐", 1 }, { "香料", 1 } },
        satiety = 35,
        sellPrice = 30,
        desc = "丝滑浓郁的奶油蘑菇汤，贵族餐桌上的常客。",
    },
    {
        name = "红烧鱼",
        levelReq = 2,
        ingredients = { { "鱼肉", 1 }, { "糖", 1 }, { "盐", 1 }, { "香料", 1 } },
        satiety = 40,
        sellPrice = 35,
        desc = "肉质鲜嫩、酱汁浓郁的红烧鱼。",
    },
    {
        name = "猪肉饺子",
        levelReq = 2,
        ingredients = { { "猪肉", 1 }, { "小麦", 2 }, { "白菜", 1 }, { "盐", 1 } },
        satiety = 45,
        sellPrice = 40,
        desc = "皮薄馅大的猪肉白菜饺子，一口一个。",
    },
    {
        name = "香料烤鸡",
        levelReq = 3,
        ingredients = { { "鸡肉", 2 }, { "香料", 2 }, { "黄油", 1 }, { "盐", 1 } },
        satiety = 55,
        sellPrice = 55,
        desc = "外焦里嫩、香气四溢的整只烤鸡。大师级料理。",
    },
}

-- ==================== 工具函数 ====================

--- 获取食材信息
function CookingSystem.getIngredientInfo(name)
    for _, ing in ipairs(CookingSystem.INGREDIENTS) do
        if ing.name == name then return ing end
    end
    return nil
end

--- 获取食谱信息
function CookingSystem.getRecipe(name)
    for _, r in ipairs(CookingSystem.RECIPES) do
        if r.name == name then return r end
    end
    return nil
end

--- 获取可用食谱列表（按等级过滤）
function CookingSystem.getAvailableRecipes()
    local S = GameState.state
    local result = {}
    for _, r in ipairs(CookingSystem.RECIPES) do
        if S.cookingLevel >= r.levelReq then
            table.insert(result, r)
        end
    end
    return result
end

--- 检查食材是否足够
function CookingSystem.canCook(recipe)
    local S = GameState.state
    for _, pair in ipairs(recipe.ingredients) do
        local name, need = pair[1], pair[2]
        local have = S.ingredients[name] or 0
        if have < need then return false end
    end
    return true
end

--- 消耗食材
function CookingSystem.consumeIngredients(recipe)
    local S = GameState.state
    for _, pair in ipairs(recipe.ingredients) do
        local name, need = pair[1], pair[2]
        S.ingredients[name] = (S.ingredients[name] or 0) - need
        if S.ingredients[name] <= 0 then S.ingredients[name] = nil end
    end
end

--- 添加食材
function CookingSystem.addIngredient(name, count)
    local S = GameState.state
    S.ingredients[name] = (S.ingredients[name] or 0) + (count or 1)
end

--- 添加烹饪经验
function CookingSystem.addCookingExp(amount)
    local S = GameState.state
    S.cookingExp = S.cookingExp + amount
    -- 升级：每级需要的经验递增
    local thresholds = { 30, 80, 160, 300 } -- 0→1, 1→2, 2→3, 3→4(max)
    if S.cookingLevel < #thresholds then
        local needed = thresholds[S.cookingLevel + 1]
        if S.cookingExp >= needed then
            S.cookingLevel = S.cookingLevel + 1
            GameState.showNotification("烹饪等级提升到 " .. S.cookingLevel .. "！")
            GameState.addDateLog("技能", "烹饪升级", "烹饪等级提升到" .. S.cookingLevel)
            if S.cookingLevel == 2 then
                GameState.showNotification("烹饪等级2——你现在可以去商业区摆小摊了！")
            end
        end
    end
end

--- 修改饱食度（安全）
function CookingSystem.modSatiety(delta)
    local S = GameState.state
    GameState.modStat("satiety", delta)
end

--- 修改疲劳（安全）
function CookingSystem.modFatigue(delta)
    local S = GameState.state
    GameState.modStat("fatigue", delta)
end

--- 修改压力（安全）
function CookingSystem.modStress(delta)
    local S = GameState.state
    GameState.modStat("stress", delta)
end

--- 获取饱食度描述
function CookingSystem.getSatietyDesc()
    local S = GameState.state
    if S.satiety >= 80 then return "饱足"
    elseif S.satiety >= 50 then return "正常"
    elseif S.satiety >= 20 then return "有点饿"
    else return "饥饿"
    end
end

--- 获取饱食度描述行（与浴室清洁度风格一致）
function CookingSystem.getSatietyLine()
    local S = GameState.state
    local sat = S.satiety or 80
    if sat <= 15 then
        return "\n你的肚子咕咕叫个不停，眼前的食物看起来格外诱人。"
    elseif sat <= 30 then
        return "\n你觉得有点饿了，该吃点什么。"
    elseif sat <= 60 then
        return "\n肚子还不算太饿，但吃点东西也不错。"
    else
        return "\n你现在不太饿。"
    end
end

--- 获取食材列表文本
function CookingSystem.getIngredientsText()
    local S = GameState.state
    local parts = {}
    for name, count in pairs(S.ingredients) do
        if count > 0 then
            table.insert(parts, name .. "×" .. count)
        end
    end
    if #parts == 0 then return "（空空如也）" end
    table.sort(parts)
    return table.concat(parts, "  ")
end

-- ==================== Passage 段落 ====================

function CookingSystem.getPassage(passageName)
    local S = GameState.state

    -- ==================== 超市 ====================

    if passageName == "商业区_超市" then
        return {
            text = "你走进那家大型超市。门口的招牌写着「日轮超市」。\n\n"
                .. "宽敞的货架上摆满了各种商品，从日用品到食材应有尽有。\n"
                .. "一个穿围裙的店员在整理货架，看到你走进来，微笑着说：\n"
                .. "'欢迎光临，需要什么尽管问。'\n\n"
                .. "你的金币：" .. S.money .. "\n"
                .. "你的食材：" .. CookingSystem.getIngredientsText(),
            choices = {
                { text = "🥕 买蔬菜谷物", target = "超市_蔬菜" },
                { text = "🥩 买肉蛋奶", target = "超市_肉蛋奶" },
                { text = "🧂 买调味料", target = "超市_调味" },
                { text = "🌱 买种子", target = "超市_种子" },
                { text = "🍞 买现成食物（直接吃）", target = "超市_速食" },
                { text = "🔙 离开超市", target = "商业区" },
            },
        }
    end

    if passageName == "超市_蔬菜" then
        local choices = {}
        for _, ing in ipairs(CookingSystem.INGREDIENTS) do
            if ing.category == "蔬菜" or ing.category == "谷物" then
                local have = S.ingredients[ing.name] or 0
                table.insert(choices, {
                    text = ing.name .. " (" .. ing.price .. "金币) [库存:" .. have .. "]",
                    target = "超市_蔬菜",
                    action = function()
                        if S.money >= ing.price then
                            S.money = S.money - ing.price
                            CookingSystem.addIngredient(ing.name, 1)
                            GameState.showNotification("购买了 " .. ing.name .. "。")
                        else
                            GameState.showNotification("金币不够！")
                        end
                    end,
                })
            end
        end
        table.insert(choices, { text = "🔙 返回超市", target = "商业区_超市" })
        return {
            text = "蔬菜谷物区。新鲜的蔬菜整齐地码在货架上。\n\n"
                .. "你的金币：" .. S.money .. "\n"
                .. "你的食材：" .. CookingSystem.getIngredientsText(),
            choices = choices,
        }
    end

    if passageName == "超市_肉蛋奶" then
        local choices = {}
        for _, ing in ipairs(CookingSystem.INGREDIENTS) do
            if ing.category == "肉类" or ing.category == "蛋类" or ing.category == "奶类" then
                local have = S.ingredients[ing.name] or 0
                table.insert(choices, {
                    text = ing.name .. " (" .. ing.price .. "金币) [库存:" .. have .. "]",
                    target = "超市_肉蛋奶",
                    action = function()
                        if S.money >= ing.price then
                            S.money = S.money - ing.price
                            CookingSystem.addIngredient(ing.name, 1)
                            GameState.showNotification("购买了 " .. ing.name .. "。")
                        else
                            GameState.showNotification("金币不够！")
                        end
                    end,
                })
            end
        end
        table.insert(choices, { text = "🔙 返回超市", target = "商业区_超市" })
        return {
            text = "肉蛋奶区。冷柜里的鲜肉和鸡蛋看着都很新鲜。\n\n"
                .. "你的金币：" .. S.money .. "\n"
                .. "你的食材：" .. CookingSystem.getIngredientsText(),
            choices = choices,
        }
    end

    if passageName == "超市_调味" then
        local choices = {}
        for _, ing in ipairs(CookingSystem.INGREDIENTS) do
            if ing.category == "调味" then
                local have = S.ingredients[ing.name] or 0
                table.insert(choices, {
                    text = ing.name .. " (" .. ing.price .. "金币) [库存:" .. have .. "]",
                    target = "超市_调味",
                    action = function()
                        if S.money >= ing.price then
                            S.money = S.money - ing.price
                            CookingSystem.addIngredient(ing.name, 1)
                            GameState.showNotification("购买了 " .. ing.name .. "。")
                        else
                            GameState.showNotification("金币不够！")
                        end
                    end,
                })
            end
        end
        table.insert(choices, { text = "🔙 返回超市", target = "商业区_超市" })
        return {
            text = "调味料货架。各种瓶瓶罐罐排列整齐。\n\n"
                .. "你的金币：" .. S.money .. "\n"
                .. "你的食材：" .. CookingSystem.getIngredientsText(),
            choices = choices,
        }
    end

    if passageName == "超市_种子" then
        local FarmingSystem = require("systems.FarmingSystem")
        local choices = {}
        for _, seed in ipairs(FarmingSystem.SEEDS) do
            local have = S.farmSeeds[seed.name] or 0
            table.insert(choices, {
                text = seed.name .. " (" .. seed.price .. "金币) [库存:" .. have .. "] — " .. seed.growDays .. "天成熟",
                target = "超市_种子",
                action = function()
                    if S.money >= seed.price then
                        S.money = S.money - seed.price
                        S.farmSeeds[seed.name] = (S.farmSeeds[seed.name] or 0) + 1
                        GameState.showNotification("购买了 " .. seed.name .. "。")
                    else
                        GameState.showNotification("金币不够！")
                    end
                end,
            })
        end
        table.insert(choices, { text = "🔙 返回超市", target = "商业区_超市" })
        return {
            text = "种子区。一个个小纸袋上画着作物的图案。\n"
                .. "买了种子可以种在家门口的空地里。\n\n"
                .. "你的金币：" .. S.money,
            choices = choices,
        }
    end

    if passageName == "超市_速食" then
        return {
            text = "速食区。这里有一些可以直接吃的食物。"
                .. CookingSystem.getSatietyLine()
                .. "\n你的金币：" .. S.money,
            choices = {
                {
                    text = "🍞 面包 (8金币 饱食+15)",
                    target = "超市_速食",
                    action = function()
                        if S.money >= 8 then
                            S.money = S.money - 8
                            CookingSystem.modSatiety(15)
                            GameState.showNotification("吃了一个面包。还不错。")
                        else
                            GameState.showNotification("金币不够！")
                        end
                    end,
                },
                {
                    text = "🥪 三明治 (15金币 饱食+25)",
                    target = "超市_速食",
                    action = function()
                        if S.money >= 15 then
                            S.money = S.money - 15
                            CookingSystem.modSatiety(25)
                            GameState.showNotification("三明治味道不错，比面包饱多了。")
                        else
                            GameState.showNotification("金币不够！")
                        end
                    end,
                },
                {
                    text = "🍖 烤肉便当 (30金币 饱食+45 减压-5)",
                    target = "超市_速食",
                    action = function()
                        if S.money >= 30 then
                            S.money = S.money - 30
                            CookingSystem.modSatiety(45)
                            CookingSystem.modStress(-5)
                            GameState.showNotification("大口吃肉的感觉真好！心情也好了一些。")
                        else
                            GameState.showNotification("金币不够！")
                        end
                    end,
                },
                { text = "🔙 返回超市", target = "商业区_超市" },
            },
        }
    end

    -- ==================== 厨房（在家做饭）====================

    if passageName == "家_食谱烹饪" then
        local recipes = CookingSystem.getAvailableRecipes()
        local choices = {}

        if #recipes == 0 then
            return {
                text = "你站在厨房里。\n\n"
                    .. "锅碗瓢盆都有，但你什么都不会做。\n"
                    .. "也许该去社区大学学学烹饪？\n\n"
                    .. "……或者先煮个水喝喝也行。\n\n"
                    .. "你的食材：" .. CookingSystem.getIngredientsText(),
                choices = {
                    {
                        text = "🫖 喝杯热水 (饱食+5)",
                        target = "家",
                        action = function()
                            CookingSystem.modSatiety(5)
                            CookingSystem.modStress(-2)
                            TimeSystem.addMinutes(5)
                            GameState.showNotification("喝了一杯热水。暖暖的。")
                        end,
                    },
                    { text = "🔙 回客厅", target = "家" },
                },
            }
        end

        for _, recipe in ipairs(recipes) do
            local canMake = CookingSystem.canCook(recipe)
            local ingList = {}
            for _, pair in ipairs(recipe.ingredients) do
                local have = S.ingredients[pair[1]] or 0
                local mark = have >= pair[2] and "✓" or "✗"
                table.insert(ingList, pair[1] .. "×" .. pair[2] .. mark)
            end
            local ingText = table.concat(ingList, " ")

            if canMake then
                table.insert(choices, {
                    text = "🍳 " .. recipe.name .. " [" .. ingText .. "] 饱食+" .. recipe.satiety,
                    target = "家_烹饪结果",
                    action = function()
                        S._cookingRecipeName = recipe.name
                    end,
                })
            else
                table.insert(choices, {
                    text = "🚫 " .. recipe.name .. " [" .. ingText .. "] — 食材不足",
                    target = "家_食谱烹饪",
                    action = function()
                        GameState.showNotification("食材不够，去超市买点吧。")
                    end,
                })
            end
        end

        table.insert(choices, { text = "🔙 回客厅", target = "家" })

        return {
            text = "你走进厨房。该做点什么吃的呢？\n\n"
                .. "烹饪等级：" .. S.cookingLevel .. "  经验：" .. S.cookingExp
                .. CookingSystem.getSatietyLine()
                .. "\n\n你的食材：" .. CookingSystem.getIngredientsText(),
            choices = choices,
        }
    end

    if passageName == "家_烹饪结果" then
        local recipeName = S._cookingRecipeName or "烤土豆"
        local recipe = CookingSystem.getRecipe(recipeName)
        S._cookingRecipeName = nil

        if not recipe or not CookingSystem.canCook(recipe) then
            return {
                text = "你翻了翻食材……好像不够了。",
                choices = { { text = "继续", target = "家_食谱烹饪" } },
            }
        end

        CookingSystem.consumeIngredients(recipe)
        CookingSystem.modSatiety(recipe.satiety)
        CookingSystem.modFatigue(5)
        CookingSystem.addCookingExp(recipe.levelReq * 3 + 5)
        TimeSystem.addMinutes(20)

        -- 学会新食谱标记
        local learned = false
        for _, known in ipairs(S.knownRecipes) do
            if known == recipe.name then learned = true; break end
        end
        if not learned then
            table.insert(S.knownRecipes, recipe.name)
            -- 学会新菜谱时收集关键词
            local kwOk, KW = pcall(require, "systems.KeywordSystem")
            if kwOk and KW.collectKeyword then KW.collectKeyword("new_recipe") end
        end

        local stressReduce = recipe.satiety >= 35 and 8 or 3
        CookingSystem.modStress(-stressReduce)

        return {
            text = "你花了一些时间准备食材、点火、烹饪……\n\n"
                .. "终于，" .. recipe.name .. "做好了。\n\n"
                .. recipe.desc .. "\n\n"
                .. "你坐下来慢慢吃完。\n"
                .. (recipe.satiety >= 35 and "吃饱了，心情也好了不少。" or "虽然简单，但填饱了肚子。")
                .. "\n\n"
                .. "（饱食+" .. recipe.satiety .. " 压力-" .. stressReduce .. " 疲劳+5 烹饪经验+"
                .. (recipe.levelReq * 3 + 5) .. "）",
            choices = { { text = "继续", target = "家" } },
        }
    end

    -- ==================== 小摊经营 ====================

    if passageName == "商业区_小摊" then
        if S.cookingLevel < 2 then
            return {
                text = "你看了看商业区的空摊位。\n\n"
                    .. "要想在这里摆摊卖小吃，至少需要烹饪等级2。\n"
                    .. "目前你的烹饪等级是 " .. S.cookingLevel .. "。\n\n"
                    .. "去社区大学学烹饪课，或者在家多练练厨艺吧。",
                choices = { { text = "🔙 返回商业区", target = "商业区" } },
            }
        end

        local recipes = CookingSystem.getAvailableRecipes()
        local choices = {}

        for _, recipe in ipairs(recipes) do
            local canMake = CookingSystem.canCook(recipe)
            if canMake then
                table.insert(choices, {
                    text = "🍳 卖" .. recipe.name .. " (售价" .. recipe.sellPrice .. "金币)",
                    target = "商业区_小摊_出摊",
                    action = function()
                        S._stallRecipeName = recipe.name
                    end,
                })
            end
        end

        if #choices == 0 then
            table.insert(choices, {
                text = "（没有足够的食材做任何菜…去超市看看？）",
                target = "商业区_超市",
            })
        end

        table.insert(choices, { text = "🔙 返回商业区", target = "商业区" })

        return {
            text = "你来到商业区的空摊位前。\n\n"
                .. "这里人来人往，是摆摊的好地方。\n"
                .. "选一道拿手菜来卖吧！\n\n"
                .. "累计出摊：" .. S.stallDayCount .. "天  今日收入：" .. S.stallRevenue .. "金币\n"
                .. "食材：" .. CookingSystem.getIngredientsText(),
            choices = choices,
        }
    end

    if passageName == "商业区_小摊_出摊" then
        local recipeName = S._stallRecipeName or "烤土豆"
        local recipe = CookingSystem.getRecipe(recipeName)
        S._stallRecipeName = nil

        if not recipe or not CookingSystem.canCook(recipe) then
            return {
                text = "食材不够了……下次备齐再来吧。",
                choices = { { text = "继续", target = "商业区_小摊" } },
            }
        end

        CookingSystem.consumeIngredients(recipe)
        CookingSystem.modFatigue(10)
        CookingSystem.addCookingExp(recipe.levelReq * 2 + 3)
        TimeSystem.addMinutes(60)

        -- 随机销售结果
        local luck = math.random(1, 100)
        local soldCount, bonus
        if luck <= 20 then
            soldCount = 1
            bonus = "生意冷清。只卖出去一份。"
        elseif luck <= 60 then
            soldCount = 2
            bonus = "生意还可以。有几个人来尝了尝你的手艺。"
        elseif luck <= 85 then
            soldCount = 3
            bonus = "生意不错！不少人被香味吸引过来。"
        else
            soldCount = 4
            bonus = "大卖！路人排起了队，有人说这是商业区最好吃的小摊。"
        end

        -- 魅力加成
        if S.ML >= 5 then
            soldCount = soldCount + 1
            bonus = bonus .. "\n（你的魅力吸引了更多客人 +1份）"
        end

        local revenue = recipe.sellPrice * soldCount
        S.money = S.money + revenue
        S.stallRevenue = S.stallRevenue + revenue
        S.stallDayCount = S.stallDayCount + 1
        S.stallOpen = true

        -- 出摊收集关键词
        local kwOk, KW = pcall(require, "systems.KeywordSystem")
        if kwOk and KW.collectKeyword then
            KW.collectKeyword("stall_income")
            KW.collectKeyword("stall_experience")
        end

        return {
            text = "你支起摊位，开始忙活起来。\n\n"
                .. "一个小时后——\n\n"
                .. bonus .. "\n\n"
                .. "今天卖了 " .. soldCount .. " 份" .. recipe.name .. "。\n"
                .. "收入：" .. revenue .. " 金币\n\n"
                .. "（疲劳+10 烹饪经验+" .. (recipe.levelReq * 2 + 3) .. "）",
            choices = {
                { text = "🍳 继续出摊", target = "商业区_小摊" },
                { text = "🔙 收摊回去", target = "商业区" },
            },
        }
    end

    return nil
end

return CookingSystem
