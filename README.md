# SaveWeapon Beta
Mod that can save weapons that have been created using GiveWeapon.

Command list (use in-game chat):
 - */sw_delete_last* (deletes last saved item entry)
 - */sw_delete_%item_name%* (auto-fill helps you) (deletes specified item's entry)
 - */sw_undo* (undoes last delete action)

Has bare bones functionality: when an item is created using GiveWeapon, it's saved in: 
 - \Users\YourNameHere\AppData\Roaming\Fatshark\Vermintide 2\user_settings.config

Open it and ctrl+f "saved_items" to see your entries. Editing it while in-game is unlikely to work too well.

The items in this list are loaded/created on game start.
 
 
# Changelog

**Version 0.10**
- Created items will now stay equipped between game sessions.
- Small syntax changes (using mod:function() instead of mod.function() across the code)

**Version 0.09**
- Created items should now be fully compatible with Loadout Manager and Weapon Kill Counter. (It sort of worked previously, but only with loaded items - not freshly created ones.)
- Mod option added for auto-saving.
- Mod option added for selecting displayed rarity for created and loaded items. Useful for differentiating them from normal items.
- "/sw_save_%item_name%" command added. Useful if you disable auto-save but want to save an item.

**Version 0.08**
 - Fixed a crash that would happen if you tried loading a weapon with no skin (This would happen if you used GiveWeapon's "Always use default skins" setting)

**Version 0.07**
 - Added chat commands */sw_delete_last*, */sw_delete_%item_name%* (auto-fill will help you), and */sw_undo*

**Version 0.06**
 - Uncommented a line of code that was responsible for running the save function when an item was created (Oopsie)
 - Rearranged stuff inside SaveWeapon.lua

**Version 0.05**
 - Fixed a bug that prevented accessories from being saved or loaded

**Version 0.04**
 - "Mark as favorite" status of created items will now be remembered by the mod and applied to loaded items
 - To support the favorite functionality, some changes have been made to the way the mod saves items
 - Now hooks MoreItemsLibary's create function rather than GiveWeapon's; this offers more direct access to an item's data
 - Moved some functions over to SaveWeapon_utilities.lua

**Version 0.03**
 - NameReferenceList.lua is gone. Functionality moved to the new SaveWeapon_utilities.lua
 - Saved item strings are now checked for errors when loaded

**Version 0.02**
 - Automatic load on game start now works
 - The savestring trait name is shortened. Example: "melee_attack_speed_on_crit" becomes "swift_slaying"
