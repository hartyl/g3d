local ffiCast = require("ffi").cast
local ffiNew = require("ffi").new
return function(bits)
    -- Create a float from the integer value
	local i = ffiNew("uint32_t[1]", bits)
    return {ffiCast("float*", i)[0]}, i[0]
end
