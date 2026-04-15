-- ============================================================================
-- BattlePassages.lua - 战斗/森林段落路由（getPassage）
-- ============================================================================

local GameState = require("systems.GameState")

--- 安装段落路由到 BattleSystem
---@param BS table BattleSystem 主表
return function(BS)

-- ==================== 段落系统内部工具 ====================

--- 构建战场状态文本
---@return string
local function buildBattleStatus()
    local S = GameState.state
    local lines = { "══════ 战 斗 ══════\n" }

    table.insert(lines, "【敌方】")
    for _, e in ipairs(S.enemies) do
        table.insert(lines, BS.getEnemyStatusText(e))
    end
    table.insert(lines, "\n【我方】")
    for _, p in ipairs(S.party) do
        table.insert(lines, BS.getActorStatusText(p))
    end

    if S.lastBattleMessage and S.lastBattleMessage ~= "" then
        table.insert(lines, "\n📋 " .. S.lastBattleMessage)
    end

    return table.concat(lines, "\n")
end

--- 执行玩家技能并自动处理后续敌人回合，返回下一段落名
---@param actor table
---@param skillId string
---@return string nextPassage
local function executeAndProcess(actor, skillId)
    local S = GameState.state
    local messages = {}

    table.insert(messages, BS.actorAct(actor, skillId))

    if not S.inCombat then
        S.lastBattleMessage = table.concat(messages, "\n")
        return S.battleResult == "victory" and "战斗_胜利" or "战斗_失败"
    end

    local safe = 0
    while S.inCombat and not BS.isPlayerTurn() and safe < 20 do
        local cur = BS.getCurrentActor()
        if cur and cur.hp > 0 and cur.isEnemy then
            table.insert(messages, BS.enemyAITurn(cur))
        else
            BS.advanceTurn()
        end
        safe = safe + 1
        if not S.inCombat then break end
    end

    S.lastBattleMessage = table.concat(messages, "\n")
    if not S.inCombat then
        return S.battleResult == "victory" and "战斗_胜利" or "战斗_失败"
    end
    return "战斗"
end

-- ==================== 段落路由 ====================

