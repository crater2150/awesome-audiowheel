-- Volume Control
local awful = require("awful")
local gears = require("gears")
local util = require("audiowheel.volume-control.util")

local timer = gears.timer
local spawn = awful.spawn
local watch = awful.spawn.with_line_callback

local vcontrol = util.class()

function vcontrol:init(args)
	self.callbacks = {}
	self.cmd = "amixer"
	self.device = args.device or nil
	self.cardid = args.cardid or nil
	self.channel = args.channel or "Master"
	self.step = args.step or "5%"

	self.timer = timer({ timeout = args.timeout or 0.5 })
	self.timer:connect_signal("timeout", function()
		self:get()
	end)
	self.timer:start()

	self:register(args.callback)
	self:get()

	if (args.listen or args.listen == nil) and watch then
		self.listener = watch({ "stdbuf", "-oL", "alsactl", "monitor" }, {
			stdout = function(line)
				self:get()
			end,
		})
		awesome.connect_signal("exit", function()
			awesome.kill(self.listener, awesome.unix_signal.SIGTERM)
		end)
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

function vcontrol:update(status)
	local volume = status:match("(%d?%d?%d)%%")
	local state = status:match("%[(o[nf]*)%]")
	if volume and state then
		local volume = tonumber(volume)
		local state = state:lower()
		local muted = state == "off"
		for _, callback in ipairs(self.callbacks) do
			callback(self, {
				volume = volume,
				state = state,
				muted = muted,
				on = not muted,
			})
		end
	end
end

function vcontrol:mixercommand(...)
	local args = awful.util.table.join(
		{ self.cmd },
		self.device and { "-D", self.device } or {},
		self.cardid and { "-c", self.cardid } or {},
		{ ... }
	)
	return util.readcommand(util.make_argv(args))
end

function vcontrol:get()
	self:update(self:mixercommand("get", self.channel))
end

function vcontrol:up()
	self:update(self:mixercommand("set", self.channel, self.step .. "+"))
end

function vcontrol:down()
	self:update(self:mixercommand("set", self.channel, self.step .. "-"))
end

function vcontrol:toggle()
	self:update(self:mixercommand("set", self.channel, "toggle"))
end

function vcontrol:mute()
	self:update(self:mixercommand("set", "Master", "mute"))
end

function vcontrol:unmute()
	self:update(self:mixercommand("set", "Master", "unmute"))
end

return vcontrol
