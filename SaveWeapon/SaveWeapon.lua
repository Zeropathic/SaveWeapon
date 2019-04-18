--[[

	================
	= SAVE WEAPONS =
	================

	 v. 0.10



	
	Summary:
	¯¯¯¯¯¯¯
	This mod saves items created with PropJoe's GiveWeapon mod and loads them up next time you launch the game.
	
	It also keeps created weapons equipped between sessions and remembers inventory favorites.
	
	Saved items are compatible with Loadout Manager and Weapon Kill Counter.



	List of commands:
	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	 /sw_load_all				-- Loads all saved items
	 /sw_save_%item_name%		-- Saves the named item. The mod keeps track of unsaved items, and auto-fill will help you.
	 /sw_delete_last			-- Deletes the last created item
	 /sw_delete_%item_name%		-- Deletes the specified item. If you start typing, autofill will kick in and you can choose one
	 /sw_undo					-- Undoes last deletion. Can be used multiple times, if you deleted multiple items.

]]--


local mod = get_mod("SaveWeapon")


-- Penlight, I guess?
-- Used for an if-check I copied from GiveWeapon, used in the GiveWeapon hook function.
local pl = require'pl.import_into'()

-- Incorporate a bunch of utility functions tied to this mod
-- Kept in a separate file to reduce clutter
mod:dofile("scripts/mods/SaveWeapon/SaveWeapon_utilities")

--
local GiveWeapon = get_mod("GiveWeapon")
local MoreItemsLibrary = get_mod("MoreItemsLibrary")

-- Mod launcher error messages
fassert(GiveWeapon, "SaveWeapon must be lower than GiveWeapon in your launcher's load order.")
fassert(MoreItemsLibrary, "SaveWeapon must be lower than MoreItemsLibrary in your launcher's load order.")

--

-- Create user_settings.config entry if there isn't one
mod.saved_items = {}
if not mod:get("saved_items") then
	mod:set("saved_items", mod.saved_items)
end
mod.saved_items = mod:get("saved_items")

-- When the game launches, data regarding SaveWeapon/GiveWeapon items equipped from last session is temporarily stored here
-- This data is used to re-equip those items, then the table gets wiped.
-- Table structure looks like so:
--[[
	mod.last_session_equipped_items = {
		bw_scholar = {
			slot_melee = %backend_id%
			slot_ring = %backend_id%
			...
		}
		wh_captain = {
			slot_ranged = %backend_id%
		}
		...
	}
]]--
mod.last_session_equipped_items = {}

-- When items are created, its backend_id is stored in this table.
-- Index #1 should be the last created item.
mod.created_items = mod:persistent_table("SaveWeapon_session_created_items", {})

-- When an item is saved, its backend_id is stored in this table.
-- Index #1 is last saved
mod.last_saved_items = mod:persistent_table("SaveWeapon_session_last_saved_items", {})

-- When an item is deleted, its data is stored in this table.
-- Index #1 is last deleted
-- Stored tables look like this: 
--		mod.deleted_items[1] = { save_id, savestring }
mod.deleted_items = mod:persistent_table("SaveWeapon_session_deleted_items", {})


--	_________________
--	# CHAT COMMANDS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

--	/sw_load_all
-- Forcibly loads your saved items, should you need to do so for whatever reason.
-- There's a chance it might cause bugs with last saved/created items
mod:command("sw_load_all", "Load all saved GiveWeapon items", function()
	mod:load_items()
end)

--	/sw_save_last (n)
-- Saves the last n created items. If no parameter is used, saves the last created item.
-- # UNFINISHED # --
--[[
mod:command("sw_save_last", "Save last created GiveWeapon item", function()
	local last_created = mod.created_items[1]
	local backend_id = last_created.backend_id
	local savestring = last_created.savestring
	mod:save_item(backend_id, savestring)
end)
]]--

--	/sw_save_%item_name%
-- Saves specified item. This command only works for unsaved items.
mod.add_save_weapon_command = function(self, backend_id, savestring)
	local item_id = mod:get_backend_save_id(backend_id)
	local command_name = "sw_save_" .. item_id
	
	local savestring_table = mod:separate_item_string(savestring)
	local command_description = savestring_table[2]
	for i = 3, #savestring_table do
		command_description = command_description .. "/" .. savestring_table[i]
	end
	mod:command(command_name, command_description, function()
		mod:save_item(backend_id, savestring)
		mod:command_remove(command_name)
		mod:echo("[SaveWeapon] " .. item_id .. " saved")
	end)
