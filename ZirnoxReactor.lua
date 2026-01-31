ZirnoxReactor =
{
    heat = 0,
    maxHeat = 0,
    water = 0,
    maxWater = 0,
    steam = 0,
    maxSteam = 0,
    carbonDioxide = 0,
    maxCarbonDioxide = 16000,
    reactorChamber = { { ReactorCell } },
    reactorBridge = { ReactorCell }
}

ZirnoxReactor.__index = ZirnoxReactor

local comp = require("component")
local tr = comp.trans
local sides = require("sides")
local zirnox = comp.zirnox

local chamberSide = sides.front
local bridgeSide = sides.left
local reactorIdSide = sides.bottom

-- =====================
-- Constructor
-- =====================
function ZirnoxReactor:new()
    local self = setmetatable({}, ZirnoxReactor)

    self.reactorChamber = {}
    self.reactorBridge = {}

    local idx = 1

    for y = 1, 7 do
        self.reactorChamber[y] = {}
        for x = 1, 7 do
            if ((y - 1) & 1) == 0 then
                self.reactorChamber[y][x] = ReactorCell:new(idx, ZirnoxRod.ROD_BLOCK)
            else
                self.reactorChamber[y][x] = ReactorCell:new(idx,
                    ZirnoxReactor.getMinecraftRodFromReactor(tr.getStackInSlot(chamberSide, idx)))
                idx = idx + 1
            end
        end

        local invSize = self:getReactorBridgeInventorySize()
        for i = 1, invSize do
            local rod = self:getMinecraftRodFromBridge(i)
            
        end
    end

    return self
end

function ZirnoxReactor:getReactorBridgeInventorySize()
    return tr.getInventorySize(bridgeSide)
end

function ZirnoxReactor:getMinecraftRodFromBridge(idx)
    return ZirnoxReactor.getMinecraftRodFromReactor(tr.getStackInSlot(bridgeSide, idx))
end

function ZirnoxReactor:getReactorBridgeUsageSize()
    local size = self:getReactorBridgeInventorySize()
    for i = 1, size do
        if tr.getStackInSlot(bridgeSide, i) == nil then
            return i
        end
    end

    return size
end

function ZirnoxReactor.getMinecraftRodFromReactor(stack)
    local rod = ZirnoxRod.ROD_EMPTY

    if stack.name ~= "hbm:zirnox_rod" then return rod end

    rod.type = ZirnoxRodType.ZIRNOX_ROD_TYPE_NORMAL

    if not stack.label:find("Fuel Rod") ~= nil then
        rod.type = ZirnoxRodType.ZIRNOX_ROD_TYPE_BREEDING
    end

    if stack.label:find("ZIRNOX Natural Uranium") ~= nil then
        rod.name = "natural_uranium_rod"
        rod.strength = 30
    elseif stack.label:find("ZIRNOX Uranium") ~= nil then
        rod.name = "uranium_rod"
        rod.strength = 50
    elseif stack.label:find("ZIRNOX Thorium-232") ~= nil then
        rod.name = "thorium232_rod"
        rod.strength = 0
    elseif stack.label:find("ZIRNOX Thorium") ~= nil then
        rod.name = "thorium_rod"
        rod.strength = 40
    elseif stack.label:find("ZIRNOX MOX") ~= nil then
        rod.name = "mox_rod"
        rod.strength = 75
    elseif stack.label:find("ZIRNOX Plutonium") ~= nil then
        rod.name = "plutonium_rod"
        rod.strength = 65
    elseif stack.label:find("ZIRNOX Uranium-233") ~= nil then
        rod.name = "uranium233_rod"
        rod.strength = 100
    elseif stack.label:find("ZIRNOX Uranium-235") ~= nil then
        rod.name = "uranium235_rod"
        rod.strength = 85
    elseif stack.label:find("ZIRNOX LES") ~= nil then
        rod.name = "les_rod"
        rod.strength = 150
    elseif stack.label:find("ZIRNOX Lithium") ~= nil then
        rod.name = "lithium_rod"
        rod.strength = 0
    elseif stack.label:find("ZIRNOX ZFB MOX") ~= nil then
        rod.name = "zfb_mox_rod"
        rod.strength = 35
    end

    return rod
