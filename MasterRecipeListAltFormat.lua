local addonName = "MasterRecipeListAltFormat"
local addon = {
    name = addonName,
    title = "ESO Master Recipe List Alt Format",
    author = "|c99CCEFsilvereyes|r",
    version = "1.0.0",
    debugMode = false,
}
local charNames = {}
local knownCharsByName = {}
local COLOR_UNKNOWN = ZO_ERROR_COLOR
local COLOR_KNOWN = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_MAGIC))
local COLOR_INDETERMINATE = ZO_DEFAULT_DISABLED_COLOR
local originalAddLine
local originalAddVerticalPadding
local function StripColor(text)
    if string.sub(text, 1, 2) == "|c" then
        text = string.sub(text, 9)
    end
    if string.sub(text, -2) == "|r" then
        text = string.sub(text, 1, -3)
    end
    return text
end
local function ReformatKnownBy(text)
    local names = {}
    for part in string.gmatch(text, '([^,]+)') do
        local characterName = zo_strtrim(part)
        characterName = StripColor(characterName)
        names[characterName] = true
    end
    local formattedNames = {}
    for _, characterName in ipairs(charNames) do
        if names[characterName] then
            table.insert(formattedNames, COLOR_KNOWN:Colorize(characterName))
        end
    end
    for _, characterName in ipairs(charNames) do
        if not names[characterName] and knownCharsByName[characterName] then
            table.insert(formattedNames, COLOR_UNKNOWN:Colorize(characterName))
        end
    end
    for _, characterName in ipairs(charNames) do
        if not names[characterName] and not knownCharsByName[characterName] then
            table.insert(formattedNames, COLOR_INDETERMINATE:Colorize(characterName))
        end
    end
    local output = table.concat(formattedNames, ", ")
    return output
end
local processNextTooltipLine
local tooltipLineBuilder
local knownByHeader
local craftableByHeader
local verticalPadding
local function ItemTooltipAddVerticalPadding(control, paddingY)
    if processNextTooltipLine then
        verticalPadding = paddingY
        return
    end
    originalAddVerticalPadding(control, paddingY)
end
local function ItemTooltipAddLine(control, text, font, r, g, b, lineAnchor, modifyTextType, textAlignment, setToFullSize)
    
    if processNextTooltipLine then
        if string.sub(text, -2) == ", " then
            if tooltipLineBuilder then
                tooltipLineBuilder = tooltipLineBuilder .. text
            else
                tooltipLineBuilder = text
            end
            return
        end
        
        processNextTooltipLine = nil
        if tooltipLineBuilder then
            text = tooltipLineBuilder .. text
            tooltipLineBuilder = nil
        end
        
        text = ReformatKnownBy(text)
        textAlignment = TEXT_ALIGN_CENTER
        font = ""
        lineAnchor = CENTER
        setToFullSize = true
        if verticalPadding then
            originalAddVerticalPadding(control, verticalPadding)
        end
        
    elseif text == knownByHeader or text == craftableByHeader then
        processNextTooltipLine = true
    end
    
    originalAddLine(control, text, font, r, g, b, lineAnchor, modifyTextType, textAlignment, setToFullSize)
end
local function OnAddonLoaded(event, name)
    if name ~= addonName then return end
    for i = 1, GetNumCharacters() do
        local characterName = zo_strformat("<<1>>", GetCharacterInfo(i))
        charNames[i] = characterName
    end
    local accountName = GetDisplayName()
    for characterName, _ in pairs(MasterRecipeList.Default[accountName]) do
        if characterName ~= "$AccountWide" then
            knownCharsByName[characterName] = true
        end
    end
    local mrlStrings = ESOMRL:GetLanguage()
    knownByHeader = mrlStrings.ESOMRL_KNOWN
    craftableByHeader = mrlStrings.ESOMRL_CRAFTABLE
    originalAddLine = ItemTooltip.AddLine
    originalAddVerticalPadding = ItemTooltip.AddVerticalPadding
    ItemTooltip.AddLine = ItemTooltipAddLine
    ItemTooltip.AddVerticalPadding = ItemTooltipAddVerticalPadding
end
EVENT_MANAGER:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, OnAddonLoaded)
MasterRecipeListAltFormat = addon