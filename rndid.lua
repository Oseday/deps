local str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
return function(tables)
	local t
	local len = str:len()
	repeat
		t=""
		for i = 1,20 do
			local n = math.random(1,len)
			t=t..str:sub(n,n)
		end
	until not tables[t]
	return t
end