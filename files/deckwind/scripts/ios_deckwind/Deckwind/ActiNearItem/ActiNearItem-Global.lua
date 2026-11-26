local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local function activateMe(data)



end
return {
    eventHandlers = {
        doMoveInto = doMoveInto,
		doEquip = doEquip,
        returnActivators = returnActivators,
        ClickedContainer = ClickedContainer,
		CLickedActor = ClickedActor,
        containerCheck = containerCheck,
        clearContainerCheck = clearContainerCheck
    },
	engineHandlers = {onUpdate = onUpdate,onItemActive = onItemActive}
}
