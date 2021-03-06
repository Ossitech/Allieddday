options = 
{
	{ 
		default = 6, 
		label = "Survival: Build Time", 
		help = "Length of initial building time.", 
		key = 'opt_Survival_BuildTime', 
		pref = 'opt_Survival_BuildTime', 
		values = { 
			{text = "0:00",help = "", key = 0, },
			{text = "0:30",help = "", key = 30, }, 
			{text = "1:00",help = "", key = 60, }, 
			{text = "1:30",help = "", key = 90, }, 
			{text = "2:00",help = "", key = 120, }, 
			{text = "2:30",help = "", key = 150, }, 
			{text = "3:00",help = "", key = 180, }, 
			{text = "4:00",help = "", key = 240, }, 
			{text = "5:00",help = "", key = 300, },
			{text = "6:00",help = "", key = 360, }, 
			{text = "7:00",help = "", key = 420, }, 
			{text = "8:00",help = "", key = 480, }, 
			{text = "9:00",help = "", key = 540, }, 
			{text = "10:00",help = "", key = 600, }, 
		}, 
	},
	{ 
		default = 3, 
		label = "Survival: Difficulty", 
		help = "How many enemies attack each minute (per player).", 
		key = 'opt_Survival_EnemiesPerMinute', 
		pref = 'opt_Survival_EnemiesPerMinute', 
		values = {
			{text = "16 (Luschen)",help = "", key = 16, }, 
			{text = "24",help = "", key = 24, }, 
			{text = "32",help = "", key = 32, }, 
			{text = "40",help = "", key = 40, }, 
			{text = "48",help = "", key = 48, }, 
			{text = "56",help = "", key = 56, }, 
			{text = "64",help = "", key = 64, }, 
			{text = "72",help = "", key = 72, },
			{text = "80 (Heeftig Aktiv)",help = "", key = 80, },
		}, 
	},
	{ 
		default = 1, 
		label = "Survival: Wave Frequency", 
		help = "How long between waves.", 
		key = 'opt_Survival_WaveFrequency', 
		pref = 'opt_Survival_WaveFrequency', 
		values = { 
			{text = "Streaming",help = "", key = 10, }, 
			{text = "1:00 - Fast Waves",help = "", key = 60, }, 
			{text = "2:00 - Normal Waves",help = "", key = 120, }, 
			{text = "3:00 - Huge Waves",help = "", key = 180, }, 
			{text = "4:00 - Epic Waves",help = "", key = 240, }, 
		},
	},
};