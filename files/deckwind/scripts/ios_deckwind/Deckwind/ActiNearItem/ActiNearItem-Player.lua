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
local input = require("openmw.input")
local storage = require("openmw.storage")

local Actor = require("openmw.types").Actor
local myModData = storage.globalSection("MundisData")
local tooltipgen = require("scripts.ios_deckwind.Deckwind.ci_tooltipgen")
local PLAYER_WIDTH = 100
local activationDist = 30
local uithing

local const = require("scripts.ios_deckwind.Deckwind.ci_const")
if not const.doesRun or true then
    return {}
end
local itemWindowLocs = {
    TopLeft = { wx = 0, wy = 0, align = ui.ALIGNMENT.Start, anchor = nil },
    TopRight = { wx = 1, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0) },
    Right = { wx = 1, wy = 0.5, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0.5) },
    Left = { wx = 0, wy = 0.5, align = ui.ALIGNMENT.Start, anchor = util.vector2(0, 0.5) },
    Center = { wx = 0.5, wy = 0.5, align = ui.ALIGNMENT.Center, anchor = util.vector2(0.5, 0.5) },
    Centerish = { wx = 0.5, wy = 0.3, align = ui.ALIGNMENT.Center, anchor = util.vector2(0.5, 0.5) },
    BottomLeft = { wx = 0, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0, 1) },
    BottomRight = { wx = 1, wy = 1, align = ui.ALIGNMENT.Start, anchor = util.vector2(1, 1) },
    BottomCenter = { wx = 0.5, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 1) },
    TopCenter = { wx = 0.5, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 0) },
    Disabled = { disabled = true }
}

local function renderItem(item)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item.recordId,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end
local function getCameraDirData()
    local pos = Camera.getPosition()
    local pitch, yaw

    pitch = -(Camera.getPitch() + Camera.getExtraPitch())
    yaw = (Camera.getYaw() + Camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end
local function isSelf(t)
    return t == self.object
end
local function getObjInCrosshairs()
    local pos, v = getCameraDirData()
    local dist = 110
    local result = nearby.castRenderingRay(pos, pos + v * dist)
    -- Ignore player if in 3rd person
    if result.hitObject and isSelf(result.hitObject) then
        result = nearby.castRenderingRay(result.hitPos + v * PLAYER_WIDTH, result.hitPos + v * (PLAYER_WIDTH + dist))
    end

    -- Get approximated area. Note that this allows you to aim through walls, because we can't distinguish floor and wall
    if (result.hisPos == nil) then
        return { item = result.hitObject, pos = pos + v * dist }
    else
        return { item = result.hitObject, pos = result.hitPos }
    end
end
local function renderItemBold(item, bold)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = item,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItem(item, bold)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = item,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function FindName(item)
    if (item == nil) then
        return nil
    end
    if not item.type.records then
        return nil
    end
    return item.type.records[item.recordId].name
end
local function renderItemChoice(itemList, currentItem, small)
    local vertical = 0
    local horizontal = ui.layers[1].size.x / 2 - 100
    if (small == true) then
        horizontal = ui.layers[1].size.x / 2 - 25
        vertical = vertical + ui.layers[1].size.y / 2 - 100
    else
    end
    local content = {}
    for _, item in ipairs(itemList) do
        if item == currentItem then
            local itemLayout = renderItemBold(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        else
            local itemLayout = renderItem(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    return ui.create {
        layer = "HUD",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            --  anchor = v2(-1, -2),
            position = v2(horizontal, vertical),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = ui.ALIGNMENT.Center
                }
            }
        }
    }
end
local nearestItem = nil
local timePast = 0.0
local function onFrame(dt)
    timePast = timePast + dt
    if (timePast < 0.1) then
        return
    else
        timePast = 0
    end
    nearestItem = nil
    local obj = getObjInCrosshairs()
    if (uithing) then
        uithing:destroy()
    end
    if (obj.item and FindName(obj.item)) then
        if uithing then
            uithing:destroy()
        end
        uithing = nil
    elseif (obj.pos and FindName(obj.item) == nil) then
        local point = obj.pos
        nearestItem = nil
        local nearestDistance = math.huge
        for i, tableItem in ipairs(nearby.items) do
            local distance = (tableItem.position - point):length()
            if distance < nearestDistance and FindName(tableItem) and distance < activationDist then
                nearestDistance = distance
                nearestItem = tableItem
            end
        end
        if nearestItem and nearestItem ~= obj.item then
            if obj.item then
                if obj.item.type.records and obj.item.type.records[obj.item.recordId].value ~= nil then
                    return
                elseif obj.item.type.records and obj.item.type.records[obj.item.recordId].name == nil then
                    return
                end
            end
            if obj.item then
                print(obj.item.recordId)
            end
            uithing = I.ZackUtilsUI_ci.drawListMenu(tooltipgen.genToolTips(nearestItem),
                itemWindowLocs.Centerish, nil, "HUD")
            nearestItem = nil
        end
    end
end
local function onInputAction(id)
    if core.isWorldPaused() then
        return
    end
    if id == input.ACTION.Activate and nearestItem then
        local itemToActivate = getObjInCrosshairs()
        if itemToActivate and itemToActivate.type.record(itemToActivate).name then
            return
        end
        nearestItem:activateBy(self)
    end
end
return {
    eventHandlers = {
        sendMessage = sendMessage,
        returnActivators = returnActivators,
        recieveActivators = recieveActivators
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onFrame = onFrame,
        onInputAction = onInputAction
    }
}
