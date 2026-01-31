ZirnoxRod = { name = "", type = ZirnoxRodType, strength = 0 }
ZirnoxRod.__index = ZirnoxRod

ZirnoxRodType = require("ZirnoxRodType")

function ZirnoxRod:new(name, rodType, strength)
    return setmetatable({
        name = name or "",
        type = rodType or ZirnoxRodType.ZIRNOX_ROD_TYPE_NONE,
        strength = strength or 0
    }, self)
end

function ZirnoxRod:isEmpty()
    return self.type == ZirnoxRodType.ZIRNOX_ROD_TYPE_NONE
end

function ZirnoxRod:isBlock()
    return self.type == ZirnoxRodType.ZIRNOX_ROD_TYPE_BLOCK
end

function ZirnoxRod:setFrom(rod)
    self.name = rod.name
    self.type = rod.type
    self.strength = rod.strength
end

function ZirnoxRod:tostring()
    return "Rod Name: "..self.name.."\nRod Type: " .. (tostring(self.type)) .. "\nRod Strength: " .. (tostring(self.strength))
end

-- Constants
ZirnoxRod.ROD_EMPTY = ZirnoxRod:new("empty", ZirnoxRodType.ZIRNOX_ROD_TYPE_NONE, 0)
ZirnoxRod.ROD_BLOCK = ZirnoxRod:new("block", ZirnoxRodType.ZIRNOX_ROD_TYPE_BLOCK, 0)