![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/banner2.png)

# Dependencies
* [qb-target](https://github.com/BerkieBb/qb-target)
* [qb-menu](https://github.com/qbcore-framework/qb-menu)
* [polyzone](https://github.com/qbcore-framework/PolyZone)

# Key Features
* NoPixel style oil company (it tried to make it as close as possible but i never played in that server so this maybe not be as close as i think!)
* Owning oilwell
* Passive income

# Missing Features
* Alot :)
* Storage action
* Acually using oils!
* and all things i didn't think of! 

# Installation
* IMPORTANT: This project is a WIP project of mine(as always) so expect too many bugs :)

** Step 1:
** shared items.lua
```lua 
["oilbarell"] = {
		["name"] = "oilbarell",
		["label"] = "Oil barell",
		["weight"] = 1000,
		["type"] = "item",
		["image"] = "oilBarrel.png",
		["unique"] = true,
		["useable"] = false,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Oil Barrel"
}
	,
["oilwell"] = {
		["name"] = "oilwell",
		["label"] = "Oilwell",
		["weight"] = 1000,
		["type"] = "item",
		["image"] = "oilwell.png",
		["unique"] = false,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Oilwell"
}
	,
["oilwellbelt"] = {
		["name"] = "oilwellbelt",
		["label"] = "oilwellbelt",
		["weight"] = 1000,
		["type"] = "item",
		["image"] = "oilwellbelt.png",
		["unique"] = false,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "oilwellbelt"
}
```
