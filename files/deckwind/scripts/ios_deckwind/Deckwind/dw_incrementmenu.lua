if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local core_aux = require("scripts.ios_deckwind.Deckwind.aux_core")
local renderStatBar = require("scripts.ios_deckwind.Deckwind.renderStatBar")
local function drawIncrementMenu(min,max,current)

end
return {
    interfaceName = "CI_IncrementMenu",
    interface = {
        version = 1,
        drawMenuSelect = drawMenuSelect,
        destroyElements = destroyElements,
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    },
    engineHandlers = {
    }
}}
