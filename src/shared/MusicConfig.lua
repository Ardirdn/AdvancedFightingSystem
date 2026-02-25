--[[
    MUSIC PLAYER CONFIG
    Place this script in ReplicatedStorage as a ModuleScript named "MusicConfig"
    
    Structure:
    - Playlists contain multiple songs
    - Each playlist has a name, thumbnail image ID, and list of songs
    - Each song has a title and audio ID
]]

local MusicConfig = {}

-- Playlist Configuration
-- Format: PlaylistName = { Thumbnail = "rbxassetid://...", Songs = {...} }
MusicConfig.Playlists = {
	["Indonesian DJ"] = {
		Thumbnail = "rbxassetid://78595834427114", -- Ganti dengan image ID playlist
		Songs = {

			{ Title = "Mejikuhibiniu", SoundId = "rbxassetid://77863478795420" },
			{ Title = "Mimi susu", SoundId = "rbxassetid://128476592786420" },
			{ Title = "Cinta Satu Malam", SoundId = "rbxassetid://93348063121828" },
			{ Title = "Aku Bt Di Cuekin", SoundId = "rbxassetid://76563579307159" },
			{ Title = "Goyang Gayung", SoundId = "rbxassetid://137977556699803" },
			{ Title = "Bintang 5", SoundId = "rbxassetid://115599341598582" },
			{ Title = "Mama Muda", SoundId = "rbxassetid://124108093410566" },
			{ Title = "Rindu Aku Rindu Kamu", SoundId = "rbxassetid://131737532295850" },
			{ Title = "Engga Dulu", SoundId = "rbxassetid://73977764935040" },
			{ Title = "Move On", SoundId = "rbxassetid://83032606928037" },
			{ Title = "Maimunah", SoundId = "rbxassetid://99313242972355" },
			{ Title = "Chori Sonia", SoundId = "rbxassetid://93004053325324" },
			{ Title = "Calon Mantu Idaman", SoundId = "rbxassetid://100650857279325" },
		},
	},
	["East Indonesian DJ"] = {
		Thumbnail = "rbxassetid://116964566373041",
		Songs = {
			{ Title = "Pica Pica", SoundId = "rbxassetid://98454206554444" },
			{ Title = "Ta Bola Bale", SoundId = "rbxassetid://127264065519682" },
			{ Title = "Tor Monitor Ketua", SoundId = "rbxassetid://107542838585296" },
			{ Title = "Pica Pica X Ta Bola Bale", SoundId = "rbxassetid://70642058369453" },
			{ Title = "Tia Monika", SoundId = "rbxassetid://83839613716494" },
		},
	},

	["Foreign DJ"] = {
		Thumbnail = "rbxassetid://131936462969181",
		Songs = {
			{ Title = "Mashup Barat", SoundId = "rbxassetid://117735386240962" },
			{ Title = "One In A Million", SoundId = "rbxassetid://140630609972572" },
			{ Title = "One Day", SoundId = "rbxassetid://78668194723814" },
			{ Title = "Rock", SoundId = "rbxassetid://105290507963805" },
			{ Title = "Phonk", SoundId = "rbxassetid://124193981970843" },
			{ Title = "Body Back Slow", SoundId = "rbxassetid://94826812911420" },
			{ Title = "Meldoy Sweet Love", SoundId = "rbxassetid://76109843754464" },
			{ Title = "The Drum", SoundId = "rbxassetid://135843452321822" },
			{ Title = "Legendaris", SoundId = "rbxassetid://74472716369386" },
			{ Title = "The Drum X Lamunan X Ya Odna", SoundId = "rbxassetid://88047252363171" },
			{ Title = "Breakbeat", SoundId = "rbxassetid://134201615365226" },
			{ Title = "Romlos Propun", SoundId = "rbxassetid://82448857819608" },
			{ Title = "NakamaToma Toma", SoundId = "rbxassetid://119973752714941" },
			{ Title = "Closer Your Eyes", SoundId = "rbxassetid://79432918986167" },
			{ Title = "Worth It Dance", SoundId = "rbxassetid://85942411727025" },
			{ Title = "Desert Rain", SoundId = "rbxassetid://114935365460501" },
			{ Title = "People", SoundId = "rbxassetid://76488904302126" },
			{ Title = "Timber", SoundId = "rbxassetid://108508626260017" },
			{ Title = "Life Break", SoundId = "rbxassetid://98588423461316" },
			{ Title = "Romlos Propun Thailand", SoundId = "rbxassetid://83948067433652" },
			{ Title = "Habibi", SoundId = "rbxassetid://77799295320271" },
			{ Title = "Broken Boys Anthem", SoundId = "rbxassetid://80974765520245" },
			{ Title = "Lie To Me", SoundId = "rbxassetid://81101352157079" },
		},
	},
}

return MusicConfig