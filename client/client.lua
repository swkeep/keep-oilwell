local QBCore = exports['qb-core']:GetCoreObject()

OBJECT = nil

-- class
OilRigs = {
     data_table = {}
}

function OilRigs:add(s_res, netId)
     if self.data_table[netId] ~= nil then
          return
     end
     s_res.entity = NetworkGetEntityFromNetworkId(netId)
     self.data_table[netId] = {}
     self.data_table[netId] = s_res
     if s_res.isOwner == true then
          createCustom(s_res.position.coord, {
               sprite = 436,
               colour = 5,
               range = 'short',
               name = 'Oilwell'
          })
     end
     local anim_speed = Round((s_res.metadata.speed / Config.AnimationSpeedDivider), 2)
     OilRigs:syncSpeed(s_res.entity, anim_speed)
end

function OilRigs:update(s_res, netId)
     if self.data_table[netId] == nil then
          return
     end
     s_res.entity = NetworkGetEntityFromNetworkId(netId)
     s_res.Qbtarget = self.data_table[netId].Qbtarget
     self.data_table[netId] = s_res
     local anim_speed = Round((s_res.metadata.speed / Config.AnimationSpeedDivider), 2)
     self:syncSpeed(s_res.entity, anim_speed)
end

function OilRigs:startUpdate(cb)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
          for key, value in pairs(result) do
               self:update(value, key)
               Wait(15)
          end
          cb(true)
     end)
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
                              icon = "fa-regular fa-file-lines",
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
     OilRigs:startUpdate(function()
          local rig = OilRigs:getByEntity(qbtarget.entity)
          local inputData = exports['qb-input']:ShowInput({
               header = "Change oil rig speed (" .. rig.metadata.speed .. ")",
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
               if not inputData.speed or tonumber(inputData.speed) < 0 and tonumber(inputData.speed) > 100 then
                    return
               end
               local NetId = NetworkGetNetworkIdFromEntity(qbtarget.entity)
               TriggerServerEvent('keep-oilrig:server:updateSpeed', inputData, NetId)
          end
     end)
end)

AddEventHandler('onResourceStart', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
          return
     end
     Wait(500)
     createEntityQbTarget()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
          for key, value in pairs(result) do
               OilRigs:add(value, key)
          end
          DistanceTracker()
     end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     -- ask server fro netIDs
     Wait(1500)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
          for key, value in pairs(result) do
               if value.isOwner == true then
                    -- TriggerEvent('keep-oilrig:client:giveControlToOwner', value.netId)
               end
               OilRigs:add(value)
          end
          DistanceTracker()
     end)
end)

function giveControlToOwner(entity)
     createOwnerQbTarget(entity)
end

--- remove/add qbtarget by distance
function DistanceTracker()
     CreateThread(function()
          local rigs = OilRigs:readAll()
          local plyped = PlayerPedId()
          while true do
               for key, value in pairs(rigs) do
                    local entity = NetworkGetEntityFromNetworkId(key)
                    if entity ~= 0 then
                         local coord = value.position.coord
                         local pedCoord = GetEntityCoords(plyped)
                         local distance = GetDistanceBetweenCoords(coord.x, coord.y, coord.z, pedCoord.x, pedCoord.y, pedCoord.z, true)
                         if distance < 5.0 then
                              -- biotech_vacuum_pump
                              value.entity = entity
                              -- add qbtarget
                              if value.Qbtarget == nil and value.entity ~= 0 then
                                   value.Qbtarget = "oil-rig-" .. value.entity
                                   giveControlToOwner(value.entity)
                              end
                         elseif distance > 5.0 then
                              value.entity = entity
                              -- remove qbtarget if player is far away
                              if value.Qbtarget ~= nil and value.entity ~= 0 then
                                   exports['qb-target']:RemoveZone(value.Qbtarget)
                                   value.Qbtarget = nil
                              end
                         end
                    end
               end
               Wait(1000)
          end
     end)
end

---force remove objects in area
---@param coord table
RegisterNetEvent('keep-oilrig:client:clearArea', function(coord)
     ClearAreaOfObjects(
          coord.x,
          coord.y,
          coord.z,
          5.0,
          1
     )
end)

RegisterNetEvent('keep-oilrig:client:syncSpeed', function(netId, speed)
     -- slowly increase and decrease speed of oilwell/pump
     local actionSpeed = Config.actionSpeed
     local entity = NetworkGetEntityFromNetworkId(netId)
     local rig = OilRigs:getByEntity(entity)
     local currentspeed = rig.metadata.speed
     if currentspeed > speed then
          while currentspeed >= speed and currentspeed > 0 do
               currentspeed = currentspeed - actionSpeed
               local anim_speed = Round((currentspeed / Config.AnimationSpeedDivider), 2)
               SetEntityAnimSpeed(entity, 'p_v_lev_des_skin', 'p_oil_pjack_03_s', anim_speed + .0)
               Wait(1000)
          end
     elseif currentspeed < speed then
          while currentspeed <= speed and currentspeed >= 0 do
               currentspeed = currentspeed + actionSpeed
               local anim_speed = Round((currentspeed / Config.AnimationSpeedDivider), 2)
               SetEntityAnimSpeed(entity, 'p_v_lev_des_skin', 'p_oil_pjack_03_s', anim_speed + .0)
               Wait(1000)
          end
     end
end)
