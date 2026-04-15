-- ============================================================================
-- MainQuest.lua - 主线任务系统（悠闲悠哉life）
-- 基于剧情概述文档实现的主线剧情，包含多分支选择和属性判定
-- ============================================================================
---@diagnostic disable: undefined-global, unicode-name, unknown-symbol, miss-symbol, exp-in-action, miss-exp, action-after-return

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")

local MainQuest = {}

-- ==================== 触发器 ====================

--- 检查当前位置是否有主线触发事件，返回要插入的choice或nil
---@param location string
---@return table|nil
function MainQuest.getTriggerChoice(location)
    local S = GameState.state

    -- 阶段0：听到传闻（条件：day>=4，在商业区或十字路口触发）
    if S.mqStage == 0 and S.day >= 4 then
        if location == "商业区" then
            return {
                text = "⚡ 酒馆门口围着一群人，低声议论着什么……",
                target = "主线_传闻",
            }
        end
    end

    -- 阶段1：继续调查
    if S.mqStage == 1 then
        if location == "十字路口" then
            return {
                text = "⚡ 关于" .. S.initialName .. "的事，你还放不下心……",
                target = "主线_追查",
            }
        end
    end

    -- 阶段2：准备营救
    if S.mqStage == 2 then
        if location == "十字路口" then
            return {
                text = "⚡ " .. S.initialName .. "还被关着，你不能再等了……",
                target = "主线_决定",
            }
        end
    end

    return nil
end

-- ==================== 段落数据 ====================

local Ch1Passages = require("systems.mainquest.Ch1Passages")

function MainQuest.getPassage(passageName)
    return Ch1Passages.getPassage(passageName, MainQuest)
end

-- ==================== 任务面板提示 ====================

--- 获取当前主线任务提示（用于日志页面任务面板）
---@return string
function MainQuest.getQuestHint()
    local S = GameState.state
    local stage = S.mqStage or 0
    local name = S.initialName or "莱德"

    -- 第一章
    if stage == 0 then
        if (S.day or 1) < 4 then
            return "在小镇安顿下来，熟悉周围环境（第4天后触发）"
        end
        return "去商业区打听" .. name .. "的消息"
    elseif stage == 1 then
        return "继续调查" .. name .. "的下落（去十字路口整理线索）"
    elseif stage == 2 then
        return "准备营救" .. name .. "（去十字路口做出决定）"
    elseif stage == 3 then
        return "正在潜入中……找到" .. name .. "！"
    elseif stage == 4 then
        return "带" .. name .. "逃离危险！"
    elseif stage == 5 then
        return "已安顿下来。留意小镇的异常变化……"

    -- 第二章
    elseif stage == 6 then
        return "小镇气氛越来越紧张……去十字路口看看发生了什么"
    elseif stage == 7 then
        return "关于那件旧外套……找" .. name .. "谈谈"
    elseif stage == 8 then
        return "三方势力各怀心思——做出你的选择"
    elseif stage == 9 then
        local route = S.mq2Route or 0
        if route == 1 then return "协助黑帮少主的计划（去花街）"
        elseif route == 2 then return "说服双方坐下来谈（寻找调停筹码）"
        elseif route == 3 then return "调查贵族势力的弱点（收集证据）"
        else return "选择你的立场"
        end
    elseif stage == 10 then
        return "追查暗教会的踪迹……"
    elseif stage == 11 then
        return "乌列尔来了——弄清他的真实意图"
    elseif stage == 12 then
        return "暴风雨就要来了。做好最后的准备"

    -- 第三章
    elseif stage == 13 then
        return "混乱已经开始——保护重要的人"
    elseif stage == 14 then
        return "追查父亲留下的秘密"
    elseif stage == 15 then
        return "揭开" .. name .. "身上的封印之谜"
    elseif stage == 16 then
        return "K的面具之下……"
    elseif stage == 17 then
        return "与乌列尔做最后的对话"
    elseif stage == 18 then
        return "前往太阳神殿"
    elseif stage == 19 then
        return "做出你的最终抉择"
    elseif stage >= 20 then
        return "故事已经结束。翻看回忆录，回味这段旅程。"
    end

    return "探索小镇，寻找线索"
