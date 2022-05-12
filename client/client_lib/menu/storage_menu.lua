local QBCore = exports['qb-core']:GetCoreObject()

function showStorage(storage_data)
     local header = storage_data.name
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-pump'
          }, {
               header = 'Crude oil',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. storage_data.metadata.crudeOil .. " /gal",
               params = {
                    event = 'keep-oilrig:client_lib:StorageActions',
                    args = {
                         type = 'crudeOil',
                         storage_data = storage_data
                    }
               }
          },
          {
               header = 'Gasoline',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. storage_data.metadata.gasoline .. " /gal",
               params = {
                    event = 'keep-oilrig:client_lib:StorageActions',
                    args = {
                         type = 'gasoline',
                         storage_data = storage_data
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

function showStorageActions(data)
     local header = "Actions " .. data.type
     local storage_data = data.storage_data
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
                    args = data
               }
          },
          {
               header = 'Storage action',
               icon = 'fa-solid fa-arrow-right-arrow-left',
               params = {
                    event = '',
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
     local header = "Storage withdraw (" .. data.type .. ")"
     local currentWithdrawTarget = data.storage_data.metadata[data.type] -- oil or gas
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-boxes-packing'
          },
          {
               header = 'you have ' .. currentWithdrawTarget .. ' gal of ' .. data.type,
               isMenuHeader = true,
               icon = 'fa-solid fa-boxes-packing'
          }, {
               header = 'Store in Barrel',
               icon = 'fa-solid fa-bottle-droplet',
               txt = "deposit: $500   Capacity: 5000 /gal",
               params = {
                    event = 'keep-oilrig:client_lib:Callback',
                    args = {
                         eventName = 'keep-oilrig:server:WithdrawWithBarrel',
                         content = data
                    }
               }
          },
          {
               header = 'Load in Truck',
               icon = 'fa-solid fa-truck-droplet',
               txt = "deposit: $25,000k   Capacity: 100,000 /gal",
               params = {
                    event = 'keep-oilrig:client_lib:Callback',
                    args = {
                         eventName = 'keep-oilrig:server:WithdrawLoadInTruck',
                         content = data
                    }
               }
          },
          {
               header = 'Back',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-oilrig:client_lib:StorageActions",
                    args = data
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
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getStorageData', function(result)
          showStorage(result)
     end)
end)


AddEventHandler('keep-oilrig:client_lib:StorageActions', function(storage_data)
     showStorageActions(storage_data)
end)


AddEventHandler('keep-oilrig:client_lib:StorageWithdraw', function(data)
     showStorageWithdraw(data)
end)


AddEventHandler('keep-oilrig:client_lib:Callback', function(data)
     QBCore.Functions.TriggerCallback(data.eventName, function(result)
          print(result)
     end, data.content)
end)
