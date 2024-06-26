local mc
if jit.os=="Windows"then
	mc = "mooncake"
else
	mc = "depsMoonCake/mooncake"
end

local fs = require"fs"
local json = require"json"
local timer = require"timer"
local helpers = require(mc.."/libs/helpers")
local tick = function() return helpers.getTime()/1000 end

local quickio = require"ose/quickio"
local auth = require"ose/authent"
local pafix = require"ose/pafix"

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

local function tablemerge(t1,t2)
	for i,v in pairs(t2) do
		if t1[i] ~= nil then
			if type(v)=="table" then
				t1[i]={}
				tableupdate(t1[i],v)
			else
				t1[i]=v
			end
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

function removedir(dir)
	return os.execute("rm -rf analytics"..OSS..dir)
end

function TableToString_OLD(t)
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

local function TableToString(t)
	local s = "{"
	for k,v in pairs(t) do
		if type(v)=="string" then v = "[==["..v.."]==]" end
		local ts = type(v)=="table" and TableToString(v) or v
		if ts==true then ts="true" elseif ts==false then ts="false" end
		if type(k)=="number" then
			s=s.."["..k.."]="..ts..","
		else
			s=s.."['"..k.."']="..ts..","
		end
	end
	return s.."}"
end

function TableToLoadstringFormat(t)
	return "return "..TableToString(t)
end

local defMetadata = {tick=1,fields={},duration=defCacheDuration,subs={}}

local function updateMetadata(metadata)
	for k,v in pairs(defMetadata) do
		if metadata[k]==nil then 
			metadata[k]=v
		end
	end
	return metadata
end

function getMetadata(key) --from file
	if not direxists(key) then return false,"Key doesn't exists",400 end
	if Analytics[key] then
		return updateMetadata(Analytics[key].metadata)
	else
		return updateMetadata(loadstring(quickio.read(pafix("analytics/%s/metadata",key)))())
	end
end

function setMetadata(key,metadata) --to file
	if not direxists(key) then return false,"Key doesn't exists",400 end
	return quickio.write(pafix("analytics/%s/metadata",key),TableToLoadstringFormat(metadata)) --pafix("analytics/%s/metadata",key)
end

function getKeyToRAM(key)
	if Analytics[key] then return true,"Already in RAM",300 end
	if not direxists(key) then return false,"Key isn't valid",400 end

	local metadata = getMetadata(key)

	Analytics[key] = {metadata=metadata}
	return true,"Success",200
end

function saveKey(key)
	if not Analytics[key] then return false,"Key doesn't exists",400 end
	if not direxists(key) then return false,"Key isn't valid",400 end

	do local s,n,e = setMetadata(key,Analytics[key].metadata) if not s then return s,n,e end end --Save metadata

	for DataField in pairs(Analytics[key].metadata.fields) do --Save data fields
		local f,s = io.open(pafix("analytics/%s/%s",key,DataField),"a+") --pafix("analytics/%s/%s",key,DataField)
		if not f then return f,s,500 end

		local n = Analytics[key][DataField] or 0

		f:write(" "..tostring(n))
		f:flush()
		f:close()
	end
	return true,"Success",200
end

local close = false


function module.removeKey(key)
	if close then return false,"Server is closing",503 end
	if type(key)~="string" then return false,"Key is not a string",400 end
	if string.len(key)<10 then return false,"Key can't be less than 10 characters",400 end

	local dire = direxists(key)

	if not Analytics[key] or not dire then return false,"Key doesn't exists",400 end

	print("removedir",removedir(key))

	for sub in pairs(Analytics[key].subs) do
		local usermeta = auth.getUserMetadata(sub)
		usermeta.keys[key]=nil
		auth.setUserMetadata(sub,usermeta)
	end


	Analytics[key] = nil
end

