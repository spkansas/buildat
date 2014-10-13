-- Buildat: builtin/voxelworld/client_lua/module.lua
-- http://www.apache.org/licenses/LICENSE-2.0
-- Copyright 2014 Perttu Ahola <celeron55@gmail.com>
local log = buildat.Logger("voxelworld")
local magic = require("buildat/extension/urho3d")
local replicate = require("buildat/extension/replicate")
local cereal = require("buildat/extension/cereal")
local dump = buildat.dump
local M = {}

local camera_node = nil
local update_counter = -1
local camera_last_dir = magic.Vector3(0, 0, 0)
local camera_last_p = magic.Vector3(0, 0, 0)

M.chunk_size_voxels = nil
M.section_size_chunks = nil
M.section_size_voxels = nil

--[[
	table.binsearch( table, value [, compval [, reversed] ] )

	Searches the table through BinarySearch for the given value.
	If the  value is found:
		it returns a table holding all the mathing indices (e.g. { startindice,endindice } )
		endindice may be the same as startindice if only one matching indice was found
	If compval is given:
		then it must be a function that takes one value and returns a second value2,
		to be compared with the input value, e.g.:
		compvalue = function( value ) return value[1] end
	If reversed is set to true:
		then the search assumes that the table is sorted in reverse order (largest value at position 1)
		note when reversed is given compval must be given as well, it can be nil/_ in this case
	Return value:
		on success: a table holding matching indices (e.g. { startindice,endindice } )
		on failure: nil
]]--
do
	-- Avoid heap allocs for performance
	local default_fcompval = function( value ) return value end
	local fcompf = function( a,b ) return a < b end
	local fcompr = function( a,b ) return a > b end
	function table_binsearch( t,value,fcompval,reversed )
		-- Initialise functions
		local fcompval = fcompval or default_fcompval
		local fcomp = reversed and fcompr or fcompf
		--  Initialise numbers
		local iStart,iEnd,iMid = 1,#t,0
		-- Binary Search
		while iStart <= iEnd do
			-- calculate middle
			iMid = math.floor( (iStart+iEnd)/2 )
			-- get compare value
			local value2 = fcompval( t[iMid] )
			-- get all values that match
			if value == value2 then
				local tfound,num = { iMid,iMid },iMid - 1
				while value == fcompval( t[num] ) do
					tfound[1],num = num,num - 1
				end
				num = iMid + 1
				while value == fcompval( t[num] ) do
					tfound[2],num = num,num + 1
				end
				return tfound
			-- keep searching
			elseif fcomp( value,value2 ) then
				iEnd = iMid - 1
			else
				iStart = iMid + 1
			end
		end
	end
end

--[[
	table.bininsert( table, value [, comp] )

	Inserts a given value through BinaryInsert into the table sorted by [, comp].

	If 'comp' is given, then it must be a function that receives
	two table elements, and returns true when the first is less
	than the second, e.g. comp = function(a, b) return a > b end,
	will give a sorted table, with the biggest value on position 1.
	[, comp] behaves as in table.sort(table, value [, comp])
	returns the index where 'value' was inserted
]]--
do
	-- Avoid heap allocs for performance
	local fcomp_default = function( a,b ) return a < b end
	function table_bininsert(t, value, fcomp)
		-- Initialise compare function
		local fcomp = fcomp or fcomp_default
		--  Initialise numbers
		local iStart,iEnd,iMid,iState = 1,#t,1,0
		-- Get insert position
		while iStart <= iEnd do
			-- calculate middle
			iMid = math.floor( (iStart+iEnd)/2 )
			-- compare
			if fcomp( value,t[iMid] ) then
				iEnd,iState = iMid - 1,0
			else
				iStart,iState = iMid + 1,1
			end
		end
		table.insert( t,(iMid+iState),value )
		return (iMid+iState)
	end
end

local function SpatialUpdateQueue()
	local self = {
		p = magic.Vector3(0, 0, 0),
		queue = {},
		queue_oldest_p = magic.Vector3(0, 0, 0),

		set_p = function(self, p)
			self.p = p
			-- If went too far, sort queue again
			if (p - self.queue_oldest_p):Length() > 16 then
				local old_queue = self.queue
				self.queue = {}
				for _, item in ipairs(old_queue) do
					self:put(item.p, item.value)
				end
				self.queue_oldest_p = p
			end
		end,
		put = function(self, p, value)
			local d = (p - self.p):Length()
			local function fcomp(a, b)
				return a.d > b.d
			end
			table_bininsert(self.queue, {p=p, d=d, value=value}, fcomp)
			--table.insert(self.queue, {p=p, value=value})
		end,
		get = function(self, p)
			-- TODO
			local item = table.remove(self.queue)
			if not item then return nil end
			return item.value
		end,
	}
	return self
