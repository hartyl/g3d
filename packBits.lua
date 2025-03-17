local ffi = require("ffi")
local bit = require 'bit'
return function(bits)
    local int_value = 0
	local i=0
	while bits > 0 do
		if bit.band(1,bits) == 1 then
			int_value = bit.bor(int_value, bit.lshift(1, i)) -- write individual bit
		end
		bits = bit.rshift(bits,1)
		i=i+1
	end

    -- Create a float from the integer value
    local float_value = ffi.cast("float*", ffi.new("int32_t[1]", int_value))
    return float_value[0]
end
