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

local const = require("scripts.ios_deckwind.Deckwind.ci_const")

if not const.doesRun then
    return {}
end
local selectedTab = 1
local key = "SettingsControllerInterface"
local playerSettings = storage.globalSection(key)
local function getIconSize()
    return playerSettings:get("iconSize")
end
local function getIconSizeGrow()
    local ret = playerSettings:get("iconSize")
    return (playerSettings:get("iconSize")) + (ret * 0.25)
end

local function getCorrectedIconPath(path)
    if not playerSettings:get("useSuppliedIcons") then
        return path
    else
        local pathCheck = "icons\\jicons\\" .. path
        if not vfs.fileExists(pathCheck) then
            print("missing ", path)
            if not vfs.fileExists(path) then
                local ddsReplacedByTga = string.gsub(path, ".dds", ".tga")
                if vfs.fileExists(ddsReplacedByTga) then
                    return ddsReplacedByTga
                end
            end
            return path
        else
            return pathCheck
        end
    end
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
local function mouseClick(mouseEvent, data)
    local px = data.props.px
    local py = data.props.py

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
    Disabled = { disabled = true }
}

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
    if not path then return nil end
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
                arrange = ui.ALIGNMENT.Start,
                size = size,
                autosize = false
            }
        }
    }
end
local function flexedItems3(content1,content2,content3, horizontal, size)
    if not horizontal then
        horizontal = false
    end
    return {
        {
            type = ui.TYPE.Flex,
            content = ui.content(content1),
            events = {
                mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Start,
                size = size,
                autosize = false
            }
        },
        {
            type = ui.TYPE.Flex,
            content = ui.content(content2),
            events = {
                mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
                size = size,
                autosize = false
            }
        },
        {
            type = ui.TYPE.Flex,
            content = ui.content(content3),
            events = {
                mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.End,
                arrange = ui.ALIGNMENT.End,
                size = size,
                autosize = false
            }
        }
    }
end
local function renderListItem(iw, selected, textx, item)
    local itemIcon = nil
    local resource2
    --item is from the menuItems table in ci_customwindow_data.lua
    local text = ""

    local resources = nil
    local magicIcon = nil
    local spacing = "   "
    local rightText = ""
    if item and item.icon then
        magicIcon = getTexture(getCorrectedIconPath(item.icon))
    else
    end
    if item then
        text = item.text
    end

    if item and item.rightText then
        rightText = item.rightText
    end
    local contentLeft = {}
    local contentCenter = {}
    local contentRight = {}

    --  if magicIcon then
    table.insert(contentLeft, I.ZackUtilsUI_ci.imageContent(magicIcon))

    --  end

    table.insert(contentLeft, I.ZackUtilsUI_ci.textContent(spacing .. text))

    table.insert(contentRight, I.ZackUtilsUI_ci.textContentRight(rightText, util.vector2(600, 0), nil, 2))
    if item and item.barData then
        local barData = item.barData
        local bar = renderStatBar.renderBar(barData.color, barData.max, barData.current, util.vector2(400, 0),
            util.vector2(120, getIconSize() * 0.8))
        table.insert(contentCenter, bar)
    end
    -- resource2 = ui.texture({ path = "textures/omw_menu_icon_active.dds" })

    local sizeX = getIconSize() * 15
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
                content = ui.content(flexedItems3(contentLeft,contentCenter,contentRight, true, util.vector2(sizeX, getIconSize())))
                --content = content
            }
        }
    }

    return box
    --    table.insert(content, box)
    --    return box
end
local function generateListItems()
    local ret = {}
    local createListItem = function(strig, iconTable, lines)
        return { text = strig, icon = iconTable, tooltipLines = lines }
    end
    local items = I.CustomWindowData.getMenuItems(selectedTab)

    for index, item in ipairs(items) do
        local listItem = item
        table.insert(ret, listItem)
    end

    -- table.sort(ret, function(a, b) return (a.name or "") < (b.name or "") end)
    return ret
end


local function filterItems()
    return generateListItems(iw)
