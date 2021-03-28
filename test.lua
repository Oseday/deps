--local uv = require"uv"
--[[local thread = require"thread"

local links = {
	"https://www.google.com/",
	--"https://stackoverflow.com/"
}

function trylink(url)
	local suffix = jit.os=="Windows" and "deps\\" or "/home/centos/lua-server/deps/"
	local corohttp = require(suffix.."coro-http")
	print(url)
	coroutine.wrap(function()
		local res = corohttp.request("GET", url)
		p(res)
	end)()
end

local threads = {}

for i,url in pairs(links) do
	--trylink(url)
	threads[i] = thread.start(trylink, url)
end

for _,thr in ipairs(threads) do
	thread.join(thr)
end

return nil]]


local coro = require("coro-http")

local url = "https://www.amazon.com/NVIDIA-RTX-3090-Founders-Graphics/dp/B08HR6ZBYJ/ref=sr_1_7?crid=2FQMGDZXBZ7VB&dchild=1&keywords=rtx+3060+founders+edition&qid=1616860393&sprefix=rtx+3060+founde%2Caps%2C317&sr=8-7" --rtx 3060 fe

coroutine.wrap(function()
	local res,body = coro.request("GET",url)

	
	if string.find(body, "Sold Out") then
		p"cant get this"	
	else
		p"GET THIS BRO"
	end

end)()
