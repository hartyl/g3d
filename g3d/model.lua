-- written by groverbuger for g3d
-- MIT license

local newMatrix = require(g3d.path .. ".matrices")
local loadObjFile = require(g3d.path .. ".objloader")
local collisions = require(g3d.path .. ".collisions")
local vectors = require(g3d.path .. ".vectors")
local camera = require(g3d.path .. ".camera")
local vectorCrossProduct = vectors.crossProduct
local vectorNormalize = vectors.normalize

local lg = love.graphics

----------------------------------------------------------------------------------------------------
-- define a model class
----------------------------------------------------------------------------------------------------

local model = {}
model.__index = model

-- define some default properties that every model should inherit
-- that being the standard vertexFormat and basic 3D shader
model.vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
    {"VertexNormal", "float", 3},
    {"VertexColor", "byte", 4},
    {"groupId", "float", 1},
}
model.shader = g3d.shader
model.instanceShader = g3d.instanceShader

-- this returns a new instance of the model class
-- a model must be given a .obj file or equivalent lua table, and a texture
-- translation, rotation, and scale are all 3d vectors and are all optional
local function newModel(verts, texture, translation, rotation, scale)
    local self = setmetatable({}, model)
    local map

    -- if verts is a string, use it as a path to a .obj file
    -- otherwise verts is a table, use it as a model defintion
    if type(verts) == "string" then
		local spheres
        verts, map, spheres = loadObjFile(verts)
		self.spheres = #spheres>0 and spheres or nil
    end

    -- if texture is a string, use it as a path to an image file
    -- otherwise texture is already an image, so don't bother
    if type(texture) == "string" then
        texture = lg.newImage(texture)
    end

    -- initialize my variables
    self.verts = verts
    self.texture = texture
    self.mesh = lg.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
    if map then
        self.mesh:setVertexMap(map)
    end
    self.matrix = newMatrix()
    if type(scale) == "number" then scale = {scale, scale, scale} end
    self:setTransform(translation or {0,0,0}, rotation or {0,0,0}, scale or {1,1,1})

    return self
end

-- populate model's normals in model's mesh automatically
-- if true is passed in, then the normals are all flipped
function model:makeNormals(isFlipped)
    for i=1, #self.verts, 3 do
        if isFlipped then
            self.verts[i+1], self.verts[i+2] = self.verts[i+2], self.verts[i+1]
        end

        local vp = self.verts[i]
        local v = self.verts[i+1]
        local vn = self.verts[i+2]

        local n_1, n_2, n_3 = vectorNormalize(vectorCrossProduct(v[1]-vp[1], v[2]-vp[2], v[3]-vp[3], vn[1]-v[1], vn[2]-v[2], vn[3]-v[3]))
        vp[6], v[6], vn[6] = n_1, n_1, n_1
        vp[7], v[7], vn[7] = n_2, n_2, n_2
        vp[8], v[8], vn[8] = n_3, n_3, n_3
    end

    self.mesh = lg.newMesh(self.vertexFormat, self.verts, "triangles")
    self.mesh:setTexture(self.texture)
end

-- move and rotate given two 3d vectors
function model:setTransform(translation, rotation, scale)
    self.translation = translation or self.translation
    self.rotation = rotation or self.rotation
    self.scale = scale or self.scale
    self:updateMatrix()
end

-- move given one 3d vector
function model:setTranslation(tx,ty,tz)
    self.translation[1] = tx
    self.translation[2] = ty
    self.translation[3] = tz
    self:updateMatrix()
end

-- rotate given one 3d vector
-- using euler angles
function model:setRotation(rx,ry,rz)
    self.rotation[1] = rx
    self.rotation[2] = ry
    self.rotation[3] = rz
    self.rotation[4] = nil
    self:updateMatrix()
end

-- create a quaternion from an axis and an angle
function model:setAxisAngleRotation(x,y,z,angle)
    x,y,z = vectorNormalize(x,y,z)
    angle = angle / 2

    self.rotation[1] = x * math.sin(angle)
    self.rotation[2] = y * math.sin(angle)
    self.rotation[3] = z * math.sin(angle)
    self.rotation[4] = math.cos(angle)

    self:updateMatrix()
