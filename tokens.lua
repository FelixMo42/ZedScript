return {

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
				set( new(tokens.number, a.value * b.value ) )
			end
		elseif self.value == "/" then
			if a.type == "number" and b.type == "number" then
				set( new(tokens.number, a.value / b.value ) )
			elseif a.type == "number" then
				set( new(tokens.number, tonumber( ({tostring(a.value):gsub(tostring(b.value),"")})[1] ) ) )
			else
				set( new(tokens.string, tostring(a.value):gsub(tostring(b.value),"") ) )
			end
		end
	end
},

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
			return new(self, code:sub(pos,pos)), 1
		end
	end,
	eat = function(self)
		local a = pull(-1)
		local b = pull(1)
		if self.value == "+" then
			if a.type == "number" and b.type == "number" then
				set( new(tokens.number, a.value + b.value ) )
			elseif a.type == "number" and tonumber(a.value..b.value) then
				set( new(tokens.number, tonumber(a.value..b.value) ) )
			else
				set( new(tokens.string, a.value..b.value ) )
			end
		elseif self.value == "-" then
			if a.type == "number" and b.type == "number" then
				set( new(tokens.number, a.value - b.value ) )
			elseif a.type == "number" then
				set( new(tokens.number, tonumber( ({tostring(a.value):gsub( tostring(b.value) , "" , 1 )})[1] )))
			else
				set( new(tokens.string, tostring(a.value):gsub( tostring(b.value) , "" , 1 )) )
			end
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

--[[ braks ]] {
	type = "power",
	get = function(self, code, pos)
		if code:sub(pos,pos) == ")" then
			return tokens.ended, 1, true
		end
		if code:sub(pos,pos) == "(" then
			comp, i = compile(code, pos + 1)
			return comp:get_first(), i - pos + 1
		end
	end
},

--[[ equals ]] {
	type = "equals",
	get = function(self, code, pos)
		if code:sub(pos,pos) == "=" then
			return new(self, code:sub(pos,pos)), 1
		end
	end,
	eat = function(self)
		v = pull(-1)
		i = pull(1)
		v.value = i.value
		v.type = i.type
		set(v)
	end
},

--[[ nil ]] {
	type = "nil",
	get = function(self, code,pos)
		if code:sub(pos,pos+3) == "nil" and code:sub(pos+4,pos+4):match("%W") then
			return new(tokens["nil"]), 3
		end
	end
},

--[[ var ]] {
	type = "var",
	get = function(self, code,pos)
		if code:sub(pos,pos):match("%W") then return end
		local leng = 0
		while pos + leng + 1 <= #code and not code:sub(pos + leng + 1,pos + leng + 1):match("%W") do
			leng = leng + 1
		end
		--print(": "..code:sub(pos,pos + leng))
		local name = code:sub(pos,pos + leng)
		local var = vars[name] or new(tokens["nil"])
		vars[name] = var
		return setmetatable( {}, {
			__newindex = function(self,key,val)
				if key == "type" then
					getmetatable(var).__index = tokens[val]
				end
				var[key] = val
			end,
			__index = function(self,key)
				return var[key]
			end
		}), leng + 1
	end
},

}