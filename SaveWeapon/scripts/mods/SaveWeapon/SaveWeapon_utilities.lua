--[[

	====================================
	= SAVE WEAPONS - UTILITY FUNCTIONS =
	====================================


	This file contains various utility functions that the mod uses.
	
	They're kept separate from the main file to reduce clutter.


	Index:
	¯¯¯¯¯
	 # STRING UTILITIES #
		trait_name_long2short 		(self, name)
		trait_name_short2long 		(self, name)
		separate_item_string  		(self, item_string)
		generate_item_string  		(self, name, skin, traits, properties)
		savestring_set_favorite		(self, savestring, is_favorite)
		
	 # STRING KEY CHECKS #
		is_item_accessory			(self, item_key)
		is_item_key_valid 	  		(self, item_key)
		is_skin_key_valid 	  		(self, skin_key, item_key)
		is_trait_key_valid 	  		(self, trait_key)
		is_property_key_valid 		(self, prop_key)
		
	 # BACKEND ID UTILITIES #
		get_backend_id_suffix 	   	(self, backend_id)
		is_backend_id_from_mod 	   	(self, backend_id)
		get_backend_save_id 	   	(self, backend_id)
		get_item_name_from_save_id 	(self, save_id)
		match_backend_id 			(self, backend_id)
		verify_backend_id 			(self, backend_id)
		find_base_item 				(self, item_key)
		is_item_saved 				(self, backend_id)
		get_last_unsaved_item 		(self)
	
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
	melee_heal_on_crit				= "melee_heal_on_crit", -- Unused - holdover of Regrowth from Verm 1?
	
	ranged_restore_stamina_headshot				= "inspirational_shot",
	ranged_replenish_ammo_headshot				= "conservative_shooter",
	ranged_reduce_cooldown_on_crit				= "resourceful_sharpshooter",
	ranged_replenish_ammo_on_crit				= "ranged_replenish_ammo_on_crit", -- Unused - Scavenger holdover?
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
mod.trait_name_long2short = function(self, name)
	return mod.trait_name_table[name] or name
end

-- Takes a short name and returns the longer name used in code
-- Example: "swift_slaying" returns "melee_attack_speed_on_crit"
mod.trait_name_short2long = function(self, name)
	for key, val in pairs(mod.trait_name_table) do
		if val == name then
			return key
		end
	end
	--mod:echo("SaveWeapon.trait_convert_short ERROR: string not in name table.")
	return name
end

-- # SEPARATE SAVESTRING
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
mod.separate_item_string = function(self, item_string)
	local item_strings = {}
	
	if not item_string then
		return {}
	end
	
	for w in string.gmatch(item_string, "[^/]+") do
		--mod:echo(w)
		table.insert(item_strings, w)
	end
	
	return item_strings
end

-- # PARSE SAVESTRING
-- Goes through the elements in a savestring and figures out what each one represents, then returns a table with the data we want.
-- It needs the item_key to check if the skin key is valid 
-- The returned table looks like this:
--[[
	data = {
		favorite = true or false
		skin = "skin_name",
		traits = {
			"trait_name",
			"trait_name_2",
			...
		},
		properties = {
			"property_name",
			"property_name_2",
			...
		},
		errors = {
			"unrecognized_string",
			"If the function can't figure out what a savestring segment means, it'll go here",
			...
		},
	}
--]]
mod.parse_savestring = function(self, item_key, item_string)
	local item_strings = mod:separate_item_string(item_string)
	local data = {
		favorite = false,
		skin = "nil",
		traits = {},
		properties = {},
		errors = {},
	}
	for _, str in ipairs(item_strings) do
		-- String is favorite?
		if str == "true" or str == "false" then
			data.favorite = str == "true"
		elseif mod:is_trait_key_valid(mod:trait_name_short2long(str)) then
			-- String is trait name?
			-- Could in theory end up with multiple traits, even though GiveWeapon doesn't support that.
			-- But if one were to manually edit user_settings it could happen
			table.insert(data.traits, mod:trait_name_short2long(str))
		elseif mod:is_property_key_valid(str) then
			-- String is property name?
			table.insert(data.properties, str)
		elseif mod:is_skin_key_valid(str, item_key) or str == "nil" then
			-- String is skin name? (Or "nil", which can happen if you use GiveWeapon's default skin setting)
			-- If the savestring for some reason contains multiple skin names, the last one will overwrite the others
			-- This should only happen if someone meddles with the user_settings file
			data.skin = str
		else
			-- If the string is unrecognizable, pass it on for error handling
			table.insert(data.errors, str)
		end
	end
	
	return data
end


-- # GENERATE SAVESTRING
-- Generates a string for saving the item with
-- It'll look something like this: "false/es_1h_mace_skin_02/swift_slaying/crit_chance/attack_speed"
mod.generate_item_string = function(self, skin, trait, properties)
	local item_string = "false" -- is favorite, false by default
	
	if skin == nil then
		item_string = item_string .. "/" .. "nil" -- Will be "nil" for necklace/charm/trinket
	else
		item_string = item_string .. "/" .. skin
	end
	
	item_string = item_string .. "/" .. mod:trait_name_long2short(trait) -- Shorten trait name to a more concise string
	
	for _, prop_name in ipairs(properties) do
		item_string = item_string .. "/" .. prop_name
	end
	
	return item_string
end

-- # CHANGE SAVESTRING FAVORITE FIELD
-- Sets the favorite field in the savestring to true or false and returns the new string
mod.savestring_set_favorite = function(self, savestring, is_favorite)
	local item_strings = mod:separate_item_string(savestring)
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

-- # IS ACCESSORY CHECK # --
-- Takes the item key/name (i.e. "es_1h_mace") and sees if it's a necklace, ring (charm), or trinket
mod.is_item_accessory = function(self, item_key)
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

-- # ITEM KEY CHECK # --
-- Takes item name (i.e. "es_1h_mace") and runs a check to see if an entry exists in ItemMasterList.
-- Then it checks if it's an equippable item. If yes, return true.
mod.is_item_key_valid = function(self, item_key)
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
mod.is_skin_key_valid = function(self, skin_key, item_key)
	if not mod:is_item_key_valid(item_key) then
		return false
	end
	if skin_key == "nil" or mod:is_item_accessory(item_key) then
		return true
	end
	-- Found this function in "weapon_skins.lua" that does the trick.
	-- It checks whether a skin key matches a weapon key and returns a boolean accordingly.
	return WeaponSkins.is_matching_skin(item_key, skin_key)
end

-- # TRAIT KEY CHECK # --
-- Takes trait name (i.e. "melee_attack_speed_on_crit") and runs a check to see if it exists.
mod.is_trait_key_valid = function(self, trait_key)
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
mod.is_property_key_valid = function(self, prop_key)
	for key, prop in pairs(WeaponProperties.properties) do
		if key == prop_key then
			--mod:echo('prop key \"' .. prop_key .. '\" valid')
			return true
		end
	end
	--mod:echo('prop key \"' .. prop_key .. '\" invalid (not in WeaponProperties.properties)')
	return false
end


--	________________________
--	# BACKEND ID UTILITIES #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- Items created with GiveWeapon or SaveWeapon have a suffix appended to their backend IDs
local backend_id_suffixes = {
	--"_from_SaveWeapon", 	-- Obsolete: all GiveWeapon/SaveWeapon items keep GiveWeapon prefix
	"_from_GiveWeapon",
	"_from_AllHats",		-- Used to track whether AllHats items were equipped last session
}

-- This function takes the backend ID and returns the suffix string, or 'nil' if there is no suffix.
mod.get_backend_id_suffix = function(self, backend_id)
	local suffix = nil
	for i = 1, #backend_id_suffixes, 1 do
		local str = backend_id_suffixes[i]
		if string.match(backend_id, str) then
			suffix = str
			break
		end
	end
	return suffix
end

-- Checks if a backend ID is from either the SaveWeapon or GiveWeapon mods and returns a boolean accordingly.
mod.is_backend_id_from_mod = function(self, backend_id)
	local suffix = mod:get_backend_id_suffix(backend_id)
	if suffix then
		return true
	end
	return false
end

-- Returns the backend ID string of a created item without the suffix
mod.get_backend_save_id = function(self, backend_id)
	local save_id = backend_id
	if save_id and save_id ~= "" then
		local suffix_len = string.len("_from_GiveWeapon") -- SaveWeapon and GiveWeapon are conveniently the same length
		save_id = string.sub(save_id, 1, string.len(save_id) - suffix_len)
	end
	return save_id
end

-- This one takes a save ID or backend ID and returns the item name (i.e. "es_2h_sword")
mod.get_item_name_from_save_id = function(self, save_id)
	for key, _ in pairs(ItemMasterList) do
		local item_name = string.match(save_id, key)
		if item_name then
			-- If save_id includes "es_2h_sword_executioner" it will still match on "es_2h_sword" and cause havoc, so this is an exception for that specific case. Similarly with repeater crossbow and Bretonnian sword & shield.
			-- Not too elegant (can potentially break if Fatshark changes item names, for some arcane reason), but it's a simple, low-effort solution
			if item_name == "es_2h_sword" then
				local exception = string.match(save_id, "es_2h_sword_executioner")
				if exception then
					return exception
				end
			elseif item_name == "wh_crossbow" then
				local exception = string.match(save_id, "wh_crossbow_repeater")
				if exception then
					return exception
				end
			elseif item_name == "es_sword_shield" then
				local exception = string.match(save_id, "es_sword_shield_breton")
				if exception then
					return exception
				end
			end
			return item_name
		end
	end
	return ""
end

-- # Look up a backend ID in created_items table # --
-- Returns true if a match is found, returns false if not
mod.match_backend_id = function(self, backend_id)
	for _, index in pairs(mod.created_items) do
		if index.backend_id == backend_id then
			--mod:echo("match for " .. backend_id)
			return true
		end
	end
	--mod:echo("no match for " .. backend_id)
	return false
end

-- # Looks up a backend ID and checks if it corresponds to an actual item # --
mod.verify_backend_id = function(self, backend_id)
	local backend_items = Managers.backend:get_interface("items")
	local item = backend_items:get_item_from_id(backend_id)

	if item then
		return true
	end
	return false
end

-- # Find base version of item # --
-- Takes an item key and returns the backend ID of the basic (power 5) version of the item
mod.find_base_item = function(self, item_key)
	-- Since accessory item keys often have a number suffix attached, reduce the string to match the base version that the power 5 items use
	if string.match(item_key, "trinket") then
		item_key = "trinket"
	elseif string.match(item_key, "ring") then
		item_key = "ring"
	elseif string.match(item_key, "necklace") then
		item_key = "necklace"
	end
	backend_items = Managers.backend:get_interface("items")
	for _, item in pairs(backend_items._items) do
		if item.power_level and item.power_level == 5 then
			if item.key == item_key then
				return item.backend_id
			end
		end
	end
	return false
end

-- # Looks up whether the item has been saved # --
-- Returns boolean, as well as the savestring of the item (or 'nil' if false)
mod.is_item_saved = function(self, backend_id)
	local saved_items = mod:get("saved_items")
	local item_id = mod:get_backend_save_id(backend_id)
	
	for save_id, savestring in pairs(saved_items) do
		if save_id == item_id then
			return true, savestring
		end
	end
	return false, nil
end

-- # Get last unsaved item # --
-- Returns the item's backend ID as well as its index in 'mod.created_items'
mod.get_last_unsaved_item = function(self)
	local items = mod.created_items
	for i = 1, #items do
		--mod:echo("[" .. i .. "] " .. tostring(items[i].backend_id) .. "/" .. tostring(items[i].saved))
		if items[i] and items[i].saved == false then
			return items[i].backend_id, i
		end
	end
	return nil, nil
end

