local QBCore = exports['qb-core']:GetCoreObject()

OBJECT = nil
local rigmodel = GetHashKey('p_oil_pjack_03_s')

-- class
OilRigs = {
     data_table = {}, -- this table holds oilwells data and defined by server
     core_entities = {} -- this table holds objects that has some functions to them and filled by dynamic spawner
}

function OilRigs:add(s_res, id)
     if self.data_table[id] ~= nil then
          return
     end
     self.data_table[id] = {}
     self.data_table[id] = s_res
     if self.data_table[id].isOwner == true then
          local blip_settings = Config.Settings.oil_well.blip
          blip_settings.type = 'oil_well'
          blip_settings.id = id

          createCustom(self.data_table[id].position.coord, blip_settings)
     end
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

function OilRigs:DynamicSpawner(PlayerJob)
     local plyped = PlayerPedId()
     local object_spawn_distance = 125.0
     local qbtarget_attachment_distance = 10.0
     CreateThread(function()
          -- create core blips
          for index, value in pairs(Config.locations) do
               value.blip.type = index
               createCustom(value.position, value.blip)
          end

          while true do
               local pedCoord = GetEntityCoords(plyped)
               -- oilwells/pumps
               for index, value in pairs(self.data_table) do
                    local coord = value.position.coord
                    local distance = GetDistanceBetweenCoords(coord.x, coord.y, coord.z, pedCoord.x, pedCoord.y, pedCoord.z, true)
                    if distance < object_spawn_distance and self.data_table[index].entity == nil then
                         self.data_table[index].entity = spawnObjects(rigmodel, self.data_table[index].position)
                         self:syncSpeed(self.data_table[index].entity, self.data_table[index].metadata.speed)
                    elseif distance > object_spawn_distance and self.data_table[index].entity ~= nil then
                         DeleteEntity(self.data_table[index].entity)
                         self.data_table[index].entity = nil
                    end

                    -- attach qbtarget only for players that has this job
                    if distance < qbtarget_attachment_distance and self.data_table[index].entity ~= nil and PlayerJob.name == 'oilwell' then
                         -- add qbtarget
                         if DoesEntityExist(self.data_table[index].entity) == 1 and value.Qbtarget == nil and value.entity ~= 0 then
                              value.Qbtarget = "oil-rig-" .. value.entity
                              createOwnerQbTarget(value.entity)
                         end
                    elseif distance > qbtarget_attachment_distance and self.data_table[index].entity ~= nil and PlayerJob.name == 'oilwell' then
                         -- remove qbtarget if player is far away
                         if DoesEntityExist(self.data_table[index].entity) == 1 and value.Qbtarget ~= nil and value.entity ~= 0 then
                              exports['qb-target']:RemoveZone(value.Qbtarget)
                              value.Qbtarget = nil
                         end
                    end
               end

               for index, value in pairs(Config.locations) do
                    local distance = GetDistanceBetweenCoords(value.position.x, value.position.y, value.position.z, pedCoord.x, pedCoord.y, pedCoord.z, true)
                    if self.core_entities[index] == nil then
                         self.core_entities[index] = {}
                    end

                    if distance < object_spawn_distance and self.core_entities[index].entity == nil then
                         local position = {
                              coord = {
                                   x = value.position.x,
                                   y = value.position.y,
                                   z = value.position.z,
                              },
                              rotation = {
                                   x = value.rotation.x,
                                   y = value.rotation.y,
                                   z = value.rotation.z,
                              }
                         }
                         local entity = spawnObjects(value.model, position)
                         self.core_entities[index].entity = entity
                         value.Qbtarget = addQbTargetToCoreEntities(entity, index, PlayerJob)
                    elseif distance > object_spawn_distance and self.core_entities[index].entity ~= nil then
                         exports['qb-target']:RemoveZone(index .. self.core_entities[index].entity)
                         DeleteEntity(self.core_entities[index].entity)
                         value.Qbtarget = nil
                         self.core_entities[index].entity = nil
                    end
               end
               Wait(1000)
          end
     end)
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
          QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
               for key, value in pairs(result) do
                    OilRigs:add(value, key)
               end
               OilRigs:DynamicSpawner(PlayerJob)
          end)
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

function spawnObjects(model, position)
     TriggerEvent('keep-oilrig:client:clearArea', position.coord)
     -- every oilwell exist only on client side!
     local entity = CreateObject(model, position.coord.x, position.coord.y, position.coord.z, 0, 0, 0)
     while not DoesEntityExist(entity) do
          Wait(10)
     end
     SetEntityRotation(entity, position.rotation.x, position.rotation.y, position.rotation.z, 0.0, true)
     FreezeEntityPosition(
          entity,
          true
     )
     SetEntityProofs(
          entity,
          1,
          1,
          1,
          1,
          1,
          1,
          1,
          1
     )
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
                    debugPoly = false,
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

          inputData.netId = netId
          QBCore.Functions.TriggerCallback('keep-oilrig:server:regiserOilrig', function(result)
               DeleteEntity(qbtarget.entity)
               if result == true then
                    Wait(1500)
                    QBCore.Functions.Notify('Registering oilwell to: ' .. inputData.cid, "success")
                    loadData()
               end
          end, inputData)
     end
end)

RegisterNetEvent('keep-oilwell:client:force_reload', function()
     loadData()
end)

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
