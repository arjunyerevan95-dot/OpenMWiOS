local core = require("openmw.core")

local self = require("openmw.self")
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local async = require('openmw.async')
local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local settings = storage.playerSection("SettingsQuickSelect")

I.Settings.registerPage {
    key = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "QuickSelect",
    description = "These settings allow you to modify the behavior of the Quickselect bar."
}
I.Settings.registerGroup {
    key = "SettingsQuickSelect",
    page = "SettingsQuickSelect",
    l10n = "SettingsQuickSelect",
    name = "Main Settings",
    permanentStorage = true,
description = [[
    These settings allow you to modify the behavior of the Quickselect bar.

    It allows for up to 3 separate hotbars, and you can select an item with 1-10, or use the arrow keys(when enabled), or the DPad on a controller to pick a slot.

    You should unbind the normal quick items before enabling this mod.
    ]],
    settings = {
        {
            key = "previewOtherHotbars",
            renderer = "checkbox",
            name = "Show Next and Previous Hotbars",
            description =
            "If enabled, a preview of the next and previous hotbars will be shown above and below the current hotbar.",
            default = false
        },
        {
            key = "persistMode",
            renderer = "checkbox",
            name = "Show Hotbar at all times",
            description =
            "If enabled, the hotbar will be visible at any time. If disabled, the hotbar will only be visible a hotkey is being selected, then will close when one is selected.",
            default = true
        },
        {
            key = "unEquipOnHotkey",
            renderer = "checkbox",
            name = "Unequip when selecting equipped items",
            description =
            "If enabled, selecting an item that is already equipped will unequip it. If disabled, selecting an item that is already equipped will do nothing.",
            default = true
        },
        {
            key = "showNumbersForEmptySlots",
            renderer = "checkbox",
            name = "Show numbers for empty slots",
            description =
            "If enabled, empty slots will show a number indicating the slot number. If disabled, empty slots will be blank.",
            default = true
        },
        {
            key = "pauseWhenSelecting",
            renderer = "checkbox",
            name = "Pause While Selecting",
            description =
            "If enabled, the game will pause while selecting a slot on the hotbar. If disabled, the game will continue.",
            default = false
        },
        {
            key = "useArrowKeys",
            renderer = "checkbox",
            name = "Use Arrow Keys for Selection",
            description =
            "If enabled, you can use the arrow keys on your keyboard as if they were a DPad.",
            default = false
        },
        {
            key = "hotBarOnTop",
            renderer = "checkbox",
            name = "Set Hotbar on Top",
            description =
            "If enabled, the hotbar will be displayed at the top.",
            default = false
        },
        {
            key = "barSelectionMode",
            renderer = "select",
            name = "Bar Selection Key",
            default = "Shift Modifier",
            description = "The keys used to select a different hotbar. If Shift Modifier is used, shift+1-3 will select the corresponding hotbar. If -/= Keys is used, - and = will select the previous and next hotbars. If [/] Keys is used, [ and ] will select the previous and next hotbars.\n\nThe described keys should be unbound in the settings if you'd like to use them. The same applies to the DPad.",
            argument = {
                disabled = false,
                l10n = "AshlanderArchitectButtons",
                items = { "Shift Modifier", "-/= Keys", "[/] Keys" },
            },
        },
    },

}
settings:get("unEquipOnHotkey")
return settings
