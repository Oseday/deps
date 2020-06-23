--_G.EXECPATH = debug.getinfo(1).source:sub(2):gsub("\\","/"):match(".+/"):sub(1,-2)

require"ose/server"


local CORS = require"ose/CORS"

local Tracker = require"ose/itu/tracker"
local WebsiteHandle = require"ose/itu/websitehandle"

local isHttps = false

local mc,ip,port,porthttps
if jit.os=="Windows" then
	mc = "mooncake"--"./ndeps/deps/depsMoonCake/mooncake"
	ip = "127.0.0.1"
	port = 80
	isHttps = false
else
	mc = "depsMoonCake/mooncake"
	ip = "172.26.10.180"
	porthttps = 443
	port = 80
	_G.EXECPATH = _G.EXECPATH .."/"
end

local MoonCake = require(mc)

function Setup(Server,port)
	CORS.setupServer(Server)
	--Analytics.setupServer(Server)
	--Authentication.setupServer(Server)
	WebsiteHandle.setupServer(Server,MoonCake)

	Tracker.setupServer(Server)

	Server:start(port,ip)
end

if isHttps then
	local ServerHttps = MoonCake:new{
	    isHttps = true, keyPath = _G.EXECPATH.."zerossl-local/keys"
	}

	Setup(ServerHttps,porthttps,ip)
end

Setup(MoonCake:new(),port,ip)

--[[

local CORS = require"ose/CORS"
local Authentication = require"ose/authent"
local Analytics = require"ose/analytics"
local WebsiteHandle = require"ose/websitehandle"

local isHttps = true

local mc,ip,port,porthhtps
if jit.os=="Windows" then
	mc = "mooncake"--"./ndeps/deps/depsMoonCake/mooncake"
	ip = "127.0.0.1"
	port = 80
	isHttps = false
else
	mc = "depsMoonCake/mooncake"
	ip = "172.26.10.180"
	porthhtps = 443
	port = 80
	_G.EXECPATH = _G.EXECPATH .."/"
end

local MoonCake = require(mc)


if isHttps then
	local ServerHttps = MoonCake:new{
	    isHttps = true, keyPath = _G.EXECPATH.."zerossl-local/keys"
	}

	CORS.setupServer(ServerHttps)
	Analytics.setupServer(ServerHttps)
	Authentication.setupServer(ServerHttps)
	WebsiteHandle.setupServer(ServerHttps,MoonCake)

	ServerHttps:start(porthhtps,ip)
end

local Server = MoonCake:new()

CORS.setupServer(Server)
Analytics.setupServer(Server)
Authentication.setupServer(Server)
WebsiteHandle.setupServer(Server,MoonCake)

Server:start(port,ip)

Analytics.setupTimer()


]]

-- git clone https://Oseday:3MicikP7fTvbkDS@github.com/Oseday/Analytics
-- C:\Users\canca\Desktop\Roblox\Vurse\combined-server\Websites\Analytics
-- rm -rf Analytics && git clone https://Oseday:3MicikP7fTvbkDS@github.com/Oseday/Analytics

-- cd /home/ec2-user/Websites/Analytics && git fetch origin && git reset --hard origin/master

-- git clone https://Oseday:3MicikP7fTvbkDS@github.com/Oseday/ose

-- git clone https://Oseday:3MicikP7fTvbkDS@github.com/Oseday/C-builds

-- cd deps/ose && git pull origin master && cd ../..

