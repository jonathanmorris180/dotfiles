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
-- config.term = "xterm-kitty" -- Needed for image.nvim to work (see here: https://www.youtube.com/watch?v=8m88Mh12yVw&ab_channel=linkarzu) but apparently not
config.term = "tmux-256color" -- Seems to work fine with images now, and this allows the cursor to behave as expected in Neovim

-- To enable kitty graphics
-- https://github.com/wez/wezterm/issues/986
-- It seems that kitty graphics is not enabled by default according to this
-- Not sure, so I'm enabling it just in case
-- https://github.com/wez/wezterm/issues/1406#issuecomment-996253377
config.enable_kitty_graphics = true
-- config.cursor_blink_rate = 0

config.window_decorations = "TITLE | RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.max_fps = 120

return config
