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

local PhotoDir = _G.EXECPATH .. OSS.."photo"..OSS

local Photos = {}

function addphoto(locname,animalname,dir)
	
end


function module.setupServer(server)
	server:post("/photos/:locname", function(req, res)
		local locname = req.params.locname
		if not req.files then res:send("no file sent",400) end
		if not req.files.photo then res:send("file sent was not a photo",400) end
		p(req.files.photo.name) --writes to the temp file at photo.path , we can just move the temp file to the new location
		p(req.files.photo.path)
		coroutine.wrap(function()
			local err,notf = fs.renameSync(req.files.photo.path, PhotoDir..locname..OSS..req.files.photo.name)
			p(err,notf)
			--if err then p(err,notf) res:send("",500) end
			p(PhotoDir..locname..OSS..req.files.photo.name)
			res:send("",200)
		end)()
	end)
end

return module