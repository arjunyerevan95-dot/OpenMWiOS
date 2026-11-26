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
local tooltipgen = require("scripts.ios_deckwind.Deckwind.ci_tooltipgen")
local renderStatBar = require("scripts.ios_deckwind.Deckwind.renderStatBar")
local vfs = require("openmw.vfs")
local iconsize = 40
local spellChance = require("scripts.ios_deckwind.Deckwind.util.spellchance")
local const = require("scripts.ios_deckwind.Deckwind.ci_const")

if not const.doesRun then
    return {}
end
local key = "SettingsControllerInterface"
local playerSettings = storage.globalSection(key)
local function getIconSize()
    return playerSettings:get("iconSize")
end
local function getIconSizeGrow()
    local ret = playerSettings:get("iconSize")
    return (playerSettings:get("iconSize")) + ret * 0.25
end
local windowType = { inventory = 1, magic = 2, skills = 3, stats = 4 }
local itemCheck = "ebony_dagger_mehrunes"
local function getEnchantment(id) --
    return core.magic.enchantments.records[id]
end
local function getCorrectedIconPath(path)
    if not path or not playerSettings:get("useSuppliedIcons") then return path end
    local alternate = "icons/jicons/" .. path
    return vfs.fileExists(alternate) and alternate or path
end
local boundItemGMSTs = {
    "sMagicBoundDaggerID",
    "sMagicBoundLongswordID",
    "sMagicBoundMaceID",
    "sMagicBoundBattleAxeID",
    "sMagicBoundSpearID",
    "sMagicBoundLongbowID",
    "sMagicBoundCuirassID",
    "sMagicBoundHelmID",
    "sMagicBoundBootsID",
    "sMagicBoundShieldID",
    "sMagicBoundLeftGauntletID",
    "sMagicBoundRightGauntletID",
}
local boundItemIds = {}
for index, gmst in ipairs(boundItemGMSTs) do
    local value = core.getGMST(gmst):lower()
    boundItemIds[value] = true
end

-- Cached cursor positions in the inventory and magic windows
local previousInvCat = 1
local previousInvX = 1;
local previousInvY = 1;
local previousMagicCat = 1
local previousMagicX = 1;
local previousMagicY = 1;

local lastRenderedItem = nil

local function mouseMove(mouseEvent, data)
    ------print("Mouse Move", data.props.px, data.props.py)
    if data.props.iw and data.props.iw.selected == false then
        I.Deckwind.setSelectedWindow(data.props.iw)
    end
    local px = data.props.px
    local py = data.props.py
    if data.props.iw and data.props.iw:getItemAt(px, py) ~= nil and (data.props.iw.selectedPosX ~= px or data.props.iw.selectedPosY ~= py) then
        data.props.iw.selectedPosX = px
        data.props.iw.selectedPosY = py
        data.props.iw:reDraw()
    end
end

local function scrollWindow(iw, delta)
    if delta == 0 then return end
    local items = iw:filterItems(iw.itemDataList, nil, iw.parentObject)
    local visible = iw.listMode and iw.rowCountY or iw.rowCountX * iw.rowCountY
    local step = iw.listMode and 1 or iw.rowCountY
    local nextOffset = math.max(0, math.min(#items - visible, iw.scrollOffset + (delta > 0 and -step or step)))
    if nextOffset == iw.scrollOffset then return end
    iw.scrollOffset = nextOffset
    iw.selectedPosX, iw.selectedPosY = 1, 1
    iw:reDraw()
end
local function mouseClick(mouseEvent, data)
    local px = data.props.px
    local py = data.props.py
    if I.Deckwind.getHeldItem() ~= nil then
        local item, container = I.Deckwind.getHeldItem()
        I.Deckwind.clearHeldItem()
        data.props.iw.ignoreList = nil
        I.ZackUtilsUI_ci.playDropSound(item)
        core.sendGlobalEvent("CI_moveInto",
            {
                sourceObj = container,
                targetObj = data.props.iw.parentObject,
                invItem = item,
                count = item.count,
                player = self
            })
        return
    end
    if data.props.iw.selected == false then
        I.Deckwind.setSelectedWindow(data.props.iw)
    end
    if data.props.iw:getItemAt(px, py) ~= nil then
        local item = data.props.iw:getItemAt(px, py)
        data.props.iw:rebuildItemList({ item })
        I.ZackUtilsUI_ci.playPickupSound(item)
        I.Deckwind.drawHandIcon(item, mouseEvent.position.x, mouseEvent.position.y, data.props.iw)
        data.props.iw:reDraw()
    end
    if data.props.iw:getItemAt(px, py) ~= nil and (data.props.iw.selectedPosX ~= px or data.props.iw.selectedPosY ~= py) then
        data.props.iw.selectedPosX = data.props.px
        data.props.iw.selectedPosY = data.props.py
        data.props.iw:reDraw()
    else
        ----print("Mouse Click", px, py)
        ----print("Mouse x", data.props.iw.selectedPosX ~= px)
        ----print("Mouse y", data.props.iw.selectedPosY ~= py)
    end
end


local function setWindowType(iw, type)
    if iw.parentObject and iw.parentObject == self then
        -- Cache current settings, so we can restore the cursor to the correct position
        if iw.windowType == windowType.inventory then
            print("Saving inventory position " .. iw.selectedPosX .. " " .. iw.selectedPosY)
            previousInvCat = I.Deckwind.getCurrentCat()
            previousInvX = iw.selectedPosX
            previousInvY = iw.selectedPosY
        elseif iw.windowType == windowType.magic then
            print("Saving magic position " .. iw.selectedPosX .. " " .. iw.selectedPosY)
            previousMagicCat = I.Deckwind.getCurrentCat()
            previousMagicX = iw.selectedPosX
            previousMagicY = iw.selectedPosY
        end
    end

    if (type == windowType.inventory) then
        iw.catTypes = { "All", "Weapon", "Apparel", "Magic", "Misc" }
        iw.typeFilter = {
            ["All"] = {},
            ["Weapon"] = { types.Weapon },
            ["Apparel"] = { types.Clothing, types.Armor },
            ["Magic"] = { types.Ingredient, types.Potion },
            ["Misc"] = { types.Apparatus, types.Book, types.Miscellaneous, types.Probe, types.Repair, types.Light }
        }
        iw.listMode = playerSettings:get("useInventoryinListMode")
        if iw.parentObject == self then
            print("Restoring inventory position " .. previousInvX .. " " .. previousInvY)
            I.Deckwind.setCurrentCat(previousInvCat)
            iw.selectedPosX = previousInvX
            iw.selectedPosY = previousInvY
        else
            iw.selectedPosX = 1
            iw.selectedPosY = 1
        end
    elseif type == windowType.magic then
        iw.catTypes = { "All", "Alteration", "Conjuration", "Destruction", "Illusion", "Mysticism", "Restoration",
            "Active Effects" }
        iw.listMode = true
        if iw.parentObject == self then
            print("Restoring magic position " .. previousMagicX .. " " .. previousMagicY)
            I.Deckwind.setCurrentCat(previousMagicCat)
            iw.selectedPosX = previousMagicX
            iw.selectedPosY = previousMagicY
        else
            iw.selectedPosX = 1
            iw.selectedPosY = 1
        end
    end
    iw.windowType = type
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

local itemWindowLocs = {
    TopLeft = { wx = 0, wy = 0, align = ui.ALIGNMENT.Start, anchor = nil },
    TopRight = { wx = 1, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0) },
    Right = { wx = 1, wy = 0.5, align = ui.ALIGNMENT.End, anchor = util.vector2(1, 0.5) },
    Left = { wx = 0, wy = 0.5, align = ui.ALIGNMENT.Start, anchor = util.vector2(0, 0.5) },
    BottomLeft = { wx = 0, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0, 1) },
    BottomRight = { wx = 1, wy = 1, align = ui.ALIGNMENT.Start, anchor = util.vector2(1, 1) },
    BottomCenter = { wx = 0.5, wy = 1, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 1) },
    TopCenter = { wx = 0.5, wy = 0, align = ui.ALIGNMENT.End, anchor = util.vector2(0.5, 0) },
    BelowItem = { wx = 0.68, wy = 0.7, align = ui.ALIGNMENT.Center, anchor = util.vector2(0.5, 0) },
    Disabled = { disabled = true }
}


