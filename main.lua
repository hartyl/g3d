-- written by groverbuger for g3d
-- MIT license

local lg = love.graphics
Winw, Winh = lg.getDimensions()
local rad = 8
local circle = lg.newCanvas(rad,rad,{format="r8"})
lg.setCanvas(circle)
for x=.5,rad+.5 do
	for y=.5,rad+.5 do
		-- lg.setColor(1,1,1,)
		local dist = math.sqrt(x*x+y*y)/rad
		lg.setColor(math.cos(dist*math.pi/2),1,1,1)
		lg.rectangle("fill",x,y,1,1)
	end
end
lg.setColor(1,1,1,1)
-- lg.rectangle("line",-1,-1,rad+1,rad+1)
lg.setCanvas()
circle = lg.newImage(circle:newImageData())
circle:setWrap("mirroredrepeat","mirroredrepeat")
local g3d = require "g3d"
local house = g3d.newModel("assets/house.obj")
local person = g3d.newModel("assets/microPerson.obj", nil, {0,10,0})
local person2 = g3d.newModel("assets/littlePerson.obj", nil, {0,0,0})
local moon = g3d.newModel("assets/dome.obj", circle, {0,10,0}, nil, 0.5)
local flat = g3d.newModel("assets/plane.obj", circle, {0,0,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 1000)
local floor = g3d.newModel("assets/plane.obj", "assets/earth.png", nil, nil, 1000)
local timer = 0
local bill = lg.newShader("g3d/billboard.vert", "g3d/cut.frag")
bill:send("projectionMatrix", g3d.camera.projectionMatrix)
local dbill = lg.newShader"g3d/depthboard.glsl"
dbill:send("projectionMatrix", g3d.camera.projectionMatrix)
-- moon.shader = lg.newShader("g3d/billboard.vert",[[
moon.shader = lg.newShader("g3d/depthboard.glsl",[[
varying vec2 texCoord;
varying vec3 worldPosition;
varying vec3 cameraForward;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(tex, texCoord);
	if (texcolor.x < .10)
		discard;
	if (worldPosition.z<-.5)
		return vec4(vec3(.5),1);
    return vec4(1);
}
]] )
moon.shader:send("projectionMatrix", g3d.camera.projectionMatrix)
-- house.shader = bill
person.shader = lg.newShader'scripts/bone.vert'
person.shader:send("projectionMatrix", g3d.camera.projectionMatrix)
g3d.shader:send("projectionMatrix", g3d.camera.projectionMatrix)

function love.update(dt)
    timer = timer + dt
    --moon:setTranslation(math.cos(timer)*5 + 4, math.sin(timer)*5, math.sin(timer*2)*5)
    moon:setRotation(0, 0, timer - math.pi/2)
    g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
    if love.keyboard.isDown "r" then
		g3d.camera.position = {0,0,0}
    end
end

house.positions = {}
for y=1,10 do
	for x=1,10 do
		house.positions[(y-1)*10+x] = {x*2 + math.floor((x+1)/2),y*2 + math.floor(y/3),0,1}
	end
end

house:instanciate(house.positions)
-- person.spheres[1]={p[1]+4,p[2]+5,p[3]+6,person.spheres[1][4]}
local p2 = person.spheres[2]
local spheres1 = moon:instanciate(person.spheres, false)
local spheres2 = moon:instanciate(person2.spheres, false)
local p = person.spheres[1]
spheres1:setVertices({{p[1]+4,p[2]+5,p[3]+6,p[4]*-100},{p2[1]+1,p2[2]+2,p2[3]+3,p2[4]}})
person.shader:send('bonePos', {1,2,3},{4,5,6})

function love.draw()
	g3d.shaderPrepare(bill)
	g3d.shaderDepthBillPrepare(dbill)
	g3d.shaderPrepare(g3d.shader)
	-- g3d.shaderPrepare(moon.shader)
	g3d.shaderDepthBillPrepare(moon.shader)
	g3d.shaderPrepare(person.shader)
    house:drawInstanced(nil,house.instances)
    moon:drawBillboard()
	floor:draw()
	person:draw()
	moon:reinstanciate(spheres1)
	moon.translation = person.translation
	moon:drawBillboardInstanced()
	person2:draw()
	moon:reinstanciate(spheres2)
	moon.translation = person2.translation
	moon:drawBillboardInstanced()
	lg.setMeshCullMode("none")
	background:setTranslation(unpack(g3d.camera.position))
	background:draw()
	lg.setMeshCullMode("back")
    lg.setShader()
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end
