# SaveWeapon
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