local mod = get_mod("SaveWeapon")

mod.SETTINGS = {
	AUTO_SAVE = "auto_save",
	
}

return {
	name = "SaveWeapon",
	description = mod:localize("mod_description"),
	is_togglable = false,
	
	--[[
	options_widgets = {
		{
			["setting_name"] = mod.SETTINGS.AUTO_SAVE,
			["widget_type"] = "checkbox",
			["text"] = mod:localize("auto_save"),
			["tooltip"] = mod:localize("auto_save_tooltip"),
			["default_value"] = true,
		},
	},
	]]--
}
