--[[

	====================================
	= SAVE WEAPONS - UTILITY FUNCTIONS =
	====================================

]]--

local mod = get_mod("SaveWeapon")


-- # TRAIT NAME DICTIONARY # --
-- Shorter names for traits to be saved in the data file.
-- Not sure there's much point to it, but here it is.
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



--	_________________
--	STRING CONVERTERS
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

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

--[[ 
-- Quick tests
local test_string = "melee_shield_on_assist"
mod:echo('\"'.. test_string .. '\" -> ' .. mod.trait_name_long2short(test_string))

test_string = "heat_sink"
mod:echo('\"'.. test_string .. '\" -> ' .. mod.trait_name_short2long(test_string))
]]--



--	_________________
--	STRING KEY CHECKS
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- # ITEM KEY CHECK # --
-- Takes item name (i.e. "es_1h_mace") and runs a check to see if an entry exists in ItemMasterList.
-- Then it checks if it's an equippable item. If yes, return true.
mod.is_item_key_valid = function(item_key)
	for key, item in pairs(ItemMasterList) do
		if key == item_key then
			if item.slot_type == "melee"
			or item.slot_type == "ranged"
			or item.slot_type == "necklace"
			or item.slot_type == "ring"
			or item.slot_type == "trinket"
			then
				--mod:echo('item key \"' .. item_key .. '\" valid')
				return true
			end
			--mod:echo('item key \"' .. item_key .. '\" valid, but item key invalid')
			return false
		end
	end
	--mod:echo('item key \"' .. item_key .. '\" invalid (not in ItemMasterList)')
	return false
end

-- # SKIN KEY CHECK # --
-- Takes skin name (i.e. "es_1h_mace_skin_02") and item name (i.e. "es_1h_mace") and runs a check to see if they match.
mod.is_skin_key_valid = function(skin_key, item_key)
	-- Found this function in "weapon_skins.lua" that does the trick.
	-- It checks whether a skin key matches a weapon key and returns a boolean accordingly.
	local b = WeaponSkins.is_matching_skin(item_key, skin_key)
	if b then
		--mod:echo('skin key \"' .. skin_key .. '\" valid: matches \"' .. item_key .. '\"')
	else
		--mod:echo('skin key \"' .. skin_key .. '\" invalid')
	end
	return b
end

-- # TRAIT KEY CHECK # --
-- Takes trait name (i.e. "melee_attack_speed_on_crit") and runs a check to see if it exists.
mod.is_trait_key_valid = function(trait_key)
	for key, trait in pairs(WeaponTraits.traits) do
		if key == trait_key then
			--mod:echo('trait key \"' .. trait_key .. '\" valid')
			return true
		end
	end
	--mod:echo('trait key \"' .. trait_key .. '\" invalid (not in WeaponTraits.traits)')
	return false
end

-- # PROPERTY KEY CHECK # --
-- Takes property name (i.e. "attack_speed") and runs a check to see if it exists.
mod.is_property_key_valid = function(prop_key)
	for key, prop in pairs(WeaponProperties.properties) do
		if key == prop_key then
			--mod:echo('prop key \"' .. prop_key .. '\" valid')
			return true
		end
	end
	--mod:echo('prop key \"' .. prop_key .. '\" invalid (not in WeaponProperties.properties)')
	return false
end



-- Key check tests
--[[
local skin_key = "wh_dual_wield_axe_falchion_skin_02"
local item_key = "wh_dual_wield_axe_falchion"
local trait_key = "melee_attack_speed_on_crit"
local prop_key = "crit_chance"

mod.is_item_key_valid(item_key)
mod.is_skin_key_valid(skin_key, item_key)
mod.is_trait_key_valid(trait_key)
mod.is_property_key_valid(prop_key)
]]--

