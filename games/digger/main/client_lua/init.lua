-- Buildat: digger/client_lua/init.lua
-- http://www.apache.org/licenses/LICENSE-2.0
-- Copyright 2014 Perttu Ahola <celeron55@gmail.com>
-- Copyright 2014 Břetislav Štec <valsiterb@gmail.com>
local log = buildat.Logger("digger")
local dump = buildat.dump
local cereal = require("buildat/extension/cereal")
local magic = require("buildat/extension/urho3d")
local replicate = require("buildat/extension/replicate")
local voxelworld = require("buildat/module/voxelworld")

--local RENDER_DISTANCE = 640
local RENDER_DISTANCE = 480
--local RENDER_DISTANCE = 320
--local RENDER_DISTANCE = 240
--local RENDER_DISTANCE = 160

local FOG_END = RENDER_DISTANCE * 1.2

local PLAYER_HEIGHT = 1.7
local PLAYER_WIDTH = 0.9
local MOVE_SPEED = 10
local JUMP_SPEED = 7 -- Barely 2 voxels

local scene = replicate.main_scene

magic.input:SetMouseVisible(false)

-- Set up zone (global visual parameters)
---[[
do
	local zone_node = scene:CreateChild("Zone")
	local zone = zone_node:CreateComponent("Zone")
	zone.boundingBox = magic.BoundingBox(-1000, 1000)
	zone.ambientColor = magic.Color(0.1, 0.1, 0.1)
	--zone.ambientColor = magic.Color(0, 0, 0)
	zone.fogColor = magic.Color(0.6, 0.7, 0.8)
	--zone.fogColor = magic.Color(0, 0, 0)
	zone.fogStart = 10
	zone.fogEnd = FOG_END
	zone.priority = -1
	zone.override = true
end
--]]

-- Add lights
do
	--[[
	local dirs = {
		magic.Vector3( 1.0, -1.0,  1.0),
		magic.Vector3( 1.0, -1.0, -1.0),
		magic.Vector3(-1.0, -1.0, -1.0),
		magic.Vector3(-1.0, -1.0,  1.0),
	}
	for _, dir in ipairs(dirs) do
		local node = scene:CreateChild("DirectionalLight")
		node.direction = dir
		local light = node:CreateComponent("Light")
		light.lightType = magic.LIGHT_DIRECTIONAL
		light.castShadows = true
		light.brightness = 0.2
		light.color = magic.Color(0.7, 0.7, 1.0)
	end
	--]]

	local node = scene:CreateChild("DirectionalLight")
	node.direction = magic.Vector3(-0.6, -1.0, 0.8)
	local light = node:CreateComponent("Light")
	light.lightType = magic.LIGHT_DIRECTIONAL
	light.castShadows = true
	light.brightness = 0.8
	light.color = magic.Color(1.0, 1.0, 0.95)

	---[[
	local node = scene:CreateChild("DirectionalLight")
	node.direction = magic.Vector3(0.3, -1.0, -0.4)
	local light = node:CreateComponent("Light")
	light.lightType = magic.LIGHT_DIRECTIONAL
	light.castShadows = true
	light.brightness = 0.2
	light.color = magic.Color(0.7, 0.7, 1.0)
	--]]

	--[[
	local node = scene:CreateChild("DirectionalLight")
	node.direction = magic.Vector3(0.0, -1.0, 0.0)
	local light = node:CreateComponent("Light")
	light.lightType = magic.LIGHT_DIRECTIONAL
	light.castShadows = false
	light.brightness = 0.05
	light.color = magic.Color(1.0, 1.0, 1.0)
	--]]
end

-- Add a node that the player can use to walk around with
local player_node = scene:CreateChild("Player")
local player_shape = player_node:CreateComponent("CollisionShape")
do
	--player_node.position = magic.Vector3(0, 30, 0)
	--player_node.position = magic.Vector3(55, 30, 40)
	player_node.position = magic.Vector3(-5, 1, 257)
	player_node.direction = magic.Vector3(-1, 0, 0.4)
	--player_node:Yaw(-177.49858)
	---[[
	local body = player_node:CreateComponent("RigidBody")
	--body.mass = 70.0
	body.friction = 0
	--body.linearVelocity = magic.Vector3(0, -10, 0)
	body.angularFactor = magic.Vector3(0, 0, 0)
	body.gravityOverride = magic.Vector3(0, -15.0, 0) -- A bit more than normally
	--player_shape:SetBox(magic.Vector3(1, 1.7*PLAYER_SCALE, 1))
	player_shape:SetCapsule(PLAYER_WIDTH, PLAYER_HEIGHT)
	--]]