end
local function renderItemList(iw)
    local posX = iw.posX
    local posY = iw.posY
    local itemList = nil

    itemList = iw:filterItems(iw.itemDataList, nil, iw.parentObject)

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
            itemLayout.template = I.MWUI.templates.padding
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
        events = {
            -- mousePress = async:callback(clickMe),
            -- mouseRelease = async:callback(clickMeStop),
            -- mouseMove = async:callback(clickMeMove)
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            size = v2(getIconSizeGrow() * iw.rowCountX, getIconSizeGrow() * iw.rowCountY),
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
    for index, cat in ipairs(I.CustomWindowData.getCategories()) do
        table.insert(topContent,
            I.ZackUtilsUI_ci.boxedTextContent(cat, I.CustomWindowData.getCategories()[selectedTab]))
    end
    table.insert(topContent,
        I.ZackUtilsUI_ci.imageContent(getTexture("textures/omw_steam_button_r1.dds")))
    return createParentUi(topContent, horizontal, vertical, "CatChooser", true, iw, v2(0.5, 0))
end
local function createCustomWindow(windowType)
    local itemWindow = {}
    local posX = 0.5
    local posY = 0.5
    itemWindow.ui = nil
    itemWindow.type = type
    itemWindow.headerUi = nil
    itemWindow.infoUi = nil
    itemWindow.favoritesOnly = false
    itemWindow.windowType = windowType

    itemWindow.listMode = true
    itemWindow.posX = posX
    itemWindow.posY = posY
    itemWindow.selected = true
    itemWindow.isCustomWindow = true
    itemWindow.selectNextCat = function(iw)
        selectedTab = selectedTab + 1
        if selectedTab > #I.CustomWindowData.getCategories() then
            selectedTab = 1
        end
        iw:reDraw()
    end
    itemWindow.selectPrevCat = function(iw)
        selectedTab = selectedTab - 1
        if selectedTab < 1 then
            selectedTab = #I.CustomWindowData.getCategories()
        end
        iw:reDraw()
    end
    itemWindow.itemDataList = I.CustomWindowData.getMenuItems(selectedTab)
    itemWindow.rowCountX = playerSettings:get("magicListLength") or 20
    itemWindow.rowCountY = playerSettings:get("magicListLength") or 20
    itemWindow.blockHeader = false
    itemWindow.selectedInvItem = nil
    itemWindow.selectedPosX = 1
    itemWindow.filterItems = filterItems
    itemWindow.selectedPosY = 1
    itemWindow.scrollOffset = 0
    itemWindow.toolTipData = nil
    itemWindow.rebuildItemList = function(iw, ignoreList)
        iw.itemDataList = I.CustomWindowData.getMenuItems(selectedTab)
    end
    itemWindow.drawWindow = function(iw)
        iw.ui = renderItemList(iw)
        if not iw.blockHeader then
            iw.headerUi = renderCatWindow(iw)
        end
        I.CI_Background.drawBackground()
        --iw.infoUi = renderInfoWindow(iw)
    end
    itemWindow.fixCursorPos = function(iw)
        local currentItem = iw:getItemAt(iw.selectedPosX, iw.selectedPosY)
        if (currentItem ~= nil) then
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
        iw.rowCountX = x
        iw.rowCountY = y
        iw:reDraw()
    end

    itemWindow.reDraw = function(iw)
        ----print("wind redraw")
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
            if item and item.tooltipLines then
                iw.toolTipData = I.ZackUtilsUI_ci.drawListMenu(item.tooltipLines,
                    itemWindowLocs.BottomCenter, iw.toolTipData, "InfoTips")
            elseif item then
                print("No tooltip lines")
            end
        end
    end
    itemWindow.getItemAt = function(iw, x)
        local itemList = iw:filterItems()
        local index = (x) + iw.scrollOffset
        if index <= #itemList then
            local item = itemList[index]

            return item
        end
        return nil
    end
    itemWindow.setSelected = function(iw, select)
        iw.selected = select
    end
    itemWindow.setType = function(iw, type)
        -- If the type is different, destroy the old window, as it will be replaced by the new one
        if iw.windowType ~= type then
            iw:destroy()
        end
    end
    itemWindow.destroy = function(iw)
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

        -- Unset the selected window
        I.Deckwind.setCustomWindow(nil)
        return "done"
    end
    itemWindow:drawWindow()

    I.CI_Background.drawBackground()
    return itemWindow
end
return {
    interfaceName = "Controller_Custom_Window",
    interface = { --I.Controller_Item_Window.testEffectIcons()
        version = 1,
        createCustomWindow = createCustomWindow,
        getTexture = getTexture,
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
    },
    engineHandlers = {
    }
}
