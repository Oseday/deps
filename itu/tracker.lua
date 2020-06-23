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
local pafix = require"ose/pafix"

local OSS = jit.os=="Windows" and "\\" or "/"

function direxists(dir) 
	return os.execute("[ -d itu"..OSS..dir.." ]")==true
end

function makedir(dir)
	return os.execute("mkdir itu"..OSS..dir)
end

function removedir(dir)
	return os.execute("rm -rf itu"..OSS..dir)
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

function SerializeHashmap(tab)
	local t = {}
	local f = 0
	for k in pairs(tab) do
		f = f + 1
		t[f]=k
	end
	return t
end

--read
	--(loadstring(quickio.read(pafix("itu/%s/metadata",key)))())

--write
	--if not direxists(key) then return false,"Key doesn't exists",400 end
	--return quickio.write(pafix("itu/%s/metadata",key),TableToLoadstringFormat(metadata))

local Users = {testuser=true}

local Locations = {
	["Lokasyon A"] = {true, "testuser"},
	["Lokasyon B"] = {false},
	["Lokasyon C"] = {false},
}

function SaveUsers()
	local f,w = quickio.write(pafix("itu/users"), TableToLoadstringFormat(Users))
	if not f then print("ERROR: Couldn't save users:", w) end
end

do --Server start read users
	local f,w = quickio.read(pafix("itu/users"))
	if f then
		Users = loadstring(f)()
	else
		print("Error opening itu/users:", w)
		SaveUsers()
	end
end

function module.setupServer(server)

	server:post("/login", function(req, res)
		local username = req.body
		p(username)
		if Users[username] then
			res:send("",200)
		else
			res:send("",400)
		end
	end)

	server:post("/tabledata", function(req, res)
		local t = {}
		for k,v in pairs(Locations) do
			t[#t+1]={k,v[1],v[2]}
		end
		res:json(t,200)
	end)

	server:post("/tablesubmit", function(req, res)
		local body = req.body

		local username = body.username
		p(username)

		if not Users[username] then
			res:send("",400)
		end

		body.username = nil

		for k,v in pairs(body) do

		end

		res:send("",200)
	end)


	--[[server:get("/viewer/:username", function(req, res)
		local username = req.params.username

	end)]]


	-- body
end


return module