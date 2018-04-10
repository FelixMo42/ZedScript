tokens = {
	--[[ number ]] {
		type = "number",
		get = function(self, code, pos)
			if code:sub(pos,pos) ~= " " and (tonumber(code:sub(pos,pos)) ~= nil) then
				local leng = 0
				while pos + leng + 1 <= #code and tonumber(code:sub(pos,pos + leng + 1)) ~= nil do
					leng = leng + 1
				end
				return new(self, tonumber(code:sub(pos,pos + leng))), leng + 1
			end
		end
	},
	--[[ adder ]] {
		type = "adder",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "+" or code:sub(pos,pos) == "-" then
				return setmetatable({
					value = code:sub(pos,pos)
				}, { __index = self } ), 1
			end
		end,
		eat = function(self)
			if self.value == "+" then
				set( new(tokens.number, pull(-1).value + pull(1).value ) )
			elseif self.value == "-" then
				set( new(tokens.number, pull(-1).value - pull(1).value ) )
			end
		end
	},
	--[[ muler ]] {
		type = "muler",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "*" or code:sub(pos,pos) == "/" or code:sub(pos,pos) == "%" then
				return setmetatable({
					value = code:sub(pos,pos)
				}, { __index = self } ), 1
			end
		end,
		eat = function(self)
			if self.value == "*" then
				set( new(tokens.number, pull(-1).value * pull(1).value ) )
			elseif self.value == "/" then
				set( new(tokens.number, pull(-1).value / pull(1).value ) )
			end
		end
	},
	--[[ power ]] {
		type = "power",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "^" then
				return setmetatable({
					value = code:sub(pos,pos)
				}, { __index = self } ), 1
			end
		end,
		eat = function(self)
			set( new(tokens.number, pull(-1).value ^ pull(1).value ) )
		end
	},
	--[[ braks ]] {
		type = "power",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "(" then
				comp, i = tokenize(code, pos + 1, {})
				return comp[0], i
			end
		end
	}
}

new = function(self, val)
	return setmetatable({
		value = val
	}, { __index = self } )
end

for k, v in pairs(tokens) do
	tokens[v.type] = v
end

--main funcs

function tokenize(code, pos, comp)
	if pos >= #code then
		return comp, pos
	end

	for i, token in pairs(tokens) do
		local tok, inc = token:get(code, pos)
		if tok ~= nil then
			comp[#comp + 1] = tok
			return tokenize(code, pos + inc, comp)
		end
	end

	return tokenize(code, pos + 1, comp)
end

function eat(comp)
	function pull(dist)
		local ret = comp[pos + dist]
		table.remove(comp, pos + dist)
		if dist < 0 then
			pos = pos - 1
		end
		return ret
	end

	function set(tok)
		comp[pos] = tok
	end

	for i, t in pairs(tokens) do
		if t.eat then
			for pos, tok in pairs(comp) do
				if tok.type == t.type then
					_G.pos = pos
					tok:eat()
				end
			end
		end
	end
end

function compile(code)
	comp, i = tokenize(code, 1, {})
	eat(comp)
	return comp[1]
end

--main loop

while true do
	code = io.read("*l").." "
	if code:find("exit") then
		break
	end
	print( ({(compile(code).value.." "):gsub(".0 "," ")})[1] )
end