local function FindEnchantment(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].enchant == nil or item.type.records[item.recordId].enchant == "") then
        return nil
    end
    return getEnchantment(item.type.records[item.recordId].enchant)
end
local function getAllEnchantments(actorInv, onlyCastable)
    local ret = {}
    for index, value in ipairs(actorInv:getAll()) do
        local ench = FindEnchantment(value)
        if (ench and not onlyCastable) then
            table.insert(ret, { enchantment = ench, item = value })
        elseif ench and onlyCastable and (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or ench.type == core.magic.ENCHANTMENT_TYPE.CastOnce) then
            table.insert(ret, { enchantment = ench, item = value })
        end
    end
    return ret
end
local function getEffectIcon(effect)
    --local strWithoutSpaces = string.gsub(effect.name, "%s", "")
    -- if( effectData[strWithoutSpaces] == nil) then
    --    ----print(strWithoutSpaces)
    --  end
    --strWithoutSpaces= string.sub(effectData[strWithoutSpaces], 1, -4) .. "dds"
    -- ----print(strWithoutSpaces)
    return effect.icon
end
local savedTextures = {}
local function getTexture(path)
    if not savedTextures[path] then
        savedTextures[path] = ui.texture({ path = path })
    end
    return savedTextures[path]
end

local function padString(str, length)
    local strLength = string.len(str)

    if strLength >= length then
        return str -- No need to pad if the string is already longer or equal to the desired length
    end

    local padding = length - strLength                   -- Calculate the number of spaces needed
    local paddedString = str .. string.rep(" ", padding) -- Concatenate the string with the required number of spaces

    return paddedString
end

local function flexedItems(content, horizontal, size)
    if not horizontal then
        horizontal = false
    end
    return {
        {
            type = ui.TYPE.Flex,
            content = ui.content(content),
            events = {
                mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Center,
                size = size,
                autosize = false
            }
        }
    }
end

local function growPadding(text, stretch)
    return {
        type = ui.TYPE.Widget,
        external = {
            grow = 1
        }
    }
end

local function unsizedNoWrapText(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = text
        }
    }
end

local function sizedText(text, width)
    return {
        type = ui.TYPE.Flex,
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textHeader,

                props = {
                    text = text,
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5)
                },
                external = {
                    grow = 1
                }
            }
        },
        props = {
            size = v2(width, 0),
            horizontal = horizontal,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        }
    }
end

local function renderListItem(iw, selected, textx, item)
    local itemIcon = nil
    local resource2

    local text = ""

    local resources = {}
    if (iw.windowType == windowType.inventory and item) then
        local magicIcon = nil
        if (item) then
            local record = item.icon

            if not iw.favoritesOnly then
                if I.Controller_Favorites.hasFavoriteItem(item.item.recordId) then
                    text = "*" .. text
                end
            end
            itemIcon = getTexture(record)
        end
        if (item.enchant and item.enchant ~= "") then
            magicIcon = getTexture("textures\\menu_icon_magic_mini.dds")
        end
        textx = item.name
        if item.count > 1 then
            textx = textx .. " (" .. formatNumber(item.count) .. ")"
        end

        local weightNum = item.type.record(item.item).weight or 0
        local weight = string.format("%.1f", weightNum)
        if weight == nil or weight == 0 or weight == "0" or weight == "0.0" then
            weight = "--"
        end

        local valueNum = item.value or 0
        local value = valueNum
        if value == 0 then
            value = "--"
        end

        local vwRatio
        if valueNum == 0 then
            vwRatio = 0
        elseif weightNum == 0 then
            vwRatio = "Inf."
        else
            vwRatio = string.format("%.0f", valueNum / weightNum)
        end

        resources = {
            I.ZackUtilsUI_ci.imageContent(magicIcon),
            I.ZackUtilsUI_ci.imageContent(itemIcon),
            I.ZackUtilsUI_ci.textContent(tostring(text)),
            unsizedNoWrapText(tostring("    " .. textx)),
            growPadding(),
            sizedText(tostring(item.type), 110),
            sizedText(tostring(weight), 40),
            sizedText(tostring(value), 60),
            sizedText(tostring(vwRatio), 60)
        }
    elseif iw.windowType == windowType.magic and item then
        local magicIcon = nil
        magicIcon = getTexture(getCorrectedIconPath(item.icon))

            text = item.spell.name
        if not iw.favoritesOnly and (item.item or item.spell) then
            local id
            if item.item and item.item.recordId then
                id = item.item.recordId
            elseif item.spell then
                id = item.spell.id
            end
            if I.Controller_Favorites.hasFavoriteItem(id) then
                text = "*" .. text
            end
        end
        local spacing = "   "

        if (text == nil) then
            text = item.name
        end

        resources = {
            I.ZackUtilsUI_ci.imageContent(magicIcon),
            unsizedNoWrapText(spacing .. text),
            growPadding(),
            -- TODO: Add spell school
            sizedText(tostring(math.floor(item.numerator)), 40),
            sizedText(tostring("/"), 5),
            sizedText(tostring(math.floor(item.denominator)), 40),
        }
    end
    -- resource2 = ui.texture({ path = "textures/omw_menu_icon_active.dds" })
    -- TODO: fix the sizing to use the full height of the left hand size, a la SkyUI
    local sizeX = getIconSize() * 15
    local size = util.vector2(sizeX, getIconSize())
    local content = ui.content(flexedItems(resources, true, size))


    local template = I.MWUI.templates.padding
    if selected and item then
        template = I.MWUI.templates.box
    end
    --    table.insert(content, flexedItems(content, true, util.vector2(sizeX, getIconSize())))
    --    resources = ui.content(content)
    local box = {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(getIconSize(), getIconSizeGrow() * sizeX),
            autoSize = false
        },
        content = ui.content {
            {
                template = template,
                props = {
                    size = util.vector2(getIconSize(), getIconSizeGrow() * sizeX),
                    autoSize = false
                },
                --  content = {}
                content = content
                --content = content
            }
        }
    }

    return box
