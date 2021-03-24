local helpers = require("depsMoonCake/mooncake/libs/helpers")
local tick = function() return helpers.getTime()/1000 end
local MoonCake = require"depsMoonCake/mooncake" 

local PRIVATE_IP = "172.26.11.122"

local PASS_DATA = nil

_G.EXECPATH = _G.EXECPATH .."/"


local returniptable = {}

function Setup(port)
	local server = MoonCake:new() 
	
	server:get("/ping", function(req, res)
		res:finish("pong")
	end)
	
	server:get("/getgpus", function(req, res)
		coroutine.wrap(function()
			local client_name = req.socket._handle:getpeername().ip
			if not client_name then return res:finish() end 

			if not returniptable[client_name] then
				returniptable[client_name] = {
					lasttick = tick(),
					data = {"www.google.com","www.facebook.com"},
				}
				return res:finish("no gpus")
			else
				returniptable[client_name].lasttick = tick()

				local data = returniptable[client_name].data
				if not next(data) then
					return res:finish("no gpus")
				else
					returniptable[client_name].data = {}
					local str = "["
					for _,d in ipairs(data) do
						str = str .. string.format([["%s",]],d)
					end
					str = str:sub(0,-1).."]"
					p(str)
					return res:finish(str)
				end
			end
		end)()
	end)
	
	server:start(port, PRIVATE_IP)
end

Setup(80)

do--Info from scraper
	local server = MoonCake:new() 
	
	server:get("/:url", function(req, res)
		local client_name = req.socket._handle:getpeername().ip
		if client_name ~= PRIVATE_IP then return end

		local url = req.params.url

		for name, tab in pairs(returniptable) do
			table.insert(tab.data, url)
		end

		res:finish("done\n")
	end)

	server:post("/", function(req, res)
		local client_name = req.socket._handle:getpeername().ip
		if client_name ~= PRIVATE_IP then return end

		local url = req.body

		for name, tab in pairs(returniptable) do
			table.insert(tab.data, url)
		end

		res:finish("done\n")
	end)
	
	server:start(351, PRIVATE_IP)
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

