local module = {}

local fs = require"fs"

local filedirs = {} --{filepath=filepath,route=route}
local files = {} --"nurl"="filepath"
local nofiles = {} --"nurl"=true

function fexist(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function file_exists(nurl)
	if nofiles[nurl] then return end
	local fp = files[nurl]
	if fp then return fp end
	for _,t in pairs(filedirs) do
		local urlfp = nurl:sub(1,t.route.l)
		if nurl:sub(-4)==".git" then return end
		p(nurl)
		p(urlfp)
		if urlfp==t.route.r then
			local np = t.filepath..nurl:sub(t.route.l+1,-1)
			p(np)
			if fexist(np) then
				files[nurl] = np
				return np
			end
		end
	end
	nofiles[nurl] = true
end

function module.addstatic(filepath,route)
	table.insert(filedirs,{filepath=filepath,route={r=route,l=string.len(route)}})
end

function module.clear()
	files = {}
	nofiles = {}
end

function module.use(req,res)
	local next = false
	local nurl = req.url
	x = string.find(nurl,"%.html$")
	if x then
		res:redirect(string.sub(nurl,1,x-1))
	elseif not string.match(nurl,"%.") then
		nurl = nurl .. ".html"
	end
	local nfile = file_exists(nurl)
	if nfile then
		res:sendFile(nfile)
	else
		print"go to next()"
	   	next = true
	end
	return next
end

return module