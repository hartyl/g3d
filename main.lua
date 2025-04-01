-- Voxel Engine for Löve2D by Hartyl

require 'jit'.off()
local bit = require 'bit'
local packBits = require 'packBits'
local g3d = require "g3d"
CHUNK_SIZE = 32
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

local bitsPerD = band(math.log(CHUNK_SIZE,2))
local coorPos = 31-bitsPerD*3
local features = love.graphics.getSupported()
local face
if features.glsl3 then
	face = love.graphics.newShader("face3.vert")--,"face.frag")
	face:send("bitsPerD",bitsPerD)
	face:send('CHUNK_SIZE',CHUNK_SIZE-1)
else
	face = love.graphics.newShader("face.vert","face.frag")
	face:send('CHUNK_SIZE',CHUNK_SIZE)
end
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

for x=-size,size-1 do
	for y=-size,size-1 do
		for z=0,depth do
			if (x+0.5)^2+(y+0.5)^2<size*size then
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
		toUpdateList[world]=false--(toUpdateList[world] or {})
		-- tI(toUpdateList[world], {_x,_y,_z})
	end
	return world, i
end

function love.update(dt)
	if love.keyboard.isDown("g") then
		camera.position[1], camera.position[2], camera.position[3] =
		g3d.vectors.add(camera.position[1], camera.position[2], camera.position[3], g3d.vectors.normalize(unpack(camera.frustrum.y)))
		camera.target[1], camera.target[2], camera.target[3] =
		g3d.vectors.add(camera.target[1], camera.target[2], camera.target[3], g3d.vectors.normalize(unpack(camera.frustrum.y)))
	end
	if love.keyboard.isDown("f") then
		camera.position[1], camera.position[2], camera.position[3] =
		g3d.vectors.add(camera.position[1], camera.position[2], camera.position[3], g3d.vectors.normalize(unpack(camera.frustrum.Y)))
		camera.target[1], camera.target[2], camera.target[3] =
		g3d.vectors.add(camera.target[1], camera.target[2], camera.target[3], g3d.vectors.normalize(unpack(camera.frustrum.Y)))
	end
	if love.keyboard.isDown("b") then
		camera.position[1], camera.position[2], camera.position[3] =
		g3d.vectors.add(camera.position[1], camera.position[2], camera.position[3], g3d.vectors.normalize(unpack(camera.right)))
		camera.target[1], camera.target[2], camera.target[3] =
		g3d.vectors.add(camera.target[1], camera.target[2], camera.target[3], g3d.vectors.normalize(unpack(camera.right)))
	end
	if love.keyboard.isDown("n") then
		camera.position[1], camera.position[2], camera.position[3] =
		g3d.vectors.add(camera.position[1], camera.position[2], camera.position[3], g3d.vectors.normalize(unpack(camera.upwards)))
		camera.target[1], camera.target[2], camera.target[3] =
		g3d.vectors.add(camera.target[1], camera.target[2], camera.target[3], g3d.vectors.normalize(unpack(camera.upwards)))
	end
	camera.updateViewMatrix()

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
		or makeChunk(floor(camera.position[1]/CHUNK_SIZE),floor(camera.position[2]/CHUNK_SIZE),floor(camera.position[3]/CHUNK_SIZE))
		setBlock(ch,m,camera.position[1]-0.5,camera.position[2]-0.5,camera.position[3]-0.5)
	end
	Lol[1],_,Lol[2],Lol[3]=checkWorldAt(camera.position[1]-0.5,camera.position[2]-0.5,camera.position[3]-0.5)
	for world,pos in next, toUpdateList do
		chunkPointer[1]=world
		updateChunk(world,pos)
		toUpdateList[world]=nil
		if world.totalBlocks == 0 then world = nil return end
	end
end

local cx,cy,cz
local checkPos = {
	x=function (v)
		return cx<v[2]+CHUNK_SIZE
	end,
	X=function (v)
		return cx>v[2]
	end,
	y=function (v)
		return cy<v[3]+CHUNK_SIZE
	end,
	Y=function (v)
		return cy>v[3]
	end,
	z=function (v)
		return cz<v[4]+CHUNK_SIZE
	end,
	Z=function (v)
		return cz>v[4]
	end
}
local colors = {
	x={1,0,0},
	X={1,1,0},
	y={0,1,1},
	Y={0,0,1},
	z={1,0,1},
	Z={1,1,1},
}

local frustrum
local checkAngle = {
	function ()
		local x,y = unpack(frustrum.xp)
		local X,Y = unpack(frustrum.Xp)
		return x>=0 or X<=0
	end,
	function ()
		local x,y = unpack(frustrum.xp)
		local X,Y = unpack(frustrum.Xp)
		return X>=0 or x<=0
	end,
	function ()
		local x,y = unpack(frustrum.xp)
		local X,Y = unpack(frustrum.Xp)
		return y>=0 or Y<=0
	end,
	function ()
		local x,y = unpack(frustrum.xp)
		local X,Y = unpack(frustrum.Xp)
		return Y>=0 or y<=0
	end,
	function ()
		local z = frustrum.yp
		local Z = frustrum.Yp
		return z>=0 or Z<=0
	end,
	function ()
		local z = frustrum.yp
		local Z = frustrum.Yp
		return Z>=0 or z<=0
	end,
}

