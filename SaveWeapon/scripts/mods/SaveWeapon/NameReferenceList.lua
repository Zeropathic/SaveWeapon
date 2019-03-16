local mod = get_mod("SaveWeapon")

--[[

	So the idea here is to make reference tables for shorter trait/property/skin/whatever names.
	
	I'm putting it here in a separate file so as not to clutter the main file.
	
	I'd like to be able to make the saved string a little shorter, while still intuitive to read.
	
	So, for example,
		"trait_melee_timed_block_cost"			-> "parry"
		"traits_ranged_replenish_ammo_headshot"	-> "conservative_shooter"
	
	The idea being to just use the in-game name, but with underscores.
	
]]--

mod.trait_name_table = {
	melee_attack_speed_on_crit 		= "swift_slaying",
	melee_timed_block_cost 			= "parry",
	melee_counter_push_power		= "opportunist",
	melee_increase_damage_on_block	= "off_balance",
	melee_reduce_cooldown_on_crit	= "resourceful_combatant",
	melee_shield_on_assist			= "heroic_intervention",
	melee_heal_on_crit				= "melee_heal_on_crit", -- What's this?
	
	ranged_restore_stamina_headshot				= "inspirational_shot",
	ranged_replenish_ammo_headshot				= "conservative_shooter",
	ranged_reduce_cooldown_on_crit				= "resourceful_sharpshooter",
	ranged_replenish_ammo_on_crit				= "ranged_replenish_ammo_on_crit", -- ??
	ranged_increase_power_level_vs_armour_crit	= "hunter",
	ranged_consecutive_hits_increase_power		= "barrage",
	ranged_movespeed_on_damage_taken			= "adrenaline_rush",
	
	ranged_reduced_overcharge			= "thermal_equalizer",
	ranged_remove_overcharge_on_crit	= "heat_sink",
	
	ring_not_consume_potion			= "home_brewer",
	ring_potion_spread				= "proxy",
	ring_not_consume_potion_damage	= "concentrated_brew",
	ring_all_potions				= "concoction",
	ring_potion_duration			= "decanter",

	necklace_not_consume_healing			= "healers_touch",
	necklace_heal_self_on_heal_other		= "hand_of_shalya",
	necklace_increased_healing_received		= "boon_of_shalya",
	necklace_no_healing_health_regen		= "natural_bond",
	necklace_damage_taken_reduction_on_heal	= "barkskin",

	trinket_not_consume_grenade		= "grenadier",
	trinket_increase_grenade_radius	= "explosive_ordnance",
	trinket_grenade_damage_taken	= "shrapnel"
}


-- Incomplete - should contain a total of 74 items
--[[
mod.skin_name_table = {
	"es_1h_sword_skin_03",
	"es_1h_mace_skin_02",
	"es_2h_sword_exe_skin_02",
	"es_2h_sword_skin_03",
	"es_2h_hammer_skin_03",
	"es_1h_sword_shield_skin_03",
	"es_1h_mace_shield_skin_03",
	"es_halberd_skin_02",
	"es_dual_wield_hammer_sword_skin_02",
	"es_longbow_skin_02",
	"es_blunderbuss_skin_01",
	"es_handgun_skin_01",
	"es_repeating_handgun_skin_02",
	
	"we_spear_skin_02",
	"we_dual_dagger_skin_04",
	"we_dual_sword_skin_01",
	"we_sword_skin_05",
	"we_1h_axe_skin_01",
	"we_dual_sword_dagger_skin_01",
	"we_shortbow_skin_02",
	"we_hagbane_skin_02",
	"we_longbow_skin_02",
	"we_2h_axe_skin_03",
	"we_2h_sword_skin_03",
	"we_crossbow_skin_02",
	
	"bw_1h_mace_skin_02",
	"bw_dagger_skin_02",
	"bw_1h_sword_skin_03",
	"bw_1h_flaming_sword_skin_03",
	"bw_1h_crowbill_skin_02",
	"bw_fireball_staff_skin_02",
	"bw_beam_staff_skin_02",
	"bw_conflagration_staff_skin_02",
	"bw_spear_staff_skin_02",
	"bw_flamethrower_staff_skin_02",
	
	"dw_1h_axe_skin_02",
	"dw_dual_axe_skin_02",
	"dw_2h_axe_skin_03",
	"dw_crossbow_skin_02",
	"dw_2h_hammer_skin_02",
	"dw_1h_hammer_skin_02",
	"dw_1h_axe_shield_skin_02",
	"dw_1h_hammer_shield_skin_02",
	"dr_dual_wield_hammers_skin_01",
	"dw_grudge_raker_skin_02",
	"dw_handgun_skin_03",
	"dw_drake_pistol_skin_02",
	"dw_drakegun_skin_01",
	"dw_2h_pick_skin_02",
	
	"wh_1h_axe_skin_01",
	"wh_2h_sword_skin_03",
	"wh_fencing_sword_skin_02",
	"wh_brace_of_pistols_skin_04",
	"wh_repeating_pistol_skin_02",
	"wh_repeating_crossbow_skin_02",
	"wh_crossbow_skin_01",
	"wh_1h_falchion_skin_02",
	"es_1h_flail_skin_02",
	"wh_dual_wield_axe_falchion_skin_02"
}
]]--

--

-- Takes a long name and returns a shortened one.
-- Example: "melee_attack_speed_on_crit" returns "swift_slaying"
mod.trait_name_long2short = function(name)
	return mod.trait_name_table[name] or name
end

-- Takes a short name and returns the longer name used in code
-- Example: "swift_slaying" returns "melee_attack_speed_on_crit"
mod.trait_name_short2long = function(name)
	for key, val in pairs(mod.trait_name_table) do
		if val == name then
			return key
		end
	end
	mod:echo("SaveWeapon.trait_convert_short ERROR: string not in name table.")
	return name
end

--[[ Quick tests
local test_string = "melee_shield_on_assist"
mod:echo('\"'.. test_string .. '\" -> ' .. mod.trait_name_long2short(test_string))

test_string = "heat_sink"
mod:echo('\"'.. test_string .. '\" -> ' .. mod.trait_name_short2long(test_string))
]]--
