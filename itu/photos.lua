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
local rndid = require"ose/rndid"

local OSS = jit.os=="Windows" and "\\" or "/"

local function OSSd(...)
	local s = ""
	for _,v in pairs(...) do
		s = s .. v
	end
	return s
end

--[[function direxists(dir) 
	return os.execute("[ -d itu"..OSS..dir.." ]")==true
end

function makedir(dir)
	return os.execute("mkdir itu"..OSS..dir)
end

function removedir(dir)
	return os.execute("rm -rf itu"..OSS..dir)
end]]

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

function SaveTable(tab,path)
	local f,w = quickio.write(pafix("itu/"..path), TableToLoadstringFormat(tab))
	if not f then print("ERROR: Couldn't save "..path..":", w) end
end

function LoadTable(tab,path)
	local f,w = quickio.read(pafix("itu/"..path))
	if f then
		for k in pairs(tab) do
			tab[k]=nil
		end
		local temp = loadstring(f)()
		for k,v in pairs(temp) do
			tab[k]=v
		end
	else
		print("Error opening itu/"..path..":", w)
		SaveTable(tab,path)
	end
end

local ITUDir = _G.EXECPATH .. OSS.."deps/ose/itu/websites"
local PhotoDir = _G.EXECPATH ..OSS.. "itu" ..OSS.. "photos" ..OSS

local Photos = {
	test={
		testanimal={"Kgo0bOfbHO.png","JH0SWGSwsd.png"}
	}
}

LoadTable(Photos,"photosmeta")

function addphoto(locname,animalname,photoname,tempdir)
	local loc = PhotoDir..locname
	fs.mkdir(loc)
	local aniloc = loc..OSS..animalname
	fs.mkdir(aniloc)

	if not Photos[locname] then Photos[locname]={} end
	if not Photos[locname][animalname] then Photos[locname][animalname]={} end
	
	table.insert(Photos[locname][animalname], photoname)

	SaveTable(Photos,"photosmeta")

	local err,notf = fs.renameSync(tempdir, aniloc..OSS..photoname)
	if err == nil then return false,notf,500 end
	return true,"success",200
end

function deletephoto(locname,animalname,photoname)
	if not Photos[locname] or not Photos[locname][animalname] then return false,"no such loc-animal exists",403 end

	local t,b = Photos[locname][animalname]
	for i,v in pairs(t) do
		if v==photoname then Photos[locname][animalname][i]=nil b=v break end
	end
	if not b then return false,"no such photo exists",403 end

	fs.unlink(PhotoDir..locname..OSS.animalname..OSS..photoname,function()end)

	SaveTable(Photos,"photosmeta")
end


function module.setupServer(server)
	server:get("/photos/:locname", function(req, res)
		local locname = req.params.locname
		res:sendFile(ITUDir .. "/photosviewer.html")
	end)

	server:post("/photos/:locname", function(req, res)
		local locname = req.params.locname
		if not req.files then res:send("no file sent",400) end
		if not req.files.photo then res:send("file sent was not a photo",400) end
		coroutine.wrap(function()
			local succ,notf,code = addphoto(locname, "testanimal", req.files.photo.name, req.files.photo.path)
			if not succ then
				p("ERROR:",notf)
				return res:send(notf,code)
			end

			res:send("",200)
		end)()
	end)

	server:delete("/photos/:locname/:animalname/:photoname", function(req, res)
		local locname = req.params.locname
		local animalname = req.params.animalname
		local photoname = req.params.photoname

		local succ,notf,code = deletephoto(locname,animalname,photoname)
		if not succ then
			p("ERROR:",notf)
			return res:send(notf,code)
		end
		
		res:send("",200)
	end)

	server:post("/photosmeta/:locname", function(req, res)
		local locname = req.params.locname
		if Photos[locname] then
			res:json(Photos[locname],200)
		else
			res:json({},200)
		end
	end)
end

return module