end

--	/sw_delete_last
-- Delete last saved item
mod:command("sw_delete_last", "Deletes the last saved item from the game", function()
	local backend_id = mod.last_saved_items[1]
	if backend_id then
		-- Remove generated delete chat command
		local save_id = mod:get_backend_save_id(backend_id)
		local command_name = "sw_delete_" .. save_id
		mod:command_remove(command_name)
		
		-- Delete the saved entry and remove from created table
		mod:delete_item(backend_id)
	else
		mod:echo("[SaveWeapon] Saved list empty; nothing to delete")
	end
end)

-- 	/sw_delete_%item_name%
-- Creates a command named after the item. It's convenient to do it this way since it lets the user use VMF's auto fill functionality.
-- Created commands will currently be lost if you reload the mod (rip)
mod.add_delete_weapon_command = function(self, backend_id)
	local item_id = mod:get_backend_save_id(backend_id)
	local command_name = "sw_delete_" .. item_id
	
	local savestring = mod:separate_item_string(mod.saved_items[item_id])
	local command_description = savestring[2]
	for i = 3, #savestring do
		command_description = command_description .. "/" .. savestring[i]
	end
	mod:command(command_name, command_description, function()
		mod:delete_item(backend_id)
		mod:command_remove(command_name)
	end)
end

--	/sw_undo
-- Undoes last delete action
mod:command("sw_undo", "Undoes the last delete action", function()
	local deleted_item = mod.deleted_items[1]
	if deleted_item then
		local backend_id = deleted_item.backend_id
		local savestring = deleted_item.savestring
		
		mod:save_item(backend_id, savestring)
		table.remove(mod.deleted_items, 1)
		
		mod:echo('[SaveWeapon] \"' .. mod:get_backend_save_id(backend_id) .. '\" restored')
	else
		mod:echo("[SaveWeapon] Nothing to undo; nothing has been deleted")
	end
end)


--	__________________
--	# DELETING ITEMS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- # Delete created item # --
-- Deletes a created item, both from your inventory (well, not yet) and your save file.
mod.delete_item = function(self, backend_id)
	local save_id = mod:get_backend_save_id(backend_id)
	local savestring = mod.saved_items[save_id]
	local entry = {
		backend_id = backend_id,
		savestring = savestring,
	}
	table.insert(mod.deleted_items, 1, entry) -- Save last deleted info, in case you want to undo it
	
	-- Remove item from last_saved_items table
	for i, str in ipairs(mod.last_saved_items) do
		if str == backend_id then
			table.remove(mod.last_saved_items, i)
			break
		end
	end
	
	-- Remove item from backend (Doesn't remove item if it's currently equipped)
	-- # Currently has issues I need to sort out, hence this is commented out # --
	--MoreItemsLibrary:remove_mod_items_from_local_backend({backend_id}, "SaveWeapon")
	--Managers.backend:get_interface("items"):_refresh() -- Doesn't seem to remove the interface icon. Won't be gone until manual refresh
	
	mod.saved_items[save_id] = nil
	mod:set("saved_items", mod.saved_items)
	
	mod:echo('[SaveWeapon] Entry "' .. tostring(backend_id) .. '" deleted from save file.') 
	mod:echo('(Use "/sw_undo" if you regret deleting it.)')
	mod:echo("Item is still in inventory, but it will not be loaded next time the game launches.")
end


--	_________________
--	# LOADING ITEMS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

--[[ 
	Checks the saved strings and loads the items.

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

	The savestring is converted into an array, which looks like this:

	Saved item array anatomy:
		[1] = is favorite ("true"/"false")
		[2] = skin name (Accessories use "nil" here)
		[3] = trait name
		[4] = property 1
		[5] = property 2
		[6] = property 3... and so on
		
	Item name/type is extrapolated from the saved item key
	
	Maybe I should put a hard cap at 2 properties, but GiveWeapon doesn't so for now I didn't bother. Theoretically you could have one of each property.
]]--

