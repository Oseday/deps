local module = {}
local EXECPATH = debug.getinfo(1).source:sub(2):gsub("\\","/"):match(".+/"):sub(1,-2)

local StaticFS = require"ose/staticfs"

function module.setupServer(Server)
	local updateMeridian = [==[ cd ]==] .. EXECPATH .. "Websites/nevs/Meridian" .. [==[ && git fetch origin && git reset --hard origin/master ]==]
	local updateAnalytics = [==[ cd ]==] .. EXECPATH .. "Websites/Analytics" .. [==[ && git fetch origin && git reset --hard origin/master ]==]

	Server:get("/updatewebsites",function(req, res)
		res:send("Updating Analytics...\n",203)
		os.execute(updateAnalytics)
		res:send("Updating Meridian...\n",203)
		os.execute(updateMeridian)
		res:send("Updated",200)
	end)

	Server:get("/",function(req, res) res:sendFile"./Websites/nevs/Meridian/home.html" end)

	StaticFS.addstatic(EXECPATH.."Websites/nevs/Meridian/","/")
	StaticFS.addstatic(EXECPATH.."Websites/Analytics/","/analytics")

	Server:use(function(req, res, next)
		local t = StaticFS.use(req, res)
		if t then next() end
	end)
end

return module
