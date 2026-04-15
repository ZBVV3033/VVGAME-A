-- passages/PassageDeps.lua
-- 段落子模块共享的工具函数和静态数据
-- 独立模块，无循环依赖
local GameState = require("systems.GameState")
local WorkSystem = require("systems.WorkSystem")

local M = {}

----- 工具函数 -----

function M.addOamelAffection(amount)
    local S = GameState.state
    S.oamelAffection = (S.oamelAffection or 0) + amount
end

function M.addMeifeiAffection(amount)
    local S = GameState.state
    S.meifeiAffection = (S.meifeiAffection or 0) + amount
end

function M.addMannerExp(amount)
    local S = GameState.state
    S.mannerExp = (S.mannerExp or 0) + amount
end

function M.addHistoryExp(amount)
    local S = GameState.state
    S.historyExp = (S.historyExp or 0) + amount
end

function M.isLeiDeHome()
    local S = GameState.state
    return S.initialNameAtHome and not (S.hour >= 22 or S.hour < 6)
end

function M.doWorkWithEvent(jobType, withLeiDe)
    local S = GameState.state
    local baseMsg, event = WorkSystem.doWorkWithEvent(jobType, withLeiDe or false)
    if event then
        S._workEvent = event
        S._workEventBase = baseMsg
        S._workEventJob = jobType
        S._workEventWithLeiDe = withLeiDe or false
        return "打工事件"
    end
    S._workResultMsg = baseMsg .. "\n\n平静地度过了一小时，没有什么特别的事发生。"
    return "打工结果"
end

function M.readBook(bookType)
    local S = GameState.state
    if bookType == "manner" then
        if not S.mannerFirstReward then
            S.mannerFirstReward = true
            S.ML = (S.ML or 3) + 1
            return "读完《贵族礼仪入门》，魅力+1！"
        else
            return "你复习了礼仪知识。"
        end
    elseif bookType == "history" then
        if not S.historyFirstReward then
            S.historyFirstReward = true
            S.ZL = (S.ZL or 1) + 1
            return "读完《日轮王国贵族名录》，智力+1！"
        else
            return "你复习了历史知识。"
        end
    elseif bookType == "osmia" then
        if not S.osmiaFirstReward then
            S.osmiaFirstReward = true
            S.ZL = (S.ZL or 1) + 2
            return "读完《奥丝米娅时代的历史》，智力+2！"
        else
            return "你复习了奥丝米娅时代的历史。"
        end
    end
    return "你翻阅了一会儿书。"
end

----- 静态数据 -----

