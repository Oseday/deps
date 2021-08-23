--Leaderboard 

local json = require"json"
local quickio = require"./deps2/quickio"

local mc --= require"depsMoonCake/mooncake"
if jit.os=="Windows"then
	mc = "mooncake"
else
	mc = "depsMoonCake/mooncake"
end

local helpers = require(mc.."/libs/helpers")--print(helpers.getTime())
local tick = function() return helpers.getTime()/1000 end

local defaultFieldCount = 10

local Leaderboards = {
	Game1Points={
		Fields={"UserId","Points"};
		List={
			{546768,100}
		};
		LastSortV=100;
		LastPoint=1;
		FieldCount=5;
	};
}

function Reset(tn)
	local l = Leaderboards[tn]
	l.List={}
	l.LastSortV=math.huge
	l.LastPoint=0
end

function Delete(tn)
	Leaderboards[tn]=nil
end

function CreateLeaderboard(t)
	if Leaderboards[t.Name] then return false,"already exists" end
	Leaderboards[t.Name]={
		Fields={t.FieldName,t.SortName},
		List={},
		LastSortV=math.huge;
		LastPoint=0;
		FieldCount=t.FieldCount and t.FieldCount or defaultFieldCount;
	}
end

function SaveLeaderboards()
	local s = json.encode(Leaderboards)
	print(quickio.write("./leaderboards/tempsave.txt", s))
end

function LoadLeaderboards()
	local s,y = quickio.read("./leaderboards/tempsave.txt")
	if not s then print("ERROR:",y) return end

	local ft = json.decode(s)
	for n,t in pairs(ft) do
		InstallLeaderboard(n,t)
	end
end

function InstallLeaderboard(n,t) -- t.Name , t.Table
	if Leaderboards[n] then
		for _,v in pairs(t.List) do
			UpdateLeaderboard(n,v[1],v[2])
		end
	else
		Leaderboards[n] = t
	end
end

function Get(LName)
	return Leaderboards[LName]
end

function UpdateLeaderboard(LName,FieldValue,SortValue)
	if not Leaderboards[LName] then
		CreateLeaderboard{Name=LName,FieldName="unkw",SortName="unkw"}
	end

	local l = Leaderboards[LName]

	if l.LastSortV > SortValue then
		return
	end

	local t = {FieldValue,SortValue}
	local add = false
	local exist = false
	for i,g in pairs(l.List) do
		if g[2]<=SortValue then
			add = i
			break
		end
		if g[1]==FieldValue then
			exist = i
		end
	end

	if not add then
		return
	end

	if not exist then
		for i = add, l.LastPoint do
			if l.List[i][1]==FieldValue then
				exist = i
				break
			end
		end
	end

	if exist then
		table.remove(l.List,exist)
		table.insert(l.List,add,t)
		l.LastSortV = l.List[l.LastPoint][2]
	else
		if l.LastPoint == l.FieldCount then
			l.List[l.LastPoint]=nil
		else
			l.LastPoint = l.LastPoint + 1
		end
		table.insert(l.List,add,t)
	end

end

--[[
UpdateLeaderboard("Game1Points",1,200)
UpdateLeaderboard("Game1Points",2,204)
UpdateLeaderboard("Game1Points",3,209)
UpdateLeaderboard("Game1Points",4,310)
UpdateLeaderboard("Game1Points",5,567)
UpdateLeaderboard("Game1Points",6,124)
UpdateLeaderboard("Game1Points",7,458)
UpdateLeaderboard("Game1Points",8,789)
UpdateLeaderboard("Game1Points",9,121)
UpdateLeaderboard("Game1Points",10,456)
UpdateLeaderboard("Game1Points",11,784)
UpdateLeaderboard("Game1Points",12,123)
UpdateLeaderboard("Game1Points",13,3)
UpdateLeaderboard("Game1Points",14,35)
]]

--[[
local s = tick()
for i = 1,10000 do
	--UpdateLeaderboard("Game1Points",i,i)
end
print(tick()-s)

table.foreach(Leaderboards["Game1Points"].List,function(i,v)
	print(i,v[1],v[2])
end)

--SaveLeaderboards()
LoadLeaderboards()

table.foreach(Leaderboards["Game1Points"].List,function(i,v)
	print(i,v[1],v[2])
end)
]]

function Prints(Table)
	table.foreach(Leaderboards[Table].List,function(i,v)
		print(i,v[1],v[2])
	end)
end

return{
	Save=SaveLeaderboards,
	Load=LoadLeaderboards,
	Update=UpdateLeaderboard,
	Create=CreateLeaderboard,
	Prints=Prints,
	Reset=Reset,
	Delete=Delete,
	Get=Get,
}
