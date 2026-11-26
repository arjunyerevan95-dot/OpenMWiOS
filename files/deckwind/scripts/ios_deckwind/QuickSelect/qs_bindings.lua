local input = require('openmw.input')


local bindings = {}

local createdBindings = {}
bindings.addBinding = function(bindingName, key, ctrl)
    createdBindings[bindingName] = { key = key, ctrl = ctrl }
end
bindings.isPressed = function(bindingName, providedKeyCode, providedCtrlCode)
    if not createdBindings[bindingName] then
        return false
    end
    local requestedBinding = createdBindings[bindingName]
    if providedKeyCode then
        for index, value in ipairs(requestedBinding.key) do
            if value == providedKeyCode then
                return true
            end
        end
    end
    if providedCtrlCode then
        for index, value in ipairs(requestedBinding.ctrl) do
            if value == providedKeyCode then
                return true
            end
        end
    end
    return false
end

bindings.addBinding("next", { input.KEY.RightArrow },
    { input.CONTROLLER_BUTTON.RightShoulder, input.CONTROLLER_BUTTON.DPadRight })

bindings.addBinding("prev", { input.KEY.LeftArrow },
    { input.CONTROLLER_BUTTON.LeftShoulder, input.CONTROLLER_BUTTON.DPadLeft })
return bindings
