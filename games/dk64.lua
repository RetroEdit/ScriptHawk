local Game = {};

-- TODO: Need to put some grab script state up here because encircle uses it before they would normally be defined
-- This can probably be fixed with a clever reshuffle of grab script state/functions
local object_index = 1;
local object_pointers = {};
local radius = 100;
encircle_enabled = false;
local grab_script_modes = {
	"Disabled",
	"List (Object Model 1)",
	"Examine (Object Model 1)",
	"List (Object Model 2)",
	"Examine (Object Model 2)",
	"List (Loading Zones)",
	"Examine (Loading Zones)",
};
local grab_script_mode_index = 1;
grab_script_mode = grab_script_modes[grab_script_mode_index];

local function switch_grab_script_mode()
	grab_script_mode_index = grab_script_mode_index + 1;
	if grab_script_mode_index > #grab_script_modes then
		grab_script_mode_index = 1;
	end
	grab_script_mode = grab_script_modes[grab_script_mode_index];
end

-------------------------
-- DK64 specific state --
-------------------------

-- TODO: Investigate bone array pointer block at 0x7FA8A0 (USA)
	-- 2 pointers
	-- 1 u32_be
local version; -- 1 USA, 2 Europe, 3 Japan, 4 Kiosk
Game.Memory = {
	["mode"] = {0x755318, 0x74FB98, 0x7553D8, 0x6FFE6C},
	["map"] = {0x7444E4, 0x73EC34, 0x743DA4, 0x72CDE4}, -- TODO: This is actually destination map
	["map_state"] = {0x76A0B1, 0x764BD1, 0x76A2A1, 0x72CDED},
	["exit"] = {0x7444E8, 0x73EC38, 0x743DA8, 0x72CDE8},
	["loading_zone_array"] = {0x7FDCB4, 0x7FDBF4, 0x7FE144, nil}, -- TODO: Kiosk
	["loading_zone_array_size"] = {0x7FDCB0, 0x7FDBF0, 0x7FE140, nil}, -- u16_be -- TODO: Kiosk
	["file"] = {0x7467C8, 0x740F18, 0x746088, nil},
	["character"] = {0x74E77C, 0x748EDC, 0x74E05C, 0x6F9EB8},
	["tb_void_byte"] = {0x7FBB63, 0x7FBA83, 0x7FBFD3, 0x7B5B13},
	["player_pointer"] = {0x7FBB4C, 0x7FBA6C, 0x7FBFBC, 0x7B5AFC},
	["camera_pointer"] = {0x7FB968, 0x7FB888, 0x7FBDD8, 0x7B5918},
	["pointer_list"] = {0x7FBFF0, 0x7FBF10, 0x7FC460, 0x7B5E58},
	["actor_count"] = {0x7FC3F0, 0x7FC310, 0x7FC860, 0x7B6258},
	["linked_list_pointer"] = {0x7F0990, 0x7F08B0, 0x7F0E00, 0x7A12C0},
	["global_base"] = {0x7FCC41, 0x7FCB81, 0x7FD0D1, 0x7B6754},
	["kong_base"] = {0x7FC950, 0x7FC890, 0x7FCDE0, 0x7B6590},
	["menu_flags"] = {0x7ED558, 0x7ED478, 0x7ED9C8, nil},
	["framebuffer_pointer"] = {0x7F07F4, 0x73EBC0, 0x743D30, 0x72CDA0},
	["flag_block_pointer"] = {0x7654F4, 0x760014, 0x7656E4, nil},
	["security_byte"] = {0x7552E0, 0x74FB60, 0x7553A0, nil}, -- As far as I am aware this function is not present in the Kiosk version
	["security_message"] = {0x75E5DC, 0x7590F0, 0x75E790, nil}, -- As far as I am aware this function is not present in the Kiosk version
	["buttons_enabled_bitfield"] = {0x755308, 0x74FB88, 0x7553C8, 0x6FFE5C},
	["joystick_enabled_x"] = {0x75530C, 0x74FB8C, 0x7553CC, 0x6FFE60},
	["joystick_enabled_y"] = {0x755310, 0x74FB90, 0x7553D0, 0x6FFE64},
	["bone_displacement_pointer"] = {0x76FDF8, 0x76A918, 0x76FFE8, nil}, -- TODO: Kiosk
	["frames_lag"] = {0x76AF10, 0x765A30, 0x76B100, 0x72D140}, -- TODO: Kiosk only works for minecart?
	["frames_real"] = {0x7F0560, 0x7F0480, 0x7F09D0, nil}, -- TODO: Make sure freezing these stalls the main thread -- TODO: Kiosk
	["boss_pointer"] = {0x7FDC90, 0x7FDBD0, 0x7FE120, nil}, -- TODO: Find Mad Jack state based on Model 1 pointer list and actor type knowledge. MJ is actor 204
	["obj_model2_array_pointer"] = {0x7F6000, 0x7F5F20, 0x7F6470, 0x6F4470},
	["obj_model2_array_count"] = {0x7F6004, 0x7F5F24, 0x7F6474, nil}, -- TODO: Kiosk
	["obj_model2_timer"] = {0x76A064, 0x764B84, 0x76A254, 0x72CDAC},
	["obj_model2_collision_linked_list_pointer"] = {0x754244, 0x74E9A4, 0x753B34, 0x6FF054},
	["rambiBase"] = {0x744548, 0x73EC98, 0x743E08, nil}, -- High score base
};

Game.modes = {
	[0] = "Nintendo Logo",
	[1] = "Opening Cutscene",
	[2] = "DK Rap",
	[3] = "DK TV",
	-- 4 is unknown
	[5] = "Main Menu",
	[6] = "Adventure",
	[7] = "Quit Game",
	-- 8 is unknown
	[9] = "Game Over",
	[10] = "End Sequence",
	[11] = "DK Theatre",
	[12] = "Mystery Menu Minigame",
	[13] = "Snide's Bonus Game",
	[14] = "End Sequence (DK Theatre)",
};

function Game.getCurrentMode()
	local modeValue = mainmemory.readbyte(Game.Memory.mode[version]);
	if Game.modes[modeValue] ~= nil then
		return Game.modes[modeValue];
	end
	return "Unknown "..modeValue;
end

local flag_array = {};
local flag_names = {};
local prev_map = 0;
local map_value = 0;

Game.maps = {
	"Test Map", -- 0
	"Funky's Store",
	"DK Arcade",
	"K. Rool Barrel: Lanky's Maze",
	"Jungle Japes: Mountain",
	"Cranky's Lab",
	"Jungle Japes: Minecart",
	"Jungle Japes",
	"Jungle Japes: Army Dillo",
	"Jetpac",
	"Kremling Kosh! (very easy)", -- 10
	"Stealthy Snoop! (normal, no logo)",
	"Jungle Japes: Shell",
	"Jungle Japes: Lanky's Cave",
	"Angry Aztec: Beetle Race",
	"Snide's H.Q.",
	"Angry Aztec: Tiny's Temple",
	"Hideout Helm",
	"Teetering Turtle Trouble! (very easy)",
	"Angry Aztec: Five Door Temple (DK)",
	"Angry Aztec: Llama Temple", -- 20
	"Angry Aztec: Five Door Temple (Diddy)",
	"Angry Aztec: Five Door Temple (Tiny)",
	"Angry Aztec: Five Door Temple (Lanky)",
	"Angry Aztec: Five Door Temple (Chunky)",
	"Candy's Music Shop",
	"Frantic Factory",
	"Frantic Factory: Car Race",
	"Hideout Helm (Level Intros, Game Over)",
	"Frantic Factory: Power Shed",
	"Gloomy Galleon", -- 30
	"Gloomy Galleon: K. Rool's Ship",
	"Batty Barrel Bandit! (easy)",
	"Jungle Japes: Chunky's Cave",
	"DK Isles Overworld",
	"K. Rool Barrel: DK's Target Game",
	"Frantic Factory: Crusher Room",
	"Jungle Japes: Barrel Blast",
	"Angry Aztec",
	"Gloomy Galleon: Seal Race",
	"Nintendo Logo", -- 40
	"Angry Aztec: Barrel Blast",
	"Troff 'n' Scoff", -- 42
	"Gloomy Galleon: Shipwreck (Diddy, Lanky, Chunky)",
	"Gloomy Galleon: Treasure Chest",
	"Gloomy Galleon: Mermaid",
	"Gloomy Galleon: Shipwreck (DK, Tiny)",
	"Gloomy Galleon: Shipwreck (Lanky, Tiny)",
	"Fungi Forest",
	"Gloomy Galleon: Lighthouse",
	"K. Rool Barrel: Tiny's Mushroom Game", -- 50
	"Gloomy Galleon: Mechanical Fish",
	"Fungi Forest: Ant Hill",
	"Battle Arena: Beaver Brawl!",
	"Gloomy Galleon: Barrel Blast",
	"Fungi Forest: Minecart",
	"Fungi Forest: Diddy's Barn",
	"Fungi Forest: Diddy's Attic",
	"Fungi Forest: Lanky's Attic",
	"Fungi Forest: DK's Barn",
	"Fungi Forest: Spider", -- 60
	"Fungi Forest: Front Part of Mill",
	"Fungi Forest: Rear Part of Mill",
	"Fungi Forest: Mushroom Puzzle",
	"Fungi Forest: Giant Mushroom",
	"Stealthy Snoop! (normal)",
	"Mad Maze Maul! (hard)",
	"Stash Snatch! (normal)",
	"Mad Maze Maul! (easy)",
	"Mad Maze Maul! (normal)", -- 69
	"Fungi Forest: Mushroom Leap", -- 70
	"Fungi Forest: Shooting Game",
	"Crystal Caves",
	"Battle Arena: Kritter Karnage!",
	"Stash Snatch! (easy)",
	"Stash Snatch! (hard)",
	"DK Rap",
	"Minecart Mayhem! (easy)", -- 77
	"Busy Barrel Barrage! (easy)",
	"Busy Barrel Barrage! (normal)",
	"Main Menu", -- 80
	"Title Screen (Not For Resale Version)",
	"Crystal Caves: Beetle Race",
	"Fungi Forest: Dogadon",
	"Crystal Caves: Igloo (Tiny)",
	"Crystal Caves: Igloo (Lanky)",
	"Crystal Caves: Igloo (DK)",
	"Creepy Castle",
	"Creepy Castle: Ballroom",
	"Crystal Caves: Rotating Room",
	"Crystal Caves: Shack (Chunky)", -- 90
	"Crystal Caves: Shack (DK)",
	"Crystal Caves: Shack (Diddy, middle part)",
	"Crystal Caves: Shack (Tiny)",
	"Crystal Caves: Lanky's Hut",
	"Crystal Caves: Igloo (Chunky)",
	"Splish-Splash Salvage! (normal)",
	"K. Lumsy",
	"Crystal Caves: Ice Castle",
	"Speedy Swing Sortie! (easy)",
	"Crystal Caves: Igloo (Diddy)", -- 100
	"Krazy Kong Klamour! (easy)",
	"Big Bug Bash! (very easy)",
	"Searchlight Seek! (very easy)",
	"Beaver Bother! (easy)",
	"Creepy Castle: Tower",
	"Creepy Castle: Minecart",
	"Kong Battle: Battle Arena",
	"Creepy Castle: Crypt (Lanky, Tiny)",
	"Kong Battle: Arena 1",
	"Frantic Factory: Barrel Blast", -- 110
	"Gloomy Galleon: Pufftoss",
	"Creepy Castle: Crypt (DK, Diddy, Chunky)",
	"Creepy Castle: Museum",
	"Creepy Castle: Library",
	"Kremling Kosh! (easy)",
	"Kremling Kosh! (normal)",
	"Kremling Kosh! (hard)",
	"Teetering Turtle Trouble! (easy)",
	"Teetering Turtle Trouble! (normal)",
	"Teetering Turtle Trouble! (hard)", -- 120
	"Batty Barrel Bandit! (easy)",
	"Batty Barrel Bandit! (normal)",
	"Batty Barrel Bandit! (hard)",
	"Mad Maze Maul! (insane)",
	"Stash Snatch! (insane)",
	"Stealthy Snoop! (very easy)",
	"Stealthy Snoop! (easy)",
	"Stealthy Snoop! (hard)",
	"Minecart Mayhem! (normal)",
	"Minecart Mayhem! (hard)", -- 130
	"Busy Barrel Barrage! (hard)",
	"Splish-Splash Salvage! (hard)",
	"Splish-Splash Salvage! (easy)",
	"Speedy Swing Sortie! (normal)",
	"Speedy Swing Sortie! (hard)",
	"Beaver Bother! (normal)",
	"Beaver Bother! (hard)",
	"Searchlight Seek! (easy)",
	"Searchlight Seek! (normal)",
	"Searchlight Seek! (hard)", -- 140
	"Krazy Kong Klamour! (normal)",
	"Krazy Kong Klamour! (hard)",
	"Krazy Kong Klamour! (insane)",
	"Peril Path Panic! (very easy)",
	"Peril Path Panic! (easy)",
	"Peril Path Panic! (normal)",
	"Peril Path Panic! (hard)",
	"Big Bug Bash! (easy)",
	"Big Bug Bash! (normal)",
	"Big Bug Bash! (hard)", -- 150
	"Creepy Castle: Dungeon",
	"Hideout Helm (Intro Story)",
	"DK Isles (DK Theatre)",
	"Frantic Factory: Mad Jack",
	"Battle Arena: Arena Ambush!",
	"Battle Arena: More Kritter Karnage!",
	"Battle Arena: Forest Fracas!",
	"Battle Arena: Bish Bash Brawl!",
	"Battle Arena: Kamikaze Kremlings!",
	"Battle Arena: Plinth Panic!", -- 160
	"Battle Arena: Pinnacle Palaver!",
	"Battle Arena: Shockwave Showdown!",
	"Creepy Castle: Basement",
	"Creepy Castle: Tree",
	"K. Rool Barrel: Diddy's Kremling Game",
	"Creepy Castle: Chunky's Toolshed",
	"Creepy Castle: Trash Can",
	"Creepy Castle: Greenhouse",
	"Jungle Japes Lobby",
	"Hideout Helm Lobby", -- 170
	"DK's House",
	"Rock (Intro Story)",
	"Angry Aztec Lobby",
	"Gloomy Galleon Lobby",
	"Frantic Factory Lobby",
	"Training Grounds",
	"Dive Barrel",
	"Fungi Forest Lobby",
	"Gloomy Galleon: Submarine",
	"Orange Barrel", -- 180
	"Barrel Barrel",
	"Vine Barrel",
	"Creepy Castle: Crypt",
	"Enguarde Arena",
	"Creepy Castle: Car Race",
	"Crystal Caves: Barrel Blast",
	"Creepy Castle: Barrel Blast",
	"Fungi Forest: Barrel Blast",
	"Fairy Island",
	"Kong Battle: Arena 2", -- 190
	"Rambi Arena",
	"Kong Battle: Arena 3",
	"Creepy Castle Lobby",
	"Crystal Caves Lobby",
	"DK Isles: Snide's Room",
	"Crystal Caves: Army Dillo",
	"Angry Aztec: Dogadon",
	"Training Grounds (End Sequence)",
	"Creepy Castle: King Kutout",
	"Crystal Caves: Shack (Diddy, upper part)", -- 200
	"K. Rool Barrel: Diddy's Rocketbarrel Game",
	"K. Rool Barrel: Lanky's Shooting Game",
	"K. Rool Fight: DK Phase",
	"K. Rool Fight: Diddy Phase",
	"K. Rool Fight: Lanky Phase",
	"K. Rool Fight: Tiny Phase",
	"K. Rool Fight: Chunky Phase",
	"Bloopers Ending",
	"K. Rool Barrel: Chunky's Hidden Kremling Game",
	"K. Rool Barrel: Tiny's Pony Tail Twirl Game", -- 210
	"K. Rool Barrel: Chunky's Shooting Game",
	"K. Rool Barrel: DK's Rambi Game",
	"K. Lumsy Ending",
	"K. Rool's Shoe",
	"K. Rool's Arena", -- 215
};

---------------------------
-- Arcade specific state --
---------------------------

local arcade_map = 2;
local jumpman_position = {0x04BD70, 0x04BD74}; -- US Defaults
local jumpman_velocity = {0x04BD78, 0x04BD7C}; -- US Defaults

---------------------------
-- Jetpac specific state --
---------------------------

local jetpac_map = 9;
local jetman_position = {0x02F050, 0x02F054}; -- US Defaults
local jetman_velocity = {0x02F058, 0x02F05C}; -- US Defaults

--------------
-- Mad Jack --
--------------

-- Relative to MJ state object
local MJ_offsets = { -- US Defaults
	["ticks_until_next_action"] = 0x2D,
	["actions_remaining"] = 0x58,
	["action_type"] = 0x59,
	["current_position"] = 0x60,
	["next_position"] = 0x61,
	["white_switch_position"] = 0x64,
	["blue_switch_position"] = 0x65
};

-----------------
-- Other state --
-----------------

local eep_checksum_offsets = {
	0x1A8,
	0x354,
	0x500,
	0x6AC,
	0x6EC
};

local eep_checksum_values = {
	0x00000000,
	0x00000000,
	0x00000000,
	0x00000000,
	0x00000000
};

----------------------------------
-- Refill Consumables           --
-- Based on research by Exchord --
----------------------------------

-- Maximum values
local max_coins          = 50;
local max_crystals       = 20;
local max_film           = 10;
local max_oranges        = 20;
local max_musical_energy = 10;

local max_blueprints = 40;
local max_cb = 3511;
local max_crowns = 10;
local max_fairies = 20;
local max_gb = 201;
local max_medals = 40;
local max_warps = (5 * 2 * 8) + 4 + 2 + 2 + 6;

-- Relative to global_base
-- TODO: Different on Kiosk
local standard_ammo = 0; -- u16_be
local homing_ammo   = 2; -- u16_be
local oranges       = 4; -- u16_be
local crystals      = 5; -- u16_be, 150 ticks per crystal or 125 in European version
local film          = 8; -- u16_be
local health        = 10; -- unknown, possibly u16_be
local melons        = 11; -- u8

-- Kong index
local DK     = 0;
local Diddy  = 1;
local Lanky  = 2;
local Tiny   = 3;
local Chunky = 4;
local Krusha = 5;

-- Relative to Kong base
local moves      = 0; -- u8
local sim_slam   = 1; -- u8
local weapon     = 2; -- byte, bitfield, xxxxxshw
local ammo_belt  = 3; -- u8, see Game.getMaxStandardAmmo() for formula
local instrument = 4; -- byte, bitfield, xxxx321i
local coins      = 6; -- u16_be
local lives      = 8; -- u16_be This is used as instrument ammo in single player
local CB_Base    = 10; -- u16_be array
local TS_CB_Base = CB_Base + (14 * 2); -- u16_be array
local GB_Base    = TS_CB_Base + (14 * 2); -- u16_be array

-- For CB, T&S CB, GB level indexes are:
-- Japes
-- Aztec
-- Factory
-- Galleon
-- Fungi
-- Caves
-- Castle
-- Isles
-- Helm
-- Unknown 1
-- Unknown 2
-- Unknown 3
-- Unknown 4
-- Null

function Game.getMaxStandardAmmo()
	local kong = mainmemory.readbyte(Game.Memory.character[version]);
	local ammoBelt = mainmemory.readbyte(Game.Memory.kong_base[version] + (kong * 0x5E) + ammo_belt);
	return ((2 ^ ammoBelt) * 100) / 2;
end
Game.getMaxHomingAmmo = Game.getMaxStandardAmmo;

----------------------------------
-- Object Model 1 Documentation --
----------------------------------

-- Relative to objects found in the backbone (and similar linked lists)
local previous_object = -0x10; -- u32_be
local object_size = -0x0C; -- u32_be

local max_objects = 0xFF; -- This only applies to the model 1 pointer list used to check collisions

local function getObjectModel1Count()
	return math.min(max_objects, mainmemory.read_u16_be(Game.Memory.actor_count[version]));
end