end

local player_touches_ground = false
local player_crouched = false

-- Add a camera so we can look at the scene
local camera_node = player_node:CreateChild("Camera")
do
	camera_node.position = magic.Vector3(0, 0.411*PLAYER_HEIGHT, 0)
	--camera_node:Pitch(13.60000)
	local camera = camera_node:CreateComponent("Camera")
	camera.nearClip = 0.5 * math.min(
			PLAYER_WIDTH * 0.15,
			PLAYER_HEIGHT * (0.5 - 0.411)
	)
	camera.farClip = RENDER_DISTANCE
	camera.fov = 75

	-- And this thing so the camera is shown on the screen
	local viewport = magic.Viewport:new(scene, camera_node:GetComponent("Camera"))
	magic.renderer:SetViewport(0, viewport)
end

-- Tell about the camera to the voxel world so it can do stuff based on the
-- camera's position and other properties
voxelworld.set_camera(camera_node)

---[[
-- Add a light to the camera
do
	local node = camera_node:CreateChild("Light")
	local light = node:CreateComponent("Light")
	light.lightType = magic.LIGHT_POINT
	light.castShadows = false
	light.brightness = 0.15
	light.color = magic.Color(1.0, 1.0, 1.0)
	light.range = 15.0
	light.fadeDistance = 15.0
end
--]]

-- Add some text
local title_text = magic.ui.root:CreateChild("Text")
local misc_text = magic.ui.root:CreateChild("Text")
do
	title_text:SetText("digger/init.lua")
	title_text:SetFont(magic.cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 15)
	title_text.horizontalAlignment = magic.HA_CENTER
	title_text.verticalAlignment = magic.VA_CENTER
	title_text:SetPosition(0, -magic.ui.root.height/2 + 20)

	misc_text:SetText("")
	misc_text:SetFont(magic.cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 15)
	misc_text.horizontalAlignment = magic.HA_CENTER
	misc_text.verticalAlignment = magic.VA_CENTER
	misc_text:SetPosition(0, -magic.ui.root.height/2 + 40)
end

-- Unfocus UI
magic.ui:SetFocusElement(nil)

magic.SubscribeToEvent("KeyDown", function(event_type, event_data)
	local key = event_data:GetInt("Key")
	if key == magic.KEY_ESC then
		log:info("KEY_ESC pressed")
		buildat.disconnect()
	end
end)

-- Return value: nil or buildat.Vector3
local function find_pointed_voxel()
end

magic.SubscribeToEvent("MouseButtonDown", function(event_type, event_data)
	local button = event_data:GetInt("Button")
	log:info("MouseButtonDown: "..button)
	if button == magic.MOUSEB_RIGHT then
		local p = player_node.position
		local data = cereal.binary_output({
			p = {
				x = math.floor(p.x+0.5),
				y = math.floor(p.y+0.5),
				z = math.floor(p.z+0.5),
			},
		}, {"object",
			{"p", {"object",
				{"x", "int32_t"},
				{"y", "int32_t"},
				{"z", "int32_t"},
			}},
		})
		buildat.send_packet("main:place_voxel", data)
	end
	if button == magic.MOUSEB_LEFT then
		local p = player_node.position
		local data = cereal.binary_output({
			p = {
				x = math.floor(p.x+0.5),
				y = math.floor(p.y+0.5 + 0.2),
				z = math.floor(p.z+0.5),
			},
		}, {"object",
			{"p", {"object",
				{"x", "int32_t"},
				{"y", "int32_t"},
				{"z", "int32_t"},
			}},
		})
		buildat.send_packet("main:dig", data)
	end
	if button == magic.MOUSEB_MIDDLE then
		local p = player_node.position
		local v = voxelworld.get_static_voxel(p)
		log:info("get_static_voxel("..buildat.Vector3(p):dump()..")"..
				" returned v.id="..dump(v.id))
	end
end)

