if type(ScriptHawk) ~= "table" then
	print("This script is not designed to run by itself");
	print("Please run ScriptHawk.lua from the parent directory instead");
	print("Thanks for using ScriptHawk :)");
	return;
end

encircle_enabled = false;

object_index = 1;
object_pointers = {}; -- TODO: I'd love to get rid of this eventually, replace with some kind of getObjectPointers() system
grab_script_modes = {
	"Disabled",
	"List (Model 1)",
	"Examine (Model 1)",
	"List (Model 2)",
	"Examine (Model 2)",
};
grab_script_mode_index = 1;
grab_script_mode = grab_script_modes[grab_script_mode_index];

local Game = {
	squish_memory_table = true,
	Memory = { -- 1 USA, 2 EU
		jim_pointer = {0x0C6810, 0x0C8670},
		floor_value = {0x0D6EDC, 0x0D8D3C},
		current_map = {0x0E9EF9, 0x0EBD59},
		destination_map = {0x0E03E7, 0x0E2247},
		destination_exit = {0x0E03E9, 0x0E2249},
		subhub_entrance_cs = {0x0C624A, nil},
		--controller_input = {0x0D4134, 0x0D5F94},
		reload_map = {0x0E03E2, 0x0E2242},
		marble_pointer = {0x0C61E2, 0x0C8042},
		object_count = {0x0E9E97, nil},
		obj1_pointer_list = {0x0E9E98, nil},
		object_m2_count = {0x0E9EFE, nil},
		obj2_pointer_list = {0x0E9F00, nil},
		flag_pointer = {0x0E9F08, 0x0EBD68},
		marble_count = {0x0E9FF3, nil},
	},
	speedy_speeds = {.001, .01, .1, .5, 1, 2, 5, 10, 20},
	speedy_index = 7,
	speedy_invert_LR = true,
	rot_speed = 10,
	max_rot_units = 360,
};

--------------------
-- Jim Parameters --
--------------------

local jim = {
	y_rotation_1 = 0x000, -- Float
	y_rotation_2 = 0x008, -- Float
	x_position = 0x030, -- Float
	y_position = 0x034, -- Float
	z_position = 0x038, -- Float
	bagpipe_lock = 0x0C0, -- Byte
	animation_timer = 0x0CA, -- 2 Byte
	control_type = 0x0F4, -- 4 Byte (0 = Normal, 2 = Boss Fights, 4 = Void Process)
	Health = 0x0FC, -- 4 Byte
	animation = 0x0C9, -- Byte
	Lives = 0x100, -- 4 Byte
	gun_pointer = 0x104,
	movement = 0x2F3, -- Byte
	cutscene_lock = 0x2A3, -- Byte
	--speed = 0x2C8, -- Float (Not too sure on this)
	y_last_action = 0x338, -- Float
	crouch_available = 0x454, -- Byte
	oob_timer = 0x455, -- Byte
	boss_pointer = 0x48C, -- Byte
	first_person_angle_delta = 0x4D8, -- Float, Radians?
	character_mode = 0x5B0, -- Byte (0 = Jim, 1+ = Kim)
};

--------------------
-- Gun Parameters --
--------------------

local gun = {
	red_gun = 0x000,
	bubble_gun = 0x018,
	rockets = 0x030,
	flamethrower = 0x048,
	bananamyte = 0x060,
	laser = 0x078,
	pea = 0x090,
	egg	= 0x0A8,
	fakegun = 0x0C0,
	magnum = 0x0D8,
	disco = 0x0F0,
	knife = 0x108,
	leprechaun = 0x120,
};

---------------------
-- Boss Parameters --
---------------------

local boss = {
	player_marbles = 0xDFC,
	player_egoboosts = 0xDFD,
	player_missiles = 0xDFE,
	boss_marbles = 0xE48,
	boss_egoboosts = 0xE49,
	boss_missiles = 0xE4A,
};

--------------
-- Position --
--------------

function Game.getXPosition()
	return mainmemory.readfloat(Game.Memory.jim_pointer + jim.x_position, true);
end

function Game.getYPosition()
	return mainmemory.readfloat(Game.Memory.jim_pointer + jim.y_position, true);
end

function Game.getZPosition()
	return mainmemory.readfloat(Game.Memory.jim_pointer + jim.z_position, true);
end

function Game.setXPosition(value)
	mainmemory.writefloat(Game.Memory.jim_pointer + jim.x_position, value, true);
end

function Game.setYPosition(value)
	mainmemory.writefloat(Game.Memory.jim_pointer + jim.y_position, value, true);
end

function Game.setZPosition(value)
	mainmemory.writefloat(Game.Memory.jim_pointer + jim.z_position, value, true);
end

function Game.getFloor()
	return mainmemory.readfloat(Game.Memory.floor_value, true);
end

--------------
-- Rotation --
--------------

function Game.calculateAngle(angle1, angle2)
	angle_1 = 90 * (angle1 + 1);

	if angle2 < 0 then
		return (angle_1 * (0 - 1)) - 90;
	else
		return (angle_1 - 90);
	end
end

function Game.getXRotation()
	return mainmemory.readfloat(Game.Memory.x_rotation, true);
end

function Game.getYRotation()
	local angle1 = mainmemory.readfloat(Game.Memory.jim_pointer + jim.y_rotation_1, true);
	local angle2 = mainmemory.readfloat(Game.Memory.jim_pointer + jim.y_rotation_2, true);
	return Game.calculateAngle(angle1, angle2);
end

function Game.getZRotation()
	return mainmemory.readfloat(Game.Memory.z_rotation, true);
end

function Game.setXRotation(value)
	mainmemory.writefloat(Game.Memory.x_rotation, value, true);
end

function Game.setYRotation(value)
	mainmemory.writefloat(Game.Memory.y_rotation, value / 180, true);
end

function Game.setZRotation(value)
	mainmemory.writefloat(Game.Memory.z_rotation, value, true);
end

------------
-- Events --
------------

Game.maps = {
	"The Brain",
	"Memory Hub",
	"Coop D'Etat",
	"Barn to be Wild",
	"Psycrow",
	"Happiness Hub",
	"Lord to the Fries",
	"Are you Hungry Tonite?",
	"Fatty Roswell",
	"Fear Hub",
	"Mansion Lobby",
	"Poultrygeist",
	"Poultrygeist Too",
	"Death Wormed Up",
	"Boogie Nights of the Living Dead",
	"Professor Monkey for a Head",
	"Fantasy Hub",
	"Violent Death Valley",
	"The Good, The Bad and The Elderly",
	"Bob and Number Four",
	"Earthworm Kim",
	"Main Menu",
};

