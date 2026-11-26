local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local input = require("openmw.input")

local const = require("scripts.ios_deckwind.Deckwind.ci_const")

if not const.doesRun then
    return {}
end

local DebugWindowElement
local hoveredOverId
local columnsAndRows = {}
local selectedCol = 1
local selectedRow = 1

local scale = 0.8
--[[
--Dump this.Start over.


--SECTIONS:

Character: Dynamic Stat Values Level, Race, Class, Birthsign, Reputation/Bounty
Attributes
Factions

Major Skills 5
Minor Skills 5
Misc Skills 5 4 4 4



--]]
local function scaledVector2(x, y)
    return util.vector2(x * scale, y * scale)
end
local function mouseMove(mouseEvent, data)
    local id = data.id
    if hoveredOverId ~= id then
        hoveredOverId = id
        for attributeIndex, attribute in ipairs(columnsAndRows) do
            for skillIndex, skill in ipairs(attribute) do
                if skill == id then
                    selectedCol = attributeIndex
                    selectedRow = skillIndex
                    I.CI_DebugMenu.drawDebugMenu()
                    return
                end
            end
        end
        I.CI_DebugMenu.drawDebugMenu()
    end
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
                mouseMove = async:callback(mouseMove),
            },
            props = {
                horizontal = horizontal,
                align = ui.ALIGNMENT.Start,
                arrange = ui.ALIGNMENT.Start,
                --     size = util.vector2(100, 100),
                autosize = true
            }
        }
    }
end
local function flexedItemsDouble(content, content2, horizontal)
    if not horizontal then
        horizontal = false
    end
    return ui.content {
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
                --     size = util.vector2(100, 100),
                autosize = true
            }
        },
        {
            type = ui.TYPE.Flex,
            content = ui.content(content2),
            events = {
                mouseMove = async:callback(mouseMove),
            },
            props = {
                position = util.vector2(140, 0),
                anchor = util.vector2(1, 0),
                horizontal = horizontal,
                align = ui.ALIGNMENT.End,
                arrange = ui.ALIGNMENT.End,
                --     size = util.vector2(100, 100),
                autosize = true
            }
        }
    }
