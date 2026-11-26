if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local cam, camera, core, self, nearby, types, ui, util, storage, async, input, debug =
    require('openmw.interfaces').Camera, require('openmw.camera'),
    require('openmw.core'), require('openmw.self'),
    require('openmw.nearby'), require('openmw.types'),
    require('openmw.ui'), require('openmw.util'),
    require("openmw.storage"), require("openmw.async"),
    require("openmw.input"),
    require("openmw.debug")

local const = require("scripts.ios_deckwind.Deckwind.ci_const")

if not const.doesRun then
    return {}
end
local delay = 0
local fstage
local function onFrame()
    if delay > 0 then
        delay = delay - 1
        if delay == 0 then
            if fstage == 1 then
                core.sendGlobalEvent("bounceBack1")
            else
                core.sendGlobalEvent("bounceBack2")
            end
        end
    end
end
return {

    interfaceName = "CrimeSystem",
    interface = {
        hackCrime = function(amount)
            core.sendGlobalEvent("hackCrime", amount)
        end
    },
    engineHandlers = {
        onFrame = onFrame,

    },
    eventHandlers = {
        bounceBack = function(stage)
            fstage = stage
            if stage == 1 then
                delay = 10
            elseif stage == 2 then
                delay = 10
            end
        end
    }
}