end

local function generateListItems(iw, spellList, enchantList, filter)
    local ret = {}
    local createListItem = function(strig, iconTable, spell, enchant, numerator, denominator)
        return {
            name = strig,
            icon = iconTable,
            spell = spell,
            enchant = enchant,
            numerator = numerator,
            denominator = denominator
        }
    end
    if iw.windowType == windowType.magic then
        local spells = types.Actor.spells(self)
        if (spellList ~= nil) then
            spells = spellList
        end
        for index, spell in ipairs(spells) do
            if spell.type == core.magic.SPELL_TYPE.Power or spell.type == core.magic.SPELL_TYPE.Spell then

                local listItem = createListItem(spell.name, getEffectIcon(spell.effects[1].effect), spell, nil, spell.cost, spellChance.getSpellSuccessChance(spell,self))
                table.insert(ret, listItem)
            end
        end
        enchantList = getAllEnchantments(types.Actor.inventory(self), true)
        for index, ench in ipairs(enchantList) do
            local use = true
            if filter then
                use = false
                local effect = ench.enchantment.effects[1].effect

                if (effect.school:lower() == filter:lower()) then
                    use = true
                end
            end
            if use then
                local name = ench.item.type.record(ench.item).name

                -- charge level is shown as: <current-charge> / <total-charge>
                local listItem = createListItem(name, getEffectIcon(ench.enchantment.effects[1].effect), ench.item,
                    ench.enchantment.id, types.Item.itemData(ench.item).enchantmentCharge, ench.enchantment.charge)
                table.insert(ret, listItem)
            end
        end
    end

    table.sort(ret, function(a, b) return a.name < b.name end)
    return ret
end
local function renderGridIcon(item, selected, listMode, valx, valy, iw)
    if selected then
        -- table.insert(context,resource2)
    end

    --context = ui.content {context}
    if (selected and item) then
        return { --box around the titem
            type = ui.TYPE.Container,
            props = {
                size = util.vector2(getIconSize(), getIconSize()),
                px = valx,
                py = valy,
                winSelected = iw.selected,
                iw = iw,
            },
            events = {
                mouseClick = async:callback(mouseClick),
                -- mouseRelease = async:callback(clickMeStop),
                mouseMove = async:callback(mouseMove)
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.box,
                    alignment = ui.ALIGNMENT.Center,
                    content = I.Controller_Icon.getItemIcon(item, true)
                }
            }
        }
    end

    return { --parent container, box around the element
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(getIconSize(), getIconSize()),
            px = valx,
            py = valy,
            iw = iw,
        },
        events = {
            mouseClick = async:callback(mouseClick),
            -- mouseRelease = async:callback(clickMeStop),
            mouseMove = async:callback(mouseMove)
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = I.Controller_Icon.getItemIcon(item, false)
            }
        }
    }

    --TODO:Make this not suck
end

local function itemIsEquipped(item, actor)
    --Checks if item record is equipped on the specified actor
    if actor.type == types.Container then
        return false
    end
    if item.equipped == false or item.equipped == true then
        return item.equipped
    end
    if (actor == nil) then actor = self end
    if (actor.type ~= types.NPC and actor.type ~= types.Creature and actor.type ~=
            types.Player) then
        ----print("invalid type")
        return false
    end
    for slot = 1, 17 do
        if (types.Actor.equipment(actor, slot)) then
            if (item.id == types.Actor.equipment(actor, slot).id) then
                return true
            end
        end
    end
    return false
end
local itemListData = {}
local function hasEnchantment(objectRecord)
    if not objectRecord.enchantment or objectRecord.enchantment == "" then
        return false
    else
        return true
    end
end
local function actorSells(actorRecord, object)
    local objectRecord = object.type.records[object.recordId]
    if not actorRecord.servicesOffered then
        return true
    else
        local services = actorRecord.servicesOffered
        if hasEnchantment(objectRecord) and services["MagicItems"] then
            return true
        elseif object.type == types.Repair and services["RepairItems"] then
            return true
        elseif object.type == types.Weapon and services["Weapon"] then
            return true
        elseif object.type == types.Armor and services["Armor"] then
            return true
        elseif object.type == types.Ingredient and services["Ingredients"] then
            return true
        elseif object.type == types.Book and services["Books"] then
            return true
        elseif object.type == types.Lockpick and services["Picks"] then
            return true
        elseif object.type == types.Probe and services["Probes"] then
            return true
        elseif object.type == types.Apparatus and services["Apparatus"] then
            return true
        elseif object.type == types.Miscellaneous and services["Misc"] then
            return true
        elseif object.type == types.Potion and services["Potions"] then
            return true
        elseif object.type == types.Light and services["Lights"] then
            return true
        elseif object.type == types.Clothing and services["Clothing"] then
            return true
        end
    end
end
local function elgibleForBarter(actor, item)
    if item.recordId == "gold_001" then
        return false
    elseif item.type == types.Miscellaneous then
        local record = item.type.records[item.recordId]
        if record.isKey then
            return false
        end
        return true
    else
        return true
    end
end
local function sortType(typeA, typeB)

    local typeOrder = {
        Weapon = 0,
        Armor = 1,
        Clothing = 2,
        Potion = 3,
        Ingredient = 4,
        Apparatus = 5,
        Book = 6,
        Light = 7,
        Miscellaneous = 8,
        Lockpick = 9,
        Repair = 10,
        Probe = 11
    }

    local typeAIndex = typeOrder[typeA]
    local typeBIndex = typeOrder[typeB]

    return typeAIndex < typeBIndex
end
local function buildItemList(itemList, iw, ignoreList)
    itemListData = {}
    if ignoreList then
        iw.ignoreList = ignoreList
    elseif iw.ignoreList ~= nil then
        ignoreList = iw.ignoreList
    end
    if iw.type == "barterNPC" then
        local newList = {}
        local actor = iw.parentObject
        local actorRecord = actor.type.records[actor.recordId]
        for index, value in ipairs(itemList) do
            if not itemIsEquipped(value, actor) and actorSells(actorRecord, value) and elgibleForBarter(actor, value) then
                table.insert(newList, value)
            end
        end
        for index, obj in ipairs(nearby.containers) do
            if I.CI_Expirement.getObjectOwner(obj) == actor.recordId then
                if obj.type.inventory(obj):isResolved() == false then
                    core.sendGlobalEvent("resolveCont", obj)
                end
                if types.Item.objectIsInstance(obj) then
                    table.insert(newList, obj)
                elseif obj.type == types.Container then
                    for index, invItem in ipairs(types.Container.content(obj):getAll()) do
                        if actorSells(actorRecord, invItem) and elgibleForBarter(actor, invItem) then
                            table.insert(newList, invItem)
                        else
                            print("Does not sell" .. invItem.type.records[invItem.recordId].name)
                        end
                    end
                end
            end
        end
        for index, obj in ipairs(nearby.items) do
            if I.CI_Expirement.getObjectOwner(obj) == actor.recordId and actorSells(actorRecord, obj) and elgibleForBarter(actor, obj) then
                if types.Item.objectIsInstance(obj) then
                    table.insert(newList, obj)
                elseif obj.type == types.Container then
                    for index, invItem in ipairs(types.Container.content(obj):getAll()) do
                        table.insert(newList, invItem)
                    end
                end
            end
        end
        itemList = newList
    elseif iw.type == "barterPlayer" then
        local newList = {}
        local actorRecord = iw.targetActor.type.record(iw.targetActor)
        for index, value in ipairs(itemList) do
            if actorSells(actorRecord, value) and elgibleForBarter(nil, value) then
                table.insert(newList, value)
            end
        end
        itemList = newList
    end
    for index, item in ipairs(itemList) do
        local skip = false
        if ignoreList then
            for index, ignob in ipairs(ignoreList) do
                if item == ignob or item == ignob.item then
                    skip = true
                end
            end
        end
        if not skip and (not iw.favoritesOnly or I.Controller_Favorites.hasFavoriteItem(item.recordId)) then
            local itemData = {}
            itemData.icon = item.type.records[item.recordId].icon
            itemData.name = item.type.records[item.recordId].name
            itemData.value = item.type.records[item.recordId].value
            itemData.type = item.type
            itemData.enchant = item.type.records[item.recordId].enchant
            itemData.equipped = itemIsEquipped(item, iw.parentObject)
            itemData.recordId = item.recordId
            itemData.count = item.count
            itemData.item = item

            table.insert(itemListData, itemData)
        end
    end
    table.sort(itemListData, function(a, b)
        if tostring(a.type) ~= tostring(b.type) then
            return sortType(tostring(a.type),tostring(b.type))
        else
            return a.name < b.name
        end
    end)
    return itemListData
