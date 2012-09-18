--[[
        Yaroot(yleaf) wrote this file, do whatever you want with it.
        Buy me a beer if you think it's worth it.
--]]

local BOE_Only = false

local defaultPrice = 99*1e4
local dePrice = {
    --[[
    0 = Poor
    1 = Common
    2 = Uncommon
    3 = Rare
    4 = Epic
    5 = Legendary
    6 = Artifact
    7 = Heirloom 
    ]]
    --	[4] = 18*1e4,
    --	[3] = 8*1e4,
    --	[2] = 7*1e4,

}

-----------------------------------------
local debugf = tekDebug and tekDebug:GetFrame('yAutoGreed')
local debug
if debugf then
    debug = function(...) debugf:AddMessage(string.join(', ', tostringall(...))) end
else
    debug = function() end
end

local function printf(...)
    print(format(...))
end

local f = CreateFrame'Frame'
yAutoGreed = f

f:SetScript('OnEvent', function(self, event, ...) self[event](self,event,...) end)

local items = {}
f.items = items

f:RegisterEvent('START_LOOT_ROLL')
f:RegisterEvent('CONFIRM_LOOT_ROLL')
f:RegisterEvent('CONFIRM_DISENCHANT_ROLL')

f:RegisterEvent('PLAYER_ENTERING_WORLD')

function f:PLAYER_ENTERING_WORLD()
    wipe(items)
end

function f:Add(id, BOP)
    items[id] = BOP and 1 or 2
end

function f:Remove(id)
    if items[id] then
        if items[id] == 1 then
            items[id] = 2
        else
            items[id] = nil
        end
    end
end

local roll_text={
    [2] = GREED,
    [3] = ROLL_DISENCHANT,
}

function f:START_LOOT_ROLL(event, rollid)
    local texture, name, count, quality, BOP, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(rollid)
    if canNeed or (BOP and BOE_Only) then return end

    local link = GetLootRollItemLink(rollid)

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)

    -- 1. need 2. greed 3. de 4. pass

    local rollType

    if canGreed then
        rollType = 2

        local price = dePrice[itemRarity] or defaultPrice
        if canDisenchant and (itemSellPrice < price) then
            rollType = 3
        end
    end

    if rollType then
        -- debug('AutoRoll', itemName, rollid, rollType)
        printf('|cff33ff99yAutoGreed: %s >> %s', roll_text[rollType], itemLink)
        self:Add(rollid, BOP)
        RollOnLoot(rollid, rollType)
    end
end

function f:CONFIRM_LOOT_ROLL(event, id, rollType)
    debug(event, id, rollType)
    if items[id] then
        ConfirmLootRoll(id, rollType)
        self:Remove(id)
    end
end

f.CONFIRM_DISENCHANT_ROLL = f.CONFIRM_LOOT_ROLL


hooksecurefunc('StaticPopup_OnShow', function(self)
    if self.which == 'CONFIRM_LOOT_ROLL' then
        local text = _G[self:GetName() .. 'Text']:GetText()
        for id in next, items do
            local _, name = GetLootRollItemInfo(id)
            if name and strfind(text, name) then
                local link = GetLootRollItemLink(id)
                -- debug('StaticPopup, CONFIRM_LOOT_ROLL', name)
                printf('|cff33ff99yAutoGreed: confirm >> %s', link)
                self:Hide()
                f:Remove(id)
                return
            end
        end
    end
end)

