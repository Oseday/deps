local http = require"coro-http"
local json = require"json"
local OSS = jit.os=="Windows" and "\\" or "/"

local audCheck = {
	["680656297638-r9vbgsbimrqueto0r5e9v5ulvmjo0fg1.apps.googleusercontent.com"]=true,
	["680656297638-r9vbgsbimrqueto0r5e9v5ulvmjo0fg1.apps.googleusercontent.com"]=true,
}

function TableToString(t)
	local s = "{"
	for k,v in pairs(t) do
		if type(k)=="number" then
			local ts = type(v)=="table" and TableToString(v) or v
			if ts==true then ts="true" elseif ts==false then ts="false" end
			s=s.."["..k.."]="..ts..","
		else
			local ts = type(v)=="table" and TableToString(v) or v
			if ts==true then ts="true" elseif ts==false then ts="false" end
			s=s.."['"..k.."']="..ts..","
		end
	end
	return s.."}"
end

function TableToLoadstringFormat(t)
	return "return "..TableToString(t)
end

module = {}

local Users = {}

local Tokens = {}

local UsersFileAppend = io.open("."..OSS.."users"..OSS.."users", "a")

do --get latest users at start
	local UsersFileRead = io.open("."..OSS.."users"..OSS.."users", "r")
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


function createUser(user)
	local tab = {}
	Users[user.sub] = tab
	local str = ("sub=[%s];table=%s;\n"):format(user.sub, TableToString(tab))
	UsersFileAppend:write(str)
	UsersFileAppend:flush()
end

function validateToken(token) --https://oauth2.googleapis.com/tokeninfo?id_token=XYZ123
	local uri = "https://oauth2.googleapis.com/tokeninfo?id_token="..token
	local suc, res, body = pcall(http.request,"GET",uri)
	if not suc or not res then return false,body or res,500 end

	print("TOKEN:")
	print(body)

	body = json.decode(body)


	if body.error and body.error_description then return false,body.error_description,res.code or 500 end

	if res.code and res.code>=400 then return false,"Check error code",res.code end

	if not audCheck[body.aud] then return false,"Invalid aud",400 end
	return true,body,200
end

function module.login(token)
	local user do
		local s,n,e = validateToken(token)
		if not s then return s,n,e else user=n end
	end
	local sub = user.sub
	if not sub then return false,"Invalid sub",500 end
	Tokens[token]=user.sub
	if Users[sub] then
		Users[sub].token = token
	else
		createUser(user)
		Users[sub].token = token
	end
	return true,"Success",200
end

function module.tokenLoggedin(token)
	local sub = Tokens[token]
	if sub then
		if Users[sub].token == token then
			return sub,"Valid",200
		else
			local user do
				local s,n,e = validateToken(token)
				if not s then return s,n,e else user=n end
			end
			if not user.sub then return false,"Invalid sub",500 end
			if sub ~= user.sub then return false,"Token sub mismatch",500 end
			Tokens[Users[sub].token] = nil
			Users[sub].token = token
			return sub,"Valid new token",200
		end
	else
		return false,"Invalid token",401
	end
end


function module.setupServer(server)
	if server then--for debugging

		server:post("/analytics/auth/login", function(req, res)
			coroutine.wrap(function()
				local token = req.body.token
				if token then
					local s,n,e = module.login(token)
					res:send(n,e)
				else
					res:send("No token",400)
				end
			end)()
		end)
		
		
	end
end

return module