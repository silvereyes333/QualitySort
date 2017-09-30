-- A very special thanks to merlight for the research done to make this possible!
QualitySort = {}

QualitySort.name = "QualitySort"
QualitySort.version = "1.5.1.0"

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
QualitySort.extendedDataCache = {}
local extendedDataCache = QualitySort.extendedDataCache
local function GetExtendedData(data)
    local uniqueId = zo_getSafeId64Key(data.uniqueId or GetItemUniqueId(data.bagId, data.slotIndex))
    if extendedDataCache[uniqueId] then
        return extendedDataCache[uniqueId]
    end
    local extendedData = { 
        uniqueId = uniqueId,
        bagId = data.bagId, 
        slotIndex = data.slotIndex,
    }
    local link = GetItemLink(extendedData.bagId, extendedData.slotIndex)
    local _, _, _, itemId, _, _, 
          enchantType, enchantSubType, enchantLevel, writ1, writ2, writ3, writ4, writ5, writ6, 
          itemStyle, _, _, _, charges, vouchers = ZO_LinkHandler_ParseLink(link)
    extendedData.itemId = tonumber(itemId)
    extendedData.link = link
    extendedData.championRank = GetItemLinkRequiredChampionPoints(link)
    extendedData.traitInfo = GetItemLinkTraitInfo(link)
    extendedData.itemStyle = GetItemLinkItemStyle(link)
    if charges and tonumber(charges) > 0 then
        extendedData.enchantment = {
            charges = tonumber(charges),
            type = tonumber(enchantType),
            subType = tonumber(enchantSubType),
            level = tonumber(enchantLevel),
        }
    end
    if data.itemType == ITEMTYPE_MASTER_WRIT and vouchers then
        extendedData.masterWrit = {
            writ1 = tonumber(writ1), 
            writ2 = tonumber(writ2), 
            writ3 = tonumber(writ3), 
            writ4 = tonumber(writ4), 
            writ5 = tonumber(writ5), 
            writ6 = tonumber(writ6),
            vouchers = math.max(2, tonumber(string.format("%.0f", tonumber(vouchers)/10000)))
        }
    end
    if uniqueId ~= nil then
        extendedDataCache[uniqueId] = extendedData
    end
    return extendedData
end
local function NilOrLessThan(value1, value2)
    if value1 == nil then
        return true
    elseif value2 == nil then
        return false
    else
        return value1 < value2
    end
end
local function CompareEnchantments(enchant1, enchant2)
    if enchant1 == nil then
        return true
    elseif enchant2 == nil then
        return false
    elseif enchant1.type ~= enchant2.type then
        return NilOrLessThan(enchant1.type, enchant2.type)
    elseif enchant1.subType ~= enchant2.subType then
        return NilOrLessThan(enchant1.subType, enchant2.subType)
    else
        return NilOrLessThan(enchant1.charges, enchant2.charges)
    end
end
local function CompareMasterWrits(writ1, writ2)
    if writ1.vouchers ~= writ2.vouchers then
        return NilOrLessThan(writ1.vouchers, writ2.vouchers)
    elseif writ1.writ1 ~= writ2.writ1 then
        return NilOrLessThan(writ1.writ1, writ2.writ1)
    elseif writ1.writ2 ~= writ2.writ2 then
        return NilOrLessThan(writ1.writ2, writ2.writ2)
    elseif writ1.writ3 ~= writ2.writ3 then
        return NilOrLessThan(writ1.writ3, writ2.writ3)
    elseif writ1.writ4 ~= writ2.writ4 then
        return NilOrLessThan(writ1.writ4, writ2.writ4)
    elseif writ1.writ5 ~= writ2.writ5 then
        return NilOrLessThan(writ1.writ5, writ2.writ5)
    else
        return NilOrLessThan(writ1.writ6, writ2.writ6)
    end
end
function QualitySort.orderByItemQuality(data1, data2)
    
    -- Sort first by quality
    if data2.quality ~= data1.quality then
        return NilOrLessThan(data2.quality, data1.quality)
    end
    
    -- Then by name
    if data1.name ~= data2.name then
        return NilOrLessThan(data1.name, data2.name)
    end
    
    -- Then by level
    if data1.requiredLevel ~= data2.requiredLevel then
        return NilOrLessThan(data1.requiredLevel, data2.requiredLevel)
    end
    
    -- Get extended data for the two data slots
    local exData1 = GetExtendedData(data1)
    local exData2 = GetExtendedData(data2)
    
    -- Then by champion rank
    if exData1.championRank ~= exData2.championRank then
        return NilOrLessThan(exData1.championRank, exData2.championRank)
    end
    
    -- Then by trait
    if exData1.traitInfo ~= exData2.traitInfo then
        return NilOrLessThan(exData1.traitInfo, exData2.traitInfo)
    end
    
    -- Then by enchant
    if exData1.enchantment ~= exData2.enchantment then
        return CompareEnchantments(exData1.enchantment, exData2.enchantment)
    end

    -- Then by style
    if exData1.itemStyle ~= exData2.itemStyle then
        return NilOrLessThan(exData1.itemStyle, exData2.itemStyle)
    end

    -- Then by item id
    if exData1.itemId ~= exData2.itemId then
        return NilOrLessThan(exData1.itemId, exData2.itemId)
    end

    -- Then by master writ
    if exData1.masterWrit ~= nil and exData2.masterWrit ~= nil then
        return CompareMasterWrits(exData1.masterWrit, exData2.masterWrit)
    end

    -- And finally, sort by item unique id, to make sure relative order stays the same on update
    return NilOrLessThan(exData1.uniqueId, exData2.uniqueId)
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
local function GetBagIdForInventoryType(inventoryType)
    for bagId, bagInventoryType in pairs(PLAYER_INVENTORY.bagToInventoryType) do
        if inventoryType == bagInventoryType then
            return bagId
        end
    end
end
local function PurgeCacheForInventoryType(inventoryManager, inventoryType)
    if inventoryType == INVENTORY_QUEST_ITEM then return end
    local bagId = GetBagIdForInventoryType(inventoryType)
    if not bagId then return end
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
    local itemsToPurge = {}
    for uniqueId, extendedData in pairs(extendedDataCache) do
        local slotData = bagCache[extendedData.slotIndex]
        if not slotData or zo_getSafeId64Key(slotData.uniqueId) ~= uniqueId then
            table.insert(itemsToPurge, uniqueId)
        end
    end
    for i=1, #itemsToPurge do
        extendedDataCache[itemsToPurge[i]] = nil
    end
end
function QualitySort.addSortByQuality(flag)
    local sortByControl = QualitySort.getSortByHeader(flag)

    local nameHeader = sortByControl:GetNamedChild("Name")
    local qualityHeader = CreateControlFromVirtual("$(parent)Quality", sortByControl, "ZO_SortHeaderIcon")

    qualityHeader:SetAnchor(RIGHT, nameHeader, LEFT, -35, 0)
    qualityHeader:SetDimensions(16, 32)
    ZO_SortHeader_InitializeArrowHeader(qualityHeader, QualitySort.orderByItemQuality, ZO_SORT_ORDER_UP)
    ZO_SortHeader_SetTooltip(qualityHeader, GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_QUALITY), BOTTOMRIGHT, 0, 32)

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
    ZO_PreHook(PLAYER_INVENTORY, "ApplySort", PurgeCacheForInventoryType)
    SLASH_COMMANDS["/qualitysort"] = QualitySort.printVersion
end

EVENT_MANAGER:RegisterForEvent("QualitySort", EVENT_ADD_ON_LOADED, QualitySort.onAddonLoaded)
