-- radial volume widget popping up in the middle of the screen when changing
-- volume.
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local default_config = {
	size = 180,
	bg = "#000000aa",
	image_prefix = "/usr/share/icons/Papirus/48x48/status/",
	image_muted = "notification-audio-volume-muted.svg",
	image_low = "notification-audio-volume-low.svg",
	image_medium = "notification-audio-volume-medium.svg",
	image_high = "notification-audio-volume-high.svg",
	image_margin = 15,
	outer_margin = 15,
	bar_color = beautiful.border_focus or "#6666FF",
	bar_color_overdrive = "#FF6666",
	bar_color_muted = beautiful.border_normal or "#000000",
	volume_control = { tooltip = false },
	timeout = 1,
	use_alsactl = false,
}

local function loadIcon(path, icon_size)
	local cairo = require("lgi").cairo
	local Rsvg = require("lgi").Rsvg
	local img = cairo.ImageSurface(cairo.Format.ARGB32, icon_size, icon_size)
	local cr = cairo.Context(img)
	local handle = assert(Rsvg.Handle.new_from_file(path))
	local dim = handle:get_dimensions()
	local aspect = math.min(icon_size / dim.width, icon_size / dim.height)
	cr:scale(aspect, aspect)
	handle:render_cairo(cr)
	return img
end

local function get_image(config, volume, state)
	local icon_size = config.size - 2 * config.image_margin
	if volume == nil or volume == 0 or state == "off" then
		return loadIcon(config.image_prefix .. config.image_muted, icon_size)
	elseif volume <= 33 then
		return loadIcon(config.image_prefix .. config.image_low, icon_size)
	elseif volume <= 66 then
		return loadIcon(config.image_prefix .. config.image_medium, icon_size)
	else
		return loadIcon(config.image_prefix .. config.image_high, icon_size)
	end
end

local function create_elements(config)
	local image = wibox.widget({
		align = "center",
		valign = "center",
		widget = wibox.widget.imagebox,
		image = get_image(config, 0, "off"),
	})

	local voltext = wibox.widget({
		text = "n/a %",
		font = beautiful.fontface .. " 8",
		align = "center",
		valign = "center",
		widget = wibox.widget.textbox,
	})
	local arc = wibox.widget({
		{
			{
				voltext,
				image,
				layout = wibox.layout.align.vertical,
			},
			top = config.image_margin,
			bottom = config.image_margin,
			left = config.image_margin,
			right = config.image_margin,
			widget = wibox.container.margin,
		},
		values = { 0, 20 },
		colors = { config.bar_color_overdrive, config.bar_color },
		max_value = 100,
		min_value = 0,
		rounded_edge = true,
		border_width = 0.5,
		border_color = "#000000",
		widget = wibox.container.arcchart,
	})

	local volbox = wibox({
		screen = mouse.screen,
		width = config.size,
		height = config.size,
		visible = false,
		ontop = true,
		bg = "#00000000",
	})
	volbox.widget = wibox.widget({
		{
			arc,
			top = config.outer_margin,
			bottom = config.outer_margin,
			left = config.outer_margin,
			right = config.outer_margin,
			widget = wibox.container.margin,
		},
		widget = wibox.container.background,
		bg = config.bg,
		shape = gears.shape.circle,
	})

	local geo = volbox.screen.geometry
	volbox.x = geo.x + ((geo.width - volbox.width) / 2)
	volbox.y = geo.y + ((geo.height - volbox.height) / 2)

	return volbox, arc, image, voltext
end

local function set_radial(config, radial, volume, state)
	if volume == 0 or state == "off" then
		radial.colors = { config.bar_color_muted }
	else
		radial.colors = { config.bar_color_overdrive, config.bar_color }
	end
	if volume > 200 then
		radial.values = { 100, 0 }
	elseif volume > 100 then
		local overdrive = volume - 100
		radial.values = { overdrive, 100 - overdrive }
	else
		radial.values = { 0, volume }
	end
end

local function init(self, myconfig)
	local config = awful.util.table.crush(awful.util.table.clone(default_config), myconfig or {})

	local volbox, arc, image, voltext = create_elements(config)
	local volume_control = config.use_alsactl and require("audiowheel.volume-control")
		or require("audiowheel.volume-control.pulse")

	local volume_cfg = volume_control(awful.util.table.join(config.volume_control, {
		widget = volbox,
		callback = function(self, setting)
			if setting.volume then
				image.image = get_image(config, setting.volume, setting.state)
				voltext.text = setting.volume .. " %"
				set_radial(config, arc, setting.volume, setting.state)
			end
		end,
	}))

	local t = gears.timer({
		timeout = config.timeout,
		callback = function()
			volbox.visible = false
		end,
		single_shot = true,
	})

	local vol = {}
	-- stylua: ignore start
	vol.up     = function() volume_cfg:update(); volbox.visible = true; volume_cfg:up();     t:again() end
	vol.down   = function() volume_cfg:update(); volbox.visible = true; volume_cfg:down();   t:again() end
	vol.toggle = function() volume_cfg:update(); volbox.visible = true; volume_cfg:toggle(); t:again() end
	-- stylua: ignore end

	vol.mixer = volume_cfg
	return vol
end

-- init on first method call, if no configure parameters were given on require
return setmetatable({}, { __call = init })
