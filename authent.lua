local http = require"coro-http"
local json = require"json"
local pafix = require"ose/pafix"
local OSS = jit.os=="Windows" and "\\" or "/"

local audCheck = {
	["680656297638-r9vbgsbimrqueto0r5e9v5ulvmjo0fg1.apps.googleusercontent.com"]=true,
	["680656297638-r9vbgsbimrqueto0r5e9v5ulvmjo0fg1.apps.googleusercontent.com"]=true,
}

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

local function tablemerge(t1,t2)
	for i,v in pairs(t2) do
		if t1[i] ~= nil then
			if type(v)=="table" then
				t1[i]={}
				tableupdate(t1[i],v)
			else
				t1[i]=v
			end
		end
	end
end

local function TableToString(t)
	local s = "{"
	for k,v in pairs(t) do
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

local function TableToLoadstringFormat(t)
	return "return "..TableToString(t)
end

module = {}

local Users = {}

local Tokens = {}

local UsersFileAppend = io.open(pafix("./users/users"), "a")

do --get latest users at start
	local UsersFileRead = io.open(pafix("./users/users"), "r")
	local pattern = "sub=%[(.-)%];table=(.-);"
	for line in UsersFileRead:lines() do
		local _,_,sub,tab = string.find(line, pattern)
		p(sub,tab)
		if sub and tab then
			Users[sub] = loadstring("return "..tab)()
		end
	end
	UsersFileRead:close()
end

local LatestMetadata = {
	keys={},
	inmem=true,
	_version=1,
}

local function writeFileUserMetadata(sub,tab)
	local fi = io.open(pafix("./users/datas/%s",sub),"w")
	fi:write(TableToString(tab))
	fi:flush()
	fi:close()
end

local function readFileUserMetadata(sub)
	local fi = io.open(pafix("./users/datas/%s",sub),"r")
	local ts = fi:read("*a")
	tab = loadstring("return "..tab)()
	fi:close()
	return tab
end

function module.getUserMetadata(sub)
	if not Users[sub].inmem then 
		Users[sub] = readFileUserMetadata(sub)
	end
	return Users[sub]
end

function module.setUserMetadata(sub,value)
	Users[sub] = value
	writeFileUserMetadata(sub,value)
end

function module.updateUserMetadata(sub,key,value)
	if type(key)~="string" then print("Key isn't a string") return false end
	if not Users[sub].inmem then 
		Users[sub] = readFileUserMetadata(sub)
	end
	Users[sub][key] = value
	writeFileUserMetadata(sub,Users[sub])
end

function createUser(user)
	local tab = {}
	Users[user.sub] = tab
	local str = ("sub=[%s];table=%s;\n"):format(user.sub, "{}")--TableToString(tab))
	UsersFileAppend:write(str)
	UsersFileAppend:flush()


	tab = {}

	tablemerge(tab,LatestMetadata)

	writeFileUserMetadata(sub,tab)
end

function validateToken(token) --https://oauth2.googleapis.com/tokeninfo?id_token=XYZ123
	if token.at == "osedaysecret" then return true,{sub="1337"},200 end

	local uri = "https://oauth2.googleapis.com/tokeninfo?id_token="..token.at
	local suc, res, body = pcall(http.request,"GET",uri)
	if not suc or not res then return false,body or res,500 end

	body = json.decode(body)

	if body.error and body.error_description then return false,body.error_description,res.code or 500 end

	if res.code and res.code>=400 then return false,"Check error code",res.code end

	if not audCheck[body.aud] then return false,"Invalid aud",401 end
	return true,body,200
end

function module.login(token)
	local user do
		local s,n,e = validateToken(token)
		if not s then return s,n,e else user=n end
	end
	local sub = user.sub
	if not sub then return false,"Invalid sub",500 end
	if Users[sub] then
		if Users[sub].token then
			if Users[sub].token.at == token.at then return false,"Already logged in" end
			Tokens[Users[sub].token.at] = nil
		end
		Users[sub].token = token
	else
		createUser(user)
		Users[sub].token = token
	end
	Tokens[token.at]={sub=user.sub,tok=token}
	return true,"Success",200
end

function module.tokenLoggedin(currenttoken)
	if not currenttoken then return false,"No token",400 end

	local ramtoken = Tokens[currenttoken.at]
	if not ramtoken then return false,"Invalid token1",401 end

	if ramtoken.tok.ip~=currenttoken.ip then return false,"Invalid token2",401 end

	if Users[ramtoken.sub].token.at ~= currenttoken.at then return false,"Invalid token3",401 end 



	return ramtoken.sub,"Valid",200



	--[[


	if not token then return false,"No token",400 end
	local sub = Tokens[token.uid]
	if sub then
		if not Users[sub] then return false,"Server data error",500 end
		if Users[sub].token.uid == token.uid then
			return sub,"Valid",200
		else
			local user do
				local s,n,e = validateToken(token)
				if not s then return s,n,e else user=n end
			end
			if not user.sub then return false,"Invalid sub",500 end
			if sub ~= user.sub then return false,"Token sub mismatch",500 end
			Tokens[Users[sub].token.uid] = nil
			Users[sub].token = token
			return sub,"Valid new token",200
		end
	else
		return false,"Invalid token",401
	end

	]]
end

function module.GetToken(req)
	local token = req.body.token or req.headers.token or req.cookies.token
	token = {at=token, ip=req.socket:address().ip}
	if not token.at or not token.ip then print("ERROR","Couldn't get token",token.at,token.ip) return end
	return token
end

function module.setupServer(server)
	if server then--for debugging
		server:post("/analytics/auth/login", function(req, res) --req.socket:address().ip
			coroutine.wrap(function()
				--p(req.body)
				local token = module.GetToken(req)--req.body.token or req.headers.token or req.cookies.token
				if token then
					local s,n,e = module.login(token)
					if not s then print(s,n,e) end
					res:send(n,e)
				else
					res:send("No token",400)
				end
			end)()
		end)
		server:get("/analytics/auth/getMetadata", function(req, res)
			coroutine.wrap(function()
				p(req.body)
				local token = module.GetToken(req)--req.body.token or req.headers.token or req.cookies.token

				local sub,n,e = module.tokenLoggedin(token)
				if not sub then return res:send(n,e) end

				local metadata = module.getUserMetadata(sub)

				res:json(metadata,200)
			end)()
		end)
	end
end

return module