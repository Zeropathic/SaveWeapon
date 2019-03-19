--[[

	================
	= SAVE WEAPONS =
	================

	 v. 0.04



	
	Planned changes:
	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	 - (Done) Move utility functions to SaveWeapon_utilities
	 - Add a mod options menu
		* Automatic load on startup ~ On/Off
		* Save methods: automatic, manual, by favorite, whatever I can come up with
	 - Some chat commands to give better control over save/load
		* /save_last
		* /delete_last (remove last save index from .config file)
		* /destroy_last (remove the last item created by GiveWeapon from the game)
		* /save/delete/destroy_equipped (do the thing with all equipped created items on current character)
		  
		  Some that I'm not sure how would work, but they're ideas:
		* /import
		* /export
		* /share
	 - (Done) Keep track of items created during current session, both from GiveWeapon and this mod
	 - Using aforementioned track keeping:
		* (Sorta done - loading an item overwrites the old copy) Check to prevent same item from being saved or loaded twice
		* Some kind of utilities to offer better control over saving/loading/deleting created items (details pending)
		* (Done ) Saving whether an item is marked as a Favorite and applying that status when it's loaded

]]--


local mod = get_mod("SaveWeapon")


-- Penlight, I guess?
-- Used for an if-check I copied from GiveWeapon, used in the GiveWeapon hook function.
local pl = require'pl.import_into'()

-- Incorporate a bunch of utility functions tied to this mod
-- Kept in a separate file to reduce clutter
mod:dofile("scripts/mods/SaveWeapon/SaveWeapon_utilities")

--
mod.give_weapon = get_mod("GiveWeapon")
mod.more_items_library = get_mod("MoreItemsLibrary")

-- Error messages - I think?
fassert(mod.give_weapon, "SaveWeapon must be lower than GiveWeapon in your launcher's load order.")
fassert(mod.more_items_library, "SaveWeapon must be lower than MoreItemsLibrary in your launcher's load order.")

--

-- Create user_settings.config entry if there isn't one
mod.saved_items = {}
if not mod:get("saved_items") then
	mod:set("saved_items", mod.saved_items)
end
mod.saved_items = mod:get("saved_items")

-- When items are created, its backend_id is stored in this table.
-- Index #1 should be the last created item.
if not mod.created_items then -- Contingency to prevent reloading the mods from wiping the mod's session data
	mod.created_items = {}
end


--[[

	The saved items look something like this:

	saved_items = [
		es_1h_mace_21932 = "es_1h_mace_skin_02/parry/attack_speed/crit_chance"
		item_name_83244 = "skin_name/trait/property/property"
	]

	The number after the name refers to the item's unique ID.
	
	The backend ID of any loaded item is:
		backend_id = "item_name_IDNUM_from_SaveWeapon"
		
	Which might look like this:
		backend_id = "es_1h_mace_21932_from_SaveWeapon"

]]--




--	_________________
--	# LOADING ITEMS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
-- Checks the saved strings and loads the items.
-- The savestring is converted into an array, which looks like this:
--[[
	Saved item array anatomy:
		[1] = is favorite
		[2] = skin name (Accessories use "nil" here)
		[3] = trait name
		[4] = property 1
		[5] = property 2
		[6] = property 3... and so on
		
	Item name is extrapolated from the saved item key
	
	Maybe I should put a hard cap at 2 properties, but GiveWeapon doesn't so for now I didn't bother. Theoretically you could have one of each property.
]]--

