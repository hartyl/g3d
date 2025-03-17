return function(CHUNK_SIZE,d3dToLine,checkWorld,packBits,lshift,tI,g3d,bitsPerD)
local wallx, wallX, wally, wallY, wallz, wallZ = require 'meshes'(g3d)
return function(world)
	world.x={}
	world.X={}
	world.y={}
	world.Y={}
	world.z={}
	world.Z={}
	local X,Y,Z=unpack(world.p)
	for x=1,CHUNK_SIZE do
		for y=1,CHUNK_SIZE do
			for z=1,CHUNK_SIZE do
				local p = {packBits(lshift(x + y * CHUNK_SIZE + z * CHUNK_SIZE^2-1-CHUNK_SIZE-CHUNK_SIZE^2,bitsPerD))}
				if world[d3dToLine(x,y,z)]>0 then
					if checkWorld(x+1,y,z,X,Y,Z)==0 then
						tI(world.X,p)
					end
					if checkWorld(x-1,y,z,X,Y,Z)==0 then
						tI(world.x,p)
					end
					---[[
					if checkWorld(x,y-1,z,X,Y,Z)==0 then
						tI(world.y,p)
					end
					if checkWorld(x,y+1,z,X,Y,Z)==0 then
						tI(world.Y,p)
					end
					if checkWorld(x,y,z-1,X,Y,Z)==0 then
						tI(world.z,p)
					end
					if checkWorld(x,y,z+1,X,Y,Z)==0 then
						tI(world.Z,p)
					end
					--]]
				end
			end
		end
	end
	world.fx:setVertices(world.x)
	world.fX:setVertices(world.X)
	world.fy:setVertices(world.y)
	world.fY:setVertices(world.Y)
	world.fz:setVertices(world.z)
	world.fZ:setVertices(world.Z)
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
