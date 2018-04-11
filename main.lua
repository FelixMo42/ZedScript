function linked()
	t = {}
	t.first = {next = nil}
	t.last = {prev = first}
	t.first.next = t.last
	
	function t:push(v)
		local ref = self.first;
		while ref.next.val ~= nil and ref.next.val < v do
			ref = ref.next;
		end
		ref.next = {val = v, next = ref.next, prev = ref}
		if ref.next.next then
			ref.next.next.prev = ref.next
		end
		return ref.next
	end
	
	function t:push_back(v)
		local ref = self.last;
		while ref.prev.val ~= nil and ref.prev.val > v do
			ref = ref.prev;
		end
		ref.prev = {val = v, prev = ref.prev, next = ref}
		if ref.prev.prev then
			ref.prev.prev.next = ref.prev
		end
		return ref.prev
	end
	
	function t:pull(ref)
		if ref.prev then
			ref.prev.next = ref.next
		end
		if ref.next then
			ref.next.prev = ref.prev
		end
	end

	return t
end

--tokens

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
	--[[ string ]] {
		type = "string",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "\"" then
				local leng = 0
				while pos + leng + 1 <= #code and code:sub(pos + leng + 1,pos + leng + 1) ~= "\"" do
					leng = leng + 1
				end
				return new(self, code:sub(pos + 1,pos + leng)), leng + 2
			end
			if code:sub(pos,pos) == "'" then
				local leng = 0
				while pos + leng + 1 <= #code and code:sub(pos + leng + 1,pos + leng + 1) ~= "'" do
					leng = leng + 1
				end
				return new(self, code:sub(pos + 1,pos + leng)), leng + 2
			end
		end
	},
	--[[ adder ]] {
		type = "adder",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "+" or code:sub(pos,pos) == "-" then
				return new(self, code:sub(pos,pos)), 1
			end
		end,
		eat = function(self)
			local a = pull(-1)
			local b = pull(1)
			if self.value == "+" then
				if a.type == "number" and b.type == "number" then
					set( new(tokens.number, a.value + b.value ) )
				else
					set( new(tokens.string, a.value..b.value ) )
				end
			elseif self.value == "-" then
				set( new(tokens.number, a.value - b.value ) )
			end
		end
	},
	--[[ muler ]] {
		type = "muler",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "*" or code:sub(pos,pos) == "/" or code:sub(pos,pos) == "%" then
				return new(self, code:sub(pos,pos)), 1
			end
		end,
		eat = function(self)
			local a = pull(-1)
			local b = pull(1)
			if self.value == "*" then
				if a.type == "string" then
					local ret = ""
					for i = 1, b.value do
						ret = ret..a.value
					end
					set( new(tokens.number, ret) )
				elseif b.type == "string" then
					local ret = ""
					for i = 1, a.value do
						ret = ret..b.value
					end
					set( new(tokens.number, ret) )
				else
					set( new(tokens.number, pull(-1).value * pull(1).value ) )
				end
			elseif self.value == "/" then
				set( new(tokens.number, pull(-1).value / pull(1).value ) )
			end
		end
	},
	--[[ power ]] {
		type = "power",
		get = function(self, code, pos)
			if code:sub(pos,pos) == "^" then
				return new(self, code:sub(pos,pos)), 1
			end
		end,
		eat = function(self)
			set( new(tokens.number, pull(-1).value ^ pull(1).value ) )
		end
	},
	--[[ braks ]] {
		type = "power",
		get = function(self, code, pos)
			if code:sub(pos,pos) == ")" then
				return tokens.ended, 1, true
			end
			if code:sub(pos,pos) == "(" then
				comp, i = compile(code, pos + 1)
				return comp[0], i - pos
			end
		end
	}
}

function new(self, val)
	return setmetatable({value = val}, {__index = self} )
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
		local tok, inc, halt = token:get(code, pos)
		if tok ~= nil then
			if halt then
				return comp, pos
			end
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

function compile(code,pos)
	comp, i = tokenize(code, pos or 1, {})
	eat(comp)
	return comp, i
end

--main loop

while true do
	code = io.read("*l").." "
	if code:find("exit") then
		break
	end
	print( ({(compile(code)[1].value.." "):gsub(".0 "," ")})[1] )
end