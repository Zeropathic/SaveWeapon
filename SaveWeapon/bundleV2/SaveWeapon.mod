return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`SaveWeapon` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("SaveWeapon", {
			mod_script       = "scripts/mods/SaveWeapon/SaveWeapon",
			mod_data         = "scripts/mods/SaveWeapon/SaveWeapon_data",
			mod_localization = "scripts/mods/SaveWeapon/SaveWeapon_localization",
		})
	end,
	packages = {
		"resource_packages/SaveWeapon/SaveWeapon",
	},
}