function module.createKey(key,sub,usermeta,specifics)
	if close then return false,"Server is closing",503 end
	if type(key)~="string" then return false,"Key is not a string",400 end
	if string.len(key)<10 then return false,"Key can't be less than 10 characters",400 end
	if Analytics[key] or direxists(key) then return false,"Key already exists",400 end

	if makedir(key)~=true then return false,"Failed to create key directory",500 end --Creates the directory
	if not direxists(key) then return false,"Key directory creation failed",500 end

	specifics = specifics or {}
	specifics.subs = specifics.subs or {}

	local ct = tick()

	local duration = defCacheDuration
	if specifics.duration then duration = specifics.duration>StepDuration and specifics.duration or StepDuration end 

	local metadata = {tick=ct,fields={},duration=duration,subs={}}
	metadata.subs[sub]={role="own"} --Put the suba s the owner of the key into keys metadata
	metadata.accessKey = "access"


	updateMetadata(metadata) --Update metadata of the key
	do local s,n,e = setMetadata(key,metadata) if not s then return s,n,e end end --Save metadata of key

	--local usermeta = auth.getUserMetadata(sub) --Get the metadata of the user who created the key and save it
	p(sub)
	usermeta.keys[key]=true
	auth.setUserMetadata(sub,usermeta)

	Analytics[key] = {metadata=metadata}
	return true,metadata,200
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

function module.getstreaming(res,key,DataField,readbytes)
	if close then return res:send("Server is closing",503) end
	if DataField=="metadata" then return res:send("Datafield name can't be metadata",400) end
	if not Analytics[key] and not direxists(key) then
		return res:send("Key doesn't exists",400)
	end
	if not Analytics[key] then
		getKeyToRAM(key)
		Analytics[key].metadata.tick = tick()
	end
	local v = Analytics[key][DataField]
	if not Analytics[key].metadata.fields[DataField] then return res:send("No data",400) end

	local fd = pafix("analytics/%s/%s",key,DataField)
	if fs.existsSync(fd) then
		fs.stat(fd,function(err,stat)
			if err then return res:send("Filesystem get stat failed",500) end
			fs.open(fd,"r",function(err, fd)
				if err then return res:send("File open failed",500) end

				local s,n = pcall(function()
					local buffer_size = 100
					readbytes = readbytes + buffer_size

					local readt = math.ceil(readbytes/buffer_size)

					local offset = 0
					if readbytes > stat.size then
						readt = math.ceil(stat.size/buffer_size)
						offset = stat.size%buffer_size
					end

					for i = 0, readt-1 do
						local o = stat.size-buffer_size*(readt-i)+buffer_size-offset

						local bytes,err = fs.readSync(fd, buffer_size, o)
						if bytes then
							res:write(bytes)
						else
							print("Error:", err)
						end
					end

					res:finish(" "..tostring(v or 0))
				end)

				if not s then return res:send(n,500) end
			end)
		end)
		
	else
		return res:json({v},200)
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

function module.setupTimer()
	timer.setInterval(1000*module.StepDuration,module.step)
end


