local mod = get_mod("SaveWeapon")

local mod_data = {
	name = "SaveWeapon",
	description = mod:localize("mod_description"),
	is_togglable = false,
	
	options = {
		widgets = {
			{
				setting_id = "auto_save",
				type = "checkbox",
				tooltip = "auto_save_tooltip",
				default_value = true,
			},
			{
				setting_id = "auto_equip_on_startup",
				type = "checkbox",
				tooltip = "auto_equip_on_startup_tooltip",
				default_value = true,
			},
			{
				setting_id = "displayed_rarity",
				type = "dropdown",
				tooltip = "displayed_rarity_tooltip",
				default_value = "plentiful",
				options = {
					{text = "rarity_default",	value = "default"},
					{text = "rarity_white",		value = "plentiful"},
					{text = "rarity_green",		value = "common"},
					{text = "rarity_blue",		value = "rare"},
					{text = "rarity_orange",	value = "exotic"},
					{text = "rarity_red",		value = "unique"},
				},
			},
			{
				setting_id = "keybinds_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "delete_item_keybind",
						type = "keybind",
						tooltip = "delete_item_keybind_tooltip",
						default_value = {},
						keybind_global = true,
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "delete_item_keybind_pressed",
					},
					{
						setting_id = "undo_delete_keybind",
						type = "keybind",
						tooltip = "undo_delete_keybind_tooltip",
						default_value = {},
						keybind_global = true,
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "undo_delete_keybind_pressed",
					},
				},
			},
			
		},
	},
}

return mod_data
