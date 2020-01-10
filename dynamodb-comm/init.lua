local http = require('coro-http')
local json = require"json"

--[[function convertToAttr(keypairs)
	local Atts={}

	for k,v in pairs(keypairs) do
		local tip = type(v)
		if tip=="string" then
			Atts[k]={S=v}
		elseif tip=="number" then
			Atts[k]={N=tostring(v)}
		elseif tip=="boolean" then
			Atts[k]={BOOL=v}
		elseif tip=="table" then
			Atts[k]={}
			if v[1] then
				local tip2=type(v[1])
				local difarray = false
				for i=2,#v do
					if type(v[i])~=tip2 then
						difarray=true
						break
					end
				end
				if difarray then
					Atts[k]={L={}}
					for i=1,#v do
						tip2=type(v[i])
						if tip2=="string" then
							Atts[k].L[i]={S=v[i]}
						elseif tip2=="number" then
							Atts[k].L[i]={N=tostring(v[i])}
						elseif tip2=="boolean" then
							Atts[k].L[i]={BOOL=v[i]}
						end
					end
				else
					if tip2=="string" then
						Atts[k]={SS=v}
					elseif tip2=="number" then
						Atts[k]={NS={}}
						for i=1,#v do
							Atts[k].NS[i]=tostring(v[i])
						end
					elseif tip2=="boolean" then
						assert(false,"Cannot do array-bool types",2)
					end
				end
			else--dictionary "M"
				Atts[k]={M={}}
				for k2,v2 in pairs(v) do
					if type(k2)~="string" then assert(false,"Cannot have non string type in dictionary format",2) end
					local tip2=type(v2)
					if tip2=="string" then
						Atts[k].M[k2]={S=v2}
					elseif tip2=="number" then
						Atts[k].M[k2]={N=tostring(v2)}
					elseif tip2=="boolean" then
						Atts[k].M[k2]={BOOL=v2}
					end
				end
			end
		end
	end

	return Atts
end]]

function convertToAttr(keypairs)
	local Atts={}

	for k,v in pairs(keypairs) do
		local tip = type(v)
		if tip=="string" then
			Atts[k]={S=v}
		elseif tip=="number" then
			Atts[k]={N=tostring(v)}
		elseif tip=="boolean" then
			Atts[k]={BOOL=v}
		elseif tip=="table" then
			if v[1] then
				Atts[k]={L=convertToAttr(v)}
			else
				Atts[k]={M=convertToAttr(v)}
			end
		end
	end

	return Atts
end

function convertToLuaTable(keypairs)
	local Atts={}

	for k,v in pairs(keypairs) do
		if v.S then
			Atts[k]=v.S
		elseif v.N then
			Atts[k]=tonumber(v.N)
		elseif v.BOOL~=nil then
			Atts[k]=v.BOOL
		elseif v.M then
			Atts[k]=convertToLuaTable(v.M)
		elseif v.L then
			Atts[k]=convertToLuaTable(v.L)
		elseif type(v)=="table" then
			Atts[k]=convertToLuaTable(v)
		else
			Atts[k]=v
		end
	end

	return Atts
end

function dorequrl(req,callback,url) 
	--print("doreq")
	coroutine.wrap(function()
		--print("doing req")
		local res,body = http.request(
		"POST",
		url,
		nil,
		req
		)
		--print("did req")
		if callback then
			callback(res,body)
		end
	end)()
end

function putItem(tablename,keypairs,callback) 
	local Atts = convertToAttr(keypairs)
	local req ={Attributes=Atts}
	req = json.encode(req)
	dorequrl(req,callback,"http://localhost:8081/put/"..tablename)
end

function getItem(tablename,keypairs,callback)
	local Atts = convertToAttr(keypairs)
	local req ={Attributes=Atts}
	req = json.encode(req)

	dorequrl(req,callback,"http://localhost:8081/get/"..tablename)
end

function batchGetItem(tablename,keypairs,callback)
	local Atts = convertToAttr(keypairs)
	local req ={Attributes=Atts}
	req = json.encode(req)

	dorequrl(req,callback,"http://localhost:8081/batchget/"..tablename)
end

return {GetItem=getItem,PutItem=putItem,convertToAttr=convertToAttr,convertToLuaTable=convertToLuaTable}