end

--- 获取进行中的支线任务提示列表
---@return string[]
function MainQuest.getSideQuestHints()
    local S = GameState.state
    local hints = {}

    if (S.quest_painting or 0) > 0 and (S.quest_painting or 0) < 9 then
        local stages = {
            [1] = "去美术馆调查失窃的画",
            [2] = "收集更多证据，找出窃贼",
            [3] = "准备好了就去对质嫌疑人",
        }
        table.insert(hints, stages[S.quest_painting] or "继续调查失窃的画")
    end

    if (S.quest_watchman or 0) > 0 and (S.quest_watchman or 0) < 9 then
        local stages = {
            [1] = "夜晚去港口跟踪可疑人影",
            [2] = "你已经知道真相了——决定怎么做",
        }
        table.insert(hints, stages[S.quest_watchman] or "继续深夜守望")
    end

    if (S.quest_vera or 0) > 0 and (S.quest_vera or 0) < 9 then
        local stages = {
            [1] = "帮薇拉找到那本旧日记",
            [2] = "了解薇拉的秘密过往",
        }
        table.insert(hints, stages[S.quest_vera] or "继续薇拉的秘密")
    end

    if (S.quest_underflow or 0) > 0 and (S.quest_underflow or 0) < 9 then
        local stages = {
            [1] = "在花街打听更多内幕",
            [2] = "花街局势紧张——选择支持哪一方",
        }
        table.insert(hints, stages[S.quest_underflow] or "继续花街暗流")
    end

    return hints
end

-- ==================== 第二章/第三章触发器扩展 ====================

--- 第二章触发器（在 PassageData 中与 getTriggerChoice 合并调用）
---@param location string
---@return table|nil
function MainQuest.getCh2TriggerChoice(location)
    local S = GameState.state

    -- 阶段5→6：营救结束一段时间后，目睹阶级冲突
    if S.mqStage == 5 and (S.day or 1) >= (S.mqSettledDay or 0) + 5 then
        if location == "十字路口" then
            return {
                text = "⚡ 街头传来一阵骚动，有人在大声争吵……",
                target = "主线2_阶级矛盾",
            }
        end
    end

    -- 阶段6→7：目睹事件后回家
    if S.mqStage == 6 then
        if location == "家" then
            return {
                text = "⚡ " .. (S.initialName or "莱德") .. "坐在桌边，手里拿着一件旧外套出神……",
                target = "主线2_外套回忆",
            }
        end
    end

    -- 阶段7→8：三方邀请
    if S.mqStage == 7 then
        if location == "十字路口" then
            return {
                text = "⚡ 今天的十字路口格外热闹——不同阵营的人都在找你。",
                target = "主线2_三路分歧",
            }
        end
    end

    -- 阶段9→10：路线子任务触发 + 完成后发现暗教会
    if S.mqStage == 9 then
        local route = S.mq2Route or 0
        local prog = S.mq2RouteProgress or 0

        -- 路线子任务渐进触发（按进度解锁，优先于完成检查）
        if route == 1 then -- 黑帮路线：花街→商业区→教堂
            if prog == 0 and location == "花街" then
                return { text = "⚡ 黑帮少主让你去打听魏德曼家的动向……", target = "主线2_黑帮送情报" }
            elseif prog == 1 and location == "商业区" then
                return { text = "⚡ 少主让你去安抚那些被贵族骚扰的商户……", target = "主线2_黑帮安抚商户" }
            elseif prog == 2 and location == "教堂" then
                return { text = "⚡ 少主让你给教堂的克丽丝修女带句话……", target = "主线2_黑帮传话教堂" }
            end
        elseif route == 2 then -- 调停路线：花街→主城区→教堂
            if prog == 0 and location == "花街" then
                return { text = "⚡ 你带着梅菲斯的信来到花街……", target = "主线2_调停送信" }
            elseif prog == 1 and location == "主城区" then
                return { text = "⚡ 是时候去说服奥梅尔参与和谈了……", target = "主线2_调停说服奥梅尔" }
            elseif prog == 2 and location == "教堂" then
                return { text = "⚡ 你需要在教堂安排一个双方都能接受的会面场地……", target = "主线2_调停安排场地" }
            end
        elseif route == 3 then -- 贵族路线：商业区→教堂→主城区
            if prog == 0 and location == "商业区" then
                return { text = "⚡ 你开始调查那些被砸商铺背后的供货商……", target = "主线2_贵族查供货商" }
            elseif prog == 1 and location == "教堂" then
                return { text = "⚡ 你来到教堂，打算暗中调查最近是否有可疑的新人……", target = "主线2_贵族查教堂" }
            elseif prog == 2 and location == "主城区" then
                return { text = "⚡ 是时候调查阿斯特的行踪了……", target = "主线2_贵族查父亲" }
            end
        end

        -- 3个子任务全部完成后，去教堂触发暗教会
        if prog >= 3 and location == "教堂" then
            return {
                text = "⚡ 教堂的地下室传来奇怪的声响……",
                target = "主线2_暗教会",
            }
        end
    end

    -- 阶段10→11：乌列尔登场
    if S.mqStage == 10 then
        if location == "十字路口" then
            return {
                text = "⚡ 一辆华丽的马车停在广场中央，下来一位气度不凡的青年……",
                target = "主线2_乌列尔登场",
            }
        end
    end

    -- 阶段11→12：暴风前夜
    if S.mqStage == 11 then
        if location == "家" then
            return {
                text = "⚡ 窗外传来远处的喊声……今夜注定不平静。",
                target = "主线2_暴风前夜",
            }
        end
    end

    return nil
