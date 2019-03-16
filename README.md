# SaveWeapon-WIP
Mod that can save weapons that have been created using GiveWeapon.

Has bare bones functionality: when an item is created using GiveWeapon, it's saved in: 
 - \Users\YourNameHere\AppData\Roaming\Fatshark\Vermintide 2\user_settings.config

Open it and ctrl+f "saved_items". Manual deletion is currently the only way to clear or curate the list.

The items in this list are loaded/created on game start. The command "/saveweapon_load" will also load/create the items in the list. There are currently no checks in place to ensure the same item isn't created multiple times.
 
 
# Changelog

**Version 0.02**
  - Automatic load on game start now works
  - The savestring trait name is shortened. Example: "melee_attack_speed_on_crit" becomes "swift_slaying".
