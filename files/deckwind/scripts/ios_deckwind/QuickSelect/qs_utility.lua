local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")

local itemWindowLocs = {
    TopLeft = { wx = 0, wy = 0, align = ui.ALIGNMENT.Start, anchor = nil },
    TopRight = { wx = 1, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0) },
    Right = { wx = 1, wy = 0.5, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0.5) },
    Left = { wx = 0, wy = 0.5, align = ui.ALIGNMENT.Start, anchor = util.vector2(0, 0.5) },
    BottomLeft = { wx = 0, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0, 1) },
    BottomRight = { wx = 1, wy = 1, align = ui.ALIGNMENT.Start, anchor = util.vector2(1, 1) },
    BottomCenter = { wx = 0.5, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 1) },
    TopCenter = { wx = 0.5, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 0) },
    Disabled = { disabled = true }
}
local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end

local function getEnchantment(id) --
    if not id then
        return end
    return core.magic.enchantments.records[id]
end
local function FindEnchantment(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].enchant == nil or item.type.records[item.recordId].enchant == "") then
        return nil
    end
    return getEnchantment(item.type.records[item.recordId].enchant)
end
local function calculateTextScale()
    local screenSize = ui.screenSize()
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    return scale
end

local scale = 0.8
local iconSize = 30

local function imageContent(resource, size)
    if (size == nil) then
        size = iconSize
    end

    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = util.vector2(size, size)
            -- relativeSize = util.vector2(1,1)
        }
    }
end

local function renderItemWithIcon(item, bold, icon)
    local resource = ui.texture { -- texture in the top left corner of the atlas
        path = icon
    }
    return {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxSolid,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    imageContent(resource, calculateTextScale() * 10),
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            anchor = util.vector2(0, 0),
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function scaledVector2(x, y)
    return util.vector2(x * scale, y * scale)
end
local function renderItemX(item, bold, fontSize)
    if not fontSize then
        fontSize = 10
    end
    fontSize = fontSize * calculateTextScale()
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
                            textSize = fontSize,
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemChoiceX(itemList, horizontal, vertical, align, anchor, layer, fontSize)
    local content = {}
    for _, item in ipairs(itemList) do
        if type(item) == "string" then
            local itemLayout = renderItemX(item, nil, fontSize)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        elseif type(item) == "table" then
            local text = item.text
            local icon = item.icon
            local itemLayout = renderItemWithIcon(text, false, icon)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    return ui.create {
        layer = layer or "InventoryWindow",
        template = I.MWUI.templates.boxSolid,
        props = {
            -- relativePosition = util.vector2(0.65, 0.8),
            anchor = anchor,
            relativePosition = util.vector2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,

                    arrange = ui.ALIGNMENT.Center,
                    align = align,
                }
            }
        }
    }
end
local function drawListMenu(buttonTable, winLoc, prevWindow, layer, fontSize, extraContent)
    if (prevWindow) then
        prevWindow:destroy()
        prevWindow = nil
    end
    local wx = 0
    local wy = 0
    local align = nil
    local anchor = nil
    local config = itemWindowLocs[winLoc] or winLoc

    if not config or config.disabled then
        -- Handle the disabled case
        return
    else
        wx = config.wx
        wy = config.wy
        align = config.align
        anchor = config.anchor
        -- Now, use wx, wy, align, and anchor as needed
    end
    return renderItemChoiceX(buttonTable, wx, wy, align, anchor, layer, fontSize)
end
local function renderItemBold(item, bold, id, tooltipData, isSpell, spellData,events)
    if not id then id = item end
    local textTemplate = I.MWUI.templates.textNormal
    if  bold or (spellData and spellData.bold )then
        textTemplate = I.MWUI.templates.textHeader
    end

    return {
        id = "renderItemBold",
        type = ui.TYPE.Container,
        tooltipData = tooltipData,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = textTemplate,
                        props = {
                            text = item,
                            textSize = 20 * scale,
                            relativePosition = util.vector2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                            spellData = spellData,
                        },
                        events = events,
                    }
                }
            }
        }
    }
end


local function flexedItems(content, horizontal,anchor)
    if not horizontal then
        horizontal = false
    end
    return ui.content {
        {
            id = "flexeditems",
            type = ui.TYPE.Flex,
            content = ui.content(content),
            events = {
                --    mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
                --     size = util.vector2(100, 100),
                autosize = true,
                relativePosition = anchor,
                anchor = anchor
            }
        }
    }
