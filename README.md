# SaveWeapon-WIP
Mod that can save weapons that have been created using GiveWeapon.

Has bare bones functionality: when an item is created using GiveWeapon, it's saved in: 
\Users\YourNameHere\AppData\Roaming\Fatshark\Vermintide 2\user_settings.config

Open it and ctrl+f "saved_items". Manual deletion is currently the only way to clear the list.

The items in this list can be created using the "/saveweapon_load" command.

Known bugs:
 - Automatic loading on game start doesn't work right now. Loading after entering the keep is fine. Use "/saveweapon_load" command
 - The first item in your user_data.config list will be created twice, but only the first time the code runs.
 
 