function module.setupServer(server)
	if not server then return end--for debugging

	local function CheckAccessSubKey(res,token,key)
		local sub,n,e = auth.tokenLoggedin(token)
		if not sub then return true,res:send(n,e) end

		local metadata,n,e = getMetadata(key)
		if not metadata then return true,res:send(n,e) end
			
		if not metadata.subs[sub] then return true,res:send("No access to key",401) end
	end

	server:post("/analytics/getMetadata", function(req, res)
		coroutine.wrap(function()
			local key = req.body.key
			if not key then return res:send("Key can't be nil",400) end
			if tonumber(key) then return res:send("Key needs to be a string",400) end
			print("Get key",key)

			local token = auth.GetToken(req)--req.body.token or req.headers.token or req.cookies.token

			if CheckAccessSubKey(res,token,key) then return end

			local metadata,n,e = getMetadata(key)
			if not metadata then return true,res:send(n,e) end

			res:json(metadata,200)
		end)()
	end)

	server:post("/analytics/createKey", function(req, res)
		coroutine.wrap(function()
			local key = req.body.key
			if tonumber(key) then return res:send("Key needs to be a string",400) end
			if string.len(key)<10 then return res:send("Key length can't be less than 10",400) end

			local token = auth.GetToken(req)--req.body.token or req.headers.token or req.cookies.token

			local sub,n,e = auth.tokenLoggedin(token)
			if not sub then return res:send(n,e) end

			local usermeta = auth.getUserMetadata(sub)
			if not usermeta then return res:send("No user metadata found",500) end

			local s,n,e = module.createKey(key,sub,usermeta)
			if not s then res:send(n,e) end

			res:json(n,e)
		end)()
	end)

	server:post("/analytics/deleteKey", function(req, res)
		coroutine.wrap(function()
			local key = req.body.key
			if tonumber(key) then return res:send("Key needs to be a string",400) end
			if string.len(key)<10 then return res:send("Key length can't be less than 10",400) end

			local token = auth.GetToken(req)--req.body.token or req.headers.token or req.cookies.token

			local sub,n,e = auth.tokenLoggedin(token)
			if not sub then return res:send(n,e) end

			local usermeta = auth.getUserMetadata(sub)
			if not usermeta then return res:send("No user metadata found",500) end

			local s,n,e = module.deleteKey(key)
			if not s then res:send(n,e) end

			res:json(n,e)
		end)()
	end)

	local function fieldcheck(res,key,DataField,amount)
		if not key then return true,res:send("No key given",400) end
		if tonumber(key) or type(key)~="string" then return true,res:send("Key needs to be a string",400) end
		if string.len(key)<10 then return true,res:send("Key length can't be less than 10",400) end

		if not DataField then return true,res:send("No DataField given",400) end
		if tonumber(DataField) or type(DataField)~="string" then return true,res:send("DataField needs to be a string",400) end
		if string.len(DataField)<5 then return true,res:send("DataField length can't be less than 5",400) end

		if not amount then return true,res:send("No amount given",400) end
		if not (type(amount)=="number" or type(amount)=="string") then return true,res:send("Amount needs to be a number",400) end
		amount = tonumber(amount)
		if not amount then return true,res:send("Amount needs to be a number",400) end
	end

	server:post("/analytics/update", function(req, res)
		coroutine.wrap(function()
			local key = req.body.key
			local DataField = req.body.DataField
			local amount = req.body.amount

			if fieldcheck(res,key,DataField,amount) then return end

			local token = auth.GetToken(req)--req.body.token or req.headers.token or req.cookies.token

			if CheckAccessSubKey(res,token,key) then return end

			local s,n,e = module.update(key,DataField,amount)

			res:send(n,e)
		end)()
	end)

	server:post("/analytics/get", function(req, res)
		coroutine.wrap(function()
			local key = req.body.key
			local DataField = req.body.DataField
			local times = req.body.times

			if fieldcheck(res,key,DataField,times) then return end

			times = math.floor(times)
			if times<1 then return res:send("Times can't be less than 1",400) end
			if times>4086 then return res:send("Times is too big",400) end

			local token = auth.GetToken(req)--req.body.token or req.headers.token or req.cookies.token
			if CheckAccessSubKey(res,token,key) then return end

			local s,n,e = module.get(key,DataField,times)

			if not s then return res:send(n,e) end

			res:json(s,200)
		end)()
	end)

	server:post("/analytics/getstreaming", function(req, res) --IMPLEMENT TOKENS AND SUBS
		coroutine.wrap(function()
			local key = req.body.key
			local DataField = req.body.DataField
			local bytes = req.body.bytes

			if fieldcheck(res,key,DataField,bytes) then return end

			bytes = math.floor(bytes)
			if bytes<1 then return res:send("Bytes can't be less than 1",400) end

			local token = auth.GetToken(req)--req.body.token or req.headers.token or req.cookies.token
			if CheckAccessSubKey(res,token,key) then return end

			module.getstreaming(res,key,DataField,bytes)
		end)()
	end)
end

return module