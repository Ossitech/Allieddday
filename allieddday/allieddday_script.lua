-- Survival MOD Script v1.1
-- Created by Brock Samson
-- Modified by Ossitech12
-- Based on Survival Extreme V3FA script

-- import
--------------------------------------------------------------------------
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua');
local ScenarioFramework = import('/lua/ScenarioFramework.lua');
local Utilities = import('/lua/utilities.lua');


-- class variables
--------------------------------------------------------------------------
local Survival_TickInterval = 0.50; -- how much delay between each script iteration

local Survival_NextSpawnTime = 0;
local Survival_CurrentTime = 0;

local Survival_GameState = 0; -- 0 pre-spawn, 1 post-spawn, 2 player win, 3 player defeat
local Survival_PlayerCount = 0; -- how many edge players there are
local Survival_PlayerCount_Total = 0; -- how many total players there are

local Survival_MarkerRefs = {{}, {}, {}, {}, {}}; -- 1 center / 2 waypoint / 3 spawn / 4 arty / 5 nuke

local Survival_UnitCountPerMinute = 0; -- how many units to spawn per minute (taking into consideration player count)
local Survival_UnitCountPerWave = 0; -- how many units to spawn with each wave (taking into consideration player count)

local Survival_MinWarnTime = 0;

local Survival_HealthBuffLand = 1.00;
local Survival_HealthBuffAir = 1.00;
local Survival_HealthBuffSea = 1.00;
local Survival_HealthBuffGate = 1.00;
local Survival_HealthBuffDefObject = 1.00;

local Survival_DefUnit = nil;
local Survival_DefCheckHP = 0.0;
local Survival_DefLastHP = 0;

local Survival_ArtyUnits = {};
local Survival_NukeUnits = {};

local Survival_ArtySpots = {};
local Survival_NukeSpots = {};

local Survival_NextNukeTime = 10000; --2040;
local Survival_NukeFrequency = 135;

local Survival_ObjectiveTime = 2400; --2160 --2160;

local mapStrings=import('/maps/allieddday/allieddday_strings.lua');

-- unit tables {'UnitID', OrderType};
--------------------------------------------------------------------------

-- order types

	-- 1 = move
	-- 2 = attack move
	-- 3 = patrol paths

-- wave table entries are in the following format

-- {"Description", OrderType, 'UnitID'},

-- entry 1 is a description text not used by code
-- entry 2 is the order given to this unit
-- entry 3 is the blueprint id and can be added multiple times as needed
-- when a unit table is randomly selected for spawn ONE unit from within will be chosen at random
-- for example if the "T1 Tank" line is selected ONE of the four tanks will be selected for spawning

-- below are default unit categories but custom ones can be made using same formatting

--	{"T1 Scout", 1, 'UAL0101', 'URL0101', 'UEL0101', 'XSL0101'},
--	{"T1 Bot", 1, 'UAL0106', 'URL0106', 'UEL0106'},
--	{"T1 Tank", 4, 'UAL0201', 'URL0107', 'UEL0201', 'XSL0201'},
--	{"T1 Arty", 2, 'UAL0103', 'URL0103', 'UEL0103', 'XSL0103'},
--	{"T1 AA", 3, 'UAL0104', 'URL0104', 'UEL0104', 'XSL0104'},

--	{"T2 Tank", 4, 'XAL0203', 'URL0202', 'UEL0202', 'DEL0204', 'XSL0203'}, -- aeon blaze, cybran rhino, uef pillar, uef mongoose, sera tank
--	{"T2 HeavyTank", 4, 'UAL0202', 'URL0203', 'UEL0203', 'XSL0202'}, -- aeon obsidian, cybran wagner, uef riptide, sera bot
--	{"T2 RocketBot", 2, 'DRL0204'},
--	{"T2 AA", 2, 'UAL0205', 'URL0205', 'UEL0205', 'XSL0205'},
--	{"T2 MML", 2, 'UAL0111', 'URL0111', 'UEL0111', 'XSL0111'},
--	{"T2 Shield", 3, 'UAL0307', 'UEL0307'},
--	{"T2 Stealth", 3, 'URL0306'},
--	{"T2 Bomb", 2, 'XRL0302'},

--	{"T2 Destroyer", 2, 'URS0201'}, -- cybran destroyer

--	{"T3 Bot1", 4, 'URL0303', 'UEL0303'}, -- cybran loyalist, uef titan
--	{"T3 Bot2", 4, 'UAL0303', 'XSL0303'}, -- aeon harb, sera tank
--	{"T3 Bot3", 4, 'XRL0305', 'XEL0303'}, -- cybran brick, uef percival
--	{"T3 Sniper", 2, 'XAL0305', 'XSL0305'},
--	{"T3 Arty", 2, 'UAL0304', 'URL0304', 'UEL0304', 'XSL0304'},
--	{"T3 Shield", 3, 'XSL0307'},
--	{"T3 MML", 2, 'XEL0306'},
--	{"T3 ShieldKill", 2, 'DAL0310'},

--	{"T3 Subcom", 2, 'UAL0301', 'URL0301', 'UEL0301', 'XSL0301'},

