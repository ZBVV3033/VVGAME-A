-- passages/NPCEventPassages.lua
-- Split into sub-modules under passages/npc_event/

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local WorkSystem = require("systems.WorkSystem")
local CommonUtils = require("utils.CommonUtils")
local PassageDeps = require("passages.PassageDeps")

local addAffection = CommonUtils.addAffection
local addDateLog = CommonUtils.addDateLog
local addOamelAffection = PassageDeps.addOamelAffection
local addMeifeiAffection = PassageDeps.addMeifeiAffection
local addHistoryExp = PassageDeps.addHistoryExp
local dateScenes = PassageDeps.dateScenes
local banquetThemes = PassageDeps.banquetThemes
local readBook = PassageDeps.readBook
local handlers = {}

local handlers = {}

local deps = {
    GameState = GameState,
    TimeSystem = TimeSystem,
    WorkSystem = WorkSystem,
    CommonUtils = CommonUtils,
    PassageDeps = PassageDeps,
    addAffection = addAffection,
    addDateLog = addDateLog,
    addOamelAffection = addOamelAffection,
    addMeifeiAffection = addMeifeiAffection,
    addHistoryExp = addHistoryExp,
    dateScenes = dateScenes,
    banquetThemes = banquetThemes,
    readBook = readBook,
    handlers = handlers,
}

require("passages.npc_event.MeetAndRename")(handlers, deps)
require("passages.npc_event.FairyInvitation")(handlers, deps)
require("passages.npc_event.BanquetCat")(handlers, deps)
require("passages.npc_event.DateAppearance")(handlers, deps)

return handlers
