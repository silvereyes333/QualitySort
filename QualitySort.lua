-- A very special thanks to merlight for the research done to make this possible!
QualitySort = {}

QualitySort.name = "QualitySort"
QualitySort.version = "1.4.0.0"

QUALITYSORT_INVENTORY_QUICKSLOT  = 100
QUALITYSORT_CRAFTING_DECON       = 200
QUALITYSORT_CRAFTING_ENCHANTING  = 201
QUALITYSORT_CRAFTING_IMPROVEMENT = 202
QUALITYSORT_CRAFTING_REFINEMENT  = 203

function QualitySort.getSortByHeader(flag)
    if flag == INVENTORY_BACKPACK then
        return ZO_PlayerInventorySortBy
    elseif flag == INVENTORY_BANK then
        return ZO_PlayerBankSortBy
    elseif flag == INVENTORY_GUILD_BANK then
        return ZO_GuildBankSortBy
    elseif flag == INVENTORY_CRAFT_BAG then
        return ZO_CraftBagSortBy
    elseif flag == QUALITYSORT_INVENTORY_QUICKSLOT then
        return ZO_QuickSlotSortBy
    elseif flag == QUALITYSORT_CRAFTING_DECON then
        return ZO_SmithingTopLevelDeconstructionPanelInventorySortBy
    elseif flag == QUALITYSORT_CRAFTING_ENCHANTING then
        return ZO_EnchantingTopLevelInventorySortBy
    elseif flag == QUALITYSORT_CRAFTING_IMPROVEMENT then
        return ZO_SmithingTopLevelImprovementPanelInventorySortBy
    elseif flag == QUALITYSORT_CRAFTING_REFINEMENT then
        return ZO_SmithingTopLevelRefinementPanelInventorySortBy
    end
    return nil
end
function QualitySort.orderByItemQuality(data1, data2)
    local link1 = GetItemLink(data1.bagId, data1.slotIndex)
    local link2 = GetItemLink(data2.bagId, data2.slotIndex)
    local instanceId1 = GetItemInstanceId(data1.bagId, data1.slotIndex)
    local instanceId2 = GetItemInstanceId(data2.bagId, data2.slotIndex)

    -- Sort first by quality
    local quality1 = GetItemLinkQuality(link1)
    local quality2 = GetItemLinkQuality(link2)
    if quality2 ~= quality1 then
        return quality2 < quality1
    end
    
    -- Then by name
    local name1 = GetItemLinkName(link1)
    local name2 = GetItemLinkName(link2)
    if name1 ~= name2 then
        return name1 < name2
    end
    
    -- Then by level
    local level1 = GetItemLinkRequiredLevel(link1)
    local level2 = GetItemLinkRequiredLevel(link2)
    if level1 ~= level2 then
        return level1 < level2
    end
    
    -- Then by champion rank
    local championRank1 = GetItemLinkRequiredChampionPoints(link1)
    local championRank2 = GetItemLinkRequiredChampionPoints(link2)
    if championRank1 ~= championRank2 then
        return championRank1 < championRank2
    end
    
    -- Then by trait
    local trait1 = GetItemLinkTraitInfo(link1)
    local trait2 = GetItemLinkTraitInfo(link2)
    if trait1 ~= trait2 then
        return trait1 < trait2
    end
    
    -- Then by enchant
    local hasCharges1, enchant1 = GetItemLinkEnchantInfo(link1)
    local hasCharges2, enchant2 = GetItemLinkEnchantInfo(link2)
    if enchant1 ~= enchant2 then
        return enchant1 < enchant2
    end

    -- Then by style
    local style1 = GetItemLinkItemStyle(link1)
    local style2 = GetItemLinkItemStyle(link2)
    if style1 ~= style2 then
        return style1 < style2
    end

    -- And finally, sort by item instance id, to make sure relative order stays the same on update
    if not instanceId1 then
        return true
    end
    return instanceId1 < instanceId2
end
local function sortFunction(entry1, entry2, sortKey, sortOrder)
    local res
    if type(sortKey) == "function" then
        if sortOrder == ZO_SORT_ORDER_UP then
            res = sortKey(entry1.data, entry2.data)
        else
            res = sortKey(entry2.data, entry1.data)
        end
    else
        local sortKeys = ZO_Inventory_GetDefaultHeaderSortKeys()
        res = ZO_TableOrderingFunction(entry1.data, entry2.data, sortKey, sortKeys, sortOrder)
    end
    return res
end
function QualitySort.initCustomInventorySortFn(inventory)
    inventory.sortFn = function(entry1, entry2)
        local sortKey = inventory.currentSortKey
        local sortOrder = inventory.currentSortOrder
        return sortFunction(entry1, entry2, sortKey, sortOrder)
    end
