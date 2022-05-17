local QBCore = exports['qb-core']:GetCoreObject()

OBJECT = nil

-- class
OilRigs = {
     data_table = {}
}

function OilRigs:add(s_res, id)
     if self.data_table[id] ~= nil then
          return
     end
     -- s_res.entity = NetworkGetEntityFromNetworkId(id)
     self.data_table[id] = {}
     self.data_table[id] = s_res
     if self.data_table[id].isOwner == true then
          createCustom(self.data_table[id].position.coord, {
               sprite = 436,
               colour = 5,
               range = 'short',
               name = 'Oilwell'
          })
     end
     self.data_table[id].entity = spawnObjects(self.data_table[id].position)

     self:syncSpeed(self.data_table[id].entity, self.data_table[id].metadata.speed)
end

function OilRigs:update(s_res, id)
     if self.data_table[id] == nil then
          return
     end
     s_res.entity = self.data_table[id].entity
     s_res.Qbtarget = self.data_table[id].Qbtarget
     self.data_table[id] = s_res
     self:syncSpeed(self.data_table[id].entity, self.data_table[id].metadata.speed)
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

function OilRigs:syncSpeed(entity, speed)
     local anim_speed = Round((speed / Config.AnimationSpeedDivider), 2)
     SetEntityAnimSpeed(entity, 'p_v_lev_des_skin', 'p_oil_pjack_03_s', anim_speed + .0)
end

function OilRigs:getById(id)
     for key, value in pairs(self.data_table) do
          if value.id == id then
               return value
          end
     end
     return false
end

function OilRigs:getByEntityHandle(handle)
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

RegisterNetEvent('keep-oilrig:client:changeRigSpeed', function(qbtarget)
     OilRigs:startUpdate(function()
          local rig = OilRigs:getByEntityHandle(qbtarget.entity)
          local inputData = exports['qb-input']:ShowInput({
               header = "Change oil rig speed",
               submitText = "change",
               inputs = { {
                    type = 'text',
                    isRequired = true,
                    name = 'speed',
                    text = 'current speed: ' .. rig.metadata.speed
               },
               }
          })
          if inputData then
               if not inputData.speed or tonumber(inputData.speed) < 0 and tonumber(inputData.speed) > 100 then
                    return
               end
               TriggerServerEvent('keep-oilrig:server:updateSpeed', inputData, rig.id)
          end
     end)
end)

local function loadData()
     OilRigs.data_table = {}
     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          OnDuty = PlayerData.job.onduty
          if PlayerJob.name == 'oilwell' and OnDuty then
               createEntityQbTarget()
          end
          QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
               for key, value in pairs(result) do
                    OilRigs:add(value, key)
               end
               if PlayerJob.name == 'oilwell' and OnDuty then
                    DistanceTracker()
               end
          end)
     end)
end

AddEventHandler('onResourceStart', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
          return
     end
     Wait(500)
     loadData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     Wait(1500)
     loadData()
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
                    if value.entity ~= nil then
                         local coord = value.position.coord
                         local pedCoord = GetEntityCoords(plyped)
                         local distance = GetDistanceBetweenCoords(coord.x, coord.y, coord.z, pedCoord.x, pedCoord.y, pedCoord.z, true)
                         if distance < 5.0 then
                              -- add qbtarget
                              if value.Qbtarget == nil and value.entity ~= 0 then
                                   value.Qbtarget = "oil-rig-" .. value.entity
                                   giveControlToOwner(value.entity)
                              end
                         elseif distance > 5.0 then
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

RegisterNetEvent('keep-oilrig:client:syncSpeed', function(id, speed)
     -- slowly increase and decrease speed of oilwell/pump
     local actionSpeed = Config.actionSpeed
     local rig = OilRigs:getById(id)
     local currentspeed = rig.metadata.speed
     if currentspeed > speed then
          while currentspeed >= speed and currentspeed > 0 do
               currentspeed = currentspeed - actionSpeed
               OilRigs:syncSpeed(rig.entity, currentspeed)
               Wait(1000)
          end
     elseif currentspeed < speed then
          while currentspeed <= speed and currentspeed >= 0 do
               currentspeed = currentspeed + actionSpeed
               OilRigs:syncSpeed(rig.entity, currentspeed)
               Wait(1000)
          end
     end
end)
local rigmodel = GetHashKey('p_oil_pjack_03_s')

function spawnObjects(position)
     TriggerEvent('keep-oilrig:client:clearArea', position.coord)
     -- every oilwell exist only on client side!
     local entity = CreateObject(rigmodel, position.coord.x, position.coord.y, position.coord.z, 0, 0, 0)
     while not DoesEntityExist(entity) do
          Wait(10)
     end
     -- set rotation
     SetEntityRotation(entity, position.rotation.x, position.rotation.y, position.rotation.z, 0.0, true)
     SetEntityAsMissionEntity(entity, 0, 0) -- #TODO replace it with dynamic spawn based on player position!
     return entity
end

-- --------------------------------------------------------------

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
          local netId = NetworkGetNetworkIdFromEntity(qbtarget.entity)
          TriggerServerEvent('keep-oilrig:server:regiserOilrig', inputData, netId)
          Wait(1500)
          loadData()
     end
end)
