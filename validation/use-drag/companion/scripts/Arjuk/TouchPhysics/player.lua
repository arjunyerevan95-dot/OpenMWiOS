-- Load AFTER LuaPhysicsEngine.omwscripts. Does not replace the user's
-- configured Drag Object binding; it adds the touch overlay's reserved input.
local input = require('openmw.input')
local async = require('openmw.async')
input.bindAction('GrabPhysicsObject', async:callback(function(_, existing)
    return existing or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.Misc1)
end), {})
return {}
