# SaveWeapon Beta
Mod that can save weapons that have been created using GiveWeapon.

Has bare bones functionality: when an item is created using GiveWeapon, it's saved in: 
 - \Users\YourNameHere\AppData\Roaming\Fatshark\Vermintide 2\user_settings.config

Open it and ctrl+f "saved_items". Manual deletion is currently the only way to clear or curate the list.

The items in this list are loaded/created on game start. The command "/saveweapon_load" will also load/create the items in the list. There are currently no checks in place to ensure the same item isn't created multiple times.
 
 
# Changelog

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
