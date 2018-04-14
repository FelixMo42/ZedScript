require "linked"
tokens = require "tokens"

function new(self, val)
	return setmetatable({
		value = val
	}, {
		__index = function(s,key)
			return tokens[rawget(s,"type") or self.type][key]
		end
	} )
end

for k, v in pairs(tokens) do
	tokens[v.type] = v
end

vars = {}

--main funcs

function tokenize(code, pos, comp)
	if pos >= #code then
		return comp, pos
	end

	for i, token in pairs(tokens) do
		local tok, inc, halt = token:get(code, pos)
		if halt then
			return comp, pos
		end
		if tok ~= nil then
			tok.i = (comp.last[comp].prev.i or 0) + 1
			comp:push_back(tok)
			return tokenize(code, pos + inc, comp)
		end
	end

	return tokenize(code, pos + 1, comp)
end

function eat(comp)
	function pull(dist)
		return comp:pull(pos, dist)
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
					--[[ debug ] ] print("---------"); for v in comp:loop() do print(v.value.." - "..v.type) end print("---------"); --]]
				end
				tok = tok[comp].next
			end
		end
	end
end

function compile(code,pos)
	comp, i = tokenize(code, pos or 1, linked())
	eat(comp)
	return comp, i
end

--main loop

while true do
	code = io.read("*l").." "
	if code:find("exit") then
		break
	end
	print( ({(compile(code):get_first().value.." "):gsub( "%.0" , "" )})[1] )
end