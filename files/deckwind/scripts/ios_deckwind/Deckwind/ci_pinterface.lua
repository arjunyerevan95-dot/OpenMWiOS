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
local core_aux = require("scripts.ios_deckwind.Deckwind.aux_core")
local input = require("openmw.input")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
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
local acti = require("openmw.interfaces").Activation
local playerSelected
local const = require("scripts.ios_deckwind.Deckwind.ci_const")

if not const.doesRun then
    -- return {}
end
local key = "SettingsControllerInterface"
local playerSettings = storage.globalSection(key)
local function getIconSize()
    return playerSettings:get("iconSize") or 40
end
local function getIconSizeGrow()
    local ret = playerSettings:get("iconSize")
    return (playerSettings:get("iconSize")) + ret * 0.25
end
--local calculateTextScale() = 0.8
local Actor = require("openmw.types").Actor
local function imageContent(resource, size)
    if (size == nil) then
        size = getIconSize()
    end
    if not resource then
        return {
            --        type = ui.TYPE.Container,
            props = {
                size = util.vector2(size, size)
                -- relativeSize = util.vector2(1,1)
            }
        }
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
local function findSlot(item)
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
    elseif item.type == types.Lockpick then
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    elseif item.type == types.Probe then
        return types.Actor.EQUIPMENT_SLOT.CarriedRight
    elseif item.type == types.Light then
        return types.Actor.EQUIPMENT_SLOT.CarriedLeft
    end
    -- --print("Couldn't find slot for " .. item.recordId)
    return nil
end
local function getFatigueTerm(actor)
    local max = types.Actor.stats.dynamic.fatigue(actor).base + types.Actor.stats.dynamic.fatigue(actor).modifier
    local current = types.Actor.stats.dynamic.fatigue(actor).current

    local normalised = math.floor(max) == 0 and 1 or math.max(0, current / max)

    local fFatigueBase = core.getGMST("fFatigueBase")
    local fFatigueMult = core.getGMST("fFatigueMult")

    return fFatigueBase - fFatigueMult * (1 - normalised)
end
local function getDerivedDisposition(npc, clamp)
    if npc.type == types.Creature then
        error("Invalid actor provided")
    end
    if clamp == nil then
        clamp = true
    end
    local currentDisposition = types.NPC.getDisposition(npc, self)
    local baseDisposition = types.NPC.records[npc.recordId].baseDisposition
    local playerDiseased = false
    local npcFact = types.NPC.getFactions(npc)[1]
    local x = currentDisposition --need  crime disposition modifier
    -- if types.Actor.activeEffects(self):getEffect("commondisease").magnitude > 0 or types.Actor.activeEffects(self):getEffect("blightdisease").magnitude > 0 then
    --    x = x + core.getGMST("fDispDiseaseMod")
    -- end
    local fDispPersonalityBase = core.getGMST("fDispPersonalityBase")
    local fDispFactionRankMult = core.getGMST("fDispFactionRankMult")
    local fDispFactionRankBase = core.getGMST("fDispFactionRankBase")
    local playerPers = types.Actor.stats.attributes.personality(self).modified
    x = x + (fDispFactionRankMult * (playerPers - fDispPersonalityBase))
    local fDispFactionMod = core.getGMST("fDispFactionMod")
    local fDispWeaponDrawn = core.getGMST("fDispWeaponDrawn")
    local reaction = 0
    local rank = 0
    if npcFact then
        local factionRecord = core.factions.records[npcFact]
        local playerIsInFact = false
        for index, factId in ipairs(types.NPC.getFactions(self)) do
            if factId == factionRecord.id then
                playerIsInFact = true
                if types.NPC.isExpelled(self, factId) then
                    break
                end
                reaction = core.factions.records[factId].reactions[factId]
                rank = types.NPC.getFactionRank(self, factId)
            end
        end
        if not playerIsInFact then
            for index, factId in ipairs(types.NPC.getFactions(self)) do
                if factId ~= factionRecord.id then
                    if not types.NPC.isExpelled(self, factId) then
                        local playerFactionRecord = core.factions.records[npcFact]
                        local freaction = core.factions.records[npcFact].reactions[factId]
                        if index == 1 or freaction < reaction then
                            rank = types.NPC.getFactionRank(self, factId)
                            reaction = freaction
                        end
                    end
                end
            end
        end
    end
    local sameRace = types.NPC.record(self).race == types.NPC.records[npc.recordId].race
    local fDispRaceMod = core.getGMST("fDispRaceMod")
    if not sameRace then
        x = x + fDispRaceMod
    end
    local weaponDrawn = types.Actor.getStance(self) == types.Actor.STANCE.Weapon
    local charmAmount = types.Actor.activeEffects(npc):getEffect("charm").magnitude
    x = x + charmAmount
    if weaponDrawn then
        x = x + fDispWeaponDrawn
    end
    x = x + (fDispFactionRankMult * rank + fDispFactionRankBase) * fDispFactionMod * reaction;

    local fDispCrimeMod = core.getGMST("fDispCrimeMod")
    local fDispDiseaseMod = core.getGMST("fDispDiseaseMod")
    x = x + fDispCrimeMod * types.Player.getCrimeLevel(self)
    if playerDiseased then
        x = x + fDispDiseaseMod
    end

    if clamp and x > 100 then
        return 100
    elseif clamp and x < 0 then
        return 0
    else
        return x
    end
