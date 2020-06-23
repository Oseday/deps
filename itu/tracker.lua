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

local Users = {testuser=true,cancakir=true}

local Locations = {
	["Lokasyon A"] = {checked=true,  username="testuser"},
	["Lokasyon B"] = {checked=true,  username="cancakir"},
	["Lokasyon C"] = {checked=false, username=""},
	["Lokasyon D"] = {checked=false, username=""},
}

function SaveUsers()
	local f,w = quickio.write(pafix("itu/users"), TableToLoadstringFormat(Users))
	if not f then print("ERROR: Couldn't save users:", w) end
end

function SaveLocations()
	local f,w = quickio.write(pafix("itu/locations"), TableToLoadstringFormat(Locations))
	if not f then print("ERROR: Couldn't save locations:", w) end
end

do --Server start read users and locations
	local f,w = quickio.read(pafix("itu/users"))
	if f then
		Users = loadstring(f)()
	else
		print("Error opening itu/users:", w)
		SaveUsers()
	end

	local f,w = quickio.read(pafix("itu/locations"))
	if f then
		Locations = loadstring(f)()
	else
		print("Error opening itu/locations:", w)
		SaveUsers()
	end
end

function module.setupServer(server)

	server:post("/login", function(req, res)
		local username = req.body.username
		p(username)
		if Users[username] then
			res:send("",200)
		else
			res:send("",400)
		end
	end)

	server:post("/viewer/tabledata", function(req, res)
		local t = {}
		for Location,tab in pairs(Locations) do

			local occupancy = tab.username
			local isChecked = tab.checked

			p(req.body)
			p(req.body.username)

			local isDisabled = not( (occupancy == "") or (occupancy == req.body.username) )

			t[#t+1]={Location, isChecked, isDisabled}
		end
		res:json(t,200)
	end)

	server:post("/viewer/tablesubmit", function(req, res)
		local body = req.body

		local username = body.username
		p(username)

		if not Users[username] then
			res:send("",400)
		end

		body.username = nil

		p(body)

		for loc,tab in pairs(Locations) do
			if body[loc] then
				if tab.username == ""  then
					Locations[loc].username = username
					Locations[loc].checked = true
				end
			else
				if tab.checked and tab.username == username then
					Locations[loc].username = ""
					Locations[loc].checked = false
				end
			end
		end

		res:send("",200)
	end)

	server:get("/admin/userlist", function(req, res)
		local s = ""
		for k in pairs(Users) do
			s = s .. k .. " "
		end
		s = s .. ""
		res:send(s,200)
	end)

	server:get("/admin/locations", function(req, res)
		local s = ""
		for k,t in pairs(Locations) do
			s = s .. k .. ": " .. (t.username=="" and "0" or t.username) .. "\n"
		end
		s = s .. ""
		res:send(s,200)
	end)

	server:post("/admin/createuser", function(req, res)
		if Users[req.body.username] then
			res:send("already an user with this name, go back",400)
		end
		Users[req.body.username]=true
		SaveUsers()
		res:send("created, go back",200)
	end)

	server:post("/admin/deleteuser/", function(req, res)
		if not Users[req.body.username] then
			res:send("no user with this name, go back",400)
		end
		Users[req.body.username]=nil
		SaveUsers()
		res:send("deleted, go back",200)
	end)



	server:get("/admin/resetalllocations", function(req, res)
		for k,v in pairs(Locations) do
			Locations[k] = {checked=false, username=""}
		end
		SaveLocations()
		res:send("Locations reset, go back",200)
	end)

	server:post("/admin/createlocation", function(req, res)
		if Locations[req.body.username] then
			res:send("already a location with this name, go back",400)
		end
		Locations[req.body.username]={checked=false, username=""}
		SaveLocations()
		res:send("created, go back",200)
	end)

	server:post("/admin/deletelocation/", function(req, res)
		if not Locations[req.body.username] then
			res:send("no locations with this name, go back",400)
		end
		Locations[req.body.username]=nil
		SaveLocations()
		res:send("deleted, go back",200)
	end)



	--server:get("")


	--[[server:get("/viewer/:username", function(req, res)
		local username = req.params.username

	end)]]


	-- body
end


return module