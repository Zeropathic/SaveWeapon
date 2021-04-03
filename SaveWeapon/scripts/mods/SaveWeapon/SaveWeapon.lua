--[[

	================
	= SAVE WEAPONS =
	================

	Version 1.2.4
	 · Fixed an issue where, when loading items, the mod would would mistake the Bretonnian Sword & Shield for a regular Sword & Shield

	Version 1.2.3
	 · Fixed an issue where, when loading items, the mod would think volley crossbows were normal crossbows
	
	Version 1.2.2
	 · Fixed broken inventory sorting that would happen if you deleted an item while in the inventory view

	Version 1.2.1
	 · I had forgotten to actually let you toggle auto-equipping on game launch on or off. Now you can do so

	Version 1.2
	 · Added functionality to delete modded items by hovering over them and pressing a hotkey
	 · Added a keybind (see mod menu) to undo the last item deletion, same as "/sw_undo"
	 · Fixed the auto-equipping of previous session's equipped mod items
	 · Added a mod menu setting to toggle the auto-equipping functionality on/off
	  

	Summary:
	¯¯¯¯¯¯¯
	This mod saves items created with PropJoe's GiveWeapon mod and loads them up next time you launch the game.
	
	It also keeps created weapons equipped between sessions and remembers inventory favorites.
	
	Saved items are compatible with Loadout Manager and Weapon Kill Counter.
	
	Special thanks to Zaphio, Prop Joe, and others from the Vermintide Modders discord for helping me out whenever I've had questions about coding.


	List of functionality:
	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	 · Saves items created with the GiveWeapon mod and recreates them when you launch the game. 
	   Auto-save can be toggled off in the mod settings, in which case created items can be saved with a chat command.
	 · Deletes Save/GiveWeapon items by either hovering the item and pressing the assigned keybind, or by using chat commands.
	 · (Currently broken) Re-equips previously equipped modded items and cosmetics from last session when you launch the game.
	 · Undo the last item deletion, bringing the item back. This can be repeated for as many times as you've deleted items.
	 

	List of commands:
	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
	 /sw_save_last				-- Saves the last created unsaved item
	 /sw_save_%item_name%		-- Saves the named unsaved item; start typing, and auto-fill will help you
	 /sw_delete_last			-- Deletes the last created item
	 /sw_delete_%item_name%		-- Deletes the specified item. If you start typing, autofill will kick in and you can choose one
	 /sw_undo					-- Undoes last deletion, can be used multiple times if you deleted multiple items

]]--

-- Keeping track of the mods we'll be interacting with
local mod = get_mod("SaveWeapon")
local GiveWeapon = get_mod("GiveWeapon")
local MoreItemsLibrary = get_mod("MoreItemsLibrary")

-- Incorporate a bunch of utility functions tied to this mod
-- Kept in a separate file to reduce clutter
mod:dofile("scripts/mods/SaveWeapon/SaveWeapon_utilities")

-- Error messages
fassert(GiveWeapon, "SaveWeapon must be lower than GiveWeapon in your launcher's load order.")
fassert(MoreItemsLibrary, "SaveWeapon must be lower than MoreItemsLibrary in your launcher's load order.")

-- Create user_settings.config entry if there isn't one
mod.saved_items = {}
if not mod:get("saved_items") then
	mod:set("saved_items", mod.saved_items)
end
mod.saved_items = mod:get("saved_items")

-- Skins are a bit of a special case. We track equipped skins so that we can keep AllHats skins equipped when relaunching the game
-- Normal skins, too; due to some weird quirk, skin changes in the modded realm are not remembered when relaunching
mod.last_skins = {}
if not mod:get("last_skins") then
	mod:set("last_skins", mod.last_skins)
end
mod.last_skins = mod:get("last_skins")

-- Keeping track of all mod item equips the same way now, since Season 3 changed something with loadout initialization
-- Table structure example:
--[[
	mod.last_equipped items = {
		bw_scholar = {
			slot_melee = %backend_id%
			slot_ring = %backend_id%
			slot_hat = %backend_id%
			...
		},
		wh_captain = {
			slot_ranged = %backend_id%
			...
		},
		...
	},
--]]
mod.last_equipped_items = {}
if not mod:get("last_equipped_items") then
	mod:set("last_equipped_items", mod.last_equipped_items)
end
mod.last_equipped_items = mod:get("last_equipped_items")