end
local function getBarterOffer(npc, basePrice, buying)
    if basePrice == 0 or npc.type == types.Creature then
        return basePrice
    end
    local disposition = types.NPC.getDisposition(npc, self) --) getDerivedDisposition(npc, false)
    local player = self
    local playerMerc = types.NPC.stats.skills.mercantile(self).modified

    local playerLuck = types.Actor.stats.attributes.luck(self).modified
    local playerPers = types.Actor.stats.attributes.personality(self).modified

    local playerFatigueTerm = getFatigueTerm(self)
    local npcFatigueTerm = getFatigueTerm(npc)

    -- Calculate the remaining parts of the function using the provided variables/methods
    local clampedDisposition = disposition
    local a = math.min(playerMerc, 100)
    local b = math.min(0.1 * playerLuck, 10)
    local c = math.min(0.2 * playerPers, 10)
    local d = math.min(types.NPC.stats.skills.mercantile(npc).modified, 100)
    local e = math.min(0.1 * types.Actor.stats.attributes.luck(npc).modified, 10)
    local f = math.min(0.2 * types.Actor.stats.attributes.personality(npc).modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * playerFatigueTerm
    local npcTerm = (d + e + f) * npcFatigueTerm
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.floor(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end
local function getTrainingPrice(npc, skill)
    local skillBase = types.NPC.stats.skills[skill](self).base
    local price = (skillBase) * core.getGMST("iTrainingMod")

    price = math.max(1, price);
    --price = types.NPC.barterOffer(npc,price,true)
    price = getBarterOffer(npc, price, true);
    return price
end
local function equipItem(itemId, actor,window)
    if actor and actor.id ~= self.id then
        actor:sendEvent("equipItem", itemId)
        return
    end
    if (itemId.recordId ~= nil) then
        itemId = itemId.recordId
    end
    if (itemId == nil) then return nil end
    if (itemId.recordId ~= nil) then itemId = itemId.recordId end
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        local prevItem = equip[slot]
        for i,x in ipairs(window.itemDataList) do
            if  x.item == prevItem then
                x.equipped = false
            elseif x.item == item then
                x.equipped = true
            end
        end
        equip[slot] = item
        types.Actor.setEquipment(self, equip)
    end
end
local function unequipItem(itemId, actor)
    if actor and actor.id ~= self.id then
        actor:sendEvent("unequipItem", itemId)
        return
    end
    if (itemId.recordId ~= nil) then
        itemId = itemId.recordId
    end
    local inv = types.Actor.inventory(self)
    local item = inv:find(itemId)
    local slot = findSlot(item)
    if (slot) then
        local equip = types.Actor.getEquipment(self)
        equip[slot] = nil
        types.Actor.setEquipment(self, equip)
    end
end
local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end

local function calculateTextScale()
    local screenSize = ui.layers[1].size
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    return scale
end
local function textContent(text, position, size, sizeModifier)
    if not size then
        size = 10 * calculateTextScale()
    end
    if sizeModifier then
        size = size * sizeModifier
    end
    if position and type(position) == "number" then
        position = nil
    end
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = tostring(text),
            textSize = size,
            arrange = alignment or ui.ALIGNMENT.Center,
            align = alignment or ui.ALIGNMENT.Center,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            relativePosition = v2(0, 0),
            -- position = position
        }
    }
end
local function textContentRight(text, position, size, sizeModifier)
    if not size then
        size = 10 * calculateTextScale()
    end
    if sizeModifier then
        size = size * sizeModifier
    end
    if position and type(position) == "number" then
        position = nil
    end
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = tostring(text),
            textSize = size,
            arrange = ui.ALIGNMENT.End,
            align = ui.ALIGNMENT.End,
            relativePosition = v2(1, 1),
            anchor = v2(1, 1),
            textAlignH = ui.ALIGNMENT.End,
            textAlignV = ui.ALIGNMENT.End,
            -- position = position
        }
    }
