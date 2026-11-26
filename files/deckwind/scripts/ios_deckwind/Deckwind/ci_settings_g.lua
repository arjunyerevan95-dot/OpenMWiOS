local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local key = "SettingsControllerInterface"
local globalSettings = storage.globalSection(key)
I.Settings.registerGroup {
    key = key,
    page = key,
    l10n = "Deckwind",
    name = "Deckwind",
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "enableMod",
            renderer = "checkbox",
            name = "Enable Deckwind",
            description = "Restart OpenMW after changing this option.",
            default = false
        },
        {
            key = "defaultDialogCursor",
            renderer = "checkbox",
            name = "Default Dialog Window to Cursor mode",
            default = true
        },
        {
            key = "useSkyrimStyleSubmenuSelection",
            renderer = "checkbox",
            name = "Use Skyrim Style Submenu Selection",
            description = "If enabled, the directional, Skyrim-style submenu selection screen will be displayed upon pausing the game. If disabled, the previously viewed menu will be displayed.",
            default = true
        },
        {
            key = "useNewStatsWindow",
            renderer = "checkbox",
            name = "Use New Stats Window",
            default = false
        },
        {
            key = "useInventoryinListMode",
            renderer = "checkbox",
            name = "Use List Mode for inventory items",
            description = "Switches to list mode for inv items, instead of a grid. Experimental.",
            default = false
        },
        {
            key = "useSuppliedIcons",
            renderer = "checkbox",
            name = "Use Provided Magic Icons",
            description = "Use alternate icons when supplied by your game data.",
            default = false
        },
        {
            key = "devModeEnable",
            renderer = "checkbox",
            name = "Developer Mode Enable",
            description = "Enable developer hotkeys.",
            default = false
        },
        {
            key = "iconSize",
            renderer = "number",
            name = "Icon Size",
            default = 40
        },
        {
            key = "gridSizeContainer",
            renderer = "number",
            name = "Container Grid Size",
            default = 10
        },
        {
            key = "gridSizeInventory",
            renderer = "number",
            name = "Inventory Grid Size",
            default = 10
        },
        {
            key = "magicListLength",
            renderer = "number",
            name = "Magic Item List Length",
            default = 10
        },
    }
}
