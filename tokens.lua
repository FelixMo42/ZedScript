-- These are the tokens in the langauge in the order of operation

tokens = {

---- **** OPERATORS **** ----

--[[ braks ]] {
	type = "braks",
	get = function(self, code, pos)
		if code:sub(pos, pos) == ")" then
			return tokens.ended, 1, true
		end
		if code:sub(pos, pos) == "(" then
			comp, i = compile(code, pos + 1, ")")
			return comp:get_first(), i - pos
		end
	end,
	eat = function(self)
		
	end
},
--[[ power ]] {
	type = "power",
	get = function(self, code, pos)
		if code:sub(pos, pos) == "^" then
			return new(self, code:sub(pos, pos)), 1
		end
	end,
	eat = function(self)
		set( new(tokens.number, pull(-1).value ^ pull(1).value ) )
	end
},
--[[ muler ]] {
	type = "muler",
	get = function(self, code, pos)
		if ("*/%"):find(code:sub(pos, pos)) then
			return new(self, code:sub(pos, pos)), 1
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
				set( new(tokens.number, a.value * b.value) )
			end
		elseif self.value == "/" then
			if a.type == "number" and b.type == "number" then
				set( new(tokens.number, a.value / b.value) )
			elseif a.type == "number" then
				set( new(tokens.number, tonumber( ({tostring(a.value):gsub(tostring(b.value), "")})[1] ) ) )
			else
				set( new(tokens.string, tostring(a.value):gsub(tostring(b.value), "") ) )
			end
		end
	end
},
--[[ adder ]] {
	type = "adder",
	get = function(self, code, pos)
		if code:sub(pos, pos) == "+" or code:sub(pos, pos) == "-" then
			return new(self, code:sub(pos, pos)), 1
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
--[[ comper ]] {
	type = "comper",
	get = function(self, code, pos)
		if code:sub(pos, pos + 1) == "==" then
			return new(self, code:sub(pos, pos + 1)), 2
		elseif code:sub(pos, pos + 1) == "<=" then
			return new(self, code:sub(pos, pos + 1)), 2
		elseif code:sub(pos, pos) == "<" then
			return new(self, code:sub(pos, pos)), 1
		elseif code:sub(pos, pos + 1) == ">=" then
			return new(self, code:sub(pos, pos + 1)), 2
		elseif code:sub(pos, pos) == ">" then
			return new(self, code:sub(pos, pos)), 1
		elseif code:sub(pos, pos + 1) == "!=" then
			return new(self, code:sub(pos, pos + 1)), 2
		end
	end,
	eat = function(self)
		local a = pull(-1)
		local b = pull(1)
		if self.value == "==" then
			set( new(tokens.bool, a.value == b.value) )
		elseif self.value == "<=" then
			set( new(tokens.bool, a.value <= b.value) )
		elseif self.value == "<" then
			set( new(tokens.bool, a.value < b.value) )
		elseif self.value == ">=" then
			set( new(tokens.bool, a.value >= b.value) )
		elseif self.value == ">" then
			set( new(tokens.bool, a.value > b.value) )
		elseif self.value == "!=" then
			set( new(tokens.bool, a.value ~= b.value) )
		end
	end
},

---- **** DATA **** ----

--[[ number ]] {
	type = "number",
	isdata = true,
	get = function(self, code, pos)
		if (code:sub(pos, pos) ~= " " and tonumber(code:sub(pos, pos + 1)) ~= nil) or tonumber(code:sub(pos, pos)) then
			local leng = 0
			while pos + leng + 1 <= #code and tonumber(code:sub(pos, pos + leng + 1)) ~= nil do
				leng = leng + 1
			end
			return new(self, tonumber(code:sub(pos, pos + leng))), leng + 1
		end
	end
},
--[[ string ]] {
	type = "string",
	isdata = true,
	get = function(self, code, pos)
		if code:sub(pos, pos) == "\"" then
			local leng = 0
			while pos + leng + 1 <= #code and code:sub(pos + leng + 1, pos + leng + 1) ~= "\"" do
				leng = leng + 1
			end
			return new(self, code:sub(pos + 1, pos + leng)), leng + 2
		end
		if code:sub(pos, pos) == "'" then
			local leng = 0
			while pos + leng + 1 <= #code and code:sub(pos + leng + 1, pos + leng + 1) ~= "'" do
				leng = leng + 1
			end
			return new(self, code:sub(pos + 1, pos + leng)), leng + 2
		end
	end
},
--[[ bool ]] {
	type = "bool",
	isdata = true,
	get = function(self, code, pos)
		if starts(code, pos, "true") then
			return new(self, true), 4
		elseif starts(code, pos, "false") then
			return new(self, false), 5
		end
	end
},
--[[ nil ]] {
	type = "nil",
	isdata = true,
	get = function(self, code, pos)
		if starts(code, pos, "nil") then
			return new(self), 3
		end
	end
},

---- **** STRUCTURE **** ----

--[[ if ]] {
	type = "if",
	get = function(self, code, pos)
		if starts(code, pos, "if") then
			local if_comp, i = compile(code, pos + 2, "do")
			local outputs, last = {}, "if"
			while true do
				local do_func, r, stop = functioniz(code, i, {"elseif", "else", "end"})
				outputs[#outputs + 1] = do_func
				
				if last == "else" then
					outputs["else"] = do_func
				end
				
				if stop == "end" then
					if if_comp:get_first().value then
						return eat(outputs[1]):get_first(), i - pos
					elseif outputs["else"] then
						return eat(outputs["else"]):get_first(), r - pos
					else
						return new(tokens["nil"]), r - pos
					end
				end

				i = r
				last = stop
			end
		end
	end
},
--[[ not ]] {
	type = "not",
	get = function(self, code, pos)
		if starts(code, pos, "not") then
			return new(self, "not"), 3
		end
	end,
	eat = function(self)
		local a = pull(1).value
		set( new(tokens.bool, not a) )
	end
},
--[[ and ]] {
	type = "and",
	get = function(self, code, pos)
		if starts(code, pos, "and") then
			return new(self, "and"), 3
		end
	end,
	eat = function(self)
		local a = pull(-1).value
		local b = pull(1).value
		set( new(tokens.bool, a and b) )
	end
},
--[[ or ]] {
	type = "or",
	get = function(self, code, pos)
		if starts(code, pos, "or") then
			return new(self, "or"), 2
		end
	end,
	eat = function(self)
		local a = pull(-1).value
		local b = pull(1).value
		set( new(tokens.bool, a or b) )
	end
},
--[[ xor ]] {
	type = "xor",
	get = function(self, code, pos)
		if starts(code, pos, "xor") then
			return new(self, "xor"), 3
		end
	end,
	eat = function(self)
		local a = pull(-1).value
		local b = pull(1).value
		set( new(tokens.bool, (a or b) and not (a and b) ) )
	end
},

---- **** VARIABLES **** ----

--[[ equals ]] {
	type = "equals",
	get = function(self, code, pos)
		if code:sub(pos, pos) == "=" then
			return new(self, code:sub(pos, pos)), 1
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
--[[ var ]] {
	type = "var",
	get = function(self, code, pos)
		if code:sub(pos, pos):match("[^%wπ]") then return end
		local leng = 0
		while pos + leng + 1 <= #code and not code:sub(pos + leng + 1, pos + leng + 1):match("[^%wπ]") do
			leng = leng + 1
		end
		local name = code:sub(pos, pos + leng)
		local var = vars[name] or new(tokens["nil"])
		vars[name] = var
		return setmetatable( {
			isdata = true
		}, {
			__newindex = function(self, key, val)
				if key == "type" then
					getmetatable(var).__index = tokens[val]
				end
				var[key] = val
			end,
			__index = function(self, key)
				return var[key]
			end
		}), leng + 1
	end
},

}