end
local function textContentLeft(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            relativePosition = v2(0.5, 0.5),
            text = tostring(text),
            textSize = 10 * calculateTextScale(),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end
local function paddedTextContent(text)
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                props = {
                    anchor = util.vector2(0, -0.5)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBoxed(item, bold)
    return {
        type = ui.TYPE.Container,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.borders,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textHeader,
                        props = {
                            text = item,
                            textSize = 10 * calculateTextScale(),
                            relativePosition = v2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function renderItemBold(item, bold)
    return {
        type = ui.TYPE.Container,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
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
                            textSize = 10 * calculateTextScale(),
                            relativePosition = v2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function renderTextInput(textLines, existingText, editCallback, OKCallback, OKText)
    if (OKText == nil) then
        OKText = "OK"
    end
    local vertical = 50
    local horizontal = (ui.layers[1].size.x / 2) - 400

    local vertical = 0
    local horizontal = ui.layers[1].size.x / 2 - 25
    local vertical = vertical + ui.layers[1].size.y / 2 + 100

    local content = {}
    for _, text in ipairs(textLines) do
        table.insert(content, I.ZackUtilsUI.textContent(text))
    end
    local textEdit = I.ZackUtilsUI.boxedTextEditContent(existingText, async:callback(editCallback))
    local okButton = I.ZackUtilsUI.boxedTextContent(OKText, async:callback(OKCallback))
    table.insert(content, textEdit)
    table.insert(content, okButton)

    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            --  anchor = v2(-1, -2),
            position = v2(horizontal, vertical),
            vertical = false,
            relativeSize = util.vector2(0.1, 0.1),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(400, 10),
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
                            textSize = 10 * calculateTextScale(),
                            arrange = ui.ALIGNMENT.Center
                        }
                    }
                }
            }
        }
    }
end
local function renderItemChoiceReal(itemList, selectedItem, horizontal, vertical, align, anchor)
    local content = {}
    for _, item in ipairs(itemList) do
        if (item == selectedItem) then
            local itemLayout = renderItemBold(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        else
            local itemLayout = renderItem(item)
            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    table.insert(content, renderItemBoxed("OK"))
    return ui.create {
        layer = "InventoryWindow",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    align = align,
                }
            }
        }
    }
end
local function renderItemChoice(itemList, horizontal, vertical, align, anchor)
    local content = {}
    for _, item in ipairs(itemList) do
        local itemLayout = renderItem(item)
        itemLayout.template = I.MWUI.templates.padding
        table.insert(content, itemLayout)
    end
    return ui.create {
        layer = "InventoryWindow",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,
                    arrange = align,
                    align = align,
                }
            }
        }
    }
end
local scale = 1.2
local function renderTextWithBox(tableItem, horizontal, vertical, size)
    if (size == nil) then
        size = 8 * scale
    else
        size = size * scale
    end


    local content = {}
    local itemLayout = renderItemBold(tableItem.Name)
    table.insert(content, itemLayout)
    local resource = ui.texture { -- texture in the top left corner of the atlas
        path = 'textures/ashlanderarchitect/' .. tableItem.Texture_Name .. ".png"
    }
    table.insert(content, imageContent(resource, size))
    return ui.create {
        layer = "InventoryWindow",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            --  anchor = v2(-1, -2),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = v2(horizontal, vertical),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content(content)
    }
end
local function boxedTextContent(text, callback, textScale, name, winSize)
    if textScale == nil then
        textScale = 1
    end
    if not winSize then
        winSize = 30
    end
    local template = I.MWUI.templates.textNormal
    if (callback == text) then
        template = I.MWUI.templates.textHeader
    end
    text = text .. "     "
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                props = {
                    anchor = util.vector2(0, -0),
                    size = util.vector2(winSize, 0)
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = template,
                        props = {
                            text = text,
                            textSize = (15 * calculateTextScale()) * textScale,
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Center,
                            name = name,
                        }
                    }
                }
            }
        }
    }
end
local function GenerateRow(item1, item2, item3)
    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = {
                    anchor = util.vector2(0, -0.5),
                    horizontal = false,
                },
                content = ui.content({ item1, item2, item3 })
            }
        }
    }
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

