ReactorCell = { index = 0, rod = ZirnoxRod.ROD_EMPTY }
ReactorCell.__index = ReactorCell

function ReactorCell:new(index, rod)
    return setmetatable({
        index = index,
        rod = rod or ZirnoxRod.ROD_EMPTY
    }, self)
end

function ReactorCell:toString()
    return "Internal Index: "..tostring(self.index).."\nZirnox Rod Info: "..self.rod:tostring()
end

return ReactorCell