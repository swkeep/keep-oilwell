local QBCore = exports['qb-core']:GetCoreObject()

PlayerJob = {}
OnDuty = nil
OBJECT = nil
local rigmodel = GetHashKey('p_oil_pjack_03_s')

function CheckJob()
     return (PlayerJob.name == 'oilwell')
end

function CheckOnduty()
     return (PlayerJob.name == 'oilwell' and PlayerJob.onduty)
end

-- class
OilRigs = {
     dynamicSpawner_state = false,
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
          local blip_settings = Oilwell_config.Settings.oil_well.blip
          blip_settings.type = 'oil_well'
          blip_settings.id = id
          self.data_table[id].blip_handle = createCustom(self.data_table[id].position.coord, blip_settings)
     end
end

function OilRigs:update(s_res, id)
     if self.data_table[id] == nil then return end
     s_res.entity = self.data_table[id].entity
     s_res.Qbtarget = self.data_table[id].Qbtarget
     self.data_table[id] = s_res
     QBCore.Functions.TriggerCallback('keep-oilwell:server:oilwell_metadata', function(metadata)
          self:syncSpeed(self.data_table[id].entity, metadata.speed)
     end, self.data_table[id].oilrig_hash)
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
     local anim_speed = Round((speed / Oilwell_config.AnimationSpeedDivider), 2)
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

function OilRigs:DynamicSpawner()
     self.dynamicSpawner_state = true
     local object_spawn_distance = 125.0

     CreateThread(function()
          -- create core blips
          Wait(50)
          for index, value in pairs(Oilwell_config.locations) do
               value.blip.type = index
               if not value.blip.handle and PlayerJob.name == 'oilwell' then
                    value.blip.handle = createCustom(value.position, value.blip)
               end
               if not value.qbtarget then
                    Add_3rd_eye(value.position, index)
                    value.qbtarget = true
               end
          end

          for _, oilwell in pairs(self.data_table) do
               if not oilwell.qbtarget then
                    local c = oilwell.position.coord
                    local coord = vector3(c.x, c.y, c.z)
                    createOwnerQbTarget(oilwell.oilrig_hash, coord)
                    oilwell.qbtarget = true
               end
          end

          while self.dynamicSpawner_state do
               local pedCoord = GetEntityCoords(PlayerPedId())
               -- oilwells/pumps
               for index, value in pairs(self.data_table) do
                    local c = value.position.coord
                    c = vector3(c.x, c.y, c.z)
                    local distance = #(c - pedCoord)
                    if distance < object_spawn_distance and self.data_table[index].entity == nil then
                         self.data_table[index].entity = spawnObjects(rigmodel, self.data_table[index].position)
                         QBCore.Functions.TriggerCallback('keep-oilwell:server:oilwell_metadata', function(metadata)
                              self:syncSpeed(self.data_table[index].entity, metadata.speed)
                         end, self.data_table[index].oilrig_hash)
                    elseif distance > object_spawn_distance and self.data_table[index].entity ~= nil then
                         DeleteEntity(self.data_table[index].entity)
                         self.data_table[index].entity = nil
                    end
               end

               for index, value in pairs(Oilwell_config.locations) do
                    local position = vector3(value.position.x, value.position.y, value.position.z)
                    local distance = #(position - pedCoord)
                    if self.core_entities[index] == nil then
                         self.core_entities[index] = {}
                    end
                    if distance < object_spawn_distance and self.core_entities[index].entity == nil then
                         self.core_entities[index].entity = spawnObjects(value.model, {
                              coord = { x = position.x, y = position.y, z = position.z, },
                              rotation = { x = value.rotation.x, y = value.rotation.y, z = value.rotation.z, }
                         })
                    elseif distance > object_spawn_distance and self.core_entities[index].entity ~= nil then
                         DeleteEntity(self.core_entities[index].entity)
                         self.core_entities[index].entity = nil
                    end
               end
               Wait(1250)
          end
     end)
end

function OilRigs:Flush_Entities()
     for _, oilwell in pairs(self.data_table) do
          if oilwell.entity then
               DeleteObject(oilwell.entity)
          end
          RemoveBlip(oilwell.blip_handle)
     end
     self.dynamicSpawner_state = false
     Wait(5)
     self.data_table = {}
end

--
RegisterNetEvent('keep-oilrig:client:changeRigSpeed', function(qbtarget)
     if not CheckJob() then
          QBCore.Functions.Notify('You not a hired by oil company', "error")
          return false
     end
     if not CheckOnduty() then
          QBCore.Functions.Notify('You must be on duty!', "error")
          return false
     end
     local rig = OilRigs:getByEntityHandle(qbtarget.entity)
     if not rig then
          return print('oilwell not found')
     end
     QBCore.Functions.TriggerCallback('keep-oilwell:server:oilwell_metadata', function(metadata)
          OilRigs:startUpdate(function()

               local inputData = exports['qb-input']:ShowInput({
                    header = "Change oil rig speed",
                    submitText = "change",
                    inputs = {
                         {
                              type = 'text',
                              isRequired = true,
                              name = 'speed',
                              text = 'current speed ' .. metadata.speed
                         },
                    }
               })
               if inputData then
                    local speed = tonumber(inputData.speed)
                    if not inputData.speed then
                         return
                    end
                    if not (0 <= speed and speed <= 100) then
                         QBCore.Functions.Notify('speed must be between 0 to 100', "error")
                         return
                    end
                    QBCore.Functions.Notify('oilwell speed changed to ' .. speed, "success")
                    TriggerServerEvent('keep-oilrig:server:updateSpeed', inputData, rig.id)
               end
          end)
     end, rig.oilrig_hash)
end)

local function loadData()
     OilRigs:Flush_Entities()
     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          OnDuty = PlayerData.job.onduty
          QBCore.Functions.TriggerCallback('keep-oilrig:server:getNetIDs', function(result)
               for key, value in pairs(result) do
                    OilRigs:add(value, key)
               end

               OilRigs:DynamicSpawner()
          end)
     end)