end

function M.init()
	log:info("voxelworld.init()")

	buildat.sub_packet("voxelworld:init", function(data)
		local values = cereal.binary_input(data, {"object",
			{"chunk_size_voxels", {"object",
				{"x", "int32_t"},
				{"y", "int32_t"},
				{"z", "int32_t"},
			}},
			{"section_size_chunks", {"object",
				{"x", "int32_t"},
				{"y", "int32_t"},
				{"z", "int32_t"},
			}},
		})
		log:info(dump(values))
		M.chunk_size_voxels = buildat.IntVector3(values.chunk_size_voxels)
		M.section_size_chunks = buildat.IntVector3(values.section_size_chunks)
		M.section_size_voxels =
				M.chunk_size_voxels:mul_components(M.section_size_chunks)
	end)

	local function update_voxel_geometry(node)
		local data = node:GetVar("buildat_voxel_data"):GetBuffer()
		--local registry_name = node:GetVar("buildat_voxel_registry_name"):GetBuffer()
		log:info(dump(node:GetName()).." voxel data size: "..data:GetSize())
		buildat.set_voxel_geometry(node, data, registry_name)
	end

	local function update_voxel_physics(node)
		local data = node:GetVar("buildat_voxel_data"):GetBuffer()
		--local registry_name = node:GetVar("buildat_voxel_registry_name"):GetBuffer()
		log:info(dump(node:GetName()).." voxel data size: "..data:GetSize())
		buildat.set_voxel_physics_boxes(node, data, registry_name)
	end

	local node_update_queue = SpatialUpdateQueue()

	magic.SubscribeToEvent("Update", function(event_type, event_data)
		update_counter = update_counter + 1

		if camera_node and M.section_size_voxels then
			-- TODO: How should position information be sent to the server?
			local p = camera_node:GetWorldPosition()
			if update_counter % 60 == 0 then
				local section_p = buildat.IntVector3(p):div_components(
						M.section_size_voxels):floor()
				--log:info("p: "..p.x..", "..p.y..", "..p.z.." -> section_p: "..
				--		section_p.x..", "..section_p.y..", "..section_p.z)
				--[[send_get_section(section_p + buildat.IntVector3( 0, 0, 0))
				send_get_section(section_p + buildat.IntVector3(-1, 0, 0))
				send_get_section(section_p + buildat.IntVector3( 1, 0, 0))
				send_get_section(section_p + buildat.IntVector3( 0, 1, 0))
				send_get_section(section_p + buildat.IntVector3( 0,-1, 0))
				send_get_section(section_p + buildat.IntVector3( 0, 0, 1))
				send_get_section(section_p + buildat.IntVector3( 0, 0,-1))]]
			end
		end

		local camera_dir = magic.Vector3(0, 0, 0)
		local camera_p = magic.Vector3(0, 0, 0)

		if camera_node then
			camera_dir = camera_node.direction
			camera_p = camera_node:GetWorldPosition()
		end

		-- Handle one node update per frame
		node_update_queue:set_p(camera_p)
		local node_update = node_update_queue:get()
		if node_update then
			if node_update.type == "geometry" then
				update_voxel_geometry(node_update.node)
			end
			if node_update.type == "physics" then
				update_voxel_physics(node_update.node)
			end
		end

		if camera_node then
			camera_last_dir = camera_dir
			camera_last_p = camera_p
		end
	end)

	replicate.sub_sync_node_added({}, function(node)
		if not node:GetVar("buildat_voxel_data"):IsEmpty() then
			node_update_queue:put(node:GetWorldPosition(), {
				type = "geometry",
				node = node,
			})
			node_update_queue:put(node:GetWorldPosition(), {
				type = "physics",
				node = node,
			})
		end
		local name = node:GetName()
	end)
end

function M.set_camera(new_camera_node)
	camera_node = new_camera_node
end

function send_get_section(p)
	local data = cereal.binary_output({
		p = {
			x = p.x,
			y = p.y,
			z = p.z,
		},
	}, {"object",
		{"p", {"object",
			{"x", "int32_t"},
			{"y", "int32_t"},
			{"z", "int32_t"},
		}},
	})
	--log:info(dump(buildat.bytes(data)))
	buildat.send_packet("voxelworld:get_section", data)
end

return M
-- vim: set noet ts=4 sw=4:
