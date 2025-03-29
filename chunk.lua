return function(CHUNK_SIZE,getChunk,lazyCheckWorld,packBits,band,lshift,rshift,tI,g3d,coorPos,checkWorldAt,bitsPerDs)
--[[local toUInt = function(x)
	x = rshift(x,coorPos)
	local s = ""
	for i=0,2 do
		s = tostring(require'bit'.band(rshift(x,i*bitsPerDs),CHUNK_SIZE-1)) .. " "..s
	end
	return s
end
--]]
local wallx, wallX, wally, wallY, wallz, wallZ = require 'meshes'(g3d)
local function packCoords(x,y,z)
	return packBits(lshift(band(x,CHUNK_SIZE-1) + lshift(band(y,CHUNK_SIZE-1)+lshift(band(z,CHUNK_SIZE-1),bitsPerDs),bitsPerDs),coorPos))
end
local function destroyAndCreateFace(V,w,v,world,p,h,d--[[,x,y,z]],_,coor)
	if V==1 then
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
local function createFaces(world, x,y,z,X,Y,Z)
	if lazyCheckWorld(x,y,z)>0 then
		local p,h = packCoords(x,y,z)
		local v
		v = checkWorldAt(X-1,Y,Z)==0
		world.x[#world.x+1] = v and p or nil
		world._x[h] = v and #world.x or nil
		v = checkWorldAt(X+1,Y,Z)==0
		world.X[#world.X+1] = v and p or nil
		world._X[h] = v and #world.X or nil
		v = checkWorldAt(X,Y-1,Z)==0
		world.y[#world.y+1] = v and p or nil
		world._y[h] = v and #world.y or nil
		v = checkWorldAt(X,Y+1,Z)==0
		world.Y[#world.Y+1] = v and p or nil
		world._Y[h] = v and #world.Y or nil
		v = checkWorldAt(X,Y,Z-1)==0
		world.z[#world.z+1] = v and p or nil
		world._z[h] = v and #world.z or nil
		v = checkWorldAt(X,Y,Z+1)==0
		world.Z[#world.Z+1] = v and p or nil
		world._Z[h] = v and #world.Z or nil
	end
end
local function lazyCreateFaces(world, x,y,z)
	if lazyCheckWorld(x,y,z)>0 then
		local p,h = packCoords(x,y,z)
		local v
		v=lazyCheckWorld(x-1,y,z)==0
		world.x[#world.x+1] = v and p or nil
		world._x[h] = v and #world.x or nil
		v=lazyCheckWorld(x+1,y,z)==0
		world.X[#world.X+1] = v and p or nil
		world._X[h] = v and #world.X or nil
		v=lazyCheckWorld(x,y-1,z)==0
		world.y[#world.y+1] = v and p or nil
		world._y[h] = v and #world.y or nil
		v=lazyCheckWorld(x,y+1,z)==0
		world.Y[#world.Y+1] = v and p or nil
		world._Y[h] = v and #world.Y or nil
		v=lazyCheckWorld(x,y,z-1)==0
		world.z[#world.z+1] = v and p or nil
		world._z[h] = v and #world.z or nil
		v=lazyCheckWorld(x,y,z+1)==0
		world.Z[#world.Z+1] = v and p or nil
		world._Z[h] = v and #world.Z or nil
	end
end
local d = {"x","X","y","Y","z","Z"}
local checker = {function (x,y,z,X,Y,Z)
	return lazyCheckWorld(x,y,z)
end,
function (x,y,z,X,Y,Z)
	return checkWorldAt(X,Y,Z)
end}
return function(world,positions) --update
	local X,Y,Z=unpack(world.p)
	X,Y,Z = X*CHUNK_SIZE,Y*CHUNK_SIZE,Z*CHUNK_SIZE
	if not positions then
		for _,v in pairs(d) do
			world[v] = {limit = world[v].limit}
		end
		-- inner
		for z=1,CHUNK_SIZE-2 do
			for y=1,CHUNK_SIZE-2 do
				for x=1,CHUNK_SIZE-2 do
					lazyCreateFaces(world,x,y,z)--x+X*CHUNK_SIZE,y+Y*CHUNK_SIZE,z+Z*CHUNK_SIZE)
				end
			end
		end
		-- faces
		local r = 1
		for z=0,CHUNK_SIZE-1,CHUNK_SIZE-1 do
			-- if getChunk(X,Y,Z-1+(CHUNK_SIZE+2)*(r)) then
			-- end
				for y=1,CHUNK_SIZE-2 do
					for x=1,CHUNK_SIZE-2 do
						local X,Y,Z = x+X,y+Y,z+Z
						if lazyCheckWorld(x,y,z)>0 then
							local p,h = packCoords(x,y,z)
							local v
							v=lazyCheckWorld(x-1,y,z)==0
							world.x[#world.x+1] = v and p or nil
							world._x[h] = v and #world.x or nil
							v=lazyCheckWorld(x+1,y,z)==0
							world.X[#world.X+1] = v and p or nil
							world._X[h] = v and #world.X or nil
							v=lazyCheckWorld(x,y-1,z)==0
							world.y[#world.y+1] = v and p or nil
							world._y[h] = v and #world.y or nil
							v=lazyCheckWorld(x,y+1,z)==0
							world.Y[#world.Y+1] = v and p or nil
							world._Y[h] = v and #world.Y or nil
							v=checker[1+r](x,y,z-1,X,Y,Z-1)==0
							world.z[#world.z+1] = v and p or nil
							world._z[h] = v and #world.z or nil
							v=checker[2-r](x,y,z+1,X,Y,Z+1)==0
							world.Z[#world.Z+1] = v and p or nil
							world._Z[h] = v and #world.Z or nil
						end
					end
				end
			r=0
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
			pushOrCreateFaces(world,v[1],v[2],v[3],v[1]+X,v[2]+Y,v[3]+Z)
		end
	end
end,
{function (world)
	wallx.mesh:attachAttribute("InstancePosition", world.fx, "perinstance")
	love.graphics.drawInstanced(wallx.mesh, #world.x)
end,
function (world)
	wallX.mesh:attachAttribute("InstancePosition", world.fX, "perinstance")
	love.graphics.drawInstanced(wallX.mesh, #world.X)
end,
function (world)
	wally.mesh:attachAttribute("InstancePosition", world.fy, "perinstance")
	love.graphics.drawInstanced(wally.mesh, #world.y)
end,
function (world)
	wallY.mesh:attachAttribute("InstancePosition", world.fY, "perinstance")
	love.graphics.drawInstanced(wallY.mesh, #world.Y)
end,
function (world)
	wallz.mesh:attachAttribute("InstancePosition", world.fz, "perinstance")
	love.graphics.drawInstanced(wallz.mesh, #world.z)
end,
function (world)
	wallZ.mesh:attachAttribute("InstancePosition", world.fZ, "perinstance")
	love.graphics.drawInstanced(wallZ.mesh, #world.Z)
end}
end
