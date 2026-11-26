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
local function getIconSize()
    return 40
end
if I.Controller_Icon_QS then
    return
end
local savedTextures = {}
local function textContent(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = tostring(text),
            textSize = 10 * 1,
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end
local function imageContent(resource, half)
    local size = getIconSize()
    local opacity = 1
    if half then
        opacity = 0.5
    end
    local size2 = size
    if half then
        size2 = size2 / 2
    end
    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = util.vector2(size, size2),
            alpha = opacity
            -- relativeSize = util.vector2(1,1)
        }
    }
end
local function getTexture(path)
    if not savedTextures[path] and path then
        savedTextures[path] = ui.texture({ path = path })
    end
    return savedTextures[path]
end
local function formatNumber(num)
    local threshold = 1000
    local millionThreshold = 1000000

    if num >= millionThreshold then
        local formattedNum = math.floor(num / millionThreshold)
        return string.format("%dm", formattedNum)
    elseif num >= threshold then
        local formattedNum = math.floor(num / threshold)
        return string.format("%dk", formattedNum)
    else
        return tostring(num)
    end
end
local function FindEnchant(item)
    if not item or not item.id then
        return nil
    end
    if item.enchant then
        return item.enchant
    end
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].enchant == nil or item.type.records[item.recordId].enchant == "") then
        return nil
    end
    return item.type.records[item.recordId].enchant
end

local function getItemIcon(item, half, selected)
    local itemIcon = nil

    local selectionResource
    local drawFavoriteStar = true
    selectionResource = getTexture("textures/omw_menu_icon_active.dds")
    local magicIcon = FindEnchant(item) and FindEnchant(item) ~= "" and getTexture("textures\\menu_icon_magic_mini.dds")
    local text = ""
    if item and item.type then
        local record = item.type.records[item.recordId]
        if not record then
            --print("No record for " .. item.recordId)
        else
            --print(record.icon)
        end
        if item.count > 1 then
            text = formatNumber(item.count)
        end

        itemIcon = getTexture(record.icon)
    end

    local selectedContent = {}
    if selected then
        selectedContent = imageContent(selectionResource)
    end
    local context = ui.content {
        selectedContent,
        imageContent(magicIcon, half),
        imageContent(itemIcon, half),
        textContent(tostring(text))
    }

    return context
end
local function getSpellIcon(iconPath, half, selected)
    local itemIcon = nil

    local selectionResource
    local drawFavoriteStar = true
    selectionResource = getTexture("textures/omw_menu_icon_active.dds")
    local pendingText = getTexture("textures/omw_menu_icon_active.dds")

    local selectedContent = {}
    if selected then
        selectedContent = imageContent(selectionResource)
    end
    itemIcon = getTexture(iconPath)

    local context = ui.content {
        imageContent(itemIcon, half),
        selectedContent,
    }

    return context
end
local function getEmptyIcon(half, num, selected,useNumber)
    local selectionResource
    local drawFavoriteStar = true
    selectionResource = getTexture("textures/omw_menu_icon_active.dds")

    local selectedContent = {}
    if selected then
        selectedContent = imageContent(selectionResource)
    end
    local text = ""
    if useNumber then
        text = tostring(num)
    end

    return ui.content {
        selectedContent,
        {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = text,
                textSize = 20 * 1,
                relativePosition = util.vector2(0.5, 0.5),
                anchor = util.vector2(0.5, 0.5),
                arrange = ui.ALIGNMENT.Center,
                align = ui.ALIGNMENT.Center,
            },
            num = num,
            events = {
                --          mouseMove = async:callback(mouseMove),
            },
        }
    }
end

return {
    interfaceName = "Controller_Icon_QS",
    interface = {
        version = 1,
        getItemIcon = getItemIcon,
        getSpellIcon = getSpellIcon,
        getEmptyIcon = getEmptyIcon,
    },
}