Game.animations = {
	[0] = "Walking",
	[1] = "Running",
	[2] = "Preparing to Run",
	[3] = "Idle",
	[4] = "Creeping",
	[5] = "Stopping",
	[6] = "Jumping",
	[7] = "Holding Gun",
	[8] = "Firing",
	[9] = "Grabbing Gun",
	-- [10] = "Wielding Gun", -- Not used?
	[11] = "Idle", -- Rope
	[12] = "Moving", -- Rope
	[13] = "Holding Gun", -- Rope
	[14] = "Firing", -- Rope
	[15] = "Grabbing Gun", -- Rope
	[16] = "Retracting Gun", -- Rope
	[17] = "Surfing", -- Pork Boarding, No Earthworm Turning
	[18] = "Surfing", -- Pork Boarding, Earthworm Turning
	[19] = "Grabbing Ledge",
	[20] = "Damage", -- Laser Guns, Fall Damage
	[21] = "Damage", -- Knockback
	[22] = "Death",
	[23] = "Idle", -- Pulling Head
	[24] = "Breaking Wind", -- Pp Can, Also acid sea damage
	[25] = "Crouching/Rolling",
	[26] = "Udder Dance",
	[27] = "Whipping",
	[28] = "Whipping", -- Jumping
	[29] = "Floating", -- Spin Move in Air
	[30] = "Damage", -- Acid Bats
	[31] = "Dodging", -- Rope
	[32] = "Damage", -- Rope
	[33] = "Drowning",
	[34] = "Inflating", -- Balloon
	[35] = "Floating", -- Balloon
	[36] = "Ego Boost", -- Pork Boarding
	[37] = "Damage", -- Pork Boarding
	[38] = "Jumping", -- Pork Boarding
	[39] = "Bagpipes", -- Opening new hub
	[40] = "Prancing", -- Main Menu Pre/Post-Accordion
	[41] = "Playing", -- Main Menu Accordion
	[42] = "Falling", -- Main Menu Post Cows
	[43] = "Locked", -- Textbox
};

Game.movements = {
	[0] = "Normal", -- A lot of things
	[1] = "Jumping", -- Moving
	[2] = "Jumping (Stationary)",
	[4] = "Stopping",
	[9] = "On Rope",
	[12] = "Grabbing Ledge", -- End of Grabbing Up
	[13] = "Grabbing Ledge", -- Grabbing Up
	[14] = "Breaking Wind",
	[16] = "Rolling",
	[17] = "Crouching",
	[18] = "Whipping (Grounded)",
	[19] = "Whipping", -- Airbourne
	[20] = "Floating",
	[21] = "Knockback", -- Damage
	[22] = "Damaged", -- Damage plane (Acid sea/bean sea etc.)
	[23] = "Acid Burn", -- Acid Bats
	[24] = "First Person",
	[25] = "Blue Balloon",
};

Game.takeMeThereType = "Checkbox";

function Game.setMap(index)
	mainmemory.writebyte(Game.Memory.destination_map, index - 1);
end

function Game.checkMapSoftlock()
	local dest_exit = mainmemory.readbyte(Game.Memory.destination_exit);
	local dest_map = mainmemory.readbyte(Game.Memory.destination_map);

	if dest_map == 1 or dest_map == 5 or dest_map == 9 or dest_map == 16 then -- Sub Hubs (Central Column Fix)
		if dest_exit > 0 and dest_exit < 4 then -- Coming from Boss/Level
			mainmemory.writebyte(Game.Memory.subhub_entrance_cs, 0);
		else -- Coming from 'The Brain'
			mainmemory.writebyte(Game.Memory.subhub_entrance_cs, 1);
		end
	end
end

function Game.reloadMap()
	mainmemory.writebyte(Game.Memory.reload_map, 1);
	Game.checkMapSoftlock();
end

function Game.reloadMapHard()
	mainmemory.writebyte(Game.Memory.current_map, 255);
	Game.reloadMap();
end

function Game.getMapOSD()
	local currentMap = mainmemory.readbyte(Game.Memory.current_map);
	local currentMapName = "Unknown";
	if Game.maps[currentMap + 1] ~= nil then
		currentMapName = Game.maps[currentMap + 1];
	end
	return currentMapName.." ("..currentMap..")";
end

function Game.setExit(index)
	mainmemory.writebyte(Game.Memory.destination_exit);
end

function Game.getExitOSD()
	local currentExit = mainmemory.readbyte(Game.Memory.destination_exit);
	return currentExit;
end

function Game.getAnimationOSD()
	local currentAnimation = mainmemory.readbyte(Game.Memory.jim_pointer + jim.animation);
	local currentAnimationName = "Unknown ("..currentAnimation..")";
	return Game.animations[currentAnimation] or currentAnimationName;
end

function Game.getMovementOSD()
	local currentMovement = mainmemory.readbyte(Game.Memory.jim_pointer + jim.movement);
	local currentMovementName = "Unknown ("..currentMovement..")";
	return Game.movements[currentMovement] or currentMovementName;
end

function Game.getAnimationTimerOSD()
	local anim_timer = mainmemory.read_u16_be(Game.Memory.jim_pointer + jim.animation_timer);
	return anim_timer;
end

function Game.FreezeOoBTimer()
	mainmemory.writebyte(Game.Memory.jim_pointer + jim.oob_timer, 0);
end

function Game.getMarbleCount()
	return mainmemory.readbyte(Game.Memory.marble_count);
end

--------------------
-- FREE ROAM MODE --
--------------------

local YStored; -- TODO: Put these in the Game table
local isYStored = false;

function Game.freeroamEnabled()
	if not isYStored then
		YStored = Game.getYPosition();
		isYStored = true;
	end

	-- detect if L to Levitate
	-- TODO: ScriptHawk should probably expose whether it's d-padding or levitating to game modules actually, hmm...
	local joypad_pressed = joypad.getimmediate();
	local input_pressed = input.get();
	local lbutton_pressed = joypad_pressed[ScriptHawk.lbutton.joypad] or input_pressed[ScriptHawk.lbutton.key];
	if lbutton_pressed then
		YStored = Game.getYPosition() + Game.speedy_speeds[Game.speedy_index];
	end

	Game.setYPosition(YStored);

	-- Cancel falling
	if mainmemory.readbyte(Game.Memory.jim_pointer + jim.movement) == 2 then
		mainmemory.writebyte(Game.Memory.jim_pointer + jim.movement, 21);
	end
end

function Game.freeroamDisabled()
	isYStored = false;
end

