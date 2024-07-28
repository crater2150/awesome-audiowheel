# audiowheel - popup audio volume widget

audiowheel is a module for [awesome](https://awesomewm.org/). It displays a
arcchart with the current volume for a few seconds whenever a volume key is pressed.

![example](https://user-images.githubusercontent.com/415635/32248192-21094d06-be85-11e7-9c05-d9553c85fca8.gif)

*requires awesome 4.0+. based on [deficient/volume-control](https://github.com/deficient/volume-control)*

## Installation

Put this repository somewhere in the lua search path for awesome, name it
`audiowheel`. If your awesome configuration is managed by git, I recommend
adding this repo as a git submodule:

```
git submodule add https://github.com/crater2150/awesome-audiowheel.git audiowheel
```

## Usage

Include audiowheel in your `rc.lua`, create a new instance and use its
methods for volume key bindings:

```lua
audiowheel = require("audiowheel")

speakerwheel = audiowheel {}

-- in your binding table, add:
    awful.key({}, "XF86AudioRaiseVolume", function() speakerwheel:up() end),
    awful.key({}, "XF86AudioLowerVolume", function() speakerwheel:down() end),
    awful.key({}, "XF86AudioMute",        function() speakerwheel:toggle() end)
```

You can create several audiowheels for diffent devices, e.g. another wheel for microphone volume ([see below](#customization) for more on the configuration options):

```lua
micwheel = audiowheel {
    image_prefix = "/usr/share/icons/Adwaita/48x48/legacy/",
    image_muted = "microphone-sensitivity-muted.png",
    image_low = "microphone-sensitivity-low.png",
    image_medium = "microphone-sensitivity-medium.png",
    image_high = "microphone-sensitivity-high.png",

    -- Uses the default pulseaudio source
	volume_control = { type = "source" },

    -- alternatively, if you don't use pulseaudio or pipewire-pulse, you need to
    -- set use_alsactl (see below) and define the channel, which depends on your
    -- soundcard
    volume_control = { channel = "Dmic0" }
}

-- add keybindings to different keys, e.g.:
    awful.key({"Shift"}, "XF86AudioRaiseVolume", function() micwheel:up() end),
    awful.key({"Shift"}, "XF86AudioLowerVolume", function() micwheel:down() end),
    awful.key({}, "XF86AudioMicMute",     function() micwheel:toggle() end)
```

## Customization

You can set configuration options when initializing a wheel. The
following call is equivalent to the default configuration:

```lua
local audiowheel = require("audiowheel") {
	-- size of the used wibox, i.e. the diameter of the whole circle
	size = 140,

	-- background of the widget
	bg = "#000000aa",

	-- paths for the speaker images. the prefix is concatenated with each of
	-- the four variants, based on current volume
	image_prefix = "/usr/share/icons/Adwaita/256x256/legacy/",
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

	-- configuration table for volume-control, see below
	volume_control = {},

    -- if set to true, use the original version of volume-control, otherwise use
    -- the pactl-based version. If in doubt, keep the pactl based version
	use_alsactl = false,
}
```
The detailed documentation for the `volume_control` option can be found in the
[`volume-control` README](volume-control/README.md).