end

--- 第三章触发器
---@param location string
---@return table|nil
function MainQuest.getCh3TriggerChoice(location)
    local S = GameState.state

    -- 阶段12→13：暴动爆发
    if S.mqStage == 12 then
        if location == "十字路口" then
            return {
                text = "⚡ 到处都是火光和呐喊——暴动爆发了！",
                target = "主线3_暴动爆发",
            }
        end
    end

    -- 阶段13→14：父亲的秘密
    if S.mqStage == 13 then
        if location == "家" then
            return {
                text = "⚡ 在旧衣柜的夹层里，你发现了一封泛黄的信件……",
                target = "主线3_父亲的交易",
            }
        end
    end

    -- 阶段14→15：莱德的封印
    if S.mqStage == 14 then
        if location == "教堂" then
            return {
                text = "⚡ " .. (S.initialName or "莱德") .. "的手背上，那个奇怪的印记在发光……",
                target = "主线3_莱德封印",
            }
        end
    end

    -- 阶段15→16：K的真面目
    if S.mqStage == 15 then
        if location == "酒馆" then
            return {
                text = "⚡ K今天格外沉默，面具后的眼睛望向窗外……",
                target = "主线3_K的真面目",
            }
        end
    end

    -- 阶段16→17：乌列尔的抉择
    if S.mqStage == 16 then
        if location == "主城区" then
            return {
                text = "⚡ 乌列尔约你在大教堂前见面，他的表情前所未有的严肃。",
                target = "主线3_乌列尔抉择",
            }
        end
    end

    -- 阶段17→18：太阳神殿
    if S.mqStage == 17 then
        if location == "教堂" then
            return {
                text = "⚡ 大教堂的壁画开始发光，一条隐藏的通路浮现在你面前……",
                target = "主线3_太阳神殿",
            }
        end
    end

    -- 阶段18→19：最终抉择
    if S.mqStage == 18 then
        if location == "十字路口" then
            return {
                text = "⚡ 所有人都聚集在广场上。是时候做出决定了。",
                target = "主线3_最终抉择",
            }
        end
    end

    return nil
end

return MainQuest
