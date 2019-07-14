local addon = QualitySort
----------------- Settings -----------------------
local COLOR_DISABLED = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
local NONE = COLOR_DISABLED:Colorize(zo_strformat(GetString(SI_QUEST_TYPE_FORMAT), GetString(SI_ITEMTYPE0)))
local INDENT = "|t420%:100%:esoui/art/worldmap/worldmap_map_background.dds|t"

local function SwapDropdownValues(settings, optionIndex, value)
    if value == "" then
        settings[optionIndex] = value
        return
    end
    local oldValue = settings[optionIndex]
    for swapOptionIndex=1,#settings do
        local swapValue = settings[swapOptionIndex]
        if swapValue == value then
            settings[swapOptionIndex] = oldValue
            settings[optionIndex] = value
            return
        end
    end
    settings[optionIndex] = value
end
local function CreateSortOrderOption(optionsTable, optionIndex)
    local self = addon
    table.insert(optionsTable, {
        type = "dropdown",
        width = "half",
        choices = self.sortOrderOptions,
        choicesValues = self.sortOrderValues,
        name = INDENT .. tostring(optionIndex + 1),
        getFunc = function() return self.settings.sortOrder[optionIndex] end,
        setFunc = function(value)
            SwapDropdownValues(self.settings.sortOrder, optionIndex, value)
        end,
        default = self.defaults.sortOrder[optionIndex]
    })
end

function addon:SetupOptions()
    
    -- Setup saved vars
    self.settings = LibSavedVars:NewAccountWide(self.name .. "_Account", self.defaults)
                                :AddCharacterSettingsToggle(self.name .. "_Character")
    
    -- Generate alphabetical list of sort order options in the current language
    local sortOrderValuesByOption = { [NONE] = "" }
    self.sortOrderOptions = { NONE }
    for value, option in pairs(self.sortOrders) do
        sortOrderValuesByOption[option] = value
        table.insert(self.sortOrderOptions, option)
    end
    table.sort(self.sortOrderOptions)
    self.sortOrderValues = {}
    for i=1,#self.sortOrderOptions do
        table.insert(self.sortOrderValues, sortOrderValuesByOption[self.sortOrderOptions[i]])
    end
    
    --Setup options panel
    local LAM2 = LibStub("LibAddonMenu-2.0")

    local panelData = {
        type = "panel",
        name = self.title,
        displayName = self.title,
        author = self.author,
        version = self.version,
        registerForRefresh = true,
        registerForDefaults = true,
    }
    LAM2:RegisterAddonPanel(self.name .. "Options", panelData)

    local optionsTable = { 
        
        -- Account-wide settings
        self.settings:GetLibAddonMenuAccountCheckbox(),
        
        -- Automatic sort
        {
            type = "checkbox",
            name = GetString(SI_QUALITYSORT_AUTO),
            getFunc = function() return self.settings.automatic end,
            setFunc = function(value) self.settings.automatic = value end,
            width = "full",
            default = self.defaults.automatic,
        },
    }
    
    local sortOrderControls = {
        {
            type  = "divider",
            width = "full",
        },
        {
            type  = "description",
            width = "half",
            title = INDENT .. "1",
            text  = INDENT .. GetString(SI_MASTER_WRIT_DESCRIPTION_QUALITY)
        },
    }
    local optionCount = #self.sortOrderOptions - 1
    local minColumn2Index = math.floor( optionCount / 2 ) + 1
    
    CreateSortOrderOption(sortOrderControls, minColumn2Index)
    for optionIndex = 1, minColumn2Index - 1 do
        CreateSortOrderOption(sortOrderControls, optionIndex)
        local optionIndex2 = optionIndex + minColumn2Index
        if optionIndex2 <= optionCount then
            CreateSortOrderOption(sortOrderControls, optionIndex2)
        end
    end
    table.insert(optionsTable,
        -- Submenu
        {
            type = "submenu",
            name = GetString(SI_QUALITYSORT_SORT_ORDER),
            controls = sortOrderControls,
        })

    LAM2:RegisterOptionControls(self.name .. "Options", optionsTable)
end