Targets = {}
local QBCore = exports['qb-core']:GetCoreObject()

local loaded = false
local PED = nil
local function setPedVariation(pedHnadle, variation)
     for componentId, v in pairs(variation) do
          if IsPedComponentVariationValid(pedHnadle, componentId, v.drawableId, v.textureId) then
               SetPedComponentVariation(pedHnadle, componentId, v.drawableId, v.textureId)
          end
     end
end

function GETPED()
     return PED
end

function SETPED(ped)
     PED = ped
end

local function spawn_ped(data)
     RequestModel(data.model)
     while not HasModelLoaded(data.model) do
          Wait(0)
     end

     if type(data.model) == 'string' then data.model = GetHashKey(data.model) end

     local ped = CreatePed(1, data.model, data.coords, data.networked or false, true)

     if data.variant then setPedVariation(ped, data.variant) end
     if data.freeze then FreezeEntityPosition(ped, true) end
     if data.invincible then SetEntityInvincible(ped, true) end
     if data.blockevents then SetBlockingOfNonTemporaryEvents(ped, true) end
     if data.animDict and data.anim then
          RequestAnimDict(data.animDict)
          while not HasAnimDictLoaded(data.animDict) do
               Wait(0)
          end

          if type(data.anim) == "table" then
               CreateThread(function()
                    while true do
                         local anim = data.anim[math.random(0, #data.anim)]
                         ClearPedTasks(ped)
                         TaskPlayAnim(ped, data.animDict, anim, 8.0, 0, -1, data.flag or 1, 0, 0, 0, 0)
                         SETPED(ped)
                         Wait(7000)
                    end
               end)
          else
               TaskPlayAnim(ped, data.animDict, data.anim, 8.0, 0, -1, data.flag or 1, 0, 0, 0, 0)
          end
     end

     if data.scenario then
          SetPedCanPlayAmbientAnims(ped, true)
          TaskStartScenarioInPlace(ped, data.scenario, 0, true)
     end

     if data.voice then
          SetAmbientVoiceName(ped, 'A_F_Y_BUSINESS_01_WHITE_FULL_01')
     end
     SETPED(ped)
end

local function makeCore()
     if loaded then return end
     Citizen.CreateThread(function()
          local c = Oilwell_config.TruckWithdraw.npc.coords
          local vec3_coord = vector3(c.x, c.y, c.z)
          PED = spawn_ped(Oilwell_config.TruckWithdraw.npc)

          exports['qb-target']:AddBoxZone("keep_oilwell_withdraw_truck_target", vec3_coord,
               Oilwell_config.TruckWithdraw.box.l,
               Oilwell_config.TruckWithdraw.box.w,
               {
                    name = "keep_oilwell_withdraw_truck_target",
                    heading = Oilwell_config.TruckWithdraw.box.heading,
                    debugPoly = false,
                    minZ = vec3_coord.z + Oilwell_config.TruckWithdraw.box.minz_offset,
                    maxZ = vec3_coord.z + Oilwell_config.TruckWithdraw.box.maxz_offset,
               }, {
               options = {
                    {
                         event = "keep-oilrig:client_lib:withdraw_from_queue",
                         icon = "fa-solid fa-truck-droplet",
                         label = 'Take out truck',
                         truck = true
                    },
               },
               distance = 2.0
          })
          loaded = true
     end)
end

AddEventHandler('keep-oilwell:client:refund_truck', function(data)
     local coord = GetEntityCoords(data.entity)
     local spawnLocation = vector3(Oilwell_config.Delivery.SpawnLocation.x, Oilwell_config.Delivery.SpawnLocation.y,
          Oilwell_config.Delivery.SpawnLocation.z)

     local plate = data.vehiclePlate

     if #(coord - spawnLocation) > 5.0 then
          QBCore.Functions.Notify('You are not close to truck refunding area', "primary")
          return
     end
     QBCore.Functions.TriggerCallback('keep-oilwell:server:refund_truck', function(result)
          if result == true then
               local netId = NetworkGetNetworkIdFromEntity(data.entity)
               local entity = NetworkGetEntityFromNetworkId(netId)
               NetworkRequestControlOfEntity(entity)
               DeleteEntity(entity)
          end
     end, plate)
end)


AddEventHandler('onResourceStart', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then return end
     Wait(1000)
     makeCore()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     Wait(1000)
     makeCore()
end)

AddEventHandler('onResourceStop', function(resourceName)
     if resourceName ~= GetCurrentResourceName() then
          return
     end
     DeleteEntity(GETPED())
end)
