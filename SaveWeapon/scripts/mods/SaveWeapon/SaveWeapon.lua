--[[

	================
	= SAVE WEAPONS =
	================

	 v. 0.02

]]--


local mod = get_mod("SaveWeapon")


-- I'm not sure what this is, but I need it for an if-check in the GiveWeapon hook function or longbows will cause trouble.
local pl = require'pl.import_into'()

mod:dofile("scripts/mods/SaveWeapon/NameReferenceList")

--
mod.give_weapon = get_mod("GiveWeapon")
mod.more_items_library = get_mod("MoreItemsLibrary")

-- Not sure these even work
fassert(mod.give_weapon, "SaveWeapon must be lower than GiveWeapon in your launcher's load order.")
fassert(mod.more_items_library, "SaveWeapon must be lower than MoreItemsLibrary in your launcher's load order.")

--

mod.saved_items = {}

-- Create user_settings.config entry if there isn't one
if not mod:get("saved_items") then
	mod:set("saved_items", mod.saved_items)
end

mod.saved_items = mod:get("saved_items")



--[[

weapon_name + illusion + trait + property...

(Illusion name can be shortened since the start of it seems to always be the same as the weapon name)
WRONG: Illusion name prefix doesn't always correspond with weapon name - full illusion string required (that or some reference table)

Readable and relatively intuitive for manual editing (syntax pending)

storage might look like this:

saved_items = [
	"es_1h_mace/es_1h_mace_skin_02/melee_timed_block_cost/attack_speed/crit_chance",
	"necklace_03/nil/necklace_increased_healing_received/health/stamina",
	"ring_05/blahblah",
	"trinket/yadayada"
]

]]--




--[[	_____________
		LOADING ITEMS
		¯¯¯¯¯¯¯¯¯¯¯¯¯
]]--

-- Takes the saved string and returns its substrings as a table
--[[
	String anatomy:
		[1] = item name
		[2] = skin name (Accessories use "nil" here)
		[3] = trait name
		[4] = property 1
		[5] = property 2
		[6] = property 3... and so on
		
	Maybe I should put a hard cap at 2 properties, but GiveWeapon doesn't so for now I didn't bother. Theoretically you could have one of each property.
]]--



mod.separate_strings = function(item_string)
	local item_strings = {}
	
	for w in string.gmatch(item_string, "[^/]+") do
		--mod:echo(w)
		table.insert(item_strings, w)
	end
	
	--for i = 1, #item_strings do
		--mod:echo(item_strings[i])
	--end
	
	return item_strings
end