end
local function filterItems(iw, itemList, skipItem, actor)
    local key = iw.catTypes[I.Deckwind.getCurrentCat()]

    if (key == nil) then
        I.Deckwind.setCurrentCat(1)
        key = iw.catTypes[I.Deckwind.getCurrentCat()]
    end
    local ret = {}
    if (iw.windowType == windowType.magic) then
        if (key == "All") then
            return generateListItems(iw)
        else
            for index, spell in ipairs(types.Actor.spells(self)) do
                local effect = spell.effects[1].effect --types.Actor.spells(self)[22].effects[1].effect

                if (effect.school == key:lower()) then
                    table.insert(ret, spell)
                end
            end
        end
        return generateListItems(iw, ret, nil, key)
    end
    local filter = iw.typeFilter[key]
    if (skipItem == nil) then
        skipItem = itemCheck
    else
        skipItem = skipItem.recordId
    end
    for index, value in ipairs(itemList) do
        if (value.recordId == itemCheck) then
            core.sendGlobalEvent("clearContainerCheck", value)
        end
    end
    if (key == "All") then
        for index, value in ipairs(itemList) do
            if (value.recordId ~= skipItem and value.equipped and value.count == 1) then
                table.insert(ret, value)
            end
        end
        for index, value in ipairs(itemList) do
            if (value.recordId ~= skipItem and value.equipped == false and value.count > 0) then
                table.insert(ret, value)
            end
        end
        return ret
    end
    for index, value in ipairs(itemList) do
        local valid = false
        for k, type in ipairs(filter) do
            if (value.type == type and value.count == 1) then
                valid = true
            end
        end
        if (key == "Magic" and valid == false) then
            if (value.type == types.Weapon or value.type == types.Book or value.type == types.Armor or value.type == types.Clothing) then
                if (value.enchant ~= nil and value.enchant ~= "" and value.count > 0) then
                    valid = true
                end
            end
        end
        if (value.recordId ~= skipItem and valid and value.equipped and value.count == 1) then
            table.insert(ret, value)
        end
    end
    for index, value in ipairs(itemList) do
        local valid = false
        for k, type in ipairs(filter) do
            if (value.type == type) then
                valid = true
            end
        end
        if (key == "Magic" and valid == false) then
            if (value.type == types.Weapon or value.type == types.Book or value.type == types.Armor or value.type == types.Clothing) then
                if (value.enchant ~= nil and value.enchant ~= "") then
                    valid = true
                end
            end
        end
        if (value.recordId ~= skipItem and valid and value.equipped == false) then
            table.insert(ret, value)
        end
    end
    return ret
