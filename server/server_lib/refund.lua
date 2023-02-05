local QBCore = exports['qb-core']:GetCoreObject()
local vehicles = {}

RegisterNetEvent('keep-oilwell:server_lib:update_vehicle', function(vehiclePlate, items)
     local src = source
     if not vehicles[src] then
          vehicles[src] = {}
     end
     vehicles[src][vehiclePlate] = vehiclePlate
     exports['qb-inventory']:addTrunkItems(vehiclePlate, items)
end)

QBCore.Functions.CreateCallback('keep-oilwell:server:refund_truck', function(source, cb, vehiclePlate)
     if vehicles[source] then
          if vehicles[source][vehiclePlate] then
               local player = QBCore.Functions.GetPlayer(source)
               player.Functions.AddMoney('bank', Oilwell_config.Delivery.refund, 'oil_barells')
               vehicles[source][vehiclePlate] = nil
               cb(true)
               return
          end
     end
     cb(false)
end)
