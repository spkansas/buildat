-- Buildat: extension/urho3d/safe_events.lua
-- http://www.apache.org/licenses/LICENSE-2.0
-- Copyright 2014 Perttu Ahola <celeron55@gmail.com>

return {
	Update = {
		TimeStep = {variant = "Float", safe = "number"},
	},
	KeyDown = {
		Key = {variant = "Int", safe = "number"},
	},
	HoverBegin = {
	},
	HoverEnd = {
	},
	Released = {
	},
	TextFinished = {
	},
	NodeAdded = {
		Scene = {variant = "Ptr", safe = "Scene"},
		Parent = {variant = "Ptr", safe = "Node"},
		Node = {variant = "Ptr", safe = "Node"},
	},
	NodeRemoved = {
		Scene = {variant = "Ptr", safe = "Scene"},
		Parent = {variant = "Ptr", safe = "Node"},
		Node = {variant = "Ptr", safe = "Node"},
	},
	ComponentAdded = {
		Scene = {variant = "Ptr", safe = "Scene"},
		Node = {variant = "Ptr", safe = "Node"},
		Component = {variant = "Ptr", safe = "Component"},
	},
	ComponentRemoved = {
		Scene = {variant = "Ptr", safe = "Scene"},
		Node = {variant = "Ptr", safe = "Node"},
		Component = {variant = "Ptr", safe = "Component"},
	},
	NodeNameChanged = {
		Scene = {variant = "Ptr", safe = "Scene"},
		Node = {variant = "Ptr", safe = "Node"},
	},
}
-- vim: set noet ts=4 sw=4:
