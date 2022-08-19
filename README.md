![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/banner3.png)

# Preview

- [Youtube video](https://youtu.be/lGgsUonmXmw)

# Dependencies

- [qb-target](https://github.com/BerkieBb/qb-target)
- [qb-menu](https://github.com/qbcore-framework/qb-menu)

# Key Features

- NoPixel inspired oil company
- Owning oilwells
- ...

## Patch 1.1.0 (employees)

- new notifications when an oilwell part breaks.
- oilwell owners can employ a person to operate their oilwells for them. (employees have access to crude oil transfer, but when they use it, it sends available oil to the owner's storage, not the employee's storage.)
- employees should have `oilwell` job.
- owners can fire their employees at will employees access will be revoked immediately.
- removed some data which should not be available on client-side.
- added script loading report.
- the CEO have ability to remove any oilwell from now on (this is not a permanent removal therefore oil wells are just flagged as deleted for easy recovery).
- information menu is now recives data directly from server.

### How to update to new patch (database changes):

- 1. update your `oilrig_position` by using ALTER TABLE available at end of sql.sql
- 2. import new table `oilcompany_employees`

## Patch 1.0.0

- (important) if you are using old version make sure you have a backup.

- balanced oil production for 1 hour
- to be able to operate oilwells players must be on duty
- oilwells now take damege and players should fix them or they will stop working
- new items to fix oilwells
- transport accepts all oil types
- new oil types
- blender new formula and new elemnts
- qb-target won't despawn with objects
- fixed qb-target not showing up
- fixed props blinking
- fixed props not spawning if players don't have oilwell job
- better check for job and onduty
- new withdraw system
- withdraw purge menu
- added octane calculation
- showing oilwell prop before assigning them
- oilbarell props
- to be honest there was so many changes i don't remember most of them!

## Usage

- add oilwell by "/create oilwell" and then place and asign it to a player. (admins)
- or use 'oilwell' item to spawn oilwell

## Installation

## Step 0:

- import sql.sql in your database

## Step 1:

\*\* qb-core shared items.lua

```lua
["oilbarell"] = {
		["name"] = "oilbarell",
		["label"] = "Oil barell",
		["weight"] = 15000,
		["type"] = "item",
		["image"] = "oilBarrel.png",
		["unique"] = true,
		["useable"] = false,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Oil Barrel"
},
["oilwell"] = {
		["name"] = "oilwell",
		["label"] = "Oilwell",
		["weight"] = 50000,
		["type"] = "item",
		["image"] = "oilwell.png",
		["unique"] = false,
		["useable"] = true,
		["shouldClose"] = true,
		["combinable"] = nil,
		["description"] = "Oilwell"
},
["reliefvalvestring"] = {
	["name"] = "reliefvalvestring",
	["label"] = "Relief Valve String",
	["weight"] = 4000,
	["type"] = "item",
	["image"] = "relief_valve_string.png",
	["unique"] = false,
	["useable"] = true,
	["shouldClose"] = true,
	["combinable"] = nil,
	["description"] = "Relief Valve String"
},
["oilfilter"] = {
	["name"] = "oilfilter",
	["label"] = "Oil Filter",
	["weight"] = 5000,
	["type"] = "item",
	["image"] = "oil_filter.png",
	["unique"] = false,
	["useable"] = true,
	["shouldClose"] = true,
	["combinable"] = nil,
	["description"] = "Oil Filter"
},
["skewgear"] = {
	["name"] = "skewgear",
	["label"] = "Skew Gear",
	["weight"] = 6000,
	["type"] = "item",
	["image"] = "skew_gear.png",
	["unique"] = false,
	["useable"] = true,
	["shouldClose"] = true,
	["combinable"] = nil,
	["description"] = "Skew Gear"
},
["timingchain"] = {
	["name"] = "timingchain",
	["label"] = "Timing Chain",
	["weight"] = 7000,
	["type"] = "item",
	["image"] = "timing_chain.png",
	["unique"] = false,
	["useable"] = true,
	["shouldClose"] = true,
	["combinable"] = nil,
	["description"] = "Timing Chain"
},
["driveshaft"] = {
	["name"] = "driveshaft",
	["label"] = "Drive Shaft",
	["weight"] = 5000,
	["type"] = "item",
	["image"] = "drive_shaft.png",
	["unique"] = false,
	["useable"] = true,
	["shouldClose"] = true,
	["combinable"] = nil,
	["description"] = "Drive Shaft"
},

```

## Step 2:

\*\* qb-core shared jobs.lua

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

- in qb-inventory\js\app.js find FormatItemInfo() there is if statement like: if (itemData.name == "id_card")
- track where all of elseif statments are ended then add code below.

```javascript
else if (itemData.name == "oilbarell") {
	$(".item-info-title").html("<p>" + itemData.label + "</p>");
	$(".item-info-description").html("<p>Gal: " + itemData.info.gal + "</p>" + "<p>Type: " + itemData.info.type + "</p>" + "<p>Octane: " + itemData.info.avg_gas_octane + "</p>");
}
```

# Support

- [Discord](https://discord.gg/ccMArCwrPV)

# Donation

- [Donation](https://swkeep.github.io)

![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_11-000275.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_18-000276.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_34-000277.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_46-000278.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_00_50-000279.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_04-000280.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_09-000281.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_11-000282.jpg)
![Keep oilwell](https://raw.githubusercontent.com/swkeep/keep-oilwell/main/.github/images/screenshots/2022-05-17-16_01_13-000283.jpg)
