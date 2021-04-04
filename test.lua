--[[local ciphered = "8Z_\144\137\161\143\030\237\240\2368\241oB\197OI\246\137\240O\030\240\180\025&\175\208\199'+^\\aw((h$\0305\224\017.6\030\248\0205Vt\005\255\250\1392\\b')w\211lI\190"

local x = ciphered:gsub("\\(%d%d%d)", function(s) return string.char(s) end)

p(x)

local base64 = require"base64"

p(base64)]]

--print(x:sub(2,-4))



--do return end

local method = "aes-256-cbc"

local key = args[2]
local data = args[3]

if not key then
	return print"ERROR: NO KEY"
end
if not data then
	return print"ERROR: NO DATA"
end

local cipher = require('openssl').cipher.get(method)
local encrypted,notf = cipher:encrypt(data, key)

if not encrypted then
	print("ERROR:",notf)
	return
end

local based = require"base64".encode(encrypted)
print(based)

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