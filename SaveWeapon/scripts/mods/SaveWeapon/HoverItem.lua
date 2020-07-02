--[[

	======================================
	= SAVE WEAPONS - DETECT HOVERED ITEM =
	======================================


	This file contains functionality to detect when the player hovers over an item in their inventory.
	
	We use this to make a more intuitive and user-friendly way to delete modded items.
	
]]--

local mod = get_mod("SaveWeapon")

-- mod.hero_view	is already being used to track whether we're in the hero view screen
-- It should be 'nil' if false, and not 'nil' if true

mod.item_grid = nil	-- This one more specifically tracks the inventory grid

mod:hook_safe(HeroWindowLoadoutInventory, "on_enter", function(hero_window_inventory)
	mod.item_grid = hero_window_inventory._item_grid
	
	mod:echo("Enter InvGrid")
end)
mod:hook_safe(HeroWindowLoadoutInventory, "on_exit", function(hero_window_inventory)
	mod.item_grid = nil
	
	mod:echo("Exit InvGrid")
end)


-- When the hotkey defined in mod settings is pressed, this function will run
mod.delete_item_keybind_pressed = function()
	-- A check to see if we're in the inventory screen - if not, there's no reason to continue
	if not mod.item_grid then
		mod:echo("[SaveWeapon] Not in inventory screen")
		return
	end
	
	-- Check to see if we're hovering an item at the moment
	local item = mod.item_grid:get_item_hovered()
	if not item then
		mod:echo("[SaveWeapon] No item hovered")
		return
	end
	
	-- If we passed the previous checks, we should be hovering an item at the moment
	-- But before we do anything to it, we need to make sure it's from SaveWeapon or GiveWeapon
	if not mod:is_backend_id_from_mod(item.backend_id) then
		mod:echo("[SaveWeapon] " .. tostring(item.backend_id) .. " hovered; ID not from mod")
		return
	end
	
	mod:echo("[SaveWeapon] " .. tostring(item.backend_id) .. " hovered. Is modded!")
end

