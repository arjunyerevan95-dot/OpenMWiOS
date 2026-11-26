local anim = require('openmw.animation')


local ui = require("openmw.ui")
local I = require("openmw.interfaces")
--local layers = require("scripts.ios_deckwind.Deckwind.ci_layers")
local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local types = require("openmw.types")
local ambient = require('openmw.ambient')
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")

local prevStance
local active = false
local currentState
local validStates = {
    waitForIdle = 1,
    castSpell = 2,
    returnToPrev = 3
}
local castState
local started = false
local wasZero = false
local delay = 0
if true then

return {}
end
local function onFrame(dt)
    if not active then return end
    local animstate = anim.getActiveGroup(self, 3)
    if currentState == validStates.waitForIdle then
        if animstate == "idlespell" then
            currentState = validStates.castSpell
            delay = 0
            self.controls.use = 1
            wasZero = false
            return
        end
    elseif currentState == validStates.castSpell then
        if animstate == "idlespell" then
            delay = delay + dt
            if self.controls.use == 1 and not wasZero then
                wasZero = true
            else
                self.controls.use = 0

                types.Actor.setStance(self, prevStance)
                active = false
                currentState = nil
                I.Controls.overrideCombatControls(false)
                return
            end
            if delay > 0.2 or started then

                types.Actor.setStance(self, prevStance)
                active = false
                currentState = nil
                I.Controls.overrideCombatControls(false)
            end
        elseif animstate == "spellcast" then
            started = true
            self.controls.use = 0
        end
    end
end

local function doQuickCast()
    active = true
    started = false
    prevStance = types.Actor.getStance(self)
    types.Actor.setStance(self, types.Actor.STANCE.Spell)
    currentState = validStates.waitForIdle
    I.Controls.overrideCombatControls(true)
end
local function onKeyPress(key)
    if key.symbol == "u" then
        doQuickCast()
    end
end

local leftPressed = false

local rightPressed = false

local function onControllerButtonRelease(id)
    if id == input.CONTROLLER_BUTTON.LeftShoulder then
        if rightPressed and leftPressed then
            doQuickCast()
            rightPressed = false
            leftPressed = false
        end
    elseif id == input.CONTROLLER_BUTTON.RightShoulder then

    else
        rightPressed = false
        leftPressed = false
    end
end
local function onControllerButtonPress(id)
    if id == input.CONTROLLER_BUTTON.LeftShoulder then
        leftPressed = true
    elseif id == input.CONTROLLER_BUTTON.RightShoulder then
        rightPressed = true
    end
end

return {
    interfaceName = "CI_QuickCast",
    interface = {
        version = 1,
        doQuickCast = doQuickCast,



    },
    eventHandlers = {
        CI_objectUpdated = objectUpdated
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onFrame = onFrame,
        onActive = onActive,
        onControllerButtonPress = onControllerButtonPress,
        onInputAction = onInputAction,
        onKeyPress = onKeyPress,
        onLoad = onLoad,
        onControllerButtonRelease = onControllerButtonRelease,
    }
}
