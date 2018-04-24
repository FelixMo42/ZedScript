require "lib"

while not exit do
	io.write("> ")
	local code = io.read("*l")

	if code:find("exit") or exit then
		break
	end
	
	local first = compile(code):get_first()
	if first.value ~= nil then
		print( ({(tostring(first.value).." "):gsub("%.0", "")})[1] )
	end
end