-- Loads the saved items
mod.load_items = function()
	--mod:echo("Loading items...")
	
	mod.saved_items = mod:get("saved_items")
	
	local items_loaded = 0
	local items_failed_to_load = 0
	
	for save_id, savestring in pairs(mod.saved_items) do
		local item_key = mod.get_item_name_from_save_id(save_id)
		
		local item_strings = mod.separate_item_string(savestring)
		
		--mod:echo("save_id = " .. save_id)
		--mod:echo("item_key = " .. item_key)
		--mod:echo("savestring = " .. savestring)
		
		item_strings[3] = mod.trait_name_short2long(item_strings[3]) -- Convert shortened trait name back to its full name
		
		local prop_check = true
		for i = 4, #item_strings do
			if not mod.is_property_key_valid(item_strings[i]) then
				prop_check = false
			end
		end
		
		if mod.is_item_key_valid(item_key)
		and mod.is_skin_key_valid(item_strings[2], item_key)
		and mod.is_trait_key_valid(item_strings[3])
		and prop_check
		then
			
			-- Trying to more or less copy how GiveWeapon uses the items library thing, I don't really know what I'm doing
			local name = item_key
			local skin = item_strings[2]
			
			local trait = { item_strings[3] }
			local custom_traits = '[\"' .. item_strings[3] .. '\",]'
			
			local properties = {}
			for i = 4, #item_strings do
				properties[item_strings[i]] = 1
			end
			local custom_properties = "{"
			for i = 4, #item_strings do
				custom_properties = custom_properties..'\"' .. item_strings[i] .. '\":1,'
			end
			custom_properties = custom_properties .. "}"
			
			-- Dunno how to use this thing but let's try
			-- This bit is more or less copied from GiveWeapon
			local new_backend_id = save_id .. "_from_SaveWeapon"
			local entry = table.clone(ItemMasterList[name])
			entry.mod_data = {
				backend_id = new_backend_id,
				ItemInstanceId = new_backend_id,
				CustomData = {
					-- traits = "[\"melee_attack_speed_on_crit\", \"melee_timed_block_cost\"]",
					traits = custom_traits,
					power_level = "300",
					properties = custom_properties,
					rarity = "exotic",
				},
				rarity = "exotic",
				-- traits = { "melee_timed_block_cost", "melee_attack_speed_on_crit" },
				traits = table.clone(trait),
				power_level = 300,
				properties = properties,
			}
			if skin ~= "nil" then
				entry.mod_data.CustomData.skin = skin
				entry.mod_data.skin = skin
				entry.mod_data.inventory_icon = WeaponSkins.skins[skin].inventory_icon
			end
			
			entry.rarity = "exotic"

			entry.rarity = "default"
			entry.mod_data.rarity = "default"
			entry.mod_data.CustomData.rarity = "default"

			mod.more_items_library:add_mod_items_to_local_backend({entry}, "SaveWeapon")
			Managers.backend:get_interface("items"):_refresh()
			
			-- Mark as favorite if the save says so
			if item_strings[1] == "true" then
				-- Disable my hook momentarily so it won't catch this call
				mod:hook_disable(ItemHelper, "mark_backend_id_as_favorite")
				ItemHelper.mark_backend_id_as_favorite(new_backend_id)
				mod:hook_enable(ItemHelper, "mark_backend_id_as_favorite")
			end
			
			
			items_loaded = items_loaded + 1
		else
			items_failed_to_load = items_failed_to_load + 1
			mod:echo('[SaveWeapon][ERROR] Failed to load item \"' .. save_id .. '\"')
		end
	end
	
	-- A little message telling the player how many items were loaded.
	if items_failed_to_load == 0 then
		mod:echo("SaveWeapon: " .. items_loaded .. " items loaded")
	else
		mod:echo("SaveWeapon: " .. items_loaded .. " items loaded / " .. items_failed_to_load .. " failed")
	end
end

-- Forcibly load items with "/saveweapon_load"
mod:command("saveweapon_load", "Load all saved GiveWeapon items", function()
    --mod:echo("command: saveweapon_load")
	mod.load_items()
end)

-- Load weapons roughly on game start
-- Need to use this rather than on mods loaded since some of the game stuff used isn't available yet
mod.on_game_state_changed = function(status, state_name)
	if status == "enter" 
	and state_name == "StateIngame" 
	and not rawget(_G, "SaveWeapon_OnStartup_Loaded")
	then
		mod.load_items()
		rawset(_G, "SaveWeapon_OnStartup_Loaded", true)
	end
end


--	________________
--	# SAVING ITEMS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯


