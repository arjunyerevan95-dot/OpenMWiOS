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

local savedTextures = {}
local function getTexture(path,size)
    if not savedTextures[path] and path then
        savedTextures[path] = ui.texture({ path = path,size = size })
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
    if item.type == nil then
        return nil
    end
    if item.type.records[item.recordId].enchant == nil or item.type.records[item.recordId].enchant == "" then
        return nil
    end
    return item.type.records[item.recordId].enchant
end
local key = "SettingsControllerInterface"
local playerSettings = storage.globalSection(key)
local function getIconSize()
    return playerSettings:get("iconSize") or 40
end
local anchhor = v2(0,0)
local function eimageContent(resource, size)

    if not resource then
        return {
            --        type = ui.TYPE.Container,
            props = {
            }
        }
    end
    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = util.vector2(size * 1, size * 1),
            anchor =anchhor,
             relativeSize = util.vector2(2,2)
        }
    }
end
local function getItemIcon(item, selected)

    local itemIcon = nil

    local selectionResource
    local drawFavoriteStar = true
    selectionResource = getTexture("textures/omw_menu_icon_active.dds")
    local pendingText = getTexture("textures/omw_menu_icon_active.dds")
    local magicIcon = nil
    if item then
        magicIcon = FindEnchant(item.item)
    end

    if magicIcon then
        magicIcon = getTexture("textures\\menu_icon_magic.dds",v2(48,48))
    end

    local text = ""
    if item then
        if item.count > 1 then
            text = formatNumber(item.count)
        end

        if I.Controller_Favorites.hasFavoriteItem(item.recordId) and drawFavoriteStar then
            text = "*" .. text
        end
        itemIcon = getTexture(item.icon)
    end
    local selectedContent = {}
    local pendingContent = {}
    if item and item.pending then
        pendingContent = I.ZackUtilsUI_ci.imageContent(pendingText)
    end
    if selected then
        selectedContent = I.ZackUtilsUI_ci.imageContent(selectionResource)
    end
    local context = ui.content {
        eimageContent(magicIcon,getIconSize()),
        I.ZackUtilsUI_ci.imageContent(itemIcon),
        selectedContent,
        pendingContent,
        I.ZackUtilsUI_ci.textContent(tostring(text))
    }

    return context

end
local function getSpellIcon(item)

end


return {
    interfaceName = "Controller_Icon",
    interface = {
        version = 1,
        getItemIcon = getItemIcon,
    },
    eventHandlers = {
    },
    engineHandlers = {
    }
}
