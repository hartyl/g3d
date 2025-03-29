local ffiCast = require("ffi").cast
local ffiNew = require("ffi").new
return function(bits)
    -- Create a float from the integer value
	local u = ffiNew("uint32_t[1]", bits)
    return {ffiCast("float*", u)[0]}, u[0]
end
