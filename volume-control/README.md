# audiowheel.volume-control

## Description

Volume control library for awesomeWM, based on
https://github.com/deficient/volume-control.git, adapted for audiowheel.

## Configuration options

The available options differ for the pulse-based implementation (which is used
by default) and the alsa-based implementation.

### Pulse options

You can specify any subset of the following arguments in the `volume_control`
table in audiowheel's config (listed here with the default values):

```lua
device = nil
```
Allows you to set the device manually. If left at `nil`, will use your default
device (i.e. depending on the type `@DEFAULT_SOURCE@`, `@DEFAULT_MONITOR@`, or
`@DEFAULT_SINK@`)

```lua
type = "sink"
```
Can be `"sink"`, `"source"`, or `"monitor"`

```lua
step = '5%'
```
Sets the step size used by volume `:up()` and `:down()` methods.
Any format accepted by `pactl set-volume` is allowed, signs (`+` or `-`) are added automatically.

```lua
timeout = nil
```
If set, the library will update the current state periodically. If you use it
inside audiowheel, you should not set this, as an update is called, whenever the
audiowheel widget is displayed.

### Alsa options

If you set `use_alsactl = true` in audiowheel's config, you can specify any
subset of the following arguments in the `volume_control` table  (listed here
with the default values):

```lua
device  = nil,      -- e.g.: "default", "pulse"
cardid  = nil,      -- e.g.: 0, 1, ...
channel = "Master",
```
Specify the ALSA device, card and channel, that should be used.

```lua
step = '5%'
```
Sets the step size used by volume `:up()` and `:down()` methods.
Any format accepted by `amixer set` is allowed, signs (`+` or `-`) are added automatically.
