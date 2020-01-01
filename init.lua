-- radial volume widget popping up in the middle of the screen when changing
-- volume.
-- Depends on volume-control (https://github.com/deficient/volume-control.git)
awful = require("awful")
wibox = require("wibox")
gears = require("gears")
volume_control = require("audiowheel.volume-control")
log = require("talkative")

local config = {
	size = 140,
	bg = "#000000aa",
	image_prefix = "/usr/share/icons/Adwaita/256x256/status/",
	image_muted = "audio-volume-muted.png",
	image_low = "audio-volume-low.png",
	image_medium = "audio-volume-medium.png",
	image_high = "audio-volume-high.png",
	image_margin = 15,
	outer_margin = 15,
	bar_color = beautiful.border_focus or "#6666FF",
	bar_color_muted = beautiful.border_normal or "#000000",
	volume_control = {tooltip = false},
	timeout = 1
}

function create_elements(config)
	local image = wibox.widget {
		align  = "center",
		valign = "center",
		widget = wibox.widget.imagebox,
		image = config.image_prefix .. config.image_muted
	}

	local arc = wibox.widget {
		{
			image,
			top    = config.image_margin,
			bottom = config.image_margin,
			left   = config.image_margin,
			right  = config.image_margin,
			widget = wibox.container.margin
		},
		value        = 20,
		colors       = { config.bar_color },
		max_value    = 100,
		min_value    = 0,
		rounded_edge = true,
		border_width = 0.5,
		border_color = "#000000",
		widget       = wibox.container.arcchart
	}

	local volbox = wibox{
		screen = mouse.screen, 
		width = config.size,
		height = config.size,
		visible = false,
		ontop = true,
		bg = "#00000000",
	}
	volbox.widget = wibox.widget {
		{
			arc,
			top    = config.outer_margin,
			bottom = config.outer_margin,
			left   = config.outer_margin,
			right  = config.outer_margin,
			widget = wibox.container.margin
		},
		widget = wibox.container.background,
		bg = config.bg,
		shape = gears.shape.circle
	}

	local geo = volbox.screen.geometry
	volbox.x = geo.x + ((geo.width - volbox.width) / 2)
	volbox.y = geo.y + ((geo.height - volbox.height) / 2)

	return volbox, arc, image
end

local function get_image(volume, state)
	if volume == 0 or state == "off"  then return config.image_prefix .. config.image_muted
	elseif volume <= 33               then return config.image_prefix .. config.image_low
	elseif volume <= 66               then return config.image_prefix .. config.image_medium
	else                                   return config.image_prefix .. config.image_high
	end
end

local function set_radial(radial, volume, state)
	if volume == 0 or state == "off"  then
		radial.colors = { config.bar_color_muted }
	else
		radial.colors = { config.bar_color }
	end
	radial.value = volume
end

local function init(self,myconfig)
	awful.util.table.crush(config, myconfig or {})

	local volbox, arc, image = create_elements(config)

	local volume_cfg = volume_control(awful.util.table.join(config.volume_control, {
		widget = volbox,
		callback = function(self, setting)
			image.image = get_image(setting.volume, setting.state)
			set_radial(arc, setting.volume, setting.state)
		end,
	}))

	local t = gears.timer({
		timeout = config.timeout,
		callback = function() volbox.visible = false end,
		single_shot=true
	});

	local vol = {}
	vol.up = function() volbox.visible = true; volume_cfg:up(); t:again() end
	vol.down = function() volbox.visible = true; volume_cfg:down(); t:again() end
	vol.toggle = function() volbox.visible = true; volume_cfg:toggle(); t:again() end
	return vol
end


-- init on first method call, if no configure parameters were given on require
return setmetatable({
	up = function(self) awful.util.table.crush(self, init()); self:up() end,
	down = function(self) awful.util.table.crush(self, init()); self:down() end,
	toggle = function(self) awful.util.table.crush(self, init()); self:toggle() end
}, { __call = init })
