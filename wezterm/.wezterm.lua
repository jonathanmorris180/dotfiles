-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 15.5
config.enable_tab_bar = false
config.window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}

config.window_decorations = "TITLE | RESIZE"

return config
