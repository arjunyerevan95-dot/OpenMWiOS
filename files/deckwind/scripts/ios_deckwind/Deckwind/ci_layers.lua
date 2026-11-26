if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local ui = require("openmw.ui")
local const = require("scripts.ios_deckwind.Deckwind.ci_const")

if not const.doesRun then
    return {}
end
ui.layers.insertAfter("HUD", "Background", {interactive = false})


ui.layers.insertAfter("Windows", "Bindings", { interactive = true })
ui.layers.insertAfter("Windows", "InfoTips", {interactive = true})
ui.layers.insertAfter('Windows', 'InventoryWindow', { interactive = true })
ui.layers.insertAfter('Windows', 'CursorLayer', { interactive = false })




if not ui.layers.indexOf("InventoryWindow") then
end
if not ui.layers.indexOf("CursorLayer") and ui.layers.indexOf("InventoryWindow") then
end