end
local function renderItemList(iw)
    local posX = iw.posX
    local posY = iw.posY
    local itemList = nil

    if (iw.windowType == windowType.inventory) then
        itemList = iw:filterItems(iw.itemDataList, nil, iw.parentObject)
    end
    if (iw.windowType == windowType.magic) then
        itemList = iw:filterItems(iw.itemDataList, nil, iw.parentObject)
    end
    local vertical = 80
    local myData = nil
    local name = "ItemGrid"

    local counter = 0
    local contents = {}

    for x = 1, iw.rowCountY do
        local content = {} -- Create a new table for each value of x
        --  for y = 1, iw.rowCountY do
        local index = (x) + iw.scrollOffset

        ------print(tostring(getScrollOffset(isPlayer)))
        ------print(index)
        if index <= #itemList then
            local item = itemList[index]
            -- if (item.recordId == itemCheck) then
            --     core.sendGlobalEvent("clearContainerCheck", item)
            ----    item = nil
            ---end
            local linetext
            local icon

            if (item == nil) then
                -- ----print(index)
                --   ----print(#itemList)
                return
            end
            local itemLayout = nil
            if iw.selectedPosX == x and iw.selected then
                iw.selectedInvItem = item
                itemLayout = renderListItem(iw, true, nil, item)
            else
                itemLayout = renderListItem(iw, false, nil, item)
            end
            if iw.windowType == windowType.inventory then
                if item.equipped then
                    itemLayout.template = I.MWUI.templates.box
                else
                    itemLayout.template = I.MWUI.templates.padding
                end
            elseif iw.windowType == windowType.magic then
                if types.Actor.getSelectedSpell(self) ~= nil and types.Actor.getSelectedSpell(self).id == item.spell.id then
                    itemLayout.template = I.MWUI.templates.box
                elseif types.Actor.getSelectedEnchantedItem(self) ~= nil and types.Actor.getSelectedEnchantedItem(self).id == item.spell.id then
                    itemLayout.template = I.MWUI.templates.box
                else
                    itemLayout.template = I.MWUI.templates.padding
                end
            end
            itemLayout.events = { mouseClick = async:callback(function()
                I.Deckwind.setSelectedWindow(iw)
                if iw.selectedPosX == x then
                    I.Deckwind.touchAction("selectButton")
                else
                    iw.selectedPosX, iw.selectedPosY = x, 1
                    iw:reDraw()
                end
            end) }
            table.insert(content, itemLayout)
        else
            if iw.selectedPosX == x and iw.selected then
                iw.selectedInvItem = nil
                local itemLayout = renderListItem(iw, true, "")
                itemLayout.template = I.MWUI.templates.padding
                table.insert(content, itemLayout)
            else
                local itemLayout = renderListItem(iw, false, "")
                itemLayout.template = I.MWUI.templates.padding
                table.insert(content, itemLayout)
            end
        end
        --    end
        table.insert(contents, content)
    end

    for _, item in ipairs(itemList) do
        counter = counter + 1
    end
    local table_contents = {} -- Table to hold the generated items

    for index, contentx in ipairs(contents) do
        local item = {
            type = ui.TYPE.Flex,
            content = ui.content(contentx),
            props = {
                size = util.vector2(getIconSizeGrow() * iw.rowCountX, getIconSize()),
                position = v2(0.8, 50 * (index - 1)),
                vertical = true,
                arrange = ui.ALIGNMENT.Start,
            },
            external = {
                grow = getIconSizeGrow()
            }
        }
        table.insert(table_contents, item)
    end
    return ui.create {
        layer = "InventoryWindow",
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxTransparent,
        events = {
            mouseWheel = async:callback(function(event) scrollWindow(iw, event.delta.y) end),
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            size = v2(getIconSizeGrow() * iw.rowCountX , getIconSizeGrow() * iw.rowCountY),
            relativePosition = v2(iw.posX, iw.posY),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = false,
            vertical = true,
            name = name,
        },
        content = ui.content(table_contents)
    }
end
local function flexedItems(content, horizontal)
    if not horizontal then
        horizontal = false
    end
    return ui.content {
        {
            type = ui.TYPE.Flex,
            content = ui.content(content),
            events = {
                mouseMove = async:callback(mouseMove)
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Start,
            }
        }
    }
end

local function renderItemBoxed(content, size)
    local itemTemplate
    local text
    if not size then
        size = util.vector2(800, 1200)
    end

    itemTemplate = I.MWUI.templates.boxThick

    return {
        type = ui.TYPE.Container,
        events = {},
        template = itemTemplate,
        content = ui.content {
            {
                props = {
                    size = size,
                },
                content = content
            },
        },
    }
end
local function getEffectiveArmorRating(ref, actor)
    local armorSkillType = I.ZackUtilsUI_ci.getArmorType(ref):lower() .. "armor"
    local armorSkill = types.NPC.stats.skills[armorSkillType](self).modified

    local iBaseArmorSkill = core.getGMST("iBaseArmorSkill")
    local record = ref.type.record(ref)
    if record.weight == 0 then
        return record.baseArmor
    else
        return record.baseArmor * armorSkill / iBaseArmorSkill
    end
end

local function getArmorRating(actor)
    if actor.type == types.Creature then
        return 0
    end
    local fUnarmoredBase1 = core.getGMST("fUnarmoredBase1")
    local fUnarmoredBase2 = core.getGMST("fUnarmoredBase2")
    local unarmoredSkill = types.NPC.stats.skills.unarmored(actor).modified

    local ratings = {}
    --  local i = 0
    local equipment = types.Actor.getEquipment(actor)
    for _, i in pairs(types.Actor.EQUIPMENT_SLOT) do
        --  i = i + 1
        local item = equipment[i]
        if not item or item.type ~= types.Armor then
            -- unarmored
            ratings[i] = (fUnarmoredBase1 * unarmoredSkill) * (fUnarmoredBase2 * unarmoredSkill)
        else
            ratings[i] = getEffectiveArmorRating(item, actor)

            -- Take into account armor condition
            local hasHealth = types.Item.itemData(item).condition
            if hasHealth then
                local maxCondition = item.type.records[item.recordId].health
                ratings[i] = ratings[i] * tooltipgen.getItemNormalizedHealth(types.Item.itemData(item), maxCondition)
            end
        end
    end

    local shield = types.Actor.activeEffects(actor):getEffect("shield") or 0
    if shield and shield ~= 0 then
        shield = shield.magnitude
    end
    local ret = ratings[types.Actor.EQUIPMENT_SLOT.Cuirass] * 0.3
        + (ratings[types.Actor.EQUIPMENT_SLOT.CarriedLeft] + ratings[types.Actor.EQUIPMENT_SLOT.Helmet]
            + ratings[types.Actor.EQUIPMENT_SLOT.Greaves] + ratings[types.Actor.EQUIPMENT_SLOT.Boots]
            + ratings[types.Actor.EQUIPMENT_SLOT.LeftPauldron] + ratings[types.Actor.EQUIPMENT_SLOT.RightPauldron])
        * 0.1
        + (ratings[types.Actor.EQUIPMENT_SLOT.LeftGauntlet] + ratings[types.Actor.EQUIPMENT_SLOT.RightGauntlet]) * 0.05
        + shield
    return math.floor(ret)
end
local function renderItemGrid(iw)
    local posX = iw.posX
    local posY = iw.posY
    local itemList = iw:filterItems(iw.itemDataList, nil, iw.parentObject)
    local vertical = 80
    local myData = nil
    local name = "ItemGrid"

    local counter = 0
    local contents = {}

    for x = 1, iw.rowCountX do
        local content = {} -- Create a new table for each value of x
        for y = 1, iw.rowCountY do
            local index = (x - 1) * iw.rowCountY + y + iw.scrollOffset

            ------print(tostring(getScrollOffset(isPlayer)))
            ------print(index)
            if index <= #itemList then
                local item = itemList[index]
                -- if (item.recordId == itemCheck) then
                --     core.sendGlobalEvent("clearContainerCheck", item)
                ----    item = nil
                ---end
                local itemLayout = nil
                if iw.selectedPosX == x and iw.selectedPosY == y and iw.selected then
                    iw.selectedInvItem = item
                    itemLayout = renderGridIcon(item, true, false, x, y, iw)
                else
                    itemLayout = renderGridIcon(item, false, false, x, y, iw)
                end

                if itemIsEquipped(item, iw.parentObject) then
                    itemLayout.template = I.MWUI.templates.box
                else
                    itemLayout.template = I.MWUI.templates.padding
                end
                table.insert(content, itemLayout)
            else
                if iw.selectedPosX == x and iw.selectedPosY == y and iw.selected then
                    iw.selectedInvItem = nil
                    local itemLayout = renderGridIcon(nil, true, false, x, y, iw)
                    itemLayout.template = I.MWUI.templates.padding
                    table.insert(content, itemLayout)
                else
                    local itemLayout = renderGridIcon(nil, false, false, x, y, iw)
                    itemLayout.template = I.MWUI.templates.padding
                    table.insert(content, itemLayout)
                end
            end
        end
        table.insert(contents, content)
    end

    for _, item in ipairs(itemList) do
        counter = counter + 1
    end
    local table_contents = {} -- Table to hold the generated items
    local counter2 = 0
    for index, contentx in ipairs(contents) do
        local item = {
            type = ui.TYPE.Flex,
            content = ui.content(contentx),
            props = {
                size = util.vector2(getIconSize(), getIconSize()),
                position = v2(getIconSizeGrow() * (index - 1), 0.8),
                vertical = false,
                arrange = ui.ALIGNMENT.Center,
                vpos = counter2,
            },
            events = {
                -- mousePress = async:callback(clickMe),
                -- mouseRelease = async:callback(clickMeStop),
                -- = async:callback(mouseMove)
            },
            external = {
                grow = getIconSizeGrow()
            },
        }
        table.insert(table_contents, item)
        counter2 = counter2 + 1
    end
    local weight = ""
    if iw.parentObject.type == types.NPC or iw.parentObject.type == types.Player then
        weight = "Armor: " .. tostring(getArmorRating(iw.parentObject))
    end
    local bottitem = {
        type = ui.TYPE.Flex,
        content = ui.content({ I.ZackUtilsUI_ci.textContent(weight), renderStatBar.renderStat(
            iw.parentObject, "encumbrance") }),
        props = {
            size = util.vector2(0, 0),
            position = v2(10, getIconSizeGrow() * iw.rowCountX),
            vertical = false,
            -- arrange = ui.ALIGNMENT.Center,
            -- vpos = counter2,
        },
        events = {
            -- mousePress = async:callback(clickMe),
            -- mouseRelease = async:callback(clickMeStop),
            -- = async:callback(mouseMove)
        },
        external = {
            grow = getIconSizeGrow()
        },
    }
    table.insert(table_contents, bottitem)
    return ui.create {
        layer = "InventoryWindow",
        type = ui.TYPE.Container,
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            size = v2(getIconSizeGrow() * iw.rowCountX, getIconSizeGrow() * (iw.rowCountY + 2)),
            relativePosition = v2(iw.posX, iw.posY),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            name = name,
        },
        events = {
            mouseWheel = async:callback(function(event) scrollWindow(iw, event.delta.y) end),
        },
        content = ui.content(table_contents)
    }