M.dateScenes = {
    leiDe = {
        ["十字路口"] = {
            desc = function(name)
                return string.format("你和%s在十字路口的长椅上坐下。夕阳西下，街道渐渐安静下来。", name)
            end,
            options = {
                {text = "「这里真安静。」", affection = 5, reply = "他点点头：「嗯。喜欢这里。」"},
                {text = "「想去别的地方走走吗？」", affection = 3, reply = "「这里就好。」他看着远方。"},
                {text = "默默陪他坐着", affection = 8, reply = "你们安静地坐着，肩膀碰在一起。"}
            }
        },
        ["主城区"] = {
            desc = function(name)
                return string.format("你和%s走在主城区的街道上。两旁是精致的橱窗和古老的建筑。", name)
            end,
            options = {
                {text = "「想逛逛书店吗？」", affection = 5, reply = "他的眼睛亮了一下：「...好。」"},
                {text = "「肚子饿了，吃点东西？」", affection = 3, reply = "「随你。」但你注意到他看了一眼面包店。"},
                {text = "「这里真繁华。」", affection = 4, reply = "「嗯。」他看着人群，「比我习惯的地方热闹多了。」"}
            }
        },
        ["港口"] = {
            desc = function(name)
                return string.format("你和%s走到码头边。海风吹起他的头发，他眯着眼看着远方。", name)
            end,
            options = {
                {text = "「海很大。」", affection = 5, reply = "「嗯。」他停顿了一下，「以后可以常来。」"},
                {text = "「你以前见过海吗？」", affection = 3, reply = "「...在书上。」他顿了顿，「实物比较好。」"},
                {text = "安静地站在他身边", affection = 8, reply = "你们并肩站着，看着夕阳沉入海面。他的手指碰了碰你的。"}
            }
        },
        ["咖啡店"] = {
            desc = function(name)
                return string.format("你和%s坐在咖啡店的角落里。他盯着杯子里的拉花看了很久。", name)
            end,
            options = {
                {text = "「好喝吗？」", affection = 5, reply = "「...甜的。」他又喝了一口，「下次多点糖。」"},
                {text = "「你喜欢什么口味？」", affection = 3, reply = "「不挑。」他想了想，「但偏甜。」"},
                {text = "给他点一份蛋糕", affection = 8, reply = "他看着蛋糕，嘴角动了动。然后默默吃完，连碎屑都没剩。"}
            }
        },
        ["花园"] = {
            desc = function(name)
                return string.format("你和%s走进花园小镇边的林荫小道。阳光透过树叶洒下斑驳的光影，他的脚步不自觉慢了下来。", name)
            end,
            options = {
                {text = "「这里的花真好看。」", affection = 5, reply = "他瞥了一眼路边的野花：「...还行。」但脚步停了下来。"},
                {text = "摘一朵花递给他", affection = 8, reply = "他愣了一下，接过花看了半天：「...我又不是女的。」但还是小心地别在了袖口。"},
                {text = "安静地一起散步", affection = 10, reply = "你们沿着小路走了很远。回去的路上，他忽然说：「下次还来。」"}
            }
        },
        ["漫步"] = {
            desc = function(name)
                return string.format("你和%s漫无目的地走着。他双手插在口袋里，偶尔抬头看看天空。", name)
            end,
            options = {
                {text = "「在想什么？」", affection = 5, reply = "「...没想什么。」他顿了顿，「就是觉得挺好的。」"},
                {text = "故意走快一点", affection = 3, reply = "他跟上来，瞪了你一眼：「你赶时间？」但嘴角有点翘。"},
                {text = "放慢脚步陪他", affection = 8, reply = "你们的步伐渐渐同步。他没说话，但肩膀靠得更近了。"}
            }
        },
        ["在家"] = {
            desc = function(name, candles)
                local c = candles or 0
                if c >= 3 then
                    return string.format("房间里点着%d根蜡烛，烛光摇曳。%s坐在窗边，表情比平时柔和。", c, name)
                else
                    return string.format("房间里有些暗。%s坐在桌边，手指无意识地敲着桌面。", name)
                end
            end,
            options = {
                {text = "「在想什么？」", affection = 5, reply = "「...没什么。」他顿了顿，「在家挺好。安静。」"},
                {text = "「饿了吗？我做点吃的。」", affection = 8, reply = "他看着你忙碌的背影，声音很轻：「...谢谢。」"},
                {text = "安静地坐在他旁边", affection = 10, reply = "你们就这样坐着，很久很久。他的肩膀慢慢靠了过来。"}
            }
        },
    },
    k = {
        ["港口"] = {
            desc = function(name)
                return "K牵着你的手走到码头边。海风吹起她的头发，光环在夕阳下闪闪发光。"
            end,
            options = {
                {text = "「海很美。」", affection = 5, reply = "「是啊，」她靠近你，「和你一起看更美。」"},
                {text = "「你的光环真漂亮。」", affection = 8, reply = "她脸红了：「只是普通的精灵光环啦...」"},
                {text = "握紧她的手", affection = 10, reply = "她愣了一下，然后回握你，笑得很甜。"}
            }
        },
        ["花园"] = {
            desc = function(name)
                return "K拉着你走进花园小镇边的田野。她蹲下来摘了一朵野花别在耳边。"
            end,
            options = {
                {text = "「好看。」", affection = 5, reply = "她转了一圈：「真的吗？」笑得像个孩子。"},
                {text = "也摘一朵给她", affection = 8, reply = "她接过花，眼睛亮亮的：「我会好好保存的。」"},
                {text = "「下次一起种花吧。」", affection = 10, reply = "「好！」她兴奋地拉着你的袖子，「我知道一个好地方！」"}
            }
        },
        ["咖啡店"] = {
            desc = function(name)
                return "K坐在你对面，手捧着热可可，鼻尖沾着一点奶泡。她完全没注意到。"
            end,
            options = {
                {text = "帮她擦掉", affection = 10, reply = "她愣住了，脸「唰」地红了：「你、你干嘛...」但没躲开。"},
                {text = "「你鼻子上有东西。」", affection = 5, reply = "她手忙脚乱地擦，越擦越多，最后噗嗤笑出来。"},
                {text = "装作没看见", affection = 3, reply = "她喝完才发现，瞪了你一眼：「你故意的！」"}
            }
        },
        ["漫步"] = {
            desc = function(name)
                return "你和K漫无目的地走着。她哼着小曲，光环随着旋律微微闪烁。"
            end,
            options = {
                {text = "「你唱的是什么歌？」", affection = 5, reply = "「精灵族的摇篮曲。」她笑，「小时候妈妈唱的。」"},
                {text = "跟着哼", affection = 8, reply = "她惊讶地看着你，然后笑了：「音准不太行，但...很好听。」"},
                {text = "牵她的手", affection = 10, reply = "她的手指扣紧你的，什么也没说，但光环亮了一点。"}
            }
        },
    }
}

