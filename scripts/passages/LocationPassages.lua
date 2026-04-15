-- passages/LocationPassages.lua
-- Split into sub-modules under passages/location/

local GameState = require("systems.GameState")
local TimeSystem = require("systems.TimeSystem")
local NPCSystem = require("systems.NPCSystem")
local WorkSystem = require("systems.WorkSystem")
local HomeSystem = require("systems.HomeSystem")
local MainQuest = require("systems.MainQuest")
local CommonUtils = require("utils.CommonUtils")
local PassageDeps = require("passages.PassageDeps")

local addAffection = CommonUtils.addAffection
local addDateLog = CommonUtils.addDateLog
local doWorkWithEvent = PassageDeps.doWorkWithEvent
local isLeiDeHome = PassageDeps.isLeiDeHome

local handlers = {}

local deps = {
    GameState = GameState, TimeSystem = TimeSystem,
    NPCSystem = NPCSystem, WorkSystem = WorkSystem,
    HomeSystem = HomeSystem, MainQuest = MainQuest,
    CommonUtils = CommonUtils, PassageDeps = PassageDeps,
    addAffection = addAffection, addDateLog = addDateLog,
    doWorkWithEvent = doWorkWithEvent, isLeiDeHome = isLeiDeHome,
}

require("passages.location.Crossroads")(handlers, deps)
require("passages.location.CommercialDistrict")(handlers, deps)
require("passages.location.Harbor")(handlers, deps)
require("passages.location.GardenTown")(handlers, deps)
require("passages.location.Slums")(handlers, deps)
require("passages.location.MainCity")(handlers, deps)

return handlers
