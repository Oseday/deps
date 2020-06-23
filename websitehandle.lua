local module = {}
local EXECPATH_local = debug.getinfo(1).source:sub(2):gsub("\\","/"):match(".+/"):sub(1,-2)

local stream = require"stream"

local StaticFS = require"ose/staticfs"
local Sleep = require"ose/sleep"
local timer = require"timer"

print("EXECPATH:",_G.EXECPATH)

function module.setupServer(Server,MoonCake)
	local MeridianDir = _G.EXECPATH .. "Websites/nevs/Meridian"
	local AnalyticsDir = _G.EXECPATH .. "Websites/Analytics"


	local updateMeridian = [==[ cd ]==] .. _G.EXECPATH .. "Websites/nevs/Meridian" .. [==[ && git fetch origin && git reset --hard origin/master ]==]
	local updateAnalytics = [==[ cd ]==] .. _G.EXECPATH .. "Websites/Analytics" .. [==[ && git fetch origin && git reset --hard origin/master ]==]

	Server:get("/streamtest", function(req, res)
		coroutine.wrap(function()
			res:flushHeaders()
			res:write("<p>")
			for i = 1,100 do
				res:write("oook ")
				timer.sleep(100)
			end
			res:write("</p>")
			res:finish("<p>done</p>")
		end)()
	end)

	Server:get("/ping", function(req, res)
		res:finish("<p>pong</p>")
	end)

	Server:get("/updatewebsites",function(req, res)
		coroutine.wrap(function()
			res:write("<p>Updating Analytics...\n</p>")
			os.execute(updateAnalytics)
			res:write("<p>Updating Meridian...\n</p>")
			os.execute(updateMeridian)
			StaticFS.clear()
			res:finish("<p>Updated</p>",200)
		end)()
	end)



	--Server:get("/",function(req, res) res:sendFile(MeridianDir.."/home.html") end)
	Server:get("/",function(req, res) res:sendFile(AnalyticsDir.."/build/index.html") end)

	--StaticFS.addstatic(_G.EXECPATH.."Websites/nevs/Meridian/","/")
	StaticFS.addstatic(_G.EXECPATH.."Websites/Analytics/build/","/")

	--StaticFS.addstatic(_G.EXECPATH.."ssl-certs/","/.well-known/acme-challenge")
	--StaticFS.addstatic(_G.EXECPATH.."zerossl/","/.well-known/acme-challenge")


	Server:use(function(req, res, next)--
		local t = StaticFS.use(req, res)
		if t then next() end
	end)
	
	MoonCake.notFound = function(req, res, err)
	    if(err) then
	        MoonCake.serverError(req, res, err)
	    else
	        --p("404 - Not Found!")
	        --res:status(404):render("./libs/template/404.html")
	        res:sendFile(AnalyticsDir.."/build/index.html")
	    end
	end


end

return module



--[[

le.pl --key account.key --csr mydomain.csr --csr-key mydomain.key --crt mydomain.crt --domains "server.roblox.observer" --path /home/bitnami/zerossl/ --generate-missing --unlink

]]
