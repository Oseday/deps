local mc
if jit.os=="Windows"then
	mc = "mooncake"
else
	mc = "depsMoonCake/mooncake"
end


--local dynamodb = require"./dynamodb-comm"
local json = require"json"
local timer = require"timer"
--local sleep = require"./sleep"
local helpers = require(mc.."/libs/helpers")
local tick = function() return helpers.getTime()/1000 end

local quickio = require"ose/quickio"
local auth = require"ose/authent"

local function tableupdate(t1,t2)
	for i,v in pairs(t2) do
		if type(v)=="table" then
			if not t1[i] then
				t1[i]={}
			end
			tableupdate(t1[i],v)
		else
			t1[i]=v
		end
	end
end

local module = {}
local Analytics = {}

local defCacheDuration = 15 --seconds

module.StepDuration = 5 --seconds

local OSS = jit.os=="Windows" and "\\" or "/"

function direxists(dir) 
	return os.execute("[ -d analytics"..OSS..dir.." ]")==true
end

function makedir(dir)
	return os.execute("mkdir analytics"..OSS..dir)
end


function TableToString(t)
	local s = "{"
	for k,v in pairs(t) do
		if type(k)=="number" then
			local ts = type(v)=="table" and TableToString(v) or v
			if ts==true then ts="true" elseif ts==false then ts="false" end
			s=s.."["..k.."]="..ts..","
		else
			local ts = type(v)=="table" and TableToString(v) or v
			if ts==true then ts="true" elseif ts==false then ts="false" end
			s=s.."['"..k.."']="..ts..","
		end
	end
	return s.."}"
end

function TableToLoadstringFormat(t)
	return "return "..TableToString(t)
end

function getMetadata(key) --from file
	if not direxists(key) then return false,"Key doesn't exists",500 end
	if Analytics[key] then
		return Analytics[key].metadata 
	else
		return loadstring(quickio.read("analytics"..OSS..key..OSS.."metadata"))()
	end
end

function setMetadata(key,metadata) --to file
	if not direxists(key) then return false,"Key doesn't exists",500 end
	return quickio.write("analytics"..OSS..key..OSS.."metadata",TableToLoadstringFormat(metadata))
end

function getKeyToRAM(key)
	if Analytics[key] then return true,"Already in RAM",300 end
	if not direxists(key) then return false,"Key isn't valid",500 end

	local metadata = getMetadata(key)

	Analytics[key] = {metadata=metadata}
	return true,"Success",200
end

function saveKey(key)
	if not Analytics[key] then return false,"Key doesn't exists",500 end
	if not direxists(key) then return false,"Key isn't valid",500 end

	do local s,n,e = setMetadata(key,Analytics[key].metadata) if not s then return s,n,e end end --Save metadata

	for DataField in pairs(Analytics[key].metadata.fields) do --Save data fields
		local f,s = io.open("analytics"..OSS..key..OSS..DataField,"a+")
		if not f then return f,s,500 end

		local n = Analytics[key][DataField] or 0

		f:write(" "..tostring(n))
		f:flush()
		f:close()
	end
	return true,"Success",200
end

local close = false

function module.createKey(key,specifics)
	if close then return false,"Server is closing",503 end
	if type(key)~="string" then return false,"Key is not a string",400 end
	if Analytics[key] or direxists(key) then return false,"Key already exists",400 end

	if makedir(key)~=true then return false,"Failed to create key directory",500 end --Creates the directory
	if not direxists(key) then return false,"Key directory creation failed",500 end

	specifics = specifics or {}

	local ct = tick()

	local duration = defCacheDuration
	if specifics.duration then duration = specifics.duration>StepDuration and specifics.duration or StepDuration end 

	local metadata = {tick=ct,fields={},duration=duration}

	do local s,n,e = setMetadata(key,metadata) if not s then return s,n,e end end --Save metadata

	Analytics[key] = {metadata=metadata}
	return true,"Success",200
end

function module.update(key,DataField,amount)
	if close then return false,"Server is closing",503 end
	if DataField=="metadata" then return false,"Datafield name can't be metadata",400 end
	if not Analytics[key] and not direxists(key) then
		return false,"Key doesn't exists",400
	end
	if not Analytics[key] then
		getKeyToRAM(key)
		Analytics[key].metadata.tick = tick()
	end
	local v = Analytics[key][DataField]
	if v then
		Analytics[key][DataField] = v + amount 
	else
		Analytics[key][DataField] = amount
	end
	if not Analytics[key].metadata.fields[DataField] then
		Analytics[key].metadata.fields[DataField]=true
	end
	return true,"Success",200
