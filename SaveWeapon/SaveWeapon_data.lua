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
				title = "auto_save",
				tooltip = "auto_save_tooltip",
				default_value = true,
			},
			{
				setting_id = "displayed_rarity",
				type = "dropdown",
				title = "displayed_rarity",
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
		},
	},
}

return mod_data