M.banquetThemes = {
    masquerade = {
        name = "假面舞会",
        desc = "今晚是假面舞会，所有人都戴着华丽的面具。",
        outfits = {
            {key = "formal", name = "黑色燕尾服配银色面具", matchBonus = 100, matchDesc = "你的装扮很得体。"},
            {key = "casual", name = "普通礼服配简单面具", failBonus = 30, matchDesc = "装扮过于朴素。"}
        },
        events = {
            {name = "与贵妇人跳舞", successText = "你优雅地完成了舞步，贵妇人很满意。", tip = 50, oamel = 5}
        }
    },
    revelry = {
        name = "盛宴之夜",
        desc = "今晚是传统的盛宴之夜，长桌上摆满了珍馐佳肴。",
        outfits = {
            {key = "formal", name = "金色刺绣礼服", matchBonus = 80, matchDesc = "华丽的装扮让你很引人注目。"},
            {key = "casual", name = "干净的白衬衫", failBonus = 20, matchDesc = "太简朴了。"}
        },
        events = {
            {name = "品酒评鉴", successText = "你准确说出了酒的年份，在座的贵族纷纷点头。", tip = 60, oamel = 3}
        }
    },
    flower = {
        name = "花之夜",
        desc = "今晚以花为主题，大厅装饰着各色鲜花，空气中弥漫着花香。",
        outfits = {
            {key = "formal", name = "绣有花纹的深蓝礼服", matchBonus = 90, matchDesc = "花纹与主题完美呼应。"},
            {key = "casual", name = "带一朵胸花的普通服装", failBonus = 25, matchDesc = "至少你有一朵花。"}
        },
        events = {
            {name = "花艺展示", successText = "你即兴的花束搭配获得了赞赏。", tip = 40, oamel = 4}
        }
    },
    hunt = {
        name = "猎人之夜",
        desc = "今晚的主题是狩猎，墙上挂着各种猎物标本，贵族们争相炫耀战绩。",
        outfits = {
            {key = "formal", name = "皮质猎装配长靴", matchBonus = 100, matchDesc = "你看起来像个经验丰富的猎人。"},
            {key = "casual", name = "普通衣服", failBonus = 15, matchDesc = "完全不搭。"}
        },
        events = {
            {name = "射箭比赛", successText = "你的箭正中靶心，引来一阵喝彩。", tip = 70, oamel = 5}
        }
    },
}

M.topicData = {
    ["猫咖啡店"] = {
        name = "猫咖啡店",
        desc = "聊聊十字路口新开的猫咖啡店",
        interest = {leiDe = true, k = true}
    }
}

M.topicDialogues = {
    ["猫咖啡店"] = {
        start = {
            text = function(name) return string.format("%s听你说起猫咖啡店，眼睛亮了一下。", name) end,
            options = {
                {text = "「想去看看吗？」", next = "invite"},
                {text = "「你喜欢猫？」", next = "like_cats"}
            }
        },
        invite = {
            text = "「...可以吗？」他有些期待。",
            next = "end_node"
        },
        like_cats = {
            text = "「不讨厌。」他顿了顿，「软软的。」",
            next = "end_node"
        },
        end_node = {
            text = "话题告一段落，你们心情都不错。",
            next = "end"
        }
    }
}

return M