magic.SubscribeToEvent("Update", function(event_type, event_data)
	--log:info("Update")
	if player_node then
		-- If falling out of world, restore onto world
		if player_node.position.y < -500 then
			player_node.position = magic.Vector3(0, 500, 0)
		end

		local dmouse = magic.input:GetMouseMove()
		--log:info("dmouse: ("..dmouse.x..", "..dmouse.y..")")
		camera_node:Pitch(dmouse.y * 0.1)
		player_node:Yaw(dmouse.x * 0.1)
		--[[log:info("y="..player_node:GetRotation():YawAngle())
		log:info("p="..camera_node:GetRotation():PitchAngle())]]

		local body = player_node:GetComponent("RigidBody")

		local wanted_v = magic.Vector3(0, 0, 0)

		if magic.input:GetKeyDown(magic.KEY_W) then
			wanted_v.x = wanted_v.x + 1
		end
		if magic.input:GetKeyDown(magic.KEY_S) then
			wanted_v.x = wanted_v.x - 1
		end
		if magic.input:GetKeyDown(magic.KEY_D) then
			wanted_v.z = wanted_v.z - 1
		end
		if magic.input:GetKeyDown(magic.KEY_A) then
			wanted_v.z = wanted_v.z + 1
		end

		if player_crouched then
			wanted_v = wanted_v:Normalized() * MOVE_SPEED / 2
		else
			wanted_v = wanted_v:Normalized() * MOVE_SPEED
		end

		if magic.input:GetKeyDown(magic.KEY_SPACE) or
				magic.input:GetKeyPress(magic.KEY_SPACE) then
			if player_touches_ground and
					math.abs(body.linearVelocity.y) < JUMP_SPEED then
				wanted_v.y = wanted_v.y + JUMP_SPEED
			end
		end
		if magic.input:GetKeyDown(magic.KEY_SHIFT) then
			--wanted_v.y = wanted_v.y - MOVE_SPEED

			-- Delay setting this to here so that it's possible to wait for the
			-- world to load first
			if body.mass == 0 then
				body.mass = 70.0
			end

			if not player_crouched then
				player_shape:SetCapsule(PLAYER_WIDTH, PLAYER_HEIGHT/2)
				camera_node.position = magic.Vector3(0, 0.411*PLAYER_HEIGHT/2, 0)
				player_crouched = true
			end
		else
			if player_crouched then
				player_shape:SetCapsule(PLAYER_WIDTH, PLAYER_HEIGHT)
				player_node:Translate(magic.Vector3(0, PLAYER_HEIGHT/4, 0))
				camera_node.position = magic.Vector3(0, 0.411*PLAYER_HEIGHT, 0)
				player_crouched = false
			end
		end

		local u = player_node.direction
		local v = u:CrossProduct(magic.Vector3(0, 1, 0))
		local bv = body.linearVelocity
		bv.x = 0
		bv.z = 0
		if wanted_v.y ~= 0 then
			bv.y = 0
		end
		bv = bv + u * wanted_v.x
		bv = bv + v * wanted_v.z
		bv = bv + magic.Vector3(0, 1, 0) * wanted_v.y
		body.linearVelocity = bv

		local p = player_node:GetWorldPosition()
		misc_text:SetText("("..math.floor(p.x + 0.5)..", "..
				math.floor(p.y + 0.5)..", "..math.floor(p.z + 0.5)..")")
	end

	player_touches_ground = false
end)

magic.SubscribeToEvent("PhysicsCollision", function(event_type, event_data)
	--log:info("PhysicsCollision")
	local node_a = event_data:GetPtr("Node", "NodeA")
	local node_b = event_data:GetPtr("Node", "NodeB")
	local contacts = event_data:GetBuffer("Contacts")
	if node_a:GetID() == player_node:GetID() or
			node_b:GetID() == player_node:GetID() then
		while not contacts.eof do
			local position = contacts:ReadVector3()
			local normal = contacts:ReadVector3()
			local distance = contacts:ReadFloat()
			local impulse = contacts:ReadFloat()
			--log:info("normal: ("..normal.x..", "..normal.y..", "..normal.z..")")
			if normal.y < 0.5 then
				player_touches_ground = true
			end
		end
	end
end)

function setup_simple_voxel_data(node)
	local voxel_reg = voxelworld.get_voxel_registry()
	local atlas_reg = voxelworld.get_atlas_registry()

	local data = node:GetVar("simple_voxel_data"):GetBuffer()
	local w = node:GetVar("simple_voxel_w"):GetInt()
	local h = node:GetVar("simple_voxel_h"):GetInt()
	local d = node:GetVar("simple_voxel_d"):GetInt()
	log:info(dump(node:GetName()).." voxel data size: "..data:GetSize())
	buildat.set_8bit_voxel_geometry(node, w, h, d, data, voxel_reg, atlas_reg)
	node:SetScale(magic.Vector3(1, 1, 1))
end

voxelworld.sub_ready(function()
	-- Subscribe to this only after the voxelworld is ready because we are using
	-- voxelworld's registries
	replicate.sub_sync_node_added({}, function(node)
		if not node:GetVar("simple_voxel_data"):IsEmpty() then
			setup_simple_voxel_data(node)
		end
		local name = node:GetName()
	end)
end)

-- vim: set noet ts=4 sw=4:
