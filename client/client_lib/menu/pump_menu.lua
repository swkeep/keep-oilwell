local QBCore = exports['qb-core']:GetCoreObject()

local function showInfo(data)
     local selected_oilrig = data.metadata
     local header = "Name: " .. data.name
     local partInfoString = "Belt: " ..
         selected_oilrig.part_info.belt ..
         " Polish: " .. selected_oilrig.part_info.polish .. " Clutch: " .. selected_oilrig.part_info.clutch
     local duration = math.floor(selected_oilrig.duration / 60)
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-oil-well'
          }, {
               header = 'Speed',
               icon = 'fa-solid fa-gauge',
               txt = "" .. selected_oilrig.speed .. " RPM",
               disabled = true,
          },
          {
               header = 'Duration',
               icon = 'fa-solid fa-clock',
               txt = "" .. duration .. " Min",
               disabled = true,
          },
          {
               header = 'Temperature',
               icon = 'fa-solid fa-temperature-high',
               txt = "" .. selected_oilrig.temp .. " °C",
               disabled = true,
          },
          {
               header = 'Oil Storage',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. selected_oilrig.oil_storage .. "/Gal",
               disabled = true,
          },
          {
               header = 'Part Info',
               icon = 'fa-solid fa-oil-can',
               txt = partInfoString,
               disabled = true,
          },
          {
               header = 'Pump oil to storage',
               icon = 'fa-solid fa-arrows-spin',
               params = {
                    event = 'keep-oilrig:storage_menu:PumpOilToStorage',
                    args = {
                         oilrig_hash = data.oilrig_hash
                    }
               }
          },
          {
               header = 'leave',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end

local function show_oilwell_stash(data)
     local selected_oilrig = data.metadata
     local header = "Name: " .. data.name
     local partInfoString = "Belt: " ..
         selected_oilrig.part_info.belt ..
         " Polish: " .. selected_oilrig.part_info.polish .. " Clutch: " .. selected_oilrig.part_info.clutch
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-oil-well'
          },
          {
               header = 'Part Info',
               icon = 'fa-solid fa-oil-can',
               txt = partInfoString,
               disabled = true,
          },
          {
               header = 'Open Stash',
               icon = 'fa-solid fa-cart-flatbed',
               params = {
                    event = 'keep-oilwell:client:openOilPump',
                    args = {
                         oilrig_hash = data.oilrig_hash
                    }
               }
          },
          {
               header = 'Fix Oilwell',
               icon = 'fa-solid fa-screwdriver-wrench',

               params = {
                    event = 'keep-oilwell:client:fix_oilwell',
                    args = {
                         oilrig_hash = data.oilrig_hash
                    }
               }
          },
          {
               header = 'leave',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end

-- Events
AddEventHandler('keep-oilrig:storage_menu:PumpOilToStorage', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:PumpOilToStorageCallback', function(result)

     end, data.oilrig_hash)
end)

AddEventHandler('keep-oilrig:client:viewPumpInfo', function(qbtarget)
     -- ask for updated data
     OilRigs:startUpdate(function()
          showInfo(OilRigs:getByEntityHandle(qbtarget.entity))
     end)
end)


AddEventHandler('keep-oilrig:client:show_oilwell_stash', function(qbtarget)
     -- ask for updated data
     OilRigs:startUpdate(function()
          show_oilwell_stash(OilRigs:getByEntityHandle(qbtarget.entity))
     end)
end)

-- Open oil pump stash.
RegisterNetEvent("keep-oilwell:client:openOilPump", function(data)
     if not data then return end
     TriggerServerEvent("inventory:server:OpenInventory", "stash", "oilPump_" .. data.oilrig_hash,
          { maxweight = 100000, slots = 5 })
     TriggerEvent("inventory:client:SetCurrentStash", "oilPump_" .. data.oilrig_hash)
end)

AddEventHandler('keep-oilwell:client:fix_oilwell', function(data)
     -- ask for updated data
     QBCore.Functions.TriggerCallback('keep-oilwell:server:fix_oil_well', function(result)
          print(result)
     end, data.oilrig_hash)

end)
