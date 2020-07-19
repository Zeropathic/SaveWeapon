# Changelog

**Version 1.2.3**
 - Fixed an issue where, when loading items, the mod would think volley crossbows were normal crossbows

**Version 1.2.2**
 - Fixed broken inventory sorting that would happen if you deleted an item while in the inventory view

**Version 1.2.1**
 - Added functionality to delete modded items by hovering over them and pressing a hotkey
 - Added a keybind (see mod menu) to undo the last item deletion, same as "/sw_undo"
 - Fixed the auto-equipping of previous session's equipped mod items
 - Added a mod menu setting to toggle the auto-equipping functionality on/off

**Version 1.1 (Season 3 update)**
 - Fixed an error with a broken hook on start-up.

**Version 1.0.3**
 - Fixed a potential crash that could occur if you used the 'sw_delete' chat command while the inventory view was open.

**Version 1.0.2 (Hotfix)**
 - Fixed an issue that prevented loaded gear from being auto-equipped on game start-up.
 - The mod was mistaking your created Executioner Swords for Two-Handed Swords when loading items, and the mix-up was causing some issues. This has been fixed.

**Version 1.0.1 (WoM hotfix)**
 - Fixed an issue where, if the inventory view was open and you tried to delete an item equipped by your currently viewed career, the unequipping of the item would fail and it wouldn't be properly deleted.

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
