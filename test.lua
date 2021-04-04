local ciphered = "'r\\160\\236\\030}u\\215Bg\\2290\\235~\\025\\155\\229'\\n'"

local x = ciphered:gsub("\\(%d%d%d)", function(s) return string.char(s) end)

print(x)

print(x:sub(2,-4))



do return end

local method = "aes256"

local key = args[2]
local data = args[3]

if not key then
	return print"ERROR: NO KEY"
end
if not data then
	return print"ERROR: NO DATA"
end

local openssl = require('openssl')

local cipher = require('openssl').cipher.get("aes-256-cbc")
local encrypted,notf = cipher:encrypt(data, key)


if not encrypted then
	print("ERROR:",notf)
	return
end


p(encrypted)

return
--[[
local openssl = require('openssl')

local encryptionKey = "keyyyyyyyyyyyyyy"

local cipher = openssl.cipher.get("aes-256-cbc")
local data = "Hello World!"

local encrypted,a,b,c = cipher:encrypt(data, encryptionKey)
p(encrypted,a,b,c)
p(cipher)
local decrypted = cipher:decrypt(encrypted, encryptionKey)

print(data)
p(encrypted)
print(decrypted)

local s = ""
for i = 1,10000 do
	local suc = pcall(function()
		local cipher = openssl.cipher.get(i)
	end)
	if suc then s = s .. " " .. i end
end
p(s)

p(openssl.cipher.list())
]]



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

--[[
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
]]