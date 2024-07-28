-- Volume Control
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")

local timer = gears.timer
local spawn = awful.spawn

local function readcommand(command)
	local file = io.popen(command)
	if file == nil then
		print("volume-control: Failed to execute command: " .. command)
		return nil
	end
	local text = file:read("*all")
	file:close()
	return text
end

local function quote_arg(str)
	return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local function table_map(func, tab)
	local result = {}
	for i, v in ipairs(tab) do
		result[i] = func(v)
	end
	return result
end

local function make_argv(args)
	return table.concat(table_map(quote_arg, args), " ")
end

local function substitute(template, context)
	if type(template) == "string" then
		return (template:gsub("%${([%w_]+)}", function(key)
			return tostring(context[key] or "default")
		end))
	else
		-- function / functor:
		return template(context)
	end
end

local function new(self, ...)
	local instance = setmetatable({}, { __index = self })
	return instance:init(...) or instance
end

local function class(base)
	return setmetatable({ new = new }, {
		__call = new,
		__index = base,
	})
end

------------------------------------------
-- Volume control interface
------------------------------------------

local vcontrol = class()

function vcontrol:init(args)
	self.callbacks = {}
	self.cmd = "pactl"
	self.type = args.type or "sink"
	self.device = args.device or nil
	if args.device == nil then
		if self.type == "source" then
			self.device = "@DEFAULT_SOURCE@"
		elseif self.type == "monitor" then
			self.device = "@DEFAULT_MONITOR@"
		else
			self.device = "@DEFAULT_SINK@"
		end
	end
	self.step = args.step or "5%"

	if args.timeout then
		self.timer = timer({ timeout = args.timeout })
		self.timer:connect_signal("timeout", function()
			self:update()
		end)
		self.timer:start()
	end
end

function vcontrol:register(callback)
	if callback then
		table.insert(self.callbacks, callback)
	end
end

function vcontrol:action(action)
	if self[action] then
		self[action](self)
	elseif type(action) == "function" then
		action(self)
	elseif type(action) == "string" then
		spawn(action)
	end
end

function vcontrol:update()
	local volume = tonumber(self:mixercommand("get", "volume"):match("(%d?%d?%d)%%"))
	local muted = self:mixercommand("get", "mute"):find("yes") ~= nil
	for _, callback in ipairs(self.callbacks) do
		callback(self, {
			volume = volume,
			state = muted and "off" or "on",
			muted = muted,
			on = not muted,
		})
	end
end

function vcontrol:mixercommand(action, property, ...)
	local args = awful.util.table.join(
		{ self.cmd, action .. "-" .. self.type .. "-" .. property, self.device },
		{ ... }
	)
	return readcommand(make_argv(args))
end

function vcontrol:up()
	self:mixercommand("set", "volume", "+" .. self.step)
	self:update()
end

function vcontrol:down()
	self:mixercommand("set", "volume", "-" .. self.step)
	self:update()
end

function vcontrol:toggle()
	self:mixercommand("set", "mute", "toggle")
	self:update()
end

function vcontrol:mute()
	self:mixercommand("set", "mute", "1")
	self:update()
end

function vcontrol:unmute()
	self:mixercommand("set", "mute", "0")
	self:update()
end

function vcontrol:list_sinks()
	return readcommand("pactl list sinks"):gmatch("Description: ([^\n]+)")
end

function vcontrol:set_default_sink(name)
	os.execute(("pactl set-default-sink %s"):format(name))
end

------------------------------------------
-- Volume control widget
------------------------------------------

-- derive so that users can still call up/down/mute etc
local vwidget = class(vcontrol)

function vwidget:init(args)
	vcontrol.init(self, args)

	self.lclick = args.lclick or "toggle"
	self.mclick = args.mclick or "pavucontrol"
	self.rclick = args.rclick or self.show_menu

	self.widget = args.widget or (self:create_widget(args) or self.widget)
	self.tooltip = args.tooltip and (self:create_tooltip(args) or self.tooltip)

	self:register(args.callback or self.update_widget)
	self:register(args.tooltip and self.update_tooltip)

	self.widget:buttons(awful.util.table.join(
		awful.button({}, 1, function()
			self:action(self.lclick)
		end),
		awful.button({}, 2, function()
			self:action(self.mclick)
		end),
		awful.button({}, 3, function()
			self:action(self.rclick)
		end),
		awful.button({}, 4, function()
			self:up()
		end),
		awful.button({}, 5, function()
			self:down()
		end)
	))

	self:update()
end

-- text widget
function vwidget:create_widget(args)
	self.widget_text = {
		unmuted = "% 3d%% ",
		muted = "% 3dM ",
	}
	self.widget = wibox.widget.textbox()
	self.widget.set_align("right")
end

function vwidget:create_menu()
	local sinks = {}
	for sink in self:list_sinks() do
		local i = #sinks
		table.insert(sinks, {
			sink,
			function()
				self:set_default_sink(i)
			end,
		})
	end
	return awful.menu({
		items = {
			{
				"mute",
				function()
					self:mute()
				end,
			},
			{
				"unmute",
				function()
					self:unmute()
				end,
			},
			{ "Default Sink", sinks },
			{
				"pavucontrol",
				function()
					self:action("pavucontrol")
				end,
			},
		},
	})
end

function vwidget:show_menu()
	if self.menu then
		self.menu:hide()
	else
		self.menu = self:create_menu()
		self.menu:show()
		self.menu.wibox:connect_signal("property::visible", function()
			self.menu = nil
		end)
	end
end

function vwidget:update_widget(setting)
	self.widget:set_text(self.widget_text[setting.muted and "muted" or "unmuted"]:format(setting.volume))
end

-- tooltip
function vwidget:create_tooltip(args)
	self.tooltip_text = args.tooltip_text or [[
Volume: ${volume}% ${state}
Device: ${device}
Card: ${card}]]
	self.tooltip = args.tooltip and awful.tooltip({ objects = { self.widget } })
end

function vwidget:update_tooltip(setting)
	self.tooltip:set_text(substitute(self.tooltip_text, {
		volume = setting.volume,
		state = setting.state,
		device = self.device,
		card = self.card,
	}))
end

-- provide direct access to the control class
vwidget.control = vcontrol
return vwidget