-- Loads the saved items
mod.load_items = function(self)
	--mod:echo("Loading items...")
	
	mod.saved_items = mod:get("saved_items")
	
	local items_loaded = 0
	local items_failed_to_load = 0
	
	for save_id, savestring in pairs(mod.saved_items) do
		local item_key = mod:get_item_name_from_save_id(save_id)
		
		local item_strings = mod:separate_item_string(savestring)
		
		--mod:echo("save_id = " .. save_id)
		--mod:echo("item_key = " .. item_key)
		--mod:echo("savestring = " .. savestring)
		
		item_strings[3] = mod:trait_name_short2long(item_strings[3]) -- Convert shortened trait name back to its full name
		
		local prop_check = true
		for i = 4, #item_strings do
			if not mod:is_property_key_valid(item_strings[i]) then
				prop_check = false
			end
		end
		
		if mod:is_item_key_valid(item_key)
		and mod:is_skin_key_valid(item_strings[2], item_key)
		and mod:is_trait_key_valid(item_strings[3])
		and prop_check
		then
			
			-- Trying to more or less copy how GiveWeapon uses the items library thing, I don't really know what I'm doing
			local name = item_key
			local skin = item_strings[2]
			if skin == "nil" then
				skin = nil
			end
			
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
			local new_backend_id = save_id .. "_from_GiveWeapon" -- Keep the backend ID from GiveWeapon; this will let loaded items work with LoadoutManager and similar mods.
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
			
			if skin then
				entry.mod_data.CustomData.skin = skin
				entry.mod_data.skin = skin
				entry.mod_data.inventory_icon = WeaponSkins.skins[skin].inventory_icon
			end
			if not skin then
				skin = nil
			end
			
			local rarity = mod:get("displayed_rarity")
			entry.rarity = rarity
			entry.mod_data.rarity = rarity
			entry.mod_data.CustomData.rarity = rarity

			MoreItemsLibrary:add_mod_items_to_local_backend({entry}, "SaveWeapon")
			Managers.backend:get_interface("items"):_refresh()
			
			-- Mark as favorite if the save says so
			if item_strings[1] == "true" then
				-- Disable my hook momentarily so it won't catch this call
				mod:hook_disable(ItemHelper, "mark_backend_id_as_favorite")
				ItemHelper.mark_backend_id_as_favorite(new_backend_id)
				mod:hook_enable(ItemHelper, "mark_backend_id_as_favorite")
			end
			
			table.insert(mod.last_saved_items, new_backend_id) -- Add to last saved (want to include loaded items)
			mod:add_delete_weapon_command(new_backend_id) -- Chat command to delete the specified item
			
			--Ghetto fix for the no-skin loaded item crash
			mod:pcall(function()
				local backend_items = Managers.backend:get_interface("items")
				local item = backend_items:get_item_from_id(new_backend_id)

				-- Set item rarity based on mod setting
				local rarity = mod:get("displayed_rarity")

				item.rarity = rarity
				item.data.rarity = rarity
				item.CustomData.rarity = rarity
					
				-- This should only occur if you use GiveWeapon's default skin option.
				if not skin then
					item.skin = nil
				end
			end)
			
			items_loaded = items_loaded + 1
		else
			-- Error message in case savestring is invalid for some reason
			
			local error_message = '[SaveWeapon][ERROR] Failed to load item \"' .. save_id .. '\": '
			local errors = 0
			if not mod:is_item_key_valid(item_key) then
				error_message = error_message .. "item"
				errors = errors + 1
			end
			if not mod:is_skin_key_valid(item_strings[2], item_key) then
				if errors > 0 then
					error_message = error_message .. ", "
				end
				error_message = error_message .. "skin"
				errors = errors + 1
			end
			if not mod:is_trait_key_valid(item_strings[3]) then
				if errors > 0 then
					error_message = error_message .. ", "
				end
				error_message = error_message .. "trait"
				errors = errors + 1
			end
			if not prop_check then
				if errors > 0 then
					error_message = error_message .. ", "
				end
				error_message = error_message .. "property"
				errors = errors + 1
			end
			
			if errors > 1 then
				error_message = error_message .. " keys invalid"
			elseif errors == 1 then
				error_message = error_message .. " key invalid"
			else
				error_message = error_message .. " ???"
			end
			
			mod:echo(error_message)
			
			items_failed_to_load = items_failed_to_load + 1
		end
	end
	
	-- A little message telling the player how many items were loaded.
	if items_failed_to_load == 0 then
		if items_loaded > 0 then
			mod:echo("[SaveWeapon] " .. items_loaded .. " items loaded")
		end
	else
		mod:echo("[SaveWeapon] " .. items_loaded .. " items loaded / " .. items_failed_to_load .. " failed")
	end
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


