function linked()
	t = {}
	t.first = {id = "first", [t] = {next = nil}}
	t.last = {id = "last", [t] = {prev = t.first}}
	t.first[t].next = t.last
	
	function t:push(v)
		local ref = self.first;
		while ref[self].next.i ~= nil and ref[self].next.i < v.i do
			ref = ref[self].next;
		end
		ref[self].next = v--{i = v, next = ref.next, prev = ref}
		v[self] = {next = ref[self].next, prev = ref}
		if ref[self].next[self].next then
			ref[self].next[self].next[self].prev = ref[self].next
		end
		return ref[self].next
	end
	
	function t:push_back(v)
		local ref = self.last;
		while ref[self].prev.i ~= nil and ref[self].prev.i > v.i do
			ref = ref[self].prev;
		end
		ref[self].prev = v
		v[self] = {prev = ref[self].prev, next = ref}
		if ref[self].prev[self].prev then
			ref[self].prev[self].prev[self].next = ref[self].prev
		end
		return ref[self].prev
	end
	
	function t:pull(ref)
		if ref[self].prev then
			ref[self].prev[self].next = ref[self].next
		end
		if ref[self].next then
			ref[self].next[self].prev = ref[self].prev
		end
	end

	function t:get_first()
		return self.first[self].next
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
		local ret = comp[pos + dist]
		local pointer = ret[comp].next
		while pointer[comp].next do
			pointer.i = pointer.i - 1
			pointer = pointer[comp].next
		end
		comp:pull(ret)
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
			local tok = comp.first[comp].next
			while tok[comp].next do
				if tok.type == t.type then
					_G.pos = tok.i
					tok:eat()
					print(tok.value)
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
	print( ({(compile(code):get_first().value.." "):gsub(".0 "," ")})[1] )
end