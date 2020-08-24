# C7 VIP System

## Features

- Fully customizable gunmenu via ini file
- Custom gun presets in gunmenu, if configured
- Enable gunmenu after round **X** (doesn't count draw-rounds)
- Extra HP & money for kills _(more HP/money for headshots, configurable)_
- Show damage dealt & recieved on HUD near the crosshair
- Restrict AWP/Auto-Sniper for non-VIP if desired
- Show a MOTD window when typing **/wantvip** in chat
- Green screen-flash when killing someone

## Gunmenu showcase

![Gunmenu showcase](https://i.imgur.com/gnak3YA.jpg)

# Development

## Basic, dirty Setup

1. [Download and install AMX Mod X](https://www.amxmodx.org/downloads.php) (install to `.../steamapps/common/Half-Life/cstrike`)
2. AMXX can now be found at `.../steamapps/common/Half-Life/cstrike/addons/amxmodx`
3. Copy the contents of this repository into `/addons/amxmodx`
4. Use your favorite Text Editor or IDE to open `/amxmodx/scripting/c7_vipsystem.sma`
5. Fiddle around
6. Use `/amxmodx/scripting/compile.exe` to compile the plugin
7. The compiled plugin should now be located at `/amxmodx/scripting/compiled`
8. Copy `/amxmodx/scripting/compiled/c7_vipsystem.amxx` into `/amxmodx/plugins/`
9. Start a LAN Server (`New Game`) and test!

## Advanced, pretty Setup

- [ ] TODO: write down
