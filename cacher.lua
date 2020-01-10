local mc
if jit.os=="Windows"then
	mc = "mooncake"
else
	mc = "depsMoonCake/mooncake"
end


local dynamodb = require"./dynamodb-comm"
local json = require"json"
local quickio = require"./deps2/quickio"
local sleep = require"./sleep"
local helpers = require(mc.."/libs/helpers")--print(helpers.getTime())
local tick = function() return helpers.getTime()/1000 end

local function tableupdate(t1,t2)
	for i,v in pairs(t2) do
		if type(v)=="table" then
			if not t1[i] then
				t1[i]={}
			end
			tableupdate(t1[i],v)
		else
			t1[i]=v
		end
	end
end

local Cache = {}

local module = {}

local CacheTime = 60 --seconds

function module.get(game,key)
	if not Cache[game] then Cache[game]={} end
	local cg = Cache[game]
	if cg[key] then
		cg[key]._tick = tick()
		return cg[key]
	end
end

function module.put(game,key,data)
	if not Cache[game] then Cache[game]={} end
	Cache[game][key] = data
	Cache[game][key]._tick = tick()
end

function module.update(game,key,data)
	if not Cache[game] then Cache[game]={} end
	local cg = Cache[game]
	if cg[key] then
		tableupdate(cg[key],data)
		cg[key]._tick = tick()
		return true
	end
end

function module.step()
	local tik = tick()-CacheTime
	local ctik = tick()
	for game,c in pairs(Cache) do
		for k,t in pairs(c) do
			if t._tick and t._tick<tik then
				dynamodb.PutItem(game, c[k], function(dbres,body)
					--res.code gives status code
					if dbres and dbres.code==200 then
						c[k]=nil
					elseif dbres then 
						print("Error "..dbres.code..": "..dbres.reason)
					else
						print("Error ".."592"..": ".."No response")
					end
				end)
			end
			if tick()-ctik>0.1 then
				sleep(0.01)
			end
		end
	end
end

function module.Save()
	local s = json.encode(Cache)
	print("Cache save success;")
	print(quickio.write("./caches/tempsave.txt", s))
end

function module.Load()
	local s,y = quickio.read("./caches/tempsave.txt")
	if not s then print("ERROR:",y) return end

	local ft = json.decode(s)
	for n,t in pairs(ft) do
		--InstallLeaderboard(n,t)
		Cache[n]=t
	end
end

return module