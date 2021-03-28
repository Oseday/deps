local helpers = require("depsMoonCake/mooncake/libs/helpers")
local tick = function() return helpers.getTime()/1000 end
local MoonCake = require"depsMoonCake/mooncake" 

local staticfs = require"ose/staticfs"
local cors = require"ose/CORS"

local timer = require("timer")

local PRIVATE_IP = "172.26.11.122"
local TIME_OUT = 3
local PASS_DATA = nil

_G.EXECPATH = _G.EXECPATH .."/"


local returniptable = {}

function Setup(port)
	local server = MoonCake:new() 
	
	cors.setupServer(server)
	
	server:get("/",function(req, res) res:sendFile(_G.EXECPATH.."website/index.html") end)

	staticfs.addstatic(_G.EXECPATH.."website/","/")
	
	server:use(function(req, res, next)
		local t = staticfs.use(req, res)
		if t then next() end
	end)
	
	server:get("/ping", function(req, res)
		res:finish("pong")
	end)
	
	server:get("/getgpus", function(req, res)
		local client_name = req.socket._handle:getpeername().ip
		if not client_name then return res:finish() end 
		
		if not returniptable[client_name] then
			returniptable[client_name] = {
				lasttick = tick(),
				data = {},
			}
			return res:finish("new connection")
		else
			returniptable[client_name].lasttick = tick()
			
			local data = returniptable[client_name].data
			if not next(data) then
				return res:finish("no gpus")
			else
				returniptable[client_name].data = {}
				
				p(data)
				return res:json(data)
			end
		end
	end)
	
	server:start(port, PRIVATE_IP)
end

Setup(80)

coroutine.wrap(function()
	timer.setInterval(1000, function()
		local t = tick()
		for name, tab in pairs(returniptable) do
			if t - tab.lasttick > TIME_OUT then
				returniptable[name] = nil
			end 
		end 
	end)
end)()

local links = {
	"https://www.google.com/",
	"https://stackoverflow.com/"
}

local coro = require"coro-http"

coroutine.wrap(function()
	for _,url in pairs(links) do
		coroutine.wrap(function()
			while true do
				local res,body = coro.request("GET",url)
				if res.code <= 300 then
					
				else
					
				end
			end
		end)()
	end
	--coro.request(method, url, headers, body, timeout)
end)()



do--Info from scraper
	local server = MoonCake:new() 
	
	server:post("/", function(req, res)
		local client_name = req.socket._handle:getpeername().ip
		if client_name ~= PRIVATE_IP then return end
		local url
		
		p(req.body)
		if type(req.body) == "string" then
			url = req.body
		else
			local ect
			url,ect = next(req.body)
			if ect ~= "" then
				url = url .. "=" .. ect
			end
		end
		p(url)
		
		local t = tick()
		for name, tab in pairs(returniptable) do
			if t - tab.lasttick > TIME_OUT then
				returniptable[name] = nil
			else
				table.insert(tab.data, url)
			end 
		end 
		
		res:finish("done\n")
	end)
	
	server:start(351, PRIVATE_IP)
end

--  http POST localhost:351 url
--  curl --data "URL_GOES_HERE" localhost:351
--  curl -d "TEST" -X POST localhost:351

-- cd deps/ose && git pull origin master && cd ../.. && sudo ./luvit server.lua

return true