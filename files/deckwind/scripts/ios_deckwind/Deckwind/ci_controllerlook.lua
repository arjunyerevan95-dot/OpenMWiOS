local input = require("openmw.input")
local camera = require("openmw.camera")

local self = require("openmw.self")
local lastXAxis = 0

local lastYAxis = 0
if true then
    return {}
end
local cameraSensitivity = 0.01 -- Control sensitivity
local function onUpdate(dt)

    local trigger = input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)

local multiplier = 1
if trigger > 0.1 then
    multiplier = 0.3
end
    local xAxisCurr = input.getAxisValue(input.CONTROLLER_AXIS.RightX) + (input.getMouseMoveX() * 0.1)
    local yAxisCurr = input.getAxisValue(input.CONTROLLER_AXIS.RightY) + (input.getMouseMoveY()  * 0.1)

    local deadzone = 0.1 -- Slightly larger deadzone for more stability
    local invertY = false -- True to invert Y-axis
    local x,y,z = self.rotation:getAnglesZYX()
    if x ~= camera.getYaw() then
        camera.setYaw(x)
    end
    -- OpenMW-like settings
    local cameraSensitivity = 0.8
    cameraSensitivity = cameraSensitivity * multiplier -- Base sensitivity, adjust to match OpenMW's feel
    local accelerationRate = 3.0 -- Controls how quickly the speed ramps up
    local maxSpeedMultiplier = 5.0 -- The maximum speed relative to the initial movement speed

    -- Apply deadzone
    xAxisCurr = math.abs(xAxisCurr) < deadzone and 0 or xAxisCurr
    yAxisCurr = math.abs(yAxisCurr) < deadzone and 0 or yAxisCurr

    -- Implement a non-linear acceleration curve for more precise control at lower speeds and quicker turns at higher speeds
    local function calculateSpeedMultiplier(axisValue)
        local absValue = math.abs(axisValue)
        return 1 + (maxSpeedMultiplier - 1) * (absValue ^ accelerationRate)
    end

    local speedMultiplierX = calculateSpeedMultiplier(xAxisCurr)
    local speedMultiplierY = calculateSpeedMultiplier(yAxisCurr)

    -- Adjust yaw and pitch based on current stick position, acceleration, and sensitivity
    local yawAdjustment = xAxisCurr * cameraSensitivity * speedMultiplierX * dt
    local pitchAdjustment = yAxisCurr * cameraSensitivity * speedMultiplierY * dt * (invertY and -1 or 1)

    -- Update camera's orientation
    camera.setYaw(camera.getYaw() + yawAdjustment)
    camera.setPitch(camera.getPitch() + pitchAdjustment)
    self.controls.pitchChange = pitchAdjustment
    self.controls.yawChange = yawAdjustment
end

local function onLoad()
    input.setControlSwitch(input.CONTROL_SWITCH.Looking, false)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onLoad = onLoad,
    }
}
