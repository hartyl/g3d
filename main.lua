-- Voxel Engine for Löve2D by Hartyl

require 'jit'.off()
local bit = require 'bit'
local packBits = require 'packBits'
local g3d = require "g3d"
CHUNK_SIZE = 64
local CHUNK_SIZE = CHUNK_SIZE
local size = 1
local depth = 1
local tI = table.insert
local band, bor, arshift, rshift, lshift = bit.band, bit.bor, bit.arshift, bit.rshift, bit.lshift
local floor = math.floor
love.graphics.setMeshCullMode("back")
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, {-1,1,1})
local timer = 0
local FPS = 0
local chunk={}
local chunkPointer = {}
local camera = g3d.camera

local bitsPerD = math.log(CHUNK_SIZE,2)
local coorPos
local features = love.graphics.getSupported()
local face
if features.glsl3 then
	coorPos = 32-bitsPerD*3
	face = love.graphics.newShader("face3.vert","face.frag")
else
	coorPos = 1/lshift(1,coorPos)
	coorPos = 31-bitsPerD*3
	-- face = love.graphics.newShader("face.vert","face.frag")
end
face:send('CHUNK_SIZE',CHUNK_SIZE)
face:send('coorPos',coorPos)

Lol = {}
Lal = {}
Lil = {}
local function coordinates(x,y,z)
	return ("%s;%s;%s"):format(x,y,z)
end

local function d3dToLine(x,y,z)
	return band(x)+lshift(y,bitsPerD)+lshift(z,lshift(bitsPerD,1))
end

local toUpdateList={}
local function checkWorldAt(x,y,z)
	local chnk=chunk[coordinates(arshift(x,bitsPerD),arshift(y,bitsPerD),arshift(z,bitsPerD))]
	if not chnk then return 0 end
	local i = d3dToLine(band(x,CHUNK_SIZE-1),band(y,CHUNK_SIZE-1),band(z,CHUNK_SIZE-1))
	return band(rshift(chnk[rshift(i,5)],band(i,31)),1), chnk, band(i,31), chnk[rshift(i,5)]
end

local function lazyCheckWorld(x,y,z)
	local i = (d3dToLine(x,y,z))
	return band(rshift(chunkPointer[1][rshift(i,5)],band(i,31)),1)
end

local faces = 0

local function getChunk(x,y,z)
	return chunk[coordinates(arshift(x,bitsPerD),arshift(y,bitsPerD),arshift(z,bitsPerD))]
end
local updateChunk,drawChunk = require'chunk'(CHUNK_SIZE,getChunk,lazyCheckWorld,packBits,band,lshift,rshift,tI,g3d,coorPos,checkWorldAt,bitsPerD)
local makeChunk=require'makeChunk'(coordinates,chunk,CHUNK_SIZE,toUpdateList)

for x=-size,size do
	for y=-size,size do
		for z=0,depth do
			if x*x+y*y<size*size then
				makeChunk(x,y,z)
			end
		end
	end
end
local function setBlock(world,value,x,y,z)
	local _x,_y,_z=band(x,CHUNK_SIZE-1),
                   band(y,CHUNK_SIZE-1),
                   band(z,CHUNK_SIZE-1)

	local i = d3dToLine(_x, _y, _z)
	chunkPointer[1]=world
	local _i = rshift(i,5)
	local i_ = i-lshift(_i,5)

	if value == 1-band(rshift(world[_i],i_),1) then
		if value == 0 then
			world.totalBlocks=world.totalBlocks-1
			world[_i]=band(world[_i],bit.bnot(lshift(1,i_)))
		else
			world[_i]=bor(world[_i],lshift(1,i_))
		end
		toUpdateList[world]=(toUpdateList[world] or {})
		tI(toUpdateList[world], {_x,_y,_z})
	end
	return world, i
end

function love.update(dt)
	-- FPS = (FPS + 1/dt) / 2
	FPS = 1/dt
    timer = timer + dt
    g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
	local m=-1
	if love.mouse.isDown(1) then m=1 elseif love.mouse.isDown(2) then m=0 end
	if m>=0 then
		local p = {camera.position[1]-0.5,camera.position[2]-0.5,camera.position[3]-0.5}
		local ch = getChunk(unpack(p))
		if ch then
			setBlock(ch,m,camera.position[1]-0.5,camera.position[2]-0.5,camera.position[3]-0.5)
		else
			makeChunk(floor(camera.position[1]/CHUNK_SIZE),floor(camera.position[2]/CHUNK_SIZE),floor(camera.position[3]/CHUNK_SIZE))
		end
	end
	Lal[1]=0
	Lol[1],_,Lol[2],Lol[3]=checkWorldAt(camera.position[1]-0.5,camera.position[2]-0.5,camera.position[3]-0.5)
	for i,v in next, toUpdateList do
		chunkPointer[1]=i
		updateChunk(i,v)
		toUpdateList[i]=nil
		Lal[1]=Lal[1]+1
	end
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
		return tx>-.7
	end,
	function ()
		return tx<.7
	end,
	function ()
		return ty>-.7
	end,
	function ()
		return ty<.7
	end,
	function ()
		return tz>-.7
	end,
	function ()
		return tz<.7
	end
}

local subtract = g3d.vectors.subtract
love.graphics.setBackgroundColor(0,0,0,0)
love.graphics.setBlendMode('replace')
local cPos = camera.position
local cTar = camera.target
function love.draw()
	love.graphics.setDepthMode("always", false)
	background:setTranslation(unpack(cPos))
	background:draw()
	love.graphics.setDepthMode("lequal", true)
	faces = 0
    love.graphics.setShader(face)
    face:send("viewMatrix", camera.viewMatrix)
    face:send("projectionMatrix", camera.projectionMatrix)
	local toDraw = {}
	tx,ty,tz = subtract(cTar[1],cTar[2],cTar[3],unpack(cPos))
	local x,y,z = tx>0 and 1 or 0,ty>0 and 1 or 0,tz>0 and 1 or 0
	for _,v in pairs(chunk) do
		local p = v.p
		local xx,yy,zz = subtract(lshift(p[1]+x,bitsPerD),lshift(p[2]+y,bitsPerD),lshift(p[3]+z,bitsPerD),unpack(cPos))
		toDraw[#toDraw+1] = (xx*tx + yy*ty + zz*tz > 0) and {v,unpack(p)} or nil
	end
	cx,cy,cz = g3d.vectors.scalarMultiply(1/CHUNK_SIZE,unpack(cPos))
	local d = {"x","X","y","Y","z","Z"}
	for i,ds in pairs(d) do
		love.graphics.setColor(colors[i])
		if checkFunctions1[i]() then
			for _, v in pairs(toDraw) do
				face:send('translation',{unpack(v,2,4)})
				if checkFunctions[i](v) then
					drawChunk[i](unpack(v))
					faces = faces + #v[1][ds]
				end
			end
		end
	end
	love.graphics.setShader()
	love.graphics.setColor(1,1,1)
	Lal=table.concat(Lal,";")
	Lil=table.concat(Lil,";")
	love.graphics.print(table.concat({table.concat(cPos,';'),FPS,faces,"lol:",table.concat(Lol,";"),"lal:",Lal,"lil:",Lil},"\n"))
	Lal = {}
	Lil = {}
end

function love.mousemoved(_,_, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end
