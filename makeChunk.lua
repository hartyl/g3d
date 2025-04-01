local bit = require'bit'
local lshift = bit.lshift
local rshift = bit.rshift
local band = bit.band
local bor = bit.bor
return function (coordinates,chunk,d,toUpdateList)
return function (X,Y,Z)
	local s = coordinates(X,Y,Z)
	chunk[s]={}
	-- local dd=d/2
	local world = chunk[s]
	local i=0
	world.totalBlocks = 0
	for x=0,rshift(d^3,5) do
		world[x]=0
	end
	---[[
	for z=Z*d,math.min(Z*d+d-1,15) do
		for y=0,d-1 do
			for x=0,d-1 do
				local k=
				-- dd-sqrt((x-dd)^2+(y-dd)^2+(z-dd)^2)+
				-(z-7-1-(
				(math.sin((x+y-2+(X+Y)*d)*0.15)
				+math.sin((-x+y-2+(-X+Y)*d)*0.15))*3))
				>0 and 1 or 0
				local _i=rshift(i,5)
				world[_i] = bor(world[_i], lshift(k,band(i,31)))
				world.totalBlocks=world.totalBlocks+k
				i=i+1
			end
		end
	end
	--]]
	local limit = 1
	local format = {{"InstancePosition", "float", 1}}
	for _,v in pairs({"x","X","y","Y","z","Z"}) do
		world[v] = {limit=limit}
		world["_"..v] = {}
		world["f"..v] = love.graphics.newMesh(format, limit, nil, "dynamic")
	end

	world.p={X,Y,Z}
	toUpdateList[world]=false
	Lil[1]=0
	local x,y,z=0,0,0
	for x=-1,1,2 do
		toUpdateList[chunk[coordinates(X+x,Y+y,Z+z)] or 0] = false
		Lil[1]=Lil[1]+1
	end
	for y=-1,1,2 do
		toUpdateList[chunk[coordinates(X+x,Y+y,Z+z)] or 0] = false
		Lil[1]=Lil[1]+1
	end
	for z=-1,1,2 do
		toUpdateList[chunk[coordinates(X+x,Y+y,Z+z)] or 0] = false
		Lil[1]=Lil[1]+1
	end
	toUpdateList[0]=nil
	return world
end
end