-- Loads the saved items
-- Weird bug: first item in the saved list is created twice? I don't really get it.
mod.load_items = function()
	--mod:echo("Loading items...")
	
	mod.saved_items = mod:get("saved_items")
	
	local item_strings
	for i = 1, #mod.saved_items do
		item_strings = mod.separate_strings(mod.saved_items[i])
		
		-- Trying to more or less copy how GiveWeapon uses the items library thing, I don't really know what I'm doing
		local name = item_strings[1]
		local skin = item_strings[2]
		
		local trait = { mod.trait_name_short2long(item_strings[3]) } -- Convert the shortened trait name back to its full name
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
		local rnd = math.random(1000000) -- uhh yeah
		local new_backend_id =  tostring(name) .. "_" .. rnd .. "_from_SaveWeapon"
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
		if skin ~= "nil" then
			entry.mod_data.CustomData.skin = skin
			entry.mod_data.skin = skin
			entry.mod_data.inventory_icon = WeaponSkins.skins[skin].inventory_icon
		end
		
		entry.rarity = "exotic"

		entry.rarity = "default"
		entry.mod_data.rarity = "default"
		entry.mod_data.CustomData.rarity = "default"

		mod.more_items_library:add_mod_items_to_local_backend({entry}, "SaveWeapon")
		Managers.backend:get_interface("items"):_refresh()
		
		--mod:echo(i)
	end
	
	mod:echo("SaveWeapon: " .. #mod.saved_items .. " items loaded.")
end

-- Forcibly load items with "/saveweapon_load"
mod:command("saveweapon_load", "Load all saved GiveWeapon items", function()
    --mod:echo("command: saveweapon_load")
	mod.load_items()
end)

-- Load weapons roughly on game start
-- Need to use this rather than on mods loaded since some of the game stuff used isn't available yet
mod.on_game_state_changed = function(status, state_name)
	if status == "enter" 
	and state_name == "StateIngame" 
	and not rawget(_G, "SaveWeapon_OnStartup_Loaded")
	then
		mod.load_items()
		rawset(_G, "SaveWeapon_OnStartup_Loaded", true)
	end
end


--[[	____________
		SAVING ITEMS
		¯¯¯¯¯¯¯¯¯¯¯¯
]]--

-- Generates a string for saving the item with
mod.generate_item_string = function(name, skin, traits, properties)
	local item_string = name
	
	item_string = item_string .. "/" .. skin -- Will be "nil" for necklace/charm/trinket

	-- Hypothetically this loop could give me multiple trait strings, but since GiveWeapon doesn't support multiple traits it won't happen.
	for _, trait_name in ipairs(traits) do
		item_string = item_string .. "/" .. mod.trait_name_long2short(trait_name) -- Shorten trait name to a more concise string
	end
	
	for _, prop_name in ipairs(properties) do
		item_string = item_string .. "/" .. prop_name
	end
	
	return item_string
end

-- Saves the item in user_data.config
mod.save_item = function(name, skin, traits, properties)
	item_string = mod.generate_item_string(name, skin, traits, properties)
	
	mod:echo("item_string = " .. item_string)
	
	table.insert(mod.saved_items, 1, item_string)
	table.sort(mod.saved_items)
	
	mod:set("saved_items", mod.saved_items)
end


-- Hooking the GiveWeapon mod to detect item creation
mod:hook(mod.give_weapon, "create_weapon", function(func, item_type, give_random_skin)
	
	--mod:echo("item_type = " .. tostring(item_type))
	
	local skin = tostring(mod.give_weapon.skin_names[mod.give_weapon.sorted_skin_names[mod.give_weapon.skins_dropdown.index]])
	--mod:echo("skin = " .. skin)
	
	local custom_properties = "{"
	for _, prop_name in ipairs( mod.give_weapon.properties ) do
		custom_properties = custom_properties..'\"'..prop_name..'\":1,'
		--mod:echo("prop_name = " .. tostring(prop_name))
	end
	custom_properties = custom_properties.."}"
	
	
	
	--mod:echo("properties = " .. custom_properties)

	local custom_traits = "["
	for _, trait_name in ipairs( mod.give_weapon.traits ) do
		custom_traits = custom_traits..'\"'..trait_name..'\",'
	end
	custom_traits = custom_traits.."]"
	
	--mod:echo("traits = " .. custom_traits)
	
	-- I'm not 100 sure what this does but certain things get wonky if I don't. Copied from GiveWeapon.
	-- Without the checks es_longbow keeps being ID'd as ww_longbow or es_longbow_tutorial and such
	if not mod.current_careers then
		local player = Managers.player:local_player()
		local profile_index = player:profile_index()
		mod.current_careers = pl.List(SPProfiles[profile_index].careers)
	end
	local current_career_names = mod.current_careers:map(function(career) return career.name end)
	
	local key = item_type
	for item_key, item in pairs( ItemMasterList ) do
		if item.item_type == item_type 
		and item.template 
		and item.can_wield
		and pl.List(item.can_wield) -- check if the item is valid career-wise
			:map(function(career_name) return current_career_names:contains(career_name) end)
			:reduce('or')
		then
			key = item_key
		end
	end
	
	mod:echo("key = " .. key)
	
	mod.save_item(tostring(key), skin, mod.give_weapon.traits, mod.give_weapon.properties)
	
	return func(item_type, give_random_skin)
end)