end

local function renderItemBoxed(content, size, itemTemplate, relativePosition, data,events)
    local text

    if data then

    end
    if not size then
        size = scaledVector2(100, 100)
    end
    if not itemTemplate then
        itemTemplate = I.MWUI.templates.borders
    end


    return {
        id = "itemBoxed",
        type = ui.TYPE.Container,
        --    events = {},
        template = itemTemplate,
        content = ui.content {
            {
                props = {
                    size = size,
                    relativePosition = relativePosition
                },
                content = content
            },
        },
        data = data,
        props = {
            relativePosition = relativePosition,
            anchor = relativePosition
        },
        events = events,
    }
end
return {
    imageContent = imageContent,
    scaledVector2 = scaledVector2,
    renderItemX = renderItemX,
    renderItemChoiceX = renderItemChoiceX,
    drawListMenu = drawListMenu,
    renderItemBoxed = renderItemBoxed,
    renderItemWithIcon = renderItemWithIcon,
    renderItemBold = renderItemBold,
    getEnchantment = getEnchantment,
    FindEnchantment = FindEnchantment,
    calculateTextScale = calculateTextScale,
    scale = scale,
    iconSize = iconSize,
    flexedItems = flexedItems,
    itemWindowLocs = itemWindowLocs,
    findSlot = function (item)
        if (item == nil) then
            return
        end
        --Finds a equipment slot for an inventory item, if it has one,
        if item.type == types.Armor then
            if (types.Armor.records[item.recordId].type == types.Armor.TYPE.RGauntlet) then
                return types.Actor.EQUIPMENT_SLOT.RightGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LGauntlet) then
                return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Boots) then
                return types.Actor.EQUIPMENT_SLOT.Boots
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Cuirass) then
                return types.Actor.EQUIPMENT_SLOT.Cuirass
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Greaves) then
                return types.Actor.EQUIPMENT_SLOT.Greaves
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LBracer) then
                return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RBracer) then
                return types.Actor.EQUIPMENT_SLOT.RightGauntlet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RPauldron) then
                return types.Actor.EQUIPMENT_SLOT.RightPauldron
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.LPauldron) then
                return types.Actor.EQUIPMENT_SLOT.LeftPauldron
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.RPauldron) then
                return types.Actor.EQUIPMENT_SLOT.RightPauldron
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Helmet) then
                return types.Actor.EQUIPMENT_SLOT.Helmet
            elseif (types.Armor.records[item.recordId].type == types.Armor.TYPE.Shield) then
                return types.Actor.EQUIPMENT_SLOT.CarriedLeft
            end
        elseif item.type == types.Clothing then
            if (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Amulet) then
                return types.Actor.EQUIPMENT_SLOT.Amulet
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Belt) then
                return types.Actor.EQUIPMENT_SLOT.Belt
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.LGlove) then
                return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.RGlove) then
                return types.Actor.EQUIPMENT_SLOT.RightGauntlet
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Ring) then
                return types.Actor.EQUIPMENT_SLOT.RightRing
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Skirt) then
                return types.Actor.EQUIPMENT_SLOT.Skirt
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shirt) then
                return types.Actor.EQUIPMENT_SLOT.Shirt
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Shoes) then
                return types.Actor.EQUIPMENT_SLOT.Boots
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Robe) then
                return types.Actor.EQUIPMENT_SLOT.Robe
            elseif (types.Clothing.records[item.recordId].type == types.Clothing.TYPE.Pants) then
                return types.Actor.EQUIPMENT_SLOT.Pants
            end
        elseif item.type == types.Weapon then
            if (item.type.records[item.recordId].type == types.Weapon.TYPE.Arrow or item.type.records[item.recordId].type == types.Weapon.TYPE.Bolt) then
                return types.Actor.EQUIPMENT_SLOT.Ammunition
            end
            return types.Actor.EQUIPMENT_SLOT.CarriedRight
        elseif item.type == types.Light then
            return types.Actor.EQUIPMENT_SLOT.CarriedLeft
        end
        -- --print("Couldn't find slot for " .. item.recordId)
        return nil
    end}