-- Saves the item in user_data.config
mod.save_item = function(backend_id, savestring)
	local save_id = mod.get_backend_save_id(backend_id)
	mod.saved_items[save_id] = savestring
	table.sort(mod.saved_items)
	mod:set("saved_items", mod.saved_items)
end


-- Mark favorite
mod:hook_safe(ItemHelper, "mark_backend_id_as_favorite", function(backend_id, save)
	-- Only act if the item comes from this mod or GiveWeapon
	if mod.is_backend_id_from_mod(backend_id) then
		--mod:echo('Marked ID \"' .. tostring(backend_id).. '\"')
		
		local save_id = mod.get_backend_save_id(backend_id)
		mod.saved_items[save_id] = mod.savestring_set_favorite(mod.saved_items[save_id], true)
		
		-- Save the favorite change
		mod:set("saved_items", mod.saved_items)
	end
end)

-- Unmark favorite
mod:hook_safe(ItemHelper, "unmark_backend_id_as_favorite", function(backend_id)	
	-- Only act if the item comes from this mod or GiveWeapon
	if mod.is_backend_id_from_mod(backend_id) then
		--mod:echo('Unmarked ID \"' .. tostring(backend_id).. '\"')
		
		local save_id = mod.get_backend_save_id(backend_id)
		mod.saved_items[save_id] = mod.savestring_set_favorite(mod.saved_items[save_id], false)
		
		-- Save the favorite change
		mod:set("saved_items", mod.saved_items)
	end
end)


-- On game launch you can have "dead" favorite entries due to the mods. 
-- This should flush them from the list and prevent complications with favorite items. 
-- When done it disables itself, never to run again.
mod:hook(BackendInterfaceItemPlayfab, "_refresh_items", function(func, self)
	--mod:echo("Flushing backend IDs...")
	
	local favorite_backend_ids = ItemHelper.get_favorite_backend_ids()
	if favorite_backend_ids then
		for backend_id, _ in pairs(favorite_backend_ids) do
			if mod.is_backend_id_from_mod(backend_id) then
				favorite_backend_ids[backend_id] = nil
				
				--mod:echo('Removed backend id \"' .. backend_id .. '\" from favorite_backend_ids')
			end
		end
	end
	
	mod:hook_disable(BackendInterfaceItemPlayfab, "_refresh_items")
	
	return func(self)
end)


-- # MORE ITEMS LIBRARY HOOK # --
-- Hooking MoreItemsLibrary to retreive item data of a created item.
mod:hook_safe(mod.more_items_library, "add_mod_items_to_local_backend", function(self, items, mod_name)
	-- Make sure the new item is created by one of these mods.
	if mod_name == "GiveWeapon"
	or mod_name == "SaveWeapon"
	then
		for item_num = 1, #items do
			local item = items[item_num]
			
			--[[
			mod:echo("backend_id = " .. item.mod_data.backend_id)
			mod:echo("name = " .. item.name)
			mod:echo("skin = " .. tostring(item.mod_data.skin))
			mod:echo("trait = " .. item.mod_data.traits[1])
			local properties = ""
			for key, val in pairs(item.mod_data.properties) do
				if properties ~= "" then
					properties = properties .. ", "
				end
				properties = properties .. key
			end
			if properties == "" then
				properties = "nil"
			end
			mod:echo("properties = " .. properties)
			]]--
			
			local name = item.name
			local skin = item.mod_data.skin
			local trait = item.mod_data.traits[1]
			local properties = {}
			for key, _ in pairs(item.mod_data.properties) do
				table.insert(properties, 1, key)
			end
			
			local savestring = mod.generate_item_string(skin, trait, properties)
			
			if mod_name == "GiveWeapon" then
				-- Eventually I want some mod settings to control whether items are autosaved
				-- For now, any item created by GiveWeapon is saved automatically
				local backend_id = item.mod_data.backend_id
				mod.save_item(backend_id, savestring)
			end
			
			-- Track created items by adding them to a table. This gets wiped when you quit the game.
			table.insert(mod.created_items, 1, item.mod_data.backend_id)
		end
	end
end)


