local helpers = require("depsMoonCake/mooncake/libs/helpers")
local tick = function() return helpers.getTime()/1000 end
local MoonCake = require"depsMoonCake/mooncake" 

local timer = require("timer")

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
					for i,d in ipairs(data) do
						str = str .. string.format([["%s"]],d)
						if i ~= #data then
							str = str .. ","
						end
					end
					str = str.."]"
					p(str)
					return res:finish(str)
				end
			end
		end)()
	end)
	
	server:start(port, PRIVATE_IP)
end

Setup(80)

coroutine.wrap(function()
	timer.setInterval(1, function()
		print(tick())
		--io.popen(file,"r")
	end)
end)()

do--Info from scraper
	local server = MoonCake:new() 
	
	server:post("/", function(req, res)
		local client_name = req.socket._handle:getpeername().ip
		if client_name ~= PRIVATE_IP then return end
		
		local url = next(req.body)
		
		local t = tick()
		
		for name, tab in pairs(returniptable) do
			if t - tab.lasttick > 1 then
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