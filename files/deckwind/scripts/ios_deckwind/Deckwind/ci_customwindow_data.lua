if not require("scripts.ios_deckwind.Deckwind.ci_const").doesRun then return {} end
local categories = {}
local menuItems = {}
local function addCategory(cat)
    local exists = false
    for index, value in ipairs(categories) do
        if value:lower() == cat:lower() then
            exists = true
            break
        end
    end
    if not exists then
        table.insert(categories, cat)
    end
end
local function addMenuItem(text,category,icon,barData, tooltipLines, rightText,actionText)
    if not text then
        error("no text")
    end
    local item = {
        text = text,
        category = category,
        icon = icon,
        barData = barData,
        tooltipLines = tooltipLines,
        rightText = rightText,
        actionText = actionText,
    }
    --addCategory(category)
    table.insert(menuItems, item)

end
local function getMenuItems(category)
    local items = {}
    if type(category) == "number" then
        category = categories[category]
    end
    for index, value in ipairs(menuItems) do
        if   (type(category) == "string" and value.category:lower() == category:lower() ) then
            table.insert(items, value)
         --   print(value.text)
        end
    end
    return items

end
local function clear()
    menuItems = {}
    categories = {}
end

return {
    interfaceName = "CustomWindowData",
    interface = {
        addCategory = addCategory,
        addMenuItem = addMenuItem,
        getMenuItems = getMenuItems,
        clear = clear,
        getCategories = function()
            return categories
        end
    },
    eventHandlers = {
    }
}