local Survival_WaveTables = {
	{ -- special
		2; -- current wave id (STARTS AT 2)
		{ -- Dummy field for wave updater function
			0.0; -- spawn time
		},
		{ -- Special ARTILLERY

			37.0; -- spawn time

			{"T3 ARTILLERY", 4, 'UAB2302', 'URB2302', 'UEB2302', 'XSB2302'}, -- second entry is MARKER ID and not order type
		},
		{ -- Special NUKES
		
			38.0; -- spawn time

			{"T3 NUKES", 5, 'UAB2305', 'UEB2305', 'XSB2305'}, -- second entry is MARKER ID and not order type
		},
	},
	{ -- ground
		2; -- current wave id (STARTS AT 2)
		{ -- Wave Set 1

			0.0; -- spawn time

			{"T1 Scout", 3, 'UAL0101'},
			{"T1 Tank", 2, 'UAL0201'},
		},
		{ -- Wave Set 2

			0.75; -- spawn time

			{"T1 Scout", 3, 'UAL0101'},
			{"T1 Tank", 2, 'UAL0201'},
			{"T1 tank", 2, 'UAL0201'},
		},
		{ -- Wave Set 3

			1.5; -- spawn time

			{"T1 Scout", 3, 'UAL0101'},
			{"T1 Tank", 2, 'UAL0201'},
			{"T1 Tank", 2, 'UAL0201'},

			{"T1 Tank", 4, 'UAL0201'},
		},
		{ -- Wave Set 4

			3.0; -- spawn time

			{"T1 Scout", 3, 'UAL0101'},

			{"T1 Tank", 4, 'UAL0201'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
			{"T1 Arty", 2, 'XSL0103'},
		},
		{ -- Wave Set 5

			4.0; -- spawn time

			{"T1 Scout", 3, 'UAL0101'},
			{"T1 Scout", 3, 'UAL0101'},

			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 4, 'UAL0201'},

			{"T1 Arty", 2, 'XSL0103'},
			{"T1 Arty", 2, 'XSL0103'},
			{"T1 Arty", 2, 'XSL0103'},
            
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
		},
		{ -- Wave Set 6

			5.0; -- spawn time

			{"T1 Scout", 3, 'UAL0101'},

			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 1, 'UAL0201'}, -- order change to 1

			{"T1 Arty", 2, 'XSL0103'},
			{"T1 Arty", 2, 'XSL0103'},
            
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
		},
		{ -- Wave Set 7

			6.0; -- spawn time

			{"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Submarine", 2, 'UAS0203', 'URS0203', 'UES0203', 'XSS0203'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
            {"T1 Anti Air Ship", 3, 'UAS0102'},
            {"T1 Anti Air Ship", 3, 'UAS0102'},
            {"T1 Frigate", 2, 'UAS0103', 'URS0103', 'UES0103', 'XSS0103'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
            {"T1 Bomber", 3, 'UAA0103', 'URA0103', 'UEA0103', 'XSA0103'},
            {"T1 Anti Air Ship", 3, 'UAS0102'},
            {"T1 Anti Air Ship", 3, 'UAS0102'},
            {"T1 Fighter", 3, 'UAA0102', 'URA0102', 'UEA0102', 'XSA0102'},
            {"T1 Fighter", 3, 'UAA0102', 'URA0102', 'UEA0102', 'XSA0102'},
		},
		{ -- Wave Set 8

			7.0; -- spawn time

			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 1, 'UAL0201'}, -- order change to 1

			{"T1 Arty", 2, 'XSL0103'},
			{"T1 Arty", 2, 'XSL0103'},

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
		},
		{ -- Wave Set 9

			8.0; -- spawn time

			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 4, 'UAL0201'},
			{"T1 Tank", 1, 'UAL0201'}, -- order change to 1

			{"T1 Arty", 2, 'XSL0103'},
			{"T1 Arty", 2, 'XSL0103'},

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
		},
		{ -- Wave Set 10

			9.0; -- spawn time

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
		},
		{ -- Wave Set 11

			10.0; -- spawn time

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
		},
		{ -- Wave Set 12

			11.0; -- spawn time

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Shield", 1, 'UAL0307'},
            {"T2 Shield", 1, 'UAL0307'},
            {"T2 Shield", 1, 'UAL0307'},
            {"T2 Shield", 1, 'UAL0307'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
		},
		{ -- Wave Set 13

			12.0; -- spawn time

			{"T2 Shield", 1, 'UAL0307'},
            {"T2 Shield", 1, 'UAL0307'},
            {"T2 Shield", 1, 'UAL0307'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
		},
		{ -- Wave Set 14

			13.0; -- spawn time

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
		},
		{ -- Wave Set 15

			14.0; -- spawn time

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
		},
		{ -- Wave Set 16

			15.0; -- spawn time

			{"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 4, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Tank", 1, 'XAL0203', 'URL0203', 'UEL0203', 'XSL0203'},
            {"T2 Flak", 3, 'UAL0205'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},

		},
		{ -- Wave Set 17

			16.0; -- spawn time

			{"T2 Flak", 3, 'UAL0205'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Destroyer", 2, 'UAS0201', 'URS0201', 'UES0201', 'XSS0201'},
            {"T2 Cruiser", 2, 'UAS0202', 'URS0202', 'UES0202', 'XSS0202'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
		},
		{ -- Wave Set 18

			17.0; -- spawn time

			{"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
		},
		{ -- Wave Set 19

			18.0; -- spawn time

			{"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 Shield disruptor", 2, 'DAL0310'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battlecruiser", 1, 'XES0307'},
		},
		{ -- Wave Set 20

			19.0; -- spawn time

			{"T3 Rocket ship", 3, 'XAS0306'},
            {"T3 Rocket ship", 3, 'XAS0306'},
            {"T3 Rocket ship", 3, 'XAS0306'},
            {"T3 Rocket ship", 3, 'XAS0306'},
            {"T3 Missile submarine", 3, 'UAS0304', 'URS0304', 'UES0304'},
            {"T3 Missile submarine", 3, 'UAS0304', 'URS0304', 'UES0304'},
            {"T3 Missile submarine", 3, 'UAS0304', 'URS0304', 'UES0304'},
            {"T3 Missile submarine", 3, 'UAS0304', 'URS0304', 'UES0304'},
            {"T2 Counter intel boat", 3, 'XRS0205'},
            {"T2 Counter intel boat", 3, 'XRS0205'},
            {"T3 Sonar Platform", 3, 'URS0305'},
            {"T3 Sonar Platform", 3, 'URS0305'},
		},
		{ -- Wave Set 21

			20.0; -- spawn time

			{"T2 Counter intel boat", 3, 'XRS0205'},
            {"T2 Counter intel boat", 3, 'XRS0205'},
            {"T3 Sonar Platform", 3, 'URS0305'},
            {"T3 Sonar Platform", 3, 'URS0305'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
            {"T2 Attack bomber", 3, 'DEA0202', 'DRA0202', 'XSA0202'},
		},
		{ -- Wave Set 22

			22.5; -- spawn time
            {"T3 Intel plane", 3, 'UAA0302', 'UEA0302', 'URA0302', 'XSA0302'},
			{"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
		},
		{ -- Wave Set 23

			25.0; -- spawn time
            {"T3 Intel plane", 3, 'UAA0302', 'UEA0302', 'URA0302', 'XSA0302'},
			{"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Air Fighter", 3, 'UAA0303', 'UEA0303', 'URA0303', 'XSA0303'},
            {"T3 Intel plane", 3, 'UAA0302', 'UEA0302', 'URA0302', 'XSA0302'},
			{"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
            {"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
            {"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
            {"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
            {"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
            {"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
            {"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
            {"T3 Bomber", 3, 'UAA0304', 'UEA0304', 'URA0304', 'XSA0304'},
			{"Monkeylord", 2, 'URL0402'},
		},
		{ -- Wave Set 24

			27.5; -- spawn time
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
			{"T2 Shield", 3, 'UAL0307'},
			{"T3 Shield", 3, 'XSL0307'},
            {"T2 Shield boat", 1, 'XES0205'},
            {"T2 Shield boat", 1, 'XES0205'},
			{"GC", 2, "UAL0401"},
			{"Ythotha", 1, "XSL0401"},
		},
		{ -- Wave Set 25

			30.0; -- spawn time

			{"T2 Shield", 3, 'UAL0307'},
			{"T3 Shield", 3, 'XSL0307'},
			{"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
			{"T2 Shield", 3, 'UAL0307'},
			{"T3 Shield", 3, 'XSL0307'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
			{"T2 Shield", 3, 'UAL0307'},
			{"T3 Shield", 3, 'XSL0307'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
            {"T3 HeavyBot", 1, 'XEL0305', 'XRL0305'},
			{"Monkeylord", 1, 'URL0402'}, -- order change to 1
			{"Monkeylord", 2, 'URL0402'},
			{"GC", 2, "UAL0401"},

			{"Ythotha", 1, "XSL0401"},

			{"Megalith", 2, "XRL0403"},
		},
		{ -- Wave Set 26

			32.5; -- spawn time
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"T3 Battleship", 1, 'UAS0302', 'URS0302', 'UES0302', 'XSS0302'},
            {"Experimental Bomber", 3, 'XSA0402'},
            {"CZAR", 3, 'UAL0401'},
            
			{"Megalith", 2, "XRL0403"},

			{"Fatboy", 3, "UEL0401"},
		},
		{ -- Wave Set 27

			35.0; -- spawn time

			{"T2 Shield", 3, 'UAL0307', 'UEL0307'},
			{"T3 Shield", 3, 'XSL0307'},

			{"T2 Shield", 3, 'UAL0307', 'UEL0307'},
			{"T3 Shield", 3, 'XSL0307'},

			{"T2 Shield", 3, 'UAL0307', 'UEL0307'},
			{"T3 Shield", 3, 'XSL0307'},

			{"Monkeylord", 1, 'URL0402'}, -- order change to 1
			{"Monkeylord", 2, 'URL0402'},
			{"GC", 2, "UAL0401"},

			{"Ythotha", 1, "XSL0401"},

			{"Megalith", 2, "XRL0403"},

			{"Fatboy", 3, "UEL0401"},
            {"Fatboy", 3, "UEL0401"},
            {"Fatboy", 3, "UEL0401"},
            {"Fatboy", 3, "UEL0401"},
            {"Experimental Bomber", 3, 'XSA0402'},
            {"Experimental Bomber", 3, 'XSA0402'},
		},
	},
};
--	{"T3 Bot1", 4, 'URL0303', 'UEL0303'}, -- cybran loyalist, uef titan
--	{"T3 Bot2", 4, 'UAL0303', 'XSL0303'}, -- aeon harb, sera tank
--	{"T3 Bot3", 4, 'XRL0305', 'XEL0305'}, -- cybran brick, uef percival
--	{"T3 Sniper", 2, 'XAL0305', 'XSL0305'},
--	{"T3 Arty", 2, 'UAL0304', 'URL0304', 'UEL0304', 'XSL0304'},
--	{"T3 Shield", 3, 'XSL0307'},
--	{"T3 MML", 2, 'XEL0306'},
--	{"T3 ShieldKill", 2, 'DAL0310'},
-- 	{"Monkeylord", 2, 'URL0402'},


-- called at start to read various settings
--------------------------------------------------------------------------
function OnPopulate()

	LOG("----- Survival MOD: OnPopulate()");

	-- start the armies
	ScenarioUtils.InitializeArmies();
    ScenarioFramework.Dialogue(mapStrings.IntroDialog, nil, true);
	-- prepare all the survival stuff
	Survival_InitGame();

	-- ScenarioFramework.SetPlayableArea('AREA_1' , false) -- restrict playable area because the map is too big

end



-- econ adjust based on who is playing
-- taken from original survival/Jotto
--------------------------------------------------------------------------
function ScenarioUtils.CreateResources()

	local Markers = ScenarioUtils.GetMarkers();

	for i, tblData in pairs(Markers) do -- loop marker list

		local SpawnThisResource = false; -- default to no

		if (tblData.resource and not tblData.SpawnWithArmy) then -- if this is a regular resource
			SpawnThisResource = true;
		elseif (tblData.resource and tblData.SpawnWithArmy) then -- if this is an army-specific resource

			if (tblData.SpawnWithArmy == "ARMY_0") then
				SpawnThisResource = true;
			else
				for x, army in ListArmies() do -- loop through army list

					if (tblData.SpawnWithArmy == army) then -- if this army is present
						SpawnThisResource = true; -- spawn this resource
						break;
					end
				end
			end
		end

		if (SpawnThisResource) then -- if we can spawn the resource do it

			local bp, albedo, sx, sz, lod;

			if (tblData.type == "Mass") then
				albedo = "/env/common/splats/mass_marker.dds";
				bp = "/env/common/props/massDeposit01_prop.bp";
				sx = 2;
				sz = 2;
				lod = 100;
			else
				albedo = "/env/common/splats/hydrocarbon_marker.dds";
				bp = "/env/common/props/hydrocarbonDeposit01_prop.bp";
				sx = 6;
				sz = 6;
				lod = 200;
			end

			-- create the resource
			CreateResourceDeposit(tblData.type,	tblData.position[1], tblData.position[2], tblData.position[3], tblData.size);

			-- create the resource graphic on the map
			CreatePropHPR(bp, tblData.position[1], tblData.position[2], tblData.position[3], Random(0,360), 0, 0);

			-- create the resource icon on the map
			CreateSplat(
				tblData.position,           # Position
				0,                          # Heading (rotation)
				albedo,                     # Texture name for albedo
				sx, sz,                     # SizeX/Z
				lod,                        # LOD
				0,                          # Duration (0 == does not expire)
				-1,                         # army (-1 == not owned by any single army)
				0							# ???
			);
		end
	end
end



-- called at start of game
--------------------------------------------------------------------------
function OnStart(self)

	LOG("----- Survival MOD: Initializing game start sequence...");

	-- start the survival tick
	ForkThread(Survival_Tick);

end



-- initializes the game settings
--------------------------------------------------------------------------
Survival_InitGame = function()

	LOG("----- Survival MOD: Configuring match settings...");

	-- check game configuration
	
		-- build time
		if (ScenarioInfo.Options.opt_Survival_BuildTime == nil) then
			LOG('----- Survival MOD: Warning! Build Time option should not be nil.')
			ScenarioInfo.Options.opt_Survival_BuildTime = 0;
		end

		Survival_NextSpawnTime = ScenarioInfo.Options.opt_Survival_BuildTime; -- set first wave time to build time
		Survival_MinWarnTime = Survival_NextSpawnTime - 60; -- set time for minute warning

		-- opt_Survival_EnemiesPerMinute
		if (ScenarioInfo.Options.opt_Survival_EnemiesPerMinute == nil) then
			ScenarioInfo.Options.opt_Survival_EnemiesPerMinute = 32;
			LOG('----- Survival MOD: Warning! Difficulty option should not be nil.')
		end

		-- opt_Survival_WaveFrequency
		if (ScenarioInfo.Options.opt_Survival_WaveFrequency == nil) then
			ScenarioInfo.Options.opt_Survival_WaveFrequency = 10;
			LOG('----- Survival MOD: Warning! Wave Frequency option should not be nil.')
		end

	ScenarioInfo.Options.Victory = 'sandbox'; -- force sandbox in order to implement our own rules

	--Utilities.UserConRequest("ui_ForceLifbarsOnEnemy"); -- force drawing of enemy life bars

	Survival_PlayerCount = 0;
	
	local Armies = ListArmies();
	Survival_PlayerCount_Total = table.getn(Armies) - 2;

	-- loop through armies
	for i, Army in ListArmies() do
		if (Army == "ARMY_1" or Army == "ARMY_2" or Army == "ARMY_3" or Army == "ARMY_4") then
			Survival_PlayerCount = Survival_PlayerCount + 1; -- save player count (ignore players in the middle)
		end
	
		-- Add build restrictions
		if (Army == "ARMY_1" or Army == "ARMY_2" or Army == "ARMY_3" or Army == "ARMY_4" or Army == "ARMY_5" or Army == "ARMY_6" or Army == "ARMY_7" or Army == "ARMY_8") then 

			--ScenarioFramework.AddRestriction(Army, categories.WALL); -- don't allow them to build walls
			--ScenarioFramework.AddRestriction(Army, categories.AIR); -- don't allow them to build air stuff

			-- loop through other armies to ally with other human armies
			for x, ArmyX in ListArmies() do
				-- if human army
				if (ArmyX == "ARMY_1" or ArmyX == "ARMY_2" or ArmyX == "ARMY_3" or ArmyX == "ARMY_4" or ArmyX == "ARMY_5" or ArmyX == "ARMY_6" or ArmyX == "ARMY_7" or ArmyX == "ARMY_8") then 
					SetAlliance(Army, ArmyX, 'Ally'); 
				end
			end			

			SetAlliance(Army, "ARMY_SURVIVAL_ALLY", 'Ally'); -- friendly AI team
			SetAlliance(Army, "ARMY_SURVIVAL_ENEMY", 'Enemy');  -- enemy AI team

			SetAlliedVictory(Army, true); -- can win together of course :)
		end
	end

	SetAlliance("ARMY_SURVIVAL_ALLY", "ARMY_SURVIVAL_ENEMY", 'Enemy'); -- the friendly and enemy AI teams should be enemies

	SetIgnoreArmyUnitCap('ARMY_SURVIVAL_ENEMY', true); -- remove unit cap from enemy AI team

	Survival_InitMarkers(); -- find and reference all the map markers related to survival
	Survival_SpawnDef();
	Survival_SpawnPrebuild();

	Survival_CalcWaveCounts(); -- calculate how many units per wave
	Survival_CalcNukeFrequency(); -- calculate how frequently to launch nukes at the players (once launchers are spawned)
--	Survival_ObjectiveTime = Survival_ObjectiveTime * 60;

end



-- spawns a specified unit
--------------------------------------------------------------------------
Survival_InitMarkers = function()

	LOG("----- Survival MOD: Initializing marker lists...");

	local MarkerRef = nil;
	local Break = 0;
	local i = 1;

	while (Break < 5) do

		Break = 0; -- reset break counter

		-- center
		MarkerRef = GetMarker("SURVIVAL_CENTER_" .. i);

		if (MarkerRef != nil) then
			table.insert(Survival_MarkerRefs[1], MarkerRef);
--			Survival_MarkerCounts[1] = Survival_MarkerCounts[1] + 1;
		else
			Break = Break + 1;
		end

		-- path
		MarkerRef = GetMarker("SURVIVAL_PATH_" .. i);

		if (MarkerRef != nil) then
			table.insert(Survival_MarkerRefs[2], MarkerRef);
--			Survival_MarkerCounts[2] = Survival_MarkerCounts[2] + 1;
		else
			Break = Break + 1;
		end

		-- spawn
		MarkerRef = GetMarker("SURVIVAL_SPAWN_" .. i);

		if (MarkerRef != nil) then
			for x, army in ListArmies() do -- loop through army list
				if (MarkerRef.SpawnWithArmy == army) then -- if this army is present
					table.insert(Survival_MarkerRefs[3], MarkerRef);
					break;
				end
			end
			
--			Survival_MarkerCounts[3] = Survival_MarkerCounts[3] + 1;
		else
			Break = Break + 1;
		end

		-- arty
		MarkerRef = GetMarker("SURVIVAL_ARTY_" .. i);

		if (MarkerRef != nil) then
			for x, army in ListArmies() do -- loop through army list
				if (MarkerRef.SpawnWithArmy == army) then -- if this army is present
					table.insert(Survival_MarkerRefs[4], MarkerRef);
					break;
				end
			end
--			Survival_MarkerCounts[4] = Survival_MarkerCounts[4] + 1;
		else
			Break = Break + 1;
		end

		-- nuke
		MarkerRef = GetMarker("SURVIVAL_NUKE_" .. i);

		if (MarkerRef != nil) then
			for x, army in ListArmies() do -- loop through army list
				if (MarkerRef.SpawnWithArmy == army) then -- if this army is present
					table.insert(Survival_MarkerRefs[5], MarkerRef);
					break;
				end
			end
--			Survival_MarkerCounts[5] = Survival_MarkerCounts[5] + 1;
		else
			Break = Break + 1;
		end

		i = i + 1; -- increment counter

	end

	LOG("----- Survival MOD: Marker counts:     CENTER(" .. table.getn(Survival_MarkerRefs[1]) .. ")     PATHS(" .. table.getn(Survival_MarkerRefs[2]) .. ")     SPAWN(" .. table.getn(Survival_MarkerRefs[3]) .. ")     ARTY(" .. table.getn(Survival_MarkerRefs[4]) .. ")     NUKE(" .. table.getn(Survival_MarkerRefs[5]) .. ")");
    
end



-- spawns a defense object
--------------------------------------------------------------------------
Survival_SpawnDef = function()

	LOG("----- Survival MOD: Initializing defense object...");

	local POS = ScenarioUtils.MarkerToPosition("SURVIVAL_CENTER_1");
	Survival_DefUnit = CreateUnitHPR('UEC1401', "ARMY_SURVIVAL_ALLY", POS[1], POS[2], POS[3], 0,0,0);
    
	Survival_DefUnit:SetReclaimable(false);
	Survival_DefUnit:SetCapturable(false);
	Survival_DefUnit:SetProductionPerSecondEnergy((Survival_PlayerCount_Total * 100) + 0);
	Survival_DefUnit:SetConsumptionPerSecondEnergy(0);

	local defenseObjectHealth = 9000 - (Survival_PlayerCount_Total * 1000);
	Survival_DefUnit:SetMaxHealth(defenseObjectHealth);
	Survival_DefUnit:SetHealth(nil, defenseObjectHealth);
	Survival_DefUnit:SetRegenRate(defenseObjectHealth / 180.0); --It takes 3 minutes for the defense object to fully regenerate.

	local Survival_DefUnitBP = Survival_DefUnit:GetBlueprint();
	Survival_DefUnitBP.Intel.MaxVisionRadius = 600;
	Survival_DefUnitBP.Intel.MinVisionRadius = 600;
	Survival_DefUnitBP.Intel.VisionRadius = 600;

	Survival_DefUnit:SetIntelRadius('Vision', 600);

       	local ShieldSpecs = {
            ImpactEffects = 'SeraphimShieldHit01',
            ImpactMesh = '/effects/entities/ShieldSection01/ShieldSection01_mesh',
            Mesh = '/effects/entities/SeraphimShield01/SeraphimShield01_mesh',
            MeshZ = '/effects/entities/Shield01/Shield01z_mesh',
            RegenAssistMult = 60,
            ShieldEnergyDrainRechargeTime = 60,
            ShieldMaxHealth = 55000 + (Survival_PlayerCount_Total * 5000),
            ShieldRechargeTime = 60,
            ShieldRegenRate = 290 - (Survival_PlayerCount_Total * 10),
            ShieldRegenStartTime = 1,
            ShieldSize = 90,
            ShieldVerticalOffset = -10,
        };

--	Survival_DefUnitBP.Defense.Shield = ShieldSpecs;

--	Survival_DefUnitBP.General.UnitName = 'Acen Accelerator';
--	Survival_DefUnitBP.Interface.HelpText = 'Special Operations Support';

	-- when the def object dies
	Survival_DefUnit.OldOnKilled = Survival_DefUnit.OnKilled;

	Survival_DefUnit.OnKilled = function(self, instigator, type, overkillRatio)
		if (Survival_GameState != 2) then -- If the timer hasn't expired yet...
			BroadcastMSG("Ihr habt hart verkackt meine Freunde!", 8);
            ScenarioFramework.Dialogue(mapStrings.DefeatDialog, nil, true);
            --end text
			self.OldOnKilled(self, instigator, type, overkillRatio);
			
			Survival_GameState = 3;

			for i, army in ListArmies() do

				if (army == "ARMY_1" or army == "ARMY_2" or army == "ARMY_3" or army == "ARMY_4" or army == "ARMY_5" or army == "ARMY_6" or army == "ARMY_7" or army == "ARMY_8") then
					GetArmyBrain(army):OnDefeat();
				end
			end
			GetArmyBrain("ARMY_SURVIVAL_ENEMY"):OnVictory();
		end
	end

	Survival_DefLastHP = Survival_DefUnit:GetHealth();

--	ScenarioFramework.CreateUnitDamagedTrigger(Survival_DefDamage, Survival_DefUnit);

--### Single Line unit damaged trigger creation
--# When <unit> is damaged it will call the <callbackFunction> provided
--# If <percent> provided, will check if damaged percent EXCEEDS number provided before callback
--# function repeats up to repeatNum ... or once if not declared
--function CreateUnitDamagedTrigger( callbackFunction, unit, amount, repeatNum )
--    TriggerFile.CreateUnitDamagedTrigger( callbackFunction, unit, amount, repeatNum )
--end

end



-- spawns a specified unit
--------------------------------------------------------------------------
Survival_SpawnPrebuild = function()

	LOG("----- Survival MOD: Initializing pre-build objects...");

	local FactionID = nil;

	local MarkerRef = nil;
	local POS = nil;
	local FactoryRef = nil;

	for i, Army in ListArmies() do
		if (Army == "ARMY_1" or Army == "ARMY_2" or Army == "ARMY_3" or Army == "ARMY_4" or Army == "ARMY_5" or Army == "ARMY_6" or Army == "ARMY_7" or Army == "ARMY_8") then 

			FactionID = GetArmyBrain(Army):GetFactionIndex();

			MarkerRef = GetMarker("SURVIVAL_FACTORY_" .. Army);

			if (MarkerRef != nil) then
				POS = MarkerRef.position;

				if (FactionID == 1) then -- uef
					FactoryRef = CreateUnitHPR('UEB0101', Army, POS[1], POS[2], POS[3], 0,0,0);
				elseif (FactionID == 2) then -- aeon
					FactoryRef = CreateUnitHPR('UAB0101', Army, POS[1], POS[2], POS[3], 0,0,0);
				elseif (FactionID == 3) then -- cybran
					FactoryRef = CreateUnitHPR('URB0101', Army, POS[1], POS[2], POS[3], 0,0,0);
				elseif (FactionID == 4) then -- seraphim
					FactoryRef = CreateUnitHPR('XSB0101', Army, POS[1], POS[2], POS[3], 0,0,0);
				end
			end
		end
	end
end



-- warns players about damage to defense object
--------------------------------------------------------------------------
--Survival_DefDamage = function()
--	BroadcastMSG("The Aeon Accelerator is taking damage!");
--	LOG("----- Survival MOD: DefDamage()");
--	Survival_DefCheckHP = 0;
--	Survival_DefLastHP
--end



-- loops every TickInterval to progress main game logic
--------------------------------------------------------------------------
Survival_Tick = function(self)

	LOG("----- Survival MOD: Tick thread started with interval of (" .. Survival_TickInterval .. ")");
    local oldNumArmies=table.getn(ListArmies());
	while (Survival_GameState < 2) do

		Survival_CurrentTime = GetGameTimeSeconds();

		Survival_UpdateWaves(Survival_CurrentTime);

--		LOG("----- Survival MOD: -LOOP- GameState: " .. Survival_GameState .. "     NextSpawnTime: " .. SecondsToTime(Survival_NextSpawnTime) .. " (" .. Survival_NextSpawnTime .. ")     Clock:" .. SecondsToTime(Survival_CurrentTime) .. " (" .. Survival_CurrentTime .. ")");

--		Survival_DefUnit:UpdateShieldRatio(0.5); --Survival_CurrentTime / Survival_ObjectiveTime);
        
		if (Survival_CurrentTime >= Survival_ObjectiveTime) then

			Survival_GameState = 2;
			BroadcastMSG("Der Feind hat keinen Bock mehr! Sieg!", 4);
			Survival_DefUnit:SetCustomName("CHUCK NORRIS MODE!"); -- update defense object name

			for i, army in ListArmies() do
				if (army == "ARMY_1" or army == "ARMY_2" or army == "ARMY_3" or army == "ARMY_4" or army == "ARMY_5" or army == "ARMY_6" or army == "ARMY_7" or army == "ARMY_8") then
					GetArmyBrain(army):OnVictory();
				end
			end

			GetArmyBrain("ARMY_SURVIVAL_ENEMY"):OnDefeat();
		else

			if (Survival_GameState == 0) then -- build stage

				if (Survival_CurrentTime >= Survival_NextSpawnTime) then -- if build period is over

					LOG("----- Survival MOD: Build state complete. Proceeding to combat state.");
					Sync.ObjectiveTimer = 0; -- clear objective timer
					Survival_GameState = 1; -- update game state to combat mode
					BroadcastMSG("Die Alliierten kommen!", 4);
                    ScenarioFramework.Dialogue(mapStrings.AttackDialog, nil, true);
					Survival_SpawnWave(Survival_NextSpawnTime);
					Survival_NextSpawnTime = Survival_NextSpawnTime + ScenarioInfo.Options.opt_Survival_WaveFrequency; -- update next wave spawn time by wave frequency

				else -- build period still active

					Sync.ObjectiveTimer = math.floor(Survival_NextSpawnTime - Survival_CurrentTime); -- update objective timer
					Survival_DefUnit:SetCustomName("Eier machen! " .. SecondsToTime(Sync.ObjectiveTimer)); -- update defense object name

					if ((Survival_MinWarnTime > 0) and (Survival_CurrentTime >= Survival_MinWarnTime)) then -- display 2 minute warning if we're at 2 minutes and it's appropriate to do so
						LOG("----- Survival MOD: Sending 1 minute warning.");
						BroadcastMSG("Eine Minute noch!", 2);
						Survival_MinWarnTime = 0; -- reset 2 minute warning time so it wont be displayed again
					end

				end

			elseif (Survival_GameState == 1) then -- combat stage

				Sync.ObjectiveTimer = math.floor(Survival_ObjectiveTime - Survival_CurrentTime); -- update objective timer

				if (Survival_CurrentTime >= Survival_NextSpawnTime) then -- ready to spawn a wave
					Survival_SpawnWave(Survival_NextSpawnTime);
					Survival_NextSpawnTime = Survival_NextSpawnTime + ScenarioInfo.Options.opt_Survival_WaveFrequency; -- update next wave spawn time by wave frequency
				end

				Survival_DefUnit:SetCustomName('Biergarten Eden: Level ' ..  (Survival_WaveTables[2][1] - 1) .. "/" .. (table.getn(Survival_WaveTables[2]) - 1) ); -- .. ' (' .. SecondsToTime(Survival_CurrentTime - (Survival_WaveTables[1][Survival_WaveTables[1][1] + 1][1] * 60)).. ')');
				--SecondsToTime((Survival_WaveTables[1][(Survival_WaveTables[1][1])][1] * 60) - Survival_CurrentTime)
			end

			Survival_DefCheckHP = Survival_DefCheckHP - Survival_TickInterval;

			if (Survival_DefCheckHP <= 0) then
				if (Survival_DefUnit:GetHealth() < Survival_DefLastHP) then
					--BroadcastMSG("The Aeon Accelerator is v damage! (" .. Survival_DefUnit:GetHealth() / Survival_DefUnit:GetMaxHealth() .. "%)", 0.5);
					local health = Survival_DefUnit:GetHealth();
					local maxHealth = Survival_DefUnit:GetMaxHealth();
					local defUnitPercent = health / maxHealth;
					BroadcastMSG("Wir erleiden Schaden! (" .. math.floor(defUnitPercent * 100) .. "%)", 0.5);

					Survival_DefCheckHP = 2;
				end
			end

			Survival_DefLastHP = Survival_DefUnit:GetHealth();

			-- nuke stuff
			if (Survival_CurrentTime >= Survival_NextNukeTime) then
				Survival_FireNuke();
			end

			WaitSeconds(Survival_TickInterval);
		end
	end
	
	--End the game the correct way
	WaitSeconds(15);
	import('/lua/victory.lua').CallEndGame(true, false);
	KillThread(self);
end



-- updates spawn waves
--------------------------------------------------------------------------
Survival_UpdateWaves = function(GameTime)

	local OldWaveID = 1;

	-- check the wave table times vs the wave spawn time to see which waves we spawn
	for x = 1, table.getn(Survival_WaveTables) do -- loop through each of the wavetable entries (ground/air/sea...)

--		OldWaveID = 1;
		OldWaveID = Survival_WaveTables[x][1];

		for y = Survival_WaveTables[x][1], table.getn(Survival_WaveTables[x]) do -- loop through each wave table within the category

			if (GameTime >= (Survival_WaveTables[x][y][1] * 60)) then -- compare spawn time against the first entry spawn time for each wave table
				if (Survival_WaveTables[x][1] < y) then -- should only update a wave once
				
					Survival_WaveTables[x][1] = y; -- update the wave id for this wave category

					if (x == 1) then -- if this is the special category update, immediately call the setup function
						Survival_SpawnSpecialWave(GameTime);
					end
				end
			else break; end

		end

		if (Survival_WaveTables[x][1] != OldWaveID) then -- if we have a new wave ID for this table
			LOG("----- Survival MOD: Updating wave table from C:" .. x .. " ID:" .. Survival_WaveTables[x][1] .. " ( Set:" .. (Survival_WaveTables[x][1] - 1) ..") at " .. SecondsToTime(GameTime));		
		end
	end
end



-- spawns a wave of units
--------------------------------------------------------------------------
Survival_SpawnWave = function(SpawnTime)

--	LOG("----- Survival MOD: Performing a wave spawn at " .. SecondsToTime(SpawnTime));

	local WaveTable = nil;
	local UnitTable = nil;

	local UnitID = nil;
	local OrderID = nil;
	local POS = nil;
	local RandID = nil;

	-- check the wave table times vs the wave spawn time to see which waves we spawn
	-- START AT TABLE 2 BECAUSE TABLE 1 IS SPECIAL UNITS (ARTY/NUKE)
	for x = 2, table.getn(Survival_WaveTables) do -- loop through each of the wavetable entries (ground/air/sea...)

--		LOG("----- Survival MOD: Category(" .. x .. ")     Wave Set (" .. Survival_WaveTables[x][1] - 1 .. ")   (ID: " .. Survival_WaveTables[x][1] .. ");

		-- for the amount of units we spawn in per wave
		if (table.getn(Survival_WaveTables[x][Survival_WaveTables[x][1]]) > 1) then -- only do a wave spawn if there is a wave table available
			-- for the amount of units we spawn in per wave
            
			for z = 1,Survival_UnitCountPerWave do
            
				WaveTable = Survival_WaveTables[x][Survival_WaveTables[x][1]]; -- grab the wave set table we're spawning from
                
				RandID = math.random(2, table.getn(WaveTable)); -- pick a random unit table from within this wave set
                
				UnitTable = WaveTable[RandID]; -- reference that unit table
                
				UnitID = Survival_GetUnitFromTable(UnitTable); -- pick a random unit id from this table
                
				OrderID = UnitTable[2]; -- get the order id from this unit table (always 2nd entry)
                
				POS = Survival_GetPOS(3, 25);
                
				Survival_SpawnUnit(UnitID, "ARMY_SURVIVAL_ENEMY", POS, OrderID);
			end
		end

	end

end



-- spawns a specified unit
--------------------------------------------------------------------------
Survival_SpawnUnit = function(UnitID, ArmyID, POS, OrderID) -- blueprint, army, position, order

--	LOG("----- Survival MOD: SPAWNUNIT: Start function...");
	local PlatoonList = {};
	local NewUnit = CreateUnitHPR(UnitID, ArmyID, POS[1], POS[2], POS[3], 0,0,0);
	-- prevent wreckage from enemy units
--	local BP = NewUnit:GetBlueprint();
--	if (BP != nil) then
--		BP.Wreckage = nil;
--	end

	NewUnit:SetProductionPerSecondEnergy(325);
	table.insert(PlatoonList, NewUnit); -- add unit to a platoon
	Survival_PlatoonOrder(ArmyID, PlatoonList, OrderID); -- give the unit orders
end



-- spawns a wave of special units
--------------------------------------------------------------------------
Survival_SpawnSpecialWave = function(SpawnTime)

	LOG("----- Survival MOD: Performing a special wave spawn at " .. SecondsToTime(SpawnTime));

	local UnitTable = Survival_WaveTables[1][Survival_WaveTables[1][1]][2]
	local UnitID = nil;
	local POS = nil;

	if (table.getn(Survival_WaveTables[1][Survival_WaveTables[1][1]]) > 1) then -- only do a wave spawn if there is a wave table available

		-- spawn one per player (up to the amount of spawn locations)
		for x = 1, Survival_PlayerCount do

			UnitID = Survival_GetUnitFromTable(UnitTable); -- pick a random unit id from this table
			POS = Survival_GetPOS(UnitTable[2], 0);

			if (POS != nil) then
				Survival_SpawnSpecialUnit(UnitID, "ARMY_SURVIVAL_ENEMY", POS)
			end
		end
	end

end



-- spawns a special unit
-- this is fairly hard-coded for this specific setup and will need to be adjusted for alternate rules and gameplay
--------------------------------------------------------------------------
Survival_SpawnSpecialUnit = function(UnitID, ArmyID, POS) -- blueprint, army, position

	LOG("----- Survival MOD: SPAWNSPECIALUNIT: Start function...");

	local PlatoonList = {};

	local NewUnit = CreateUnitHPR(UnitID, ArmyID, POS[1], POS[2], POS[3], 0,0,0);

	NewUnit:SetReclaimable(false);
	NewUnit:SetCapturable(false);
	NewUnit:SetProductionPerSecondEnergy(25000);
	NewUnit:SetConsumptionPerSecondEnergy(0);
	NewUnit:SetProductionPerSecondMass(1000);

	NewUnit:SetMaxHealth(25000000);
	NewUnit:SetHealth(nil, 25000000);
	NewUnit:SetRegenRate(5000000);

	table.insert(PlatoonList, NewUnit); -- add unit to a platoon

	-- if this is an artillery unit
	if ((UnitID == "UAB2302") or (UnitID == "URB2302") or (UnitID == "UEB2302") or (UnitID == "XSB2302") or (UnitID == "UEB2401") or (UnitID == "XAB2307") or (UnitID == "URL0401")) then

		table.insert(Survival_ArtyUnits, NewUnit); -- add unit to special unit list
		NewUnit:SetIntelRadius('Vision', 1000);

	elseif ((UnitID == "UAB2305") or (UnitID == "UEB2305") or (UnitID == "XSB2305") or (UnitID == "XSB2401")) then

		table.insert(Survival_NukeUnits, NewUnit); -- add unit to special unit list

		if (Survival_NextNukeTime == 10000) then
			Survival_NextNukeTime = Survival_CurrentTime; -- update counter for next time
		end

		Survival_FireNuke();
	end

end



-- launches a nuke from a random silo
--------------------------------------------------------------------------
Survival_FireNuke = function()

	LOG("----- Survival MOD: FIRENUKE: Start function...");

	local RandID = 1;

	if (Survival_CurrentTime >= Survival_NextNukeTime) then

		LOG("----- Survival MOD: FIRENUKE: CurrentTime > NextNukeTime...");

		if (table.getn(Survival_NukeUnits) >= 1) then

			LOG("----- Survival MOD: FIRENUKE: table.getn >= 1...");

			RandID = math.random(1, table.getn(Survival_NukeUnits)); -- pick a random nuke launcher
			Survival_NukeUnits[RandID]:GiveNukeSiloAmmo(1); -- give it 1 ammo
			IssueNuke({Survival_NukeUnits[RandID]}, ScenarioUtils.MarkerToPosition('SURVIVAL_CENTER_1' ) );

			Survival_NextNukeTime = Survival_CurrentTime + Survival_NukeFrequency; -- update counter for next time
		end
	end
end


-- returns a random unit from within a specified unit table
--------------------------------------------------------------------------
Survival_GetUnitFromTable = function(UnitTable)

	local RandID = math.random(3, table.getn(UnitTable));
	local UnitID = UnitTable[RandID];

	return UnitID;

end



-- returns a random spawn position
--------------------------------------------------------------------------
Survival_GetPOS = function(MarkerType, Randomization)

	local RandID = 1;
--	local MarkerName = nil;

	RandID = math.random(1, table.getn(Survival_MarkerRefs[MarkerType]));  -- get a random value from the selected marker count
--	LOG("----- Survival MOD: GetPOS: RandID[" .. RandID .. "]");

	if (RandID == 0) then
		return nil;
	end

 	local POS = Survival_MarkerRefs[MarkerType][RandID].position;
 
 	if (MarkerType == 4) then
 		table.remove(Survival_MarkerRefs[4], RandID);
 	elseif (MarkerType == 5) then
 		table.remove(Survival_MarkerRefs[5], RandID);
 	end
 
--	if (MarkerType == 1) then
--		MarkerName = "SURVIVAL_CENTER_" .. RandID;
--	elseif (MarkerType == 2) then
--		MarkerName = "SURVIVAL_PATH_" .. RandID;
--	elseif (MarkerType == 3) then
--		MarkerName = "SURVIVAL_SPAWN_" .. RandID;
--	elseif (MarkerType == 4) then
--		MarkerName = "SURVIVAL_ARTY_" .. RandID;
--		table.remove(Survival_MarkerRefs[4]);
--	elseif (MarkerType == 5) then
--		MarkerName = "SURVIVAL_NUKE_" .. RandID;
--		table.remove(Survival_MarkerRefs[5]);
--	else
--		return nil;
--	end

--	local POS = Survival_RandomizePOS(ScenarioUtils.MarkerToPosition(MarkerName), Randomization);

	return POS;

end



-- test platoon order function
--------------------------------------------------------------------------
Survival_PlatoonOrder = function(ArmyID, UnitList, OrderID)	

--	LOG("----- Survival MOD: PLATOON: Start function...");

	if (UnitList == nil) then
		return;
	end

	local aiBrain = GetArmyBrain(ArmyID); --"ARMY_SURVIVAL_ENEMY");
	local aiPlatoon = aiBrain:MakePlatoon('','');
	aiBrain:AssignUnitsToPlatoon(aiPlatoon, UnitList, 'Attack', 'None'); -- platoon, unit list, "mission" and formation

 	-- 1 center / 2 waypoint / 3 spawn
 
 	if (OrderID == 4) then -- attack move / move

		-- attack move to random path
		POS = Survival_GetPOS(2, 25);
		aiPlatoon:AggressiveMoveToLocation(POS);

		-- move to random center
		POS = Survival_GetPOS(1, 25);
		aiPlatoon:MoveToLocation(POS, false);

 	elseif (OrderID == 3) then -- patrol paths

		-- move to random path
		POS = Survival_GetPOS(2, 25);
		aiPlatoon:MoveToLocation(POS, false);

		-- patrol to random path
		POS = Survival_GetPOS(2, 25);
		aiPlatoon:Patrol(POS);

	elseif (OrderID == 2) then -- attack move

		-- attack move to random path
		POS = Survival_GetPOS(2, 25);
		aiPlatoon:AggressiveMoveToLocation(POS);

		-- attack move to random center
		POS = Survival_GetPOS(1, 25);
		aiPlatoon:AggressiveMoveToLocation(POS);

	else -- default/order 1 is move

		-- move to random path
		POS = Survival_GetPOS(2, 25);
		aiPlatoon:MoveToLocation(POS, false);

		-- move to random center
		POS = Survival_GetPOS(1, 25);
		aiPlatoon:MoveToLocation(POS, false);
	end

end



-- calculates how many units to spawn per wave
--------------------------------------------------------------------------
function Survival_CalcWaveCounts()

	local WaveMultiplier = ScenarioInfo.Options.opt_Survival_WaveFrequency / 60;
	Survival_UnitCountPerMinute = ScenarioInfo.Options.opt_Survival_EnemiesPerMinute * Survival_PlayerCount;
	Survival_UnitCountPerWave = Survival_UnitCountPerMinute * WaveMultiplier;
	LOG("----- Survival MOD: CalcWaveCounts = ((" .. ScenarioInfo.Options.opt_Survival_EnemiesPerMinute .. " EPM * " .. Survival_PlayerCount .. " Players = " .. Survival_UnitCountPerMinute .. ")) * ((" .. ScenarioInfo.Options.opt_Survival_WaveFrequency .. " Second Waves / 60 = " .. WaveMultiplier .. ")) = " .. Survival_UnitCountPerWave .. " Units Per Wave     (( with Waves Per Minute of " .. (60 / ScenarioInfo.Options.opt_Survival_WaveFrequency) .. " = " .. (Survival_UnitCountPerWave * (60 / ScenarioInfo.Options.opt_Survival_WaveFrequency)) .. " of " .. Survival_UnitCountPerMinute .. " Units Per Minute.");
--	LOG("----- Survival MOD: CalcWaveCounts() accounts for " .. Survival_UnitCountPerWave .. " of " .. Survival_UnitCountPerMinute .. " units " .. (60 / ScenarioInfo.Options.opt_Survival_WaveFrequency) .. " times per minute.");

end



-- calculates how many units to spawn per wave
--------------------------------------------------------------------------
function Survival_CalcNukeFrequency()

	local RatioEPM = (math.min(ScenarioInfo.Options.opt_Survival_EnemiesPerMinute, 64) - 16) / 48; -- returns 0-1 based on EPM difficulty
	
	 -- Additional difficulty scaling.  This increases the nuke frequency by 3 seconds for every 8 points of difficulty.
	RatioEPM = RatioEPM + math.max(ScenarioInfo.Options.opt_Survival_EnemiesPerMinute - 64, 0) * 0.00625;
	
	
	local RatioPC = (Survival_PlayerCount - 1) / 3; -- returns 0-1 based on player count

 	Survival_NukeFrequency = 135 - (RatioPC * 60) - (RatioEPM * 60);

	LOG("----- Survival MOD: CalcNukeFrequency = " .. " 135 - (RatioEPM: " .. RatioEPM * 60 .. "/" .. RatioEPM .. ") - (RatioPC: " .. RatioPC * 60 .. "/" .. RatioPC .. ") = " .. Survival_NukeFrequency);
--	LOG("----- Survival MOD: CalcWaveCounts() accounts for " .. Survival_UnitCountPerWave .. " of " .. Survival_UnitCountPerMinute .. " units " .. (60 / ScenarioInfo.Options.opt_Survival_WaveFrequency) .. " times per minute.");

end



-- misc functions
--------------------------------------------------------------------------


-- returns hh:mm:ss from second count
-- taken from original survival script
SecondsToTime = function(Seconds)
	return string.format("%02d:%02d", math.floor(Seconds / 60), math.mod(Seconds, 60));
end

-- broadcast a text message to players
-- modified version of original survival script function
BroadcastMSG = function(MSG, Fade, TextColor)
	PrintText(MSG, 20, TextColor, Fade, 'center') ;	
end

-- gets map marker reference by name
-- taken from forum post by Saya
function GetMarker(MarkerName)
	return Scenario.MasterChain._MASTERCHAIN_.Markers[MarkerName]
end

-- returns a random spawn position
Survival_RandomizePOS = function(POS, x)

	local NewPOS = {0, 0, 0};

	NewPOS[1] = POS[1] + ((math.random() * (x * 2)) - x);
	NewPOS[3] = POS[3] + ((math.random() * (x * 2)) - x);

	return NewPOS;

end


--function OverrideDoDamage(self, instigator, amount, vector, damageType)
--    local preAdjHealth = self:GetHealth()
--    self:AdjustHealth(instigator, -amount)
--    local health = self:GetHealth()
--    if (( health <= 0 ) or ( amount > preAdjHealth )) and not self.KilledFlag then
--        self.KilledFlag = true
--        if( damageType == 'Reclaimed' ) then
--            self:Destroy()
--        else
--            local excessDamageRatio = 0.0
--            # Calculate the excess damage amount
--            local excess = preAdjHealth - amount
--            local maxHealth = self:GetMaxHealth()
--            if(excess < 0 and maxHealth > 0) then
--                excessDamageRatio = -excess / maxHealth
--            end
--            IssueClearCommands({self})
--            ForkThread( UnlockAndKillUnitThread, self, instigator, damageType, excessDamageRatio )
--        end
--    end
--end