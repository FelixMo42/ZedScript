require "lib"

local peram = {...}

local f = assert(io.open(peram[2], "rb"))
local code = f:read("*all")
f:close()

local first = compile(code):get_first()
if first.value ~= nil then
	print( ({(tostring(first.value).." "):gsub("%.0", "")})[1] )
end