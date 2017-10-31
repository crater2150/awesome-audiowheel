# audiowheel - popup audio volume widget

audiowheel is a module for [awesome](https://awesomewm.org/). It displays a
arcchart with the current volume for a few seconds whenever a volume key is pressed.

![example](https://user-images.githubusercontent.com/415635/32248192-21094d06-be85-11e7-9c05-d9553c85fca8.gif)

*requires awesome 4.0+. based on ![deficient/volume-control](https://github.com/deficient/volume-control)*

## Installation

Put this repository somewhere in the lua search path for awesome, name it
`audiowheel`. If your awesome configuration is managed by git, I recommend
adding this repo as a git submodule:

```
git submodule add https://github.com/crater2150/awesome-audiowheel.git audiowheel
```

## Usage

Include audiowheel in your `awesomerc.lua` and use its methods for volume key
bindings:

```lua
local audiowheel = require("audiowheel")

-- in your binding table, add:
    awful.key({}, "XF86AudioRaiseVolume", function() audiowheel:up() end),
    awful.key({}, "XF86AudioLowerVolume", function() audiowheel:down() end),
    awful.key({}, "XF86AudioMute",        function() audiowheel:toggle() end)
```
## Customization

You can append a table to the `require` call to set configuration options. The
following call is equivalent to the default configuration:

```lua
local audiowheel = require("audiowheel") {
	-- size of the used wibox, i.e. the diameter of the whole circle
	size = 140,

	-- background of the widget
	bg = "#000000aa",

	-- paths for the speaker images. the prefix is concatenated with each of
	-- the four variants, based on current volume
	image_prefix = "/usr/share/icons/Adwaita/256x256/status/",
	image_muted = "audio-volume-muted.png",
	image_low = "audio-volume-low.png",
	image_medium = "audio-volume-medium.png",
	image_high = "audio-volume-high.png",

	-- margin between image and arc
	image_margin = 15,
	-- margin between arc and outer widget border
	outer_margin = 15,

	-- color of the volume arc
	bar_color = beautiful.border_focus or "#6666FF",
	bar_color_muted = beautiful.border_normal or "#000000",

	-- time after the last keypress to hide the widget again
	timeout = 1

	-- configuration table for volume-control. see volume-control's readme
	-- for more info
	volume_control = {tooltip = false},
}
```
