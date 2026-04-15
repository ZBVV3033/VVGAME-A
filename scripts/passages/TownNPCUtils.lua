-- ============================================================================
-- TownNPCUtils.lua - NPC段落生成器，消除重复结构
-- ============================================================================

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local kwOk, KW = pcall(require, "systems.KeywordSystem")

local U = {}

--- 生成"遇见NPC"段落 handler
---@param cfg { var:string, name:string, aff:number?, time:number?, loc:string, logDesc:string, keywords:string[]?, text:string, choices:table? }
function U.meet(cfg)
    return function()
        local S = GameState.state
        S[cfg.var .. "Met"] = true
        S[cfg.var] = (S[cfg.var] or 0) + (cfg.aff or 5)
        TimeSystem.addMinutes(cfg.time or 5)
        GameState.addDateLog(cfg.name, "初遇", cfg.logDesc)
        if cfg.keywords and kwOk then
            for _, kw in ipairs(cfg.keywords) do KW.collectKeyword(kw) end
        end
        return {
            text = cfg.text,
            choices = cfg.choices or { { text = "继续", target = S._settingsFrom or cfg.loc } },
        }
    end
end

--- 生成"闲聊/卖画/故事"段落 handler（随机台词）
---@param cfg { var:string, aff:number?, time:number?, loc:string, talks:table[] }
function U.chat(cfg)
    return function()
        local S = GameState.state
        S[cfg.var] = (S[cfg.var] or 0) + (cfg.aff or 3)
        TimeSystem.addMinutes(cfg.time or 5)
        local talk = cfg.talks[math.random(1, #cfg.talks)]
        return {
            text = talk.text,
            choices = { {
                text = "继续",
                target = S._settingsFrom or cfg.loc,
                action = talk.extraAction,
            } },
        }
    end
end

--- 生成"特殊遭遇"段落 handler（固定文本 + 好感 + 可选效果）
---@param cfg { var:string, aff:number?, time:number?, loc:string, text:string, extraAction:function? }
function U.event(cfg)
    return function()
        local S = GameState.state
        S[cfg.var] = (S[cfg.var] or 0) + (cfg.aff or 5)
        TimeSystem.addMinutes(cfg.time or 10)
        if cfg.extraAction then cfg.extraAction() end
        return {
            text = cfg.text,
            choices = { { text = "继续", target = cfg.loc } },
        }
    end
end

--- 生成"治安事件"段落 handler（战斗类）
---@param cfg { time:number?, text:string, enemy:string, returnTo:string, fightText:string?, fleeText:string?, fleeAction:function? }
function U.battle(cfg)
    local BattleSystem = require("systems.BattleSystem")
    return function()
        local S = GameState.state
        TimeSystem.addMinutes(cfg.time or 5)
        local choices = {
            {
                text = cfg.fightText or "⚔️ 迎战！",
                action = function()
                    S.battleSource = "town"
                    S.townBattleReturnTo = cfg.returnTo
                    S.townBattleToday = (S.townBattleToday or 0) + 1
                    BattleSystem.startBattleWith({ cfg.enemy })
                    BattleSystem.processEnemyTurnsUntilPlayer()
                    return "战斗"
                end,
            },
        }
        if cfg.fleeText then
            if cfg.fleeAction then
                choices[2] = { text = cfg.fleeText, action = cfg.fleeAction }
            else
                choices[2] = { text = cfg.fleeText, target = cfg.returnTo }
            end
        end
        return { text = cfg.text, choices = choices }
    end
end

return U