--- 处理所有战斗/森林相关段落
---@param passageName string
---@return table|nil
function BS.getPassage(passageName)
    local S = GameState.state
    local TimeSystem = require("systems.TimeSystem")

    -- ═══════════════════════════════════════════
    --  渡劫森林（入口 / 层间导航）
    -- ═══════════════════════════════════════════
    if passageName == "渡劫森林" then
        local pc = S.playerCombat
        local cleared = BS.isForestCleared()
        local h = S.hour or 8

        local text = "🌲 渡劫森林\n\n"
        if cleared then
            text = text .. "你已经征服了渡劫森林，森林之主被击败了。\n"
                .. "林间的怪物不再敌视你，鸟鸣声回荡在枝头。\n"
                .. "如果想再次挑战，可以重置森林。"
        else
            if h >= 6 and h < 12 then
                text = text .. "晨光透过密集的树冠，在林间投下斑驳的光影。空气里弥漫着泥土和落叶的气息。远处传来鸟啼和溪水声。"
            elseif h >= 12 and h < 17 then
                text = text .. "午后的森林闷热而安静。阳光只能从高处的缝隙间洒落，像一根根金色的柱子。偶尔有不知名的小动物从灌木丛中窜过。"
            elseif h >= 17 and h < 20 then
                text = text .. "傍晚的森林笼罩在橘红色的余晖中。树影拉得很长，暗处开始变得模糊。你听到了远处狼群的嚎叫。"
            else
                text = text .. "夜晚的渡劫森林幽暗而危险。月光勉强照亮脚下的路，四周是密不透风的黑暗。奇怪的声响不时从林子深处传来。"
            end
            text = text .. "\n\n林子边缘立着一块斑驳的木牌：「渡劫森林——深处危险，入者自负。」"

            text = text .. string.format(
                "\n\n当前进度：第 %.0f / %.0f 层\n", S.forestLayer, S.maxLayer)
            text = text .. string.format(
                "⚔️ 勇者  HP:%.0f/%.0f  MP:%.0f/%.0f  Lv.%.0f\n",
                pc.hp, pc.maxHp, pc.mp, pc.maxMp, pc.level)
            if S.kInParty then
                local kc = S.kCombat
                text = text .. string.format(
                    "🗡️ K  HP:%.0f/%.0f  MP:%.0f/%.0f  Lv.%.0f\n",
                    kc.hp, kc.maxHp, kc.mp, kc.maxMp, kc.level)
            end
            text = text .. string.format("\n💰 金币：%.0f", S.gold)
        end

        if S.forestExploreMsg and S.forestExploreMsg ~= "" then
            text = text .. "\n\n📋 " .. S.forestExploreMsg
            S.forestExploreMsg = ""
        end

        local choices = {}

        if cleared then
            table.insert(choices, {
                text = "🔄 重置森林（重新挑战）",
                action = function()
                    BS.resetForest()
                    return "渡劫森林"
                end,
            })
        else
            table.insert(choices, {
                text = "🚶 探索第 " .. S.forestLayer .. " 层（30分钟）",
                action = function()
                    TimeSystem.addMinutes(30)
                    if BS.checkEncounter() then
                        S.battleSource = "explore"
                        BS.startBattle()
                        BS.processEnemyTurnsUntilPlayer()
                        if not S.inCombat then
                            return S.battleResult == "victory" and "战斗_胜利" or "战斗_失败"
                        end
                        return "战斗"
                    else
                        if math.random() < 0.5 then
                            local evt = BS.getRandomForestEvent()
                            return "森林事件_" .. evt
                        else
                            BS.advanceLayer()
                            S.forestExploreMsg = "你安全通过了这一层，没有遇到任何危险。"
                            return "渡劫森林"
                        end
                    end
                end,
            })

            table.insert(choices, {
                text = "🌿 沿着小径探索（30分钟 | 疲劳+8）",
                action = function()
                    TimeSystem.addMinutes(30)
                    GameState.modStat("fatigue", 8)
                    S.forageItems = S.forageItems or {}

                    local roll = math.random(100)
                    if roll <= 35 then
                        local herbs = { "薄荷草", "止血草", "安神花", "苦根" }
                        local herb = herbs[math.random(#herbs)]
                        S.forageItems[herb] = (S.forageItems[herb] or 0) + 1
                        GameState.showNotification("你在灌木丛旁发现了一株" .. herb .. "，小心翼翼地采了下来。\n(获得：" .. herb .. " ×1)")
                    elseif roll <= 60 then
                        local fruits = { "野莓", "山楂果", "松子", "橡子" }
                        local fruit = fruits[math.random(#fruits)]
                        local count = math.random(1, 3)
                        S.forageItems[fruit] = (S.forageItems[fruit] or 0) + count
                        GameState.showNotification("你在一棵矮树上摘到了" .. fruit .. "！看起来还挺新鲜的。\n(获得：" .. fruit .. " ×" .. count .. ")")
                    elseif roll <= 75 then
                        local shrooms = { "松茸", "白蘑菇", "可疑的红蘑菇" }
                        local shroom = shrooms[math.random(#shrooms)]
                        S.forageItems[shroom] = (S.forageItems[shroom] or 0) + 1
                        GameState.showNotification("朽木边长着几朵" .. shroom .. "。你摘了一朵放进口袋。\n(获得：" .. shroom .. " ×1)")
                    elseif roll <= 85 then
                        GameState.showNotification("你在林子里转了半天，除了蚊虫叮咬什么也没找到。(疲劳+8)")
                    elseif roll <= 95 then
                        GameState.modStat("stress", 10)
                        local incidents = {
                            "一只蛇从脚边窜过，你吓了一大跳！",
                            "你踩到了一根滑腻的树根，差点摔进沟里。",
                            "一群乌鸦突然从头顶飞过，吵得你心慌。",
                            "你不小心碰到了荨麻，手臂火辣辣地疼。",
                        }
                        GameState.showNotification(incidents[math.random(#incidents)] .. "\n(压力+10)")
                    else
                        local rares = { "月光草", "黑铁矿石碎片", "旧冒险者的笔记" }
                        local rare = rares[math.random(#rares)]
                        S.forageItems[rare] = (S.forageItems[rare] or 0) + 1
                        GameState.showNotification("你在一处隐蔽的角落发现了稀有的" .. rare .. "！\n(获得：" .. rare .. " ×1)")
                    end
                    return "渡劫森林"
                end,
            })

            if h >= 6 and h < 20 then
                table.insert(choices, {
                    text = "🗡️ 深入森林深处（1小时 | 疲劳+15，有风险）",
                    action = function()
                        TimeSystem.addMinutes(60)
                        GameState.modStat("fatigue", 15)
                        S.forageItems = S.forageItems or {}

                        local roll = math.random(100)
                        if roll <= 50 then
                            S.battleSource = "explore"
                            BS.startBattle()
                            BS.processEnemyTurnsUntilPlayer()
                            if not S.inCombat then
                                return S.battleResult == "victory" and "战斗_胜利" or "战斗_失败"
                            end
                            return "战斗"
                        elseif roll <= 75 then
                            local herb = ({ "灵芝", "天麻", "人参须" })[math.random(3)]
                            S.forageItems[herb] = (S.forageItems[herb] or 0) + 1
                            local fruit = ({ "野莓", "山楂果" })[math.random(2)]
                            S.forageItems[fruit] = (S.forageItems[fruit] or 0) + 2
                            GameState.showNotification("深处的资源果然丰富！你采到了" .. herb .. "和一些" .. fruit .. "。\n(获得：" .. herb .. " ×1, " .. fruit .. " ×2)")
                        elseif roll <= 90 then
                            local goldAmt = math.random(10, 30)
                            S.gold = (S.gold or 0) + goldAmt
                            GameState.showNotification("你在一棵老树根下发现了一个破旧的箱子，里面有些金币！\n(金币+" .. goldAmt .. ")")
                        else
                            GameState.modStat("stress", 8)
                            GameState.modStat("fatigue", 10)
                            GameState.showNotification("你在森林深处迷了路，花了好长时间才找到回去的路。(压力+8, 疲劳+10)")
                        end
                        return "渡劫森林"
                    end,
                })
            end

            table.insert(choices, {
                text = "🏪 森林商人",
                target = "森林商人",
            })
        end

        table.insert(choices, {
            text = "🪵 找块石头坐一会儿（15分钟 | 压力-5）",
            action = function()
                TimeSystem.addMinutes(15)
                GameState.modStat("stress", -5)
                GameState.modStat("fatigue", -3)
                GameState.showNotification("你靠着一块大石头坐了一会儿，听着林间的风声。(压力-5, 疲劳-3)")
                return "渡劫森林"
            end,
        })

        if (S.forageItems or {})["野莓"] and S.forageItems["野莓"] > 0 then
            table.insert(choices, {
                text = "🫐 吃点野莓充饥（3分钟 | 饱食+8）",
                action = function()
                    S.forageItems["野莓"] = S.forageItems["野莓"] - 1
                    if S.forageItems["野莓"] <= 0 then S.forageItems["野莓"] = nil end
                    GameState.modStat("satiety", 8)
                    TimeSystem.addMinutes(3)
                    GameState.showNotification("酸酸甜甜的野莓，还挺好吃。(饱食+8)")
                    return "渡劫森林"
                end,
            })
        end

        table.insert(choices, {
            text = "🔙 离开森林",
            target = "十字路口",
        })

        return { text = text, choices = choices }

    -- ═══════════════════════════════════════════
    --  战斗主界面
    -- ═══════════════════════════════════════════
    elseif passageName == "战斗" then
        if not S.inCombat then
            return {
                text = "没有正在进行的战斗。",
                choices = { { text = "返回森林", target = "渡劫森林" } },
            }
        end

        local actor = BS.getCurrentActor()
        local text = buildBattleStatus()

        if actor and actor.isPlayer and actor.hp > 0 then
            text = text .. "\n\n▶ " .. actor.name .. " 的回合，请选择行动："

            local categories = BS.getCategoriesForActor(actor)
            local choices = {}

            for _, cat in ipairs(categories) do
                table.insert(choices, {
                    text = cat.name,
                    target = "战斗_" .. cat.id,
                })
            end

            table.insert(choices, {
                text = "🛡️ 防御（恢复5%HP）",
                action = function()
                    return executeAndProcess(actor, "defend")
                end,
            })

            table.insert(choices, {
                text = "🏃 逃跑",
                target = "战斗_逃跑",
            })

            return { text = text, choices = choices }
        else
            return {
                text = text,
                choices = { { text = "继续", target = "战斗" } },
            }
        end

    -- ═══════════════════════════════════════════
    --  技能子菜单：物理 / 魔法 / 增益
    -- ═══════════════════════════════════════════
    elseif passageName == "战斗_物理" or passageName == "战斗_魔法" or passageName == "战斗_增益" then
        local catId
        if passageName == "战斗_物理" then catId = "物理"
        elseif passageName == "战斗_魔法" then catId = "魔法"
        else catId = "增益" end

        local actor = BS.getCurrentActor()
        if not actor or not actor.isPlayer then
            return {
                text = "不是你的回合。",
                choices = { { text = "返回", target = "战斗" } },
            }
        end

        local categories = BS.getCategoriesForActor(actor)
        local cat = nil
        for _, c in ipairs(categories) do
            if c.id == catId then cat = c; break end
        end

        if not cat then
            return {
                text = "该角色没有此类技能。",
                choices = { { text = "返回", target = "战斗" } },
            }
        end

        local text = buildBattleStatus()
        text = text .. "\n\n▶ " .. actor.name .. " - " .. cat.name .. "："

        local choices = {}
        for _, sk in ipairs(cat.skills) do
            local label = sk.icon .. " " .. sk.name
            if sk.cost ~= "" then label = label .. "（" .. sk.cost .. "）" end
            label = label .. " - " .. sk.desc

            table.insert(choices, {
                text = label,
                action = function()
                    return executeAndProcess(actor, sk.id)
                end,
            })
        end

        table.insert(choices, { text = "🔙 返回", target = "战斗" })
        return { text = text, choices = choices }

    -- ═══════════════════════════════════════════
    --  逃跑
    -- ═══════════════════════════════════════════
    elseif passageName == "战斗_逃跑" then
        local ok, escMsg = BS.tryEscape()
        if ok then
            return {
                text = "🏃 " .. escMsg .. "\n\n你们成功脱离了战斗！",
                choices = { { text = "返回森林", target = "渡劫森林" } },
            }
        else
            S.lastBattleMessage = escMsg
            BS.advanceTurn()
            BS.processEnemyTurnsUntilPlayer()

            if not S.inCombat then
                return {
                    text = "🏃 " .. escMsg .. "\n\n"
                        .. (S.battleResult == "victory" and "敌人被击败了！" or "你们被击败了..."),
                    choices = { {
                        text = "继续",
                        target = S.battleResult == "victory" and "战斗_胜利" or "战斗_失败",
                    } },
                }
            end

            return {
                text = buildBattleStatus() .. "\n\n🏃 " .. escMsg .. "\n浪费了一个回合！",
                choices = { { text = "继续战斗", target = "战斗" } },
            }
        end

    -- ═══════════════════════════════════════════
    --  战斗胜利
    -- ═══════════════════════════════════════════
    elseif passageName == "战斗_胜利" then
        -- 切磋胜利
        if S.battleSource == "sparring" then
            local text = "🤝 切磋结束！\n\n"
            if S.lastBattleMessage and S.lastBattleMessage ~= "" then
                text = text .. S.lastBattleMessage
            end
            local leideName = S.initialName or "莱德"
            text = text .. "\n\n" .. leideName .. "收起武器，微微喘着气，嘴角带着一丝笑意。\n"
                .. "「不错嘛……你比上次进步了。」\n\n"
                .. "他伸出手，你们碰了碰拳。\n"
            S.initialNameAffection = (S.initialNameAffection or 0) + 3
            text = text .. "（" .. leideName .. " 好感+3）"
            S.playerCombat.hp = S.playerCombat.maxHp
            S.playerCombat.mp = S.playerCombat.maxMp
            if S.kInParty then
                S.kCombat.hp = S.kCombat.maxHp
                S.kCombat.mp = S.kCombat.maxMp
            end
            S.battleSource = ""
            return {
                text = text,
                choices = { { text = "继续", target = S.sparringReturnTo or "十字路口" } },
            }
        end

        -- 城内治安战斗胜利
        if S.battleSource == "town" then
            local text = "🛡️ 治安事件解决！\n\n"
            if S.lastBattleMessage and S.lastBattleMessage ~= "" then
                text = text .. S.lastBattleMessage
            end
            text = text .. "\n\n周围的居民向你投来感激的目光。"
            S.playerCombat.hp = math.min(S.playerCombat.maxHp,
                S.playerCombat.hp + math.floor(S.playerCombat.maxHp * 0.15))
            if S.kInParty then
                S.kCombat.hp = math.min(S.kCombat.maxHp,
                    S.kCombat.hp + math.floor(S.kCombat.maxHp * 0.15))
            end
            local returnTo = S.townBattleReturnTo or "十字路口"
            S.battleSource = ""
            return {
                text = text,
                choices = { { text = "继续", target = returnTo } },
            }
        end

        -- 普通战斗胜利
        local text = "🎉 战斗胜利！\n\n"
        if S.lastBattleMessage and S.lastBattleMessage ~= "" then
            text = text .. S.lastBattleMessage
        end

        if S.battleSource == "girl" then
            local reward = math.random(30, 60)
            S.gold = S.gold + reward
            S.playerCombat.hp = math.min(S.playerCombat.maxHp,
                S.playerCombat.hp + math.floor(S.playerCombat.maxHp * 0.3))
            if S.kInParty then
                S.kCombat.hp = math.min(S.kCombat.maxHp,
                    S.kCombat.hp + math.floor(S.kCombat.maxHp * 0.3))
            end
            text = text .. string.format(
                "\n\n👧 被救的女孩向你道谢，赠送了 %d 金币，并为你们治疗了伤口（恢复30%%HP）。",
                reward)
            S.battleSource = ""
        end

        local choices = {}
        if BS.isForestCleared() then
            table.insert(choices, { text = "🏆 森林已通关！", target = "渡劫森林" })
        else
            table.insert(choices, { text = "继续探索", target = "渡劫森林" })
        end

        return { text = text, choices = choices }

    -- ═══════════════════════════════════════════
    --  战斗失败
    -- ═══════════════════════════════════════════
    elseif passageName == "战斗_失败" then
        -- 切磋失败
        if S.battleSource == "sparring" then
            local leideName = S.initialName or "莱德"
            S.initialNameAffection = (S.initialNameAffection or 0) + 1
            S.playerCombat.hp = S.playerCombat.maxHp
            S.playerCombat.mp = S.playerCombat.maxMp
            if S.kInParty then
                S.kCombat.hp = S.kCombat.maxHp
                S.kCombat.mp = S.kCombat.maxMp
            end
            local returnTo = S.sparringReturnTo or "十字路口"
            S.battleSource = ""
            return {
                text = "🤝 切磋结束\n\n"
                    .. leideName .. "伸手拉起了你。\n\n"
                    .. "「还差一点……不过你的反应速度比之前快多了。」\n"
                    .. "他递过来一壶水：「下次再来。」\n\n"
                    .. "虽然输了，但你感觉自己学到了很多。\n"
                    .. "（" .. leideName .. " 好感+1）",
                choices = { { text = "继续", target = returnTo } },
            }
        end

        -- 城内治安战斗失败
        if S.battleSource == "town" then
            S.playerCombat.hp = math.floor(S.playerCombat.maxHp * 0.7)
            S.playerCombat.mp = math.floor(S.playerCombat.maxMp * 0.7)
            if S.kInParty then
                S.kCombat.hp = math.floor(S.kCombat.maxHp * 0.7)
                S.kCombat.mp = math.floor(S.kCombat.maxMp * 0.7)
            end
            local returnTo = S.townBattleReturnTo or "十字路口"
            S.battleSource = ""
            return {
                text = "💔 你被打倒了...\n\n"
                    .. "路过的巡逻兵把你救了起来。\n"
                    .. "「小心点，这一带最近不太平。」\n\n"
                    .. "你休息了一会儿，恢复了大部分体力。",
                choices = { { text = "继续", target = returnTo } },
            }
        end

        -- 普通战斗失败
        S.forestLayer = 1
        S.playerCombat.hp = math.floor(S.playerCombat.maxHp * 0.5)
        S.playerCombat.mp = math.floor(S.playerCombat.maxMp * 0.5)
        if S.kInParty then
            S.kCombat.hp = math.floor(S.kCombat.maxHp * 0.5)
            S.kCombat.mp = math.floor(S.kCombat.maxMp * 0.5)
        end
        S.battleSource = ""

        return {
            text = "💀 战斗失败...\n\n"
                .. "你被击败了，勉强逃出了森林。\n"
                .. "恢复了一半的HP和MP，探索进度已重置。",
            choices = {
                { text = "回到十字路口", target = "十字路口" },
            },
        }

    -- ═══════════════════════════════════════════
    --  森林事件：果树
    -- ═══════════════════════════════════════════
    elseif passageName == "森林事件_fruit" then
        if S.eventFruitUsed then
            BS.advanceLayer()
            return {
                text = "🌳 神秘果树\n\n你再次经过那棵果树，但果实已经被摘光了。\n你继续前进。",
                choices = { { text = "继续", target = "渡劫森林" } },
            }
        end

        return {
            text = "🌳 神秘果树\n\n"
                .. "你在林中发现一棵奇异的果树，上面结着两种果实：\n\n"
                .. "🔴 红色果实散发着温暖的力量气息\n"
                .. "🔵 蓝色果实闪烁着清冷的智慧光芒",
            choices = {
                {
                    text = "🔴 摘红色果实（力量+1）",
                    action = function()
                        local msg = BS.handleFruitEvent("red")
                        BS.advanceLayer()
                        S.forestExploreMsg = msg
                        return "渡劫森林"
                    end,
                },
                {
                    text = "🔵 摘蓝色果实（灵感+1）",
                    action = function()
                        local msg = BS.handleFruitEvent("blue")
                        BS.advanceLayer()
                        S.forestExploreMsg = msg
                        return "渡劫森林"
                    end,
                },
                {
                    text = "离开",
                    action = function()
                        BS.advanceLayer()
                        return "渡劫森林"
                    end,
                },
            },
        }

    -- ═══════════════════════════════════════════
    --  森林事件：温泉
    -- ═══════════════════════════════════════════
    elseif passageName == "森林事件_hotspring" then
        return {
            text = "♨️ 森林温泉\n\n"
                .. "你在密林深处发现了一处天然温泉，温暖的水雾缭绕。\n"
                .. "泉水清澈见底，似乎蕴含着某种神奇的力量。",
            choices = {
                {
                    text = "♨️ 泡温泉（全体恢复20%HP）",
                    action = function()
                        S.playerCombat.hp = math.min(S.playerCombat.maxHp,
                            S.playerCombat.hp + math.floor(S.playerCombat.maxHp * 0.2))
                        if S.kInParty then
                            S.kCombat.hp = math.min(S.kCombat.maxHp,
                                S.kCombat.hp + math.floor(S.kCombat.maxHp * 0.2))
                        end
                        BS.advanceLayer()
                        S.forestExploreMsg = "你们在温泉中休息，全体恢复20%生命值。"
                        return "渡劫森林"
                    end,
                },
                {
                    text = "🥤 饮用泉水（最大HP+5）",
                    action = function()
                        S.playerCombat.maxHp = S.playerCombat.maxHp + 5
                        S.playerCombat.hp = S.playerCombat.hp + 5
                        BS.advanceLayer()
                        S.forestExploreMsg = "你饮用泉水，最大HP+5！"
                        return "渡劫森林"
                    end,
                },
                {
                    text = "离开",
                    action = function()
                        BS.advanceLayer()
                        return "渡劫森林"
                    end,
                },
            },
        }

    -- ═══════════════════════════════════════════
    --  森林事件：被袭女孩
    -- ═══════════════════════════════════════════
    elseif passageName == "森林事件_girl" then
        return {
            text = "👧 紧急！\n\n"
                .. "你听到前方传来呼救声，一个年轻的女孩正被一只石块怪物追赶。\n"
                .. "她看起来已经筋疲力尽了。",
            choices = {
                {
                    text = "⚔️ 上前帮忙！",
                    action = function()
                        S.battleSource = "girl"
                        BS.startBattleWith({"小石块"})
                        BS.processEnemyTurnsUntilPlayer()
                        if not S.inCombat then
                            return S.battleResult == "victory" and "战斗_胜利" or "战斗_失败"
                        end
                        return "战斗"
                    end,
                },
                {
                    text = "😐 装作没看到，继续前进",
                    action = function()
                        BS.advanceLayer()
                        S.forestExploreMsg = "你避开了那个方向，安静地穿过了这片区域。"
                        return "渡劫森林"
                    end,
                },
            },
        }

    -- ═══════════════════════════════════════════
    --  森林商人
    -- ═══════════════════════════════════════════
    elseif passageName == "森林商人" then
        local text = "🏪 森林商人\n\n"
            .. "一个神秘的商人坐在树桩上，面前摆着各种物品。\n"
            .. string.format("💰 你的金币：%d\n", S.gold)

        if S.merchantMsg and S.merchantMsg ~= "" then
            text = text .. "\n" .. S.merchantMsg
            S.merchantMsg = ""
        end

        local choices = {}
        for _, item in ipairs(BS.MERCHANT_ITEMS) do
            local label = item.name .. "（" .. item.cost .. "金币）"
            if item.id == "potion" and S.boughtPotion then
                label = label .. " [已购]"
            end
            table.insert(choices, {
                text = "🛒 " .. label,
                action = function()
                    local ok, resultMsg = BS.buyMerchantItem(item.id)
                    S.merchantMsg = (ok and "✅ " or "❌ ") .. resultMsg
                    return "森林商人"
                end,
            })
        end

        table.insert(choices, { text = "🔙 返回森林", target = "渡劫森林" })
        return { text = text, choices = choices }
    end

    return nil
end

end -- installer