end
local function getInventory(object)
    --Quick way to get the inventory of an object, regardless of type
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
    return nil --Not any of the above types, so no inv
end
local function createParentUi(content, horizontal, vertical, name, isHorizontal, iw, anchor, width)
    if (isHorizontal == nil) then
        isHorizontal = false
    end
    if not width then
        width = 40
    end
    local ret = {
        layer = "InventoryWindow",
        template = I.MWUI.templates.boxTransparent,
        --    type = ui.TYPE.Flex,
        events = {
            --    mousePress = async:callback(clickMe),
            --   mouseRelease = async:callback(clickMeStop),
            --     mouseMove = async:callback(clickMeMove)
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            -- position = v2(horizontal, vertical),
            vertical = not isHorizontal,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            name = name
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    --   size = v2(iconsizegrow * iw.rowCountX, width),
                    horizontal = isHorizontal,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center
                }
            }
        }
    }
    local myData = nil
    --  if (invMode) then
    --     myData = locDataInvMode[name]
    --  else
    --      myData = locData[name]
    --  end


    if (myData ~= nil) then
        ret.props = {
            -- relativePosition = v2(0.65, 0.8),
            position = v2(myData.xpos, myData.ypos),
            vertical = not isHorizontal,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            name = name
        }
    end
    return ui.create(ret)
end
local function renderCatWindow(iw)
    local topContent = {}

    local horizontal = 0.5
    local vertical = 0.0
    table.insert(topContent,
        I.ZackUtilsUI_ci.imageContent(getTexture("textures/omw_steam_button_l1.dds")))
    for index, cat in ipairs(iw.catTypes) do
        local tab = I.ZackUtilsUI_ci.boxedTextContent(cat, iw.catTypes[I.Deckwind.getCurrentCat()])
        tab.events = { mouseClick = async:callback(function()
            I.Deckwind.setCurrentCat(index)
            iw.scrollOffset = 0
            iw.selectedPosX, iw.selectedPosY = 1, 1
            iw:rebuildItemList()
            iw:reDraw()
        end) }
        table.insert(topContent, tab)
    end
    table.insert(topContent,
        I.ZackUtilsUI_ci.imageContent(getTexture("textures/omw_steam_button_r1.dds")))
    return createParentUi(topContent, horizontal, vertical, "CatChooser", true, iw, v2(0.5, 0))
end
local function getActorGoldCount(actor)
    if not actor then
        return -1000
    end
    --local baseGold = actor.type.records[actor.recordId].baseGold

    return I.CI_ActorGold.getActorGold(actor)
end
local function renderBarterWindow(goldValue, actor)
    local topContent = {}



    local horizontal = 1
    local vertical = 0

    local myGoldCount = types.Actor.inventory(self):countOf("gold_001")
    local sellerGoldCount = getActorGoldCount(actor)
    table.insert(topContent,
        I.ZackUtilsUI_ci.boxedTextContent("Price: " .. tostring(goldValue), nil, 0.5, nil, 30))
    table.insert(topContent,
        I.ZackUtilsUI_ci.boxedTextContent("Your Gold: " .. tostring(myGoldCount), nil, 0.5, nil, 30))
    table.insert(topContent,
        I.ZackUtilsUI_ci.boxedTextContent("Seller Gold: " .. tostring(sellerGoldCount), nil, 0.5, nil, 30))
    return createParentUi(topContent, horizontal, vertical, "CatChooser", true, nil, v2(1, 0), 20)
end

local function renderInfoWindow(iw)
    local topContent = {}



    local horizontal = 0.5
    local vertical = 01

    if (iw.selectedInvItem == nil) then
        return
    end
    if (iw.windowType == windowType.inventory) then
        --local record = iw.selectedInvItem.type.record(iw.selectedInvItem)

        table.insert(topContent,
            I.ZackUtilsUI_ci.boxedTextContent(padString(iw.selectedInvItem.name, 15), nil))
        table.insert(topContent,
            I.ZackUtilsUI_ci.boxedTextContent(padString("Value: " .. tostring(iw.selectedInvItem.value), 15), nil))
    elseif iw.windowType == windowType.magic then

    end
    return createParentUi(topContent, horizontal, vertical, "CatChooser", true, iw, v2(0.5, 1))