local subtract = g3d.vectors.subtract
love.graphics.setBackgroundColor(0,0,0,0)
love.graphics.setBlendMode('replace')
local cPos = camera.position
local cTar = camera.target
-- face:send("projectionMatrix", camera.projectionMatrix)
local matMul = require 'matrixMul'
local cross = g3d.vectors.crossProduct
function love.draw()
	love.graphics.setDepthMode("always", false)
	background:setTranslation(unpack(cPos))
	background:draw()
	love.graphics.setDepthMode("lequal", true)
	-- if FPS < 45 then return end
	faces = 0
    love.graphics.setShader(face)
	local pvMat = matMul(camera.viewMatrix,camera.projectionMatrix)
	face:send("viewMatrix", pvMat)
	local toDraw = {}
	local frontMultFar = {g3d.vectors.scalarMultiply(camera.farClip, subtract(cTar[1],cTar[2],cTar[3],unpack(cPos)))}
	local halfVSide = camera.farClip * math.tan(camera.fov * .5)
	local halfHSide = halfVSide * camera.aspectRatio
	local dir,pitch = camera.getDirectionPitch()
	camera.dir, camera.pitch = dir%(math.pi+math.pi),pitch
	camera.right = {math.sin(dir),-math.cos(dir),0}
	local zU = -math.sin(pitch)
	camera.upwards = {math.cos(dir)*zU,math.sin(dir)*zU,math.cos(pitch)}
	-- camera.upwards = {cross(cTar[1], cTar[2], cTar[3], camera.right[1], camera.right[2], camera.right[3])} --funny hops
	-- screenPosition = pvMat * (vertexPosition + vec4(translation*CHUNK_SIZE,0));
	local Ux,Uy,Uz = g3d.vectors.scalarMultiply(halfVSide, unpack(camera.upwards))
	local Rx,Ry,Rz = g3d.vectors.scalarMultiply(halfHSide, unpack(camera.right))
	frustrum = {
		x = {
			cross(
				frontMultFar[1] - Rx,
				frontMultFar[2] - Ry,
				frontMultFar[3] - Rz,
				camera.upwards[1], camera.upwards[2], camera.upwards[3]
			)
		},
		X = {
			cross(
				camera.upwards[1], camera.upwards[2], camera.upwards[3],
				frontMultFar[1] + Rx,
				frontMultFar[2] + Ry,
				frontMultFar[3] + Rz
			)
		},
		y = {
			cross(
				frontMultFar[1] + Ux,
				frontMultFar[2] + Uy,
				frontMultFar[3] + Uz,
				camera.right[1], camera.right[2], camera.right[3]
			)
		},
		Y = {
			cross(
				camera.right[1], camera.right[2], camera.right[3],
				frontMultFar[1] - Ux,
				frontMultFar[2] - Uy,
				frontMultFar[3] - Uz
			)
		}
	}
	camera.frustrum = frustrum

	local x_,y_,z_ = {}, {}, {}
	for ds in pairs(frustrum) do
		x_[ds],y_[ds],z_[ds] =
		frustrum[ds][1]>=0 and CHUNK_SIZE or 0,
		frustrum[ds][2]>=0 and CHUNK_SIZE or 0,
		frustrum[ds][3]>=0 and CHUNK_SIZE or 0
	end
	for _,v in pairs(chunk) do
		local x,y,z = lshift(v.p[1],bitsPerD),lshift(v.p[2],bitsPerD),lshift(v.p[3],bitsPerD)
		local r = true
		local xx,yy,zz
		for d,ds in pairs(frustrum) do
			xx,yy,zz = subtract( x+x_[d],y+y_[d],z+z_[d], unpack(cPos) )
			r = (xx*ds[1] + yy*ds[2] + zz*ds[3] > 0) and r
		end
		toDraw[#toDraw+1] = r and {v,x,y,z} or nil
	end
	-- return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
	frustrum.xp = {camera.upwards[2]*frustrum.x[3] - camera.upwards[3]*frustrum.x[2], camera.upwards[3]*frustrum.x[1] - camera.upwards[1]*frustrum.x[3]}
	frustrum.Xp = {camera.upwards[2]*frustrum.X[3] - camera.upwards[3]*frustrum.X[2], camera.upwards[3]*frustrum.X[1] - camera.upwards[1]*frustrum.X[3]}
	frustrum.yp = camera.right[1]*frustrum.y[2] - camera.right[2]*frustrum.y[1]
	frustrum.Yp = camera.right[1]*frustrum.Y[2] - camera.right[2]*frustrum.Y[1]
	cx,cy,cz = unpack(cPos)
	local d = {"x","X","y","Y","z","Z"}
	local d2 = {}
	for i,ds in pairs(d) do
		d2[ds] = checkAngle[i]() and i or nil
	end
	for ds in pairs(d2) do
		love.graphics.setColor(colors[ds])
		local toDraw2 = {}
		for _, v in pairs(toDraw) do
			toDraw2[#toDraw2+1] = checkPos[ds](v) and v or nil
		end
		for _, w in pairs(toDraw2) do
			face:send('translation',{unpack(w,2,4)})
			drawChunk[ds](w[1])
			faces = faces + #w[1][ds]
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
