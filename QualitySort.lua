-- A very special thanks to merlight for the research done to make this possible!
QualitySort = {}

QualitySort.name = "QualitySort"
QualitySort.version = "1.2.0.0"

QUALITYSORT_INVENTORY_QUICKSLOT = 100

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
function QualitySort.initCustomQuickSlotSortFn()
    QUICKSLOT_WINDOW.sortFunction = function(entry1, entry2)
        local sortKey = QUICKSLOT_WINDOW.sortHeaders:GetCurrentSortKey()
        local sortOrder = QUICKSLOT_WINDOW.sortHeaders:GetSortDirection()
        return sortFunction(entry1, entry2, sortKey, sortOrder)
    end
end
function QualitySort.addSortByQuality(inventoryID)
	local invSortBy
	if inventoryID == INVENTORY_BACKPACK then
    	invSortBy = ZO_PlayerInventorySortBy
    elseif inventoryID == INVENTORY_BANK then
   		invSortBy = ZO_PlayerBankSortBy
   	elseif inventoryID == INVENTORY_GUILD_BANK then
    	invSortBy = ZO_GuildBankSortBy
   	elseif inventoryID == INVENTORY_CRAFT_BAG then
    	invSortBy = ZO_CraftBagSortBy
   	elseif inventoryID == QUALITYSORT_INVENTORY_QUICKSLOT then
    	invSortBy = ZO_QuickSlotSortBy
    end

    local nameHeader = invSortBy:GetNamedChild("Name")
    local qualityHeader = CreateControlFromVirtual("$(parent)Quality", invSortBy, "ZO_SortHeaderIcon")

    qualityHeader:SetAnchor(RIGHT, nameHeader, LEFT, -35, 0)
    qualityHeader:SetDimensions(16, 32)
    ZO_SortHeader_InitializeArrowHeader(qualityHeader, QualitySort.orderByItemQuality, ZO_SORT_ORDER_UP)
    ZO_SortHeader_SetTooltip(qualityHeader, "Quality", BOTTOMRIGHT, 0, 32)

    if inventoryID == QUALITYSORT_INVENTORY_QUICKSLOT then
        QualitySort.initCustomQuickSlotSortFn()
        QUICKSLOT_WINDOW.sortHeaders:AddHeader(qualityHeader)
    else
        local inventory = PLAYER_INVENTORY.inventories[inventoryID]
        QualitySort.initCustomInventorySortFn(inventory)
        inventory.sortHeaders:AddHeader(qualityHeader)
    end
end

function QualitySort.onAddonLoaded(eventCode, addonName)
    if addonName ~= QualitySort.name then return end

    EVENT_MANAGER:UnregisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, QualitySort.onAddonLoaded)

    QualitySort.addSortByQuality(INVENTORY_BACKPACK)
    QualitySort.addSortByQuality(INVENTORY_BANK)
    QualitySort.addSortByQuality(INVENTORY_GUILD_BANK)
    QualitySort.addSortByQuality(INVENTORY_CRAFT_BAG)
    QualitySort.addSortByQuality(QUALITYSORT_INVENTORY_QUICKSLOT)
end

EVENT_MANAGER:RegisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, QualitySort.onAddonLoaded)