-- Relative to Model 1 Objects
obj_model1 = {
	["model_pointer"] = 0x00,
	["model"] = { -- Relative to model_pointer
		["num_bones"] = 0x20,
	},
	["rendering_parameters_pointer"] = 0x04,
	["rendering_parameters"] = { -- Relative to rendering_parameters_pointer
		["bone_array_1"] = 0x14, -- Pointer: Used for camera, updating bone positions
		["bone_array_2"] = 0x18, -- Pointer: Used for camera, updating bone positions
		["scale_x"] = 0x34, -- 32 bit float big endian
		["scale_y"] = 0x38, -- 32 bit float big endian
		["scale_z"] = 0x3C, -- 32 bit float big endian
		["anim_timer1"] = 0x94, -- 32 bit float big endian
		["anim_timer2"] = 0x98, -- 32 bit float big endian
		["anim_timer3"] = 0x104, -- 32 bit float big endian
		["anim_timer4"] = 0x108, -- 32 bit float big endian
	},
	["current_bone_array_pointer"] = 0x08,
	["actor_type"] = 0x58, -- u32 be
	["actor_types"] = { -- These are different on Kiosk
		[2] = "DK",
		[3] = "Diddy",
		[4] = "Lanky",
		[5] = "Tiny",
		[6] = "Chunky",
		[7] = "Krusha",
		[8] = "Rambi",
		[9] = "Enguarde",
		--[10] = "Unknown", -- Always loaded -- TODO: What is this?
		--[11] = "Unknown", -- Always loaded -- TODO: What is this?
		[12] = "Loading Zone Controller", -- Always loaded
		--[13] = "Unknown", -- Always loaded -- TODO: What is this?
		--[14] = "Unknown", -- Always loaded -- TODO: What is this?
		--[15] = "Unknown", -- Always loaded -- TODO: What is this?
		[17] = "Cannon Barrel",
		[18] = "Rambi Box",
		[19] = "Barrel (Diddy 5DI)",
		--[20] = "Unknown", -- Possibily some kind of cutscene controller
		[21] = "Pushable Box", -- TODO: Unused?
		[22] = "Barrel Spawner", -- TODO: Unused?
		[23] = "Cannon",
		[25] = "Hunky Chunky Barrel",
		[26] = "TNT Barrel",
		[27] = "TNT Barrel Spawner", -- Army Dillo
		[28] = "Bonus Barrel",
		--[29] = "Unknown - Japes Minecart", -- TODO
		[30] = "Fireball", -- Boss fights TODO: where else is this used?
		[31] = "Bridge (Castle)",
		[32] = "Swinging Light",
		[33] = "Vine", -- Brown
		[34] = "Kremling Kosh Controller",
		[35] = "Melon (Projectile)",
		[36] = "Peanut",
		--[37] = "Unknown - Factory Intro", -- TODO: What is this?
		[38] = "Pineapple",
		[39] = "Large Brown Bridge", -- TODO: Unused?
		[40] = "Mini Monkey barrel",
		[41] = "Orange",
		[42] = "Grape",
		[43] = "Feather",
		[44] = "Laser", -- Projectile
		[45] = "Golden Banana", -- TODO: Unused? There are normally model 2
		[47] = "Watermelon Slice",
		[48] = "Coconut",
		[49] = "Rocketbarrel",
		[50] = "Lime",
		[51] = "Ammo Crate", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[52] = "Orange Pickup", -- Dropped by Klump & Purple Klaptrap
		[53] = "Banana Coin", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[54] = "DK Coin", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[55] = "Small Explosion", -- TODO: Unused?
		[56] = "Orangstand Sprint Barrel",
		[57] = "Strong Kong Barrel",
		[58] = "Swinging Light",
		[59] = "Fireball", -- Mad Jack etc.
		[61] = "Boulder",
		[63] = "Vase (O)",
		[64] = "Vase (:)",
		[65] = "Vase (Triangle)",
		[66] = "Vase (+)",
		[67] = "Cannon Ball",
		[69] = "Vine", -- Green
		[70] = "Counter", -- TODO: Unused?
		[71] = "Red Kremling", -- Lanky's Keyboard Game in R&D
		[72] = "Boss Key",
		[73] = "Cannon", -- Galleon Minigame
		[75] = "Blueprint (Diddy)",
		[76] = "Blueprint (Chunky)",
		[77] = "Blueprint (Lanky)",
		[78] = "Blueprint (DK)",
		[79] = "Blueprint (Tiny)",
		[81] = "Fire Spawner? (Dogadon)", -- TODO: Verify
		[82] = "Small Grey Rock", -- TODO: Unused?
		[83] = "Spider Web", -- Fungi miniBoss
		[84] = "Steel Keg Spawner",
		[85] = "Steel Keg",
		[86] = "Crown",
		[89] = "Fire", -- TODO: Unused?
		[91] = "Balloon (Diddy)",
		[92] = "Stalactite",
		[94] = "Car", -- TODO: Unused?
		[95] = "Pause Menu",
		[96] = "Hunky Chunky Barrel (Dogadon)",
		[98] = "Tag Barrel",
		[97] = "TNT Barrel Spawner (Dogadon)",
		[100] = "1 Pad (Diddy 5DI)",
		[101] = "2 Pad (Diddy 5DI)",
		[102] = "3 Pad (Diddy 5DI)",
		[103] = "4 Pad (Diddy 5DI)",
		[104] = "5 Pad (Diddy 5DI)",
		[105] = "6 Pad (Diddy 5DI)",
		[106] = "5DI Controller?", -- TODO: Investigate
		[107] = "Bonus Barrel (Hideout Helm)",
		[110] = "CB Bunch", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[111] = "Balloon (Chunky)",
		[112] = "Balloon (Tiny)",
		[113] = "Balloon (Lanky)",
		[114] = "Balloon (DK)",
		[115] = "K. Lumsy's Cage", -- TODO: Also rabbit race finish line?
		[116] = "Chain",
		[118] = "Yellow ?", -- TODO: Unused?
		[119] = "CB Single (Blue)", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[120] = "CB Single (Yellow)", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[121] = "Crystal Coconut", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[122] = "DK Coin", -- TODO: Unused? Doesn't seem to work, these are normally model 2
		[124] = "Peril Path Panic Controller?", -- TODO: Verify, used anywhere else?
		[126] = "Fly Swatter",
		[128] = "Headphones",
		[129] = "Enguarde Box",
		[130] = "Apple", -- Fungi
		[132] = "Enguarde Box", -- TODO: Does this work? Unused?
		[133] = "Barrel",
		[134] = "Training Barrel",
		[135] = "Boombox (Treehouse)",
		[136] = "Tag Barrel",
		[137] = "Tag Barrel", -- Troff'n'Scoff
		[138] = "B. Locker",
		[139] = "Rainbow Coin Patch",
		[140] = "Rainbow Coin",
		[148] = "Rope", -- K. Rool's Arena
		[149] = "Banana Barrel", -- TODO: Lanky Phase?
		[156] = "Wrinkly",
		[163] = "Banana Fairy (BFI)",
		[164] = "Ice Tomato",
		[165] = "Tag Barrel (King Kutout)",
		[166] = "King Kutout Part",
		[167] = "Cannon",
		[170] = "Damage Source", -- TODO?
		[171] = "Orange", -- Krusha's Gun
		[173] = "Cutscene Controller",
		[175] = "Barrel Enemy (TNT)",
		[176] = "Timer",
		[178] = "Beaver", -- Blue
		[179] = "Shockwave (Mad Jack)",
		[181] = "Book", -- Castle Library
		[182] = "Barrel Enemy (Normal)",
		[183] = "Zinger",
		[184] = "Snide",
		[185] = "Army Dillo",
		[186] = "Kremling", -- Kremling Kosh
		[187] = "Klump",
		[188] = "Camera",
		[189] = "Cranky",
		[190] = "Funky",
		[191] = "Candy",
		[192] = "Beetle", -- Race
		[193] = "Mermaid",
		[195] = "Squawks",
		[196] = "DK (Rap)",
		[197] = "Trapped Diddy",
		[198] = "Trapped Lanky",
		[199] = "Trapped Tiny",
		[200] = "Trapped Chunky",
		[201] = "Llama",
		[202] = "Fairy Picture",
		[203] = "Padlock (T&S)",
		[204] = "Mad Jack",
		[205] = "Klaptrap", -- Green
		[206] = "Zinger",
		[207] = "Vulture (Race)",
		[208] = "Klaptrap (Purple)",
		[211] = "Klaptrap (Skeleton)",
		[212] = "Beaver (Gold)",
		[214] = "TNT Minecart", -- Minecart Mayhem
		[215] = "TNT Minecart",
		[216] = "Pufftoss",
		[224] = "Mushroom Man",
		[226] = "Troff",
		[228] = "Bad Hit Detection Man",
		[230] = "Ruler",
		[231] = "Toy Box",
		[232] = "Text Overlay",
		[234] = "Scoff",
		[235] = "Robo-Kremling",
		[236] = "Dogadon",
		[238] = "Kremling",
		[239] = "Bongos",
		[240] = "Fish with headlamp",
		[241] = "Kasplat (DK)",
		[242] = "Kasplat (Diddy)",
		[243] = "Kasplat (Lanky)",
		[244] = "Kasplat (Tiny)",
		[245] = "Kasplat (Chunky)",
		[247] = "Seal",
		[248] = "Banana Fairy",
		[249] = "Squawks w/spotlight",
		[251] = "Spider miniBoss",
		[252] = "Rabbit", -- Fungi
		[254] = "Static Object", -- Used in TONS of places, mainly for objects animated by cutscenes
		[255] = "Shockwave",
		[258] = "Shockwave", -- Boss
		[259] = "Guard", -- Stealthy Snoop
		[260] = "Text Overlay", -- K. Rool fight
		[261] = "Robo-Zinger",
		[262] = "Krossbones",
		[263] = "Fire Shockwave (Dogadon)",
		[264] = "Squawks",
		[265] = "Light beam", -- Boss fights etc
		[266] = "DK Rap Controller", -- Handles the lyrics etc
		[267] = "Shuri",
		[268] = "Gimpfish",
		[270] = "Sir Domino",
		[271] = "Mr. Dice",
		[275] = "K. Lumsy",
		[276] = "Spiderling",
		[278] = "Projectile", -- Spider miniBoss
		--[280] = "Unknown - Spider Boss Map" -- TODO: What is this?
		[281] = "K. Rool (DK Phase)",
		[285] = "Bat",
		[286] = "Giant Clam",
		[288] = "Tomato", -- Fungi
		[289] = "Kritter-in-a-Sheet",
		[290] = "Pufftup",
		[291] = "Kosha",
		[292] = "K. Rool (Diddy Phase)",
		[293] = "K. Rool (Lanky Phase)",
		[294] = "K. Rool (Tiny Phase)",
		[295] = "K. Rool (Chunky Phase)",
		--[297] = "Unknown - Kritter Karnage",
		[299] = "Textbox",
		[305] = "Missile", -- Car Race
		[309] = "Kong Logo (Instrument)", -- DK for DK, Star for Diddy, DK for Lanky, Flower for Tiny, DK for Chunky
		[310] = "Spotlight", -- Tag barrel, instrument etc.
		[311] = "Checkpoint (Race)", -- Seal race & Castle car race
		[313] = "Particle (Idle Anim.)",
		[314] = "Rareware logo",
		[316] = "Kong (Tag Barrel)",
		[317] = "Locked Kong (Tag Barrel)",
		[322] = "Car", -- Car Race
		[323] = "Enemy Car", -- Car Race, aka George
		[325] = "Shockwave", -- Simian Slam
		[326] = "Main Menu Controller",
		[328] = "Klaptrap", -- Peril Path Panic
		[329] = "Fairy", -- Peril Path Panic
		[330] = "Bug", -- Big Bug Bash
		[331] = "Klaptrap", -- Searchlight Seek
		[332] = "Big Bug Bash Controller?", -- TODO: Verify -- TODO: Fly swatter?
		[333] = "Barrel (Main Menu)",
		[334] = "Padlock (K. Lumsy)",
		[335] = "Snide's Menu",
		[336] = "Training Barrel Controller",
		[337] = "Multiplayer Model (Main Menu)",
		[339] = "Arena Controller", -- Rambi/Enguarde
		[340] = "Bug", -- Trash Can
		[342] = "Try Again Dialog",
		[343] = "Pause Menu", -- Mystery menu bosses
	},
	-- 0000 0010 = Block playing instrument
	["object_properties_bitfield_1"] = 0x60, -- TODO: Document & rename this, probably lump into a u32_be bitfield
	-- 0001 0000 = collides with terrain
	-- 0000 0100 = visible
	-- 0000 0001 = in water
	["visibility"] = 0x63, -- Byte (bitfield) TODO: Fully document & rename this, probably lump into a u32_be bitfield
	["specular_highlight"] = 0x6D, -- TODO: uh
	["shadow_width"] = 0x6E, -- u8
	["shadow_height"] = 0x6F, -- u8
	["x_pos"] = 0x7C, -- 32 bit float big endian
	["y_pos"] = 0x80, -- 32 bit float big endian
	["z_pos"] = 0x84, -- 32 bit float big endian
	["floor"] = 0xA4, -- 32 bit float big endian
	["distance_from_floor"] = 0xB4, -- 32 bit float big endian
	["velocity"] = 0xB8, -- 32 bit float big endian
	--["acceleration"] = 0xBC, -- TODO: Seems wrong
	["y_velocity"] = 0xC0, -- 32 bit float big endian
	["y_acceleration"] = 0xC4, -- 32 bit float big endian
	["terminal_velocity"] = 0xC8, -- 32 bit float big endian
	["light_thing"] = 0xCC, -- Values 0x00->0x14
	["x_rot"] = 0xE4, -- u16_be
	["y_rot"] = 0xE6, -- u16_be
	["z_rot"] = 0xE8, -- u16_be
	["locked_to_pad"] = 0x110, -- TODO: What datatype is this? code says byte but I'd think it'd be a pointer
	["health"] = 0x134, -- s16_be
	["takes_enemy_damage"] = 0x13B, -- TODO: put into examine method and double check datatype
	["lock_method_1_pointer"] = 0x13C,
	["ledge_info_pointer"] = 0x140, -- TODO: I don't quite know what to call this, it has 2 pointers to the bone arrays used for tree grab, telegrab, oranges & bullets
	["ledge_info"] = {
		["last_x"] = 0x1C, -- 32 bit float big endian
		["last_z"] = 0x20, -- 32 bit float big endian
		["is_locked"] = 0x21, -- Byte, setting this > 0 will send the player to last_x, player Y, last_z
		["bone_array_1_pointer"] = 0x74, -- Pointer: Used for enemy eye position, bullets & oranges, telegrabs & tree warps
		["bone_array_2_pointer"] = 0x78, -- Pointer: Used for enemy eye position, bullets & oranges, telegrabs & tree warps
	},
	["hand_state"] = 0x147, -- Bitfield
	["control_state_byte"] = 0x154,
	["control_states"] = {
		[0x01] = "Idle", -- Enemy
		[0x02] = "First person camera",
		[0x03] = "First person camera", -- Water
		[0x04] = "Fairy Camera",
		[0x05] = "Fairy Camera", -- Water
		[0x06] = "Locked", -- Inside bonus barrel
		[0x07] = "Minecart (Idle)",
		[0x08] = "Minecart (Crouch)",
		[0x09] = "Minecart (Jump)",
		[0x0A] = "Minecart (Left)",
		[0x0B] = "Minecart (Right)",
		[0x0C] = "Idle",
		[0x0D] = "Walking",
		[0x0E] = "Skidding",
		[0x0F] = "Sliding", -- Beetle Race
		[0x10] = "Sliding (Left)", -- Beetle Race
		[0x11] = "Sliding (Right)", -- Beetle Race
		[0x12] = "Sliding (Forward)", -- Beetle Race
		[0x13] = "Sliding (Back)", -- Beetle Race
		[0x14] = "Jumping", -- Beetle Race
		[0x15] = "Slipping",
		[0x16] = "Slipping", -- DK Slope in Helm
		[0x17] = "Jumping",
		[0x18] = "Baboon Blast Pad",
		[0x19] = "Bouncing", -- Mushroom
		[0x1A] = "Double Jump", -- Diddy

		[0x1C] = "Simian Slam",
		[0x1D] = "Long Jumping",
		[0x1E] = "Falling",
		[0x1F] = "Falling", -- Gun
		[0x20] = "Falling/Splat",
		[0x21] = "Falling", -- Beetle Race
		[0x22] = "Pony Tail Twirl",
		[0x23] = "Attacking", -- Enemy
		[0x24] = "Primate Punch", -- TODO: Is this used anywhere else?
		[0x25] = "Attacking", -- Enemy
		[0x26] = "Ground Attack",
		[0x27] = "Attacking", -- Enemy
		[0x28] = "Ground Attack (Final)",
		[0x29] = "Moving Ground Attack",
		[0x2A] = "Aerial Attack",
		[0x2B] = "Rolling",
		[0x2C] = "Throwing Orange",
		[0x2D] = "Shockwave",
		[0x2E] = "Chimpy Charge",
		[0x2F] = "Charging", -- Rambi
		[0x30] = "Bouncing",
		[0x31] = "Damaged",

		[0x35] = "Damaged", -- Klump knockback
		[0x36] = "Death",
		[0x37] = "Damaged", -- Underwater
		--[0x38] = "Crash",
		[0x39] = "Shrinking",
		[0x3C] = "Crouching",
		[0x3D] = "Uncrouching",
		[0x3E] = "Backflip",
		[0x3F] = "Entering Orangstand",
		[0x40] = "Orangstand",
		[0x41] = "Jumping", -- Orangstand
		[0x42] = "Barrel", -- Tag Barrel, Bonus Barrel, Mini Monkey Barrel
		[0x43] = "Barrel", -- Underwater
		[0x44] = "Baboon Blast Shot",
		[0x45] = "Cannon Shot",
		[0x46] = "Pushing Object", -- TODO: Unused?
		[0x47] = "Picking up Object",
		[0x48] = "Idle", -- Carrying Object
		[0x49] = "Walking", -- Carrying Object
		[0x4A] = "Dropping Object",
		[0x4B] = "Throwing Object",
		[0x4C] = "Jumping", -- Carrying Object

		[0x4E] = "Surface swimming",
		[0x4F] = "Underwater",
		[0x50] = "Leaving Water",
		[0x51] = "Jumping", -- Out of water
		[0x52] = "Bananaporter",
		[0x53] = "Monkeyport",
		[0x54] = "Bananaporter", -- Multiplayer

		[0x56] = "Locked", -- Funky's & Candy's store
		[0x57] = "Swinging on Vine",
		[0x58] = "Leaving Vine",
		[0x59] = "Climbing Tree",
		[0x5A] = "Leaving Tree",
		[0x5B] = "Grabbed Ledge",
		[0x5C] = "Pulling up on Ledge",
		[0x5D] = "Idle", -- With gun
		[0x5E] = "Walking", -- With gun
		[0x5F] = "Putting away gun",
		[0x60] = "Pulling out gun",
		[0x61] = "Jumping", -- With gun
		[0x62] = "Aiming gun",
		[0x63] = "Rocketbarrel",
		[0x64] = "Taking Photo",
		[0x65] = "Taking Photo", -- Underwater
		[0x66] = "Damaged", -- Exploding TNT Barrels
		[0x67] = "Instrument",

		[0x6A] = "Learning Gun",
		[0x6B] = "Locked", -- Bonus barrel
		[0x6C] = "Feeding T&S",
		[0x6D] = "Boat",
		[0x6E] = "Baboon Balloon",
		[0x6F] = "Updraft", -- Castle tower
		[0x70] = "GB Dance",
		[0x71] = "Key Dance",

		[0x73] = "Loss Dance",
		[0x74] = "Victory Dance",
		[0x75] = "Vehicle", -- Castle Car Race
		[0x76] = "Entering Battle Crown",
		[0x77] = "Locked", -- Tons of cutscenes use this
		[0x78] = "Gorilla Grab",

		[0x7A] = "Locked", -- Car race loss, possibly elsewhere

		[0x7C] = "Trapped", -- Spider miniBoss
		[0x7D] = "Klaptrap Kong", -- Beaver Bother
		[0x7E] = "Surface Swimming", -- Enguarde
		[0x7F] = "Underwater", -- Enguarde
		[0x81] = "Attacking", -- Enguarde
		[0x82] = "Leaving Water", -- Enguarde
		[0x83] = "Fairy Refill",

		[0x85] = "Main Menu",
		[0x86] = "Entering Main Menu",
		[0x87] = "Entering Portal",
		[0x88] = "Exiting Portal",
	},
	["texture_renderer_pointer"] = 0x158, -- Pointer
	["texture_renderer"] = {
		["texture_index"] = 0x0C, -- u16_be
		--["unknown_float"] = 0x10, -- Float -- TODO: What is this?
		--["unknown_float"] = 0x14, -- Float -- TODO: What is this?
		["next_renderer"] = 0x24, -- Pointer
	},
	["shade_byte"] = 0x16D,
	["player"] = {
		["animation_type"] = 0x181, -- Seems to be the same value as control_states
		["velocity_uncrouch_aerial"] = 0x1A4, -- TODO: What is this?
		["misc_acceleration_float"] = 0x1AC, -- TODO: What is this?
		["horizontal_acceleration"] = 0x1B0, -- Set to a negative number to go fast
		["misc_acceleration_float_2"] = 0x1B4, -- TODO: What is this?
		["misc_acceleration_float_3"] = 0x1B8, -- TODO: What is this?
		["velocity_ground"] = 0x1C0, -- TODO: What is this?
		["vehicle_actor_pointer"] = 0x208, -- u32 be
		["slope_timer"] = 0x243,
		["shockwave_charge_timer"] = 0x248, -- s16 be
		["shockwave_recovery_timer"] = 0x24A, -- byte
		["grabbed_vine_pointer"] = 0x2B0, -- u32 be
		["grab_pointer"] = 0x32C, -- u32 be
		["scale"] = {
			0x344, 0x348, 0x34C, 0x350, 0x354 -- 0x344 and 0x348 seem to be a target, the rest must be current value for each axis
		},
		["fairy_active"] = 0x36C, -- TODO: Find a pointer for the actor the camera is focusing on
		["effect_byte"] = 0x372, -- Bitfield, TODO: Document bits
	},
	["camera"] = {
		-- TODO: Focused vehicle pointers
		-- TODO: Verify for all versions
		["focused_actor_pointer"] = 0x178,
		["focused_vehicle_pointer"] = 0x1BC,
		["focused_vehicle_pointer_2"] = 0x1C0,
		["viewport_x_position"] = 0x1FC, -- 32 bit float big endian
		["viewport_y_position"] = 0x200, -- 32 bit float big endian
		["viewport_z_position"] = 0x204, -- 32 bit float big endian
		["tracking_distance"] = 0x21C, -- 32 bit float big endian
		["viewport_y_rotation"] = 0x22A,
		["tracking_angle"] = 0x230,
		["zoom_level_c_down"] = 0x266, -- u8
		["zoom_level_current"] = 0x267, -- u8
		["zoom_level_after_c_up"] = 0x268, -- u8
		["state_switch_timer_1"] = 0x269,
		["state_switch_timer_2"] = 0x26E,
		["state_type"] = 0x26B,
		["state_values"] = {
			[1] = "Normal",
			[2] = "Locked",
			[3] = "First Person",
			[4] = "Vehicle",
			[5] = "Water",
			[9] = "Tag Barrel",
			[11] = "Fairy",
			[12] = "Vine", -- Swinging
			[13] = "Aiming", -- Gun, not first person
		},
	},
	["tag_barrel"] = {
		["scroll_timer"] = 0x17D,
		["current_index"] = 0x17E,
		["previous_index"] = 0x17F,
		["DK_actor_pointer"] = 0x180,
		["Diddy_actor_pointer"] = 0x184,
		["Lanky_actor_pointer"] = 0x188,
		["Tiny_actor_pointer"] = 0x18C,
		["Chunky_actor_pointer"] = 0x190,
		["kickout_timer"] = 0x1B4, -- Kicks the player out of the tag barrel at >= 9000
	},
	["text_overlay"] = {
		["text_shown"] = 0x1EE, -- u16 be
	},
	["kosh_kontroller"] = {
		["slot_location"] = 0x1A2,
		["melons_remaining"] = 0x1A3,
		["slot_pointer_base"] = 0x1A8,
	},
	["main_menu_controller"] = {
		["menu_screen"] = 0x18A,
		["menu_position"] = 0x18F,
	},
	["bug"] = { -- Big Bug Bash -- TODO: These possibly apply to other AI objects
		["current_direction"] = 0x180, -- Float
		["ticks_til_direction_change"] = 0x184, -- u32_be
	},
};

local function getActorName(pointer)
	if isRDRAM(pointer) then
		local actorBehavior = mainmemory.read_u32_be(pointer + obj_model1.actor_type) % 0x10000;
		if type(obj_model1.actor_types[actorBehavior]) ~= "nil" then
			return obj_model1.actor_types[actorBehavior];
		end
		return actorBehavior;
	end
	return "Unknown";
end