end
local function renderItemBold(item, bold, id, tooltipData)
    if not id then id = item end
    local textTemplate = I.MWUI.templates.textNormal
    if bold or hoveredOverId == id then
        textTemplate = I.MWUI.templates.textHeader
    end
    return {
        type = ui.TYPE.Container,
        id = id,
        tooltipData = tooltipData,
        props = {
            --  anchor = util.vector2(-1,0),
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(1, 0.5),
            arrange = ui.ALIGNMENT.Center,
        },
        events = {
            mouseMove = async:callback(mouseMove),
            --  mousePress = async:callback(mouseClick),
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = textTemplate,
                        props = {
                            text = item,
                            textSize = 20 * scale,
                            relativePosition = util.vector2(0.5, 0.5),
                            arrange = ui.ALIGNMENT.Center,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end

local function renderButton(text)
    local itemTemplate
    itemTemplate = I.MWUI.templates.boxThick

    return {
        type = ui.TYPE.Container,
        --  events = {},
        template = itemTemplate,
        content = ui.content { renderItemBold(text) },
    }
end
local function renderItemBoxed(content, size, itemTemplate)
    local text
    if not size then
        size = scaledVector2(100, 100)
    end
    if not itemTemplate then
        itemTemplate = I.MWUI.templates.borders
    end

    return {
        type = ui.TYPE.Container,
        --    events = {},
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
local function getSkillBase(skillID, actor)
    return types.NPC.stats.skills[skillID:lower()](actor).base
end
local function getAttributeBase(skillID, actor)
    return types.NPC.stats.attributes[skillID:lower()](actor).base
end
local currentColumn = 0
local function addColumn(tablel, header, startOffset, limit, column, dataSource, getBaseValueFunc)
    currentColumn = currentColumn + 1
    local myItems = {}
    local attribContent = {}
    local attribContent2 = {}
    local xContent = {}
    local itemName = header
    table.insert(attribContent, renderItemBold(itemName, true))
    table.insert(attribContent2, renderItemBold("", false))
    local itemIndex = 0
    local addedItems = 0
    if not columnsAndRows[currentColumn] then
        columnsAndRows[currentColumn] = {}
    end
    if not tablel then
        for _, item in ipairs(dataSource) do
            itemIndex = itemIndex + 1

            columnsAndRows[currentColumn][itemIndex] = item.id
            local itemName = tostring(item.name)
            -- Retrieve the base value using the specified function
            local itemBase = getBaseValueFunc(item.id, self)

            table.insert(myItems, itemName)
            table.insert(attribContent, renderItemBold(itemName, false, item.id))
            table.insert(attribContent2, renderItemBold(tostring(itemBase), false, item.id))
            addedItems = addedItems + 1
        end
    else
        for index, itemId in ipairs(tablel or dataSource) do
            if not startOffset or index >= startOffset then
                for _, item in ipairs(dataSource) do
                    if item.id == itemId then
                        itemIndex = itemIndex + 1

                        columnsAndRows[currentColumn][itemIndex] = item.id
                        local itemName = tostring(item.name)
                        -- Retrieve the base value using the specified function
                        local itemBase = getBaseValueFunc(item.id, self)

                        table.insert(myItems, itemName)
                        table.insert(attribContent, renderItemBold(itemName, false, item.id))
                        table.insert(attribContent2, renderItemBold(tostring(itemBase), false, item.id))
                        addedItems = addedItems + 1
                        break -- Break the inner loop once a match is found
                    end
                end
                if limit and itemIndex == limit then
                    break
                end
            end
        end
    end

    return renderItemBoxed(flexedItemsDouble(attribContent, attribContent2, false), scaledVector2(180, 220))
end
local function getMiscSkills(class)
    local miscSkills = {}
    for index, skill in ipairs(core.stats.Skill.records) do
        local isMisc = true
        for index, skillId in ipairs(class.minorSkills) do
            if skillId == skill.id then
                isMisc = false
            end
        end
        for index, skillId in ipairs(class.majorSkills) do
            if skillId == skill.id then
                isMisc = false
            end
        end
        if isMisc then
            table.insert(miscSkills, skill.id)
        end
    end
    return miscSkills
end
local miscSkills
local function drawDebugMenu()
    local myClass = types.NPC.classes.record(types.NPC.record(self).class)
    if DebugWindowElement then
        DebugWindowElement:destroy()
    end
    local content    = {}
    local xContent   = {}

    --major skills

    local myName     = types.NPC.record(self).name
    local headerText = renderItemBold(myName, true)
    if not miscSkills then
        miscSkills = getMiscSkills(myClass)
    end
    table.insert(content, headerText)
    table.insert(xContent,
        addColumn(myClass.majorSkills, "Major Skills", nil, nil, nil, core.stats.Skill.records, getSkillBase))
    table.insert(xContent,
        addColumn(myClass.minorSkills, "Minor Skills", nil, nil, nil, core.stats.Skill.records, getSkillBase))
    table.insert(xContent, addColumn(miscSkills, "Misc Skills", 1, 5, nil, core.stats.Skill.records, getSkillBase))
    table.insert(xContent, addColumn(miscSkills, "", 6, 4, nil, core.stats.Skill.records, getSkillBase))
    table.insert(xContent, addColumn(miscSkills, "", 10, 4, nil, core.stats.Skill.records, getSkillBase))
    table.insert(xContent, addColumn(miscSkills, "", 14, 4, nil, core.stats.Skill.records, getSkillBase))
    --print(#miscSkills)
    local skillRow = renderItemBoxed(flexedItems(xContent, true), util.vector2((160 * scale) * 7, 220 * scale),
        I.MWUI.templates.padding)
    table.insert(content, skillRow)


    xContent = {}
    local attirbutes = {}

    table.insert(xContent, addColumn(nil, "Attributes", nil, nil, nil, core.stats.Attribute.records, getAttributeBase))
    local secondRow = renderItemBoxed(flexedItems(xContent, true), util.vector2((160 * scale) * 7, 250 * scale),
        I.MWUI.templates.padding)
    table.insert(content, secondRow)
    local knownTrainers = {}
    local spacelessId = ""

    local trainerRow = renderItemBoxed(flexedItems(knownTrainers, false), util.vector2((160 * scale) * 7, 400 * scale),
        I.MWUI.templates.padding)
    table.insert(content, trainerRow)
    -- table.insert(content, imageContent(resource, size))
    DebugWindowElement = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = util.vector2(0, 0),
                }
            }
        }
    }
end



local function onKeyPress(key)
    if not DebugWindowElement then return end

    local nextCol = selectedCol
    local nextRow = selectedRow
    if key.code == input.KEY.LeftArrow then
        nextCol = nextCol - 1
    elseif key.code == input.KEY.RightArrow then
        nextCol = nextCol + 1
    elseif key.code == input.KEY.DownArrow then
        nextRow = nextRow + 1
    elseif key.code == input.KEY.UpArrow then
        nextRow = nextRow - 1
    end
    if not columnsAndRows[nextCol] or not columnsAndRows[nextCol][nextRow] then

    else
        hoveredOverId = columnsAndRows[nextCol][nextRow]
        selectedCol = nextCol
        selectedRow = nextRow
        drawDebugMenu()
    end
end
local function TriggerItem()
    print(hoveredOverId)
end
local function onControllerButtonPress(id)
    if not DebugWindowElement then return end

    local nextCol = selectedCol
    local nextRow = selectedRow
    if id == input.CONTROLLER_BUTTON.DPadLeft then
        nextCol = nextCol - 1
    elseif id == input.CONTROLLER_BUTTON.DPadRight then
        nextCol = nextCol + 1
    elseif id == input.CONTROLLER_BUTTON.DPadDown then
        nextRow = nextRow + 1
    elseif id == input.CONTROLLER_BUTTON.DPadUp then
        nextRow = nextRow - 1
    elseif id == input.CONTROLLER_BUTTON.A then
        TriggerItem()
    end
    ui.showMessage("press")
    print("press")

    if not columnsAndRows[nextCol] or not columnsAndRows[nextCol][nextRow] then

    else
        hoveredOverId = columnsAndRows[nextCol][nextRow]
        selectedCol = nextCol
        selectedRow = nextRow
        drawDebugMenu()
    end
end
local function splitLines(inputString, maxLen)
    local lines = {}
    local line = ""

    -- Loop over each word in the input string
    if not inputString then
        return { "No description available" }
    end
    if #inputString < maxLen then
        return { inputString }
    end
    for word in inputString:gmatch("%S+") do
        -- Check if adding this word would exceed the maximum length
        if #line + #word + 1 > maxLen then
            -- If line is not empty, add it to the lines table
            if #line > 0 then
                table.insert(lines, line)
            end
            -- Start a new line with the current word
            line = word
        else
            -- If the line is not empty, add a space before the word
            if #line > 0 then
                line = line .. " " .. word
            else
                line = word
            end
        end
    end

    -- Add the last line if it contains any text
    if #line > 0 then
        table.insert(lines, line)
    end

    return lines
end
local bit8 = 255
local statColors = {
    fatigue = util.color.rgb(0 / bit8, 150 / bit8, 60 / bit8),
    health = util.color.rgb(200 / bit8, 60 / bit8, 30 / bit8),
    magicka = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8),
    encumbrance = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8),
    level = util.color.rgb(53 / bit8, 69 / bit8, 159 / bit8),
}
local function getSkillBar(id)
    local stat = types.NPC.stats.skills[id](self)
    local string = tostring(stat.modified)
    local base = 100
    local current = math.floor(stat.progress * 100)
    return {
        max = base,
        current = current,
        modified = stat.modified,
        progress = stat.progress,
        string = string
    }
