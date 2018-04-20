--set up

require "linked"
require "tokens"

for k, v in pairs(tokens) do
	tokens[v.type] = v
end

vars = {}
debug = false
exit = false

--functions

function new(self, val)
	return setmetatable({
		value = val
	}, {
		__index = function(s, key)
			return tokens[rawget(s, "type") or self.type][key]
		end
	} )
end

function starts(code, pos, val, pat)
	pat = pat or "%W"
	local s = #val
	return code:sub(pos, pos + s - 1) == val and code:sub(pos + s, pos + s):match(pat)
end

--main funcs

function tokenize(code, pos, comp, stop)
	if pos > #code then
		return comp, pos + 1, false
	end
	
	if stop and starts(code, pos, stop) then
		return comp, pos + #stop, true
	end

	for i, token in pairs(tokens) do
		local tok, inc, halt = token:get(code, pos)

		if halt then
			return comp, pos + inc
		end

		if tok ~= nil then
			tok.i = (comp.last[comp].prev.i or 0) + 1
			comp:push_back(tok)

			if debug then
				for v in comp:loop() do
					print((v.value or " ").." - "..v.type)
				end
				print("---------")
			end

			return tokenize(code, pos + inc, comp, stop)
		end
	end

	return tokenize(code, pos + 1, comp, stop)
end

function eat(comp)
	function pull(dist)
		return comp:pull(pos, dist) or tokens["nil"]
	end

	function set(tok)
		pos = comp:replace(pos, tok)
	end

	for i, t in pairs(tokens) do
		if t.eat then
			local tok = comp:get_first()

			while tok[comp].next do
				if tok.type == t.type then
					_G.pos = tok
					tok:eat()

					if debug then
						for v in comp:loop() do
							print((v.value or " ").." - "..v.type)
						end
						print("---------")
					end
				end

				tok = tok[comp].next
			end
		end
	end

	return comp
end

function functioniz(code, pos, stop)
	local comp = linked()

	while pos <= #code do
		if debug then
			print("==== token:")
		end

		comp, pos, ret = tokenize(code, pos, comp, stop)

		if ret then
			break
		end
	end

	return comp, pos
end

function compile(code, pos, stop)
	local comp = linked()
	local pos = pos or 1

	while pos <= #code do
		if debug then
			print("==== token:")
		end

		comp, pos, ret = tokenize(code, pos, comp, stop)

		if debug then
			print("====== eat:")
			for v in comp:loop() do
				print((v.value or " ").." - "..v.type)
			end
			print("---------")
		end

		eat(comp)

		if ret then
			break
		end
	end

	return comp, pos
end

--main loop

while not exit do
	io.write("> ")
	code = io.read("*l")
	if code:find("exit") or exit then
		break
	end
	print( ({(compile(code):get_first().value.." "):gsub( "%.0" , "" )})[1] )
end