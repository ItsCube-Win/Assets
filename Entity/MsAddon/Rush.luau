
local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"))()

local entity = Spawner:Create({
	Entity = {
		Name = "Rush",
		Asset = "https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main/Assets/Entities/Rush.rbxm",
		HeightOffset = 0
	},
	Lights = {
		Flicker = {
			Enabled = true,
			Duration = 4
		},
		Shatter = true,
		Repair = false
	},
	Earthquake = {
		Enabled = false
	},
	CameraShake = {
		Enabled = true,
		Range = 100,
		Values = {1.5, 20, 0.1, 1}
	},
	Movement = {
		Speed = 100,
		Delay = 6,
		Reversed = false
	},
	Rebounding = {
		Enabled = false,
		Type = "Ambush",
		Min = 1,
		Max = 1,
		Delay = 2
	},
	Damage = {
		Enabled = false,
		IgnoreHiding = false,
		Range = 40,
		Amount = 125
	},
	Crucifixion = {
        Type = "Guiding",
		Enabled = false,
		Range = 40,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding",
		Hints = {"No way", "!", "!", "!"},
		Cause = ""
	}
})

entity:Run(true)
