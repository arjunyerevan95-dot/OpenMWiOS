local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local input = require("openmw.input")
local v2 = require("openmw.util").vector2
local menuElement
local selectedElement = 1
local function textContentRight(text, selected, size, sizeModifier)
    if not size then
        size = 14
    end

    local template = I.MWUI.templates.textNormal
    if selected then
        template = I.MWUI.templates.textHeader
    end
    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            textSize = size,
            relativePosition = v2(1, 1),
            anchor = v2(1, 1),
            multiLine = true,
            -- position = position
        }
    }
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
local function drawMenu()
    if menuElement then
        menuElement:destroy()
    end
    local listItems = {}
    local questNameLs = I.CI_questlog.getQuestList()
    if selectedElement > #questNameLs then
        selectedElement = #questNameLs
    end
    for index, value in ipairs(questNameLs) do
        local selected = selectedElement == index
        table.insert(listItems, textContentRight(value.name, selected))
    end
    local subBox1 = {


        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            --   anchor = v2(0., 0.5),
            --    relativePosition = v2(0.5, 0.5),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(listItems),
                props = {
                    vertical = true,
                    size = v2(200, 600),
                    arrange = ui.ALIGNMENT.Start,

                }
            }
        }




    }
    local selectedQuest2 = I.CI_questlog.getQuestText(questNameLs[selectedElement].id)
    local elements = {}
    for index, value in ipairs(selectedQuest2) do
        table.insert(elements, textContentRight(value, false, 12))
    end
    local subBox2 = {


        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            --   anchor = v2(0., 0.5),
            --    relativePosition = v2(0.5, 0.5),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(elements),
                props = {
                    vertical = true,
                    size = v2(600, 600),
                    arrange = ui.ALIGNMENT.Start,
                }
            }
        }





    }
    menuElement = ui.create {
        layer = "InventoryWindow",
        template = I.MWUI.templates.boxTransparent,
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content
                    {
                        subBox1,
                        subBox2
                    },
                props = {
                    horizontal = true,
                    size = v2(800, 600),
                    arrange = ui.ALIGNMENT.Start,
                },
            }
        }
    }
end
local function onControllerButtonPress(id)
    if not menuElement then
        if id == input.CONTROLLER_BUTTON.Y and I.UI.getMode() == "Journal" then
            drawMenu()
        end
        return
    end
    if id == input.CONTROLLER_BUTTON.B then
        menuElement:destroy()
        menuElement = nil
    elseif id == input.CONTROLLER_BUTTON.DPadUp then
        selectedElement = selectedElement - 1
        if selectedElement < 1 then
            selectedElement = 1
        end
        drawMenu()
    elseif id == input.CONTROLLER_BUTTON.DPadDown then
        selectedElement = selectedElement + 1
        if selectedElement > #I.CI_questlog.getQuestList() then
            selectedElement = #I.CI_questlog.getQuestList()
        end
        drawMenu()
    end
end

return {
    drawMenu = drawMenu,
    onControllerButtonPress = onControllerButtonPress,
}