------------------
-- CONSOLE MODE --
------------------

function Game.toggleConsoleMode()
	if console_mode == 0 or console_mode == nil then
		console_mode = 1;
	elseif console_mode == 1 then
		console_mode = 2;
	else
		console_mode = 0;
	end
end

function Game.getConsoleMode()
	if not TASSafe then
		if console_mode == 1 then
			forms.settext(ScriptHawk.UI.form_controls["Console Mode Switch"], "N64 Mode");
			twirl_yFreeze = 1;
			roll_cap = 0; -- Currently desyncs like crazy
			walljump_hack = 1;
		elseif console_mode == 2 then
			forms.settext(ScriptHawk.UI.form_controls["Console Mode Switch"], "PC Mode");
			twirl_yFreeze = 0;
			roll_cap = 1;
			walljump_hack = 0;
		else
			forms.settext(ScriptHawk.UI.form_controls["Console Mode Switch"], "Emulator Mode");
			twirl_yFreeze = 0;
			roll_cap = 0;
			walljump_hack = 0;
		end
	end
end

-- List of edits to make more accurate to N64 or PC release
function Game.applyConsoleSettings()
	local animation_value = mainmemory.readbyte(Game.Memory.jim_pointer + jim.animation);
	local animation_frame = mainmemory.read_u16_be(Game.Memory.jim_pointer + jim.animation_timer);
	local movement_value = mainmemory.readbyte(Game.Memory.jim_pointer + jim.movement);

	if twirl_yFreeze == 1 then	-- NO TWIRL HEIGHT GAIN
		if animation_value == 29 and movement_value == 20 then
			if twirlStoredY == nil then
				if Game.version == 1 then -- US
					twirlStoredY = Game.getYPosition() - 0.0498;
				else -- Game.version == 2 (EU)
					twirlStoredY = Game.getYPosition() - 0.042;
				end
			end

			Game.setYPosition(twirlStoredY);

			if animation_frame == 9 then
				twirlStoredY = nil;
			end
		else
			twirlStoredY = nil;
		end
	end

	if roll_cap == 1 then -- NO HYPEREXTENDED ROLL (NOT EVEN ON PC, JUST AN EMU BUG)
		if animation_value == 25 and movement_value == 16 then
			if roll_count == nil then
				roll_count = 0;
			end

			if animation_frame == 21 then
				roll_count = roll_count + 1;
				if roll_count == 8 then
					mainmemory.write_u16_be(Game.Memory.jim_pointer + jim.animation_timer, 23);
					roll_count = 0;
				end
			end
		end
	end

	if walljump_hack == 1 then -- WALLJUMP
		if animation_value == 6 and movement_value == 12 then
			mainmemory.writebyte(Game.Memory.jim_pointer + jim.crouch_available, 1);
		end
	end
end

---------------
-- INFINITES --
---------------

function Game.applyInfinites()
	local max_ammo_red_gun = 250;
	local max_ammo_bubble_gun = 50;
	local max_ammo_rockets = 25;
	local max_ammo_flamethrower = 50;
	local max_ammo_bananamyte = 1;
	local max_ammo_laser = 6;
	local max_ammo_pea = 50;
	local max_ammo_egg = 25;
	local max_ammo_fakegun = 0;
	local max_ammo_magnum = 50;
	local max_ammo_disco = 6;
	local max_ammo_knife = 1;
	local max_ammo_leprechaun = 5;
	local max_lives = 3;
	local max_health = 100;
	local max_missiles = 2;
	local max_egoboosts = 2;

	-------------------
	-- Set Infinites --
	-------------------

	-- Lives
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.Lives, max_lives);
	-- Health
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.Health, max_health);
	-- Red Gun
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.red_gun, max_ammo_red_gun);
	-- Bubble Gun
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.bubble_gun, max_ammo_bubble_gun);
	-- Rocket Launcher
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.rockets, max_ammo_rockets);
	-- Flamethrower
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.flamethrower, max_ammo_flamethrower);
	-- Bananamyte
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.bananamyte, max_ammo_bananamyte);
	-- Laser Gun
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.laser, max_ammo_laser);
	-- Pea Shooter
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.pea, max_ammo_pea);
	-- Egg Shooter
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.egg, max_ammo_egg);
	-- Fake unused gun
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.fakegun, max_ammo_fakegun);
	-- Magnum Gun
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.magnum, max_ammo_magnum);
	-- Disco Gun
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.disco, max_ammo_disco);
	-- Knife Boomerang
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.knife, max_ammo_knife);
	-- Leprechaun Launcher
	mainmemory.write_u32_be(Game.Memory.jim_pointer + jim.gun_pointer + gun.leprechaun, max_ammo_leprechaun);
	local bossPointer = dereferencePointer(Game.Memory.jim_pointer + jim.boss_pointer);
	if isRDRAM(bossPointer) then
		-- Missiles
		mainmemory.writebyte(bossPointer + boss.player_missiles, max_missiles);
		-- Ego Boosts
		mainmemory.writebyte(bossPointer + boss.player_egoboosts, max_egoboosts);
	end
end