end
function QualitySort.initSortFunction(owner)
    owner.sortFunction = function(entry1, entry2)
        local sortKey = owner.sortHeaders:GetCurrentSortKey()
        local sortOrder = owner.sortHeaders:GetSortDirection()
        return sortFunction(entry1, entry2, sortKey, sortOrder)
    end
end
local function Prehook_NameHeader_SetWidth(nameHeader, width)
    return true
end
local function ShiftRightAnchorOffsetX(header, relativeTo, shiftX, qualityHeader)
    if header == relativeTo or header == qualityHeader then
        return
    end
    local isValidAnchor, point, anchorRelativeTo, relativePoint, offsetX, offsetY, anchorConstrains = header:GetAnchor(0)
    if not isValidAnchor or anchorRelativeTo ~= relativeTo then
        return
    end
    if (relativePoint == RIGHT or relativePoint == TOPRIGHT or relativePoint == BOTTOMRIGHT) then
        header:ClearAnchors()
        -- If the original offset is less than the width of the quality header, 
        -- just anchor it to the right of the quality header instead
        local leftPoint = offsetX + shiftX
        if point == RIGHT or point == TOPRIGHT or point == BOTTOMRIGHT then
            leftPoint = leftPoint - header:GetWidth()
        end
        
        if leftPoint < qualityHeader:GetWidth() then
            header:SetAnchor(LEFT, qualityHeader, relativePoint, 0, offsetY, anchorConstrains)
        
        -- Otherwise, shift the original anchor
        else
            header:SetAnchor(point, relativeTo, relativePoint, offsetX + shiftX, offsetY, anchorConstrains)
        end
    end
end
function QualitySort.addSortByQuality(flag)
    local newNameWidth = 80
    local qualityWidth = 80
    local sortByControl = QualitySort.getSortByHeader(flag)
    local nameHeader = sortByControl:GetNamedChild("Name")
    local nameWidth = nameHeader:GetWidth()
    local shiftX = nameWidth - newNameWidth
    
    -- Make the name header narrower to avoid overlap with the quality header.
    nameHeader:SetWidth(newNameWidth)
    
    -- Disable changing the name header's width again
    ZO_PreHook(nameHeader, "SetWidth", Prehook_NameHeader_SetWidth)
    
    -- Create the quality header
    local qualityHeader = CreateControlFromVirtual("$(parent)Quality", sortByControl, "ZO_SortHeader")
    
    -- Anchor the quality header to the right side of the name header
    qualityHeader:SetAnchor(LEFT, nameHeader, RIGHT)
    qualityHeader:SetDimensions(qualityWidth, 20)

    -- Shift all headers that are anchored to the right side of the name header
    -- over to account for the decreased name header width.
    for i=1,sortByControl:GetNumChildren() do
        local child = sortByControl:GetChild(i)
        ShiftRightAnchorOffsetX(child, nameHeader, shiftX, qualityHeader)
    end
    
    ZO_SortHeader_Initialize(qualityHeader, GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_QUALITY), QualitySort.orderByItemQuality,
                             ZO_SORT_ORDER_UP, TEXT_ALIGN_RIGHT, "ZoFontHeader")

    if flag >= QUALITYSORT_INVENTORY_QUICKSLOT then
        local inventory = sortByControl:GetParent()
        local owner = inventory.owner
        QualitySort.initSortFunction(owner)
        owner.sortHeaders:AddHeader(qualityHeader)
    else
    
        local inventory = PLAYER_INVENTORY.inventories[flag]
        QualitySort.initCustomInventorySortFn(inventory)
        inventory.sortHeaders:AddHeader(qualityHeader)
    end
end


function QualitySort.printVersion()
    d(QualitySort.name.." version "..QualitySort.version)
end

function QualitySort.onAddonLoaded(eventCode, addonName)
    if addonName ~= QualitySort.name then return end

    EVENT_MANAGER:UnregisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, QualitySort.onAddonLoaded)

    ZO_QuickSlot.owner = QUICKSLOT_WINDOW
    QualitySort.addSortByQuality(INVENTORY_BACKPACK)
    QualitySort.addSortByQuality(INVENTORY_BANK)
    QualitySort.addSortByQuality(INVENTORY_GUILD_BANK)
    QualitySort.addSortByQuality(INVENTORY_CRAFT_BAG)
    QualitySort.addSortByQuality(QUALITYSORT_INVENTORY_QUICKSLOT)
    QualitySort.addSortByQuality(QUALITYSORT_CRAFTING_DECON)
    QualitySort.addSortByQuality(QUALITYSORT_CRAFTING_ENCHANTING)
    QualitySort.addSortByQuality(QUALITYSORT_CRAFTING_IMPROVEMENT)
    QualitySort.addSortByQuality(QUALITYSORT_CRAFTING_REFINEMENT)
    SLASH_COMMANDS["/qualitysort"] = QualitySort.printVersion
end

EVENT_MANAGER:RegisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, QualitySort.onAddonLoaded)
