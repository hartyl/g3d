local drawInstanced = love.graphics.drawInstanced
local bnot = require'bit'.bnot
return function(CHUNK_SIZE,getChunk,lazyCheckWorld,packBits,band,lshift,rshift,tI,g3d,coorPos,checkWorldAt,bitsPerDs)
--[[local toUInt = function(x) -- decode uint
	x = rshift(x,coorPos)
	local s = ""
	for i=0,2 do
		s = tostring(require'bit'.band(rshift(x,i*bitsPerDs),CHUNK_SIZE-1)) .. " "..s
	end
	return s
end
--]]

local function packCoords(x,y,z)
	return packBits((band(x,CHUNK_SIZE-1) + lshift(band(y,CHUNK_SIZE-1)+lshift(band(z,CHUNK_SIZE-1),bitsPerDs),bitsPerDs))*2^coorPos)
end
local checker = {function (x,y,z,_,_,_)
	return lazyCheckWorld(x,y,z)
end,
function (_,_,_,X,Y,Z)
	return checkWorldAt(X,Y,Z)
end}
local val
local function lazyx(world,p,h,x,y,z)
	val=lazyCheckWorld(x-1,y,z)==0
	world.x[#world.x+1] = val and p or nil
	world._x[h] = val and #world.x or nil
	val=lazyCheckWorld(x+1,y,z)==0
	world.X[#world.X+1] = val and p or nil
	world._X[h] = val and #world.X or nil
end

local function lazyy(world,p,h,x,y,z)
	val=lazyCheckWorld(x,y-1,z)==0
	world.y[#world.y+1] = val and p or nil
	world._y[h] = val and #world.y or nil
	val=lazyCheckWorld(x,y+1,z)==0
	world.Y[#world.Y+1] = val and p or nil
	world._Y[h] = val and #world.Y or nil
end

local function lazyz(world,p,h,x,y,z)
	val=lazyCheckWorld(x,y,z-1)==0
	world.z[#world.z+1] = val and p or nil
	world._z[h] = val and #world.z or nil
	val=lazyCheckWorld(x,y,z+1)==0
	world.Z[#world.Z+1] = val and p or nil
	world._Z[h] = val and #world.Z or nil
end

local function checkerx(world,p,h,x,y,z,X,Y,Z,r)
	val=checker[1+r](x-1,y,z,X-1,Y,Z)==0
	world.x[#world.x+1] = val and p or nil
	world._x[h] = val and #world.x or nil
	val=checker[2-r](x+1,y,z,X+1,Y,Z)==0
	world.X[#world.X+1] = val and p or nil
	world._X[h] = val and #world.X or nil
end

local function checkery(world,p,h,x,y,z,X,Y,Z,r)
	val=checker[1+r](x,y-1,z,X,Y-1,Z)==0
	world.y[#world.y+1] = val and p or nil
	world._y[h] = val and #world.y or nil
	val=checker[2-r](x,y+1,z,X,Y+1,Z)==0
	world.Y[#world.Y+1] = val and p or nil
	world._Y[h] = val and #world.Y or nil
end

local function checkerz(world,p,h,x,y,z,X,Y,Z,r)
	val=checker[1+r](x,y,z-1,X,Y,Z-1)==0
	world.z[#world.z+1] = val and p or nil
	world._z[h] = val and #world.z or nil
	val=checker[2-r](x,y,z+1,X,Y,Z+1)==0
	world.Z[#world.Z+1] = val and p or nil
	world._Z[h] = val and #world.Z or nil
end

local wallx, wallX, wally, wallY, wallz, wallZ = require 'meshes'(g3d)
local function destroyAndCreateFace(V,w,v,world,p,h,d--[[,x,y,z]],_,coor)
	if V==1 and #w[d]>0 then
		local side = w[d]
		local sidePointer = w['_'..d]
		local index = sidePointer[coor]
		-- assert(index,table.concat({tostring(index),toUInt(coor),x,y,z, d},","))
		local lastFaceValue = side[#side][1]
		side[index] = {lastFaceValue}
		w["f"..d]:setVertex(index,side[index]) -- update
		sidePointer[lastFaceValue] = index
		side[#side] = nil
		sidePointer[coor] = nil
	end
	if v==0 then
		tI(world[d],p)
		world["_"..d][h] = #world[d]
		if #world[d]>world[d].limit then
			world["f"..d]=love.graphics.newMesh({{"InstancePosition", "float", 1}},world[d],nil,"static")
		else
			world["f"..d]:setVertex(#world[d],world[d][#world[d]]) -- update
		end
	end
end
local function pushOrCreateFaces(world, x,y,z, X,Y,Z)
	if lazyCheckWorld(x,y,z)>0 then
		local p,h = packCoords(x,y,z)
		local v,w,V,W
		v,w = checkWorldAt(X-1,Y,Z) -- voxel needs a face
		V,W = checkWorldAt(X+1,Y,Z)
		destroyAndCreateFace(V,W,v,world,p,h,"x"--[[,x,y,z]],packCoords(x+1,y,z))
		destroyAndCreateFace(v,w,V,world,p,h,"X"--[[,x,y,z]],packCoords(x-1,y,z))
		v,w = checkWorldAt(X,Y-1,Z)
		V,W = checkWorldAt(X,Y+1,Z)
		destroyAndCreateFace(V,W,v,world,p,h,"y"--[[,x,y,z]],packCoords(x,y+1,z))
		destroyAndCreateFace(v,w,V,world,p,h,"Y"--[[,x,y,z]],packCoords(x,y-1,z))
		v,w = checkWorldAt(X,Y,Z-1)
		V,W = checkWorldAt(X,Y,Z+1)
		destroyAndCreateFace(V,W,v,world,p,h,"z"--[[,x,y,z]],packCoords(x,y,z+1))
		destroyAndCreateFace(v,w,V,world,p,h,"Z"--[[,x,y,z]],packCoords(x,y,z-1))
	end
end
local d = {"x","X","y","Y","z","Z"}
local todoz = {}
for z=0,CHUNK_SIZE-1,CHUNK_SIZE-1 do
	todoz[z] = checkerz
end
for z=1,CHUNK_SIZE-2 do
	todoz[z] = lazyz
end
local todoy = {}
for y=0,CHUNK_SIZE-1,CHUNK_SIZE-1 do
	todoy[y] = checkery
end
for y=1,CHUNK_SIZE-2 do
	todoy[y] = lazyy
end
return function(world,positions) --update
	local bX,bY,bZ=unpack(world.p)
	bX,bY,bZ = bX*CHUNK_SIZE,bY*CHUNK_SIZE,bZ*CHUNK_SIZE
	local X,Y,Z
	if not positions then
		for _,v in pairs(d) do
			world[v] = {limit = world[v].limit}
		end

		local rz,ry,rx

		rz = 1
		for z,funz in pairs(todoz) do
			ry=1
			for y,funy in pairs(todoy) do
				local todox = {}
				for x=0,CHUNK_SIZE-1,CHUNK_SIZE-1 do
					todox[x] = lazyCheckWorld(x,y,z)>0 and checkerx or nil
				end
				for x=1,CHUNK_SIZE-2 do
					todox[x] = lazyCheckWorld(x,y,z)>0 and lazyx or nil
				end
				rx = 1
				for x,funx in pairs(todox) do
					X,Y,Z = x+bX,y+bY,z+bZ
					local p,h = packCoords(x,y,z)
					funx(world,p,h,x,y,z,X,Y,Z,rx)
					funy(world,p,h,x,y,z,X,Y,Z,ry)
					funz(world,p,h,x,y,z,X,Y,Z,rz)
					rx=0
				end
				ry=0
			end
			rz=0
		end

		for _,v in pairs(d) do
			if #world[v]>world[v].limit then
				world[v].limit = #world[v]
				world["f"..v]=love.graphics.newMesh({{"InstancePosition", "float", 1}},world[v],nil,"static")
			else
				world["f"..v]:setVertices(world[v])
			end
		end
	else
		for _,v in pairs(positions) do
			pushOrCreateFaces(world,v[1],v[2],v[3],v[1]+bX,v[2]+bY,v[3]+bZ)
		end
	end
end,
{
x=function (world)
	wallx:attachAttribute("InstancePosition", world.fx, "perinstance")
	drawInstanced(wallx, #world.x)
end,
X=function (world)
	wallX:attachAttribute("InstancePosition", world.fX, "perinstance")
	drawInstanced(wallX, #world.X)
end,
y=function (world)
	wally:attachAttribute("InstancePosition", world.fy, "perinstance")
	drawInstanced(wally, #world.y)
end,
Y=function (world)
	wallY:attachAttribute("InstancePosition", world.fY, "perinstance")
	drawInstanced(wallY, #world.Y)
end,
z=function (world)
	wallz:attachAttribute("InstancePosition", world.fz, "perinstance")
	drawInstanced(wallz, #world.z)
end,
Z=function (world)
	wallZ:attachAttribute("InstancePosition", world.fZ, "perinstance")
	drawInstanced(wallZ, #world.Z)
end}
end