-- # Re-equip saved items on game start # --
mod.equip_saved_items_on_startup = function(self)
	local player = Managers.player:local_player()
	local player_career = player:career_name()
	local player_unit = player.player_unit
	
	local backend_items = Managers.backend:get_interface("items")
	
	-- First loop goes through all careers that were saved in the table
	-- (Will only contain those who had Save/GiveWeapon items last session)
	for career, item_slot in pairs(mod.last_session_equipped_items) do
		-- Second loop cycles through Save/GiveWeapon IDs and checks if they match any of this session's loaded items
		for slot_name, backend_id in pairs(item_slot) do
			if mod:match_backend_id(backend_id) then
				-- This tells the backend that the item is equipped
				backend_items:set_loadout_item(backend_id, career, slot_name)
				
				-- And these tell the front end to do the needful
				if player_career == career then
					-- Weapons and trinkets have their own equip functions
					if slot_name == "slot_ranged" or slot_name == "slot_melee" then
						local inventory_extension = ScriptUnit.extension(player_unit, "inventory_system")
						inventory_extension:create_equipment_in_slot(slot_name, backend_id)
					else
						local attachment_extension = ScriptUnit.extension(player_unit, "attachment_system")
						attachment_extension:create_attachment_in_slot(slot_name, backend_id)
					end
				end
			else
				mod:echo("[SaveWeapon][ERROR] Previous session's equipped item ID does not match any loaded items (" .. backend_id)
			end
		end
	end
	
end


-- # Load and equip weapons on game start # --
-- This function runs when the player model loads in
-- We let the hook run once to load our stuff, then we disable the hook since we don't need it any more
mod:hook_safe(BulldozerPlayer, "spawn", function(self, optional_position, optional_rotation, is_initial_spawn, ammo_melee, ammo_ranged, healthkit, potion, grenade)
	mod:echo("Loading/equipping saved items...")
	
	mod:load_items()
	
	--mod:echo("Attempting to equip saved items.")
	mod:equip_saved_items_on_startup()
	--mod:echo("...")

	-- Disable hook; it has served its use
	mod:hook_disable(BulldozerPlayer, "spawn")
end)


-- # Catch previous session's equipped GiveWeapon/SaveWeapon items # --
-- This function runs once for each career on start-up, cycling through equipped items to check if they're broken
-- Backend ID's of previously equipped items can be caught here, even if the item no longer exists
-- Thus we have a way to know if a GiveWeapon/SaveWeapon item was used last session
local item_slot_list = {
	"slot_ranged",
	"slot_melee",
	"slot_necklace",
	"slot_trinket_1",
	"slot_ring",
}
mod:hook(PlayFabMirror, "_set_inital_career_data", function(func, self, character_id, character_data)
	local career_name = self._career_lookup[character_id]
	
	-- This table saves custom item backend ID's for the specific character
	local load_items = {}
	
	-- Cut-down version of the original function's loop
	-- We're just checking if a slot has a ghost ID from one of our items
	for i = 1, #item_slot_list, 1 do
		local slot_name = item_slot_list[i]
		if character_data[slot_name] and character_data[slot_name].Value then
			local value = character_data[slot_name].Value
			-- If the backend ID is ours, keep track of it for later
			if mod:is_backend_id_from_mod(value) then
				load_items[slot_name] = value
			end
		end
	end

	-- Custom backend IDs from the mod are passed on to the public table
	-- Only insert if anything's been put into 'load_items', no need to clutter the table
	if next(load_items) then
		mod.last_session_equipped_items[career_name] = load_items
	end
	
	-- Debug
	--mod:echo("_set_inital_career_data (" .. career_name .. ")")

	return func(self, character_id, character_data)
end)


--	________________
--	# SAVING ITEMS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- # Save an item # --
-- Saves the item in user_data.config
mod.save_item = function(self, backend_id, savestring)
	local save_id = mod:get_backend_save_id(backend_id)
	
	mod.saved_items[save_id] = savestring
	table.sort(mod.saved_items)
	mod:set("saved_items", mod.saved_items)
	
	table.insert(mod.last_saved_items, backend_id) -- Add to last saved
	mod:add_delete_weapon_command(backend_id) -- Create a chat command to delete the specified item
end