end

local ffi = require"ffi"

function seekFileLast(f,times)
	local array = {}--ffi.new()

	local i,trials = 0,20*times
	f:seek("end",-20*times)
	while true do
		i=i+1
		local n = f:read("*n")
		if not n or i>trials then break else
			table.insert(array,n)
		end
	end
	return array
end

function module.get(key,DataField,times)
	if close then return false,"Server is closing",503 end
	if DataField=="metadata" then return false,"Datafield name can't be metadata",400 end
	if not Analytics[key] and not direxists(key) then
		return false,"Key doesn't exists",400
	end
	if not Analytics[key] then
		getKeyToRAM(key)
		Analytics[key].metadata.tick = tick()
	end
	local v = Analytics[key][DataField]
	local array = {}--ffi.new()
	if v then
		if times == 1 then return {v},"Success",200 end
		local f = io.open("analytics"..OSS..key..OSS..DataField,"r")
		if not f then return {v},"Success",200 end

		array = seekFileLast(f,times)

		local ar = {v}
		for i = 0,times-1 do
			ar[i+2]=array[#array-i]
		end
		f:close()
		return ar,"Success",200
	else
		local f,n = io.open("analytics"..OSS..key..OSS..DataField,"r")
		if not f then return f,"No info at this datafield",400 end

		array = seekFileLast(f,times)

		f:close()

		local ar = {}
		for i = 0,times-1 do
			ar[i+1]=array[#array-i]
		end
		return ar,"Success",200
	end
end

function module.step()
	for key,tab in pairs(Analytics) do
		if tab.metadata.tick + tab.metadata.duration < tick() then--Cache duration expired
			Analytics[key].metadata.tick = tick()
			saveKey(key)
			Analytics[key]={metadata=Analytics[key].metadata}
		end
	end
end

function module.close()
	for key,tab in pairs(Analytics) do
		print(saveKey(key))
	end
	Analytics = {}
end

function module.setupServer(server)
	if server then--for debugging

	server:get("/analytics", function(req, res)--Website home page
		print("Doing analytics")
		res:send("Analytics website goes here", 200)
	end)

	server:get("/analytics/getMetadata/:key", function(req, res)
		local key = req.pargams.key
		if tonumber(key) then return res:send("Key needs to be a string",400) end
		print("Get key",key)
		local metadata,n,e = getMetadata(key)
		if not metadata then return res:send(n,e) end
		metadata = tableToString(metadata)
		res:send(metadata,200)
	end)

	server:get("/analytics/createKey/:key", function(req, res)
		local key = req.params.key
		if tonumber(key) then return res:send("Key needs to be a string",400) end
		if string.len(key)<5 then return res:send("Key length can't be less than 5",400) end

		local s,n,e = module.createKey(key)

		res:send(n,e)
	end)

	server:get("/analytics/update/:key/:DataField/:amount", function(req, res)
		local key = req.params.key
		if tonumber(key) then return res:send("Key needs to be a string",400) end
		if string.len(key)<5 then return res:send("Key length can't be less than 5",400) end

		local DataField = req.params.DataField
		if tonumber(DataField) then return res:send("DataField needs to be a string",400) end
		if string.len(DataField)<5 then return res:send("DataField length can't be less than 5",400) end

		local amount = tonumber(req.params.amount)
		if not amount then return res:send("Amount needs to be a number",400) end

		local s,n,e = module.update(key,DataField,amount)

		res:send(n,e)
	end)

	server:get("/analytics/get/:key/:DataField/:times", function(req, res)
		local key = req.params.key
		if tonumber(key) then return res:send("Key needs to be a string",400) end
		if string.len(key)<5 then return res:send("Key length can't be less than 5",400) end

		local DataField = req.params.DataField
		if tonumber(DataField) then return res:send("DataField needs to be a string",400) end
		if string.len(DataField)<5 then return res:send("DataField length can't be less than 5",400) end

		local times = math.floor(tonumber(req.params.times))
		if not times then return res:send("Times needs to be a number",400) end
		if times<1 then return res:send("Times can't be less than 1",400) end
		if times>4086 then return res:send("Times is too big",400) end

		local s,n,e = module.get(key,DataField,times)

		if not s then return res:send(n,e) end

		res:json(s,200)
	end)

	end
	timer.setInterval(1000*module.StepDuration,module.step)
end

return module