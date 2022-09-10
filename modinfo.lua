---@diagnostic disable: lowercase-global
name = "Genshin impact Music pack"
description = "Music mod pack"
author = "♪ Mio and 1526606449"
version = "1.2.0"
forumthread = ""
api_version = 10
icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- For Don't Starve Together
dst_compatible = true

-- This version is not for single player
dont_starve_compatible = false
reign_of_giants_compatible = false

--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = false

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = true

configuration_options =
{
	{
		name = "music_mode",
		label = "Music Mode",
		options =	{
						{description = "Continuous", data = "default", hover = "Music will always play."},
						{description = "Working", data = "busy", hover = "Music only plays if you're working."},
					},

		default = "default",
	
	},
}