local OSS = jit.os=="Windows" and "\\" or "/"

return function(str,...)
	return str:gsub("/",OSS):format(...)
end