-- When the game launches, data regarding custom items equipped from last session is temporarily stored here
-- This data is used to re-equip those items, then the table gets wiped.
-- Table structure looks like this:
--[[
	mod.last_session_equipped_items = {
		bw_scholar = {
			slot_melee = %backend_id%
			slot_ring = %backend_id%
			slot_hat = %backend_id%
			...
		}
		wh_captain = {
			slot_ranged = %backend_id%
			...
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
--		mod.deleted_items[1] = { save_id, savestring, saved }
mod.deleted_items = mod:persistent_table("SaveWeapon_session_deleted_items", {})

-- Variables used to track whether the Hero View and Inventory screens are open
mod.hero_view = nil 	-- The hero overview window - used when properly unequipping an item while it is being deleted
mod.item_grid = nil		-- The inventory screen's item grid in particular - used for the delete-on-hover hotkey
mod.item_filter = nil	-- Used in item_grid's functions to filter out items it doesn't want to display - we use it to refresh the item_grid page



--	_____________________
--	# VARIABLE TRACKERS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- # Hook when the player enters and exits HeroView ("I" screen) # --
-- We track some variables for use in 'mod.unequip_item'; it needs to know whether this screen is open, in which case special steps are taken to unequip an item
mod:hook_safe(HeroViewStateOverview, "on_exit", function(self, params)
	mod.hero_view = nil
end)
mod:hook_safe(HeroViewStateOverview, "on_enter", function(self, params)
	mod.hero_view = self
	
	local player = self.player_manager:player_from_peer_id(self.peer_id)
	local unit = player.player_unit
	local profile = SPProfiles[FindProfileIndex(self.hero_name)]
	local career_data = profile.careers[self.career_index]
	
	-- I use the career name when re-equipping base power items after deleting a custom item, and this is a very convenient place to store it
	mod.hero_view.career_name = career_data.name
end)

-- # Hook when the player enters and exits the Inventory view # --
-- We track the item grid (the part where all your items are listed) for use when deleting items by hovering them and pressing a hotkey
mod:hook_safe(HeroWindowLoadoutInventory, "on_enter", function(hero_window_inventory)
	mod.item_grid = hero_window_inventory._item_grid
end)
mod:hook_safe(HeroWindowLoadoutInventory, "on_exit", function(hero_window_inventory)
	mod.item_grid = nil
end)

-- # Track item_grid's last used item_filter
mod:hook_safe(ItemGridUI, "change_item_filter", function(self, item_filter, change_page)
	mod.item_filter = item_filter
end)



--	_________________
--	# CHAT COMMANDS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

--	/sw_load_all
-- ! Debug command !
-- Forcibly loads your saved items, should you need to do so for whatever reason.
-- There's a chance it might cause bugs with last saved/created items
--[[
mod:command("sw_load_all", "Load all saved GiveWeapon items", function()
	mod:load_items()
end)
--]]

--	/sw_save_last
-- Saves the last created item
mod.update_save_last_command = function(self)
	local backend_id, index = mod:get_last_unsaved_item()
	--mod:echo(tostring(backend_id) .. " (" .. tostring(index) .. ")")
	if not backend_id then
		return
	end
	local item_id = mod:get_backend_save_id(backend_id)
	local command_description = 'Save last created item ("' .. item_id .. '")'
	mod:command_remove("sw_save_last")
	if backend_id then
		mod:command("sw_save_last", command_description, function()
			local savestring = mod.created_items[index].savestring
			mod:save_item(backend_id, savestring)
		end)
	end
end

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
	
	mod:update_save_last_command()
end
-- Removes the save command for the specified item
mod.remove_save_weapon_command = function(self, backend_id)
	local item_id = mod:get_backend_save_id(backend_id)
	local command_name = "sw_save_" .. item_id
	mod:command_remove(command_name)
end

--	/sw_delete_last
-- Delete last saved item
-- The command's description is updated with the name of the last created item every time one is created
mod.update_delete_last_command = function(self)
	local last_item = mod.created_items[1]
	local backend_id = last_item.backend_id
	local item_id = mod:get_backend_save_id(backend_id)
	local command_description = 'Delete last created item ("' .. item_id .. '")'
	mod:command_remove("sw_delete_last")
	if last_item then
		mod:command("sw_delete_last", command_description, function()
			if backend_id then
				-- Remove generated delete chat command
				local save_id = mod:get_backend_save_id(backend_id)
				local command_name = "sw_delete_" .. save_id
				mod:command_remove(command_name)
				
				-- Delete the saved entry and remove from created table
				mod:delete_item(backend_id)
				mod:update_delete_last_command()
			else
				mod:echo("[SaveWeapon] Saved list empty; nothing to delete")
			end
		end)
	end
end

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
	
	-- Create the command
	mod:command(command_name, command_description, function()
		mod:delete_item(backend_id)
		mod:command_remove(command_name) -- Command is removed once it has been executed
	end)
	
	-- Update "/sw_delete_last" command
	mod:update_delete_last_command()
end
-- Removes the delete command for the specified item
mod.remove_delete_weapon_command = function(self, backend_id)
	local item_id = mod:get_backend_save_id(backend_id)
	local command_name = "sw_delete_" .. item_id
	mod:command_remove(command_name)
end

-- # Undo last item deletion # --
mod.undo_delete = function(self)
	local deleted_item = mod.deleted_items[1]
	if deleted_item then
		local backend_id = deleted_item.backend_id
		local savestring = deleted_item.savestring
		local saved = deleted_item.saved
		
		-- Re-create the item
		mod:create_saved_item(backend_id, savestring)
		
		if saved then
			mod:save_item(backend_id, savestring)
		end
		table.remove(mod.deleted_items, 1)
		
		local msg = '[SaveWeapon] \"' .. mod:get_backend_save_id(backend_id) .. '\" restored'
		if saved then
			msg = msg .. '\" re-created and saved'
		else
			msg = msg .. '\" re-created'
		end
		mod:echo(msg)
	else
		mod:echo("[SaveWeapon] Nothing to undo; nothing has been deleted")
	end
end

--	/sw_undo
-- Undoes last delete action
mod:command("sw_undo", "Undoes the last delete action", function()
	mod:undo_delete()
end)

-- # Undo hotkey pressed # --
-- When the hotkey defined in mod settings is pressed, this function will run and undo the last deleted item
mod.undo_delete_keybind_pressed = function()
	-- A check to see if we're in the inventory screen - if not, there's no reason to continue
	if not mod.item_grid then
		return
	end
	mod:undo_delete()
end


--	__________________
--	# DELETING ITEMS #
--	¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

-- # Delete created item # --
-- Deletes a created item, both from your inventory and your save file.
mod.delete_item = function(self, backend_id)
	local saved, savestring = mod:is_item_saved(backend_id)
	
	-- Remove item from created_items table
	for i = 1, #mod.created_items do
		if mod.created_items[i].backend_id == backend_id then
			table.remove(mod.created_items, i)
			break
		end
	end
	
	local deleted_entry = {
		backend_id = backend_id,
		savestring = savestring,
		saved = false
	}
	if saved then
		deleted_entry.saved = true
		
		-- Remove item from last_saved_items table
		for i, str in ipairs(mod.last_saved_items) do
			if str == backend_id then
				table.remove(mod.last_saved_items, i)
				break
			end
		end
	else
		-- If the item was not saved, remove the chat command to save it
		mod:remove_save_weapon_command(backend_id)
		mod:update_save_last_command()
	end
	
	-- Add item to deleted_items table (in case the user wants to bring it back again with "/sw_undo")
	table.insert(mod.deleted_items, 1, deleted_entry)
	
	-- Remove item from backend
	mod:unequip_item(backend_id)
	local backend_items = Managers.backend:get_interface("items")
	backend_items:_refresh()
	
	MoreItemsLibrary:remove_mod_items_from_local_backend({backend_id}, "SaveWeapon")
	
	local save_id = mod:get_backend_save_id(backend_id)
	mod.saved_items[save_id] = nil
	mod:set("saved_items", mod.saved_items)
	
	-- Update inventory UI to remove the deleted item from the listing
	--[[
	-- Old code
	mod:pcall(function()
		if GiveWeapon.loadout_inv_view then -- Making use of GiveWeapon's inventory screen tracking
			local backend_items = Managers.backend:get_interface("items")
			backend_items:_refresh()
			local inv_item_grid = GiveWeapon.loadout_inv_view._item_grid
			if inv_item_grid then
				local index = inv_item_grid._selected_page_index
				local settings = inv_item_grid._category_settings[index]
				local item_filter = settings.item_filter
				
				inv_item_grid:change_item_filter(item_filter, false)
				inv_item_grid:repopulate_current_inventory_page()
			end
		end
	end)
	--]]
	mod:pcall(function()
		-- We check if we're in the Item Grid view - if yes, refresh the item backend and repopulate the inventory page
		if mod.item_grid then
			local backend_items = Managers.backend:get_interface("items")
			backend_items:_refresh()
			
			-- Repopulate the inventory page so that our deleted item's icon is removed from the screen
			-- If we don't do this, and the player were to try and equip the deleted item, the game would crash (trying to equip a 'nil' item)
			mod.item_grid:change_item_filter(mod.item_filter, false)
			mod.item_grid:repopulate_current_inventory_page()
		end
	end)
	
	-- Remove the chat command to delete the item
	self:remove_delete_weapon_command(backend_id)
	
	-- Notify the player with a confirmation that the item has been deleted
	mod:echo('[SaveWeapon] Deleted "' .. tostring(backend_id) .. '"' .. '\n("/sw_undo" to undo)') 
end

-- # Delete created item on hover # --
-- When the hotkey defined in mod settings is pressed, this function will run
-- If a Give- or SaveWeapon item is hovered then, it will be deleted
mod.delete_item_keybind_pressed = function()
	-- A check to see if we're in the inventory screen - if not, there's no reason to continue
	if not mod.item_grid then
		return
	end
	
	-- Check to see if we're hovering an item at the moment
	local item = mod.item_grid:get_item_hovered()
	if not item then
		return
	end
	
	-- If we passed the previous checks, we should be hovering an item at the moment
	-- But before we do anything to it, we need to make sure it's from SaveWeapon or GiveWeapon
	if not mod:is_backend_id_from_mod(item.backend_id) then
		return
	end
	
	-- Item is from either SaveWeapon or GiveWeapon, else we wouldn't have gotten this far. We're good to go!
	mod:delete_item(item.backend_id)
end

-- # Unequip item # --
-- Unequips the specified item from all careers and equips base power 5 items in its place
mod.unequip_item = function(self, backend_id)
	local player = Managers.player:local_player()
	local player_unit = player.player_unit
	
	local career_extension = ScriptUnit.extension(player_unit, "career_system")
	local current_career = career_extension:career_name()
	
	local backend_items = Managers.backend:get_interface("items")
	local item = backend_items:get_item_from_id(backend_id)
	local base_item_backend_id = mod:find_base_item(item.key)
	
	local slot_name = "slot_" .. item.data.slot_type
	if slot_name == "slot_trinket" then
		-- I don't know why it be like it is, but it do
		slot_name = "slot_trinket_1"
	end
	local loadouts = backend_items._loadouts
	
	-- Cycle through each career to see if the item is equipped on them
	if base_item_backend_id then
		for career, loadout in pairs(loadouts) do
			--mod:echo('career = "' .. tostring(career) .. '", ' .. slot_name .. ' = "' .. loadout[slot_name] .. '"')
			
			-- Check to see if the item is the one we're looking for
			if loadout[slot_name] == backend_id then
			
				-- If the HeroView (equipment screen) is open and the currently viewed career is the same as the currently checked career,
				-- we use a separate method which will properly update the equipped item icons
				if mod.hero_view and mod.hero_view.career_name == career then
					local base_item = backend_items:get_item_from_id(base_item_backend_id)
					mod.hero_view:_set_loadout_item(base_item, slot_name)	-- (base_item, item_slot)
					
				-- If we're not in HeroView and the currently played career is the same as the currently checked career,
				-- we use this method, which ensures that the base power item is properly equipped
				-- Includes a special case for when the current career has the item equipped, and Hero View is open but is displaying a different career
				elseif ( not mod.hero_view and career == current_career ) 
				or ( mod.hero_view and career == current_career and mod.hero_view_career_name ~= current_career ) 
				then
					backend_items:set_loadout_item(base_item_backend_id, career, slot_name)
					if slot_name == "slot_ranged" or slot_name == "slot_melee" then
						local inventory_extension = ScriptUnit.extension(player_unit, "inventory_system")
						inventory_extension:create_equipment_in_slot(slot_name, base_item_backend_id)
					else
						local attachment_extension = ScriptUnit.extension(player_unit, "attachment_system")
						attachment_extension:create_attachment_in_slot(slot_name, base_item_backend_id)
					end
				
				-- If the currently checked career is not currently played or viewed, we just need to use this to equip the base power item
				else
					backend_items:set_loadout_item(base_item_backend_id, career, slot_name)
				end
			end
		end
	end
end

-- # Debug function # --
--  "/unequip slot_melee"
-- Unequips the item in the specified slot for the currently played career.
--[[
mod:command("unequip", "test function", function(which_slot)
	local player = Managers.player:local_player()
	local player_unit = player.player_unit
	local career_extension = ScriptUnit.extension(player_unit, "career_system")
	local career_name = career_extension:career_name()
	local backend_items = Managers.backend:get_interface("items")
	local loadout = backend_items._loadouts[career_name]
	local slots = {
		"slot_melee",
		"slot_ranged",
		"slot_necklace",
		"slot_ring",
		"slot_trinket_1",
	}
	if which_slot == "slot_trinket" then
		which_slot = "slot_trinket_1"
	end
	for i = 1, #slots do
		if which_slot == slots[i] then
			local slot_name = which_slot

			local equipped_backend_id = loadout[slot_name]
			local item = backend_items:get_item_from_id(equipped_backend_id)
			local item_key = item.key
			
			--mod:echo(equipped_backend_id)
			mod:unequip_item(equipped_backend_id)
			break
		end
	end
end)
--]]



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
		backend_id = "item_name_IDNUM_from_GiveWeapon"
		
	Which might look like this:
		backend_id = "es_1h_mace_21932_from_GiveWeapon"

	The savestring is converted into an array, which looks like this:

	Saved item array anatomy:
		[1] = is favorite ("true"/"false")
		[2] = skin name (Accessories use "nil" here)
		[3] = trait name
		[4] = property 1
		[5] = property 2
		[6] = property 3... and so on
		
	Item name/type is extrapolated from the name of the saved variable
	
	Maybe I should put a hard cap at 2 properties, but GiveWeapon doesn't so for now I didn't bother. Theoretically you could have one of each property.
]]--


-- # Create saved item # --
-- Takes an item backend ID and a savestring and creates an item based on it
-- Returns a table with detailed errors if it for some reason can't create the item
mod.create_saved_item = function(self, backend_id, savestring)
	local item_key = mod:get_item_name_from_save_id(backend_id)
	local savestring_data = mod:parse_savestring(item_key, savestring)
	
	if mod:is_item_key_valid(item_key) then
		local skin = savestring_data.skin
		if skin == "nil" then
			skin = nil
		end
		
		local custom_traits = "["
		for i = 1, #savestring_data.traits do
			custom_traits = custom_traits .. '\"' .. savestring_data.traits[i] .. '\",'
		end
		custom_traits = custom_traits .. "]"
		
		local properties = {}
		for i = 1, #savestring_data.properties do
			properties[savestring_data.properties[i]] = 1
		end
		
		local custom_properties = "{"
		for i = 1, #savestring_data.properties do
			custom_properties = custom_properties..'\"' .. savestring_data.properties[i] .. '\":1,'
		end
		custom_properties = custom_properties .. "}"
		
		local rarity = mod:get("displayed_rarity")
		
		-- Set up item data before using MoreItemsLibrary to create the item
		local new_backend_id = backend_id
		local entry = table.clone(ItemMasterList[item_key])
		entry.mod_data = {
			backend_id = new_backend_id,
			ItemInstanceId = new_backend_id,
			CustomData = {
				-- traits = "[\"melee_attack_speed_on_crit\", \"melee_timed_block_cost\"]",
				traits = custom_traits,
				power_level = "300",
				properties = custom_properties,
				rarity = rarity,
			},
			rarity = rarity,
			-- traits = { "melee_timed_block_cost", "melee_attack_speed_on_crit" },
			traits = table.clone(savestring_data.traits),
			power_level = 300,
			properties = properties,
		}
		entry.rarity = rarity
		
		if skin then
			entry.mod_data.CustomData.skin = skin
			entry.mod_data.skin = skin
			entry.mod_data.inventory_icon = WeaponSkins.skins[skin].inventory_icon
		end
		
		MoreItemsLibrary:add_mod_items_to_local_backend({entry}, "SaveWeapon")
		Managers.backend:get_interface("items"):make_dirty()
		Managers.backend:get_interface("items"):_refresh()
		
		-- Mark as favorite if the save says so
		if savestring_data.favorite then
			-- Disable my hook momentarily so it won't catch this call
			mod:hook_disable(ItemHelper, "mark_backend_id_as_favorite")
			ItemHelper.mark_backend_id_as_favorite(new_backend_id)
			mod:hook_enable(ItemHelper, "mark_backend_id_as_favorite")
		end
		
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
		
		-- Update UI
		mod:pcall(function()
			-- We check if we're in the Item Grid view - if yes, refresh the item backend and repopulate the inventory page
			if mod.item_grid then
				local backend_items = Managers.backend:get_interface("items")
				backend_items:_refresh()
				
				mod.item_grid:change_item_filter(mod.item_filter, false)
				mod.item_grid:repopulate_current_inventory_page()
			end
		end)
	else
		local error = '[SaveWeapon][ERROR] Failed to load item \"' .. mod:get_backend_save_id(backend_id) .. '\": invalid item key'
		mod:echo(error)
	end
	if #savestring_data.errors > 0 and mod:is_item_key_valid(item_key) then
		local error = '[SaveWeapon](' .. mod:get_backend_save_id(backend_id) .. ') Invalid savestring segment'
		if #savestring_data.errors > 1 then
			error = error .. 's'
		end
		error = error .. ': {'
		for i = 1, #savestring_data.errors do
			if i > 1 then
				error = error .. ', '
			end
			error = error .. '\"' .. savestring_data.errors[i] .. '\"'
		end
		error = error .. '}'
		mod:echo(error)
	end

	return mod:is_item_key_valid(item_key), savestring_data.errors
end

-- # Loads the saved items # --
mod.load_items = function(self)
	--mod:echo("Loading items...")
	
	mod.saved_items = mod:get("saved_items")
	
	local items_loaded = 0
	local items_loaded_with_errors = 0
	local items_failed_to_load = 0
	
	for save_id, savestring in pairs(mod.saved_items) do
		local backend_id = save_id .. "_from_GiveWeapon"
		local item_created, errors = mod:create_saved_item(backend_id, savestring)
		
		table.insert(mod.last_saved_items, backend_id) -- Add to last saved (I want to include items loaded on game start in this table)
		
		if item_created then
			items_loaded = items_loaded + 1
			if #errors > 0 then
				items_loaded_with_errors = items_loaded_with_errors + 1
			end
		else
			items_failed_to_load = items_failed_to_load + 1
		end
	end
	
	-- A little message telling the player how many items were loaded.
	if items_loaded > 0 or items_failed_to_load > 0 then
		local msg = "[SaveWeapon] "
		if items_loaded > 0 then
			msg = msg .. items_loaded .. " items loaded"
			if items_loaded_with_errors > 0 then
				msg = msg .. " (" .. items_loaded_with_errors .. " with errors )"
			end
		end
		if items_failed_to_load > 0 then
			if items_loaded > 0 then
				msg = msg .. " / "
			end
			msg = msg .. items_failed_to_load .. " failed"
		end
		mod:echo(msg)
	end
end

--[=[ =#! OBSOLETE VERSION !#=
	This functionality is now handled by .set_equipped_items_on_startup
	
-- # Set items as equipped on game start # --
mod.set_equipped_backend_items = function(self)
	local backend_items = Managers.backend:get_interface("items")
	
	-- First loop goes through all careers that were saved in the table
	-- (Will only contain those who had Save/GiveWeapon items last session)
	for career, item_slot in pairs(mod.last_session_equipped_items) do
		-- Second loop cycles through Save/GiveWeapon IDs and checks if they match any of this session's loaded items
		for slot_name, backend_id in pairs(item_slot) do
			if mod:match_backend_id(backend_id) then
				-- This tells the backend that the item is equipped
				-- It results in the game automatically equipping it once the character is loaded into the game
				backend_items:set_loadout_item(backend_id, career, slot_name)
				
				--[[
				-- Unnecessary
				local loadout = backend_items:get_loadout()
				if loadout then
					-- This would set the equipped item when the character is loaded in, but would not apply to the inventory.
					loadout[career][slot_name] = backend_id
				end
				--]]
				
			-- Special case for AllHats cosmetics
			elseif mod:get_backend_id_suffix(backend_id) == "_from_AllHats" then	
				-- Not actually doing anything different here
				backend_items:set_loadout_item(backend_id, career, slot_name)
			else
				mod:echo("[SaveWeapon][ERROR] Can't find previously equipped item (" .. career .. ": " .. backend_id .. ")")
			end
		end
	end
end
--]=]

--[[
-- # Set skins equipped on game start # --
-- Due to the game being weird about skins we need a separate solution for them
mod.set_equipped_backend_skins = function(self)
	local backend_items = Managers.backend:get_interface("items")
	
	-- We go through all items in 'mod.last_skins' (= 'mod:get("last_skins")') and equip them
	for career, skin_id in pairs(mod.last_skins) do
		if mod:verify_backend_id(skin_id) then
			backend_items:set_loadout_item(skin_id, career, "slot_skin")
			
			--mod:echo("Equipped \"" .. skin_id .. "\" for " .. career)
		else
			mod:echo("[SaveWeapon][ERROR] Previous session's equipped skin ID is invalid (" .. career .. ": " .. skin_id .. ")")
		end
	end
end
--]]

-- # Set items equipped on game start # --
-- This is currently not working
mod.set_equipped_items_on_startup = function(self)
	--[[
		mod.last_equipped_items = {
			career_name = {
				slot_name = "backend_id",
				...
			},
			...
		},
	--]]
	local backend_items = Managers.backend:get_interface("items")
	
	-- Loop through all career names and lots
	for career_name, slots in pairs(mod.last_equipped_items) do
		for slot_name, backend_id in pairs(slots) do
			if mod:verify_backend_id(backend_id) then
				backend_items:set_loadout_item(backend_id, career_name, slot_name)
				
				--mod:echo("Equipped \"" .. backend_id .. "\" in " .. slot_name .. " for " .. career_name)
			else
				mod:echo("[SaveWeapon][ERROR] Previous session's equipped item ID is invalid (" .. career_name .. ": " .. backend_id .. ")")
			end
		end
	end
end

-- # Hook the creation of the item backend # --
-- We need it to exist before we can load our custom items
-- Thanks to Zaphio for suggesting this method
mod:hook_safe(BackendManagerPlayFab, "_create_interfaces", function(...)
	mod:echo("[SaveWeapon] Loading and equipping items...")
	
	-- load_items will read our save data and re-create our items
	mod:load_items()
	
	--[[ =! OBSOLETE != 
	-- This hook runs before the player model is loaded
	-- set_equipped_backend_items will set our custom items as equipped, so that when the player loads they'll already have our items in hand
	mod:set_equipped_backend_items()
	-- ... and set_equipped_backend_skins will set skins. Skins are a bit of a special case, so I'm doing them separately.
	--mod:set_equipped_backend_skins()
	--]]
	
	-- Set previously equipped items on game launch
	if mod:get("auto_equip_on_startup") then
		mod:set_equipped_items_on_startup()
	end
	
	-- Create a hook to detect when items are equipped
	-- Its purpose is to see when an item is equipped so we can save its ID and re-equip it on next game launch
	local backend_items = Managers.backend:get_interface("items")
	mod:hook_safe(backend_items, "set_loadout_item", function(self, backend_id, career_name, slot_name)
		-- mod:echo("set_loadout_item: \"" .. backend_id .. "\" (" .. slot_name .. ")") -- Debug
		
		-- If the equipped item is a skin, save its backend ID to our table
		--[[
		if slot_name == "slot_skin" then
			mod.last_skins[career_name] = backend_id
			mod:set("last_skins", mod.last_skins)
		end
		--]]
		
		--
		-- Track last equipped item's backend ID
		if not mod.last_equipped_items[career_name] then
			mod.last_equipped_items[career_name] = {}
		end
		mod.last_equipped_items[career_name][slot_name] = backend_id
		--
		
		-- Debug stuff
		mod:set("last_equipped_items", mod.last_equipped_items)
		--mod:echo(".last_equipped_items[" .. career_name .. "][" .. slot_name .. "] = " .. tostring(mod.last_equipped_items[career_name][slot_name]))
	end)
	
	-- Disable this hook after it has served its use (probably not necessary since I don't think the function ever runs again)
	mod:hook_disable(BackendManagerPlayFab, "_create_interfaces")
end)


--[[ =#! OBSOLETE !#=
-- # Catch previous session's equipped GiveWeapon/SaveWeapon items # --
-- This function runs once for each career on start-up, cycling through equipped items to check if they're broken
-- Backend ID's of previously equipped items can be caught here, even if the item no longer exists
-- Thus we have a way to know if a GiveWeapon/SaveWeapon item was used last session

-- This check takes place before the items backend exists, so we need to look for traces from equipped items while they're still available
-- This data is then passed on to 'mod.set_equipped_backend_items' via the 'mod.last_session_equipped_items' table
local item_slot_list = {
	"slot_ranged",
	"slot_melee",
	"slot_necklace",
	"slot_trinket_1",
	"slot_ring",
	
	-- For AllHats mod
	"slot_hat",
	"slot_skin",	-- Skins used to be a weird and special case. Now they all seem to be.
	"slot_frame",
}
-- PlayFabMirror (which is the class I want to access) apparently doesn't exist under that label, so we do some roundabout stuff to get to it
mod:hook(BackendInterfaceItemPlayfab, "init", function (func, self, backend_mirror)
	-- "backend_mirror" refers to "PlayFabMirror". And yes, it really is written "inital" in the source code
	mod:hook(backend_mirror, "_set_inital_career_data", function(func, self, career_name, character_data)
	
		-- This table saves custom item backend ID's for the specific character
		local load_items = {}
		
		-- Cut-down version of the original function's loop
		-- We're just checking if a slot has a ghost ID from one of our items
		for i = 1, #item_slot_list, 1 do
			local slot_name = item_slot_list[i]
			
			if character_data[slot_name] and character_data[slot_name].Value then
				local backend_id = character_data[slot_name].Value
				
				-- If the backend ID is ours, keep track of it for later
				if mod:is_backend_id_from_mod(backend_id) then
					load_items[slot_name] = backend_id
				end
			end
		end

		-- Custom backend IDs from the mod are passed on to the public table
		-- Only insert if anything's been put into 'load_items', no need to clutter the table
		if next(load_items) then
			mod.last_session_equipped_items[career_name] = load_items
		end

		return func(self, career_name, character_data)
	end)
	
	return func(self, backend_mirror)
end)
--]]


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
	
	for i = 1, #mod.created_items do
		if mod.created_items[i].backend_id == backend_id then
			mod.created_items[i].saved = true
			break
		end
	end
	
	table.insert(mod.last_saved_items, backend_id) -- Add to last saved
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
			
			local name = item.name
			local skin = item.mod_data.skin
			local trait = item.mod_data.traits[1]
			local properties = {}
			for key, _ in pairs(item.mod_data.properties) do
				table.insert(properties, 1, key)
			end
			
			local backend_id = item.mod_data.backend_id
			local savestring = mod:generate_item_string(skin, trait, properties)
			
			-- Add item backend to the list of items created this session
			-- This will catch both newly created (GiveWeapon) and loaded (SaveWeapon) items
			local created_item_data = {
				backend_id = backend_id,
				savestring = savestring,
				saved = false,
			}
			-- Only save the item if it comes from GiveWeapon and auto save is enabled
			if mod_name == "SaveWeapon" then
				created_item_data.saved = true
			elseif mod_name == "GiveWeapon" and mod:get("auto_save") then
				mod:save_item(backend_id, savestring)
				created_item_data.saved = true
			end
			
			table.insert(mod.created_items, 1, created_item_data)
			
			-- Add command to delete the weapon
			mod:add_delete_weapon_command(backend_id)
			
			-- If the item wasn't saved, create a chat command to save it
			if created_item_data.saved == false then
				mod:add_save_weapon_command(backend_id, savestring)
			end
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
-- ... and apply the updated rarity to all GiveWeapon items
local old_rarity_setting = mod:get("displayed_rarity")
mod.on_setting_changed = function()
	local rarity = mod:get("displayed_rarity")
	if rarity == old_rarity_setting then
		return
	end
	old_rarity_setting = rarity
	
	mod:set_created_items_rarity(rarity)
end

-- # Set the rarity of a newly created GiveWeapon item according to the mod setting # --
-- Thanks to Prop Joe for making his GiveWeapon mod more convenient for me to hook
-- This function lets me tell GiveWeapon which rarity I want a created item to be
mod:hook(GiveWeapon, "create_weapon", function(func, item_type, give_random_skin, rarity, no_skin)
	rarity = mod:get("displayed_rarity")
	return func(item_type, give_random_skin, rarity, no_skin)
end)

