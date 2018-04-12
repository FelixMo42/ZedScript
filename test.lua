outher = {
	"1",
	"2",
	"3"
}

value = setmetatable({},{
	__index = function(self,key)
		return outher[key]
	end,
	__newindex = function(self,key)
	end
})

value[2] = "1"

print( value[2] )