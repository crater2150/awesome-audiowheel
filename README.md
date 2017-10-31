# audiowheel - popup audio volume widget

audiowheel is a module for [awesome](https://awesomewm.org/). It displays a
arcchart with the current volume, whenever a volume key is pressed:

![example](https://user-images.githubusercontent.com/415635/32248192-21094d06-be85-11e7-9c05-d9553c85fca8.gif)

*requires awesome 4.0+*

## Installation

Put this repository somewhere in the lua search path for awesome, name it
`audiowheel`. If your awesome configuration is managed by git, I recommend
adding this repo as a git submodule:

```
git submodule add https://github.com/crater2150/awesome-audiowheel.git audiowheel
```

## Usage


```lua
local vol_ctrl = require("audiowheel") {
  -- custom config here
}
```

TODO
