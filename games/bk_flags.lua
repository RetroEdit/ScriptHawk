local flag_array = {
--Mumbo Tokens
	{["name"] = "MM: MT: By Conga", 			["index"] = 0x01,	["type"] = "MT" },
	{["name"] = "MM: MT: Behind Ruins",			["index"] = 0x02,	["type"] = "MT" },
	{["name"] = "MM: MT: Mumbos Hut Ramp",		["index"] = 0x03,	["type"] = "MT" },
	{["name"] = "MM: MT: By Purple Jinjo", 		["index"] = 0x04,	["type"] = "MT" },
	{["name"] = "MM: MT: Ticker Tower", 		["index"] = 0x05,	["type"] = "MT" },
	{["name"] = "TTC: MT: In Ship",		 		["index"] = 0x06,	["type"] = "MT" },
	{["name"] = "TTC: MT: In Lockup 1",			["index"] = 0x07,	["type"] = "MT" },
	{["name"] = "TTC: MT: In Lockup 2",			["index"] = 0x08,	["type"] = "MT" },
	{["name"] = "TTC: MT: Ship Mast",			["index"] = 0x09,	["type"] = "MT" },
	{["name"] = "TTC: MT: Lighthouse",			["index"] = 0x0A,	["type"] = "MT" },
	{["name"] = "TTC: MT: Floating Box",		["index"] = 0x0B,	["type"] = "MT" },
	{["name"] = "TTC: MT: By Last X",			["index"] = 0x0C,	["type"] = "MT" },
	{["name"] = "TTC: MT: Pool",				["index"] = 0x0D,	["type"] = "MT" },
	{["name"] = "TTC: MT: Shock Spring Pad",	["index"] = 0x0E,	["type"] = "MT" },
	{["name"] = "TTC: MT: Behind Nipper",		["index"] = 0x0F,	["type"] = "MT" },
	{["name"] = "CC: MT: Tail Chompa",			["index"] = 0x10,	["type"] = "MT" },
	{["name"] = "CC: MT:Above World Exit",		["index"] = 0x11,	["type"] = "MT" },
	{["name"] = "CC: MT:Underwater Alcove",		["index"] = 0x12,	["type"] = "MT" },
	{["name"] = "CC: MT:Window",				["index"] = 0x13,	["type"] = "MT" },
	{["name"] = "CC: MT:Clanker's Mouth",		["index"] = 0x14,	["type"] = "MT" },
	{["name"] = "BGS: MT: Under Mud Huts 1",	["index"] = 0x15,	["type"] = "MT" },
	{["name"] = "BGS: MT: Under Mud Huts 2",	["index"] = 0x16,	["type"] = "MT" },
	{["name"] = "BGS: MT: Above Cattail",		["index"] = 0x17,	["type"] = "MT" },
	{["name"] = "BGS: MT: By Yellow Jinjo",		["index"] = 0x18,	["type"] = "MT" },
	{["name"] = "BGS: MT: Above Mud Huts",		["index"] = 0x19,	["type"] = "MT" },
	{["name"] = "BGS: MT: Behind Mumbo's",		["index"] = 0x1A,	["type"] = "MT" },
	{["name"] = "BGS: MT: Elevated Walkway",	["index"] = 0x1B,	["type"] = "MT" },
	{["name"] = "BGS: MT: In Tanktup",			["index"] = 0x1C,	["type"] = "MT" },
	{["name"] = "BGS: MT: Mr. Vile",			["index"] = 0x1D,	["type"] = "MT" },
	{["name"] = "BGS: MT: In Mumbo's",			["index"] = 0x1E,	["type"] = "MT" },
	{["name"] = "FP: MT: Snowman Leg 1",		["index"] = 0x1F,	["type"] = "MT" },
	{["name"] = "FP: MT: Snowman Leg 2m",		["index"] = 0x20,	["type"] = "MT" },
	{["name"] = "FP: MT: Present Stack",		["index"] = 0x21,	["type"] = "MT" },
	{["name"] = "FP: MT: Chimney Fly Pad",		["index"] = 0x22,	["type"] = "MT" },
	{["name"] = "FP: MT: Sir Slush Island",		["index"] = 0x23,	["type"] = "MT" },
	{["name"] = "FP: MT: Sir Slush Present",	["index"] = 0x24,	["type"] = "MT" },
	{["name"] = "FP: MT: Xmas Tree Base",		["index"] = 0x25,	["type"] = "MT" },
	{["name"] = "FP: MT: Scarf Sled",			["index"] = 0x26,	["type"] = "MT" },
	{["name"] = "FP: MT: Water By Wozza",		["index"] = 0x27,	["type"] = "MT" },
	{["name"] = "FP: MT: In Boggy's Igloo",		["index"] = 0x28,	["type"] = "MT" },
	{["name"] = "GV: MT: Jinxy's Nose",			["index"] = 0x29,	["type"] = "MT" },
	{["name"] = "GV: MT: In Sand By Jinxy",		["index"] = 0x2A,	["type"] = "MT" },
	{["name"] = "GV: MT: Moat",					["index"] = 0x2B,	["type"] = "MT" },
	{["name"] = "GV: MT: Over Maze Pyramid",	["index"] = 0x2C,	["type"] = "MT" },
	{["name"] = "GV: MT: Water Temple Door",	["index"] = 0x2D,	["type"] = "MT" },
	{["name"] = "GV: MT: Matching Pyramid",		["index"] = 0x2E,	["type"] = "MT" },
	{["name"] = "GV: MT: In Maze Pyramid",		["index"] = 0x2F,	["type"] = "MT" },
	{["name"] = "GV: MT: In Water Pyramid",		["index"] = 0x30,	["type"] = "MT" },
	{["name"] = "GV: MT: Rubee's Pyramid",		["index"] = 0x31,	["type"] = "MT" },
	{["name"] = "GV: MT: In Jinxy",				["index"] = 0x32,	["type"] = "MT" },
	{["name"] = "MMM: MT: By Fountain",			["index"] = 0x33,	["type"] = "MT" },
	{["name"] = "MMM: MT: By Tumblar Shed",		["index"] = 0x34,	["type"] = "MT" },
	{["name"] = "MMM: MT: Church Roof",			["index"] = 0x35,	["type"] = "MT" },
	{["name"] = "MMM: MT: Hedges By Ramp",		["index"] = 0x36,	["type"] = "MT" },
	{["name"] = "MMM: MT: Hedge Maze",			["index"] = 0x37,	["type"] = "MT" },
	{["name"] = "MMM: MT: Cemetary",			["index"] = 0x38,	["type"] = "MT" }, 
	{["name"] = "MMM: MT: In Fountain Whip",	["index"] = 0x39,	["type"] = "MT" },
	{["name"] = "MMM: MT: Church Rafters",		["index"] = 0x3A,	["type"] = "MT" },
	{["name"] = "MMM: MT: Organ Stool",			["index"] = 0x3B,	["type"] = "MT" },
	{["name"] = "MMM: MT: Tumblar Shed Roof",	["index"] = 0x3C,	["type"] = "MT" },
	{["name"] = "MMM: MT: Cellar/Loggo",		["index"] = 0x3D,	["type"] = "MT" },
	{["name"] = "MMM: MT: Dinning Room",		["index"] = 0x3E,	["type"] = "MT" },
	{["name"] = "MMM: MT: Well",				["index"] = 0x3F,	["type"] = "MT" },
	{["name"] = "MMM: MT: Bedroom",				["index"] = 0x40,	["type"] = "MT" },
	{["name"] = "MMM: MT: Bathroom",			["index"] = 0x41,	["type"] = "MT" }, 
	{["name"] = "RBB: MT: Top Of Funnel",		["index"] = 0x42,	["type"] = "MT" },
	{["name"] = "RBB: MT: Front Of Ship",		["index"] = 0x43,	["type"] = "MT" },
	{["name"] = "RBB: MT: Lifeboat",			["index"] = 0x44,	["type"] = "MT" },
	{["name"] = "RBB: MT: Above Tollway",		["index"] = 0x45,	["type"] = "MT" },
	{["name"] = "RBB: MT: Toxic Pool",			["index"] = 0x46,	["type"] = "MT" },
	{["name"] = "RBB: MT: In front Of Chompa",	["index"] = 0x47,	["type"] = "MT" },
	{["name"] = "RBB: MT: Left Container",		["index"] = 0x48,	["type"] = "MT" },
	{["name"] = "RBB: MT: Middle Container",	["index"] = 0x49,	["type"] = "MT" },
	{["name"] = "RBB: MT: Crew Cabin",			["index"] = 0x4A,	["type"] = "MT" },
	{["name"] = "RBB: MT: Navigation Room",		["index"] = 0x4B,	["type"] = "MT" },
	{["name"] = "RBB: MT: Kitchen Oven",		["index"] = 0x4C,	["type"] = "MT" },
	{["name"] = "RBB: MT: Engine Room Left",	["index"] = 0x4D,	["type"] = "MT" },
	{["name"] = "RBB: MT: Engine Room Right",	["index"] = 0x4E,	["type"] = "MT" },
	{["name"] = "RBB: MT: Engine Room Mid",		["index"] = 0x4F,	["type"] = "MT" },
	{["name"] = "RBB: MT: Store Room",			["index"] = 0x50,	["type"] = "MT" },
	{["name"] = "Lair: MT: Purple Cauldron",	["index"] = 0x51,	["type"] = "MT" },
	{["name"] = "Lair: MT: By CCW Puzzle",		["index"] = 0x52,	["type"] = "MT" },
	{["name"] = "Lair: MT: Red Cauldron",		["index"] = 0x53,	["type"] = "MT" },
	{["name"] = "Lair: MT: Above CC Entrance",	["index"] = 0x54,	["type"] = "MT" },
	{["name"] = "Lair: MT: Behind GV Coffin",	["index"] = 0x55,	["type"] = "MT" },
	{["name"] = "Lair: MT: Advent Calendar",	["index"] = 0x56,	["type"] = "MT" },
	{["name"] = "Lair: MT: In Crypt",			["index"] = 0x57,	["type"] = "MT" },
	{["name"] = "Lair: MT: 640 Note Door",		["index"] = 0x58,	["type"] = "MT" },
	{["name"] = "Lair: MT: RBB Entrance",		["index"] = 0x59,	["type"] = "MT" },
	{["name"] = "Lair: MT: MMM Puzzle",			["index"] = 0x5A,	["type"] = "MT" },
	{["name"] = "CCW: MT: Spring House",		["index"] = 0x5B,	["type"] = "MT" },
	{["name"] = "CCW: MT: Spring Low Branch",	["index"] = 0x5C,	["type"] = "MT" },
	--0x5D Unused. Supposed to be brambles or eeyrie???
	{["name"] = "CCW: MT: Spring Brambles/Eeyrie",	["index"] = 0x5E,	["type"] = "MT" },
	{["name"] = "CCW: MT: Spring Garden Snare",	["index"] = 0x5F,	["type"] = "MT" },
	{["name"] = "CCW: MT: Spring Entrance",		["index"] = 0x60,	["type"] = "MT" },
	{["name"] = "CCW: MT: Spring Hive",			["index"] = 0x61,	["type"] = "MT" },
	{["name"] = "CCW: MT: Nabnut's House",		["index"] = 0x62,	["type"] = "MT" },
	{["name"] = "CCW: MT: Summer Eeyrie",		["index"] = 0x63,	["type"] = "MT" },
	{["name"] = "CCW: MT: Summer Garden Corner",	["index"] = 0x64,	["type"] = "MT" },
	{["name"] = "CCW: MT: Summer Bramble Snare",	["index"] = 0x65,	["type"] = "MT" },
	{["name"] = "CCW: MT: Summer Low Branch",	["index"] = 0x66,	["type"] = "MT" },
	{["name"] = "CCW: MT: Summer Gnawty's",		["index"] = 0x67,	["type"] = "MT" },
	{["name"] = "CCW: MT: Summer Leaf Jumps",	["index"] = 0x68,	["type"] = "MT" },
	{["name"] = "CCW: MT: Summer In Mumbo's",	["index"] = 0x69,	["type"] = "MT" },
	{["name"] = "CCW: MT: Autumn Leaf Jumps",	["index"] = 0x6A,	["type"] = "MT" },
	{["name"] = "CCW: MT: Autumn Entrance",		["index"] = 0x6B,	["type"] = "MT" },
	{["name"] = "CCW: MT: Autumn Top",			["index"] = 0x6C,	["type"] = "MT" },
	{["name"] = "CCW: MT: Autumn By House",		["index"] = 0x6C,	["type"] = "MT" },
	{["name"] = "CCW: MT: Autumn Low Branch",	["index"] = 0x6E,	["type"] = "MT" },
	{["name"] = "CCW: MT: Winter Flower",		["index"] = 0x70,	["type"] = "MT" },
	{["name"] = "CCW: MT: Winter River Fly Pad",	["index"] = 0x70,	["type"] = "MT" },
	{["name"] = "CCW: MT: Winter Hive",			["index"] = 0x71,	["type"] = "MT" },
	{["name"] = "CCW: MT: Winter Nabnut",		["index"] = 0x72,	["type"] = "MT" },
	{["name"] = "CCW: MT: Winter Sir Slush",	["index"] = 0x73,	["type"] = "MT" },
	
--HoneyCombs
	{["name"] = "MM: H: Hill",				["index"] = 0x01,	["type"] = "H" },
	{["name"] = "MM: H: JuJu",				["index"] = 0x02,	["type"] = "H" },
	{["name"] = "TTC: H: Underwater",		["index"] = 0x03,	["type"] = "H" },
	{["name"] = "TTC: H: Floating Box",		["index"] = 0x04,	["type"] = "H" },
	{["name"] = "CC: H: Underwater",		["index"] = 0x05,	["type"] = "H" },
	{["name"] = "CC: H: Above Water",		["index"] = 0x06,	["type"] = "H" },
	{["name"] = "BGS: H: In Mumbo's",		["index"] = 0x07,	["type"] = "H" },
	{["name"] = "BGS: H: In Tanktup",		["index"] = 0x08,	["type"] = "H" },
	{["name"] = "FP: H: In Wozza's Cave",	["index"] = 0x09,	["type"] = "H" },
	{["name"] = "FP: H: Sir Slush",			["index"] = 0x0A,	["type"] = "H" },
	{["name"] = "GV: H: Cactus",			["index"] = 0x0B,	["type"] = "H" },
	{["name"] = "GV: H: Gobi 3",			["index"] = 0x0C,	["type"] = "H" },
	{["name"] = "CCW: H: Gnawty's",			["index"] = 0x0D,	["type"] = "H" },
	{["name"] = "CCW: H: Nabnut's",			["index"] = 0x0E,	["type"] = "H" },
	{["name"] = "RBB: H: Boat House",		["index"] = 0x0F,	["type"] = "H" },
	{["name"] = "RBB: H: Engine Room",		["index"] = 0x10,	["type"] = "H" },
	{["name"] = "MMM: H: Church Rafters",	["index"] = 0x11,	["type"] = "H" },
	{["name"] = "MMM: H: Floorboard",		["index"] = 0x12,	["type"] = "H" },
	{["name"] = "SM: H: Stump",				["index"] = 0x13,	["type"] = "H" },
	{["name"] = "SM: H: Waterfall",			["index"] = 0x14,	["type"] = "H" },
	{["name"] = "SM: H: Underwater",		["index"] = 0x15,	["type"] = "H" },
	{["name"] = "SM: H: Tree",				["index"] = 0x16,	["type"] = "H" },
	{["name"] = "SM: H: Coliwobble",		["index"] = 0x17,	["type"] = "H" },
	{["name"] = "SM: H: Quarries",			["index"] = 0x18,	["type"] = "H" },
	
--Jiggies
	{["name"] = "MM: Jig: Jinjo",			["index"] = 0x01,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Ticker's Tower",	["index"] = 0x02,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Mumbo's Skull",	["index"] = 0x03,	["type"] = "Jig"},
	{["name"] = "MM: Jig: JuJu",			["index"] = 0x03,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Huts",			["index"] = 0x05,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Ruins",			["index"] = 0x06,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Hill",			["index"] = 0x07,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Orange Switch",	["index"] = 0x08,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Chimpy",			["index"] = 0x09,	["type"] = "Jig"},
	{["name"] = "MM: Jig: Conga",			["index"] = 0x0A,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Jinjo",			["index"] = 0x0B,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Lighthouse",		["index"] = 0x0C,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Alcove 1",		["index"] = 0x0D,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Alcove 2",		["index"] = 0x0E,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Pool",			["index"] = 0x0F,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Sandcastle",		["index"] = 0x10,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Red X's",		["index"] = 0x11,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Nipper",			["index"] = 0x12, 	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Lockup",			["index"] = 0x13,	["type"] = "Jig"},
	{["name"] = "TTC: Jig: Blubber",		["index"] = 0x14,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Jinjo",			["index"] = 0x15,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Snippets",		["index"] = 0x16,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Back",			["index"] = 0x17,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Bolt",			["index"] = 0x18,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Tail",			["index"] = 0x19,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Long Pipe",		["index"] = 0x1A,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Tooth",			["index"] = 0x1B,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Rings",			["index"] = 0x1C,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Slow Sawblades",	["index"] = 0x1D,	["type"] = "Jig"},
	{["name"] = "CC: Jig: Fast Sawblades",	["index"] = 0x1E,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Jinjo",			["index"] = 0x1F,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Elevated Walkway",	["index"] = 0x20,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Egg",			["index"] = 0x21,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Croctus",		["index"] = 0x22,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Mud Huts",		["index"] = 0x23,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Flibbits",		["index"] = 0x24,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Maze",			["index"] = 0x25,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Tanktup",		["index"] = 0x26,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Tiptup",			["index"] = 0x27,	["type"] = "Jig"},
	{["name"] = "BGS: Jig: Mr. Vile",		["index"] = 0x28,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Jinjo",			["index"] = 0x29,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Boggy 1",			["index"] = 0x2A,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Pipe",			["index"] = 0x2B,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Boggy 3",			["index"] = 0x2B,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Snowman Buttons",	["index"] = 0x2D,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Presents",		["index"] = 0x2E,	["type"] = "Jig"},
	{["name"] = "FP: Jig: XMas Tree",		["index"] = 0x2F,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Boggy 2",			["index"] = 0x30,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Sir Slush",		["index"] = 0x31,	["type"] = "Jig"},
	{["name"] = "FP: Jig: Wozza",			["index"] = 0x32,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: 1st Jiggy",		["index"] = 0x33,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: MM Witch Switch",	["index"] = 0x34,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: CC Witch Switch",	["index"] = 0x35,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: TTC Witch Switch",	["index"] = 0x36,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: BGS Witch Switch",	["index"] = 0x37,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: FP Witch Switch",	["index"] = 0x38,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: MMM Witch Switch",	["index"] = 0x39,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: GV Witch Switch",	["index"] = 0x3A,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: RBB Witch Switch",	["index"] = 0x3B,	["type"] = "Jig"},
	{["name"] = "Lair: Jig: CCW Witch Switch",	["index"] = 0x3C,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Jinjo",			["index"] = 0x3D,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Grabba",			["index"] = 0x3E,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Shynx",			["index"] = 0x3F,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Matching Puzzle",	["index"] = 0x40,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Maze",			["index"] = 0x41,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Water Pyramid",	["index"] = 0x42,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Histup",			["index"] = 0x43,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Gobi 1",			["index"] = 0x44,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Gobi 2",			["index"] = 0x45,	["type"] = "Jig"},
	{["name"] = "GV: Jig: Ancient Ones",	["index"] = 0x46,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Jinjo",			["index"] = 0x47,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: House",			["index"] = 0x48,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Eeyrie",			["index"] = 0x49,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Nabnut",			["index"] = 0x4A,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Gnawty",			["index"] = 0x4B,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Zubbas",			["index"] = 0x4C,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Flower",			["index"] = 0x4D,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Summer Leaf Jumps",	["index"] = 0x4E,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Tree Top",		["index"] = 0x4F,	["type"] = "Jig"},
	{["name"] = "CCW: Jig: Top Room",		["index"] = 0x50,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Jinjo",			["index"] = 0x51,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Warehouse",		["index"] = 0x52,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Snorkel",		["index"] = 0x53,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Whistle",		["index"] = 0x54,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Funnel",			["index"] = 0x55,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Boss Boom Box",	["index"] = 0x56,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Propellor",		["index"] = 0x57,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Captains Cabin",	["index"] = 0x58,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Crane Cage",		["index"] = 0x59,	["type"] = "Jig"},
	{["name"] = "RBB: Jig: Engine Room",	["index"] = 0x5A,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Jinjo",			["index"] = 0x5B,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Well",			["index"] = 0x5C,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Napper",			["index"] = 0x5D,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Cellar",			["index"] = 0x5E,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Church Roof",	["index"] = 0x5F,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Motzhand",		["index"] = 0x60,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Rain Barrel",	["index"] = 0x61,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Tumblar",		["index"] = 0x62,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Flower Pots",	["index"] = 0x63,	["type"] = "Jig"},
	{["name"] = "MMM: Jig: Loggo",			["index"] = 0x64,	["type"] = "Jig"},
	
--Game Progress
	{["name"] = "1st Note Text",			["index"] = 0x03,	["type"] = "Prog"},
	{["name"] = "1st Mumbo Token Text",		["index"] = 0x04,	["type"] = "Prog"},
	{["name"] = "1st Egg Text",				["index"] = 0x05,	["type"] = "Prog"},
	{["name"] = "1st Red Feather Text",		["index"] = 0x06,	["type"] = "Prog"},
	{["name"] = "1st Gold Feather Text",	["index"] = 0x07,	["type"] = "Prog"},
	
	{["name"] = "1st Honeycomb Text",		["index"] = 0x0A,	["type"] = "Prog"},
	{["name"] = "1st Empty Honeycomb Text",	["index"] = 0x0B,	["type"] = "Prog"},
	{["name"] = "1st Extra Life Text",		["index"] = 0x0C,	["type"] = "Prog"},
	{["name"] = "1st Behive Text",			["index"] = 0x0D,	["type"] = "Prog"},
	{["name"] = "1st Jinjo Text",			["index"] = 0x0E,	["type"] = "Prog"},
	{["name"] = "1st Time Pirahana Text",	["index"] = 0x0F,	["type"] = "Prog"},
	{["name"] = "1st Sand Eel Text",		["index"] = 0x10,	["type"] = "Prog"},
	{["name"] = "1st Meeting Mumbo Text",	["index"] = 0x11,	["type"] = "Prog"},
	{["name"] = "1st Post XForm Mumbo Text",	["index"] = 0x12,	["type"] = "Prog"},
	
	{["name"] = "1st Icy Water Text",		["index"] = 0x14,	["type"] = "Prog"},
	{["name"] = "1st Time in Mansion Text",	["index"] = 0x15,	["type"] = "Prog"},
	{["name"] = "1st Time in Jigsaw Text",	["index"] = 0x16,	["type"] = "Prog"},
	{["name"] = "1st Time Enough Pieces Jigsaw Text",	["index"] = 0x17,	["type"] = "Prog"},
	{["name"] = "MM WS Jiggy Spawned",		["index"] = 0x18,	["type"] = "Prog"},
	{["name"] = "MMM WS Jiggy Spawned",		["index"] = 0x19,	["type"] = "Prog"},
	{["name"] = "TTC WS Jiggy Spawned",		["index"] = 0x1A,	["type"] = "Prog"},
	{["name"] = "CC WS Jiggy Spawned",		["index"] = 0x1B,	["type"] = "Prog"},
	{["name"] = "RBB WS Jiggy Spawned",		["index"] = 0x1C,	["type"] = "Prog"},
	{["name"] = "MMM Diningroom Cutscene",	["index"] = 0x1D,	["type"] = "Prog"},
	
	{["name"] = "Water Switch 1 Pressed",	["index"] = 0x22,	["type"] = "Prog"},
	{["name"] = "Lair Water Level 1",		["index"] = 0x23,	["type"] = "Prog"},
	{["name"] = "Water Switch 2 Pressed",	["index"] = 0x24,	["type"] = "Prog"},
	{["name"] = "Lair Water Level 2",		["index"] = 0x25,	["type"] = "Prog"},
	{["name"] = "Water Switch 3 Pressed",	["index"] = 0x26,	["type"] = "Prog"},
	{["name"] = "Lair Water Level 3",		["index"] = 0x27,	["type"] = "Prog"},
	
	{["name"] = "MM Open",					["index"] = 0x31,	["type"] = "Prog"},
	{["name"] = "TTC Open",					["index"] = 0x32,	["type"] = "Prog"},
	{["name"] = "CC Open",					["index"] = 0x33,	["type"] = "Prog"},
	{["name"] = "BGS Open",					["index"] = 0x34,	["type"] = "Prog"},
	{["name"] = "FP Open",					["index"] = 0x35,	["type"] = "Prog"},
	{["name"] = "GV Open",					["index"] = 0x36,	["type"] = "Prog"},
	{["name"] = "MMM Open",					["index"] = 0x37,	["type"] = "Prog"},
	{["name"] = "RBB Open",					["index"] = 0x38,	["type"] = "Prog"},
	{["name"] = "CCW Open",					["index"] = 0x39,	["type"] = "Prog"},
	{["name"] = "50 Note Door Open",		["index"] = 0x3A,	["type"] = "Prog"},
	{["name"] = "180 Note Door Open",		["index"] = 0x3B,	["type"] = "Prog"},
	{["name"] = "260 Note Door Open",		["index"] = 0x3C,	["type"] = "Prog"},
	{["name"] = "350 Note Door Open",		["index"] = 0x3D,	["type"] = "Prog"},
	{["name"] = "450 Note Door Open",		["index"] = 0x3E,	["type"] = "Prog"},
	{["name"] = "640 Note Door Open",		["index"] = 0x3F,	["type"] = "Prog"},
	{["name"] = "765 Note Door Open",		["index"] = 0x40,	["type"] = "Prog"},
	{["name"] = "810 Note Door Open",		["index"] = 0x41,	["type"] = "Prog"},
	{["name"] = "828 Note Door Open",		["index"] = 0x42,	["type"] = "Prog"},
	{["name"] = "846 Note Door Open",		["index"] = 0x43,	["type"] = "Prog"},
	{["name"] = "864 Note Door Open",		["index"] = 0x44,	["type"] = "Prog"},
	{["name"] = "882 Note Door Open",		["index"] = 0x45,	["type"] = "Prog"},
	{["name"] = "CCW WS Jiggy Spawned",		["index"] = 0x46,	["type"] = "Prog"},
	
	{["name"] = "FP WS Advent Door Open",	["index"] = 0x48,	["type"] = "Prog"},
	{["name"] = "Pink Cauldron 1 Active",	["index"] = 0x49,	["type"] = "Prog"},
	{["name"] = "Pink Cauldron 2 Active",	["index"] = 0x4A,	["type"] = "Prog"},
	{["name"] = "Green Cauldron 1 Active",	["index"] = 0x4B,	["type"] = "Prog"},
	{["name"] = "Green Cauldron 2 Active",	["index"] = 0x4C,	["type"] = "Prog"},
	{["name"] = "Red Cauldron 1 Active",	["index"] = 0x4D,	["type"] = "Prog"},
	{["name"] = "Red Cauldron 2 Active",	["index"] = 0x4E,	["type"] = "Prog"},
	
	{["name"] = "Yellow Cauldron 1 Active",	["index"] = 0x51,	["type"] = "Prog"},
	{["name"] = "Yellow Cauldron 2 Active",	["index"] = 0x52,	["type"] = "Prog"},
	{["name"] = "CCW Puzzle Podium Switch Pressed",	["index"] = 0x53,	["type"] = "Prog"},
	{["name"] = "CCW Puzzle Podium Active",	["index"] = 0x54,	["type"] = "Prog"},
	{["name"] = "1st FF BK Square Text",	["index"] = 0x55,	["type"] = "Prog"},
	{["name"] = "1st FF Pic Square Text",	["index"] = 0x56,	["type"] = "Prog"},
	{["name"] = "1st FF Music Square Text",	["index"] = 0x57,	["type"] = "Prog"},
	{["name"] = "1st FF Grunty Square Text",	["index"] = 0x58,	["type"] = "Prog"},
	{["name"] = "1st FF Death Square Text",	["index"] = 0x59,	["type"] = "Prog"},
	{["name"] = "1st FF Joker Square Text",	["index"] = 0x5A,	["type"] = "Prog"},
	
	--pieces places in puzzles info
	
	{["name"] = "Lair Crypt Gate Open",		["index"] = 0x85,	["type"] = "Prog"},
	
	{["name"] = "1st Exiting Loggo Text",	["index"] = 0x88,	["type"] = "Prog"},
	{["name"] = "CCW Spring Open",			["index"] = 0x8B,	["type"] = "Prog"},
	{["name"] = "CCW Summer Open",			["index"] = 0x8C,	["type"] = "Prog"},
	{["name"] = "CCW Autumn Open",			["index"] = 0x8D,	["type"] = "Prog"},
	{["name"] = "CCW Winter Open",			["index"] = 0x8E,	["type"] = "Prog"},
	
	{["name"] = "Termite Payed",			["index"] = 0x90,	["type"] = "Prog"},
	{["name"] = "Pumpkin Payed",			["index"] = 0x91,	["type"] = "Prog"},
	{["name"] = "Walrus Payed",				["index"] = 0x92,	["type"] = "Prog"},
	{["name"] = "Croc Payed",				["index"] = 0x93,	["type"] = "Prog"},
	{["name"] = "Bee Payed",				["index"] = 0x94,	["type"] = "Prog"},
	
	{["name"] = "1st Time Brentilda Text",	["index"] = 0x96,	["type"] = "Prog"},
	{["name"] = "1st Time In Lair Text",	["index"] = 0x97,	["type"] = "Prog"},
	{["name"] = "1st Time Exit Level Text",	["index"] = 0x98,	["type"] = "Prog"},
	{["name"] = "1st Time Past 50 ND Text",	["index"] = 0x99,	["type"] = "Prog"},
	
	{["name"] = "CC WS Eyes Active",		["index"] = 0x9B,	["type"] = "Prog"},
	{["name"] = "CC WS Left Eye Pressed",	["index"] = 0x9C,	["type"] = "Prog"},
	{["name"] = "CC WS Right Eye Pressed",	["index"] = 0x9D,	["type"] = "Prog"},
	{["name"] = "Crypt Coffin Lid Open",	["index"] = 0x9E,	["type"] = "Prog"},
	
	{["name"] = "Statue Hat Open",			["index"] = 0xA1,	["type"] = "Prog"},
	{["name"] = "GV Lobby Coffin Open",		["index"] = 0xA2,	["type"] = "Prog"},
	
	{["name"] = "Near Puzzle Podium Text",	["index"] = 0xA7,	["type"] = "Prog"},
	{["name"] = "1st Death Text",			["index"] = 0xA8,	["type"] = "Prog"},
	{["name"] = "RBB Oven Text",			["index"] = 0xA9,	["type"] = "Prog"},
	
	{["name"] = "BLUEEGGS Cheato",			["index"] = 0xAD,	["type"] = "Prog"},
	{["name"] = "REDFEATHERS Cheato",		["index"] = 0xAE,	["type"] = "Prog"},
	{["name"] = "GOLDFEATHERS Cheato",		["index"] = 0xAF,	["type"] = "Prog"},
	{["name"] = "Has Been in MM",			["index"] = 0xB0,	["type"] = "Prog"},
	{["name"] = "Has Been in BGS",			["index"] = 0xB1,	["type"] = "Prog"},
	{["name"] = "Has Been in TTC",			["index"] = 0xB2,	["type"] = "Prog"},
	{["name"] = "Has Been in GV",			["index"] = 0xB3,	["type"] = "Prog"},
	{["name"] = "Has Been in RBB",			["index"] = 0xB4,	["type"] = "Prog"},

	{["name"] = "Has Been in FP",			["index"] = 0xB6,	["type"] = "Prog"},

	{["name"] = "Has Been in CC",			["index"] = 0xB8,	["type"] = "Prog"},
	{["name"] = "Double Health",			["index"] = 0xB9,	["type"] = "Prog"},
	
	{["name"] = "1st Time in Lair Cutscene",	["index"] = 0xBD,	["type"] = "Prog"},
	
	{["name"] = "Grate to RBB Puzzle Open",	["index"] = 0xC2,	["type"] = "Prog"},
	{["name"] = "Ice Ball To Cheato Broken",	["index"] = 0xC3,	["type"] = "Prog"},
	{["name"] = "Statue Eye Broken",		["index"] = 0xC4,	["type"] = "Prog"},
	{["name"] = "Rareware Box Broken",		["index"] = 0xC5,	["type"] = "Prog"},
	{["name"] = "Jump Pad Switch Pressed",	["index"] = 0xC6,	["type"] = "Prog"},
	{["name"] = "Jump Pad Active",			["index"] = 0xC7,	["type"] = "Prog"},
	{["name"] = "Wall to Wading Boots Broken",	["index"] = 0xC8,	["type"] = "Prog"},
	{["name"] = "Wall to Jump Pad Switch Broken",	["index"] = 0xC9,	["type"] = "Prog"},
	{["name"] = "Cobweb to Purple Cauldron Broken",	["index"] = 0xCA,	["type"] = "Prog"},
	{["name"] = "Cobweb to Flight Pad Broken",	["index"] = 0xCB,	["type"] = "Prog"},
	{["name"] = "Cobweb to Green Cauldron Broken",	["index"] = 0xCC,	["type"] = "Prog"},
	{["name"] = "Grate to Water Switch 3 Open",		["index"] = 0xCD,	["type"] = "Prog"},
	{["name"] = "Grate by MMM Puzzle Open",	["index"] = 0xCE,	["type"] = "Prog"},
	
	{["name"] = "Fight 1st Jinjo Statue Activated Cutscene",	["index"] = 0xD1,	["type"] = "Prog"},
	{["name"] = "Fight 1st Jinjo Statue Rising Cutscene",	["index"] = 0xD2,	["type"] = "Prog"},
	
	{["name"] = "In Mumbo's With Enough Tokens Text",	["index"] = 0xDC,	["type"] = "Prog"},
	
	{["name"] = "Remove Puzzle Piece Text",	["index"] = 0xDF,	["type"] = "Prog"},
	{["name"] = "Place All Puzzle Pieces Text",	["index"] = 0xE0,	["type"] = "Prog"},
	
	{["name"] = "DoG Open",					["index"] = 0xE2,	["type"] = "Prog"},
	{["name"] = "CCW Flower Spring",		["index"] = 0xE3,	["type"] = "Prog"},
	{["name"] = "CCW Flower Summer",		["index"] = 0xE4,	["type"] = "Prog"},
	{["name"] = "CCW Flower Autumn",		["index"] = 0xE5,	["type"] = "Prog"},
	
	{["name"] = "Talked to Dingpot",		["index"] = 0xF3,	["type"] = "Prog"},
	{["name"] = "1st Time FF Cutscene",		["index"] = 0xF4,	["type"] = "Prog"},
	
	{["name"] = "1st Time Near DoG Puzzle Podium",	["index"] = 0xF6,	["type"] = "Prog"},
	
	{["name"] = "Defeated Grunty",	["index"] = 0xFC,	["type"] = "Prog"},
}