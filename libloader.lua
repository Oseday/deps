local module = {}

local libdir = jit.os=="Windows" and [[C:\Users\canca\Desktop\C++ Projects\C-builds\]] or [[/home/bitnami/deps/ose/lib/C-builds/]]

local ffi = require"ffi"

function module.load(name)
	return ffi.load(libdir..name..(jit.os=="Windows"and""or".so"))
end

return module