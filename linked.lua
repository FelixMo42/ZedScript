local function push(self, v)
	local ref = self.first;
	while ref[self].next.i ~= nil and ref[self].next.i <= v.i do
		ref = ref[self].next;
	end
	
	v[self] = {next = ref[self].next, prev = ref}

	ref[self].next[self].prev = v
	ref[self].next = v

	return v
end

local function push_back(self, v)
	local ref = self.last;
	while ref[self].prev.i ~= nil and v.i <= ref[self].prev.i do
		ref = ref[self].prev;
	end

	v[self] = {prev = ref[self].prev, next = ref}

	ref[self].prev[self].next = v
	ref[self].prev = v

	return v
end

local function pull(self, ref, i)
	if i and i >= 1 then
		for i = 1, i do
			ref = ref[self].next
		end
	elseif i and i <= -1 then
		for i = 1, math.abs(i) do
			ref = ref[self].prev
		end
	end
	if ref[self].prev then
		ref[self].prev[self].next = ref[self].next
	end
	if ref[self].next then
		ref[self].next[self].prev = ref[self].prev
	end
	return ref
end

local function replace(self, ref, new)
	new.i = ref.i
	ref[self].next[self].prev = new
	ref[self].prev[self].next = new
	new[self] = ref[self]
	return new
end

function get_first(self)
	return self.first[self].next
end

local function iter(self, index)
	if not index[self].next[self].next then return end
	return index[self].next
end

local function loop(self)
	return iter, self, self.first
end

function linked()
	t = {}

	t.first = {id = "first", [t] = {next = nil}}
	t.last = {id = "last", [t] = {prev = t.first}}
	t.first[t].next = t.last

	t.push = push
	t.push_back = push_back
	t.pull = pull
	t.get_first = get_first
	t.loop = loop
	t.replace = replace

	return t
end