local QBCore = exports['qb-core']:GetCoreObject()

local function showStorage(storage_data)
     local header = storage_data.name
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-warehouse'
          }, {
               header = 'Crude oil',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. storage_data.metadata.crudeOil .. " /gal",
               params = {
                    event = 'keep-oilrig:storage_menu:StorageActions',
                    args = {
                         type = 'crudeOil',
                         storage_data = storage_data
                    }
               }
          },
          {
               header = 'Gasoline',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. storage_data.metadata.gasoline .. " /gal | Octane: " .. storage_data.metadata.avg_gas_octane,
               params = {
                    event = 'keep-oilrig:storage_menu:StorageActions',
                    args = {
                         type = 'gasoline',
                         storage_data = storage_data
                    }
               }
          },

     }

     if storage_data.metadata.fuel_oil then
          openMenu[#openMenu + 1] = {
               header = 'Fuel Oil',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. storage_data.metadata.fuel_oil .. " /gal",
               params = {
                    event = 'keep-oilrig:storage_menu:StorageActions',
                    args = {
                         type = 'fuel_oil',
                         storage_data = storage_data
                    }
               }
          }
     end


     openMenu[#openMenu + 1] = {
          header = 'leave',
          icon = 'fa-solid fa-circle-xmark',
          params = {
               event = "qb-menu:closeMenu"
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end

local function showStorageActions(data)
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
                    event = 'keep-oilrig:storage_menu:StorageWithdraw',
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
                    event = "keep-oilrig:storage_menu:ShowStorage"
               }
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end

local function showStorageWithdraw(data)
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
                    event = 'keep-oilrig:storage_menu:Callback',
                    args = {
                         eventName = 'keep-oilrig:server:Withdraw',
                         citizenid = data.storage_data.citizenid,
                         type = data.type,
                         truck = false
                    }
               }
          },
          {
               header = 'Load in Truck',
               icon = 'fa-solid fa-truck-droplet',
               txt = "deposit: $25,000k   Capacity: 100,000 /gal",
               params = {
                    event = 'keep-oilrig:storage_menu:Callback',
                    args = {
                         eventName = 'keep-oilrig:server:Withdraw',
                         citizenid = data.storage_data.citizenid,
                         type = data.type,
                         truck = true
                    }
               }
          },
          {
               header = 'Back',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-oilrig:storage_menu:StorageActions",
                    args = data
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

MakeVehicle = function(model, Coord, TriggerLocation, DinstanceToTrigger, items)
     local plyped = PlayerPedId()
     local pedCoord = GetEntityCoords(plyped)
     local finished = false
     local distance = GetDistanceBetweenCoords(pedCoord.x, pedCoord.y, pedCoord.z, TriggerLocation.x, TriggerLocation.y,
          TriggerLocation.z, true)
     CreateThread(function()
          while distance > DinstanceToTrigger do
               local pedCoord = GetEntityCoords(plyped)
               distance = GetDistanceBetweenCoords(pedCoord.x, pedCoord.y, pedCoord.z, TriggerLocation.x,
                    TriggerLocation.y, TriggerLocation.z, true)
               Wait(1000)
          end
          finished = true
     end)

     -- wait for player at delivery coord
     while finished == false do
          DrawMarker(2, TriggerLocation.x, TriggerLocation.y, TriggerLocation.z + 2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0
               , 1.0,
               1.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)
          Wait(0)
     end

     local vehiclePlate = "SWK" .. math.random(1, 9) .. math.random(1, 9) .. math.random(1, 9)
     model = GetHashKey(model)
     RequestModel(model)
     while not HasModelLoaded(model) do
          Wait(10)
     end

     local veh = CreateVehicle(model, Coord.x, Coord.y, Coord.z, Coord.w, true, false)
     local netid = NetworkGetNetworkIdFromEntity(veh)
     SetVehicleHasBeenOwnedByPlayer(veh, true)

     SetNetworkIdCanMigrate(netid, true)
     SetVehicleNeedsToBeHotwired(veh, false)
     SetVehRadioStation(veh, "OFF")

     SetVehicleNumberPlateText(veh, vehiclePlate)

     exports[Oilwell_config.fuel_script]:SetFuel(veh, math.random(80, 90))
     SetVehicleEngineOn(veh, true, true)

     SetNetworkIdAlwaysExistsForPlayer(NetworkGetNetworkIdFromEntity(veh), PlayerPedId(), true)
     TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
     TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate)
     SetModelAsNoLongerNeeded(model)
     Targets.qb_target.truck(vehiclePlate, veh)

     TriggerServerEvent('keep-oilwell:server_lib:update_vehicle', vehiclePlate, items)
