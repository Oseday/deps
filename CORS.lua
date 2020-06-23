local data = {
	["/analytics/auth/login"]={
		["Access-Control-Allow-Origin"]="*",
		["Access-Control-Allow-Methods"]="POST",
		["Access-Control-Allow-Headers"]="*",
	},
}

local module = {}

local defHeaders = {
	["Access-Control-Allow-Origin"]="*",
	["Access-Control-Allow-Headers"]="*",
}

function module.setupServer(server)
	if not server then return end
	server:use(function(req,res,next)
		local headers = data[req.url]
		if headers then
			for k,v in pairs(headers) do
				res:setHeader(k,v)
			end
		else
			for k,v in pairs(defHeaders) do
				res:setHeader(k,v)
			end
		end

		if req.method == "OPTIONS" then
			res:send("",200)
		else
			next()
		end
	end)
end


return module