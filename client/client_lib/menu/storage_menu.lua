local QBCore = exports['qb-core']:GetCoreObject()

function showStorage(data)
     local header = "swkeep's oil storage"
     local gal = 5
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-pump'
          }, {
               header = 'Crude oil',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. gal .. " /gal",
               params = {
                    event = 'keep-oilrig:client_lib:StorageActions',
               }
          },
          {
               header = 'Gasoline',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. gal .. " /gal",
               params = {
                    event = 'keep-oilrig:client_lib:StorageActions',
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

function showStorageActions(data)
     local header = "Actions"
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-pump'
          }, {
               header = 'Withraw from storage',
               icon = 'fa-solid fa-truck-ramp-box',
               txt = "",
               params = {
                    event = 'keep-oilrig:client_lib:StorageWithdraw',
               }
          },
          {
               header = 'Storage action',
               icon = 'fa-solid fa-arrow-right-arrow-left',
               params = {
                    event = 'keep-oilrig:client_lib:StorageWithdraw',

               }
          },
          {
               header = 'Back',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-oilrig:client_lib:ShowStorage"
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

function showStorageWithdraw(data)
     local header = "Storage withdraw"
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-boxes-packing'
          }, {
               header = 'Store in Barrel',
               icon = 'fa-solid fa-bottle-droplet',
               txt = "deposit: $500   Capacity: 5000 /gal",
               params = {
                    event = 'keep-oilrig:client_lib:PumpOilToStorage',
               }
          },
          {
               header = 'Load in Truck',
               icon = 'fa-solid fa-truck-droplet',
               txt = "deposit: $25,000k   Capacity: 100,000 /gal",
               params = {
                    event = 'keep-oilrig:client_lib:PumpOilToStorage',
               }
          },
          {
               header = 'Back',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-oilrig:client_lib:StorageActions"
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

-- Events
AddEventHandler('keep-oilrig:client_lib:PumpOilToStorage', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:client_lib:PumpOilToStorageCallback', function(result)

     end, data.oilrig_hash)
end)

AddEventHandler('keep-oilrig:client_lib:ShowStorage', function(data)
     showStorage()
end)


AddEventHandler('keep-oilrig:client_lib:StorageActions', function(data)
     showStorageActions()
end)


AddEventHandler('keep-oilrig:client_lib:StorageWithdraw', function(data)
     showStorageWithdraw()
end)
