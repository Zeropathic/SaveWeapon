# SaveWeapon Beta
Saves items created with the GiveWeapon mod and loads them into your inventory next time you launch the game.

Compatible with the Loadout Manager and Weapon Kill Counter mods, and also supports inventory favorites (hover an item and press F).

Chat commands are included to offer some control over saved items.

Command list (use in-game chat):
 - */sw_save_last* (saves the last created unsaved item)
 - */sw_save_%item_name%* (saves a specified unsaved item, useful if auto-save is off - start typing and auto-fill will help you)
 - */sw_delete_last* (deletes last created item)
 - */sw_delete_%item_name%* (deletes specified item - auto-fill will show options when you start typing)
 - */sw_undo* (undoes the last deletion in case you messed up)

When an item is created using GiveWeapon, it's saved in: 
 - *\Users\YourNameHere\AppData\Roaming\Fatshark\Vermintide 2\user_settings.config*

Open it and ctrl+f "saved_items" to see your entries. Any edits made while the game is running will likely be overwritten, so if you must change something do so out of game.


Special thanks to Zaphio, Prop Joe, and the Vermintide Modders discord for helping me out whenever I have questions about coding.
 

# Changelog

**Version 1.0**
 - We're out of beta!
 - Removed a debug line that dumped some data to the console log; would bloat the log file slightly.
 - Rewrote some of the code used to load items; savestring parser should be a bit more flexible and less strict about the order of the savestring segments.
 - The commands to delete weapons now also deletes the custom item from your inventory, as well as from your save file.

**Version 0.12**
 - Added support for Prop Joe's AllHats mod; equipped hats, portraits, and skins will now be remembered next game launch.

**Version 0.11**
- Changed method for equipping saved items; rather than manually equipping them after the player character is loaded, the backend data is modified beforehand so that the game automatically equips the correct items.
- Some minor code cleanup and commenting.
- Included source code in the Steam Workshop download.

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
