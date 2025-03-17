return function (g3d)
	local cube = {}
	for x=0,1 do
		for y=0,1 do
			for z=0,1 do
				cube[#cube+1] = {x,y,z}
			end
		end
	end
	local wallx = g3d.newModel(cube)
	wallx.mesh:setVertexMap({1,2,3,4})
	wallx.mesh:setDrawMode('strip')
	local wallX = g3d.newModel(cube)
	wallX.mesh:setVertexMap({7,8,5,6})
	wallX.mesh:setDrawMode('strip')
	local wally = g3d.newModel(cube)
	wally.mesh:setVertexMap({5,6,1,2})
	wally.mesh:setDrawMode('strip')
	local wallY = g3d.newModel(cube)
	wallY.mesh:setVertexMap({3,4,7,8})
	wallY.mesh:setDrawMode('strip')
	local wallz = g3d.newModel(cube)
	wallz.mesh:setVertexMap({1,3,5,7})
	wallz.mesh:setDrawMode('strip')
	local wallZ = g3d.newModel(cube)
	wallZ.mesh:setVertexMap({6,8,2,4})
	wallZ.mesh:setDrawMode('strip')
	return wallx, wallX, wally, wallY, wallz, wallZ
end
