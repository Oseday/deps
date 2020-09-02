local vips = require"vips"
local fs = require"fs"

local OSS = jit.os=="Windows" and "\\" or "/"


function scanrecursive(pathfrom,pathto,f)
	for file,types in fs.scandirSync(pathfrom) do
		if types=="directory" then
			scanrecursive(pathfrom..OSS..file, pathto..OSS..file,f)
		else
			p(pcall(f,pathfrom..OSS..file, pathto..OSS..file))
		end
	end
end	



scanrecursive(
	"/home/centos/itu/photos",
	"/home/centos/itu/minphotos",
	function(from,to)
		print(from,to)
		vips.Image.thumbnail(from, 300):write_to_file(to)
	end
)

print"done"

--cd deps/ose && git pull origin master && cd ../.. && sudo ./luvit /home/centos/deps/ose/itu/tests.lua


--[[
-- fast thumbnail generator
local image = vips.Image.thumbnail("somefile.jpg", 128)
image:write_to_file("tiny.jpg")

-- make a new image with some text rendered on it
image = vips.Image.text("Hello <i>World!</i>", {dpi = 300})

-- call a method
image = image:invert()

-- use the `..` operator to join images bandwise
image = image .. image .. image

-- add a constant
image = image + 12
-- add a different value to each band
image = image + { 1, 2, 3 }
-- add two images
image = image + image

-- split bands up again
b1, b2, b3 = image:bandsplit()

-- read a pixel from coordinate (10, 20)
r, g, b = image(10, 20)

-- make all pixels less than 128 bright blue
--    :less(128) makes an 8-bit image where each band is 255 (true) if that 
--        value is less than 128, and 0 (false) if it's >= 128 ... you can use
---       images or {1,2,3} constants as well as simple values
--    :bandand() joins all image bands together with bitwise AND, so you get a
--        one-band image which is true where all bands are true
--    condition:ifthenelse(then, else) takes a condition image and uses true or
--        false values to pick pixels from the then or else images ... then and
--        else can be constants or images
image = image:less(128):bandand():ifthenelse({ 0, 0, 255 }, image)

-- go to Yxy colourspace
image = image:colourspace("yxy")

-- pass options to a save operation
image:write_to_file("x.png", { compression = 9 })]]