end


RegisterNetEvent('keep-oilrig:client_lib:withdraw_from_queue', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:withdraw_from_queue', function(result)
          -- res >> table of items
          if result == false then
               return
          end
          if not result.truck then
               return
          end
          local SpawnLocation = Oilwell_config.Delivery.SpawnLocation
          local TriggerLocation = Oilwell_config.Delivery.TriggerLocation
          local DinstanceToTrigger = Oilwell_config.Delivery.DinstanceToTrigger
          local model = Oilwell_config.Delivery.vehicleModel

          MakeVehicle(model, SpawnLocation, TriggerLocation, DinstanceToTrigger, result)
     end, data.truck)
end)

-- Events

AddEventHandler('keep-oilrig:storage_menu:ShowStorage', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getStorageData', function(result)
          showStorage(result)
     end)
end)

AddEventHandler('keep-oilrig:storage_menu:StorageActions', function(storage_data)
     showStorageActions(storage_data)
end)

AddEventHandler('keep-oilrig:storage_menu:StorageWithdraw', function(data)
     showStorageWithdraw(data)
end)

AddEventHandler('keep-oilrig:storage_menu:Callback', function(data)
     local inputData = exports['qb-input']:ShowInput({
          header = "Enter withdraw value",
          submitText = "Confirm",
          inputs = {
               {
                    type = 'number',
                    isRequired = true,
                    name = 'amount',
                    text = "amount"
               },
          }
     })
     if inputData then
          if not inputData.amount then
               return
          end
          data.amount = inputData.amount
          QBCore.Functions.TriggerCallback(data.eventName, function(res)

          end, data)
     end
end)


-- withdraw spot
AddEventHandler("keep-oilwell:client:openWithdrawStash", function(data)
     local player = QBCore.Functions.GetPlayerData()
     if not data then return end
     local settings = { maxweight = 100000, slots = 5 }
     TriggerServerEvent("inventory:server:OpenInventory", "stash", "Withdraw_" .. player.citizenid, settings)
     TriggerEvent("inventory:client:SetCurrentStash", "Withdraw_" .. player.citizenid)
end)

-- purge menu
local function purge_menu()
     local openMenu = {
          {
               header = 'PURGE',
               txt = 'do you want to purge withdraw stash?',
               icon = 'fa-solid fa-trash-can',
               isMenuHeader = true,
          },
          {
               header = 'Confirm Purge!',
               icon = 'fa-solid fa-square-check',
               params = {
                    event = 'keep-oilwell:client:purgeWithdrawStash',
               }
          },
          {
               header = 'Cancel',
               icon = 'fa-solid fa-circle-xmark',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

AddEventHandler('keep-oilwell:client:open_purge_menu', function()
     purge_menu()
end)

local purge_conf = 0
AddEventHandler('keep-oilwell:client:purgeWithdrawStash', function()
     if purge_conf == 0 then
          QBCore.Functions.Notify('Try again to confirm Purge! (confirmation will reset in 5sec)', "primary")
          purge_conf = purge_conf + 1
          SetTimeout(5000, function()
               purge_conf = 0
          end)
          purge_menu()
          return
     end
     purge_conf = 0
     TriggerServerEvent('keep-oilwell:server:purgeWithdrawStash')
end)
