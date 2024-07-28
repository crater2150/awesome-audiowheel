-- Volume Control
local awful = require("awful")
local gears = require("gears")
local util = require("audiowheel.volume-control.util")

local timer = gears.timer
local spawn = awful.spawn

local vcontrol = util.class()

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
	self:register(args.callback)
	self:update()
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
	return util.readcommand(util.make_argv(args))
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
	return util.readcommand("pactl list sinks"):gmatch("Description: ([^\n]+)")
end

function vcontrol:set_default_sink(name)
	os.execute(("pactl set-default-sink %s"):format(name))
end

return vcontrol
