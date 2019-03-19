--[[

	====================================
	= SAVE WEAPONS - UTILITY FUNCTIONS =
	====================================


	This file contains various utility functions that the mod uses.
	
	They're kept separate from the main file to reduce clutter.


	Index:
	¯¯¯¯¯
	 # STRING UTILITIES #
		trait_name_long2short 		(name)
		trait_name_short2long 		(name)
		separate_item_string  		(item_string)
		generate_item_string  		(name, skin, traits, properties)
		savestring_set_favorite		(savestring, is_favorite)
		
	 # STRING KEY CHECKS #
		is_item_key_valid 	  		(item_key)
		is_skin_key_valid 	  		(skin_key, item_key)
		is_trait_key_valid 	  		(trait_key)
		is_property_key_valid 		(prop_key)
		
	 # BACKEND ID UTILITIES #
		get_backend_id_suffix 	   	(backend_id)
		is_backend_id_from_mod 	   	(backend_id)
		get_backend_save_id 	   	(backend_id)
		get_item_name_from_save_id 	(save_id)
	
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



--	____________________
--	# STRING UTILITIES #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

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

-- # PARSE SAVESTRING
-- The savestring is converted into an array, which looks like this:
--[[
	Saved item array anatomy:
		[1] = is favorite (true/false)
		[2] = skin name (Accessories use "nil" here)
		[3] = trait name
		[4] = property 1
		[5] = property 2
		[6] = property 3... and so on
]]--
mod.separate_item_string = function(item_string)
	local item_strings = {}
	
	for w in string.gmatch(item_string, "[^/]+") do
		--mod:echo(w)
		table.insert(item_strings, w)
	end
	
	return item_strings
end

-- # GENERATE SAVESTRING
-- Generates a string for saving the item with
-- It'll look something like this: "false/es_1h_mace_skin_02/swift_slaying/crit_chance/attack_speed"
mod.generate_item_string = function(skin, trait, properties)
	local item_string = "false" -- is favorite, false by default
	
	if skin == nil then
		item_string = item_string .. "/" .. "nil" -- Will be "nil" for necklace/charm/trinket
	else
		item_string = item_string .. "/" .. skin
	end
	
	item_string = item_string .. "/" .. mod.trait_name_long2short(trait) -- Shorten trait name to a more concise string
	
	for _, prop_name in ipairs(properties) do
		item_string = item_string .. "/" .. prop_name
	end
	
	return item_string
end

-- # CHANGE SAVESTRING FAVORITE FIELD
-- Sets the favorite field in the savestring to true or false and returns the new string
mod.savestring_set_favorite = function(savestring, is_favorite)
	local item_strings = mod.separate_item_string(savestring)
	item_strings[1] = tostring(is_favorite)
	local new_savestring = ""
	for _, str in pairs(item_strings) do
		if new_savestring ~= "" then
			new_savestring = new_savestring .. "/"
		end
		new_savestring = new_savestring .. str
	end
	return new_savestring
end


--	_____________________
--	# STRING KEY CHECKS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

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

mod.is_item_accessory = function(item_key)
	for key, item in pairs(ItemMasterList) do
		if key == item_key then
			if item.slot_type == "necklace"
			or item.slot_type == "ring"
			or item.slot_type == "trinket"
			then
				return true
			end
			return false
		end
	end
	return false
end

-- # SKIN KEY CHECK # --
-- Takes skin name (i.e. "es_1h_mace_skin_02") and item name (i.e. "es_1h_mace") and runs a check to see if they match.
mod.is_skin_key_valid = function(skin_key, item_key)
	if skin_key == "nil" and mod.is_item_accessory then
		return true
	end
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


--	________________________
--	# BACKEND ID UTILITIES #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- Items created with GiveWeapon or SaveWeapon have a suffix appended to their backend IDs
-- 	"_from_GiveWeapon"
--	"_from_SaveWeapon"
-- This function takes the backend ID and returns this string, or an empty string if there is no suffix.
mod.get_backend_id_suffix = function(backend_id)
	local suffix = string.match(backend_id, "_from_GiveWeapon")
	if not suffix then
		suffix = string.match(backend_id, "_from_SaveWeapon")
		if not suffix then
			suffix = ""
		end
	end
	--mod:echo('suffix = \"' .. suffix .. '\"')
	return suffix
end

-- Checks if a backend ID is from either the SaveWeapon or GiveWeapon mods and returns a boolean accordingly.
mod.is_backend_id_from_mod = function(backend_id)
	local suffix = mod.get_backend_id_suffix(backend_id)
	if suffix == "_from_GiveWeapon" or suffix == "_from_SaveWeapon" then
		return true
	end
	return false
end

-- Returns the backend ID string of a created item without the suffix
mod.get_backend_save_id = function(backend_id)
	local save_id = backend_id
	if get_backend_id_suffix ~= "" then
		local suffix_len = string.len("_from_GiveWeapon") -- SaveWeapon and GiveWeapon are conveniently the same length
		save_id = string.sub(save_id, 1, string.len(save_id) - suffix_len)
	end
	return save_id
end

-- This one takes a save ID and returns the weapon name
mod.get_item_name_from_save_id = function(save_id)
	for key, _ in pairs(ItemMasterList) do
		item_name = string.match(save_id, key)
		if item_name then
			return item_name
		end
	end
	return ""
end

