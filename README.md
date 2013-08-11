## awesome.volume-control

### Description

Volume indicator+control widget for awesome window manager.

### Installation

Drop the script into your awesome config folder. Suggestion:

    cd ~/.config/awesome
    git clone https://github.com/coldfix/awesome.volume-control.git
    ln -s awesome.volume-control/volume-control.lua


### Usage

In your `rc.lua`:

    -- load the widget code
    local volume_control = require("volume-control")


    -- define your volume control
    volumecfg = volume_control({channel="Master"})

    -- open alsamixer in terminal on middle-mouse
    volumecfg.widget:buttons(awful.util.table.join(
        volumecfg.widget:buttons(),
        awful.button({ }, 2,
            function() awful.util.spawn(TERMINAL .. " -x alsamixer") end)
    ))


    -- add the widget to your wibox
    ...
    right_layout:add(volumecfg.widget)
    ...


### Requirements

* [awesome 3.5](http://awesome.naquadah.org/)