end

-- rotate given one quaternion
function model:setQuaternionRotation(x,y,z,w)
    self.rotation[1] = x
    self.rotation[2] = y
    self.rotation[3] = z
    self.rotation[4] = w
    self:updateMatrix()
end

-- resize model's matrix based on a given 3d vector
function model:setScale(sx,sy,sz)
    self.scale[1] = sx
    self.scale[2] = sy or sx
    self.scale[3] = sz or sx
    self:updateMatrix()
end

-- update the model's transformation matrix
function model:updateMatrix()
    local p = camera.position
    self.matrix:setTransformationMatrix(
        {vectors.add(-p[1], -p[2],-p[3],unpack(self.translation))},
        self.rotation,
        self.scale)
end

-- update model's matrix position
function model:updateMatrixTranslation()
    local p = camera.position
    local m = self.matrix
    local t = self.translation
    m[4], m[8], m[12] = t[1]-p[1], t[2]-p[2],t[3]-p[3]
end

-- align's the model matrix to a given point
-- up vector is assumed to be normalized
function model:lookAtFrom(pos, target, up)
    local pos = pos or self.translation
    self.matrix:lookAtFrom(pos, target, up or {0,0,1}, self.scale)
end

function model:lookAt(target, up)
    self.matrix:lookAtFrom(self.translation, target, up or {0,0,1}, self.scale)
end


-- draw the model
function model:draw(shader)
    local shader = shader or self.shader
    lg.setShader(shader)
    self:updateMatrixTranslation()
    shader:send("modelMatrix", self.matrix)
	-- shader:send("isCanvasEnabled", lg.getCanvas() ~= nil)
    lg.draw(self.mesh)
end


function model:instanciate(positions, notattach)
	self.instanceMesh = love.graphics.newMesh({{"InstancePosition", "float", 4}}, positions, nil, "dynamic")
	self.positions = positions
	if not notattach then
		self.mesh:attachAttribute("InstancePosition", self.instanceMesh, "perinstance")
	end
	return self.instanceMesh
end
function model:reinstanciate(mesh)
	self.instanceMesh = mesh
	self.mesh:attachAttribute("InstancePosition", mesh, "perinstance")
end

