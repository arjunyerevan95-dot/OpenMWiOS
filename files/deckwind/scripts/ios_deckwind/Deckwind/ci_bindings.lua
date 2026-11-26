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
local bindings = {}
local function registerBinding(bindingName, controllerButton, keyId,shortDesc)
    bindings[bindingName:lower()] = { key = keyId, controllerButton = controllerButton ,shortDesc = shortDesc}
end
local passedKey, passedCtrl = nil, nil
local function passInput(ctrl, key)
    passedKey = key
    passedCtrl = ctrl
end
local function clearInput()
    passedKey = nil
    passedCtrl = nil
end
local function checkBinding(bindingName, controllerButton, keyId)
    local binding = bindings[bindingName:lower()]

    if controllerButton and binding.controllerButton == controllerButton then
        return true
    elseif keyId and binding.key == keyId then
        return true
    elseif passedCtrl and binding.controllerButton == passedCtrl then
        clearInput()
        return true
    elseif passedKey and binding.key == passedKey then
        clearInput()
        return true
    end
    if (controllerButton or keyId or passedKey or passedCtrl) then return false end
    if (input.isControllerButtonPressed(binding.controllerButton)) then
        return true
    elseif input.isKeyPressed(binding.key) then
        return true
    end
    return false
end
local function getButtonLabel(bindingName, controllerMode)

end
local function getBindingDesc(bindingName)

    local binding = bindings[bindingName:lower()]

    if(binding) then
        return binding.shortDesc
    end
end
return {
    interfaceName = "CI_Bindings",
    interface = {
        version = 1,
        registerBinding = registerBinding,
        checkBinding = checkBinding,
        getBindingDesc = getBindingDesc,
        getButtonLabel = getButtonLabel,
    },
    eventHandlers = {

    },
    engineHandlers = {
    }
}