end

function ZirnoxReactor:update()
end

-- =====================
-- Bridge
-- =====================
function ZirnoxReactor:addRodToBridge(rod)
    self.reactorBridge[#self.reactorBridge + 1] = rod
end

function ZirnoxReactor:getRodFromBridge(idx)
    return self.reactorBridge[idx] or ZirnoxRod.ROD_BLOCK
end

function ZirnoxReactor:getMostPowerfullRodFromBridge()
    local best = 1
    for i = 2, #self.reactorBridge do
        if self.reactorBridge[i].strength > self.reactorBridge[best].strength then
            best = i
        end
    end
    return best
end

-- =====================
-- Position checks
-- =====================
function ZirnoxReactor:isRodPositionValid(x, y)
    return self.reactorChamber[y]
       and self.reactorChamber[y][x]
       and not self.reactorChamber[y][x].rod:isBlock()
end

function ZirnoxReactor:isRodPositionBlock(x, y)
    return self.reactorChamber[y]
       and self.reactorChamber[y][x]
       and self.reactorChamber[y][x].rod:isBlock()
end

-- =====================
-- Chamber access
-- =====================
function ZirnoxReactor:getRodAt(x, y)
    if not self.reactorChamber[y] or not self.reactorChamber[y][x] then
        return ZirnoxRod.ROD_BLOCK
    end
    return self.reactorChamber[y][x].rod
end

function ZirnoxReactor:setRodAt(x, y, rod)
    local cell = self.reactorChamber[y] and self.reactorChamber[y][x]
    if not cell or cell.rod:isBlock() or not cell.rod:isEmpty() then
        return false
    end

    cell.rod:setFrom(rod)
    return true
end

-- =====================
-- Rod transfer
-- =====================
function ZirnoxReactor:storeRodAtBridge(x, y)
    local rod = self:getRodAt(x, y)
    if rod:isEmpty() or rod:isBlock() then return false end

    self:addRodToBridge(rod)
    self.reactorChamber[y][x].rod = ZirnoxRod.ROD_EMPTY
    return true
end

function ZirnoxReactor:pullRodFromBridge(idx, x, y)
    local cell = self.reactorChamber[y] and self.reactorChamber[y][x]
    if not cell or not cell.rod:isEmpty() then return false end
    if not self.reactorBridge[idx] then return false end

    local rod = table.remove(self.reactorBridge, idx)
    cell.rod:setFrom(rod)
    return true
end

function ZirnoxReactor:replaceRodWithBridgeRod(idx, x, y)
    if not self:storeRodAtBridge(x, y) then return false end
    return self:pullRodFromBridge(idx, x, y)
end

-- =====================
-- Neighbour access
-- =====================
function ZirnoxReactor:getRodLeft(x, y)
    return self:getRodAt(x - 2, y)
end

function ZirnoxReactor:getRodRight(x, y)
    return self:getRodAt(x + 2, y)
end

function ZirnoxReactor:getRodUp(x, y)
    return self:getRodAt(x, y + 2)
end

function ZirnoxReactor:getRodDown(x, y)
    return self:getRodAt(x, y - 2)
end

-- =====================
-- Neighbour counts
-- =====================
function ZirnoxReactor:getEmptyNeightbourCount(x, y)
    local n = 0
    if self:getRodUp(x, y):isEmpty() then n = n + 1 end
    if self:getRodDown(x, y):isEmpty() then n = n + 1 end
    if self:getRodLeft(x, y):isEmpty() then n = n + 1 end
    if self:getRodRight(x, y):isEmpty() then n = n + 1 end
    return n
end

function ZirnoxReactor:getRodNeightbourCountT(x, y, minStrength)
    local n = 0
    local function check(r)
        if not r:isEmpty() and not r:isBlock() and r.strength > minStrength then
            n = n + 1
        end
    end
    check(self:getRodUp(x, y))
    check(self:getRodDown(x, y))
    check(self:getRodLeft(x, y))
    check(self:getRodRight(x, y))
    return n
end

function ZirnoxReactor:getRodNeightbourCount(x, y)
    return self:getRodNeightbourCountT(x, y, 0)
end


local test = ZirnoxReactor:new()
test:update()