function model:drawInstanced(shader)
    local shader = shader or self.shader
    lg.setShader(shader)
	local instanceMesh = self.instanceMesh
	self.mesh:attachAttribute("InstancePosition", instanceMesh, "perinstance")
    self:updateMatrixTranslation()
    shader:send("modelMatrix", self.matrix)
	shader:send("isCanvasEnabled", lg.getCanvas() ~= nil)
    lg.drawInstanced(self.mesh,instanceMesh:getVertexCount())--(#self.positions)
    lg.setShader()
end

function model:drawBillboard(shader)
    local shader = shader or self.shader
    lg.setShader(shader)
	shader:send("isCanvasEnabled", lg.getCanvas() ~= nil)
    shader:send("translation", {vectors.add(-camera.position[1], -camera.position[2],-camera.position[3],unpack(self.translation))})
    lg.draw(self.mesh)
    lg.setShader()
end

function model:drawBillboardInstanced(shader)
	local instanceMeshN = self.instanceMesh:getVertexCount()
    local shader = shader or self.shader
    lg.setShader(shader)
	shader:send("isCanvasEnabled", lg.getCanvas() ~= nil)
    shader:send("translation", {vectors.add(-camera.position[1], -camera.position[2],-camera.position[3],unpack(self.translation))})
    lg.drawInstanced(self.mesh,instanceMeshN)--(#self.positions)
    lg.setShader()
end
function model:drawMultiple(shader, positions)
    local shader = shader or self.shader
    lg.setShader(shader)
	local instanceMesh = love.graphics.newMesh({{"InstancePosition", "float", 3}}, positions, nil, "static")
	self.mesh:attachAttribute("InstancePosition", instanceMesh, "perinstance")
    shader:send("modelMatrix", self.matrix)
    if shader:hasUniform "isCanvasEnabled" then
        shader:send("isCanvasEnabled", lg.getCanvas() ~= nil)
    end
    lg.drawInstanced(self.mesh,#positions)
	instanceMesh:release()
    lg.setShader()
end

-- local prepared = {}
local function shaderPrepare(shader)
    shader:send("viewMatrix", {
        camera.viewMatrix[1],camera.viewMatrix[2],camera.viewMatrix[3],
        camera.viewMatrix[5],camera.viewMatrix[6],camera.viewMatrix[7],
        camera.viewMatrix[9],camera.viewMatrix[10],camera.viewMatrix[11],
})
    -- if not prepared[shader] then
        -- prepared[shader] = true
        -- shader:send("projectionMatrix", camera.projectionMatrix)
    -- end
end
g3d.shaderPrepare = shaderPrepare
function g3d.shaderDepthBillPrepare(shader)
	local camDir, camPit = camera.getDirectionPitch()
	local cosPitch = math.cos(camPit)
	local sinPitch = math.sin(camPit)
	local ax, ay = -math.sin(camDir), math.cos(camDir)
    --  local camFor = {
    --  	ay*cosPitch,
    --  	-ax*cosPitch,
    --  	sinPitch,
    --  }
	local camUp = {
		ay*sinPitch,
		-ax*sinPitch,
		-cosPitch,
	}
    shader:send("cameraUp", camUp)
    -- shader:send("cameraForward", camFor)
    -- shader:send("cameraPos", camera.position)
    -- shader:send("cameraRight", {ax,ay})
	shaderPrepare(shader)
end

-- the fallback function if ffi was not loaded
function model:compress()
    print("[g3d warning] Compression requires FFI!\n" .. debug.traceback())
end

-- makes models use less memory when loaded in ram
-- by storing the vertex data in an array of vertix structs instead of lua tables
-- requires ffi
-- note: throws away the model's verts table
local success, ffi = pcall(require, "ffi")
if success then
    ffi.cdef([[
        struct vertex {
            float x, y, z;
            float u, v;
            float nx, ny, nz;
            uint8_t r, g, b, a;
        }
    ]])

    function model:compress()
        local data = love.data.newByteData(ffi.sizeof("struct vertex") * #self.verts)
        local datapointer = ffi.cast("struct vertex *", data:getFFIPointer())

        for i, vert in ipairs(self.verts) do
            local dataindex = i - 1
            datapointer[dataindex].x  = vert[1]
            datapointer[dataindex].y  = vert[2]
            datapointer[dataindex].z  = vert[3]
            datapointer[dataindex].u  = vert[4] or 0
            datapointer[dataindex].v  = vert[5] or 0
            datapointer[dataindex].nx = vert[6] or 0
            datapointer[dataindex].ny = vert[7] or 0
            datapointer[dataindex].nz = vert[8] or 0
            datapointer[dataindex].r  = (vert[9] or 1)*255
            datapointer[dataindex].g  = (vert[10] or 1)*255
            datapointer[dataindex].b  = (vert[11] or 1)*255
            datapointer[dataindex].a  = (vert[12] or 1)*255
        end

        self.mesh:release()
        self.mesh = lg.newMesh(self.vertexFormat, #self.verts, "triangles")
        self.mesh:setVertices(data)
        self.mesh:setTexture(self.texture)
        self.verts = nil
    end
end

function model:rayIntersection(...)
    return collisions.rayIntersection(self.verts, self, ...)
end

function model:isPointInside(...)
    return collisions.isPointInside(self.verts, self, ...)
end

function model:sphereIntersection(...)
    return collisions.sphereIntersection(self.verts, self, ...)
end

function model:closestPoint(...)
    return collisions.closestPoint(self.verts, self, ...)
end

function model:capsuleIntersection(...)
    return collisions.capsuleIntersection(self.verts, self, ...)
end

return newModel