function completeFile()
	collectable_counts = { -- Udders, Marbles
		[0] = {1,0}, -- Brain
		[1] = {0,0}, -- Memory
		[2] = {3,100}, -- CDE
		[3] = {7,100}, -- BTBW
		[4] = {5,0}, -- Psycrow
		[5] = {0,0}, -- Happiness
		[6] = {5,100}, -- LOTF
		[7] = {5,100}, -- AYHT
		[8] = {5,0}, -- Roswell
		[9] = {0,0}, -- Fear
		[10] = {0,0}, -- Mansion Lobby
		[11] = {5,100}, -- PG1
		[12] = {5,100}, -- PG2
		[13] = {6,100}, -- DWU
		[14] = {5,100}, -- BNotLD
		[15] = {5,0}, -- PMFAH
		[16] = {0,0}, -- Fantasy
		[17] = {6,100}, -- VDV
		[18] = {6,100}, -- GBE
		[19] = {5,0}, -- Bob
		[20] = {0,0}, -- Kim
		[21] = {0,0}, -- Main Menu
	};

	for i = 0, (#collectable_counts - 1) do
		mainmemory.writebyte(Game.Memory.marble_pointer + i + 0x14, collectable_counts[i][1]);
		mainmemory.writebyte(Game.Memory.marble_pointer + i - 0x02, collectable_counts[i][2]);
	end

	setFlagsByType("Udder");
	setFlag(0x150); -- Have all udders check
end

Game.BossCamLockOffset = {
	[4] = 0x4D8, -- Psycrow
	[8] = 0x4C8, -- Roswell
	[15] = 0x4B0, -- PMFAH
	[19] = 0x4C8, -- Bob
	[20] = 0x4C0, -- Kim
};

function Game.killBoss()
	BossCamLockOffSet = Game.BossCamLockOffset[mainmemory.readbyte(Game.Memory.current_map)];
	if BossCamLockOffSet ~= nil then
		camlock_address = dereferencePointer(Game.Memory.flag_pointer) + BossCamLockOffSet;
		bossdeath_address = dereferencePointer(Game.Memory.jim_pointer + jim.boss_pointer) + 0xE73;
		mainmemory.writebyte(camlock_address, 1);
		mainmemory.writebyte(bossdeath_address, 1);
	else
		print("This map does not have a programmed boss, and so this function will not run");
	end
end

------------------------------
-- Fix Controller Input Bug --
------------------------------

--[[
function Game.fixInputBug()
	local joystick_x_input = mainmemory.readbyte(Game.Memory.controller_input + 0x2);
	if joystick_x_input == 127 then
		mainmemory.writebyte(Game.Memory.controller_input + 0x2, 126);
	end

	joystick_x_input = mainmemory.readbyte(Game.Memory.controller_input + 0x2);
	if joystick_x_input == 127 then
		joypad.setanalog({["P1 X Axis"] = 126})
	end
end
--]]

------------------
-- Object Stuff --
------------------

local function getObjectCount()
	return math.min(255, mainmemory.readbyte(Game.Memory.object_count) - 1);
end

function incrementObjectIndex()
	object_index = object_index + 1;
	if object_index > #object_pointers then
		object_index = 1;
	end
end

function decrementObjectIndex()
	object_index = object_index - 1;
	if object_index <= 0 then
		object_index = #object_pointers;
	end
end

function switch_grab_script_mode()
	grab_script_mode_index = grab_script_mode_index + 1;
	if grab_script_mode_index > #grab_script_modes then
		grab_script_mode_index = 1;
	end
	grab_script_mode = grab_script_modes[grab_script_mode_index];
end

	---------------
	-- MODEL ONE --
	---------------

object_properties = {
	object_x = 0x70,
	object_y = 0x74,
	object_z = 0x78,
	object_angle = 0x80,
	object_model_pointer = 0xD8;
	object_health = 0x129,
	object_size = 0x12C,
	object_pointer_to_pointer = 0x130,
	object_opacity = 0x138,
	object_anim = 0x13B,
	object_anim_timer = 0x13D,
	object_value = 0x1122,
	object_types = {
		[0x1] = "Mini Roswell",
		[0x2] = "Beaver", -- PG1
		[0x3] = "Billy the Kid",
		[0x4] = "Bob and Number Four",
		[0x5] = "Fatty Roswell",
		[0x6] = "Professor Monkey for a Head",
		[0x7] = "Psycrow",
		[0x8] = "Cow Enemy",
		[0x9] = "Acid Bat",
		[0xA] = "Dynamite Bunny",
		[0xB] = "Cactus",
		[0xC] = "Chick", -- CDE
		[0xD] = "Disco Body",
		[0xE] = "Disco Head",
		[0xF] = "Toilet gun guy", -- VDV
		[0x11] = "Pork Board (Earthworm Kim)",
		[0x12] = "Frog Enemies", -- PG2 Tree Room
		[0x13] = "Pickle",
		[0x14] = "Large Cow", -- Hubs, Boss Worlds
		[0x15] = "Elderly Mobster", -- GBE
		[0x16] = "Hamster", -- CDE
		[0x17] = "Hedgehog", -- CDE/BTBW
		[0x18] = "Vacuum",
		[0x1A] = "Cow", --Main Menu
		[0x1B] = "Robot", -- LOTF
		[0x1C] = "Granny",
		[0x1D] = "Peter the Dog",
		[0x1E] = "Pork Board",
		[0x1F] = "Green Piranha", -- LOTF
		[0x20] = "Orange Piranha", -- DWU
		[0x22] = "Pluckitt",
		[0x23] = "Moosilini",
		[0x24] = "Sheriff",
		[0x25] = "Speaker Enemy",
		[0x26] = "Particle Spawner",
		[0x27] = "Hot Sauce",
		[0x28] = "Agent Crow",
		[0x29] = "Wasps",
		[0x2A] = "Elvis", -- AYHT
	},
};

local function populateObjectM1Pointers()
	object_pointers = {};
	obj1_pointers_start = dereferencePointer(Game.Memory.obj1_pointer_list);
	if isRDRAM (obj1_pointers_start) then
		for object_no = 0, getObjectCount() do
			local pointer = dereferencePointer(obj1_pointers_start + (object_no * 0xC0));
			if isRDRAM(pointer) then
				table.insert(object_pointers, pointer);
			end
		end
	end
	-- Clamp index
	object_index = math.min(object_index, math.max(1, #object_pointers));
end

function getObjectM1Value(pointer)
	modelPtr = dereferencePointer(pointer + object_properties.object_model_pointer);
	if isRDRAM(modelPtr) then
		objectValue = mainmemory.read_u16_be(modelPtr + 0x1122);
	else
		objectValue = 0;
	end
	return objectValue;
end

function getObjectM1NameFromValue(value)
	if type(object_properties.object_types[value]) == 'string' then
		objname = object_properties.object_types[value];
	else
		objname = toHexString(value);
	end
	return objname;
end

local function getExamineM1Data(pointer)
	local examine_data = {};

	if not isRDRAM(pointer) then
		return examine_data;
	end

	local objectPtrPtr = dereferencePointer(pointer + object_properties.object_pointer_to_pointer);
	local objectPointer = dereferencePointer(objectPtrPtr);
	local modelPointer = dereferencePointer(pointer + object_properties.object_model_pointer);
	local xPos = mainmemory.readfloat(pointer + object_properties.object_x, true);
	local yPos = mainmemory.readfloat(pointer + object_properties.object_y, true);
	local zPos = mainmemory.readfloat(pointer + object_properties.object_z, true);
	local hasPosition = hasModel or xPos ~= 0 or yPos ~= 0 or zPos ~= 0;
	local objectVal = getObjectM1Value(pointer)

	table.insert(examine_data, { "Address", toHexString(objectPointer) });
	table.insert(examine_data, { "Object Name", getObjectM1NameFromValue(objectVal) });
	table.insert(examine_data, { "Object Value", toHexString(objectVal) });
	table.insert(examine_data, { "Separator", 1 });
	table.insert(examine_data, { "X", xPos });
	table.insert(examine_data, { "Y", yPos });
	table.insert(examine_data, { "Z", zPos });
	table.insert(examine_data, { "Separator", 1 });
	table.insert(examine_data, { "Angle", mainmemory.read_u16_be(pointer + object_properties.object_angle) });
	table.insert(examine_data, { "Scale", mainmemory.read_u16_be(pointer + object_properties.object_size) });
	table.insert(examine_data, { "Health", mainmemory.readbyte(pointer + object_properties.object_health) });
	table.insert(examine_data, { "Opacity", mainmemory.readbyte(pointer + object_properties.object_opacity) });
	table.insert(examine_data, { "Separator", 1 });
	table.insert(examine_data, { "Model Address", toHexString(modelPointer) });
	table.insert(examine_data, { "Separator", 1 });
	table.insert(examine_data, { "Animation", mainmemory.readbyte(pointer + object_properties.object_anim) });
	table.insert(examine_data, { "Animation Timer", mainmemory.readbyte(pointer + object_properties.object_anim_timer) });

	return examine_data;
end

	---------------
	-- MODEL TWO --
	---------------

object_m2_properties = {
	object_texture_pointer = 0x8;
	object_model_pointer = 0x18;
	object_trait_pointer = 0x1C,
	traits_list = {
		obj_type = 0x0; -- 2 Byte
		opacity = 0xD;
	},
	object_x = 0xA0, -- (8x larger)
	object_y = 0xA4, -- (8x larger)
	object_z = 0xA8, -- (8x larger)
	object_types = {
		[0xB] = "Rocket Launcher/Marble/Pp Can", -- Pickup
		[0x32] = "Udder",
		[0x34] = "Bunny Land mine", -- DWU
		[0x3E] = "Text Trigger", -- DWU Gravestones, BNotLD Grannies
		[0x40] = "Vending Machine", -- Rocket Launcher
		[0x42] = "Statue", -- DWU
		[0x5A] = "Snott",
	},
};

local function getObjectM2Count()
	return math.min(65535, mainmemory.read_u16_be(Game.Memory.object_m2_count) - 1);
end

local function populateObjectM2Pointers()
	object_pointers = {};
	obj2_pointers_start = dereferencePointer(Game.Memory.obj2_pointer_list);
	if isRDRAM (obj2_pointers_start) then
		for object_no = 0, getObjectM2Count() do
			local pointer = dereferencePointer(obj2_pointers_start + (object_no * 0x4));
			if isRDRAM(pointer) then
				table.insert(object_pointers, pointer);
			end
		end
	end
	-- Clamp index
	object_index = math.min(object_index, math.max(1, #object_pointers));
end

function getObjectM2Value(pointer)
	traitPtr = dereferencePointer(pointer + object_m2_properties.object_trait_pointer);
	local hasTrait = traitPtr ~= nil;
	if hasTrait then
		objectM2Value = mainmemory.read_u16_be(traitPtr + object_m2_properties.traits_list.obj_type);
	else
		objectM2Value = 0;
	end
	return objectM2Value;
end

function getObjectM2NameFromValue(value)
	if type(object_m2_properties.object_types[value]) == 'string' then
		objname = object_m2_properties.object_types[value];
	else
		objname = toHexString(value);
	end
	return objname;
end

local function getExamineM2Data(pointer)
	local examine_data = {};

	if not isRDRAM(pointer) then
		return examine_data;
	end

	local xPos = mainmemory.readfloat(pointer + object_m2_properties.object_x, true) / 8;
	local yPos = mainmemory.readfloat(pointer + object_m2_properties.object_y, true) / 8;
	local zPos = mainmemory.readfloat(pointer + object_m2_properties.object_z, true) / 8;
	local hasPosition = hasModel or xPos ~= 0 or yPos ~= 0 or zPos ~= 0;

	local traitPointer = dereferencePointer(pointer + object_m2_properties.object_trait_pointer);
	local texturePointer = dereferencePointer(pointer + object_m2_properties.object_texture_pointer);
	local modelPointer = dereferencePointer(pointer + object_m2_properties.object_model_pointer);
	local hasTrait = traitPointer ~= nil;
	local objectM2Val = getObjectM2Value(pointer)

	table.insert(examine_data, { "Address", toHexString(pointer) });
	table.insert(examine_data, { "Object Name", getObjectM2NameFromValue(objectM2Val) });
	table.insert(examine_data, { "Object Value", toHexString(objectM2Val) });
	table.insert(examine_data, { "Separator", 1 });
	table.insert(examine_data, { "Trait Pointer", toHexString(traitPointer) });
	table.insert(examine_data, { "Texture Pointer", toHexString(texturePointer) });
	table.insert(examine_data, { "Model Pointer", toHexString(modelPointer) });
	table.insert(examine_data, { "Separator", 1 });
	table.insert(examine_data, { "X", xPos });
	table.insert(examine_data, { "Y", yPos });
	table.insert(examine_data, { "Z", zPos });
	table.insert(examine_data, { "Separator", 1 });

	if hasTrait then
		local objAnimTimer = mainmemory.readbyte(traitPointer + object_m2_properties.traits_list.opacity); -- Not entirely sure. Opacity for Snott, Anim Timer for Udder?
		table.insert(examine_data, { "Animation Timer", objAnimTimer });
	end
	return examine_data;
end

local function drawGrabScriptUI()
	if grab_script_mode == "Disabled" then
		return;
	end

	local gui_x = 32;
	local gui_y = 32;
	local row = 0;
	local height = 16;

	gui.text(gui_x, gui_y + height * row, "Mode: "..grab_script_mode, nil, 'bottomright');
	row = row + 1;

	if string.contains(grab_script_mode, "Model 1") then
		populateObjectM1Pointers();
	elseif string.contains(grab_script_mode, "Model 2") then
		populateObjectM2Pointers();
	end

	gui.text(gui_x, gui_y + height * row, "Index: "..object_index.."/"..#object_pointers, nil, 'bottomright');
	row = row + 1;
	gui.text(gui_x, gui_y + height * row, "Page: "..(page_pos).."/"..(page_total), nil, 'bottomright');
	row = row + 1;
	row = row + 1;

	-- Clamp index to number of objects
	if #object_pointers > 0 and object_index > #object_pointers then
		object_index = #object_pointers;
	end

	if #object_pointers > 0 and object_index <= #object_pointers then
		if string.contains(grab_script_mode, "Examine") then
			local examine_data = {};
			if grab_script_mode == "Examine (Model 1)" then
				examine_data = getExamineM1Data(object_pointers[object_index]);
			elseif  grab_script_mode == "Examine (Model 2)" then
				examine_data = getExamineM2Data(object_pointers[object_index]);
			end

			pagifyThis(examine_data,40);

			for i = page_finish, page_start + 1, -1 do
				if examine_data[i][1] ~= "Separator" then
					if type(examine_data[i][2]) == "number" then
						examine_data[i][2] = round(examine_data[i][2], precision);
					end
					gui.text(gui_x, gui_y + height * row, examine_data[i][1]..": "..examine_data[i][2], nil, 'bottomright');
					row = row + 1;
				else
					row = row + examine_data[i][2];
				end
			end
		end

		if string.contains(grab_script_mode, "List") then
			row = row + 1;
			pagifyThis(object_pointers,40);
			for i = page_finish, page_start + 1, -1 do
				local color = nil;
				if object_index == i then
					color = colors.yellow;
				end
				if object_pointers[i] == playerObject then
					color = colors.green;
				end

				if string.contains(grab_script_mode, "Model 1") then
					local objectVal = getObjectM1Value(object_pointers[i] or 0)
					gui.text(gui_x, gui_y + height * row, i..": "..toHexString(object_pointers[i] or 0, 6).." ("..getObjectM1NameFromValue(objectVal)..")", color, 'bottomright');
				elseif string.contains(grab_script_mode, "Model 2") then
					local objectVal = getObjectM2Value(object_pointers[i] or 0)
					gui.text(gui_x, gui_y + height * row, i..": "..toHexString(object_pointers[i] or 0, 6).." ("..getObjectM2NameFromValue(objectVal)..")", color, 'bottomright');
				end
				row = row + 1;
			end
		end
	end
end

function zipToSelectedObject()
	local desiredX, desiredY, desiredZ;
	local selectedObject = object_pointers[object_index];
	if isRDRAM(selectedObject) then
		-- Get selected object X,Y,Z position
		if string.contains(grab_script_mode, "Model 1") then
			desiredX = mainmemory.readfloat(selectedObject + object_properties.object_x, true);
			desiredY = mainmemory.readfloat(selectedObject + object_properties.object_y, true);
			desiredZ = mainmemory.readfloat(selectedObject + object_properties.object_z, true);
		elseif string.contains(grab_script_mode, "Model 2") then
			desiredX = mainmemory.readfloat(selectedObject + object_m2_properties.object_x, true) / 8;
			desiredY = mainmemory.readfloat(selectedObject + object_m2_properties.object_y, true) / 8;
			desiredZ = mainmemory.readfloat(selectedObject + object_m2_properties.object_z, true) / 8;
		end
	end

	-- Update player position
	if type(desiredX) == "number" and type(desiredY) == "number" and type(desiredZ) == "number" then
		Game.setPosition(desiredX, desiredY, desiredZ);
	end
end

----------------
-- Flag Stuff --
----------------

flag_block_size = 0x438; -- D34 max
flag_Array = {};

function getFlagTypeCount(flagType)
	flag_type_count = 0
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then -- is a documented flag
			if flagBlock[i]["type"] == flagType then
				flag_type_count = flag_type_count + 1;
			end
		end
	end
	return flag_type_count;
end

function getFlagsKnown()
	flag_count = 0
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then -- is a documented flag
			flag_count = flag_count + 1;
		end
	end
	return flag_count;
end

function getFlagsTotal()
	return flag_block_size / 8;
end

function getFlagArray()
	flag_start = dereferencePointer(Game.Memory.flag_pointer);
	if isRDRAM(flag_start) then
		for i = 1, flag_block_size do
			flag_Array[i] = mainmemory.readbyte(flag_start + i);
		end
	end
end

function checkFlagArray()
	flag_start = dereferencePointer(Game.Memory.flag_pointer);
	currentFrame = emu.framecount();
	if isRDRAM(flag_start) then
		if flag_Array[1] ~= nil then -- flag array populated
			for i = 1, flag_block_size do
				currentFlagState = mainmemory.readbyte(flag_start + i);
				if flagBlock[i] ~= nil then
					flag_name = flagBlock[i]["name"];
				else
					flag_name = "Unknown ("..toHexString(i)..")";
				end
				if flag_Array[i] ~= currentFlagState then -- Flag has changed states
					if currentFlagState == 1 then
						print("'"..flag_name.."' has been SET on frame "..currentFrame);
					else
						print("'"..flag_name.."' has been CLEARED on frame "..currentFrame);
					end
				end
			end
		end
	end
end

function checkFlag(offset)
	flag_start = dereferencePointer(Game.Memory.flag_pointer);
	if isRDRAM(flag_start) then
		flag_state = mainmemory.readbyte(flag_start + offset);
		if flag_state == 1 then
			print("Flag: '"..flagBlock[offset]["name"].."' is SET");
		else
			print("Flag: '"..flagBlock[offset]["name"].."' is NOT SET");
		end
	end
end

function setFlag(offset)
	flag_start = dereferencePointer(Game.Memory.flag_pointer);
	if isRDRAM(flag_start) then
		mainmemory.writebyte(flag_start + offset,1);
		if flagBlock[offset] ~= nil then
			flag_name = flagBlock[offset]["name"]
		else
			flag_name = "Unknown ("..toHexString(offset)..")"
		end
		print("Set flag '"..flag_name.."'");
	end
end

function clearFlag(offset)
	flag_start = dereferencePointer(Game.Memory.flag_pointer);
	if isRDRAM(flag_start) then
		mainmemory.writebyte(flag_start + offset,0);
		if flagBlock[offset] ~= nil then
			flag_name = flagBlock[offset]["name"]
		else
			flag_name = "Unknown ("..toHexString(offset)..")"
		end
		print("Cleared flag '"..flag_name.."'");
	end
end

function setFlagByName(name_string)
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then
			if flagBlock[i]["name"] == name_string then
				setFlag(i);
			end
		end
	end
end

function clearFlagByName(name_string)
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then
			if flagBlock[i]["name"] == name_string then
				clearFlag(i);
			end
		end
	end
end

function checkFlagByName(name_string)
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then
			if flagBlock[i]["name"] == name_string then
				checkFlag(i);
			end
		end
	end
end

function setFlagsByType(type_string)
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then
			if flagBlock[i]["type"] == type_string then
				setFlag(i);
			end
		end
	end
end

function clearFlagsByType(type_string)
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then
			if flagBlock[i]["type"] == type_string then
				checkFlag(i);
			end
		end
	end
end

local function formatOutputString(caption, value, max)
	return caption..value.."/"..max.." or "..round(value / max * 100, 2).."%";
end

function flagStats()
	local udders_known = getFlagTypeCount("Udder");
	local udders_total = 74;
	local flags_known = getFlagsKnown();
	local flags_total = getFlagsTotal();

	dprint("Block size: "..toHexString(flag_block_size));
	dprint(formatOutputString("Flags known: ", flags_known, flags_total));
	dprint(formatOutputString("Udders: ", udders_known, udders_total));
	dprint("");
	print_deferred();
end

function getFlagNameArray()
	flagNameBlock = {}
	j = 0;
	for i = 1, flag_block_size do
		if flagBlock[i] ~= nil then
			j = j + 1;
			flagNameBlock[j] = flagBlock[i]["name"];
		end
	end
	return flagNameBlock;
end

local function flagSetButtonHandler()
	setFlagByName(forms.getproperty(ScriptHawk.UI.form_controls["Flag Dropdown"], "SelectedItem"));
end

local function flagClearButtonHandler()
	clearFlagByName(forms.getproperty(ScriptHawk.UI.form_controls["Flag Dropdown"], "SelectedItem"));
end

local function flagCheckButtonHandler()
	checkFlagByName(forms.getproperty(ScriptHawk.UI.form_controls["Flag Dropdown"], "SelectedItem"));
end

flagBlock = {
	[0x018] = {name = "DWU: Stone Door Open", type = "Physical"},
	[0x040] = {name = "BTBW: Crow in final position", type = "Physical"},
	[0x070] = {name = "LOTF: Talked to King Gherkin", type = "Physical"},
	[0x078] = {name = "PG1: First Wall Cleared", type = "Physical"},
	[0x080] = {name = "PG1: Chicken Gauntlet Defeated", type = "Physical"},
	[0x098] = {name = "CDE: Barn Door Open", type = "Physical"},
	[0x0A8] = {name = "AYHT: Elevator Lasers Lowered", type = "Physical"},
	[0x130] = {name = "Brain: CDE Open", type = "Physical"},
	[0x138] = {name = "Brain: Happiness Hub Snott Spawned", type = "Physical"},
	[0x150] = {name = "Have all udders", type = "Check"},
	[0x160] = {name = "Brain: Snott FTT", type = "FTT"},
	[0x1B0] = {name = "Brain: Earthworm Kim Open", type = "Physical"},
	[0x1C0] = {name = "DWU: Rabbit Hole Udder", type = "Udder"},
	[0x1C8] = {name = "DWU: Gravestones Udder", type = "Udder"},
	[0x1D0] = {name = "DWU: Medallion Udder", type = "Udder"},
	[0x1D8] = {name = "DWU: Quicksand Udder", type = "Udder"},
	[0x1E0] = {name = "DWU: Statues Udder", type = "Udder"},
	[0x1F0] = {name = "DWU: Blue Balloon Udder", type = "Udder"},
	[0x1F8] = {name = "PG1: Beaver Head Udder", type = "Udder"},
	[0x200] = {name = "PG1: Painting Room Udder", type = "Udder"},
	[0x208] = {name = "PG1: Furniture Room Udder", type = "Udder"},
	[0x210] = {name = "PG1: Vacuum Udder", type = "Udder"},
	[0x218] = {name = "PG1: Chicken Gauntlet Udder", type = "Udder"},
	[0x220] = {name = "BNotLD: Boom Box Udder", type = "Udder"},
	[0x228] = {name = "BNotLD: Zombie Heads Udder", type = "Udder"},
	[0x230] = {name = "BNotLD: Manhole Udder", type = "Udder"},
	[0x238] = {name = "BNotLD: Speaker Towers Udder", type = "Udder"},
	[0x240] = {name = "BNotLD: Sewers Udder", type = "Udder"},
	[0x248] = {name = "GBE: Ice Block Udder", type = "Udder"},
	[0x250] = {name = "GBE: Bank Udder", type = "Udder"},
	[0x258] = {name = "GBE: Sheriff Udder", type = "Udder"},
	[0x260] = {name = "GBE: Bottle Udder", type = "Udder"},
	[0x268] = {name = "GBE: Granny Herding Udder", type = "Udder"},
	[0x270] = {name = "GBE: Bingo Udder", type = "Udder"},
	[0x278] = {name = "BTBW: Bootcamp Udder", type = "Udder"},
	[0x280] = {name = "BTBW: Camera Udder", type = "Udder"},
	[0x288] = {name = "BTBW: Barn Door Udder", type = "Udder"},
	[0x290] = {name = "BTBW: Crow Udder", type = "Udder"},
	[0x298] = {name = "BTBW: Kill Pluckitt Udder", type = "Udder"},
	-- 0x2A0 - Udder
	-- 0x2A8 - Udder
	[0x2B0] = {name = "BTBW: Blue Balloon Udder", type = "Udder"},
	-- 0x2B8
	[0x2C0] = {name = "CDE: Fridges Udder", type = "Udder"},
	[0x2C8] = {name = "CDE: Underpants Udder", type = "Udder"},
	[0x2D0] = {name = "CDE: Bomb Room Udder", type = "Udder"},
	-- 0x2D8
	[0x2E0] = {name = "AYHT: Elevator Udder", type = "Udder"},
	[0x2E8] = {name = "AYHT: Bean Room Udder", type = "Udder"},
	[0x2F0] = {name = "AYHT: Pan Room Udder", type = "Udder"},
	[0x2F8] = {name = "AYHT: Elvis Udder", type = "Udder"},
	[0x300] = {name = "VDV: Hidden Udder", type = "Udder"},
	[0x308] = {name = "VDV: Bean Room Udder", type = "Udder"},
	[0x310] = {name = "VDV: Ice Cream Udder", type = "Udder"},
	[0x318] = {name = "VDV: Kill Grannies Udder", type = "Udder"},
	[0x320] = {name = "VDV: Granny Herding Udder", type = "Udder"},
	[0x328] = {name = "BTBW: Swamp Udder", type = "Udder"},
	[0x330] = {name = "PG2: Vacuum Udder", type = "Udder"},
	[0x338] = {name = "PG2: Chicken Udder", type = "Udder"},
	[0x340] = {name = "PG2: Painting Room Udder", type = "Udder"},
	[0x348] = {name = "PG2: Library Udder", type = "Udder"},
	[0x350] = {name = "PG2: Blue Balloon Udder", type = "Udder"},
	[0x358] = {name = "LOTF: Blue Balloon Udder", type = "Udder"},
	[0x360] = {name = "LOTF: Central Tree Udder", type = "Udder"},
	[0x368] = {name = "LOTF: Tall Platform Udder", type = "Udder"},
	[0x370] = {name = "LOTF: King Gherkin Udder", type = "Udder"},
	[0x378] = {name = "LOTF: Potatoes Udder", type = "Udder"},
	-- 0x380
	[0x388] = {name = "AYHT: Blue Balloon Udder", type = "Udder"},
	[0x390] = {name = "Brain: Peter Udder", type = "Udder"},
	[0x398] = {name = "Psycrow: Udder (1)", type = "Udder"},
	[0x3A0] = {name = "Psycrow: Udder (2)", type = "Udder"},
	[0x3A8] = {name = "Psycrow: Udder (3)", type = "Udder"},
	[0x3B0] = {name = "Psycrow: Udder (4)", type = "Udder"},
	[0x3B8] = {name = "Psycrow: Udder (5)", type = "Udder"},
	[0x3C0] = {name = "Bob and No. 4: Udder (1)", type = "Udder"},
	[0x3C8] = {name = "Bob and No. 4: Udder (2)", type = "Udder"},
	[0x3D0] = {name = "Bob and No. 4: Udder (3)", type = "Udder"},
	[0x3D8] = {name = "Bob and No. 4: Udder (4)", type = "Udder"},
	[0x3E0] = {name = "Bob and No. 4: Udder (5)", type = "Udder"},
	[0x3E8] = {name = "PMFAH: Udder (1)", type = "Udder"},
	[0x3F0] = {name = "PMFAH: Udder (2)", type = "Udder"},
	[0x3F8] = {name = "PMFAH: Udder (3)", type = "Udder"},
	[0x400] = {name = "PMFAH: Udder (4)", type = "Udder"},
	[0x408] = {name = "PMFAH: Udder (5)", type = "Udder"},
	[0x410] = {name = "Fatty Roswell: Udder (1)", type = "Udder"},
	[0x418] = {name = "Fatty Roswell: Udder (2)", type = "Udder"},
	[0x420] = {name = "Fatty Roswell: Udder (3)", type = "Udder"},
	[0x428] = {name = "Fatty Roswell: Udder (4)", type = "Udder"},
	[0x430] = {name = "Fatty Roswell: Udder (5)", type = "Udder"},
	[0x438] = {name = "VDV: Blue Balloon Udder", type = "Udder"},
};

ScriptHawk.bindKeyRealtime("N", decrementObjectIndex, true);
ScriptHawk.bindKeyRealtime("M", incrementObjectIndex, true);
ScriptHawk.bindKeyRealtime("Z", zipToSelectedObject, true);
ScriptHawk.bindKeyRealtime("H", decrementPage, true);
ScriptHawk.bindKeyRealtime("J", incrementPage, true);
ScriptHawk.bindKeyRealtime("C", switch_grab_script_mode, true);

local labelValue = 0;
function Game.initUI()
	if not TASSafe then
		ScriptHawk.UI.button(5, 4, {4, 10}, nil, "Reload Map (Soft)", "Reload Map", Game.reloadMap);
		ScriptHawk.UI.button(10, 0, {4, 10}, nil, "Reload Map (Hard)", "Hard Reload", Game.reloadMapHard);
		ScriptHawk.UI.button(10, 1, {4, 10}, nil, "Kill Boss", "Kill Boss", Game.killBoss);
		ScriptHawk.UI.checkbox(5, 5, "OoB Timer Checkbox", "OoB Timer Off");
		ScriptHawk.UI.checkbox(5, 6, "Free Roam Mode", "Free Roam Mode");
		ScriptHawk.UI.button(10, 4, {4, 10}, nil, "Console Mode Switch", "Emulator Mode", Game.toggleConsoleMode);

		ScriptHawk.UI.button(10, 7, {46}, nil, "Set Flag Button", "Set", flagSetButtonHandler);
		ScriptHawk.UI.button(12, 7, {46}, nil, "Check Flag Button", "Check", flagCheckButtonHandler);
		ScriptHawk.UI.button(14, 7, {46}, nil, "Clear Flag Button", "Clear", flagClearButtonHandler);
	else
		-- Use a bigger check flags button if the others are hidden by TASSafe
		ScriptHawk.UI.button(10, 7, {4, 10}, nil, "Check Flag Button", "Check Flag", flagCheckButtonHandler);
	end

	getFlagNameArray();
	ScriptHawk.UI.form_controls["Flag Dropdown"] = forms.dropdown(ScriptHawk.UI.options_form, flagNameBlock, ScriptHawk.UI.col(0) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.row(7) + ScriptHawk.UI.dropdown_offset, ScriptHawk.UI.col(9) + 8, ScriptHawk.UI.button_height);
	ScriptHawk.UI.checkbox(10, 6, "realtime_flags", "Realtime Flags", true);
	flagStats();
end

function Game.drawUI()
	drawGrabScriptUI();
end

function Game.realTime()
--	if ScriptHawk.UI.ischecked("Fix Input Bug") then
--		Game.fixInputBug();
--	end
	Game.getConsoleMode();
end

function Game.eachFrame()
	if ScriptHawk.UI.ischecked("OoB Timer Checkbox") then
		Game.FreezeOoBTimer();
	end

	if ScriptHawk.UI.ischecked("Free Roam Mode") then
		Game.freeroamEnabled();
	else
		Game.freeroamDisabled();
	end

	Game.applyConsoleSettings();
	if ScriptHawk.UI.ischecked("realtime_flags") then
		checkFlagArray();
		getFlagArray();
	end
end

Game.OSD = {
	{"Map", Game.getMapOSD, category="mapData"},
	{"Exit", Game.getExitOSD, category="mapData"},
	{"Separator"},
	{"X", category="position"},
	{"Y", category="position"},
	{"Z", category="position"},
	{"Separator"},
	{"dY", category="positionStats"},
	{"dXZ", category="positionStats"},
	{"Separator"},
	{"Max dY", category="positionStatsMore"},
	{"Max dXZ", category="positionStatsMore"},
	{"Odometer", category="positionStatsMore"},
	{"Separator"},
	--{"Rot. X", Game.getXRotation, category="angleMore"},
	{"Floor", Game.getFloor, category="position"},
	{"Animation", Game.getAnimationOSD, category="animation"},
	{"Animation Timer", Game.getAnimationTimerOSD, category="animation"},
	{"Movement", Game.getMovementOSD, category="movement"},
	{"Facing", Game.getYRotation, category="angle"},
	--{"Rot. Z", Game.getZRotation, category="angleMore"},
	{"Separator"},
	{"Marble Count", Game.getMarbleCount, category="marbleCount"},
};

return Game;