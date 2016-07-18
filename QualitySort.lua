-- A very special thanks to merlight for the research done to make this possible!
QualitySort = {}

QualitySort.name = "QualitySort"
QualitySort.version = "1.3.0.0"

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
    local quality1 = GetItemLinkQuality(link1)
    local quality2 = GetItemLinkQuality(link2)

    if quality2 == quality1 then
        return GetItemLinkName(link1) < GetItemLinkName(link2)
    else
        return quality2 < quality1
    end
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
function QualitySort.addSortByQuality(flag)
    local sortByControl = QualitySort.getSortByHeader(flag)

    local nameHeader = sortByControl:GetNamedChild("Name")
    local qualityHeader = CreateControlFromVirtual("$(parent)Quality", sortByControl, "ZO_SortHeader")
    
    qualityHeader:SetAnchor(LEFT, nameHeader, LEFT, 38, 0)
    qualityHeader:SetDimensions(100, 20)
    
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
end

EVENT_MANAGER:RegisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, QualitySort.onAddonLoaded)
