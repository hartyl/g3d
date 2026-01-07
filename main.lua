-- written by groverbuger for g3d
-- MIT license

local lg = love.graphics
local lki = love.keyboard.isDown
local floor, ceil, abs, random, cos,sin,pi =
math.floor,math.ceil,math.abs,math.random,math.cos,math.sin,math.pi
Winw, Winh = lg.getDimensions()
local rad = 4
local circle = lg.newCanvas(rad,rad,{format="r8"})
lg.setCanvas(circle)
local start = .5--1.5
local e = rad
for x=start,e do
	for y=start,e do
		-- lg.setColor(1,1,1,)
		local dist = (x*x+y*y)^.5/rad
		lg.setColor(cos(dist*pi/2),1,1,1)
		lg.rectangle("fill",x,y,1,1)
	end
end
lg.setColor(0,1,1,1)
-- lg.rectangle("line",-1,-1,rad+1,rad+1)
lg.setCanvas()
circle = lg.newImage(circle:newImageData())
circle:setWrap("mirroredrepeat","mirroredrepeat")
local g3d = require "g3d"
local house = g3d.newModel("assets/house.obj")
local person = g3d.newModel("assets/microPerson.obj", nil, {0,10,0})
local person2 = g3d.newModel("assets/littlePerson.obj", nil, {0,0,0})
local moon = g3d.newModel("assets/circle.obj", circle, {0,10,0}, nil, 0.5)
local flat = g3d.newModel("assets/plane.obj", circle, {0,0,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, g3d.camera.farClip)
local plane = g3d.newModel("assets/plane.obj", "assets/earth.png", nil, nil, g3d.camera.farClip)
local timer = 0
local bill = lg.newShader("g3d/billboard.vert", "g3d/cut.frag")
bill:send("projectionMatrix", g3d.camera.projectionMatrix)
local dbill = lg.newShader"g3d/depthboard.glsl"
dbill:send("projectionMatrix", g3d.camera.projectionMatrix)
-- moon.shader = lg.newShader("g3d/depthboard.glsl",[[
local cloudShader = lg.newShader([[
varying vec2 texCoord;
attribute vec4 InstancePosition;
uniform lowp mat4 projectionMatrix;
uniform mat3 viewMatrix;

uniform vec3 translation;
uniform bool isCanvasEnabled;

varying vec3 worldPosition;
varying vec3 viewPosition;
varying vec4 screenPosition;
varying vec3 cameraForward;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
	vec3 pos = vec3(InstancePosition.xy+translation.xy,0);
	pos.xy = mod(pos.xy+2000,4000)-2000;
	float l = length(pos.xy);
	pos.z = length(InstancePosition.zw)+translation.z+100*(1-l/2000);
	cameraForward = pos/l;
	viewPosition = viewMatrix * pos;
	viewPosition.xy += vertexPosition.xy * 32;//*(1-l/2000*3);
	screenPosition = projectionMatrix * vec4(viewPosition,1);
	texCoord = vertexPosition.xy;
	return screenPosition;
}
]]
,[[
varying vec2 texCoord;
varying vec3 cameraForward;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	// vec4 texcolor = Texel(tex, vec2(max(texCoord.x,texCoord.y),min(texCoord.x,texCoord.y))*2);
	vec4 texcolor = Texel(tex, texCoord/8.1*7);
	if (texcolor.x < .20)
		discard;
		// return vec4(vec3(0),1);
	if (texCoord.y- texcolor.x*cameraForward.z*3<0)
		return vec4(vec3(.5),1);
	return vec4(1);
}
]] )
moon.shader = cloudShader
moon.shader:send("projectionMatrix", g3d.camera.projectionMatrix)
-- house.shader = bill
person.shader = lg.newShader'scripts/bone.vert'
person.shader:send("projectionMatrix", g3d.camera.projectionMatrix)
g3d.shader:send("projectionMatrix", g3d.camera.projectionMatrix)


house.positions = {}
for y=1,10 do
	for x=1,10 do
		house.positions[(y-1)*10+x] = {x*2 + floor((x+1)/2),y*2 + floor(y/3),0,1}
	end
end

house:instanciate(house.positions)
-- person.spheres[1]={p[1]+4,p[2]+5,p[3]+6,person.spheres[1][4]}
local p2 = person.spheres[2]
local spheres1 = moon:instanciate(person.spheres, true)
local spheres2 = moon:instanciate(person2.spheres, true)
local p = person.spheres[1]
-- spheres1:setVertices({{p[1]+4,p[2]+5,p[3]+6,p[4]*-100},{p2[1]+1,p2[2]+2,p2[3]+3,p2[4]}})
spheres1:setVertices({{0,0,0,1},{p2[1]+1,p2[2]+2,p2[3]+3,p2[4]}})
person.shader:send('bonePos', {1,2,3},{4,5,6})

local clouds
local cloudsN = 2000
local range = g3d.camera.farClip
local c = {}
--	local size = 30
--	local density = {}
--	for y=0,size do
--		density[y]={}
--		for x=0,size do
--			density[y][x]=0
--		end
--	end
local points = {}
if true then
for i=1,20 do
	points[i] = {random(-range,range), random(-range,range)}
end
for i=1,cloudsN do
	local xp,yp = unpack(points[i%#points+1])
	--	local xP, yP = xp/16+.5, yp/16.5
		--	for Y=floor(yP),ceil(yP) do
		--		local d = density[Y%size]
		--		for X=floor(xP),ceil(xP) do
		--			local dist = ((xP-X)^2+(yP-Y)^2)^.5*16
		--			dist = dist == 0 and 0 or 1/dist
		--			d[X%size] = d[X%size]+1
		--		end
		--	end
	c[i] = {xp+random(-200,200),yp+random(-200,200),0,0}
end
clouds = moon:instanciate(c)
end
local camera = g3d.camera
local pos = camera.position
local id = 0
local init = 00000
local lol = 0
local pid = 0
function love.update(dt)
	lol = lol + (love.keyboard.isDown'o' and 1 or 0) + (love.keyboard.isDown'l' and -1 or 0)
	timer = timer + dt
	--moon:setTranslation(cos(timer)*5 + 4, sin(timer)*5, sin(timer*2)*5)
	moon:setRotation(0, 0, timer - pi/2)
	g3d.camera.firstPersonMovement(dt)
	if love.keyboard.isDown "escape" then
		love.event.push "quit"
	end
	if love.keyboard.isDown "r" then
		g3d.camera.position = {0,0,0}
	end
	local range2 = range*2
	for _=1,init do
		id = (id)%(cloudsN-1)+1
		local i1 = id
		local pid = id%#points+1
		local pp = random(0,1)==0 and #points or 1
		local i2 = (i1+pp*random(cloudsN/pp)-1)%cloudsN+1
		local xp, yp, xSpd, ySpd = clouds:getVertex(i1)
		local xp2, yp2, xSpd2, ySpd2 = clouds:getVertex(i2)
		xp2 = (abs(xp-xp2)>range and (xp2<=0 and xp2+range2 or xp2-range2) or xp2)
		yp2 = (abs(yp-yp2)>range and (yp2<=0 and yp2+range2 or yp2-range2) or yp2)
		local p = points[pid]
		local px, py = unpack(p)
		px = (abs(xp-px)>range and (px<=0 and px+range2 or px-range2) or px)
		py = (abs(yp-py)>range and (py<=0 and py+range2 or py-range2) or py)
		--	local den = lol/100+3
		--	local xP, yP = xp/16+.5, yp/16.5
		--	for Y=floor(yP),ceil(yP) do
		--		local d = density[Y%size]
		--		for X=floor(xP),ceil(xP) do
		--			local dist = ((xP-X)^2+(yP-Y)^2)^.5*16
		--			dist = dist == 0 and 0 or 1/dist
		--			d[X%size] = d[X%size]-1
		--			den = den + d[X%size]
		--		end
		--	end
		-- + pi/6*random(-1,1)
		--
		--	local d_1 = density[(y-1)%size]
		--	local y0,y1 = floor(yP), ceil(yP)
		--	local d0 = density[y0%size]
		--	local d1 = density[y1%size]
		--	local x0,x1 = floor(xP), ceil(xP)
		--	local x0s, x1s = x0%size,x1%size
		--	local c0,c1,c2,c3 =
		--	((x0-xP)^2+(y0-yP)^2)^.5-1,
		--	((x1-xP)^2+(y0-yP)^2)^.5-1,
		--	((x0-xP)^2+(y1-yP)^2)^.5-1,
		--	((x1-xP)^2+(y1-yP)^2)^.5-1
		--	c0,c1,c2,c3 =
		--	c0<1 and 2^-6 or 1/c0,
		--	c1<1 and 2^-6 or 1/c1,
		--	c2<1 and 2^-6 or 1/c2,
		--	c3<1 and 2^-6 or 1/c3
		--
		--	local _x_y,x_y,_xy,xy =
		--	abs(d0[x0s] - den)*c0,
		--	abs(d0[x1s] - den)*c1,
		--	abs(d1[x0s] - den)*c2,
		--	abs(d1[x1s] - den)*c3
		-- local spd = .995
		local di2 = ((xp2-xp)^2+(yp2-yp)^2)^.5 -200
		di2 = di2 < 1 and -1/200 or 2^-5/di2
		local r = 2^((lki'g' and -10 or -12)-lol/100+sin(timer/100))
		xSpd,ySpd =
		 -- (xSpd - (-_x_y-_xy+x_y+xy)*0)*spd+
		0.9*xSpd+
		 random(-32,32)/2^9 + (xp2 - xp + xSpd2) * di2
		 - (xp-px) * r
		,--(ySpd - (-_x_y+_xy-x_y+xy)*0)*spd+
		0.9*ySpd+
		random(-32,32)/2^9 + (yp2 - yp + ySpd2) * di2
		 - (yp-py) * r

		xp,yp = xp +xSpd ,yp + ySpd

		-- clamp at place
		--	local range = range/4
		local cx, cy = pos[1],pos[2]
		cx, cy =
		(cx + range)%range2-range,
		(cy + range)%range2-range
		cx = (abs(xp-cx)>range and (cx<=0 and cx+range2 or cx-range2) or cx)
		cy = (abs(yp-cy)>range and (cy<=0 and cy+range2 or cy-range2) or cy)
		local dd2 = (xp-cx)^2+(yp-cy)^2 > (range)^2 and 1.95 or 0
		xp, yp = xp+(cx-xp)*dd2, yp+(cy-yp)*dd2
		--	local precision = 2^32
		-- xp, yp = (floor(xp*precision+.5)/precision+size*8) % (size*16)-size*8,(floor(yp*precision+.5)/precision+size*8) % (size*16)-size*8
		--	xp, yp =
		--	(floor(xp*precision+.5)/precision+range*.5) % (range)-range*.5,
		--	(floor(yp*precision+.5)/precision+range*.5) % (range)-range*.5
		xp, yp =
		(xp+range) % range2-range,
		(yp+range) % range2-range
		-- xp,yp=(xp+size*8)%(size*16)-size*8,yp%(size*16)
		--	xP, yP = xp/16+.5, yp/16.5
		--	for Y=floor(yP),ceil(yP) do
		--		local d = density[Y%size]
		--		for X=floor(xP),ceil(xP) do
		--			local dist = ((xP-X)^2+(yP-Y)^2)^.5*16
		--			dist = dist == 0 and 0 or 1/dist
		--			d[X%size] = d[X%size]+1
		--		end
		--	end
		-- xp,yp=(xp-pos[1]+range)%(range*2)+pos[1]-range,(yp-pos[2]+range)%(range*2)+pos[2]-range

		clouds:setVertex(i1, {xp,yp, xSpd, ySpd})
	end

	pid=pid%#points+1
	local p = points[pid]
	local r = random(100)>99 and 100 or 10
	p[1] = (p[1]+range + random(-r,r))%range2-range
	p[2] = (p[2]+range + random(-r,r))%range2-range

	init = cloudsN/100
end

function love.draw()
	g3d.shaderPrepare(bill)
	g3d.shaderDepthBillPrepare(dbill)
	g3d.shaderPrepare(g3d.shader)
	g3d.shaderPrepare(cloudShader)
	-- g3d.shaderPrepare(moon.shader)
	g3d.shaderDepthBillPrepare(moon.shader)
	g3d.shaderPrepare(person.shader)
	--	ready
	house:drawInstanced(nil,house.instances)
	person:draw()
	moon:reinstanciate(spheres1)
	moon.translation = person.translation
	moon:drawBillboardInstanced()
	person2:draw()
	moon:reinstanciate(spheres2)
	moon.translation = person2.translation
	moon:drawBillboardInstanced()
	moon.shader = cloudShader
	moon:reinstanciate(clouds)
	moon:drawBillboardInstanced()
	moon.shader = bill
	lg.setMeshCullMode("none")
	moon:drawBillboard()
	lg.setMeshCullMode("back")
	lg.setMeshCullMode("none")
	background:setTranslation(unpack(g3d.camera.position))
	background:draw()
	plane:draw()
	lg.setMeshCullMode("back")
	lg.setShader()
	lg.setColor(.75,.75,.5,1)
	--	local out = ""
	--	for y=0, size do
	--		for x=0, size do
	--			-- local c = floor(density[y][x]+.5)
	--			-- local c = (density[y][x])
	--			local c = floor(density[y][x]+.5)
	--			out = out .. (c == 0 and "  " or c < 0 and c or c > 0 and (" " .. c))  .. " "
	--		end
	--		out = out .. "\n"
	--	end
	--	lg.print(love.timer.getFPS())
	lg.print(lol)
	lg.push()
	lg.scale(.1)
	lg.translate(lg.getDimensions())
	lg.translate(lg.getDimensions())
	lg.points(points)
	lg.pop()
	lg.setColor(1,1,1,1)
end

function love.mousemoved(x,y, dx,dy)
	g3d.camera.firstPersonLook(dx,dy)
end