end

RegisterNetEvent('keep-oilrig:client:syncSpeed', function(id, speed)
     local rig = OilRigs:getById(id)
     if rig then
          OilRigs:syncSpeed(rig.entity, speed)
     end
end)

function spawnObjects(model, position)
     TriggerEvent('keep-oilrig:client:clearArea', position.coord)
     -- every oilwell exist only on client side!
     local entity = CreateObject(model, position.coord.x, position.coord.y, position.coord.z, 0, 0, 0)
     while not DoesEntityExist(entity) do Wait(10) end
     SetEntityRotation(entity, position.rotation.x, position.rotation.y, position.rotation.z, 0.0, true)
     FreezeEntityPosition(entity, true)
     SetEntityProofs(entity, 1, 1, 1, 1, 1, 1, 1, 1)
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
                                   if not CheckJob() then return false end
                                   if not (PlayerJob.grade.level == 4) then
                                        TriggerEvent('QBCore:Notify', 'You must be on duty!', "error")
                                        Wait(2000)
                                        return false
                                   end
                                   if not CheckOnduty() then
                                        TriggerEvent('QBCore:Notify', 'You must be on duty!', "error")
                                        Wait(2000)
                                        return false
                                   end
                                   return true
                              end,
                         },
                         {
                              type = "client",
                              event = "keep-oilwell:menu:OPENMENU",
                              icon = "fa-regular fa-file-lines",
                              label = "Adjust position",
                              canInteract = function(entity)
                                   if not CheckJob() then
                                        TriggerEvent('QBCore:Notify', 'Only CEO have access to this', "error")
                                        Wait(2000)
                                        return false
                                   end
                                   if not (PlayerJob.grade.level == 4) then
                                        TriggerEvent('QBCore:Notify', 'Only CEO have access to this', "error")
                                        Wait(2000)
                                        return false
                                   end
                                   if not CheckOnduty() then
                                        TriggerEvent('QBCore:Notify', 'You must be on duty!', "error")
                                        Wait(2000)
                                        return false
                                   end
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
     Wait(25)
     loadData()
end)

AddEventHandler('onResourceStart', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
          return
     end
     Wait(500)

     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          OnDuty = PlayerData.job.onduty
          loadData()
     end)
     StartBarellAnimation()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
     Wait(3000)
     QBCore.Functions.GetPlayerData(function(PlayerData)
          PlayerJob = PlayerData.job
          OnDuty = PlayerData.job.onduty
          loadData()
     end)
     StartBarellAnimation()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
     OilRigs.dynamicSpawner_state = false
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
     PlayerJob = JobInfo
     OnDuty = PlayerJob.onduty
     loadData()
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
     OnDuty = duty
     loadData()
end)

RegisterNetEvent('keep-oilrig:client:local_mail_sender', function(data)
     local Lang = Oilwell_config.Locale
     Lang.mail.message = string.format(Lang.mail.message, data.gender, data.charinfo.lastname, data.money, data.amount,
          data.refund)
     TriggerServerEvent('qb-phone:server:sendNewMail', {
          sender = Lang.mail.sender,
          subject = Lang.mail.subject,
          message = Lang.mail.message,
          button = {}
     })
end)

RegisterNetEvent('keep-oilwell:server_lib:AddExplosion', function(bullding_type)
     local c = Oilwell_config.locations[bullding_type].position
     local t = 0
     for i = 1, 5, 1 do
          AddExplosion(c.x, c.y, c.z + 0.5, 9, 10.0, true, false, true)
          t = t + 1000
          Wait(t)
     end
end)
