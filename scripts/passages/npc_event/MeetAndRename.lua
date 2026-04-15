-- passages/npc_event/MeetAndRename.lua
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

handlers["偶遇与改名"] = function(S)
    local name = S.initialName or "莱德"

    if not S.renamed then
        if S.renaming then
            -- 改名中
            return {
                text = "你想了想，试探着说：「我能给你起个别的称呼吗？」\n\n"
                    .. name .. " 愣了一下，似乎没料到你会这么说。沉默片刻后，他微微点头：\n"
                    .. "「……随你。」\n\n"
                    .. "你想叫他：",
                inputField = true,
                inputTarget = "initialName",
                choices = {
                    { text = "就这么定了", action = function()
                        S.renamed = true
                        S.renaming = false
                        local newName = S.initialName or "莱德"
                        GameState.showNotification("从今以后，你叫他「" .. newName .. "」。\n他没有反对，嘴角似乎微微动了一下。")
                        return "十字路口"
                    end },
                    { text = "算了，还是叫你莱德吧", action = function()
                        S.renamed = true
                        S.renaming = false
                        S.initialName = "莱德"
                        return "十字路口"
                    end },
                },
            }
        else
            -- 未改名，首次偶遇描述
            local text = ""
            local meetAction = S.meetActionVar or ""
            if S.meetLocationVar == "港口" then
                text = "「嘿，" .. name .. "。」你走近他。他正把最后一箱货码好，接过工头给的铜币。\n「又来搬货？」你问。\n「嗯。」他简短应了一声，把钱收进口袋，「港口鱼不错，有空可以试试。」"
            elseif meetAction == "休息" then
                text = "你推开咖啡店的门，" .. name .. " 抬头看见你，示意你坐下。\n「这咖啡…」他低头又喝了一口，似乎想说什么，却只说了句：「还行。」\n「你喜欢喝咖啡？」你问。\n「不讨厌。」他把杯子放下，「你怎么来了？」"
            elseif meetAction == "跑腿" then
                text = "你追上 " .. name .. "，他停下脚步，把包裹换了个肩。「有事？」\n「没什么，看你忙。」你跟他并排走着，「天天帮人跑腿，不累？」\n「习惯了。」他瞥了你一眼，「比闲着好。」"
            elseif meetAction == "睡觉" then
                text = "你蹲在帐篷边，" .. name .. " 在睡袋里蜷着，呼吸均匀。月光从帐篷缝隙漏进来，照在他脸上。"
                return {
                    text = text,
                    choices = {
                        { text = "叫醒他", action = function()
                            if (S.initialNameLevel or 1) < 3 then
                                GameState.showNotification("你轻声叫了叫他，但他只是翻了个身，继续沉睡。")
                            else
                                S.hour = 6
                                TimeSystem.addMinutes(0)
                                addAffection("initialName", 3)
                            end
                            return "十字路口"
                        end },
                    },
                }
            else
                text = "月光下，" .. name .. " 的剑停在空中。他收了势，把剑插回鞘里。\n「这么晚还在练？」你走过去。\n「睡不着。」他坐下来，拍了拍身边的草地，「坐。」\n你坐到他旁边，抬头看天。他忽然说：「今晚星星不错。」"
            end

            text = text .. "\n\n你看着他的侧脸，忽然觉得'" .. name .. "'这个称呼有些生疏。"

            return {
                text = text,
                choices = {
                    { text = "我能给你起个别的称呼吗？", action = function()
                        S.renaming = true
                        return "偶遇与改名"
                    end },
                    { text = "（不改名）聊聊别的吧", action = function()
                        S.renamed = true
                        addAffection("initialName", 3)
                        return "十字路口"
                    end },
                },
            }
        end
    else
        -- 已改名，后续偶遇
        S.initialNameTalkCount = (S.initialNameTalkCount or 0) + 1

        -- 首次再会：莱德入队事件（改名后第一次见面即可入队）
        if S.initialNameTalkCount == 1 and not S.initialNameInParty then
            local joinText = name .. "看见你走过来，把剑靠在墙边。"
                .. "「又是你。」他的语气比上次柔和了些。"
                .. "你在他身边坐下，两人沉默了一会儿。\n\n"
                .. name .. "忽然开口：「你……每次都来找我。」\n"
                .. "「没别的朋友嘛。」你半开玩笑地说。\n"
                .. "他没笑，但也没否认。过了一会儿，他握了握剑柄，低声说：\n"
                .. "「以后如果你要去危险的地方……叫上我。」\n"
                .. "他移开视线，耳尖微微发红：「反正闲着也是闲着。」"

            return {
                text = joinText,
                choices = {
                    { text = "⚔️ 当然，一起走", action = function()
                        S.initialNameInParty = true
                        addAffection("initialName", 20)
                        TimeSystem.addMinutes(15)
                        return "十字路口"
                    end },
                    { text = "下次再说", action = function()
                        -- 重置计数让下次再触发
                        S.initialNameTalkCount = 1
                        addAffection("initialName", 5)
                        TimeSystem.addMinutes(10)
                        return "十字路口"
                    end },
                },
            }
        end

        local text = "「你好，" .. name .. "。」你走近他。\n"
            .. "他看了你一眼，嘴角动了动：「又来了。」\n"
            .. "「不欢迎？」你靠在他旁边的墙上。\n"
            .. "「没有。」他顿了顿，「…你好像很闲？」\n"
            .. "「刚来这个镇子一周，没什么事做。」你笑笑，「你呢？来多久了？」\n"
            .. "「差不多。」他淡淡地说，「比你早两天。」\n"
            .. "「那咱们都是新人啊。」你意外地说。\n"
            .. "他看了你一眼，没接话，但也没否认。"

        local choices = {}

        -- 聊天话题池（随机选取）
        local chatTopics = {
            "你随口聊起今天的天气。" .. name .. "嗯了一声，半晌才说：「今天确实……还行。」\n沉默了一会儿，他又补了句：「风不大的时候练剑比较舒服。」",
            "你问他平时都做什么。他想了想：「练剑，发呆，偶尔逛逛。」\n「听起来挺无聊的。」\n「……习惯了。」",
            "你聊起昨晚看到的星星。" .. name .. "抬头看了看天：「嗯，北边那颗最亮的叫猎户星。」\n「你还懂星星？」\n「以前有人教过。」他没再说下去。",
            "你问他剑术是跟谁学的。他沉默了一下：「一个已经不在了的人。」\n气氛有点沉重，你识趣地换了个话题。他似乎松了口气。",
            "你随口吐槽镇上的物价。" .. name .. "难得接话：「面包铺的黑麦面包还行，便宜。」\n「你经常去？」\n「……偶尔。」",
        }
        table.insert(choices, { text = "聊聊天", action = function()
            addAffection("initialName", 5)
            TimeSystem.addMinutes(15)
            local topic = chatTopics[math.random(1, #chatTopics)]
            GameState.showNotification(topic .. "（好感+5）")
            return "偶遇与改名"
        end })

        -- 请吃饭反馈
        table.insert(choices, { text = "🍽️ 请他吃饭", action = function()
            if S.money >= 15 then
                S.money = S.money - 15
                addAffection("initialName", 15)
                TimeSystem.addMinutes(30)
                local eatLines = {
                    "你带他去了街角的小餐馆。他点了最便宜的汤面，你硬是帮他加了个煎蛋。\n" .. name .. "看着碗里的蛋，嘴角微微上扬：「……谢了。」",
                    "你们在路边摊吃了烤肉串。" .. name .. "一口气吃了三串，然后不自在地别过头：「……很久没吃过热乎的了。」",
                    "餐馆里，" .. name .. "安静地喝着汤，你注意到他吃东西的速度比平时慢了不少。\n「怎么了？」\n「……想慢点吃。」他低声说，「这样好像能多待一会儿。」",
                }
                GameState.showNotification(eatLines[math.random(1, #eatLines)] .. "（好感+15，-15金币）")
            else
                GameState.showNotification("你摸了摸口袋……钱不够请客。" .. name .. "看了你一眼：「不用勉强。」")
            end
            return "偶遇与改名"
        end })

        -- 一起走走反馈
        local walkLines = {
            "你们沿着小镇的石板路走了一圈。" .. name .. "走在你右边，保持着半步的距离。\n偶尔有猫从墙头跳过，他会多看两眼，然后假装什么都没发生。",
            "傍晚的风吹过来，带着远处麦田的香气。你们默默地走着。\n" .. name .. "忽然说：「这个镇子……还不错。」\n这大概是你听过他说的最温柔的话了。",
            "你带他绕到镇外的河边。水面映着晚霞，" .. name .. "靠在树干上，破天荒地没有摸剑柄。\n「以后……还能来吗？」他问得很轻。",
        }
        table.insert(choices, { text = "🚶 一起走走", action = function()
            addAffection("initialName", 10)
            TimeSystem.addMinutes(30)
            GameState.showNotification(walkLines[math.random(1, #walkLines)] .. "（好感+10）")
            return "偶遇与改名"
        end })

        table.insert(choices, { text = "整天这样叫你是不是听起来太奇怪了？", action = function()
            S.renaming = true
            S.renamed = false
            return "偶遇与改名"
        end })

        -- 约会反馈
        if (S.initialNameLevel or 1) >= 2 then
            table.insert(choices, { text = "💬 上次约会感觉怎么样？", action = function()
                addAffection("initialName", 3)
                TimeSystem.addMinutes(10)
                local dateLines = {
                    name .. "顿了一下：「……还行。」\n你盯着他看。他别开脸：「好吧，比还行好一点。」",
                    "「不讨厌。」" .. name .. "说。\n你等了一会儿。他小声补充：「……下次也行。」",
                }
                GameState.showNotification(dateLines[math.random(1, #dateLines)] .. "（好感+3）")
                return "偶遇与改名"
            end })
        end

        -- 贵族身份揭露
        if (S.initialNameLevel or 1) >= 2 and not S.nobleSecret then
            table.insert(choices, { text = "📖 聊聊我的过去", action = function()
                S.nobleSecret = true
                addAffection("initialName", 15)
                TimeSystem.addMinutes(20)
                GameState.showNotification("你把自己贵族出身的事告诉了他。" .. name .. "沉默了很久，然后说：\n「……这不重要。你现在在这里，这就够了。」（好感+15）")
                return "偶遇与改名"
            end })
        end

        -- 关键词聊天
        table.insert(choices, { text = "💬 聊聊见闻", action = function()
            S._keywordChatChar = "leiDe"
            S._keywordChatReturn = "偶遇与改名"
            return "keyword_chat_select"
        end })

        -- AI 自由对话（需要多人模式连接）
        local chatLabel = "🤖 自由对话"
        local chatClient = package.loaded["network.Client"]
        if chatClient and not chatClient.connected then
            chatLabel = "🤖 自由对话（连接中…）"
        end
        table.insert(choices, { text = chatLabel, action = function()
            local UIManager = require("systems.UIManager")
            UIManager.openChat(name)
        end })

        -- 邀请同住（条件：等级>=2，已入队，未邀请过）
        if (S.initialNameLevel or 1) >= 2 and S.initialNameInParty and not S.initialNameInvited then
            table.insert(choices, { text = "🏠 邀请" .. name .. "来家里住", action = function()
                TimeSystem.addMinutes(20)
                return "邀请同住"
            end })
        end

        -- 莱德约会（条件：等级>=2，已入住，约会可用）
        if (S.initialNameLevel or 1) >= 2 and S.initialNameAtHome and S.leiDeDateAvailable then
            table.insert(choices, { text = "🌸 邀请" .. name .. "出去约会", action = function()
                S.leiDeDateAvailable = false
                S.dateTarget = "leiDe"
                return "约会选择"
            end })
        end

        -- 游戏觉醒
        if (S.initialNameLevel or 1) >= 3 and not S.gameAware then
            table.insert(choices, { text = "🔓 他似乎想说什么...", action = function()
                S.gameAware = true
                addAffection("initialName", 20)
                TimeSystem.addMinutes(30)
                GameState.showNotification(name .. "欲言又止了好几次，最终低声说：「你有没有觉得……这个世界有时候很奇怪？」\n他的眼神前所未有地认真。（好感+20）")
                return "偶遇与改名"
            end })
        end

        -- 离开
        table.insert(choices, { text = "🔙 告辞离开", action = function()
            TimeSystem.addMinutes(1)
            return "十字路口"
        end })

        return { text = text, choices = choices }
    end
end

---===================== 邀请同住 =====================


handlers["邀请同住"] = function(S)
    local name = S.initialName or "莱德"
    local text = "你鼓起勇气，看着" .. name .. "的眼睛。\n\n"
        .. "「" .. name .. "，你一直在外面风餐露宿的……不如搬来我家住吧？」\n\n"
        .. name .. "愣住了，手中的剑差点滑落。他低下头，沉默了好一会儿。\n\n"
        .. "「……你认真的？」他的声音很轻。\n"
        .. "「当然。」你点头，「家里有空房间，而且……一个人住也挺冷清的。」\n\n"
        .. name .. "抬起头，目光闪烁着你从未见过的温度。\n"
        .. "「我没什么能回报你的。」\n"
        .. "「不需要回报。」\n\n"
        .. "他的嘴角终于浮起一丝不易察觉的笑意：\n"
        .. "「……那我就不客气了。」"

    return {
        text = text,
        choices = {
            { text = "🏠 欢迎你，" .. name, action = function()
                S.initialNameInvited = true
                S.initialNameAtHome = true
                addAffection("initialName", 25)
                GameState.showNotification(name .. "搬进了你的家！从今以后，他会住在你家里。\n家中会出现新的互动选项。(好感+25)")
                return "十字路口"
            end },
            { text = "再考虑一下……", action = function()
                addAffection("initialName", 5)
                GameState.showNotification(name .. "点了点头：「……嗯，不勉强。」他的表情有一瞬间的失落。(好感+5)")
                return "十字路口"
            end },
        },
    }
end

---===================== K入队事件 =====================


handlers["K入队事件"] = function(S)
    local text = "你在酒馆角落找到K，她正用手指转着一枚硬币。\n\n"
        .. "「K，我有件事想跟你说。」\n"
        .. "她停下手里的动作，歪着头看你：「嗯？」\n\n"
        .. "「之后如果遇到危险的事……你愿意和我一起吗？」\n\n"
        .. "K眨了眨眼，然后绽开一个大大的笑容。\n"
        .. "「你终于开口了！我等这句话等好久了！」\n"
        .. "她从吧台后跳出来，光环亮了一大截：\n"
        .. "「当然愿意！以后你去哪儿我就去哪儿！」\n\n"
        .. "辛奇在一旁擦杯子，头也不抬：「别在我店里闹。」\n"
        .. "K吐了吐舌头，拉着你的袖子往外跑。"

    return {
        text = text,
        choices = {
            { text = "⚔️ 欢迎入队，K！", action = function()
                S.kInParty = true
                addAffection("k", 20)
                GameState.showNotification("K加入了你的队伍！她的战斗属性已更新到队伍面板中。(好感+20)")
                return "商业区"
            end },
            { text = "再等等吧……", action = function()
                addAffection("k", 5)
                GameState.showNotification("K的笑容黯淡了一瞬：「……好吧，那我继续等。」(好感+5)")
                return "商业区"
            end },
        },
    }
end

---===================== 妖精的邀请 =====================
--- Twine pid 32: 忠实原文


end
