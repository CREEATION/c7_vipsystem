# Gunmenu Setup

## General

- Every page in the menu only shows a maximum of **`7`** items at once
- Start a line with a _semicolon_ (`;`) to disable it

## Formatting

You can format names using

- `\d` = _default color_
- `\r` = _red_
- `\y` = _yellow_
- `\w` = _white_
- `\n` = _new line_

# Weapons Overview

| Type        | ID          | Name             |
| ----------- | ----------- | ---------------- |
| _primary_   | `ak47`      | **AK-47**        |
| _primary_   | `m4a1`      | **M4A1**         |
| _primary_   | `famas`     | **FAMAS**        |
| _primary_   | `awp`       | **AWP**          |
| _primary_   | `m249`      | **M249 LMG**     |
| _primary_   | `galil`     | **AUG**          |
| _primary_   | `aug`       | **SG 552**       |
| _primary_   | `sg552`     | **Galil**        |
| _primary_   | `m3`        | **M3**           |
| _primary_   | `xm1014`    | **M4 Super 90**  |
| _primary_   | `mac10`     | **MAC-10**       |
| _primary_   | `tmp`       | **TMP**          |
| _primary_   | `mp5navy`   | **MP5**          |
| _primary_   | `ump45`     | **UMP**          |
| _primary_   | `p90`       | **P90**          |
| _primary_   | `scout`     | **Scout**        |
| _primary_   | `g3sg1`     | **G3 SG 1**      |
| _primary_   | `sg550`     | **SG 550**       |
| -           | -           | -                |
| _secondary_ | `deagle`    | **Desert Eagle** |
| _secondary_ | `usp`       | **USP**          |
| _secondary_ | `glock18`   | **Glock 18**     |
| _secondary_ | `elite`     | **Dual Elites**  |
| _secondary_ | `fiveseven` | **Five-Seven**   |
| _secondary_ | `p228`      | **P228**         |

# Examples

## Predefined Setups

`+weapon_id_1 weapon_id_2: "Setup Name"`

```
+m4a1 deagle: "M4A1 \r+ \wDeagle"
+ak47 deagle: "AK-47 \r+ \wDeagle"
+famas deagle: "FAMAS \r+ \wDeagle"
+awp deagle: "AWP \r+ \wDeagle"
```

## Single Weapon Entries

`weapon_id: "Weapon Name"`

```
ak47: "AK-47"
m4a1: "M4A1"
deagle: "Deagle"
elite: "Dual Elite"
```
