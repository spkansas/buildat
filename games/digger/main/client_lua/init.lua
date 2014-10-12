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

local scene = replicate.main_scene

magic.input:SetMouseVisible(false)

-- Add a node that the player can use to walk around with
local player_node = scene:CreateChild("Player")
player_node.position = magic.Vector3(55, 30, 40)
local body = player_node:CreateComponent("RigidBody")
--body.mass = 70.0
local shape = player_node:CreateComponent("CollisionShape")
shape:SetBox(magic.Vector3(1, 1.7, 1))

local other_node = scene:CreateChild("Other")
other_node.position = magic.Vector3(0, 10, 0)
local body = other_node:CreateComponent("RigidBody")
body.mass = 0
--body.friction = 0.7
local shape = other_node:CreateComponent("CollisionShape")
shape:SetBox(magic.Vector3(50, 1, 50))

--[[
-- Add a camera so we can look at the scene
local camera_node = scene:CreateChild("Camera")
camera_node.position = magic.Vector3(70.0, 50.0, 70.0)
camera_node:LookAt(magic.Vector3(0, -5, 0))
local camera = camera_node:CreateComponent("Camera")
camera.nearClip = 1.0
camera.farClip = 500.0
--]]

-- Add a camera so we can look at the scene
local camera_node = player_node:CreateChild("Camera")
camera_node.position = magic.Vector3(0, 0.7, 0)
--camera_node:LookAt(magic.Vector3(30, 10, 0))
camera_node:LookAt(magic.Vector3(30, 20, 40))
local camera = camera_node:CreateComponent("Camera")
camera.nearClip = 1.0
camera.farClip = 500.0

-- And this thing so the camera is shown on the screen
local viewport = magic.Viewport:new(scene, camera_node:GetComponent("Camera"))
magic.renderer:SetViewport(0, viewport)

voxelworld.set_camera(camera_node)

-- Add some text
local title_text = magic.ui.root:CreateChild("Text")
title_text:SetText("digger/init.lua")
title_text:SetFont(magic.cache:GetResource("Font", "Fonts/Anonymous Pro.ttf"), 15)
title_text.horizontalAlignment = magic.HA_CENTER
title_text.verticalAlignment = magic.VA_CENTER
title_text:SetPosition(0, -magic.ui.root.height/2 + 20)

magic.ui:SetFocusElement(nil)

magic.SubscribeToEvent("KeyDown", function(event_type, event_data)
	local key = event_data:GetInt("Key")
	if key == magic.KEY_ESC then
		log:info("KEY_ESC pressed")
		buildat.disconnect()
	end
end)

magic.SubscribeToEvent("Update", function(event_type, event_data)
	if player_node then
		local dmouse = magic.input:GetMouseMove()
		--log:info("dmouse: ("..dmouse.x..", "..dmouse.y..")")
		camera_node:Pitch(dmouse.y * 0.1)
		player_node:Yaw(dmouse.x * 0.1)

		local MOVE_AMOUNT = event_data:GetFloat("TimeStep") * 20.0
		if magic.input:GetKeyDown(magic.KEY_W) then
			player_node:Translate(magic.Vector3( 1, 0, 0) * MOVE_AMOUNT)
		end
		if magic.input:GetKeyDown(magic.KEY_S) then
			player_node:Translate(magic.Vector3(-1, 0, 0) * MOVE_AMOUNT)
		end
		if magic.input:GetKeyDown(magic.KEY_A) then
			player_node:Translate(magic.Vector3( 0, 0, 1) * MOVE_AMOUNT)
		end
		if magic.input:GetKeyDown(magic.KEY_D) then
			player_node:Translate(magic.Vector3( 0, 0,-1) * MOVE_AMOUNT)
		end
		if magic.input:GetKeyDown(magic.KEY_SPACE) then
			player_node:Translate(magic.Vector3( 0, 1, 0) * MOVE_AMOUNT)
		end
		if magic.input:GetKeyDown(magic.KEY_SHIFT) then
			player_node:Translate(magic.Vector3( 0,-1, 0) * MOVE_AMOUNT)
		end
	end
end)

function setup_simple_voxel_data(node)
	local data = node:GetVar("simple_voxel_data"):GetBuffer()
	local w = node:GetVar("simple_voxel_w"):GetInt()
	local h = node:GetVar("simple_voxel_h"):GetInt()
	local d = node:GetVar("simple_voxel_d"):GetInt()
	log:info(dump(node:GetName()).." voxel data size: "..data:GetSize())
	buildat.set_8bit_voxel_geometry(node, w, h, d, data)
	node:SetScale(magic.Vector3(1, 1, 1))
end

replicate.sub_sync_node_added({}, function(node)
	if not node:GetVar("simple_voxel_data"):IsEmpty() then
		setup_simple_voxel_data(node)
	end
	local name = node:GetName()
end)

-- vim: set noet ts=4 sw=4:
