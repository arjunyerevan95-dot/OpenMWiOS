if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

if I.QuickSelect_Storage then
    return
end
local settings = storage.playerSection("SettingsQuickSelect")

local utility = require("scripts.ios_deckwind.QuickSelect.qs_utility")
local storedItems

local function getFavoriteItems()
    if not storedItems then
        storedItems = {}
        for i = 1, 30, 1 do
            storedItems[i] = { num = i, item = nil }
        end
    end
    return storedItems
end
local function getFavoriteItemData(slot)
    getFavoriteItems()
    return storedItems[slot]
end
local function deleteStoredItemData(slot)
    getFavoriteItems()
    storedItems[slot].spell     = nil
    storedItems[slot].spellType = nil
    storedItems[slot].enchantId = nil
    storedItems[slot].itemId    = nil
    storedItems[slot].item      = nil
end
local function saveStoredItemData(id, slot)
    getFavoriteItems()
    --print(id, slot)
    deleteStoredItemData(slot   )
    storedItems[slot].item      = id
end
local function saveStoredSpellData(spellId, spellType, slot)
    getFavoriteItems()
    deleteStoredItemData(slot   )
    storedItems[slot].spellType = spellType
    storedItems[slot].spell     = spellId
end
local function saveStoredEnchantData(enchantId, itemId, slot)
    getFavoriteItems()
    deleteStoredItemData(slot   )
    storedItems[slot].spellType = "Enchant"
    storedItems[slot].enchantId = enchantId
    storedItems[slot].itemId    = itemId
end
local function findItem(id)
    for index, value in ipairs(types.Actor.inventory(self)) do

    end
end
local function isSlotEquipped(slot)
    local item = getFavoriteItemData(slot)
    if item then
        if item.spell and not item.enchantId then
            local spell = types.Actor.getSelectedSpell(self)
            if not spell then return false end
            return spell.id == item.spell
        elseif item.enchantId then
            --print("enchant:", slot)
            local equip = types.Actor.getSelectedEnchantedItem(self)
            if not equip then return false end
            local realItem = types.Actor.inventory(self):find(item.itemId)
            if not realItem then return false end

            return types.Actor.getSelectedEnchantedItem(self).recordId == realItem.recordId
        elseif item.item then
            local equip = types.Actor.equipment(self)
            local realItem = types.Actor.inventory(self):find(item.item)
            if not realItem then return false end
            local slot = utility.findSlot(realItem)
            if not slot then
                return false
            end
            return equip[slot] == realItem
        end
    end
    return false
end
local function getEquipped(item)
    local equip = types.Actor.equipment(self)
    for index, value in pairs(equip) do
        if value == item then

            return index
        end
    end
    return nil
end
local function equipSlot(slot)
    local item = getFavoriteItemData(slot)
    if item then
        if item.spell and not item.enchantId then
            types.Actor.clearSelectedCastable(self)
            types.Actor.setSelectedSpell(self, item.spell)

            async:newUnsavableSimulationTimer(0.3, function()
                if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then
                    types.Actor.setStance(self, types.Actor.STANCE.Spell)
                end
            end)
        elseif item.enchantId then
            local equip = types.Actor.equipment(self)
            local realItem = types.Actor.inventory(self):find(item.itemId)
            if not realItem then return end
            types.Actor.setSelectedEnchantedItem(self, realItem)

            async:newUnsavableSimulationTimer(0.1, function()
                if types.Actor.getStance(self) ~= types.Actor.STANCE.Spell then
                    types.Actor.setStance(self, types.Actor.STANCE.Spell)
                end
            end)
        elseif item.item then
            local realItem = types.Actor.inventory(self):find(item.item)
            if not realItem then return end
            local equipped = getEquipped(realItem)
            if not equipped then
                core.sendGlobalEvent('UseItem', { object = realItem, actor = self })

                if realItem.type == types.Weapon or realItem.type == types.Lockpick or realItem.type == types.Probe then
                    async:newUnsavableSimulationTimer(0.1, function()
                        if types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon then
                            types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                        end
                    end)
                end
            elseif settings:get("unEquipOnHotkey") then
                local equip = types.Actor.equipment(self)
                equip[equipped] = nil

                types.Actor.setEquipment(self, equip)
            end
        end
    end

    async:newUnsavableSimulationTimer(0.1, function()
        I.QuickSelect_Hotbar.drawHotbar()
    end)
end

return {

    interfaceName = "QuickSelect_Storage",
    interface = {
        saveStoredItemData    = saveStoredItemData,
        getFavoriteItemData   = getFavoriteItemData,
        getFavoriteItems      = getFavoriteItems,
        saveStoredSpellData   = saveStoredSpellData,
        equipSlot             = equipSlot,
        saveStoredEnchantData = saveStoredEnchantData,
        isSlotEquipped        = isSlotEquipped,
        deleteStoredItemData = deleteStoredItemData,
    },
    engineHandlers = {
        onSave = function()
            return { storedItems = storedItems }
        end,
        onLoad = function(data)
            storedItems = data.storedItems
        end,
    }
}