-- # MoreItemsLibrary create item hook # --
-- Hooking MoreItemsLibrary to retreive item data of a created item
mod:hook_safe(MoreItemsLibrary, "add_mod_items_to_local_backend", function(self, items, mod_name)
	-- Make sure the new item is created by one of these mods.
	if mod_name == "GiveWeapon"
	or mod_name == "SaveWeapon"
	then
		for item_num = 1, #items do
			local item = items[item_num]
			
			--[[
			-- # Old debugging messages # --
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
			
			local backend_id = item.mod_data.backend_id
			local savestring = mod:generate_item_string(skin, trait, properties)
			
			if mod_name == "GiveWeapon" then
				-- Only save if auto-save is enabled
				if mod:get("auto_save") then
					mod:save_item(backend_id, savestring)
					
					--mod:echo("[SaveWeapon] Saved item \"" .. mod:get_backend_save_id(backend_id) .. "\"")
				else
					mod:add_save_weapon_command(backend_id, savestring)
					
					--mod:echo("[SaveWeapon] Auto-save disabled. Use command \"/sw_save_*item_name*\" to save this item.")
				end
			end
			
			-- Add item backend to the list of items created this session
			-- This will catch both newly created (GiveWeapon) and loaded (SaveWeapon) items
			local created_item_data = {
				backend_id = backend_id,
				savestring = savestring,
			}
			table.insert(mod.created_items, 1, created_item_data)
		end
	end
end)




--	_____________
--	# FAVORITES #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯

-- # Mark favorite # --
mod:hook_safe(ItemHelper, "mark_backend_id_as_favorite", function(backend_id, save)
	-- Only act if the item comes from this mod or GiveWeapon
	if mod:is_backend_id_from_mod(backend_id) then
		--mod:echo('Marked ID \"' .. tostring(backend_id).. '\"')
		
		local save_id = mod:get_backend_save_id(backend_id)
		mod.saved_items[save_id] = mod:savestring_set_favorite(mod.saved_items[save_id], true)
		
		-- Save the favorite change
		mod:set("saved_items", mod.saved_items)
	end
end)

-- # Unmark favorite # --
mod:hook_safe(ItemHelper, "unmark_backend_id_as_favorite", function(backend_id)	
	-- Only act if the item comes from this mod or GiveWeapon
	if mod:is_backend_id_from_mod(backend_id) then
		--mod:echo('Unmarked ID \"' .. tostring(backend_id).. '\"')
		
		local save_id = mod:get_backend_save_id(backend_id)
		mod.saved_items[save_id] = mod:savestring_set_favorite(mod.saved_items[save_id], false)
		
		-- Save the favorite change
		mod:set("saved_items", mod.saved_items)
	end
end)

-- # Flush dead favorites on game start # --
-- On game launch you can have "dead" favorite entries due to the mods. 
-- This should flush them from the list and prevent complications with favorite items. 
-- When done it disables itself, never to run again.
mod:hook(BackendInterfaceItemPlayfab, "_refresh_items", function(func, self)
	--mod:echo("Flushing backend IDs...")
	
	local favorite_backend_ids = ItemHelper.get_favorite_backend_ids()
	if favorite_backend_ids then
		for backend_id, _ in pairs(favorite_backend_ids) do
			if mod:is_backend_id_from_mod(backend_id) then
				favorite_backend_ids[backend_id] = nil
				
				--mod:echo('Removed backend id \"' .. backend_id .. '\" from favorite_backend_ids')
			end
		end
	end
	
	mod:hook_disable(BackendInterfaceItemPlayfab, "_refresh_items") -- Make sure this doesn't run again
	
	return func(self)
end)

--	_________________
--	# CHANGE RARITY #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- # Changes displayed rarity of all GiveWeapon and SaveWeapon items # --
mod.set_created_items_rarity = function(self, rarity)
	local backend_items = Managers.backend:get_interface("items")
	for _, created_item in pairs(mod.created_items) do
		local item = backend_items:get_item_from_id(created_item.backend_id)
		item.rarity = rarity
		item.data.rarity = rarity
		item.CustomData.rarity = rarity
	end
end

-- # Detect when the rarity setting is changed # --
local old_rarity_setting = mod:get("displayed_rarity")
mod.on_setting_changed = function()
	-- Check to see if it was the rarity setting that was changed
	local rarity = mod:get("displayed_rarity")
	if rarity == old_rarity_setting then
		return
	end
	old_rarity_setting = rarity
	
	mod:set_created_items_rarity(rarity)
end

-- # Set the rarity of a newly created GiveWeapon item according to the mod setting # --
mod:hook(GiveWeapon, "create_weapon", function(func, item_type, give_random_skin, rarity, no_skin)
	rarity = mod:get("displayed_rarity")
	return func(item_type, give_random_skin, rarity, no_skin)
end)

