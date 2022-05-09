local QBCore = exports['qb-core']:GetCoreObject()

OBJECT = nil

-- class
local OilRigs = {
     data_table = {}
}

function OilRigs:add(s_res)
     if self.data_table[s_res.netId] ~= nil then
          return
     end
     s_res.entity = NetworkGetEntityFromNetworkId(s_res.netId)
     self.data_table[s_res.netId] = {}
     self.data_table[s_res.netId] = s_res
     local anim_speed = math.floor((s_res.metadata.speed / 10))
     OilRigs:syncSpeed(s_res.entity, anim_speed)
end

function OilRigs:syncSpeed(entity, anim_speed)
     SetEntityAnimSpeed(entity, 'p_v_lev_des_skin', 'p_oil_pjack_03_s', anim_speed + .0)
end

function OilRigs:getByNetId(netId)
     for key, value in pairs(self.data_table) do
          if value.netId == netId then
               return value
          end
     end
     return false
end

function OilRigs:getByEntity(handle)
     for key, value in pairs(self.data_table) do
          if value.entity == handle then
               return value
          end
     end
     return false
end

function OilRigs:readAll()
     return self.data_table
end

--

RegisterNetEvent('keep-oilrig:client:spawn')
AddEventHandler('keep-oilrig:client:spawn', function()
     local coords = ChooseSpawnLocation()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:createNewOilrig', function(NetId)
          if NetId ~= nil then
               local entity = NetworkGetEntityFromNetworkId(NetId)
               OBJECT = entity
               exports['qb-target']:AddEntityZone("oil-rig-" .. entity, entity, {
                    name = "oil-rig-" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = true,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "keep-oilrig:client:enterInformation",
                              icon = "fa-solid fa-scythe",
                              label = "Assign to player",
                              canInteract = function(entity)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          end
     end, coords)
end)

RegisterNetEvent('keep-oilrig:client:enterInformation', function(qbtarget)
     local inputData = exports['qb-input']:ShowInput({
          header = "Assign oil rig: ",
          submitText = "Assign",
          inputs = { {
               type = 'text',
               isRequired = true,
               name = 'name',
               text = "enter rig name"
          },
          {
               type = 'number',
               isRequired = true,
               name = 'cid',
               text = "current player cid"
          },
          }
     })
     if inputData then
          if not inputData.name and not inputData.cid then
               return
          end
          local NetId = NetworkGetNetworkIdFromEntity(qbtarget.entity)
          TriggerServerEvent('keep-oilrig:server:regiserOilrig', inputData, NetId)
     end
end)

RegisterNetEvent('keep-oilrig:client:changeRigSpeed', function(qbtarget)
     local inputData = exports['qb-input']:ShowInput({
          header = "Change oil rig speed: ",
          submitText = "change",
          inputs = { {
               type = 'text',
               isRequired = true,
               name = 'speed',
               text = "enter rig speed"
          },
          }
     })
     if inputData then
          if not inputData.speed and inputData.speed > 0 and inputData.speed < 100 then
               return
          end
          local NetId = NetworkGetNetworkIdFromEntity(qbtarget.entity)
          TriggerServerEvent('keep-oilrig:server:updateSpeed', inputData, NetId)
     end
end)

RegisterNetEvent('keep-oilrig:client:syncOilrigSpeed', function(netId, speed)
     local entity = NetworkGetEntityFromNetworkId(netId)
     -- local blip = AddBlipForEntity(
     --      entity
     -- )
     -- SetEntityAsMissionEntity(entity, 0, 0)
     -- -- blip only for owner
     -- SetBlipSprite(blip, 436)
     -- SetBlipColour(blip, 5)
     -- BeginTextCommandSetBlipName("STRING")
     -- AddTextComponentString('Oil Rig')
     -- EndTextCommandSetBlipName(blip)
     SetEntityAnimSpeed(entity, 'p_v_lev_des_skin', 'p_oil_pjack_03_s', speed + .0)
end)

-- this thing should called when player is loaded
AddEventHandler('keep-oilrig:client:placeonground', function(netId)
     local entity = NetworkGetEntityFromNetworkId(netId)

     exports['qb-target']:AddEntityZone("oil-rig-" .. entity, entity, {
          name = "oil-rig-" .. entity,
          heading = GetEntityHeading(entity),
          debugPoly = false,
     }, {
          options = {
               {
                    type = "client",
                    event = "keep-oilrig:client:viewPumpInfo",
                    icon = "fa-solid fa-scythe",
                    label = "View Pump Info",
                    s_res = OilRigs:getByEntity(entity),
                    canInteract = function(entity)
                         -- only owner should intactet with it!
                         return true
                    end,
               },
               {
                    type = "client",
                    event = "keep-oilrig:client:changeRigSpeed",
                    icon = "fa-solid fa-scythe",
                    label = "Modifiy Pump Settings",
                    canInteract = function(entity)
                         -- only owner should intactet with it!
                         return true
                    end,
               },
               {
                    type = "client",
                    event = "",
                    icon = "fa-solid fa-scythe",
                    label = "Manange Parts",
                    canInteract = function(entity)
                         -- only owner should intactet with it!
                         return true
                    end,
               },
          },
          distance = 2.5
     })
end)

AddEventHandler('onResourceStart', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
          return
     end
     TriggerServerEvent('keep-oilrig:server:spawnOilrigsOnResourceStart')

     Wait(1500)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
          for key, value in pairs(result) do
               OilRigs:add(value)
               Wait(7)
               if value.isOwner == true then
                    TriggerEvent('keep-oilrig:client:placeonground', value.netId)
               end
          end
     end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     -- ask server fro netIDs
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
          for key, value in pairs(result) do
               if value.isOwner == true then
                    TriggerEvent('keep-oilrig:client:placeonground', value.netId)
               end
               OilRigs:add(value)
          end

     end)
end)