end
local function createItemWindow(contOrActor, posX, posY, favOnly, type, targetActor, isMagic, isSelected)
    local itemWindow = {}
    if not posX then
        posX = 0.25
    end
    if not posY then
        posY = 0.5
    end
    itemWindow.targetActor = targetActor
    itemWindow.parentObject = contOrActor
    if isSelected == nil then
        isSelected = true
    end
    itemWindow.selected = isSelected
    itemWindow.inventory = getInventory(contOrActor)
    itemWindow.ui = nil
    itemWindow.type = type
    itemWindow.headerUi = nil
    itemWindow.infoUi = nil
    itemWindow.favoritesOnly = false
    if favOnly then
        itemWindow.favoritesOnly = true
    end
    itemWindow.windowType = 0
    itemWindow.setType = setWindowType
    if not isMagic then
        itemWindow.listMode = playerSettings:get("useInventoryinListMode")
        itemWindow:setType(windowType.inventory)
    else
        itemWindow.listMode = true

        itemWindow:setType(windowType.magic)
    end
    itemWindow.posX = posX
    itemWindow.posY = posY
    itemWindow.itemDataList = buildItemList(getInventory(contOrActor):getAll(), itemWindow)
    itemWindow.rowCountX = 20
    itemWindow.rowCountY = 20
    if isMagic then
        itemWindow.rowCountX = playerSettings:get("magicListLength") or 20
        itemWindow.rowCountY = playerSettings:get("magicListLength") or 20
    end
    itemWindow.blockHeader = false
    itemWindow.selectedInvItem = nil
    itemWindow.filterItems = filterItems
    itemWindow.scrollOffset = 0
    itemWindow.toolTipData = nil
    itemWindow.rebuildItemList = function(iw, ignoreList)
        iw.itemDataList = buildItemList(getInventory(iw.parentObject):getAll(), iw, ignoreList)
    end
    itemWindow.transferAllToOtherInventory = function(iw, otherWindow)
        for index, value in ipairs(types.Actor.inventory(otherWindow.parentObject):getAll()) do
            iw:transferSelectedToOtherInventory(otherWindow, true, value)
        end
        I.UI.setMode()
    end
    itemWindow.transferSelectedToOtherInventory = function(iw, otherWindow, silent, item, count)
        local sourceObj = iw.parentObject
        local targetObj = otherWindow.parentObject

        local invItem
        local merchantObj = iw.parentObject
        if merchantObj.type == types.Player then
            merchantObj = otherWindow.parentObject
        end
        if not item then
            invItem = iw:getItemAt(iw.selectedPosX, iw.selectedPosY)
        else
            invItem = { item = item }
        end

        if invItem.count then
            if count == nil or invItem.count < count then
                count = invItem.count
            end
        else
            if count == nil or invItem.item.count < count then
                count = invItem.item.count
            end
        end

        if targetObj.type == types.Container then
            local itemWeight = invItem.item.type.record(invItem.item).weight
            if itemWeight and itemWeight > 0 then
                itemWeight = itemWeight * count
                local encData = renderStatBar.contEncumbranceData(targetObj)

                local nextWeight = encData.current + itemWeight
                if nextWeight > encData.base then
                    if not silent then
                        ui.showMessage(core.getGMST("sContentsMessage3"))
                    end
                    return
                end
            end
        end
        if invItem and invItem.item then
            if boundItemIds[invItem.item.recordId] and targetObj == self then
                if not silent then
                    ui.showMessage(core.getGMST("sContentsMessage1"))
                end
                return
            end
            if boundItemIds[invItem.item.recordId] and targetObj ~= self then
                if not silent then
                    ui.showMessage(core.getGMST("sBarterDialog12"))
                end
                return
            end
        end
        if not invItem then
            return
        end
        if iw.type then
            for index, value in ipairs(iw.itemDataList) do
                if value == invItem then
                    local found = false
                    for index2, value2 in ipairs(otherWindow.itemDataList) do
                        if value2.recordId == value.recordId and value2.pending ~= invItem.pending then
                            otherWindow.itemDataList[index2].count = otherWindow.itemDataList[index2].count + count
                            found = true
                        end
                    end

                    if not found then
                        local itemData = {}
                        itemData.icon = value.icon
                        itemData.name = value.name
                        itemData.value = value.value
                        itemData.type = value.type
                        itemData.enchant = value.enchant
                        itemData.equipped = false
                        itemData.recordId = value.recordId
                        itemData.count = count
                        itemData.item = value.item
                        itemData.pending = not value.pending

                        -- prepend stuff when selling so you actually see what
                        -- you're selling without scrolling to the last items
                        otherWindow.itemDataList = { itemData, table.unpack(otherWindow.itemDataList) }
                    end

                    if count == invItem.count then
                        table.remove(iw.itemDataList, index)
                        invItem.pending = not invItem.pending
                    else
                        invItem.count = invItem.count - count
                    end

                    if not silent then
                        otherWindow:reDraw()
                        iw:reDraw()
                        I.ZackUtilsUI_ci.playPickupSound(invItem.item)
                        I.Deckwind.updateBarterWindow(merchantObj)
                    end
                    return
                end
            end
        end

        for index, value in ipairs(iw.itemDataList) do
            if value == invItem then
                table.remove(iw.itemDataList, index)
                break
            end
        end
        if not silent then
            table.insert(otherWindow.itemDataList, invItem)
            otherWindow:reDraw()
            iw:reDraw()
            I.ZackUtilsUI_ci.playPickupSound(invItem.item)
        end
        core.sendGlobalEvent("CI_moveInto",
            { sourceObj = sourceObj, targetObj = targetObj, invItem = invItem.item, count = count, player = self })
    end
    itemWindow.dropSelected = function(iw, dropPos)
        local sourceObj = iw.parentObject
        local invItem = iw:getItemAt(iw.selectedPosX, iw.selectedPosY)
        if invItem and invItem.item then
            if boundItemIds[invItem.item.recordId] then
                ui.showMessage(core.getGMST("sBarterDialog12"))
                return
            end
            I.ZackUtilsUI_ci.playPickupSound(invItem.item)
            core.sendGlobalEvent("CI_moveInto",
                { sourceObj = sourceObj, dropPos = dropPos, invItem = invItem.item, player = self })
        else
            print("can't find it")
        end
    end
    itemWindow.drawWindow = function(iw)
        if iw.ui then
            iw.ui:destroy()
        end
        if (iw.listMode) then
            iw.ui = renderItemList(iw)
        else
            iw.ui = renderItemGrid(iw)
        end
        if not iw.blockHeader then
            iw.headerUi = renderCatWindow(iw)
        end
        I.CI_Background.drawBackground(true)
        --iw.infoUi = renderInfoWindow(iw)
    end
    itemWindow.fixCursorPos = function(iw)
        local currentItem = iw:getItemAt(iw.selectedPosX, iw.selectedPosY)
        if (currentItem ~= nil) then
            return
        end
        local itemList = iw:filterItems(iw.itemDataList, nil, iw.parentObject)
        if (#itemList == 0) then
            return
        end

        --local index = (iw.selectedPosX - 1) * iw.rowCountY + iw.selectedPosY + iw.scrollOffset
        --local lastItem = nil
        --if (index > #itemList) then
        iw.selectedPosX = 1
        iw.selectedPosY = 1
        --  end
    end
    itemWindow.setGridSize = function(iw, x, y)
        local screen = ui.screenSize()
        local tile = getIconSizeGrow()
        -- The two original Deckwind panels each occupy one half of the viewport.
        iw.rowCountX = math.max(1, math.min(x, math.floor((screen.x / 2 - 24) / tile)))
        iw.rowCountY = math.max(1, math.min(y, math.floor((screen.y - 108) / tile)))
        iw:reDraw()
    end

    itemWindow.reDraw = function(iw)
        if iw.ui then
            iw.ui:destroy()
        end
        if iw.toolTipData then
            iw.toolTipData:destroy()
        end
        if (iw.headerUi) then
            iw.headerUi:destroy()
        end
        if (iw.infoUi) then
            iw.infoUi:destroy()
        end
        if (iw.barterUi) then
            iw.barterUi:destroy()
        end
        if (iw.listMode) then
            iw.ui = renderItemList(iw)
        else
            iw.ui = renderItemGrid(iw)
        end
        if (iw.selected) then
            if not iw.blockHeader then
                iw.headerUi = renderCatWindow(iw)
            end
            if iw.type then
                --   iw.barterUi = renderBarterWindow(iw)
            end
            -- iw.infoUi = renderInfoWindow(iw)
            local item = iw:getItemAt(iw.selectedPosX, iw.selectedPosY)
            if item then
                if item.spell then
                    iw.toolTipData = I.ZackUtilsUI_ci.drawListMenu(tooltipgen.genToolTips(item),
                        itemWindowLocs.BottomCenter, iw.toolTipData, "InfoTips")
                    core.sendGlobalEvent("CI_removeItemHoverRender", {item = lastRenderedItem})
                    lastRenderedItem = nil
                else
                    iw.toolTipData = I.ZackUtilsUI_ci.drawListMenu(tooltipgen.genToolTips(item.item),
                        itemWindowLocs.BelowItem, iw.toolTipData, "InfoTips")
                end

                if item.type and item.type.baseType == types.Item and (lastRenderedItem == nil or lastRenderedItem.recordId ~= item.recordId) then
                    local fov = camera.getFieldOfView()
                    local hRatio = ui.screenSize().x / ui.screenSize().y

                    local cameraPos = camera.getPosition()
                    local cameraPitch = camera.getPitch()
                    local cameraYaw = camera.getYaw()

                    -- Forward direction
                    local x = math.cos(cameraPitch) * math.sin(cameraYaw)
                    local y = math.cos(cameraPitch) * math.cos(cameraYaw)
                    local z = math.sin(cameraPitch)
                    local forward = util.vector3(x, y, -z)

                    -- Right direction (perpendicular to forward, on horizontal plane)
                    local rightX = math.cos(cameraYaw)
                    local rightY = -math.sin(cameraYaw)
                    local rightZ = 0
                    local right = util.vector3(rightX, rightY, rightZ)

                    local up = right:cross(forward):normalize()

                    -- Desired direction for the item to face = opposite of camera forward
                    local targetDir = -forward
                    local defaultForward = util.vector3(0, 0, 1)  -- Assuming item faces +Z by default

                    -- Compute rotation axis and angle between the two vectors
                    local faceAxis = defaultForward:cross(targetDir)
                    local faceAngle = 0
                    if faceAxis:length() > 0 then
                        faceAxis = faceAxis:normalize()
                        faceAngle = math.acos(defaultForward:dot(targetDir))
                    end

                    local faceRotation = util.transform.rotate(faceAngle, faceAxis)

                    local spinAngle = -cameraYaw
                    local rotationAxis = -forward  -- already normalized

                    local spinRotation = util.transform.rotate(spinAngle, rotationAxis)

                    if lastRenderedItem ~= nil then
                        core.sendGlobalEvent("CI_removeItemHoverRender", {item = lastRenderedItem})
                        lastRenderedItem = nil
                    end

                    -- Final offset: 100 forward, 40 right, 5 up

                    local forwardOffset = forward * (5 - ((fov - 1.15) * (fov + 0.3)))
                    local rightOffset = right * fov * hRatio
                    local upOffset = up * 0
                    local finalOffset = forwardOffset + rightOffset + upOffset

                    core.sendGlobalEvent('CI_itemHoverRender', {
                        recordId = item.recordId,
                        cell = self.cell.name,
                        position = cameraPos + finalOffset,
                        rotation = spinRotation * faceRotation,
                        scale = 0.03237 * fov + 0.00817
                    })
                elseif item.type and item.type.baseType ~= types.Item then
                    core.sendGlobalEvent("CI_removeItemHoverRender", {item = lastRenderedItem})
                end
            end
        end
    end
    itemWindow.getItemAt = function(iw, x, y)
        local itemList = iw:filterItems(iw.itemDataList, nil, iw.parentObject)
        if (iw.listMode) then
            local index = (x) + iw.scrollOffset
            if index <= #itemList then
                local item = itemList[index]

                return item
            end
            return nil
        end
        local index = (x - 1) * iw.rowCountY + y + iw.scrollOffset
        if index <= #itemList then
            local item = itemList[index]
            return item
        end
        return nil
    end
    itemWindow.updateSelection = function(iw, x, y)
        --validate the specified position is valid, return if it is or not
    end
    itemWindow.setSelected = function(iw, select)
        iw.selected = select
    end
    itemWindow.destroy = function(iw)
        core.sendGlobalEvent("CI_removeItemHoverRender", {item = lastRenderedItem})
        lastRenderedItem = nil
        if iw.parentObject and iw.parentObject == self then
            --Cache current settings, so we can restore the cursor to the correct position--
            if iw.windowType == windowType.inventory then
                print("Saving inventory position " .. iw.selectedPosX .. " " .. iw.selectedPosY)
                previousInvCat = I.Deckwind.getCurrentCat()
                previousInvX = iw.selectedPosX
                previousInvY = iw.selectedPosY
            elseif iw.windowType == windowType.magic then
                print("Saving magic position " .. iw.selectedPosX .. " " .. iw.selectedPosY)
                previousMagicCat = I.Deckwind.getCurrentCat()
                previousMagicX = iw.selectedPosX
                previousMagicY = iw.selectedPosY
            end
        end
        if iw.ui then
            iw.ui:destroy()
        end
        I.CI_Background.destroyBackground()
        iw.ui = nil
        if (iw.headerUi) then
            iw.headerUi:destroy()
            iw.headerUi = nil
        end
        if (iw.infoUi) then
            iw.infoUi:destroy()
            iw.infoUi = nil
        end


        if iw.toolTipData then
            iw.toolTipData:destroy()
            iw.toolTipData = nil
        end
        iw = nil
    end
    --itemWindow:drawWindow()

    I.CI_Background.drawBackground(true)
    return itemWindow
end
local function CI_itemHoverRenderCreated(data)
    lastRenderedItem = data.item
end
local function onFrame(dt)
    local rightAxisX = input.getAxisValue(input.CONTROLLER_AXIS.RightX)
    local rightAxisY = input.getAxisValue(input.CONTROLLER_AXIS.RightY)
    if lastRenderedItem ~= nil and (math.abs(rightAxisX) + math.abs(rightAxisY)) > 0.08 then
        core.sendGlobalEvent("CI_updateRenderedItemRotation", {rightAxisX = rightAxisX, rightAxisY = rightAxisY, fov = camera.getFieldOfView()})
    end
end
return {
    interfaceName = "Controller_Item_Window",
    interface = { --I.Controller_Item_Window.testEffectIcons()
        version = 1,
        createItemWindow = createItemWindow,
        renderGridIcon = renderGridIcon,
        getTexture = getTexture,
        renderBarterWindow = renderBarterWindow,
        getActorGoldCount = getActorGoldCount,
        testEffectIcons = function()
            for index, value in pairs(core.magic.effects.records) do
                -- print(value.icon)
                local correctedIcon = getCorrectedIconPath(value.icon)
                if not vfs.fileExists(correctedIcon) then
                    print(correctedIcon)
                end
            end
        end
    },
    eventHandlers = {
        sendMessage = sendMessage,
        returnActivators = returnActivators,
        ClickedContainer = ClickedContainer,
        upDateinvWins = upDateinvWins,
        ClickedActor = ClickedActor,
        CI_itemHoverRenderCreated = CI_itemHoverRenderCreated,
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onFrame = onFrame,
        onActive = onActive,
        onControllerButtonPress = onControllerButtonPress,
        onInputAction = onInputAction,
        onSave = onSave,
        onKeyPress = onKeyPress,
        onLoad = onLoad,
        onControllerButtonRelease = onControllerButtonRelease,
    }
}
