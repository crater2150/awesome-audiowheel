-- Volume Control
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")

-- compatibility fallbacks for 3.5:
local timer = gears.timer or timer
local spawn = awful.spawn or awful.util.spawn
local watch = awful.spawn and awful.spawn.with_line_callback


------------------------------------------
-- Private utility functions
------------------------------------------

local function readcommand(command)
    local file = io.popen(command)
    local text = file:read('*all')
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

------------------------------------------
-- Volume control interface
------------------------------------------

local vcontrol = {}

function vcontrol:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function vcontrol:init(args)
    self.callbacks = {}
    self.cmd = "amixer"
    self.device = args.device or nil
    self.cardid  = args.cardid or nil
    self.channel = args.channel or "Master"
    self.step = args.step or '5%'
    self.lclick = args.lclick or "toggle"
    self.mclick = args.mclick or "pavucontrol"
    self.rclick = args.rclick or "pavucontrol"

    self.widget = args.widget    or (self:create_widget(args)  or self.widget)
    self.tooltip = args.tooltip and (self:create_tooltip(args) or self.tooltip)

    self:register(args.callback or self.update_widget)
    self:register(args.tooltip and self.update_tooltip)

    self.widget:buttons(awful.util.table.join(
        awful.button({}, 1, function() self:action(self.lclick) end),
        awful.button({}, 2, function() self:action(self.mclick) end),
        awful.button({}, 3, function() self:action(self.rclick) end),
        awful.button({}, 4, function() self:up() end),
        awful.button({}, 5, function() self:down() end)
    ))

    self.timer = timer({ timeout = args.timeout or 0.5 })
    self.timer:connect_signal("timeout", function() self:get() end)
    self.timer:start()

    if (args.listen or args.listen == nil) and watch then
        self.listener = watch({'stdbuf', '-oL', 'alsactl', 'monitor'}, {
          stdout = function(line) self:get() end,
        })
        awesome.connect_signal("exit", function()
            awesome.kill(self.listener, 9)
        end)
    end

    self:get()

    return self
end

function vcontrol:register(callback)
    if callback then
        table.insert(self.callbacks, callback)
    end
end

function vcontrol:action(action)
    if self[action]                   then self[action](self)
    elseif type(action) == "function" then action(self)
    elseif type(action) == "string"   then spawn(action)
    end
end

function vcontrol:update(status)
    local volume = status:match("(%d?%d?%d)%%")
    local state  = status:match("%[(o[nf]*)%]")
    if volume and state then
        for _, callback in ipairs(self.callbacks) do
            callback(self, tonumber(volume), state:lower())
        end
    end
end

function vcontrol:mixercommand(...)
    local args = awful.util.table.join(
      {self.cmd},
      self.device and {"-D", self.device} or {},
      self.cardid and {"-c", self.cardid} or {},
      {...})
    return readcommand(make_argv(args))
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

-- text widget
function vcontrol:create_widget(args)
    self.widget_text = {
        on  = '% 3d%% ',
        off = '% 3dM ',
    }
    self.widget = wibox.widget.textbox()
    self.widget.set_align("right")
end

function vcontrol:update_widget(volume, state)
    self.widget:set_text(
        self.widget_text[state]:format(volume))
end

-- tooltip
function vcontrol:create_tooltip(args)
    self.tooltip_text = args.tooltip_text or [[
Volume: ${volume}% ${state}
Channel: ${channel}
Device: ${device}
Card: ${card}]]
    self.tooltip = args.tooltip and awful.tooltip({objects={self.widget}})
end

function vcontrol:update_tooltip(volume, state)
    self.tooltip:set_text(substitute(self.tooltip_text, {
        volume  = volume,
        state   = state,
        device  = self.device,
        card    = self.card,
        channel = self.channel,
    }))
end

return setmetatable(vcontrol, {
    __call = vcontrol.new,
})

