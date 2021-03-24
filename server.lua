--_G.EXECPATH = debug.getinfo(1).source:sub(2):gsub("\\","/"):match(".+/"):sub(1,-2)

require"ose/server"

local uv = require('uv')
local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield

-- timer.sleep is redefined here to avoid a memory leak in the luvit module
local function sleep(delay)
	local thread = running()
	local t = uv.new_timer()
	t:start(delay, 0, function()
		t:stop()
		t:close()
		return assert(resume(thread))
	end)
	return yield()
end

local helpers = require("depsMoonCake/mooncake/libs/helpers")
local tick = function() return helpers.getTime()/1000 end

local PORT_COUNT = 1
local START_PORT = 6969

local ip = "172.26.11.122"

local PASS_DATA = nil

_G.EXECPATH = _G.EXECPATH .."/"

local MoonCake = require"depsMoonCake/mooncake"

local returniptable = {}

function Setup(port)
	local server = MoonCake:new() 
	
	server:get("/ping", function(req, res)
		coroutine.wrap(function()
			--[[local TTL = tick() + 2
			while true do
				sleep(0.02)
				print(tick()-TTL)
				if PASS_DATA ~= nil or tick() > TTL then
					return
				end
			end]]
			--p(res)
			--p(req.socket.handshake and req.socket.handshake.address)
			--p(req.socket.handshake and req.socket.handshake.address)
			--p(req.socket.remoteAddress and req.socket.remoteAddress())
			--p(req.socket.getpeername and req.socket.getpeername())
			p(req.socket._handle:getpeername())
			--print(req.connection.remoteAddress)
			p(PASS_DATA)
			res:finish(PASS_DATA or "no gpus")
		end)()
	end)
	
	server:start(port,ip)
end

for i = 1,PORT_COUNT do
	Setup(START_PORT + i-1)
end

Setup(80)


do--Info from scraper
	local server = MoonCake:new() 
	
	server:get("/:test", function(req, res)
		--print(req.params.test)
		--PASS_DATA = req.params.test

		res:finish("done\n")

		--coroutine.wrap(function()
			--sleep(2)
			--PASS_DATA = nil
		--end)()
	end)
	
	server:start(351,ip)
end


--  http POST localhost:351 url
--  curl --data "URL_GOES_HERE" localhost:351
--  curl -d "TEST" -X POST localhost:351

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

-- cd deps/ose && git pull origin master && cd ../.. && sudo ./luvit server.lua

