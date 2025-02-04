-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.font = wezterm.font("MesloLGS Nerd Font")
config.font_size = 15.5
config.enable_tab_bar = false
config.window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}
config.term = "tmux-256color" -- this has to be set for tmux's Ctrl-Space + [ to work
-- config.term = "xterm-kitty" -- might be needed for images to work, see https://www.youtube.com/watch?v=8m88Mh12yVw&t=121s

-- To enable kitty graphics
-- https://github.com/wez/wezterm/issues/986
-- It seems that kitty graphics is not enabled by default according to this
-- Not sure, so I'm enabling it just in case
-- https://github.com/wez/wezterm/issues/1406#issuecomment-996253377
config.enable_kitty_graphics = true

config.window_decorations = "TITLE | RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.max_fps = 120

return config