local function getExamineDataModelOne(pointer)
	local examine_data = {};

	if not isRDRAM(pointer) then
		return examine_data;
	end

	local modelPointer = dereferencePointer(pointer + obj_model1.model_pointer);
	local renderingParametersPointer = dereferencePointer(pointer + obj_model1.rendering_parameters_pointer);
	local boneArrayPointer = dereferencePointer(pointer + obj_model1.current_bone_array_pointer);
	local hasModel = isRDRAM(modelPointer) or isRDRAM(renderingParametersPointer) or isRDRAM(boneArrayPointer);

	local xPos = mainmemory.readfloat(pointer + obj_model1.x_pos, true);
	local yPos = mainmemory.readfloat(pointer + obj_model1.y_pos, true);
	local zPos = mainmemory.readfloat(pointer + obj_model1.z_pos, true);
	local hasPosition = hasModel or xPos ~= 0 or yPos ~= 0 or zPos ~= 0;

	table.insert(examine_data, { "Actor base", toHexString(pointer, 6) });
	table.insert(examine_data, { "Actor size", toHexString(mainmemory.read_u32_be(pointer + object_size)) });
	local currentActorTypeNumeric = mainmemory.read_u32_be(pointer + obj_model1.actor_type);
	local currentActorType = getActorName(pointer); -- Needed for detecting special fields
	table.insert(examine_data, { "Actor type", currentActorType });
	table.insert(examine_data, { "Separator", 1 });

	if hasModel then
		table.insert(examine_data, { "Model", toHexString(modelPointer, 6) });
		table.insert(examine_data, { "Rendering Params", toHexString(renderingParametersPointer, 6) });
		table.insert(examine_data, { "Bone Array", toHexString(boneArrayPointer, 6) });
		table.insert(examine_data, { "Texture Renderer", toHexString(dereferencePointer(pointer + obj_model1.texture_renderer_pointer) or 0)});
		table.insert(examine_data, { "Separator", 1 });
	end

	if hasPosition then
		table.insert(examine_data, { "X", xPos });
		table.insert(examine_data, { "Y", yPos });
		table.insert(examine_data, { "Z", zPos });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Floor", mainmemory.readfloat(pointer + obj_model1.floor, true) });
		table.insert(examine_data, { "Distance From Floor", mainmemory.readfloat(pointer + obj_model1.distance_from_floor, true) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Rot X", ScriptHawk.UI.formatRotation(mainmemory.read_u16_be(pointer + obj_model1.x_rot)) });
		table.insert(examine_data, { "Rot Y", ScriptHawk.UI.formatRotation(mainmemory.read_u16_be(pointer + obj_model1.y_rot)) });
		table.insert(examine_data, { "Rot Z", ScriptHawk.UI.formatRotation(mainmemory.read_u16_be(pointer + obj_model1.z_rot)) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Velocity", mainmemory.readfloat(pointer + obj_model1.velocity, true) });
		table.insert(examine_data, { "Y Velocity", mainmemory.readfloat(pointer + obj_model1.y_velocity, true) });
		table.insert(examine_data, { "Y Accel", mainmemory.readfloat(pointer + obj_model1.y_acceleration, true) });
		table.insert(examine_data, { "Terminal Velocity", mainmemory.readfloat(pointer + obj_model1.terminal_velocity, true) });
		table.insert(examine_data, { "Separator", 1 });
	end

	table.insert(examine_data, { "Health", mainmemory.read_s16_be(pointer + obj_model1.health) });
	table.insert(examine_data, { "Hand state", mainmemory.readbyte(pointer + obj_model1.hand_state) });
	table.insert(examine_data, { "Specular highlight", mainmemory.readbyte(pointer + obj_model1.specular_highlight) });
	table.insert(examine_data, { "Separator", 1 });

	table.insert(examine_data, { "Shadow width", mainmemory.readbyte(pointer + obj_model1.shadow_width) });
	table.insert(examine_data, { "Shadow height", mainmemory.readbyte(pointer + obj_model1.shadow_height) });
	local controlStateValue = mainmemory.readbyte(pointer + obj_model1.control_state_byte);
	if obj_model1.control_states[controlStateValue] ~= nil then
		controlStateValue = obj_model1.control_states[controlStateValue]
	else
		controlStateValue = toHexString(controlStateValue);
	end
	table.insert(examine_data, { "Control State", controlStateValue });
	table.insert(examine_data, { "Brightness", mainmemory.readbyte(pointer + obj_model1.shade_byte) });
	table.insert(examine_data, { "Separator", 1 });

	local visibilityValue = mainmemory.readbyte(pointer + obj_model1.visibility);
	table.insert(examine_data, { "Visibility", bizstring.binary(visibilityValue) });
	table.insert(examine_data, { "In water", tostring(not get_bit(visibilityValue, 0)) });
	table.insert(examine_data, { "Visible", tostring(get_bit(visibilityValue, 2)) });
	table.insert(examine_data, { "Collides with terrain", tostring(get_bit(visibilityValue, 4)) });
	table.insert(examine_data, { "Separator", 1 });

	table.insert(examine_data, { "Lock Method 1 Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.lock_method_1_pointer), 8) });
	table.insert(examine_data, { "Separator", 1 });

	if isKong(currentActorTypeNumeric) then
		table.insert(examine_data, { "Shockwave Charge Timer", mainmemory.read_s16_be(pointer + obj_model1.player.shockwave_charge_timer) });
		table.insert(examine_data, { "Shockwave Recovery Timer", mainmemory.readbyte(pointer + obj_model1.player.shockwave_recovery_timer) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Vehicle Actor Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.player.vehicle_actor_pointer), 8) });
		table.insert(examine_data, { "Grabbed Vine Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.player.grabbed_vine_pointer), 8) });
		table.insert(examine_data, { "Grab pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.player.grab_pointer), 8) });
		table.insert(examine_data, { "Fairy Active", mainmemory.readbyte(pointer + obj_model1.player.fairy_active) });
		local animationType = mainmemory.readbyte(pointer + obj_model1.player.animation_type);
		if obj_model1.control_states[animationType] ~= nil then
			animationType = obj_model1.control_states[animationType];
		end
		table.insert(examine_data, { "Animation Type", animationType });
		table.insert(examine_data, { "Separator", 1 });

		for index, offset in ipairs(obj_model1.player.scale) do
			table.insert(examine_data, { "Scale "..toHexString(offset), mainmemory.readfloat(pointer + offset, true) });
		end
		table.insert(examine_data, { "Separator", 1 });
	end

	if currentActorType == "Camera" then
		local focusedActor = dereferencePointer(pointer + obj_model1.camera.focused_actor_pointer);
		local focusedActorType = "Unknown";

		if isRDRAM(focusedActor) then
			focusedActorType = getActorName(focusedActor);
		end

		table.insert(examine_data, { "Focused Actor", toHexString(focusedActor, 6).." "..focusedActorType });
		table.insert(examine_data, { "Focused Vehicle", toHexString(mainmemory.read_u32_be(pointer + obj_model1.camera.focused_vehicle_pointer))});
		table.insert(examine_data, { "Focused Vehicle 2", toHexString(mainmemory.read_u32_be(pointer + obj_model1.camera.focused_vehicle_pointer_2))});
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Viewport X Pos", mainmemory.readfloat(pointer + obj_model1.camera.viewport_x_position, true) });
		table.insert(examine_data, { "Viewport Y Pos", mainmemory.readfloat(pointer + obj_model1.camera.viewport_y_position, true) });
		table.insert(examine_data, { "Viewport Z Pos", mainmemory.readfloat(pointer + obj_model1.camera.viewport_z_position, true) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Viewport Y Rot", ScriptHawk.UI.formatRotation(mainmemory.read_u16_be(pointer + obj_model1.camera.viewport_y_rotation)) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Tracking Distance", mainmemory.readfloat(pointer + obj_model1.camera.tracking_distance, true) });
		table.insert(examine_data, { "Tracking Angle", mainmemory.readfloat(pointer + obj_model1.camera.tracking_angle, true) });
		table.insert(examine_data, { "Separator", 1 });

		local stateType = mainmemory.readbyte(pointer + obj_model1.camera.state_type);
		if obj_model1.camera.state_values[stateType] ~= nil then
			stateType = obj_model1.camera.state_values[stateType];
		end
		table.insert(examine_data, { "Camera State Type", stateType });
		table.insert(examine_data, { "C-Down Zoom Level", mainmemory.readbyte(pointer + obj_model1.camera.zoom_level_c_down) });
		table.insert(examine_data, { "Current Zoom Level", mainmemory.readbyte(pointer + obj_model1.camera.zoom_level_current) });
		table.insert(examine_data, { "Zoom Level After C-Up", mainmemory.readbyte(pointer + obj_model1.camera.zoom_level_after_c_up) });
		table.insert(examine_data, { "Zoom Level Timer 1", mainmemory.readbyte(pointer + obj_model1.camera.state_switch_timer_1) });
		table.insert(examine_data, { "Zoom Level Timer 2", mainmemory.readbyte(pointer + obj_model1.camera.state_switch_timer_2) });
		table.insert(examine_data, { "Separator", 1 });
	end

	if currentActorType == "Tag Barrel" then
		table.insert(examine_data, { "TB scroll timer", mainmemory.readbyte(pointer + obj_model1.tag_barrel.scroll_timer) });
		table.insert(examine_data, { "TB current index", mainmemory.readbyte(pointer + obj_model1.tag_barrel.current_index) });
		table.insert(examine_data, { "TB previous index", mainmemory.readbyte(pointer + obj_model1.tag_barrel.previous_index) });
		table.insert(examine_data, { "TB kickout timer", mainmemory.read_u32_be(pointer + obj_model1.tag_barrel.kickout_timer) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "DK Actor Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.tag_barrel.DK_actor_pointer)) });
		table.insert(examine_data, { "Diddy Actor Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.tag_barrel.Diddy_actor_pointer)) });
		table.insert(examine_data, { "Lanky Actor Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.tag_barrel.Lanky_actor_pointer)) });
		table.insert(examine_data, { "Tiny Actor Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.tag_barrel.Tiny_actor_pointer)) });
		table.insert(examine_data, { "Chunky Actor Pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.tag_barrel.Chunky_actor_pointer)) });
		table.insert(examine_data, { "Separator", 1 });

	elseif currentActorType == "Kremling Kosh Controller" then
		table.insert(examine_data, { "Current Slot", mainmemory.readbyte(pointer + obj_model1.kosh_kontroller.slot_location) });
		table.insert(examine_data, { "Melons Remaining", mainmemory.readbyte(pointer + obj_model1.kosh_kontroller.melons_remaining) });
		for i = 1, 8 do
			table.insert(examine_data, { "Slot "..i.." pointer", toHexString(mainmemory.read_u32_be(pointer + obj_model1.kosh_kontroller.slot_pointer_base + (i - 1) * 4), 8) });
		end
		table.insert(examine_data, { "Separator", 1 });
	elseif currentActorType == "Bug" then -- Big Bug Bash
		table.insert(examine_data, { "Current AI direction", mainmemory.readfloat(pointer + obj_model1.bug.current_direction, true) });
		table.insert(examine_data, { "Ticks til direction change", mainmemory.read_u32_be(pointer + obj_model1.bug.ticks_til_direction_change) });
		table.insert(examine_data, { "Separator", 1 });
	elseif currentActorType == "Main Menu Controller" then
		table.insert(examine_data, { "Menu Screen", mainmemory.readbyte(pointer + obj_model1.main_menu_controller.menu_screen) });
		table.insert(examine_data, { "Menu Position", mainmemory.readbyte(pointer + obj_model1.main_menu_controller.menu_position) });
		table.insert(examine_data, { "Separator", 1 });
	end

	return examine_data;
end

function Game.getPlayerObject() -- TODO: Cache this
	return dereferencePointer(Game.Memory.player_pointer[version]);
end

----------------------------------
-- Object Model 2 Documentation --
----------------------------------

-- Things in object model 2
-- GB's & CB's
-- Doors in helm
-- K. Rool's chair
-- Gorilla Grab Levers
-- Bananaporters
-- DK portals
-- Trees
-- Instrument pads
-- Wrinkly doors
-- Shops (Snide's, Cranky's, Funky's, Candy's)

local obj_model2_slot_size = 0x90;

-- Relative to objects in model 2 array
obj_model2 = {
	["x_pos"] = 0x00, -- Float
	["y_pos"] = 0x04, -- Float
	["z_pos"] = 0x08, -- Float
	["hitbox_scale"] = 0x0C, -- Float
	["model_pointer"] = 0x20,
	["model"] = {
		["x_pos"] = 0x00, -- Float
		["y_pos"] = 0x04, -- Float
		["z_pos"] = 0x08, -- Float
		["scale"] = 0x0C, -- Float
		["rot_x"] = 0x10, -- Float
		["rot_y"] = 0x14, -- Float
		["rot_z"] = 0x18, -- Float
	},
	["behavior_type_pointer"] = 0x24, -- TODO: Fields for this object
	["unknown_counter"] = 0x3A, -- u16_be
	["behavior_pointer"] = 0x7C,
	-- 0x00 Seen in game, but currently unknown
	-- 0x01 Seen in game, but currently unknown
	-- 0x02 Seen in game, but currently unknown
	-- 0x04 Seen in game, but currently unknown
	-- 0x08 Seen in game, but currently unknown
	-- 0x20 Seen in game, but currently unknown
	-- 0x21 100001 GB - Chunky can collect
	-- 0x22 100010 GB - Diddy can collect
	-- 0x24 100100 GB - Tiny can collect
	-- 0x28 101000 GB - DK can collect
	-- 0x30 110000 GB - Lanky can collect
	-- 0x3F 111111 GB - Anyone can collect?
	["collectable_state"] = 0x8C, -- byte (bitfield)
};

function getObjectModel2Array()
	if version ~= 4 then
		return dereferencePointer(Game.Memory["obj_model2_array_pointer"][version]);
	end
	return Game.Memory["obj_model2_array_pointer"][version]; -- Kiosk doesn't move
end

function getObjectModel2ArraySize()
	local objModel2Array = getObjectModel2Array();
	if isRDRAM(objModel2Array) then
		return mainmemory.read_u32_be(objModel2Array + object_size) / obj_model2_slot_size;
	end
	return 0;
end

function getObjectModel2SlotBase(index) -- TODO: Can this be used anywhere?
	local objModel2Array = getObjectModel2Array();
	if isRDRAM(objModel2Array) then
		return objModel2Array + index * obj_model2_slot_size;
	end
end

function getObjectModel2ModelBase(index)
	local objModel2Array = getObjectModel2Array();
	if isRDRAM(objModel2Array) then
		return dereferencePointer(objModel2Array + (index * obj_model2_slot_size) + obj_model2.model_pointer);
	end
end

function getScriptName(objectModel2Base) -- TODO: Can this be used anywhere else?
	local behaviorTypePointer = dereferencePointer(objectModel2Base + obj_model2.behavior_type_pointer);
	if isRDRAM(behaviorTypePointer) then
		return readNullTerminatedString(behaviorTypePointer + 0x0C);
	end
	return "";
end

object_model2_filter = nil;
function populateObjectModel2Pointers()
	object_pointers = {};
	local objModel2Array = getObjectModel2Array();
	if isRDRAM(objModel2Array) then
		if version ~= 4 then
			numSlots = mainmemory.read_u32_be(Game.Memory["obj_model2_array_count"][version]);
		else
			numSlots = 430;
		end

		if object_model2_filter == nil then
			-- Fill and sort pointer list
			for i = 1, numSlots do
				table.insert(object_pointers, objModel2Array + (i - 1) * obj_model2_slot_size);
			end
		else
			-- Fill and sort pointer list
			for i = 1, numSlots do
				base = objModel2Array + (i - 1) * obj_model2_slot_size;
				if getScriptName(base) == object_model2_filter then
					table.insert(object_pointers, base);
				end
			end
		end
	end
end

local function encirclePlayerObjectModel2()
	if encircle_enabled and stringContains(grab_script_mode, "Model 2") then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local xPos = mainmemory.readfloat(playerObject + obj_model1.x_pos, true);
			local yPos = mainmemory.readfloat(playerObject + obj_model1.y_pos, true);
			local zPos = mainmemory.readfloat(playerObject + obj_model1.z_pos, true);

			-- Iterate and set position
			local x, z, modelPointer;
			for i = 1, #object_pointers do
				x = xPos + math.cos(math.pi * 2 * i / #object_pointers) * radius;
				z = zPos + math.sin(math.pi * 2 * i / #object_pointers) * radius;

				-- Set hitbox X, Y, Z
				mainmemory.writefloat(object_pointers[i] + obj_model2.x_pos, x, true);
				mainmemory.writefloat(object_pointers[i] + obj_model2.y_pos, yPos, true);
				mainmemory.writefloat(object_pointers[i] + obj_model2.z_pos, z, true);

				-- Set model X, Y, Z
				modelPointer = dereferencePointer(object_pointers[i] + obj_model2.model_pointer);
				if isRDRAM(modelPointer) then
					mainmemory.writefloat(modelPointer + obj_model2.model.x_pos, x, true);
					mainmemory.writefloat(modelPointer + obj_model2.model.y_pos, yPos, true);
					mainmemory.writefloat(modelPointer + obj_model2.model.z_pos, z, true);
				end
			end
		end
	end
end

function offsetObjectModel2(x, y, z)
	-- Iterate and set position
	local behaviorTypePointer, behaviorType, modelPointer, currentX, currentY, currentZ;
	for i = 1, #object_pointers do
		behaviorTypePointer = dereferencePointer(object_pointers[i] + obj_model2.behavior_type_pointer);
		behaviorType = "unknown";
		if isRDRAM(behaviorTypePointer) then
			behaviorType = readNullTerminatedString(behaviorTypePointer + 0x0C);
		end
		if behaviorType == "pickups" then
			-- Read hitbox X, Y, Z
			currentX = mainmemory.readfloat(object_pointers[i] + obj_model2.x_pos, true);
			currentY = mainmemory.readfloat(object_pointers[i] + obj_model2.y_pos, true);
			currentZ = mainmemory.readfloat(object_pointers[i] + obj_model2.z_pos, true);

			-- Write hitbox X, Y, Z
			mainmemory.writefloat(object_pointers[i] + obj_model2.x_pos, currentX + x, true);
			mainmemory.writefloat(object_pointers[i] + obj_model2.y_pos, currentY + y, true);
			mainmemory.writefloat(object_pointers[i] + obj_model2.z_pos, currentZ + z, true);

			-- Check for model
			modelPointer = dereferencePointer(object_pointers[i] + obj_model2.model_pointer);
			if isRDRAM(modelPointer) then
				-- Read model X, Y, Z
				currentX = mainmemory.readfloat(modelPointer + obj_model2.model.x_pos, true);
				currentY = mainmemory.readfloat(modelPointer + obj_model2.model.y_pos, true);
				currentZ = mainmemory.readfloat(modelPointer + obj_model2.model.z_pos, true);

				-- Write model X, Y, Z
				mainmemory.writefloat(modelPointer + obj_model2.model.x_pos, currentX + x, true);
				mainmemory.writefloat(modelPointer + obj_model2.model.y_pos, currentY + y, true);
				mainmemory.writefloat(modelPointer + obj_model2.model.z_pos, currentZ + z, true);
			end
		end
	end
end

local function getExamineDataModelTwo(pointer)
	local examine_data = {};

	if not isRDRAM(pointer) then
		return examine_data;
	end

	local modelPointer = dereferencePointer(pointer + obj_model2.model_pointer);
	local hasModel = isRDRAM(modelPointer);

	local xPos = mainmemory.readfloat(pointer + obj_model2.x_pos, true);
	local yPos = mainmemory.readfloat(pointer + obj_model2.y_pos, true);
	local zPos = mainmemory.readfloat(pointer + obj_model2.z_pos, true);
	local hasPosition = xPos ~= 0 or yPos ~= 0 or zPos ~= 0 or hasModel;

	table.insert(examine_data, { "Slot base", toHexString(pointer, 6) });
	local behaviorTypePointer = mainmemory.read_u32_be(pointer + obj_model2.behavior_type_pointer); -- TODO: dereferencePointer calls
	local behaviorPointer = mainmemory.read_u32_be(pointer + obj_model2.behavior_pointer);
	local behaviorType = "unknown";
	if isPointer(behaviorTypePointer) then
		behaviorType = readNullTerminatedString(behaviorTypePointer - RDRAMBase + 0x0C);
		table.insert(examine_data, { "Behavior Type", behaviorType });
		table.insert(examine_data, { "Behavior Type Pointer", toHexString(behaviorTypePointer) });
	end
	if isPointer(behaviorPointer) then
		table.insert(examine_data, { "Behavior Pointer", toHexString(behaviorPointer) });
	end
	table.insert(examine_data, { "Separator", 1 });

	if behaviorType == "pads" then
		table.insert(examine_data, { "Warp Pad Texture", toHexString(mainmemory.read_u32_be(behaviorTypePointer - RDRAMBase + 0x374), 8) }); -- TODO: figure out the format for behavior scripts
		table.insert(examine_data, { "Separator", 1 });
	end

	if behaviorType == "gunswitches" then
		table.insert(examine_data, { "Gunswitch Texture", toHexString(mainmemory.read_u32_be(behaviorTypePointer - RDRAMBase + 0x22C), 8) }); -- TODO: figure out the format for behavior scripts
		table.insert(examine_data, { "Separator", 1 });
	end

	if hasPosition then
		table.insert(examine_data, { "Hitbox X", xPos });
		table.insert(examine_data, { "Hitbox Y", yPos });
		table.insert(examine_data, { "Hitbox Z", zPos });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Hitbox Scale", mainmemory.readfloat(pointer + obj_model2.hitbox_scale, true) });
		table.insert(examine_data, { "Separator", 1 });
	end

	table.insert(examine_data, { "Unknown Counter", mainmemory.read_u16_be(pointer + obj_model2.unknown_counter) });
	table.insert(examine_data, { "GB Interaction Bitfield", bizstring.binary(mainmemory.readbyte(pointer + obj_model2.collectable_state)) });

	if hasModel then
		table.insert(examine_data, { "Model Base", toHexString(modelPointer, 6) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Model X", mainmemory.readfloat(modelPointer + obj_model2.model.x_pos, true) });
		table.insert(examine_data, { "Model Y", mainmemory.readfloat(modelPointer + obj_model2.model.y_pos, true) });
		table.insert(examine_data, { "Model Z", mainmemory.readfloat(modelPointer + obj_model2.model.z_pos, true) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Model Rot X", mainmemory.readfloat(modelPointer + obj_model2.model.rot_x, true) });
		table.insert(examine_data, { "Model Rot Y", mainmemory.readfloat(modelPointer + obj_model2.model.rot_y, true) });
		table.insert(examine_data, { "Model Rot Z", mainmemory.readfloat(modelPointer + obj_model2.model.rot_z, true) });
		table.insert(examine_data, { "Separator", 1 });

		table.insert(examine_data, { "Model Scale", mainmemory.readfloat(modelPointer + obj_model2.model.scale, true) });
		table.insert(examine_data, { "Separator", 1 });
	end

	return examine_data;
end

--------------------------------
-- Loading Zone Documentation --
--------------------------------

function getLoadingZoneArray()
	if version ~= 4 then
		return dereferencePointer(Game.Memory.loading_zone_array[version]);
	end
end

local loading_zone_size = 0x3A;
local loading_zone_fields = {
	["x_position"] = 0x00, -- s16_be
	["y_position"] = 0x02, -- s16_be
	["z_position"] = 0x04, -- s16_be
	["object_type"] = 0x10, -- u16_be
	["object_types"] = {
		[0x05] = "Cutscene Trigger",
		[0x09] = "Loading Zone",
		[0x0A] = "Cutscene Trigger",
		[0x0C] = "Loading Zone + Objects", -- Alows objects through
		[0x0D] = "Loading Zone",
		[0x10] = "Loading Zone",
		[0x11] = "Loading Zone", -- Snide's
		-- [0x13] = "Unknown - Caves Lobby", -- Behind ice walls
		[0x15] = "Cutscene Trigger",
		[0x17] = "Cutscene Trigger",
		-- [0x19] = "Trigger", -- Seal Race
	},
	["destination_map"] = 0x12, -- u16_be, index of Game.maps
	["destination_exit"] = 0x14, -- u16_be
	["fade_type"] = 0x16, -- u16_be?
	["active"] = 0x39, -- Byte
};

function getExamineDataLoadingZone(base)
	local data = {};
	if isRDRAM(base) then
		local _type = mainmemory.read_u16_be(base + loading_zone_fields.object_type);
		if loading_zone_fields.object_types[_type] ~= nil then
			_type = loading_zone_fields.object_types[_type].." ("..toHexString(_type)..")";
		else
			_type = toHexString(_type);
		end
		table.insert(data, {"Address", toHexString(base)});
		table.insert(data, {"Type", _type});
		table.insert(data, {"Separator", 1});

		if stringContains(_type, "Cutscene Trigger") then
			table.insert(data, {"Cutscene Index", mainmemory.read_u16_be(base + loading_zone_fields.destination_map)});
			table.insert(data, {"Separator", 1});
		end

		if stringContains(_type, "Loading Zone") then
			local destinationMap = mainmemory.read_u16_be(base + loading_zone_fields.destination_map);
			if Game.maps[destinationMap + 1] ~= nil then
				destinationMap = Game.maps[destinationMap + 1];
			else
				destinationMap = "Unknown Map "..toHexString(destinationMap);
			end
			table.insert(data, {"Destination Map", destinationMap});
			table.insert(data, {"Destination Exit", mainmemory.read_u16_be(base + loading_zone_fields.destination_exit)});
			table.insert(data, {"Fade", mainmemory.read_u16_be(base + loading_zone_fields.fade_type)});
			table.insert(data, {"Active", mainmemory.readbyte(base + loading_zone_fields.active)});
			table.insert(data, {"Separator", 1});
		end

		table.insert(data, {"X Position", mainmemory.read_s16_be(base + loading_zone_fields.x_position)});
		table.insert(data, {"Y Position", mainmemory.read_s16_be(base + loading_zone_fields.y_position)});
		table.insert(data, {"Z Position", mainmemory.read_s16_be(base + loading_zone_fields.z_position)});
		table.insert(data, {"Separator", 1});
	end
	return data;
end

function populateLoadingZonePointers()
	object_pointers = {};
	local loadingZoneArray = getLoadingZoneArray();
	if isRDRAM(loadingZoneArray) then
		local arraySize = mainmemory.read_u16_be(Game.Memory.loading_zone_array_size[version]);
		for i = 0, arraySize do
			table.insert(object_pointers, loadingZoneArray + (i * loading_zone_size));
		end

		-- Clamp index
		object_index = math.min(object_index, math.max(1, #object_pointers));
	end
end

function dumpLoadingZones()
	local loadingZoneArray = getLoadingZoneArray();
	if isRDRAM(loadingZoneArray) then
		local arraySize = mainmemory.read_u16_be(Game.Memory.loading_zone_array_size[version]);
		for i = 0, arraySize do
			local base = loadingZoneArray + (i * loading_zone_size);

			if isRDRAM(base) then
				local _type = mainmemory.read_u16_be(base + loading_zone_fields.object_type);
				if loading_zone_fields.object_types[_type] ~= nil then
					_type = loading_zone_fields.object_types[_type].." ("..toHexString(_type)..")";
				else
					_type = toHexString(_type);
				end

				if stringContains(_type, "Loading Zone") then
					local destinationMap = mainmemory.read_u16_be(base + loading_zone_fields.destination_map);
					if Game.maps[destinationMap + 1] ~= nil then
						destinationMap = Game.maps[destinationMap + 1];
					else
						destinationMap = "Unknown Map "..toHexString(destinationMap);
					end
					local destinationExit = mainmemory.read_u16_be(base + loading_zone_fields.destination_exit);
					local transitionType = mainmemory.read_u16_be(base + loading_zone_fields.fade_type);

					local xPosition = mainmemory.read_s16_be(base + loading_zone_fields.x_position);
					local yPosition = mainmemory.read_s16_be(base + loading_zone_fields.y_position);
					local zPosition = mainmemory.read_s16_be(base + loading_zone_fields.z_position);

					print(Game.maps[map_value + 1]..","..destinationMap..","..destinationExit..","..transitionType..",unknown,"..xPosition..","..yPosition..","..zPosition);
				end
			end
		end
	end
end

--------------------
-- Region/Version --
--------------------

function Game.detectVersion(romName, romHash)
	if romHash == "CF806FF2603640A748FCA5026DED28802F1F4A50" then -- USA
		version = 1;
		flag_array = require("games.dk64_flags");
	elseif romHash == "F96AF883845308106600D84E0618C1A066DC6676" then -- Europe
		version = 2;
		flag_array = require("games.dk64_flags");

		--Mad Jack
		MJ_offsets["ticks_until_next_action"] = 0x25;
		MJ_offsets["actions_remaining"]       = 0x60;
		MJ_offsets["action_type"]             = 0x61;
		MJ_offsets["current_position"]        = 0x68;
		MJ_offsets["next_position"]           = 0x69;
		MJ_offsets["white_switch_position"]   = 0x6C;
		MJ_offsets["blue_switch_position"]    = 0x6D;

		--Subgames
		jumpman_position = {0x03ECD0, 0x03ECD4};
		jumpman_velocity = {0x03ECD8, 0x03ECDC};
		jetman_position  = {0x022100, 0x022104};
		jetman_velocity  = {0x022108, 0x02210C};
	elseif romHash == "F0AD2B2BBF04D574ED7AFBB1BB6A4F0511DCD87D" then -- Japan
		version = 3;
		flag_array = require("games.dk64_flags_JP");

		--Mad Jack
		MJ_offsets["ticks_until_next_action"] = 0x25;
		MJ_offsets["actions_remaining"]       = 0x60;
		MJ_offsets["action_type"]             = 0x61;
		MJ_offsets["current_position"]        = 0x68;
		MJ_offsets["next_position"]           = 0x69;
		MJ_offsets["white_switch_position"]   = 0x6C;
		MJ_offsets["blue_switch_position"]    = 0x6D;

		--Subgames
		jumpman_position = {0x03EB00, 0x03EB04};
		jumpman_velocity = {0x03EB00, 0x03EB04};
		jetman_position  = {0x022060, 0x022064};
		jetman_velocity  = {0x022068, 0x02206C};
	elseif romHash == "B4717E602F07CA9BE0D4822813C658CD8B99F993" then -- Kiosk
		version = 4;
		-- flag_array = require("games.dk64_flags_Kiosk"); -- TODO: Flags?

		-- Kiosk specific Object Model 1 offsets
		obj_model1.x_rot = 0xD8;
		obj_model1.y_rot = 0xDA;
		obj_model1.z_rot = 0xDC;

		obj_model1.velocity = 0xB0;
		obj_model1.y_velocity = 0xB8;
		obj_model1.y_acceleration = 0xBC;
		obj_model1.hand_state = 0x137;
		obj_model1.control_state_byte = 0x144;
		obj_model1.control_states = { -- TODO: Fill this in
			[0x02] = "First Person Camera",
			[0x03] = "First Person Camera", -- Water
			[0x04] = "Fairy Camera",
			[0x05] = "Fairy Camera", -- Water

			[0x07] = "Minecart (Idle)",
			[0x08] = "Minecart (Crouch)",
			[0x09] = "Minecart (Jump)",
			[0x0A] = "Minecart (Left)",
			[0x0B] = "Minecart (Right)",
			[0x0C] = "Idle",
			[0x0D] = "Walking",

			[0x0F] = "Skidding",

			[0x18] = "Jumping",

			[0x1C] = "Simian Slam",
			[0x1D] = "Long Jumping",
			[0x1F] = "Falling",
			[0x20] = "Falling/Splat",

			[0x23] = "Primate Punch",

			[0x25] = "Ground Attack",

			[0x28] = "Moving Ground Attack",
			[0x29] = "Aerial Attack",

			[0x2D] = "Charging", -- Rambi

			[0x2F] = "Damaged",

			[0x37] = "Crouching",
			[0x38] = "Uncrouching",
			[0x39] = "Backflip",

			[0x44] = "Picking up Object",
			[0x45] = "Idle", -- Carrying Object
			[0x46] = "Walking", -- Carrying Object
			[0x47] = "Dropping Object",

			[0x49] = "Jumping", -- Carrying Object

			[0x4F] = "Bananaporter",

			[0x6B] = "Key Dance",

			[0x71] = "Locked", -- Tons of cutscenes use this
		};
		obj_model1.camera.focus_pointer = 0x168;
		obj_model1.player.grab_pointer = 0x2F4;

		obj_model1.actor_types = {
			[2] = "DK",
			[3] = "Diddy",
			[4] = "Lanky",
			[5] = "Tiny",
			[6] = "Chunky",
			[7] = "Rambi",
			[11] = "Loading Zone Controller",
			[25] = "TNT Barrel",
			[26] = "TNT Barrel Spawner (Army Dillo)",
			[29] = "Fireball", -- Army Dillo, Dogadon
			[71] = "Boss Key",
			[96] = "TNT Barrel Spawner (Dogadon)",
			[145] = "Army Dillo",
			[149] = "Camera",
			[201] = "Dogadon",
			[214] = "Banana Fairy",
			[221] = "Static Object", -- Fake Chunky in Dogadon 2 opening cutscene
			[230] = "Fireball Shockwave", -- Dogadon
			[232] = "Light Beam", -- Boss fights etc
		};

		-- Kiosk version maps
		--0 Crash
		--1 Crash
		--2 Crash
		--3 Dogadon (2?) fight (Crash??!?!?!)
		--4 Crash
		--5 Crash
		--6 Minecart
		--7 Crash
		--8 Army Dillo fight
		--9-39 Crash
		--40 N+R logo
		--41-75 Crash
		--76 DK Rap
		--77 Crash
		--78 Crash
		--79 Crash
		--80 Title screen
		--81 "Thanks for playing" or Test Map
		--82 Crash?
		--83 Dogadon Fight
		--84-214 Crash
		--215 Partially loads (kong position changes), then crashes
		--216-228 Crash
		--229 Partially loads (kong position changes), then crashes
		--230-240 Crash
		--241 Partially loads (kong position changes), then crashes
		--242-255 Crash
	else
		return false;
	end

	-- Read EEPROM checksums
	if memory.usememorydomain("EEPROM") then
		for i = 1, #eep_checksum_offsets do
			eep_checksum_values[i] = memory.read_u32_be(eep_checksum_offsets[i]);
		end
	end
	memory.usememorydomain("RDRAM");

	-- Fill the flag names
	if #flag_array > 0 then
		for i = 1, #flag_array do
			flag_names[i] = flag_array[i]["name"];
		end
	else
		print("Warning: No flags found");
		flag_names = {"None"};
	end

	return true;
end

----------------
-- Flag stuff --
----------------

local flag_block_size = 0x13B; -- TODO: Different size on Europe/Japan? -- TODO: Find exact size

local flag_action_queue = {};
flag_block = {};

function adjustBlockSize(value)
	flag_block = {};
	flag_block_size = value;
	checkFlags();
end

function isFound(byte, bit)
	for i = 1, #flag_array do
		if byte == flag_array[i]["byte"] and bit == flag_array[i]["bit"] then
			return true;
		end
	end
	return false;
end

function isValidFlagBlockAddress(address)
	return type(address) == "number" and address > 0x700000 and address ~= 0x756494 and address ~= 0x7F0000 and address ~= 0x7FBFB0 and address < RDRAMSize - flag_block_size;
end

local function getFlagByName(flagName)
	for i = 1, #flag_array do
		if flagName == flag_array[i]["name"] then
			return flag_array[i];
		end
	end
end

local function getFlagName(byte, bit)
	for i = 1, #flag_array do
		if byte == flag_array[i]["byte"] and bit == flag_array[i]["bit"] then
			return flag_array[i]["name"];
		end
	end
	return "Unknown at "..toHexString(byte)..">"..bit;
end

function checkFlags(_type)
	local flags = dereferencePointer(Game.Memory.flag_block_pointer[version]);
	if isValidFlagBlockAddress(flags) then
		local temp_value;
		local flag_found = false;
		local known_flags_found = 0;
		_type = _type or "Type";

		if #flag_block > 0 then
			for i = 0, #flag_block do
				temp_value = mainmemory.readbyte(flags + i);
				if flag_block[i] ~= temp_value then
					for bit = 0, 7 do
						if get_bit(temp_value, bit) and not get_bit(flag_block[i], bit) then
							-- Output debug info if the flag isn't known
							if not isFound(i, bit) then
								flag_found = true;
								dprint("{[\"byte\"] = "..toHexString(i)..", [\"bit\"] = "..bit..", [\"name\"] = \"Name\", [\"type\"] = \"".._type.."\", [\"map\"] = "..Game.getMap().."},");
							else
								known_flags_found = known_flags_found + 1;
							end
						end
					end

					-- Update entry in array
					flag_block[i] = temp_value;
				end
			end
			if known_flags_found > 0 then
				dprint(known_flags_found.." Known flags skipped.")
			end
			if not flag_found then
				dprint("No unknown flags were changed.")
			end
		else
			-- Populate flag block
			for i = 0, flag_block_size do
				flag_block[i] = mainmemory.readbyte(flags + i);
			end
			dprint("Populated flag array.")
		end
	else
		dprint("Failed to find flag block on this frame, adding to queue. Will be checked next time block is found.");
		table.insert(flag_action_queue, {["action_type"] = "check"});
	end
	print_deferred();
end

local function processFlagQueue()
	if #flag_action_queue > 0 then
		local flags = dereferencePointer(Game.Memory.flag_block_pointer[version]);
		if isValidFlagBlockAddress(flags) then
			local queue_item, current_value;
			for i = 1, #flag_action_queue do
				queue_item = flag_action_queue[i];
				if type(queue_item) == "table" then
					if queue_item["action_type"] == "set" then
						current_value = mainmemory.readbyte(flags + queue_item["byte"]);
						mainmemory.writebyte(flags + queue_item["byte"], set_bit(current_value, queue_item["bit"]));
						if not queue_item["suppressPrint"] then
							if type(queue_item["name"]) == "string" then
								dprint("Set \""..queue_item["name"].."\" at "..toHexString(queue_item["byte"])..">"..queue_item["bit"]);
							else
								dprint("Set "..getFlagName(queue_item["byte"], queue_item["bit"]));
							end
						end
					elseif queue_item["action_type"] == "clear" then
						current_value = mainmemory.readbyte(flags + queue_item["byte"]);
						mainmemory.writebyte(flags + queue_item["byte"], clear_bit(current_value, queue_item["bit"]));
						if not queue_item["suppressPrint"] then
							if type(queue_item["name"]) == "string" then
								dprint("Cleared \""..queue_item["name"].."\" at "..toHexString(queue_item["byte"])..">"..queue_item["bit"]);
							else
								dprint("Cleared "..getFlagName(queue_item["byte"], queue_item["bit"]));
							end
						end
					elseif queue_item["action_type"] == "checkSingle" then
						current_value = mainmemory.readbyte(flags + queue_item["byte"]);
						if check_bit(current_value, queue_item["bit"]) then
							dprint(getFlagName(queue_item["byte"], queue_item["bit"]).." is set.");
						else
							dprint(getFlagName(queue_item["byte"], queue_item["bit"]).." is not set.");
						end
					elseif queue_item["action_type"] == "check" then
						checkFlags();
					end
				end
			end
			-- Speed up output by printing everything in one call to print
			print_deferred();
			-- Clear queue if we found the block that frame
			flag_action_queue = {};
		end
	end
end

function checkFlag(byte, bit)
	if type(byte) == "string" then
		local flag = getFlagByName(byte);
		if type(flag) == "table" then
			byte = flag["byte"];
			bit = flag["bit"];
		end
	end
	if type(byte) == "number" and type(bit) == "number" then
		table.insert(flag_action_queue, {["action_type"] = "checkSingle", ["byte"] = byte, ["bit"] = bit});
	else
		print("Warning: Flag not found.");
	end
end

----------------------------------
-- Duplicate checking functions --
----------------------------------

local function checkDuplicatedName(flagName)
	local count = 0;
	local flags = {};
	for i = 1, #flag_array do
		if flagName == flag_array[i]["name"] then
			count = count + 1;
			table.insert(flags, flag_array[i]);
		end
	end
	if #flags > 1 then
		for i = 1, #flags do
			print("Warning: Duplicate flag name found for '"..flags[i]["name"].."' at "..toHexString(flags[i]["byte"])..">"..flags[i]["bit"]);
		end
	end
end

function checkDuplicateFlagNames()
	for i = 1, #flag_array do
		checkDuplicatedName(flag_array[i]["name"]);
	end
end

------------------------
-- Set flag functions --
------------------------

function setFlag(byte, bit, suppressPrint)
	suppressPrint = suppressPrint or false;
	if type(byte) == "number" and type(bit) == "number" and bit >= 0 and bit <= 7 then
		table.insert(flag_action_queue, {["action_type"] = "set", ["byte"] = byte, ["bit"] = bit, ["suppressPrint"] = suppressPrint});
		processFlagQueue();
	end
end

function setFlagByName(name)
	local flag = getFlagByName(name);
	if type(flag) == "table" then
		flag["action_type"] = "set";
		table.insert(flag_action_queue, flag);
		processFlagQueue();
	end
end

function setFlagsByType(_type)
	local num_set = 0;
	if type(_type) == "string" then
		local flag;
		for i = 1, #flag_array do
			if flag_array[i]["type"] == _type then
				flag = flag_array[i];
				flag["action_type"] = "set";
				flag["suppressPrint"] = true;
				table.insert(flag_action_queue, flag);
				num_set = num_set + 1;
			end
		end
	end
	if num_set > 0 then
		processFlagQueue();
		print("Set "..num_set.." flags of type '".._type.."'");
	else
		print("No flags found of type '".._type.."'");
	end
end

function setFlagsByMap(mapIndex)
	for i = 1, #flag_array do
		local flag = flag_array[i];
		if flag["map"] == mapIndex then
			setFlag(flag["byte"], flag["bit"], true);
		end
	end
end

function clearFlagsByMap(mapIndex)
	for i = 1, #flag_array do
		local flag = flag_array[i];
		if flag["map"] == mapIndex then
			clearFlag(flag["byte"], flag["bit"], true);
		end
	end
end

function setKnownFlags()
	for i = 1, #flag_array do
		local flag = flag_array[i];
		if flag["type"] ~= "Unknown" then
			setFlag(flag["byte"], flag["bit"], true);
		end
	end
end

function clearKnownFlags()
	for i = 1, #flag_array do
		local flag = flag_array[i];
		if flag["type"] ~= "Unknown" then
			clearFlag(flag["byte"], flag["bit"], true);
		end
	end
end

function setAllFlags()
	for byte = 0, flag_block_size do
		for bit = 0, 7 do
			setFlag(byte, bit, true);
		end
	end
end

function clearAllFlags()
	for byte = 0, flag_block_size do
		for bit = 0, 7 do
			clearFlag(byte, bit, true);
		end
	end
end

--------------------------
-- Clear flag functions --
--------------------------

function clearFlag(byte, bit, suppressPrint)
	suppressPrint = suppressPrint or false;
	if type(byte) == "number" and type(bit) == "number" and bit >= 0 and bit <= 7 then
		table.insert(flag_action_queue, {["action_type"] = "clear", ["byte"] = byte, ["bit"] = bit, ["suppressPrint"] = suppressPrint});
		processFlagQueue();
	end
end

function clearFlagByName(name)
	local flag = getFlagByName(name);
	if type(flag) == "table" then
		flag["action_type"] = "clear";
		table.insert(flag_action_queue, flag);
		processFlagQueue();
	end
end

function clearFlagByType(_type)
	local num_cleared = 0;
	if type(_type) == "string" then
		local flag;
		for i = 1, #flag_array do
			if flag_array[i]["type"] == _type then
				flag = flag_array[i];
				flag["action_type"] = "clear";
				flag["suppressPrint"] = true;
				table.insert(flag_action_queue, flag);
				num_cleared = num_cleared + 1;
			end
		end
	end
	if num_cleared > 0 then
		processFlagQueue();
		print("Cleared "..num_cleared.." flags of type '".._type.."'");
	else
		print("No flags found for specified type.");
	end
end
clearFlagsByType = clearFlagByType;

--------------------------
-- Other flag functions --
--------------------------

local function flagSetButtonHandler()
	setFlagByName(forms.getproperty(ScriptHawk.UI.form_controls["Flag Dropdown"], "SelectedItem"));
end

local function flagClearButtonHandler()
	clearFlagByName(forms.getproperty(ScriptHawk.UI.form_controls["Flag Dropdown"], "SelectedItem"));
end

local function formatOutputString(caption, value, max)
	return caption..value.."/"..max.." or "..round(value / max * 100, 2).."%";
end

function flagStats(verbose)
	local fairies_known = 0;
	local blueprints_known = 0;
	local warps_known = 0;
	local cb_known = 0;
	local gb_known = 0;
	local crowns_known = 0;
	local coins_known = 0;
	local medals_known = 0;
	local untypedFlags = 0;
	local flagsWithUnknownType = 0;

	-- Setting this to true warns the user of flags without types
	verbose = verbose or false;

	local flag, name, flagType, validType;
	for i = 1, #flag_array do
		flag = flag_array[i];
		name = flag["name"];
		flagType = flag["type"];
		validType = false;
		if flagType == "Fairy" then
			fairies_known = fairies_known + 1;
			validType = true;
		end
		if flagType == "Blueprint" then
			blueprints_known = blueprints_known + 1;
			validType = true;
		end
		if flagType == "Warp" or name == "Caves: Tiny GB: W3" or name == "Aztec: DK GB: W5" or name == "Galleon: Diddy GB: W4" then
			warps_known = warps_known + 1;
			validType = true;
		end
		if flagType == "GB" then
			gb_known = gb_known + 1;
			validType = true;
		end
		if flagType == "CB" then
			cb_known = cb_known + 1;
			validType = true;
		end
		if flagType == "Bunch" then
			cb_known = cb_known + 5;
			validType = true;
		end
		if flagType == "Balloon" then
			cb_known = cb_known + 10;
			validType = true;
		end
		if flagType == "Crown" then
			crowns_known = crowns_known + 1;
			validType = true;
		end
		if flagType == "Coin" then
			coins_known = coins_known + 1;
			validType = true;
		end
		if flagType == "Medal" then
			medals_known = medals_known + 1;
			validType = true;
		end
		if flagType == "Rainbow Coin" then
			coins_known = coins_known + 25;
			validType = true;
		end
		if flagType == nil then
			untypedFlags = untypedFlags + 1;
			if verbose then
				dprint("Warning: Flag without type at "..toHexString(flag["byte"])..">"..flag["bit"].." with name: \""..name.."\"");
			end
		else
			if flagType == "B. Locker" or flagType == "Cutscene" or flagType == "FTT" or flagType == "Key" or flagType == "Kong" or flagType == "T&S" or flagType == "Unknown" then
				validType = true;
			end
			if not validType then
				flagsWithUnknownType = flagsWithUnknownType + 1;
				if verbose then
					dprint("Warning: Flag with unknown type at "..toHexString(flag["byte"])..">"..flag["bit"].." with name: \""..name.."\"".." and type: \""..flagType.."\"");
				end
			end
		end
	end

	local knownFlags = #flag_array;
	local totalFlags = flag_block_size * 8;

	dprint("Block size: "..toHexString(flag_block_size));
	dprint(formatOutputString("Flags known: ", knownFlags, totalFlags));
	dprint(formatOutputString("Without types: ", untypedFlags, knownFlags));
	dprint(formatOutputString("Unknown types: ", flagsWithUnknownType, knownFlags));
	dprint("");
	dprint(formatOutputString("CB: ", cb_known, max_cb));
	dprint(formatOutputString("GB: ", gb_known, max_gb));
	dprint("");
	dprint(formatOutputString("Crowns: ", crowns_known, max_crowns));
	dprint(formatOutputString("Fairies: ", fairies_known, max_fairies));
	dprint(formatOutputString("Blueprints: ", blueprints_known, max_blueprints));
	dprint(formatOutputString("Medals: ", medals_known, max_medals));
	dprint(formatOutputString("Warps: ", warps_known, max_warps));
	dprint("Coins: "..coins_known); -- Just a note: Fungi Rabbit Race coins aren't flagged
	dprint("");
	print_deferred();
end

------------------
-- TBS Nonsense --
------------------

force_tbs = false; -- Set this through lua console for now -- TODO: Add some kind of UI for it
function forceTBS()
	if force_tbs then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local pointer = dereferencePointer(playerObject + obj_model1.lock_method_1_pointer);
			if isRDRAM(pointer) then
				mainmemory.write_u32_be(playerObject + obj_model1.lock_method_1_pointer, 0);
				print("Forcing TBS. Nulled pointer to "..toHexString(pointer));
			end
		end
	end
end

-------------------
-- Physics/Scale --
-------------------

Game.speedy_speeds = { .001, .01, .1, 1, 5, 10, 15, 20, 35, 50, 100, 250, 500, 1000 };
Game.speedy_index = 8;

Game.rot_speed = 10;
Game.max_rot_units = 4096;

function isInSubGame()
	return map_value == arcade_map or map_value == jetpac_map;
end

function Game.getFloor()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + obj_model1.floor, true);
	end
	return 0;
end

function Game.setFloor(value)
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + obj_model1.floor, value, true);
	end
end

function Game.getDistanceFromFloor()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + obj_model1.distance_from_floor, true);
	end
	return 0;
end

function Game.getCameraState()
	local cameraObject = dereferencePointer(Game.Memory.camera_pointer[version]);
	local cameraState = "Unknown";
	if isRDRAM(cameraObject) then
		cameraState = mainmemory.readbyte(cameraObject + obj_model1.camera.state_type);
		if obj_model1.camera.state_values[cameraState] ~= nil then
			cameraState = obj_model1.camera.state_values[cameraState];
		else
			cameraState = toHexString(cameraState);
		end
	end
	return cameraState;
end

function Game.getMovementState()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local controlState = mainmemory.readbyte(playerObject + obj_model1.control_state_byte);
		if obj_model1.control_states[controlState] ~= nil then
			return obj_model1.control_states[controlState];
		end
		return toHexString(controlState);
	end
	return 'Unknown';
end

function Game.setMovementState(value)
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		mainmemory.writebyte(playerObject + obj_model1.control_state_byte, value);
	end
end
Game.setControlState = Game.setMovementState;

-- TODO: Game.getWaterHeight()

--------------
-- Position --
--------------

function Game.getXPosition()
	if map_value == arcade_map then
		return mainmemory.readfloat(jumpman_position[1], true);
	elseif map_value == jetpac_map then
		return mainmemory.readfloat(jetman_position[1], true);
	end
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + obj_model1.x_pos, true);
	end
	return 0;
end

function Game.getYPosition()
	if map_value == arcade_map then
		return mainmemory.readfloat(jumpman_position[2], true);
	elseif map_value == jetpac_map then
		return mainmemory.readfloat(jetman_position[2], true);
	end
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + obj_model1.y_pos, true);
	end
	return 0;
end

function Game.getZPosition()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			return mainmemory.readfloat(playerObject + obj_model1.z_pos, true);
		end
	end
	return 0;
end

function Game.setXPosition(value)
	if map_value == arcade_map then
		--mainmemory.writefloat(jumpman_position[1], value, true);
	elseif map_value == jetpac_map then
		--mainmemory.writefloat(jetman_position[1], value, true);
	else
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local vehiclePointer = dereferencePointer(playerObject + obj_model1.player.vehicle_actor_pointer);
			if isRDRAM(vehiclePointer) then
				mainmemory.writefloat(vehiclePointer + obj_model1.x_pos, value, true);
			end
			mainmemory.writefloat(playerObject + obj_model1.x_pos, value, true);
			mainmemory.writebyte(playerObject + obj_model1.locked_to_pad, 0x00);
			mainmemory.write_u32_be(playerObject + obj_model1.lock_method_1_pointer, 0x00);
		end
	end
end

function Game.setYPosition(value)
	if map_value == arcade_map then
		--mainmemory.writefloat(jumpman_position[2], value, true);
	elseif map_value == jetpac_map then
		--mainmemory.writefloat(jetman_position[2], value, true);
	else
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local vehiclePointer = dereferencePointer(playerObject + obj_model1.player.vehicle_actor_pointer);
			if isRDRAM(vehiclePointer) then
				if mainmemory.readfloat(vehiclePointer + obj_model1.floor, true) > value then -- Move the vehicle floor down if the desired Y position is lower than the floor
					mainmemory.writefloat(vehiclePointer + obj_model1.floor, value, true);
				end
				mainmemory.writefloat(vehiclePointer + obj_model1.y_pos, value, true);
				mainmemory.writebyte(vehiclePointer + obj_model1.locked_to_pad, 0);
			end
			mainmemory.writefloat(playerObject + obj_model1.y_pos, value, true);
			mainmemory.writebyte(playerObject + obj_model1.locked_to_pad, 0);
			if Game.getFloor() > value then  -- Move the floor down if the desired Y position is lower than the floor
				Game.setFloor(value);
			end
			Game.setYVelocity(0);
		end
	end
end

function Game.setZPosition(value)
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local vehiclePointer = dereferencePointer(playerObject + obj_model1.player.vehicle_actor_pointer);
			if isRDRAM(vehiclePointer) then
				mainmemory.writefloat(vehiclePointer + obj_model1.z_pos, value, true);
			end
			mainmemory.writefloat(playerObject + obj_model1.z_pos, value, true);
			mainmemory.writebyte(playerObject + obj_model1.locked_to_pad, 0x00);
			mainmemory.write_u32_be(playerObject + obj_model1.lock_method_1_pointer, 0x00);
		end
	end
end

-- Relative to objects in bone array
local bone_size = 0x40;
local bone = {
	['position_x'] = 0x18, -- int 16 be
	['position_y'] = 0x1A, -- int 16 be
	['position_z'] = 0x1C, -- int 16 be
	['scale_x'] = 0x20, -- uint 16 be
	['scale_y'] = 0x2A, -- uint 16 be
	['scale_z'] = 0x34, -- uint 16 be
};

function Game.getActiveBoneArray()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			return mainmemory.read_u32_be(playerObject + obj_model1.current_bone_array_pointer);
		end
	end
	return 0;
end

function Game.getBoneArray1()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local animationParamObject = dereferencePointer(playerObject + obj_model1.rendering_parameters_pointer);
			if isRDRAM(animationParamObject) then
				return mainmemory.read_u32_be(animationParamObject + obj_model1.rendering_parameters.bone_array_1);
			end
		end
	end
	return 0;
end

function Game.getBoneArray2()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local animationParamObject = dereferencePointer(playerObject + obj_model1.rendering_parameters_pointer);
			if isRDRAM(animationParamObject) then
				return mainmemory.read_u32_be(animationParamObject + obj_model1.rendering_parameters.bone_array_2);
			end
		end
	end
	return 0;
end

function Game.getOSDBoneArray1()
	local suffix = "";
	if Game.getActiveBoneArray() == Game.getBoneArray1() then
		suffix = "*";
	end
	return toHexString(Game.getBoneArray1())..suffix;
end

function Game.getOSDBoneArray2()
	local suffix = "";
	if Game.getActiveBoneArray() == Game.getBoneArray2() then
		suffix = "*";
	end
	return toHexString(Game.getBoneArray2())..suffix;
end

function Game.getStoredX1()
	local boneArray1 = Game.getBoneArray1();
	if isPointer(boneArray1) then
		boneArray1 = boneArray1 - RDRAMBase;
		return mainmemory.read_s16_be(boneArray1 + bone_size + bone.position_x);
	end
	return 0;
end

function Game.getStoredX2()
	local boneArray2 = Game.getBoneArray2();
	if isPointer(boneArray2) then
		boneArray2 = boneArray2 - RDRAMBase;
		return mainmemory.read_s16_be(boneArray2 + bone_size + bone.position_x);
	end
	return 0;
end

function Game.getStoredY1()
	local boneArray1 = Game.getBoneArray1();
	if isPointer(boneArray1) then
		boneArray1 = boneArray1 - RDRAMBase;
		return mainmemory.read_s16_be(boneArray1 + bone_size + bone.position_y);
	end
	return 0;
end

function Game.getStoredY2()
	local boneArray2 = Game.getBoneArray2();
	if isPointer(boneArray2) then
		boneArray2 = boneArray2 - RDRAMBase;
		return mainmemory.read_s16_be(boneArray2 + bone_size + bone.position_y);
	end
	return 0;
end

function Game.getStoredZ1()
	local boneArray1 = Game.getBoneArray1();
	if isPointer(boneArray1) then
		boneArray1 = boneArray1 - RDRAMBase;
		return mainmemory.read_s16_be(boneArray1 + bone_size + bone.position_z);
	end
	return 0;
end

function Game.getStoredZ2()
	local boneArray2 = Game.getBoneArray2();
	if isPointer(boneArray2) then
		boneArray2 = boneArray2 - RDRAMBase;
		return mainmemory.read_s16_be(boneArray2 + bone_size + bone.position_z);
	end
	return 0;
end

--------------
-- Rotation --
--------------

function Game.getXRotation()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			return mainmemory.read_u16_be(playerObject + obj_model1.x_rot);
		end
	end
	return 0;
end

function Game.getYRotation()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			return mainmemory.read_u16_be(playerObject + obj_model1.y_rot);
		end
	end
	return 0;
end

function Game.colorYRotation()
	local currentRotation = Game.getYRotation()
	if currentRotation > 4095 then -- Detect STVW angles
		return 0xFF007FFF; -- Blue
	end
end

function Game.getZRotation()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			return mainmemory.read_u16_be(playerObject + obj_model1.z_rot);
		end
	end
	return 0;
end

function Game.setXRotation(value)
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			mainmemory.write_u16_be(playerObject + obj_model1.x_rot, value);
		end
	end
end

function Game.setYRotation(value)
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			mainmemory.write_u16_be(playerObject + obj_model1.y_rot, value);
		end
	end
end

function Game.setZRotation(value)
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			mainmemory.write_u16_be(playerObject + obj_model1.z_rot, value);
		end
	end
end

-----------------------------
-- Velocity & Acceleration --
-----------------------------

function Game.getVelocity()
	local playerObject = Game.getPlayerObject();
	if map_value == arcade_map then
		return mainmemory.readfloat(jumpman_velocity[1], true);
	elseif map_value == jetpac_map then
		return mainmemory.readfloat(jetman_velocity[1], true);
	elseif isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + obj_model1.velocity, true);
	end
	return 0;
end

function Game.setVelocity(value)
	local playerObject = Game.getPlayerObject();
	if map_value == arcade_map then
		mainmemory.writefloat(jumpman_velocity[1], value, true);
	elseif map_value == jetpac_map then
		mainmemory.writefloat(jetman_velocity[1], value, true);
	elseif isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + obj_model1.velocity, value, true);
	end
end

function Game.getYVelocity()
	local playerObject = Game.getPlayerObject();
	if map_value == arcade_map then
		return mainmemory.readfloat(jumpman_velocity[2], true);
	elseif map_value == jetpac_map then
		return mainmemory.readfloat(jetman_velocity[2], true);
	elseif isRDRAM(playerObject) then
		return mainmemory.readfloat(playerObject + obj_model1.y_velocity, true);
	end
	return 0;
end

function Game.setYVelocity(value)
	local playerObject = Game.getPlayerObject();
	if map_value == arcade_map then
		mainmemory.writefloat(jumpman_velocity[2], value, true);
	elseif map_value == jetpac_map then
		mainmemory.writefloat(jetman_velocity[2], value, true);
	elseif isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + obj_model1.y_velocity, value, true);
	end
end

function Game.getYAcceleration()
	if not isInSubGame() then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			return mainmemory.readfloat(playerObject + obj_model1.y_acceleration, true);
		end
	end
	return 0;
end

function Game.setYAcceleration(value)
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		mainmemory.writefloat(playerObject + obj_model1.y_acceleration, value, true);
	end
end

--------------------
-- Misc functions --
--------------------

local current_invisify = "Invisify";
local function toggle_invisify()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local visibilityBitfieldValue = mainmemory.readbyte(playerObject + obj_model1.visibility);
		mainmemory.writebyte(playerObject + obj_model1.visibility, toggle_bit(visibilityBitfieldValue, 2));
	end
end

local function updateCurrentInvisify()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local isVisible = check_bit(mainmemory.readbyte(playerObject + obj_model1.visibility), 2);
		if isVisible then
			current_invisify = "Invisify";
		else
			current_invisify = "Visify";
		end
		forms.settext(ScriptHawk.UI.form_controls["Toggle Visibility Button"], current_invisify);
	end
end

local function toggle_tb_void()
	local tb_void_byte_val = mainmemory.readbyte(Game.Memory.tb_void_byte[version]);
	tb_void_byte_val = toggle_bit(tb_void_byte_val, 4); -- Show Object Model 2 Objects
	tb_void_byte_val = toggle_bit(tb_void_byte_val, 5); -- Turn on the lights
	mainmemory.writebyte(Game.Memory.tb_void_byte[version], tb_void_byte_val);
end
toggleTBVoid = toggle_tb_void;
Game.toggleTBVoid = toggleTBVoid;

function force_pause()
	local voidByteValue = mainmemory.readbyte(Game.Memory.tb_void_byte[version]);
	mainmemory.writebyte(Game.Memory.tb_void_byte[version], set_bit(voidByteValue, 0));
end
forcePause = force_pause;
Game.forcePause = forcePause;

function force_zipper()
	local voidByteValue = mainmemory.readbyte(Game.Memory.tb_void_byte[version] - 1);
	mainmemory.writebyte(Game.Memory.tb_void_byte[version] - 1, set_bit(voidByteValue, 0));
end
forceZipper = force_zipper;
Game.forceZipper = forceZipper;

function gainControl()
	local playerObject = Game.getPlayerObject();
	local cameraObject = dereferencePointer(Game.Memory.camera_pointer[version]);
	if isRDRAM(playerObject) then
		local visibilityBitfieldValue = mainmemory.readbyte(playerObject + obj_model1.visibility);
		mainmemory.writebyte(playerObject + obj_model1.visibility, set_bit(visibilityBitfieldValue, 2));
		mainmemory.writebyte(playerObject + obj_model1.control_state_byte, 0x0C);
		local vehiclePointer = dereferencePointer(playerObject + obj_model1.player.vehicle_actor_pointer);
		if isRDRAM(vehiclePointer) then
			mainmemory.write_u32_be(playerObject + obj_model1.player.vehicle_actor_pointer, playerObject + RDRAMBase);
		end
		--mainmemory.write_u32_be(playerObject + obj_model1.lock_method_1_pointer, 0);
		if isRDRAM(cameraObject) then
			mainmemory.writebyte(cameraObject + obj_model1.camera.state_type, 1);
			mainmemory.write_u32_be(cameraObject + obj_model1.camera.focused_vehicle_pointer, 0);
			mainmemory.write_u32_be(cameraObject + obj_model1.camera.focused_vehicle_pointer_2, 0);
		end
	end
	mainmemory.write_u16_be(Game.Memory.buttons_enabled_bitfield[version], 0xFFFF); -- Enable all buttons
	mainmemory.writebyte(Game.Memory.joystick_enabled_x[version], 0xFF); -- Enable Joystick X axis
	mainmemory.writebyte(Game.Memory.joystick_enabled_y[version], 0xFF); -- Enable Joystick X axis
	mainmemory.writebyte(Game.Memory.map_state[version], 0x08); -- Patch map state byte to a value where the player has control, allows gaining control during death and some cutscenes
end
gain_control = gainControl;
Game.gainControl = gainControl;

-----------------------------------
-- DK64 - ISG Timer
-- Written by Isotarge, 2015
-- Based on research by Exchord
-----------------------------------

local timer_value = 0;
local timer_start_frame = 0;
local timer_started = false;

local function ISGTimer()
	if map_value == 153 and prev_map ~= 153 then
		timer_value = 0;
		timer_start_frame = emu.framecount();
		timer_started = true;
	end
	prev_map = map_value;

	if timer_started then
		timer_value = emu.framecount() - timer_start_frame;
	end

	if timer_value / 60 > 270 or timer_value < 0 then
		timer_value = 0;
		timer_start_frame = 0;
		timer_started = false;
	end
end

-----------------------------------
-- DK64 - Mad Jack Minimap
-- Written by Isotarge, 2014-2015
-----------------------------------

-- Colors (ARGB32)
local MJ_colors = {
	["blue"] = 0x7F00A2E8,
	["blue_switch"] = 0xFF00A2E8,
	["white"] = 0x7FFFFFFF,
	["white_switch"] = 0xFFFFFFFF
};

-- Minimap ui
local MJ_minimap_x_offset  = 19;
local MJ_minimap_y_offset  = 19;
local MJ_minimap_width     = 16;
local MJ_minimap_height    = 16;

local MJ_minimap_text_x = MJ_minimap_x_offset + 4.5 * MJ_minimap_width;
local MJ_minimap_text_y = MJ_minimap_y_offset;

local MJ_minimap_phase_number_y      = MJ_minimap_text_y;
local MJ_minimap_actions_remaining_y = MJ_minimap_phase_number_y + MJ_minimap_height;
local MJ_time_until_next_action_y    = MJ_minimap_actions_remaining_y + MJ_minimap_height;

local MJ_kong_row_y                  = MJ_time_until_next_action_y + MJ_minimap_height;
local MJ_kong_col_y                  = MJ_kong_row_y + MJ_minimap_height;

local function position_to_rowcol(pos)
	pos = math.floor((pos - 330) / 120); -- Calculate row index
	return math.min(7, math.max(0, pos)); -- Clamp between 0 and 7
end

local function MJ_get_col_mask(position)
	return bit.band(position, 0x03);
end

local function MJ_get_row_mask(position)
	return bit.rshift(bit.band(position, 0x0C), 2);
end

local function MJ_get_switch_active_mask(position)
	return bit.rshift(bit.band(position, 0x10), 4) > 0;
end

local function MJ_get_color(col, row)
	local color = 'blue';
	if row % 2 == col % 2 then
		color = 'white';
	end
	return color;
end

local function MJ_get_action_type(phase_byte)
	if phase_byte == 0x28 or phase_byte == 0x2D or phase_byte == 0x32 then
		return "Fireball";
	elseif phase_byte == 0x01 or phase_byte == 0x05 then
		return "Laser";
	end
	return "Jump";
end

local function MJ_get_phase(phase_byte)
	if phase_byte == 0x08 or phase_byte == 0x32 then
		return 1;
	elseif phase_byte == 0x0A or phase_byte == 0x2D then
		return 2;
	elseif phase_byte == 0x0B or phase_byte == 0x28 then
		return 3;
	elseif phase_byte == 0x0C or phase_byte == 0x05 then
		return 4;
	elseif phase_byte == 0x0E or phase_byte == 0x01 then
		return 5;
	end
	return 0;
end

local function MJ_get_arrow_image(current, new)
	if new.row > current.row then
		if new.col > current.col then
			return image_directory_root.."up_right.png";
		elseif new.col == current.col then
			return image_directory_root.."up.png";
		elseif new.col < current.col then
			return image_directory_root.."up_left.png";
		end
	elseif new.row == current.row then
		if new.col > current.col then
			return image_directory_root.."right.png";
		elseif new.col < current.col then
			return image_directory_root.."left.png";
		end
	elseif new.row < current.row then
		if new.col > current.col then
			return image_directory_root.."down_right.png";
		elseif new.col == current.col then
			return image_directory_root.."down.png";
		elseif new.col < current.col then
			return image_directory_root.."down_left.png";
		end
	end
	return image_directory_root.."question-mark.png";
end

local function MJ_parse_position(position)
	return {
		["active"] = MJ_get_switch_active_mask(position),
		["col"] = MJ_get_col_mask(position),
		["row"] = MJ_get_row_mask(position),
	};
end

function Game.drawMJMinimap()
	-- Only draw minimap if the player is in the Mad Jack fight
	if version ~= 4 and map_value == 154 then
		local MJ_state = dereferencePointer(Game.Memory.boss_pointer[version]);
		if not isRDRAM(MJ_state) then -- MJ object not found
			return;
		end

		local cur_pos = MJ_parse_position(mainmemory.readbyte(MJ_state + MJ_offsets["current_position"]));
		local next_pos = MJ_parse_position(mainmemory.readbyte(MJ_state + MJ_offsets["next_position"]));

		local white_pos = MJ_parse_position(mainmemory.readbyte(MJ_state + MJ_offsets["white_switch_position"]));
		local blue_pos = MJ_parse_position(mainmemory.readbyte(MJ_state + MJ_offsets["blue_switch_position"]));

		local switches_active = white_pos.active or blue_pos.active;

		local x, y, color;

		gui.clearGraphics();

		-- Calculate where the kong is on the MJ Board
		local colseg = position_to_rowcol(Game.getZPosition());
		local rowseg = position_to_rowcol(Game.getXPosition());

		local col = math.floor(colseg / 2);
		local row = math.floor(rowseg / 2);

		local kongPosition = {
			["col"] = col, ["row"] = row,
			["col_seg"] = colseg, ["row_seg"] = rowseg
		};

		for row = 0, 3 do
			for	col = 0, 3 do
				x = MJ_minimap_x_offset + col * MJ_minimap_width;
				y = MJ_minimap_y_offset + (3 - row) * MJ_minimap_height;

				color = MJ_colors.blue;
				if MJ_get_color(col, row) == 'white' then
					color = MJ_colors.white;
				end

				if switches_active then
					if white_pos.row == row and white_pos.col == col and MJ_get_color(cur_pos.col, cur_pos.row) == 'white' then
						color = MJ_colors.white_switch;
					elseif blue_pos.row == row and blue_pos.col == col and MJ_get_color(cur_pos.col, cur_pos.row) == 'blue' then
						color = MJ_colors.blue_switch;
					end
				end

				gui.drawRectangle(x, y, MJ_minimap_width, MJ_minimap_height, 0, color);

				if switches_active then
					if (white_pos.row == row and white_pos.col == col) or (blue_pos.row == row and blue_pos.col == col) then
						gui.drawImage(image_directory_root.."switch.png", x, y, MJ_minimap_width, MJ_minimap_height);
						--gui.drawText(x, y, "S");
					end
				end

				if cur_pos.row == row and cur_pos.col == col then
					gui.drawImage(image_directory_root.."jack_icon.png", x, y, MJ_minimap_width, MJ_minimap_height);
					--gui.drawText(x, y, "J")
				elseif next_pos.row == row and next_pos.col == col then
					gui.drawImage(MJ_get_arrow_image(cur_pos, next_pos), x, y, MJ_minimap_width, MJ_minimap_height);
					--gui.drawText(x, y, "N");
				end

				if kongPosition.row == row and kongPosition.col == col then
					gui.drawImage(image_directory_root.."TinyFaceEdited.png", x, y, MJ_minimap_width, MJ_minimap_height);
					--gui.drawText(x, y, "K");
				end
			end
		end

		-- Text info
		local phase_byte = mainmemory.readbyte(MJ_state + MJ_offsets["action_type"]);
		local actions_remaining = mainmemory.readbyte(MJ_state + MJ_offsets["actions_remaining"]);
		local time_until_next_action = mainmemory.readbyte(MJ_state + MJ_offsets["ticks_until_next_action"]);

		local phase = MJ_get_phase(phase_byte);
		local action_type = MJ_get_action_type(phase_byte);

		gui.drawText(MJ_minimap_text_x, MJ_minimap_actions_remaining_y, actions_remaining.." "..action_type.."s remaining");

		if action_type ~= "Jump" then
			gui.drawText(MJ_minimap_text_x, MJ_minimap_phase_number_y, "Phase "..phase.." (switch)");
			gui.drawText(MJ_minimap_text_x, MJ_time_until_next_action_y, time_until_next_action.." ticks until next "..action_type);
		else
			gui.drawText(MJ_minimap_text_x, MJ_minimap_phase_number_y, "Phase "..phase);
		end
	end
end

------------------------------------
-- Never Slip                     --
-- Written by Isotarge, 2014-2016 --
------------------------------------

function Game.neverSlip() -- TODO: Set movement state properly
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		mainmemory.writebyte(playerObject + obj_model1.player.slope_timer, 0); -- Patch the slope timer
	end
end

-----------------------
-- Bone Displacement --
-----------------------

local bone_displacement_fix = false;

local function fixBoneDisplacement()
	bone_displacement_fix = true;
end

local function breakBoneDisplacement()
	bone_displacement_fix = false;
end

event.onloadstate(breakBoneDisplacement, "ScriptHawk - Break bone displacement");

local function applyBoneDisplacementFix()
	if bone_displacement_fix and version ~= 4 then -- TODO: Kiosk
		-- Old fix basically crashes sound thread, seems to work well but... no sound.
		mainmemory.write_u32_be(Game.Memory.bone_displacement_pointer[version], 0);
	end
end

---------------------------------
-- Bone Displacement Detection --
---------------------------------

print_every_frame = false;
print_threshold = 1;

local safeBoneNumbers = {};

local function setNumberOfBones(modelBasePointer)
	if isRDRAM(modelBasePointer) then
		if safeBoneNumbers[modelBasePointer] == nil then
			safeBoneNumbers[modelBasePointer] = mainmemory.readbyte(modelBasePointer + obj_model1.model.num_bones);
		end

		local currentNumBones = mainmemory.readbyte(modelBasePointer + obj_model1.model.num_bones);
		local newNumBones;

		if joypad.getimmediate()["P1 L"] then
			newNumBones = math.max(currentNumBones - 1, 1);
		else
			newNumBones = math.min(currentNumBones + 1, safeBoneNumbers[modelBasePointer]);
		end

		if newNumBones ~= currentNumBones then
			mainmemory.writebyte(modelBasePointer + obj_model1.model.num_bones, newNumBones);
		end
	end
end

local function getBoneInfo(baseAddress)
	local boneInfo = {};
	boneInfo["positionX"] = mainmemory.read_s16_be(baseAddress + bone.position_x);
	boneInfo["positionY"] = mainmemory.read_s16_be(baseAddress + bone.position_y);
	boneInfo["positionZ"] = mainmemory.read_s16_be(baseAddress + bone.position_z);
	boneInfo["scaleX"] = mainmemory.read_u16_be(baseAddress + bone.scale_x);
	boneInfo["scaleY"] = mainmemory.read_u16_be(baseAddress + bone.scale_y);
	boneInfo["scaleZ"] = mainmemory.read_u16_be(baseAddress + bone.scale_z);
	return boneInfo;
end

local function outputBones(boneArrayBase, numBones)
	dprint("Bone,X,Y,Z,ScaleX,ScaleY,ScaleZ,");
	local boneInfoTables = {};
	for i = 0, numBones - 1 do
		local boneInfo = getBoneInfo(boneArrayBase + i * bone_size);
		table.insert(boneInfoTables, boneInfo);
		dprint(i..","..boneInfo["positionX"]..","..boneInfo["positionY"]..","..boneInfo["positionZ"]..","..boneInfo["scaleX"]..","..boneInfo["scaleY"]..","..boneInfo["scaleZ"]..",");
	end
	print_deferred();
	return boneInfoTables;
end

local function calculateCompleteBones(boneArrayBase, numberOfBones)
	local numberOfCompletedBones = numberOfBones;
	local statisticallySignificantX = {};
	local statisticallySignificantZ = {};
	for currentBone = 0, numberOfBones - 1 do
		-- Get all known information about the current bone
		local boneInfo = getBoneInfo(boneArrayBase + currentBone * bone_size);
		local boneDisplaced = false;

		-- Detect basic zeroing, the bone displacement method method currently detailed in the document
		if boneInfo["positionX"] == 0 and boneInfo["positionY"] == 0 and boneInfo["positionZ"] == 0 then
			if boneInfo["scaleX"] == 0 and boneInfo["scaleY"] == 0 and boneInfo["scaleZ"] == 0 then
				boneDisplaced = true;
			end
		end

		-- Detect position being set to -32768
		if boneInfo["positionX"] == -32768 and boneInfo["positionY"] == -32768 and boneInfo["positionZ"] == -32768 then
			boneDisplaced = true;
		end

		if boneDisplaced then
			numberOfCompletedBones = numberOfCompletedBones - 1;
		else
			table.insert(statisticallySignificantX, boneInfo["positionX"]);
			table.insert(statisticallySignificantZ, boneInfo["positionZ"]);
		end
	end

	-- Stats based check for type 3 "translation"
	local meanX = Stats.mean(statisticallySignificantX);
	local stdX = Stats.standardDeviation(statisticallySignificantX) * 2.5;

	local meanZ = Stats.mean(statisticallySignificantZ);
	local stdZ = Stats.standardDeviation(statisticallySignificantZ) * 2.5;

	-- Check for outliers
	for currentBone = 1, #statisticallySignificantX do
		local diffX = math.abs(meanX - statisticallySignificantX[currentBone]);
		local diffZ = math.abs(meanZ - statisticallySignificantZ[currentBone]);
		if diffX > stdX and diffZ > stdZ then
			numberOfCompletedBones = numberOfCompletedBones - 1;
		end
	end

	return math.max(0, numberOfCompletedBones);
end

local function detectDisplacement(objectPointer)
	local currentModelBase = dereferencePointer(objectPointer + obj_model1.model_pointer);
	local currentBoneArrayBase = dereferencePointer(objectPointer + obj_model1.current_bone_array_pointer);

	if isRDRAM(currentModelBase) and isRDRAM(currentBoneArrayBase) then
		-- Stupid stuff
		setNumberOfBones(currentModelBase);

		-- Calculate how many bones were correctly processed this frame
		local numberOfBones = mainmemory.readbyte(currentModelBase + obj_model1.model.num_bones);
		local completedBones = calculateCompleteBones(currentBoneArrayBase, numberOfBones);

		local completedBoneRatio = completedBones / numberOfBones;

		if completedBoneRatio < print_threshold or print_every_frame then
			print(toHexString(objectPointer).." ("..getActorName(objectPointer)..") updated "..completedBones.."/"..numberOfBones.." bones.");
			outputBones(currentBoneArrayBase, numberOfBones);
		end
	end
end

local function displacementDetection()
	for i = 0, getObjectModel1Count() do
		local objectPointer = dereferencePointer(Game.Memory.pointer_list[version] + (i * 4));
		if isRDRAM(objectPointer) then
			detectDisplacement(objectPointer);
		end
	end
end

-----------------------
-- Lag configuration --
-----------------------

local lag_factor = 1;

local function increase_lag_factor()
	local max_lag_factor = 20;
	lag_factor = math.min(max_lag_factor, lag_factor + 1);
end

local function decrease_lag_factor()
	local min_lag_factor = -30;
	lag_factor = math.max(min_lag_factor, lag_factor - 1);
end

local function fixLag()
	if version ~= 4 then -- TODO: Kiosk
		local frames_real_value = mainmemory.read_u32_be(Game.Memory.frames_real[version]);
		mainmemory.write_u32_be(Game.Memory.frames_lag[version], frames_real_value - lag_factor);
	end
end

local moon_mode = "None";
local function toggle_moonmode()
	if moon_mode == 'None' then
		moon_mode = 'Kick';
	elseif moon_mode == 'Kick' then
		moon_mode = 'All';
	elseif moon_mode == 'All' then
		moon_mode = 'None';
	end
end

function everythingIsKong()
	local playerObject = Game.getPlayerObject();
	if not isRDRAM(playerObject) then
		return false;
	end

	local kongSharedModel = dereferencePointer(playerObject + obj_model1.model_pointer);
	if not isRDRAM(kongSharedModel) then
		print("This ain't gonna work...");
		return false;
	end

	local kongNumBones = mainmemory.readbyte(kongSharedModel + obj_model1.model.num_bones);
	local cameraObject = dereferencePointer(Game.Memory.camera_pointer[version]);

	for actorListIndex = 0, getObjectModel1Count() do
		local pointer = dereferencePointer(Game.Memory.pointer_list[version] + (actorListIndex * 4));
		if isRDRAM(pointer) and (pointer ~= cameraObject) then
			local modelPointer = dereferencePointer(pointer + obj_model1.model_pointer);
			if isRDRAM(modelPointer) then
				local numBones = mainmemory.readbyte(modelPointer + obj_model1.model.num_bones);
				if numBones >= kongNumBones then
					mainmemory.write_u32_be(pointer + obj_model1.model_pointer, kongSharedModel + RDRAMBase);
					print("Wrote: "..toHexString(pointer).." Bones: "..numBones.." Type: "..getActorName(pointer));
				end
			end
		end
	end
	return true;
end

function Game.setScale(value)
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		for i = 1, #obj_model1.player.scale do
			mainmemory.writefloat(playerObject + obj_model1.player.scale[i], value, true);
		end
	end
end

function Game.randomEffect()
	-- Randomly manipulate the effect byte
	local randomEffect = math.random(0, 0xFFFF);
	mainmemory.write_u16_be(Game.getPlayerObject() + obj_model1.player.effect_byte, randomEffect);

	-- Randomly resize the kong
	local scaleValue = 0.01 + math.random() * 0.49;
	Game.setScale(scaleValue);

	print("Activated effect: "..bizstring.binary(randomEffect).." with scale "..scaleValue);
end

----------------
-- Paper Mode --
----------------

function Game.paperMode()
	local paper_thickness = 0.015;
	local actorListIndex = 0;
	local cameraObject = dereferencePointer(Game.Memory.camera_pointer[version]);

	for actorListIndex = 0, getObjectModel1Count() do
		local pointer = dereferencePointer(Game.Memory.pointer_list[version] + (actorListIndex * 4));

		if isRDRAM(pointer) and pointer ~= cameraObject then
			local objectRenderingParameters = dereferencePointer(pointer + obj_model1.rendering_parameters_pointer);
			if isRDRAM(objectRenderingParameters) then
				mainmemory.writefloat(objectRenderingParameters + obj_model1.rendering_parameters.scale_z, paper_thickness, true);
			end
		end
	end
end

---------------
-- BRB Stuff --
---------------

local japan_charset = {
--   0    1    2    3    4    5    6    7    8    9
	"\0", "\0", "$", "(", ")", "\0", "%", "「", "」", "`", -- 0
	"\0", "<", ">", "&", "~", " ", "0", "1", "2", "3", -- 1
	"4", "5", "6", "7", "8", "9", "A", "B", "C", "D", -- 2
	"E", "F", "G", "H", "I", "J", "K", "\0", "M", "N", -- 3
	"O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", -- 4
	"Y", "Z", "!", "\"", "#", "'", "*", "+", ",", "-", -- 5
	".", "/", ":", "=", "?", "@", "。", "゛", " ", "ァ", -- 6
	"ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ", "ヲ", "ン", -- 7
	"ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", -- 8
	"サ", "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト", -- 9
	"ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", -- 10
	"マ", "ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", -- 11
	"ル", "レ", "ロ", "ワ", "ガ", "ギ", "グ", "ゲ", "ゴ", "ザ", -- 12
	"ジ", "ズ", "ゼ", "ゾ", "ダ", "ヂ", "ヅ", "デ", "ド", "バ", -- 13
	"ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ", "a", -- 14
	"b", "c", "d", "e", "f", "g", "h", "i", "j", "k", -- 15
	"l", "m", "n", "o", "p", "q", "r", "s", "t", "u", -- 16
	"v", "w", "x", "y", "z", "ぁ", "ぃ", "ぅ", "ぇ", "ぉ", -- 17
	"っ", "ゃ", "ゅ", "ょ", "を", "ん", "あ", "い", "う", "え", -- 18
	"お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", -- 19
	"そ", "た", "ち", "つ", "て", "と", "な", "に", "ぬ", "ね", -- 20
	"の", "は", "ひ", "ふ", "へ", "ほ", "ま", "み", "む", "め", -- 21
	"も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "わ", -- 22
	"が", "ぎ", "ぐ", "げ", "ご", "ざ", "じ", "ず", "ぜ", "ぞ", -- 23
	"だ", "ぢ", "づ", "で", "ど", "ば", "び", "ぶ", "べ", "ぼ", -- 24
	"ぱ", "ぴ", "ぷ", "ぺ", "ぽ", "ヴ" -- 25
};

function Game.toJapaneseString(value)
	local length = string.len(value);
	local tempString = "";
	local char;
	local charFound = false;
	for i = 1, length do
		char = bizstring.substring(value, i - 1, 1); -- TODO: call string.sub() instead, how do params work?
		charFound = false;
		for j = 1, #japan_charset do
			if japan_charset[j] == char then
				tempString = tempString..string.char(j - 1);
				charFound = true;
				break;
			end
		end
		if charFound == false then
			dprint("String parse warning: Didn't find character for '"..char..'\'');
		end
	end
	print_deferred();
	return tempString;
end

brb_message = "BRB";
is_brb = false;

function brb(value)
	local message = value or "BRB";
	if version == 3 then -- Japan
		message = Game.toJapaneseString(message);
	else
		message = string.upper(message);
	end
	if version ~= 4 then -- TODO: Kiosk?
		brb_message = message;
		is_brb = true;
	else
		print("Not supported in this version.");
	end
end

function back()
	is_brb = false;
end

local function doBRB()
	if is_brb then
		mainmemory.writebyte(Game.Memory.security_byte[version], 0x01);
		local messageLength = math.min(string.len(brb_message), 79); -- 79 bytes appears to be the maximum length we can write here without crashing
		for i = 1, messageLength do
			mainmemory.writebyte(Game.Memory.security_message[version] + i - 1, string.byte(brb_message, i));
		end
		mainmemory.writebyte(Game.Memory.security_message[version] + messageLength, 0x00);
	end
end

-------------------
-- For papa cfox --
-------------------

function setText(pointer, message)
	local messageLength = math.min(string.len(message), 40); -- Maximum message length is 40
	for i = 1, messageLength do
		mainmemory.writebyte(pointer + i - 1, string.byte(message, i));
	end
	mainmemory.writebyte(pointer + messageLength, 0x00);
end

function setDKTV(message)
	local linkedListRoot = derferencePointer(Game.Memory.linked_list_pointer[version]);
	if not isRDRAM(linkedListRoot) then
		return; -- Something went hilariously wrong here
	end

	local linkedListSize = mainmemory.read_u32_be(Game.Memory.linked_list_pointer[version] + 4);
	local totalSize = 0;
	local currentPointer = linkedListRoot;
	while totalSize < linkedListSize do
		local currentObjectSize = mainmemory.read_u32_be(currentPointer + 4);
		currentPointer = currentPointer + 0x10;
		if currentObjectSize == 0x40 then
			if mainmemory.read_u32_be(currentPointer) == 0x444B2054 then -- TODO: Better method of detection
				setText(currentPointer, message);
			end
		end
		currentPointer = currentPointer + currentObjectSize;
		totalSize = currentPointer - linkedListRoot;
	end
end

--------------------------
-- Free Trade Agreement --
--------------------------

local BalloonStates = {
	[DK] = 114,
	[Diddy] = 91,
	[Lanky] = 113,
	[Tiny] = 112,
	[Chunky] = 111,
};

function isBalloon(actorType)
	return array_contains(BalloonStates, actorType)
end

local KasplatStates = { -- Not actually used by the check function for speed reasons, really just here for documentation
	[DK] = 241,
	[Diddy] = 242,
	[Lanky] = 243,
	[Tiny] = 244,
	[Chunky] = 245,
};

function isKasplat(actorType)
	return actorType >= 241 and actorType <= 245;
end

local BulletChecks = {
	[DK] = 0x0030,
	[Diddy] = 0x0024,
	[Lanky] = 0x002A,
	[Tiny] = 0x002B,
	[Chunky] = 0x0026,
	[Krusha] = 0x00AB,
};

function isBulletCheck(value)
	return array_contains(BulletChecks, value);
end

local GBStates = {
	[DK] = 0x28,
	[Diddy] = 0x22,
	[Lanky] = 0x30,
	[Tiny] = 0x24,
	[Chunky] = 0x21,
};

function isGB(collectableState)
	return array_contains(GBStates, collectableState);
end

local SimSlamChecks = { -- Not actually used by the check function for speed reasons, really just here for documentation
	[DK] = 0x0002,
	[Diddy] = 0x0003,
	[Lanky] = 0x0004,
	[Tiny] = 0x0005,
	[Chunky] = 0x0006,
	[Krusha] = 0x0007,
};

function isKong(actorType)
	return actorType >= 2 and actorType <= 6;
end

function freeTradeObjectModel1(currentKong)
	if currentKong >= DK and currentKong <= Chunky then
		for object_no = 0, getObjectModel1Count() do
			local pointer = dereferencePointer(Game.Memory.pointer_list[version] + (object_no * 4));
			if isRDRAM(pointer) then
				local actorType = mainmemory.read_u32_be(pointer + obj_model1.actor_type);
				if isKasplat(actorType) then
					mainmemory.write_u32_be(pointer + obj_model1.actor_type, KasplatStates[currentKong]); -- Fix which blueprint the Kasplat drops
				end
				if isBalloon(actorType) then
					mainmemory.write_u32_be(pointer + obj_model1.actor_type, BalloonStates[currentKong]); -- Fix balloon color
				end
			end
		end
	end
end

local collisionTypes = {
	[0x000A] = "CB Single (0x0A)",
	[0x000D] = "CB Single (0x0D)",
	[0x0011] = "Homing Ammo Crate",
	[0x0016] = "CB Single (0x16)",
	[0x001C] = "Coin (0x1C)",
	[0x001D] = "Coin (0x1D)",
	[0x001E] = "CB Single (0x1E)",
	[0x001F] = "CB Single (0x1F)",
	[0x0023] = "Coin (0x23)",
	[0x0024] = "Coin (0x24)",
	[0x0027] = "Coin (0x27)",
	[0x002B] = "CB Bunch (0x2B)",
	[0x0056] = "Orange",
	[0x0074] = "GB",
	[0x008E] = "Crystal Coconut",
	[0x008F] = "Ammo Crate",
	[0x0098] = "Film",
	[0x0205] = "CB Bunch (0x205)",
	[0x0206] = "CB Bunch (0x206)",
	[0x0207] = "CB Bunch (0x207)",
	[0x0208] = "CB Bunch (0x208)",
	[0x0288] = "Rareware GB (0x288)",
};

local function isKnownCollisionType(collisionType)
	return collisionTypes[collisionType] ~= nil;
end

function fixSingleCollision(objectBase)
	local collisionType = mainmemory.read_u16_be(objectBase + 2);
	local collisionValue = mainmemory.read_u16_be(objectBase + 4);
	if isKnownCollisionType(collisionType) and isKong(collisionValue) then
		mainmemory.write_u16_be(objectBase + 4, 0); -- Set the collision to accept any Kong
	end
end

function freeTradeCollisionList()
	local collisionLinkedListPointer = dereferencePointer(Game.Memory.obj_model2_collision_linked_list_pointer[version]);
	if isRDRAM(collisionLinkedListPointer) then
		local collisionListObjectSize = mainmemory.read_u32_be(collisionLinkedListPointer + object_size);
		for i = 0, collisionListObjectSize, 4 do
			local object = dereferencePointer(collisionLinkedListPointer + i);
			local safety = nil;
			while isRDRAM(object) do
				fixSingleCollision(object);
				safety = dereferencePointer(object + 0x18);
				if safety == object then -- Prevent infinite loops
					break;
				end
				object = safety;
			end
		end
	end
end

function dumpCollisionTypes(kongFilter)
	local kongCounts = {};
	local collisionLinkedListPointer = dereferencePointer(Game.Memory.obj_model2_collision_linked_list_pointer[version]);
	if isRDRAM(collisionLinkedListPointer) then
		local collisionListObjectSize = mainmemory.read_u32_be(collisionLinkedListPointer + object_size);
		for i = 0, collisionListObjectSize, 4 do
			local object = dereferencePointer(collisionLinkedListPointer + i);
			while isRDRAM(object) do
				local kong = mainmemory.read_u16_be(object + 0x04);
				if isKong(kong) and (kongFilter == nil or kong == kongFilter) then
					local collisionType = mainmemory.read_u16_be(object + 0x02);
					if collisionTypes[collisionType] ~= nil then
						collisionType = collisionTypes[collisionType];
					else
						collisionType = toHexString(collisionType, 4);
					end
					if kongCounts[kong] == nil then
						kongCounts[kong] = 1;
					else
						kongCounts[kong] = kongCounts[kong] + 1;
					end
					dprint(toHexString(object)..": "..collisionType..", Kong: "..toHexString(kong));
				end
				object = dereferencePointer(object + 0x18);
			end
		end
		for k, v in pairs(kongCounts) do
			dprint("Kong "..toHexString(k).." Count: "..v);
		end
		print_deferred();
	end
end

function replaceCollisionType(target, desired)
	local collisionLinkedListPointer = dereferencePointer(Game.Memory.obj_model2_collision_linked_list_pointer[version]);
	if isRDRAM(collisionLinkedListPointer) then
		local collisionListObjectSize = mainmemory.read_u32_be(collisionLinkedListPointer + object_size);
		for i = 0, collisionListObjectSize, 4 do
			local object = dereferencePointer(collisionLinkedListPointer + i);
			while isRDRAM(object) do
				local collisionType = mainmemory.read_u16_be(object + 0x02);
				if collisionType == target then
					mainmemory.write_u16_be(object + 0x02, desired);
				end
				object = dereferencePointer(object + 0x18);
			end
		end
	end
end

function ohWrongnanaDebugOut(objName, objBase, scriptBase, scriptOffset)
	local preceedingCommand = mainmemory.read_u16_be(scriptBase + scriptOffset - 2);
	print("patched "..objName.." at "..toHexString(objBase).." -> "..toHexString(scriptBase).." + "..toHexString(scriptOffset).." preceeding command "..toHexString(preceedingCommand));
end

function ohWrongnana(verbose)
	if version == 4 then -- Anything but kiosk
		return;
	end

	if mainmemory.read_u32_be(Game.Memory.obj_model2_timer[version]) == 0 then -- Check model 2 timer to make sure we're not patching through loading zones
		return;
	end

	--if emu.framecount() % 100 ~= 0 then -- Only run this once every 100 frames
	--	return;
	--end

	local currentKong = mainmemory.readbyte(Game.Memory.character[version]);

	local objModel2Array = dereferencePointer(Game.Memory.obj_model2_array_pointer[version]);
	if isRDRAM(objModel2Array) and currentKong >= DK and currentKong <= Chunky then
		local numSlots = mainmemory.read_u32_be(Game.Memory.obj_model2_array_count[version]);
		local scriptName, slotBase, currentValue, activationScript;
		-- Fill and sort pointer list
		for i = 0, numSlots - 1 do
			slotBase = objModel2Array + i * obj_model2_slot_size;
			currentValue = mainmemory.readbyte(slotBase + obj_model2.collectable_state);
			if currentKong ~= Krusha and isGB(currentValue) then
				mainmemory.writebyte(slotBase + obj_model2.collectable_state, GBStates[currentKong]);
			end
			-- Get activation script
			activationScript = dereferencePointer(slotBase + 0x7C);
			if isRDRAM(activationScript) then
				scriptName = getScriptName(slotBase);
				if scriptName == "gunswitches" then
					-- Get part 2
					activationScript = dereferencePointer(activationScript + 0xA0);
					while isRDRAM(activationScript) do
						-- Check for the bullet magic and patch if needed
						if isBulletCheck(mainmemory.read_u16_be(activationScript + 0x0C)) then
							if verbose then
								ohWrongnanaDebugOut(scriptName, slotBase, activationScript, 0x0C);
							end
							mainmemory.write_u16_be(activationScript + 0x0C, BulletChecks[currentKong]);
						end
						-- Get next script chunk
						activationScript = dereferencePointer(activationScript + 0x4C);
					end
				end
				if scriptName == "buttons" then
					-- Get part 2
					activationScript = dereferencePointer(activationScript + 0xA0);
					while isRDRAM(activationScript) do
						-- New method, slower but catches weird switches
						--for j = 0x04, 0x48, 4 do
						--	if mainmemory.read_u16_be(activationScript + j) == 0x0019 then
						--		if isKong(mainmemory.read_u16_be(activationScript + j + 2)) then
						--			mainmemory.write_u16_be(activationScript + j + 2, SimSlamChecks[currentKong]);
						--		end
						--	end
						--end

						-- Old method
						-- Check for the simslam magic and patch if needed
						if isKong(mainmemory.read_u16_be(activationScript + 0x0C)) then
							if verbose then
								ohWrongnanaDebugOut(scriptName, slotBase, activationScript, 0x0C);
							end
							mainmemory.write_u16_be(activationScript + 0x0C, SimSlamChecks[currentKong]);
						end
						if isKong(mainmemory.read_u16_be(activationScript + 0x1C)) then
							if verbose then
								ohWrongnanaDebugOut(scriptName, slotBase, activationScript, 0x1C);
							end
							mainmemory.write_u16_be(activationScript + 0x1C, SimSlamChecks[currentKong]);
						end
						if isKong(mainmemory.read_u16_be(activationScript + 0x24)) then
							if verbose then
								ohWrongnanaDebugOut(scriptName, slotBase, activationScript, 0x24);
							end
							mainmemory.write_u16_be(activationScript + 0x24, SimSlamChecks[currentKong]);
						end

						-- Get next script chunk
						activationScript = dereferencePointer(activationScript + 0x4C);
					end
				end
			end
		end

		freeTradeObjectModel1(currentKong);
		freeTradeCollisionList();
	end
end

----------------------
-- Framebuffer Jank --
----------------------

function fillFB()
	local image_filename = forms.openfile(nil, nil, "PNG Images (*.png)|*.png");
	if not fileExists(image_filename) then
		print("No image selected. Exiting.");
		return;
	end

	local framebuffer_width = 320; -- Oddly enough it's the same size on PAL
	local framebuffer_height = 240; -- Oddly enough it's the same size on PAL
	local frameBufferLocation = dereferencePointer(Game.Memory.framebuffer_pointer[version]);
	if isRDRAM(frameBufferLocation) then
		replaceTextureRGBA5551(image_filename, frameBufferLocation, framebuffer_width, framebuffer_height);
		replaceTextureRGBA5551(image_filename, frameBufferLocation + (framebuffer_width * framebuffer_height * 2), framebuffer_width, framebuffer_height);
	end
end

-----------------
-- Grab Script --
-----------------

hide_non_scripted = false;
rat_enabled = false;

local function incrementObjectIndex()
	object_index = object_index + 1;
	if object_index > #object_pointers then
		object_index = 1;
	end
end

local function decrementObjectIndex()
	object_index = object_index - 1;
	if object_index <= 0 then
		object_index = #object_pointers;
	end
end

local function grabObject(pointer)
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		mainmemory.write_u32_be(playerObject + obj_model1.player.grab_pointer, pointer + RDRAMBase);
		mainmemory.write_u32_be(playerObject + obj_model1.player.grab_pointer + 4, pointer + RDRAMBase);
	end
end

local function grabSelectedObject()
	if stringContains(grab_script_mode, "Model 1") then
		grabObject(object_pointers[object_index]);
	end
end

local function focusObject(pointer) -- TODO: There's more pointers to set here, mainly vehicle stuff
	local cameraObject = dereferencePointer(Game.Memory["camera_pointer"][version]);
	if isRDRAM(cameraObject) and isRDRAM(pointer) then
		mainmemory.write_u32_be(cameraObject + obj_model1.camera.focused_actor_pointer, pointer + RDRAMBase);
	end
end

local function focusSelectedObject()
	if stringContains(grab_script_mode, "Model 1") then
		focusObject(object_pointers[object_index]);
	end
end

local function zipToSelectedObject()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local desiredX, desiredY, desiredZ;
		-- Get selected object X,Y,Z position
		if stringContains(grab_script_mode, "Model 1") then
			local selectedActorBase = object_pointers[object_index];
			if isRDRAM(selectedActorBase) then
				desiredX = mainmemory.readfloat(selectedActorBase + obj_model1.x_pos, true);
				desiredY = mainmemory.readfloat(selectedActorBase + obj_model1.y_pos, true);
				desiredZ = mainmemory.readfloat(selectedActorBase + obj_model1.z_pos, true);
			end
		elseif stringContains(grab_script_mode, "Model 2") then
			local selectedObjectBase = object_pointers[object_index];
			if isRDRAM(selectedObjectBase) then
				desiredX = mainmemory.readfloat(selectedObjectBase + obj_model2.x_pos, true);
				desiredY = mainmemory.readfloat(selectedObjectBase + obj_model2.y_pos, true);
				desiredZ = mainmemory.readfloat(selectedObjectBase + obj_model2.z_pos, true);
			end
		elseif stringContains(grab_script_mode, "Loading Zones") then
			local selectedLoadingZoneBase = object_pointers[object_index];
			if isRDRAM(selectedLoadingZoneBase) then
				desiredX = mainmemory.read_s16_be(selectedLoadingZoneBase + loading_zone_fields.x_position);
				desiredY = mainmemory.read_s16_be(selectedLoadingZoneBase + loading_zone_fields.y_position);
				desiredZ = mainmemory.read_s16_be(selectedLoadingZoneBase + loading_zone_fields.z_position);
			end
		end

		-- Update player position
		if type(desiredX) == "number" and type(desiredY) == "number" and type(desiredZ) == "number" then
			mainmemory.writefloat(playerObject + obj_model1.x_pos, desiredX, true);
			mainmemory.writefloat(playerObject + obj_model1.y_pos, desiredY, true);
			mainmemory.writefloat(playerObject + obj_model1.z_pos, desiredZ, true);

			-- Allow movement when locked to pads etc
			mainmemory.writebyte(playerObject + obj_model1.locked_to_pad, 0x00);
			mainmemory.write_u32_be(playerObject + obj_model1.lock_method_1_pointer, 0x00);
		end
	end
end

ScriptHawk.bindKeyRealtime("N", decrementObjectIndex, true);
ScriptHawk.bindKeyRealtime("M", incrementObjectIndex, true);
ScriptHawk.bindKeyRealtime("Z", zipToSelectedObject, true);
ScriptHawk.bindKeyRealtime("V", grabSelectedObject, true);
ScriptHawk.bindKeyRealtime("B", focusSelectedObject, true);
ScriptHawk.bindKeyRealtime("C", switch_grab_script_mode, true);

------------------------------
-- Grab Script              --
-- Object Model 1 Functions --
------------------------------

local function isValidModel1Object(pointer, playerObject, cameraObject)
	local modelPointer = dereferencePointer(pointer + obj_model1.model_pointer);

	if encircle_enabled then
		return isRDRAM(modelPointer) and pointer ~= playerObject;
	end

	return true;
end

local function populateObjectModel1Pointers()
	object_pointers = {};
	local playerObject = Game.getPlayerObject();
	local cameraObject = dereferencePointer(Game.Memory["camera_pointer"][version]);
	if isRDRAM(playerObject) and isRDRAM(cameraObject) then
		for object_no = 0, getObjectModel1Count() do
			local pointer = dereferencePointer(Game.Memory["pointer_list"][version] + (object_no * 4));
			if isRDRAM(pointer) and isValidModel1Object(pointer, playerObject, cameraObject) then
				table.insert(object_pointers, pointer);
			end
		end

		-- Clamp index
		object_index = math.min(object_index, math.max(1, #object_pointers));
	end
end

local function encirclePlayerObjectModel1()
	if encircle_enabled and stringContains(grab_script_mode, "Model 1") then
		local playerObject = Game.getPlayerObject();
		if isRDRAM(playerObject) then
			local x, z;
			local xPos = mainmemory.readfloat(playerObject + obj_model1.x_pos, true);
			local yPos = mainmemory.readfloat(playerObject + obj_model1.y_pos, true);
			local zPos = mainmemory.readfloat(playerObject + obj_model1.z_pos, true);

			for i = 1, #object_pointers do
				x = xPos + math.cos(math.pi * 2 * i / #object_pointers) * radius;
				z = zPos + math.sin(math.pi * 2 * i / #object_pointers) * radius;

				mainmemory.writefloat(object_pointers[i] + obj_model1.x_pos, x, true);
				mainmemory.writefloat(object_pointers[i] + obj_model1.y_pos, yPos, true);
				mainmemory.writefloat(object_pointers[i] + obj_model1.z_pos, z, true);
			end
		end
	end
end

-----------------------
-- Kremling Kosh Bot --
-----------------------

local kremling_kosh_joypad_angles = {
	[0] = {["X Axis"] = 0,    ["Y Axis"] = 0},
	[1] = {["X Axis"] = -128, ["Y Axis"] = 0},
	[2] = {["X Axis"] = -128, ["Y Axis"] = -128},
	[3] = {["X Axis"] = 0,    ["Y Axis"] = -128},
	[4] = {["X Axis"] = 127,  ["Y Axis"] = -128},
	[5] = {["X Axis"] = 127,  ["Y Axis"] = 0},
	[6] = {["X Axis"] = 127,  ["Y Axis"] = 127},
	[7] = {["X Axis"] = 0,    ["Y Axis"] = 127},
	[8] = {["X Axis"] = -128, ["Y Axis"] = 127},
};

function getKoshController()
	for object_no = 0, getObjectModel1Count() do
		local pointer = dereferencePointer(Game.Memory["pointer_list"][version] + (object_no * 4));
		if isRDRAM(pointer) and getActorName(pointer) == "Kremling Kosh Controller" then
			return pointer;
		end
	end
end

function countMelonProjectiles()
	local melonCount = 0;
	for object_no = 0, getObjectModel1Count() do
		local pointer = dereferencePointer(Game.Memory["pointer_list"][version] + (object_no * 4));
		if isRDRAM(pointer) and getActorName(pointer) == "Melon (Projectile)" then
			melonCount = melonCount + 1;
		end
	end
	return melonCount;
end

function getSlotPointer(koshController, slotIndex)
	return dereferencePointer(koshController + obj_model1.kosh_kontroller.slot_pointer_base + (slotIndex - 1) * 4);
end

function getCurrentSlot()
	local koshController = getKoshController();
	if type(koshController) ~= "nil" then
		return mainmemory.readbyte(koshController + obj_model1.kosh_kontroller.slot_location);
	end
end

local shots_fired = {
	0, 0, 0, 0, 0, 0, 0, 0
};

function getDesiredSlot()
	local koshController = getKoshController();
	if type(koshController) ~= "nil" then
		local currentSlot = mainmemory.readbyte(koshController + obj_model1.kosh_kontroller.slot_location);
		local melonsRemaining = mainmemory.readbyte(koshController + obj_model1.kosh_kontroller.melons_remaining);
		if melonsRemaining == 0 then
			return 0;
		end

		-- Check for kremlings
		local slotIndex = 0;
		local desiredSlot = 0;
		for slotIndex = 1, 8 do
			local slotPointer = getSlotPointer(koshController, slotIndex);
			if isRDRAM(slotPointer) and slotPointer ~= shots_fired[slotIndex] then
				desiredSlot = slotIndex;
			end
			if slotPointer == 0 then
				shots_fired[slotIndex] = 0;
			end
		end

		if desiredSlot > 0 then
			return desiredSlot;
		end
	end
end

local previousFrameMelonCount = 0;
function koshBotLoop()
	local koshController = getKoshController();
	if koshController ~= nil then
		local currentSlot = getCurrentSlot();
		local desiredSlot = getDesiredSlot();
		if type(desiredSlot) ~= "nil" then
			joypad.setanalog(kremling_kosh_joypad_angles[desiredSlot], 1);
			--print("Moving to slot "..desiredSlot);
			if currentSlot == desiredSlot then
				joypad.set({["B"] = emu.framecount() % 5 == 0}, 1);
				--print("Firing!");
				if desiredSlot > 0 and countMelonProjectiles() > previousFrameMelonCount then
					shots_fired[desiredSlot] = getSlotPointer(koshController, desiredSlot);
				end
				previousFrameMelonCount = countMelonProjectiles();
			end
		else
			joypad.setanalog({["X Axis"] = false, ["Y Axis"] = false}, 1);
		end
	end
end

local function drawGrabScriptUI()
	if grab_script_mode == "Disabled" then
		return;
	end

	local gui_x = 32;
	local gui_y = 32;
	local row = 0;
	local height = 16;

	local green_highlight = 0xFF00FF00;
	local yellow_highlight = 0xFFFFFF00;

	gui.text(gui_x, gui_y + height * row, "Mode: "..grab_script_mode, nil, nil, 'bottomright');
	row = row + 1;

	local playerObject = Game.getPlayerObject();
	if not isRDRAM(playerObject) then
		return;
	end

	local cameraObject = dereferencePointer(Game.Memory["camera_pointer"][version]);
	if not isRDRAM(cameraObject) then
		return;
	end

	if stringContains(grab_script_mode, "Model 1") then
		populateObjectModel1Pointers();
		encirclePlayerObjectModel1();
	end

	if stringContains(grab_script_mode, "Model 2") then
		populateObjectModel2Pointers();
		encirclePlayerObjectModel2();
	end

	if stringContains(grab_script_mode, "Loading Zones") then
		populateLoadingZonePointers();
	end

	if rat_enabled then
		local renderingParams = dereferencePointer(playerObject + obj_model1.rendering_parameters_pointer);
		if isRDRAM(renderingParams) then
			if math.random() > 0.9 then
				local timerValue = math.random() * 50;
				mainmemory.writefloat(renderingParams + obj_model1.rendering_parameters.anim_timer1, timerValue, true);
				mainmemory.writefloat(renderingParams + obj_model1.rendering_parameters.anim_timer2, timerValue, true);
				mainmemory.writefloat(renderingParams + obj_model1.rendering_parameters.anim_timer3, timerValue, true);
				mainmemory.writefloat(renderingParams + obj_model1.rendering_parameters.anim_timer4, timerValue, true);
			end
		end
	end

	if stringContains(grab_script_mode, "Model 2") then
		gui.text(gui_x, gui_y + height * row, "Array Size: "..getObjectModel2ArraySize(), nil, nil, 'bottomright');
		row = row + 1;
	end

	gui.text(gui_x, gui_y + height * row, "Index: "..object_index.."/"..#object_pointers, nil, nil, 'bottomright');
	row = row + 1;

	if stringContains(grab_script_mode, "Model 1") then
		local focusedActor = dereferencePointer(cameraObject + obj_model1.camera.focused_actor_pointer);
		local grabbedActor = dereferencePointer(playerObject + obj_model1.player.grab_pointer);

		local focusedActorType = "Unknown";
		local grabbedActorType = "Unknown";

		if isRDRAM(focusedActor) then
			focusedActorType = getActorName(focusedActor);
		end

		if isRDRAM(grabbedActor) then
			grabbedActorType = getActorName(grabbedActor);
		end

		-- Display which object the camera is currently focusing on
		gui.text(gui_x, gui_y + height * row, "Focused Actor: "..toHexString(focusedActor, 6).." "..focusedActorType, nil, nil, 'bottomright');
		row = row + 1;

		-- Display which object is grabbed
		gui.text(gui_x, gui_y + height * row, "Grabbed Actor: "..toHexString(grabbedActor, 6).." "..grabbedActorType, nil, nil, 'bottomright');
		row = row + 1;
	end

	-- Clamp index to number of objects
	if #object_pointers > 0 and object_index > #object_pointers then
		object_index = #object_pointers;
	end

	if #object_pointers > 0 and object_index <= #object_pointers then
		if stringContains(grab_script_mode, "Examine") then
			local examine_data = {};
			if grab_script_mode == "Examine (Object Model 1)" then
				examine_data = getExamineDataModelOne(object_pointers[object_index]);
			elseif grab_script_mode == "Examine (Object Model 2)" then
				examine_data = getExamineDataModelTwo(object_pointers[object_index]);
			elseif grab_script_mode == "Examine (Loading Zones)" then
				examine_data = getExamineDataLoadingZone(object_pointers[object_index]);
			end

			for i = #examine_data, 1, -1 do
				if examine_data[i][1] ~= "Separator" then
					if type(examine_data[i][2]) == "number" then
						examine_data[i][2] = round(examine_data[i][2], precision);
					end
					gui.text(gui_x, gui_y + height * row, examine_data[i][1]..": "..examine_data[i][2], nil, nil, 'bottomright');
					row = row + 1;
				else
					row = row + examine_data[i][2];
				end
			end
		end

		if grab_script_mode == "List (Object Model 1)" then
			row = row + 1;
			for i = #object_pointers, 1, -1 do
				local currentActorSize = mainmemory.read_u32_be(object_pointers[i] + object_size); -- TODO: Got an exception here while kiosk was booting
				local color = nil;
				if object_index == i then
					color = yellow_highlight;
				end
				if object_pointers[i] == playerObject then
					color = green_highlight;
				end
				gui.text(gui_x, gui_y + height * row, i..": "..getActorName(object_pointers[i]).." "..toHexString(object_pointers[i] or 0, 6).." ("..toHexString(currentActorSize)..")", color, nil, 'bottomright');
				row = row + 1;
			end
		end

		if grab_script_mode == "List (Object Model 2)" then
			for i = #object_pointers, 1, -1 do
				local behaviorPointer = dereferencePointer(object_pointers[i] + obj_model2.behavior_pointer);
				local collectableState = mainmemory.readbyte(object_pointers[i] + obj_model2.collectable_state);
				if isRDRAM(behaviorPointer) then
					behaviorPointer = " ("..toHexString(behaviorPointer or 0, 6)..")";
				else
					behaviorPointer = "";
				end
				local color = nil;
				if isGB(collectableState) then
					color = yellow_highlight;
				end
				if object_index == i then
					color = green_highlight
				end

				local behaviorType = "";
				local behaviorTypePointer = dereferencePointer(object_pointers[i] + obj_model2.behavior_type_pointer);
				if isRDRAM(behaviorTypePointer) then
					behaviorType = " "..behaviorType..readNullTerminatedString(behaviorTypePointer + 0x0C);
				end

				if not (behaviorPointer == "" and hide_non_scripted) then
					gui.text(gui_x, gui_y + height * row, i..": "..toHexString(object_pointers[i] or 0, 6)..behaviorType..behaviorPointer, color, nil, 'bottomright');
					row = row + 1;
				end
			end
		end

		if grab_script_mode == "List (Loading Zones)" then
			for i = #object_pointers, 1, -1 do
				local color = nil;
				if object_index == i then
					color = green_highlight
				end

				local base = object_pointers[i];
				if isRDRAM(base) then
					local _type = mainmemory.read_u16_be(base + loading_zone_fields.object_type);
					if loading_zone_fields.object_types[_type] ~= nil then
						_type = loading_zone_fields.object_types[_type].." ("..toHexString(_type)..")";
					else
						_type = toHexString(_type);
					end
					if stringContains(_type, "Loading Zone") then
						local destinationMap = mainmemory.read_u16_be(base + loading_zone_fields.destination_map);
						if Game.maps[destinationMap + 1] ~= nil then
							destinationMap = Game.maps[destinationMap + 1];
						else
							destinationMap = "Unknown Map "..toHexString(destinationMap);
						end
						local destinationExit = mainmemory.read_u16_be(base + loading_zone_fields.destination_exit);
						gui.text(gui_x, gui_y + height * row, destinationMap.." ("..destinationExit..") "..toHexString(base or 0, 6).." "..i, color, nil, 'bottomright');
						row = row + 1;
					elseif stringContains(_type, "Cutscene Trigger") then
						gui.text(gui_x, gui_y + height * row, _type.." ("..mainmemory.read_u16_be(base + loading_zone_fields.destination_map)..") "..toHexString(base or 0, 6).." "..i, color, nil, 'bottomright');
						row = row + 1;
					else
						gui.text(gui_x, gui_y + height * row, _type.." "..toHexString(base or 0, 6).." "..i, color, nil, 'bottomright');
						row = row + 1;
					end
				end
			end
		end
	end
end

------------
-- Events --
------------

function Game.unlockMoves()
	for kong = DK, Krusha do -- TODO: Double check Kiosk offsets
		local base = Game.Memory.kong_base[version] + kong * 0x5E;
		mainmemory.writebyte(base + moves, 3);
		mainmemory.writebyte(base + sim_slam, 3);
		mainmemory.writebyte(base + weapon, 7);
		mainmemory.writebyte(base + instrument, 15);
	end

	-- Complete Training barrels & Unlock Camera
	setFlagByName("Camera/Shockwave");
	setFlagByName("Training Grounds: Dive Barrel Completed");
	setFlagByName("Training Grounds: Orange Barrel Completed");
	setFlagByName("Training Grounds: Barrel Barrel Completed");
	setFlagByName("Training Grounds: Vine Barrel Completed");

	-- Unlock Kongs
	setFlagsByType("Kong");
end

function Game.getMap()
	return mainmemory.read_u32_be(Game.Memory.map[version]);
end

function Game.setMap(value)
	if value >= 1 and value <= #Game.maps then
		if version == 4 then
			mainmemory.write_u16_be(0x5931BA, value - 1); -- Replace object model 2, rather than loading the map since basically everything crashes on kiosk
		else
			mainmemory.write_u32_be(Game.Memory.map[version], value - 1);
		end
	end
end

function Game.initUI()
	-- Flag stuff
	ScriptHawk.UI.form_controls["Flag Dropdown"] = forms.dropdown(ScriptHawk.UI.options_form, flag_names, ScriptHawk.UI.col(0) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(7) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.col(9) + 8, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Set Flag Button"] = forms.button(ScriptHawk.UI.options_form, "Set", flagSetButtonHandler, ScriptHawk.UI.col(10), ScriptHawk.UI.row(7), 59, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Clear Flag Button"] = forms.button(ScriptHawk.UI.options_form, "Clear", flagClearButtonHandler, ScriptHawk.UI.col(13) - 5, ScriptHawk.UI.row(7), 59, ScriptHawk.UI.button_height);

	-- Moon stuff
	ScriptHawk.UI.form_controls["Moon Mode Label"] = forms.label(ScriptHawk.UI.options_form, "Moon:", ScriptHawk.UI.col(10), ScriptHawk.UI.row(2) + ScriptHawk.UI.label_offset, 48, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Moon Mode Button"] = forms.button(ScriptHawk.UI.options_form, moon_mode, toggle_moonmode, ScriptHawk.UI.col(13) - 18, ScriptHawk.UI.row(2), 59, ScriptHawk.UI.button_height);

	-- Buttons
	ScriptHawk.UI.form_controls["Unlock Moves Button"] = forms.button(ScriptHawk.UI.options_form, "Unlock Moves", Game.unlockMoves, ScriptHawk.UI.col(10), ScriptHawk.UI.row(0), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Toggle Visibility Button"] = forms.button(ScriptHawk.UI.options_form, "Invisify", toggle_invisify, ScriptHawk.UI.col(7), ScriptHawk.UI.row(1), 64, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Toggle TB Void Button"] = forms.button(ScriptHawk.UI.options_form, "Toggle TB Void", toggle_tb_void, ScriptHawk.UI.col(10), ScriptHawk.UI.row(1), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Fix Bone Displacement Button"] = forms.button(ScriptHawk.UI.options_form, "Fix Spiking", fixBoneDisplacement, ScriptHawk.UI.col(10), ScriptHawk.UI.row(4), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Toggle Detect Displacement Checkbox"] = forms.checkbox(ScriptHawk.UI.options_form, "Detect Spiking", ScriptHawk.UI.col(10) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(5) + ScriptHawk.UI.dropdown_offset);
	--ScriptHawk.UI.form_controls["Random Color"] = forms.button(ScriptHawk.UI.options_form, "Random Color", Game.setKongColor, ScriptHawk.UI.col(5), ScriptHawk.UI.row(5), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);
	--ScriptHawk.UI.form_controls["Everything is Kong Button"] = forms.button(ScriptHawk.UI.options_form, "Kong", everythingIsKong, ScriptHawk.UI.col(10), ScriptHawk.UI.row(3), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);
	--ScriptHawk.UI.form_controls["Force Pause Button"] = forms.button(ScriptHawk.UI.options_form, "Force Pause", force_pause, ScriptHawk.UI.col(10), ScriptHawk.UI.row(4), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Force Zipper Button"] = forms.button(ScriptHawk.UI.options_form, "Force Zipper", force_zipper, ScriptHawk.UI.col(5), ScriptHawk.UI.row(4), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);
	--ScriptHawk.UI.form_controls["Random Effect Button"] = forms.button(ScriptHawk.UI.options_form, "Random effect", random_effect, ScriptHawk.UI.col(10), ScriptHawk.UI.row(6), ScriptHawk.UI.col(4) + 10, ScriptHawk.UI.button_height);

	-- Lag fix
	ScriptHawk.UI.form_controls["Decrease Lag Factor Button"] = forms.button(ScriptHawk.UI.options_form, "-", decrease_lag_factor, ScriptHawk.UI.col(13) - 5, ScriptHawk.UI.row(6), ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Increase Lag Factor Button"] = forms.button(ScriptHawk.UI.options_form, "+", increase_lag_factor, ScriptHawk.UI.col(13) + ScriptHawk.UI.button_height - 5, ScriptHawk.UI.row(6),ScriptHawk.UI.button_height, ScriptHawk.UI.button_height);
	ScriptHawk.UI.form_controls["Lag Factor Value Label"] = forms.label(ScriptHawk.UI.options_form, "0", ScriptHawk.UI.col(13) + ScriptHawk.UI.button_height + 21, ScriptHawk.UI.row(6) + ScriptHawk.UI.label_offset, 54, 14);
	ScriptHawk.UI.form_controls["Toggle Lag Fix Checkbox"] = forms.checkbox(ScriptHawk.UI.options_form, "Lag fix", ScriptHawk.UI.col(10) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(6) + ScriptHawk.UI.dropdown_offset);

	-- Checkboxes
	ScriptHawk.UI.form_controls["Toggle Homing Ammo Checkbox"] = forms.checkbox(ScriptHawk.UI.options_form, "Homing Ammo", ScriptHawk.UI.col(0) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(6) + ScriptHawk.UI.dropdown_offset);
	--ScriptHawk.UI.form_controls["Toggle Neverslip Checkbox"] = forms.checkbox(ScriptHawk.UI.options_form, "Never Slip", ScriptHawk.UI.col(10) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(5) + ScriptHawk.UI.dropdown_offset);
	ScriptHawk.UI.form_controls["Toggle Paper Mode Checkbox"] = forms.checkbox(ScriptHawk.UI.options_form, "Paper Mode", ScriptHawk.UI.col(5) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(5) + ScriptHawk.UI.dropdown_offset);
	ScriptHawk.UI.form_controls["Toggle OhWrongnana"] = forms.checkbox(ScriptHawk.UI.options_form, "OhWrongnana", ScriptHawk.UI.col(5) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(6) + ScriptHawk.UI.dropdown_offset);

	-- Output flag statistics
	flagStats();
end

----------------------
-- High Score Stuff --
----------------------

--[[

local arcadeScores = {
	{"INT", 1222900}, -- https://www.youtube.com/watch?v=lekPEle8F8w
};

local enguardeScores = {
	{"JON", 430}, -- https://www.youtube.com/watch?v=VrFWWcGlKOE
	{"ING", 420}, -- https://www.youtube.com/watch?v=UEPeqomGHN4
};

local jetpacScore = 999135; -- Bismuth http://i.imgur.com/5mHz6QA.png

local scoreBase = 0;
local nameBase = 2;
local scoreInstanceSize = 6;

local rambiScores = {
	{"BIS", 220}, -- http://www.twitch.tv/bismuth9/v/42515576
	{"BO ", 220}, -- http://highscore.com/scores/N64/DonkeyKong64/33503
	{"ISO", 190}, -- https://www.youtube.com/watch?v=pu3lmK3p8bc
};

function Game.getScore(index)
	readNullTerminatedString();
end

function Game.setScore(index, name, score)
	if version ~= 4 then
		mainmemory.write_u16_be(Game.Memory.rambiBase[version] + index * scoreInstanceSize + scoreBase, score);
		for i = 0, 3 do
			mainmemory.writebyte(Game.Memory.rambiBase[version] + index * scoreInstanceSize + nameBase, string.byte(name, i))
		end
	end
end

function Game.setHighScores()
	-- TODO: Game.setHighScores
end

]]--

function Game.unlockMenus()
	if version ~= 4 then -- Anything but the Kiosk version
		mainmemory.write_u32_be(Game.Memory.menu_flags[version], 0xFFFFFFFF);
		mainmemory.write_u32_be(Game.Memory.menu_flags[version] + 4, 0xFFFFFFFF);
	end
end

function Game.applyInfinites()
	local global_base = Game.Memory.global_base[version]; -- TODO: Use HUD pointer and object to get these memory locations

	mainmemory.writebyte(global_base + standard_ammo, Game.getMaxStandardAmmo());
	if forms.ischecked(ScriptHawk.UI.form_controls["Toggle Homing Ammo Checkbox"]) then
		mainmemory.writebyte(global_base + homing_ammo, Game.getMaxHomingAmmo());
	else
		mainmemory.writebyte(global_base + homing_ammo, 0);
	end

	mainmemory.writebyte(global_base + oranges, max_oranges);
	if version == 2 then
		mainmemory.write_u16_be(global_base + crystals, max_crystals * 125); -- European ticks per crystal is 125
	else
		mainmemory.write_u16_be(global_base + crystals, max_crystals * 150);
	end
	mainmemory.writebyte(global_base + film, max_film);
	mainmemory.writebyte(global_base + health, mainmemory.readbyte(global_base + melons) * 4);

	if version ~= 4 then -- TODO: Kiosk
		for kong = DK, Krusha do
			local base = Game.Memory.kong_base[version] + kong * 0x5E;
			mainmemory.write_u16_be(base + coins, max_coins);
			mainmemory.write_u16_be(base + lives, max_musical_energy);
		end
	end
end

-------------------
-- Color setters --
-------------------

function getNextTextureRenderer(texturePointer)
	return dereferencePointer(texturePointer + obj_model1.texture_renderer.next_renderer);
end

function Game.getTextureRenderers()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local texturePointer = dereferencePointer(playerObject + obj_model1.texture_renderer_pointer);
		while isRDRAM(texturePointer) do
			print(toHexString(texturePointer));
			texturePointer = getNextTextureRenderer(texturePointer);
		end
	end
end

function Game.setDKColors()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local texturePointer = dereferencePointer(playerObject + obj_model1.texture_renderer_pointer);
		if isRDRAM(texturePointer) then
			local DKBodyColors = {
				{"Normal", 0},
				{"Light Blue", 1},
				{"Light Green", 2},
				{"Purple", 3},
				{"Bright Orange", 16},
				{"Yellow", 19},
			};

			local DKTieColors = {
				{"Red (Normal)", 0},
				{"Purple", 1},
				{"Blue", 2},
				{"Yellow", 3},
			};

			texturePointer = getNextTextureRenderer(texturePointer); -- Skip eyes

			-- 1 Body
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, DKBodyColors[math.random(1, #DKBodyColors)][2]);
			texturePointer = getNextTextureRenderer(texturePointer);

			-- 2 Tie Outer
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, DKTieColors[math.random(1, #DKTieColors)][2]);

			-- TODO: Tie inner
		end
	end
end

function Game.setDiddyColors()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local texturePointer = mainmemory.dereferencePointer(playerObject + obj_model1.texture_renderer_pointer);
		if isRDRAM(texturePointer) then
			local DiddyHatColors = {
				{"Red (Normal)", 0},
				{"Dark Blue", 1},
				{"Yellow", 2},
				{"Blue", 3},
				{"Purple", 19},
				{"Dark Red", 24},
				{"Green", 26},
			}

			texturePointer = getNextTextureRenderer(texturePointer); -- Skip Left eye
			texturePointer = getNextTextureRenderer(texturePointer); -- Skip Right eye

			-- 3 Hat
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, DiddyHatColors[math.random(1, #DiddyHatColors)][2]);
		end
	end
end

function Game.setLankyColors()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local texturePointer = dereferencePointer(playerObject + obj_model1.texture_renderer_pointer);
		if isRDRAM(texturePointer) then
			local LankyTopColors = {
				{"Blue (Normal)", 0},
				{"Green", 1},
				{"Purple", 2},
				{"Red", 3},
				{"Yellow", 27},
			};

			texturePointer = getNextTextureRenderer(texturePointer); -- Skip eyes

			-- 1 Top
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, LankyTopColors[math.random(1, #LankyTopColors)][2]);

			-- TODO: Bottom
		end
	end
end

function Game.setTinyColors()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local texturePointer = dereferencePointer(playerObject + obj_model1.texture_renderer_pointer);
		if isRDRAM(texturePointer) then
			local TinyBodyColors = {
				{"Blue (Normal)", 0},
				{"Green", 1},
				{"Purple", 2},
				{"Orange", 3},
			};

			texturePointer = getNextTextureRenderer(texturePointer); -- Skip Left eye
			texturePointer = getNextTextureRenderer(texturePointer); -- Skip Right eye

			-- 3 Body
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, TinyBodyColors[math.random(1, #TinyBodyColors)][2]);
		end
	end
end

function Game.setChunkyColors()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local texturePointer = dereferencePointer(playerObject + obj_model1.texture_renderer_pointer);
		if isRDRAM(texturePointer) then
			local ChunkyBackColors = {
				{"Green + Yellow (Normal)", 0},
				{"Red + Yellow", 1},
				{"Blue + Light Blue", 2},
				{"Purple + Pink", 3},
				{"Blue", 16},
				{"Red", 17},
				{"Purple", 18},
				{"Green", 19},
			};

			local ChunkyFrontColors = {
				{"Blue (Normal)", 0},
				{"Red", 1},
				{"Purple", 2},
				{"Green", 3},
			};

			texturePointer = getNextTextureRenderer(texturePointer); -- Skip Eyes

			-- 1 Back
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, ChunkyBackColors[math.random(1, #ChunkyBackColors)][2]);
			texturePointer = getNextTextureRenderer(texturePointer);

			-- 2 Front
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, ChunkyFrontColors[math.random(1, #ChunkyFrontColors)][2]);
		end
	end
end

function Game.setKrushaColors()
	local playerObject = Game.getPlayerObject();
	if isRDRAM(playerObject) then
		local texturePointer = dereferencePointer(playerObject + obj_model1.texture_renderer_pointer);
		if isRDRAM(texturePointer) then
			local KrushaColors = {
				{"Blue (Normal)", 0},
				{"Green", 1},
				{"Purple", 2},
				{"Yellow", 3},
			};

			texturePointer = getNextTextureRenderer(texturePointer); -- Skip Eyes

			-- 2 Body
			mainmemory.write_u16_be(texturePointer + obj_model1.texture_renderer.texture_index, TinyBodyColors[math.random(1, #TinyBodyColors)][2]);
		end
	end
end

local setColorFunctions = {
	[DK] = Game.setDKColors,
	[Diddy] = Game.setDiddyColors,
	[Lanky] = Game.setLankyColors,
	[Tiny] = Game.setTinyColors,
	[Chunky] = Game.setChunkyColors,
	[Krusha] = Game.setKrushaColors
};

function Game.setKongColor()
	local currentKong = mainmemory.readbyte(Game.Memory.character[version]);
	if type(setColorFunctions[currentKong]) == "function" then
		setColorFunctions[currentKong]();
	end
end

function Game.realTime()
	updateCurrentInvisify();
	forms.settext(ScriptHawk.UI.form_controls["Lag Factor Value Label"], lag_factor);
	forms.settext(ScriptHawk.UI.form_controls["Toggle Visibility Button"], current_invisify);
	forms.settext(ScriptHawk.UI.form_controls["Moon Mode Button"], moon_mode);
	drawGrabScriptUI();

	-- Draw ISG timer
	if timer_started then
		local s = timer_value / 60;
		local timer_string = string.format("%.2d:%05.2f", s / 60 % 60, s % 60);
		gui.text(16, 16, "ISG Timer: "..timer_string, nil, nil, 'topright');
	else
		--gui.text(16, 16, "Waiting for ISG", nil, nil, 'topright');
	end
end

function Game.eachFrame()
	local playerObject = Game.getPlayerObject();
	map_value = Game.getMap();

	--koshBotLoop(); -- TODO: This probably stops the virtual pad from working
	forceTBS();
	Game.unlockMenus(); -- TODO: Allow user to toggle this

	-- Force STVW
	--local yRot = Game.getYRotation();
	--if yRot < Game.max_rot_units then
	--	Game.setYRotation(yRot + Game.max_rot_units);
	--end

	-- Lag fix
	if forms.ischecked(ScriptHawk.UI.form_controls["Toggle Lag Fix Checkbox"]) then
		fixLag();
	end

	if neverSlip then
	--if forms.ischecked(ScriptHawk.UI.form_controls["Toggle Neverslip Checkbox"]) then
		Game.neverSlip();
	end

	if type(ScriptHawk.UI.form_controls["Toggle Paper Mode Checkbox"]) ~= "nil" and forms.ischecked(ScriptHawk.UI.form_controls["Toggle Paper Mode Checkbox"]) then
		Game.paperMode();
	end

	-- OhWrongnana
	if type(ScriptHawk.UI.form_controls["Toggle OhWrongnana"]) ~= "nil" and forms.ischecked(ScriptHawk.UI.form_controls["Toggle OhWrongnana"]) then
		ohWrongnana();
	end

	-- Mad Jack
	Game.drawMJMinimap();

	applyBoneDisplacementFix();
	if type(ScriptHawk.UI.form_controls["Toggle Detect Displacement Checkbox"]) ~= "nil" and forms.ischecked(ScriptHawk.UI.form_controls["Toggle Detect Displacement Checkbox"]) then
		displacementDetection();
	end
	ISGTimer();
	doBRB();
	processFlagQueue();

	-- Moonkick
	if moon_mode == 'All' or (moon_mode == 'Kick' and isRDRAM(playerObject) and mainmemory.readbyte(playerObject + obj_model1.player.animation_type) == 0x29) then
		Game.setYAcceleration(-2.5);
	end

	-- Check EEPROM checksums
	if memory.usememorydomain("EEPROM") then
		local checksum_value;
		local slotChanged = false;
		for i = 1, #eep_checksum_offsets do
			checksum_value = memory.read_u32_be(eep_checksum_offsets[i]);
			if eep_checksum_values[i] ~= checksum_value then
				slotChanged = true;
				if i == 5 then
					dprint("Global flags "..i.." Checksum: "..toHexString(eep_checksum_values[i], 8).." -> "..toHexString(checksum_value, 8));
				else
					dprint("Slot "..i.." Checksum: "..toHexString(eep_checksum_values[i], 8).." -> "..toHexString(checksum_value, 8));
				end
				eep_checksum_values[i] = checksum_value;
			end
		end
		if slotChanged then
			print_deferred();
		end
	end
	memory.usememorydomain("RDRAM");
end

function Game.crankyCutsceneMininumRequirements()
	setFlagsByType("Crown");
	setFlagsByType("Fairy");
	setFlagsByType("Key");
	setFlagsByType("Medal");
	setFlagByName("Nintendo Coin");
	setFlagByName("Rareware Coin");

	-- CB and GB counters
	for kong = DK, Chunky do
		local base = Game.Memory.kong_base[version] + kong * 0x5E;
		for level = 0, 7 do
			mainmemory.write_s16_be(base + GB_Base + (level * 2), 5); -- Normal GB's
			if level == 7 and kong == Tiny then
				mainmemory.write_s16_be(base + GB_Base + (level * 2), 6); -- Rareware GB
			end
		end
	end
end

function Game.completeFile()
	Game.unlockMoves();

	setFlagsByType("Blueprint"); -- Not needed to trigger Cranky Cutscene
	setFlagsByType("CB"); -- Not needed to trigger the Cranky Cutscene
	setFlagsByType("Bunch"); -- Not needed to trigger the Cranky Cutscene
	setFlagsByType("Balloon"); -- Not needed to trigger the Cranky Cutscene
	setFlagsByType("Crown");
	setFlagsByType("Fairy");
	setFlagsByType("GB"); -- Not needed to trigger Cranky Cutscene
	setFlagsByType("Key");
	setFlagsByType("Medal");
	setFlagByName("Nintendo Coin");
	setFlagByName("Rareware Coin");

	-- CB and GB counters
	for kong = DK, Chunky do
		local base = Game.Memory.kong_base[version] + kong * 0x5E;
		for level = 0, 6 do
			mainmemory.write_u16_be(base + CB_Base + (level * 2), 75); -- Not needed to trigger Cranky Cutscene
		end
		for level = 0, 7 do
			mainmemory.write_s16_be(base + GB_Base + (level * 2), 5); -- Normal GB's
			if level == 7 and kong == Tiny then
				mainmemory.write_s16_be(base + GB_Base + (level * 2), 6); -- Rareware GB
			end
		end
	end
end

Game.OSDPosition = {32, 70};
Game.OSD = {
	{"X", Game.getXPosition},
	{"Y", Game.getYPosition},
	{"Z", Game.getZPosition},
	{"Separator", 1},
	{"Floor", Game.getFloor},
	{"Separator", 1},
	{"dY"},
	{"dXZ"},
	{"Velocity", Game.getVelocity},
	--{"Accel", Game.getAcceleration}, -- TODO: Game.getAcceleration
	{"Y Velocity", Game.getYVelocity},
	{"Y Accel", Game.getYAcceleration},
	{"Separator", 1},
	{"Max dY"},
	{"Max dXZ"},
	{"Odometer"},
	{"Separator", 1},
	{"Rot. X", Game.getXRotation},
	{"Facing", Game.getYRotation, Game.colorYRotation},
	--{"Moving", Game.getMovingRotation}, -- TODO: Game.getMovingRotation
	{"Rot. Z", Game.getZRotation},
	{"Movement", Game.getMovementState},
	--{"Mode", Game.getCurrentMode},
	--{"Camera", Game.getCameraState},
	{"Separator", 1},
	{"Bone Array 1", Game.getOSDBoneArray1},
	{"Stored X1", Game.getStoredX1},
	{"Stored Y1", Game.getStoredY1},
	{"Stored Z1", Game.getStoredZ1},
	{"Separator", 1},
	{"Bone Array 2", Game.getOSDBoneArray2},
	{"Stored X2", Game.getStoredX2},
	{"Stored Y2", Game.getStoredY2},
	{"Stored Z2", Game.getStoredZ2},
};

---------------
-- ASM Stuff --
---------------

Game.supportsASMHacks = true;
Game.ASMHookBase = 0x7494;
Game.ASMHook = {
	0x3C, 0x08, 0x80, 0x7F, 0x35, 0x08, 0xF5, 0x00,
	0x01, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00
}
Game.ASMCodeBase = 0x7FF500;
Game.ASMMaxCodeSize = 0xAFF;

return Game;