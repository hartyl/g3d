-- Voxel Engine for Löve2D by Hartyl

local bit = require 'bit'
local packBits = require 'packBits'
local g3d = require "g3d"
local CHUNK_SIZE = 32
local tI = table.insert
local floor = math.floor
love.graphics.setMeshCullMode("back")
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, {-1,1,1})
local timer = 0
local FPS = 0
local chunk={}
local c
local camera = g3d.camera

Lol = {}
Lal = {}
Lil = {}
local function coordinates(x,y,z)
	return ("%s;%s;%s"):format(x,y,z)
end

local function d3dToLine(x,y,z)
	return x+y*CHUNK_SIZE+z*CHUNK_SIZE*CHUNK_SIZE-(1+CHUNK_SIZE)*CHUNK_SIZE
end

local toUpdateList={}
local function checkWorld(x,y,z,X,Y,Z)
	local chnk = c
	if not (x>0 and x<=CHUNK_SIZE and y>0 and y<=CHUNK_SIZE and z>0 and z<=CHUNK_SIZE) then
		if x<=0 then
			X=X-1
			x=x+CHUNK_SIZE
		elseif x> CHUNK_SIZE then
			X=X+1
			x=x-CHUNK_SIZE
		end
		if y<=0 then
			Y=Y-1
			y=y+CHUNK_SIZE
		elseif y> CHUNK_SIZE then
			Y=Y+1
			y=y-CHUNK_SIZE
		end
		if z<=0 then
			Z=Z-1
			z=z+CHUNK_SIZE
		elseif z> CHUNK_SIZE then
			Z=Z+1
			z=z-CHUNK_SIZE
		end
		chnk=chunk[coordinates(X,Y,Z)]
		if X==camera.position[1] and Y == camera.position[2] and Z == camera.position[3] then
			Lil[1] = table.concat({x,y,z,},",")
		end
		if not chnk then return 0 end
		local l=d3dToLine(x,y,z)
		assert(chnk[l],table.concat({x,y,z,l},","))
	end
	return chnk[d3dToLine(x,y,z)]
end

local face = love.graphics.newShader("face.vert","face.frag")
face:send('CHUNK_SIZE',CHUNK_SIZE)
local bitsPerD = math.log(CHUNK_SIZE,2)
local coorPos = bit.lshift(1,31-bitsPerD*3)
face:send('bitsPerDs',coorPos)
local faces = 0
local updateChunk,drawChunk = require'chunk'(CHUNK_SIZE,d3dToLine,checkWorld,packBits,bit.lshift,tI,g3d,31-bitsPerD*3)

local function getChunk(x,y,z)
	return chunk[coordinates(floor(x/CHUNK_SIZE),floor(y/CHUNK_SIZE),floor(z/CHUNK_SIZE))]
end
local makeChunk=require'makeChunk'(coordinates,chunk,CHUNK_SIZE,toUpdateList,getChunk)

local size = 10
for x=-size,size do
	for y=-size,size do
		for z=-1,0 do
			makeChunk(x,y,z)
		end
	end
end

local function getOrMakeChunk(x,y,z)
	local X,Y,Z = floor(x/CHUNK_SIZE),floor(y/CHUNK_SIZE),floor(z/CHUNK_SIZE)
	return chunk[coordinates(X,Y,Z)] or makeChunk(X,Y,Z)
end


local bakedBorderCheck = {}
local function checkChunkX(x,y,z,_x)
	local world2 = getChunk(x+_x,y,z) or 0
	toUpdateList[world2]=true
end
local function checkChunkY(x,y,z,_y)
	local world2 = getChunk(x,y+_y,z) or 0
	toUpdateList[world2]=true
end
local function checkChunkZ(x,y,z,_z)
	local world2 = getChunk(x,y,z+_z) or 0
	toUpdateList[world2]=true
end
for i=1,CHUNK_SIZE^3 do
	local x,y,z=i%CHUNK_SIZE+1,floor(i/CHUNK_SIZE)%CHUNK_SIZE+1,floor(i/CHUNK_SIZE^2)+1
	bakedBorderCheck[i]=
	{
		x==1 and (1) or x==CHUNK_SIZE and (-1) or 0,
		y==1 and (-1) or y==CHUNK_SIZE and (1) or 0,
		z==1 and (-1) or z==CHUNK_SIZE and (1) or 0,
	}