local function renderItemWithIcon(item, bold, icon)
    local resource = ui.texture { -- texture in the top left corner of the atlas
        path = icon
    }
    return {
        type = ui.TYPE.Container,
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
                            anchor = v2(0, 0),
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
            local itemLayout = nil
            if icon == nil then
               itemLayout = renderItemX(text, false, fontSize)
            else
               itemLayout = renderItemWithIcon(text, false, icon)
            end

            itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        end
    end
    return ui.create {
        layer = layer or "InventoryWindow",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = anchor,
            relativePosition = v2(horizontal, vertical),
            arrange = align,
            align = align,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    vertical = true,

                    arrange = ui.ALIGNMENT.Start,
                    align = align,
                }
            }
        }
    }
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
    Disabled = { disabled = true }
}
local function getArmorType(armor)
    if armor.type ~= types.Armor and not armor.baseArmor then
        error("Not Armor")
    end
    local record = nil
    if armor.baseArmor then --A record was supplied, not a gameObject
        record = armor
    else
        record = types.Armor.record(armor)
    end
    local epsilon = 0.0005;
    local lightMultiplier = core.getGMST("fLightMaxMod") + epsilon
    local medMultiplier = core.getGMST("fMedMaxMod") + epsilon
    local armorGMSTs = {
        [types.Armor.TYPE.Boots] = "iBootsWeight",
        [types.Armor.TYPE.Cuirass] = "iCuirassWeight",
        [types.Armor.TYPE.Greaves] = "iGreavesWeight",
        [types.Armor.TYPE.Shield] = "iShieldWeight",
        [types.Armor.TYPE.LBracer] = "iGauntletWeight",
        [types.Armor.TYPE.RBracer] = "iGauntletWeight",
        [types.Armor.TYPE.RPauldron] = "iPauldronWeight",
        [types.Armor.TYPE.LPauldron] = "iPauldronWeight",
        [types.Armor.TYPE.Helmet] = "iHelmWeight",
        [types.Armor.TYPE.LGauntlet] = "iGauntletWeight",
        [types.Armor.TYPE.RGauntlet] = "iGauntletWeight",
    }
    local armorType = record.type
    local weight = record.weight
    local armorTypeWeight = math.floor(core.getGMST(armorGMSTs[armorType]))

    if weight <= armorTypeWeight * lightMultiplier then
        return "Light"
    elseif weight <= armorTypeWeight * medMultiplier then
        return "Medium"
    else
        return "Heavy"
    end
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
local function boxedTextEditContent(text, callback, textScale, width)
    if textScale == nil then
        textScale = 1
    end
    if width == nil then
        width = 400
    end
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = {
                    anchor = util.vector2(0, -0.5),
                    size = util.vector2(400, 10),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.TextEdit,
                        template = I.MWUI.templates.textEditLine,
                        events = { textChanged = callback },
                        props = {
                            text = text,
                            size = util.vector2(width, 30),
                            textAlignH = 15,
                            textSize = (25 * calculateTextScale()) * textScale,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local cachedSounds = {}

local function getObjectPrefix(object, add)
    if object.type == types.Miscellaneous then
        return "Item Misc" .. add
    else
        local try = "Item " .. tostring(object.type) .. add
        try = try:lower()
        for index, value in ipairs(core.sound.sounds) do
            if value.id == try then
                cachedSounds[try] = value.id
                return value.id
            end
        end
        cachedSounds[try] = "Item Misc" .. add
        return "Item Misc" .. add
    end
end
--I.ZackUtilsUI_ci.playPickupSound(item)
local function playPickupSound(item)
    local soundName = core_aux.getPickupSound(item)

    ambient.playSound(soundName:lower())
end
local function playDropSound(item)
    local soundName = core_aux.getDropSound(item)
    ambient.playSound(soundName:lower())
end
local function findItemIcon(item)
    if (item == nil or item.type == nil or item.type.records[item.recordId] == nil or item.type.records[item.recordId].icon == nil) then
        return nil
    end
    return item.type.records[item.recordId].icon
end
return {
    interfaceName = "ZackUtilsUI_ci",
    interface = {
        version = 1,
        imageContent = imageContent,
        textContent = textContent,
        textContentLeft = textContentLeft,
        paddedTextContent = paddedTextContent,
        boxedTextContent = boxedTextContent,
        renderItemX = renderItemX,
        hoverOne = hoverOne,
        playPickupSound = playPickupSound,
        playDropSound = playDropSound,
        textContentRight = textContentRight,
        hoverTwo = hoverTwo,
        hoverNone = hoverNone,
        GenerateRow = GenerateRow,
        boxedTextEditContent = boxedTextEditContent,
        renderItemChoice = renderItemChoice,
        renderTextWithBox = renderTextWithBox,
        renderTextInput = renderTextInput,
        renderTravelOptions = renderTravelOptions,
        renderItemChoiceReal = renderItemChoiceReal,
        getBarterOffer = getBarterOffer,
        findSlot = findSlot,
        equipItem = equipItem,
        unequipItem = unequipItem,
        findItemIcon = findItemIcon,
        drawListMenu = drawListMenu,
        getArmorType = getArmorType,
        getDerivedDisposition = getDerivedDisposition,
        getTrainingPrice = getTrainingPrice,
    },
}
