![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/banner2.png)

# Dependencies
* [qb-target](https://github.com/BerkieBb/qb-target)
* [qb-menu](https://github.com/qbcore-framework/qb-menu)
* [polyzone](https://github.com/qbcore-framework/PolyZone)

# Key Features
* Kinda NoPixel inspired oil company (of course not complete as their version)
* Owning oilwell
* ...

# Missing Features
* Storage action
* Acually using products!
* and all things i didn't think of! 

## Usage
* add oilwell by "/create oilwell" and then place and asign it to a player.

## Installation
* IMPORTANT: This project is a WIP project of mine(as always) so expect too many bugs :)
## Step 0:
* import sql.sql in your database 

## Step 1:
** qb-core shared items.lua
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
## Step 2:
** qb-core shared jobs.lua
```lua
['oilwell'] = {
        label = 'Oil Company',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Oilwell Operator',
                payment = 50
            },
            ['1'] = {
                name = 'Oilwell Operator tier 2',
                payment = 75
            },
            ['2'] = {
                name = 'Event Driver tier 2',
                payment = 100
            },
            ['3'] = {
                name = 'Sales',
                payment = 125
            },
            ['4'] = {
                name = 'CEO',
                isboss = true,
                payment = 150
            },
        },
},
```

## Step 3: tooltip

* i'm using lj-inventory and it's just reskin of qb-inventory.
* in inventory\js\app.js find FormatItemInfo() there is if statement like: if (itemData.name == "id_card")
* track where all of elseif statments are ended then add else if below.

```javascript
else if (itemData.name == "oilbarell") {
	$(".item-info-title").html("<p>" + itemData.label + "</p>");
	$(".item-info-description").html("<p>Gal: " + itemData.info.gal + "</p>" + "<p>Type: " + itemData.info.type + "</p>" + "<p>Octane: " + itemData.info.avg_gas_octane + "</p>");
}
```

![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_11-000275.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_18-000276.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_34-000277.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_46-000278.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_50-000279.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_04-000280.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_09-000281.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_11-000282.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_13-000283.jpg)