end
local function setBlock(world,value,x,y,z)
	local _x,_y,_z=floor(x%CHUNK_SIZE)+1,
                   floor(y%CHUNK_SIZE)+1,
                   floor(z%CHUNK_SIZE)+1

	local i = d3dToLine(_x, _y, _z)

	c=world
	world[i]=value
	toUpdateList[world]=true
	local X,Y,Z = unpack(bakedBorderCheck[i])
	checkChunkX(x,y,z,X)
    checkChunkY(x,y,z,Y)
    checkChunkZ(x,y,z,Z)

	toUpdateList[0]=nil
	return world, i
end

function love.update(dt)
	FPS = (FPS + 1/dt) / 2
    timer = timer + dt
    g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
	local m=-1
	if love.mouse.isDown(1) then m=1 elseif love.mouse.isDown(2) then m=0 end
	if m>=0 then
		local p = {unpack(g3d.camera.position)}
		for i=1,1 do
			setBlock(getOrMakeChunk(unpack(p)),m,unpack(p))
			p[1]=p[1]+floor(math.random(-1,1)+0.5)*CHUNK_SIZE*i/8-(g3d.camera.position[1]-p[1])/5
			p[2]=p[2]+floor(math.random(-1,1)+0.5)*CHUNK_SIZE*i/8-(g3d.camera.position[2]-p[2])/5
			p[3]=p[3]+CHUNK_SIZE
		end
	end
	Lal[1]=0
	for i in next, toUpdateList do
		c=i
		updateChunk(i)
		toUpdateList[i]=nil
		Lal[1]=Lal[1]+1
	end
	toUpdateList={}
end

local cx,cy,cz
local checkFunctions = {
	function (v)
		return cx<(v[2]+1)
	end,
	function (v)
		return cx>v[2]
	end,
	function (v)
		return cy<(v[3]+1)
	end,
	function (v)
		return cy>v[3]
	end,
	function (v)
		return cz<(v[4]+1)
	end,
	function (v)
		return cz>v[4]
	end
}
local colors = {
	{1,0,0},
	{1,1,0},
	{0,1,1},
	{0,0,1},
	{1,0,1},
	{1,1,1},
}

local tx,ty,tz
local checkFunctions1 = {
	function ()
		return tx>-0.75
	end,
	function ()
		return tx<0.75
	end,
	function ()
		return ty>-0.75
	end,
	function ()
		return ty<0.75
	end,
	function ()
		return tz>-0.75
	end,
	function ()
		return tz<0.75
	end
}

function love.draw()
	love.graphics.setDepthMode("always", false)
	background:setTranslation(unpack(g3d.camera.position))
	background:draw()
	love.graphics.setDepthMode("lequal", true)
	faces = 0
    love.graphics.setShader(face)
    face:send("viewMatrix", camera.viewMatrix)
    face:send("projectionMatrix", camera.projectionMatrix)
	local toDraw = {}
	local t={}
	t[true]=toDraw
	t[false]={}
	tx,ty,tz = g3d.vectors.subtract(camera.target[1],camera.target[2],camera.target[3],unpack(camera.position))
	local x,y,z = tx>0 and 1 or 0,ty>0 and 1 or 0,tz>0 and 1 or 0
	for i,v in pairs(chunk) do
		local p = {}
		for w in i:gmatch("-?%d*") do
			p[#p+1] = tonumber(w)
		end
		local x,y,z = g3d.vectors.subtract((p[1]+x)*CHUNK_SIZE,(p[2]+y)*CHUNK_SIZE,(p[3]+z)*CHUNK_SIZE,unpack(camera.position))
		local yes = x*tx + y*ty + z*tz > 0
		tI(t[yes],{v,unpack(p)})
	end
	cx,cy,cz = g3d.vectors.scalarMultiply(1/CHUNK_SIZE,unpack(camera.position))
	local d = {"x","X","y","Y","z","Z"}
	for i=1,6 do
		love.graphics.setColor(colors[i])
		if checkFunctions1[i]() then
			for _, v in pairs(toDraw) do
				face:send('translation',{unpack(v,2,4)})
				if checkFunctions[i](v) then
					drawChunk[i](unpack(v))
					faces = faces + #v[1][d[i]]
				end
			end
		end
	end
	love.graphics.setShader()
	love.graphics.setColor(1,1,1)
	Lol=table.concat(Lol,";")
	Lal=table.concat(Lal,";")
	Lil=table.concat(Lil,";")
	love.graphics.print(table.concat({table.concat(g3d.camera.position,';'),FPS,faces,"lol:",Lol,"lal:",Lal,"lil:",Lil},"\n"))
	Lol = {}
	Lal = {}
	Lil = {}
end

function love.mousemoved(_,_, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end
