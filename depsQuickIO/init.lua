local function read(f)
	f,w = io.open(f,"r");
	if f then
		local s = f:read("*all")
		f:close()
		return s
	end
	return f,w
end

local function write(f,...)
	f = io.open(f,"w");
	if f then
		f:write(...)
		f:flush()
		f:close()
		return true
	end
	return f,w
end

return {read=read,write=write}