end
local favoritesMenu = {
    { text = "Toggle God Mode", command = "tgm" },

    { text = "Feather",         command = "feather" },
    { text = "Add Gold",        command = "additem gold_001 1000" },
    { text = "Fly",             command = "fly" },
    { text = "Add Gold",        command = "additem gold_001 1000" },

}
local activeWin
local function OpenDebugMenu()
    I.CI_Expirement.openEmptyUIWindow()
    I.CustomWindowData.clear()
    I.CustomWindowData.addCategory("Favorites")
    I.CustomWindowData.addCategory("Log")
    I.CustomWindowData.addCategory("Terminal")
    I.CustomWindowData.addCategory("General")
    I.CustomWindowData.addCategory("Destinations")
    I.CustomWindowData.addCategory("Items")
    local lineLength = 50
    for i, x in ipairs(favoritesMenu) do
        I.CustomWindowData.addMenuItem(x.text, "Favorites", nil, nil,
            splitLines(x.command, lineLength), x.text, x.command)
    end
    local newWin = I.Controller_Custom_Window.createCustomWindow()
    I.Deckwind.setCustomWindow(newWin)
    activeWin = newWin
end
local function CustomWindowButtonPressed()
    if not activeWin then
        return
    end
    local item = activeWin:getItemAt(activeWin.selectedPosX, activeWin.selectedPosY)
    if item and I.DebugMode then
    -- print(item.actionText)
     I.DebugMode.runConsoleCommand(item.actionText)
    end
end
return {

    interfaceName = "CI_DebugMenu",
    interface = {
        drawDebugMenu = drawDebugMenu,
        OpenDebugMenu = OpenDebugMenu,
        renderItemBold = renderItemBold,
        flexedItems = flexedItems,
        renderItemBoxed = renderItemBoxed,
        addColumn = addColumn,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            if DebugWindowElement then
                DebugWindowElement:destroy()
                DebugWindowElement = nil
                I.CI_Background.destroyBackground()
                activeWin = nil
            end
        end,
        CustomWindowButtonPressed = CustomWindowButtonPressed,
        drawDebugMenu = drawDebugMenu,
        openStatsMenu = openStatsMenu,
    },
    engineHandlers = {
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
    }
}
