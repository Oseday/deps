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

local Users = {testuser={fullname="Test User"},cancakir={fullname="Can Çakır"}}

local Locations = {
	["Lokasyon A"] = {checked=true, details="",  username="testuser", date="15:07", pos={latitude=0,longitude=0}},
	["Lokasyon B"] = {checked=true, details="",  username="cancakir", date="10:41", pos={latitude=0,longitude=0}},
	["Lokasyon C"] = {checked=false, details="", username="", date="", pos={latitude=0,longitude=0}},
	["Lokasyon D"] = {checked=false, details="", username="", date="", pos={latitude=0,longitude=0}},
}



function SaveTable(tab,path)
	local f,w = quickio.write(pafix("itu/"..path), TableToLoadstringFormat(tab))
	if not f then print("ERROR: Couldn't save "..path..":", w) end
end

function LoadTable(tab,path)
	local f,w = quickio.read(pafix("itu/"..path))
	if f then
		local temp = loadstring(f)()
		for k,v in pairs(temp) do
			tab[k]=v
		end
	else
		print("Error opening itu/"..path..":", w)
		SaveTable(tab,path)
	end
end

do --Server start read users and locations
	LoadTable(Users,"users")
	LoadTable(Locations,"locations")
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

			t[#t+1]={Location, isChecked, isDisabled, (occupancy~="") and Users[occupancy].fullname or "", tab.date, tab.details}
		end
		res:json(t,200)
	end)

	server:post("/viewer/tablesubmit", function(req, res)
		p(req.body)

		print(next(req.body))

		req.body = json.parse((next(req.body)))

		local dataT = req.body.data
		local pos = req.body.pos

		local username
		do
			for i,v in pairs(dataT) do
				if v.name == "username" then
					username = v.value
					dataT[i]=nil
				end	
			end
		end

		local data = {}
		for i,v in pairs(dataT) do
			data[v.name]=v.value
		end

		if not Users[username] then
			res:send("",400)
		end

		data.username = nil

		for loc,tab in pairs(Locations) do
			if data[loc] then
				if tab.username == ""  then
					Locations[loc].username = username
					Locations[loc].checked = true
					Locations[loc].date = os.date("%H:%M", os.time()+3*60*60)
					Locations[loc].pos = pos
				end
			else
				if tab.checked and tab.username == username then
					Locations[loc].username = ""
					Locations[loc].checked = false
					Locations[loc].date = ""
					Locations[loc].pos = {latitude=0,longitude=0}
				end
			end
		end

		res:send("",200)
	end)

	--[[
	server:get("/admin/userlist", function(req, res)
		local s = "<p>"
		for k in pairs(Users) do
			s = s .. k .. "<br>"
		end
		s = s .. "</p>"
		res:send(s,200)
	end)
	]]

	--[[
	server:get("/admin/locations", function(req, res)
		local s = "<p>"
		for k,t in pairs(Locations) do
			s = s .. k .. ": " .. (t.username=="" and "0" or (t.username .."("..Users[t.username].fullname..")") ) .. "<br>"
		end
		s = s .. "</p>"
		res:send(s,200)
	end)
	]]


	server:get("/admin/userdata", function(req, res)
		local t = {}
		for username,v in pairs(Users) do

			local owned = ""
			for loc,ltab in pairs(Locations) do
				if ltab.username == username then
					owned = owned .. loc .. ", " 
				end
			end
			owned = owned:sub(1,-3)

			t[#t+1] = {username, v.fullname, owned}
		end
		res:json(t,200)
	end)

	server:post("/admin/createuser", function(req, res)
		p(req.body.username)
		if Users[req.body.username] then
			res:send("already an user with this name, go back",400)
		end
		Users[req.body.username]={fullname=req.body.fullname}
		p("created")
		SaveTable(Users,"users")
		res:send("created, go back",200)
	end)

	local function deleteuser(username)
		if not Users[username] then
			return "no user with this name, go back",400
		end
		Users[username]=nil
		SaveTable(Users,"users")
		return "deleted, go back",200
	end

	server:post("/admin/deleteuser", function(req, res)
		res:send(deleteuser(req.body.username))
	end)

	server:post("/admin/bulkdeleteusers", function(req, res)
		for username in pairs(req.body) do
			deleteuser(username)
		end
		res:send("deleted",200)
	end)



	server:get("/admin/resetalllocations", function(req, res)
		for k,v in pairs(Locations) do
			Locations[k].checked = false
			Locations[k].username = ""
			Locations[k].date = ""
		end
		SaveTable(Locations,"locations")
		res:send("Locations reset, go back",200)
	end)

	server:post("/admin/createlocation", function(req, res)
		p(req.body)
		p(req.body.pos)
		req.body = json.parse((next(req.body)))
		if Locations[req.body.location] then
			res:send("already a location with this name, go back",400)
		end
		Locations[req.body.location]={checked=false, details=req.body.details, username="", date="", pos={latitude=tonumber(req.body.pos.latitude),longitude=tonumber(req.body.pos.longitude)}}
		SaveTable(Locations,"locations")
		res:send("created, go back",200)
	end)

	local function deletelocation(location)
		if not Locations[location] then
			return "no locations with this name, go back",400
		end
		Locations[location]=nil
		SaveTable(Locations,"locations")
		return "deleted, go back",200
	end

	server:get("/admin/locationdata", function(req, res)
		local t = {}
		for k,v in pairs(Locations) do
			t[#t+1] = {k}
		end
		res:json(t,200)
	end)

	server:post("/admin/deletelocation", function(req, res)
		res:send(deletelocation(req.body.location))
	end)

	server:post("/admin/bulkdeletelocations", function(req, res)
		for location in pairs(req.body) do
			deletelocation(location)
		end
		res:send("deleted",200)
	end)
end


return module