local floor=math.floor
local sqrt = math.sqrt
return function (coordinates,chunk,CHUNK_SIZE,toUpdateList,getChunk)
return function (X,Y,Z)
	local s = coordinates(X,Y,Z)
	chunk[s]={}
	local d=CHUNK_SIZE
	local dd=d/2
	local ddd=dd^2
	local world = chunk[s]
	local i=1
	for z=1,d do
		for y=1,d do
			for x=1,d do
				world[i] = dd-sqrt((x-dd)^2+(y-dd)^2+(z-dd)^2)+
				-(Z*CHUNK_SIZE+z-(
				(math.sin((x+y+(X+Y)*CHUNK_SIZE)/12)
				+math.sin((-x+y+(-X+Y)*CHUNK_SIZE)/12))*6))
				
				>0 and 1 or 0
				i=i+1
			end
		end
	end
	world.x={}
	world.X={}
	world.y={}
	world.Y={}
	world.z={}
	world.Z={}
	local t={0}
	for i=1,d^3 do
		world.x[i]=t
		world.X[i]=t
		world.y[i]=t
		world.Y[i]=t
		world.z[i]=t
		world.Z[i]=t
	end

	local format = {{"InstancePosition", "float", 1}}
	world.fx = love.graphics.newMesh(format, world.x, nil, "dynamic")
	world.fX = love.graphics.newMesh(format, world.X, nil, "dynamic")
	world.fy = love.graphics.newMesh(format, world.y, nil, "dynamic")
	world.fY = love.graphics.newMesh(format, world.Y, nil, "dynamic")
	world.fz = love.graphics.newMesh(format, world.z, nil, "dynamic")
	world.fZ = love.graphics.newMesh(format, world.Z, nil, "dynamic")
	
	world.p={X,Y,Z}
	toUpdateList[world]=true
	Lil[1]=0
	local x,y,z=0,0,0
	for x=-1,1,2 do
		toUpdateList[chunk[coordinates(X+x,Y+y,Z+z)] or 0] = true
		Lil[1]=Lil[1]+1
	end
	for y=-1,1,2 do
		toUpdateList[chunk[coordinates(X+x,Y+y,Z+z)] or 0] = true
		Lil[1]=Lil[1]+1
	end
	for z=-1,1,2 do
		toUpdateList[chunk[coordinates(X+x,Y+y,Z+z)] or 0] = true
		Lil[1]=Lil[1]+1
	end
	toUpdateList[0]=nil
	return world
end
end
