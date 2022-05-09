local QBCore = exports['qb-core']:GetCoreObject()

Oilrigs = {} -- cache rigs after loading them from databse/and save their netID
Gotrigs = false
local rigmodel = GetHashKey('p_oil_pjack_03_s')
local serverUpdateInterval = 30000

--class
-- class
local OilRigs = {
     data_table = {}
}

function OilRigs:add(oilrig)
     if self.data_table[oilrig.netId] ~= nil then
          return
     end
     oilrig.entity = NetworkGetEntityFromNetworkId(oilrig.netId)
     oilrig.metadata = json.decode(oilrig.metadata)
     self.data_table[oilrig.netId] = {}
     self.data_table[oilrig.netId] = oilrig
end

function OilRigs:update(oilrig_hash, newData)
     for key, value in pairs(self.data_table) do
          if value.oilrig_hash == oilrig_hash then
               value = newData
               print(equals(value, newData))
               return true
          end
     end
     return false
end

function OilRigs:keep_updated()
     CreateThread(function()
          while true do
               Wait(serverUpdateInterval - 100)
               Gotrigs = false
               GetAllOilrigsFromDatabase()
               while Gotrigs == false do
                    Wait(500)
               end
               for key, value in pairs(Oilrigs) do
                    OilRigs:update(Oilrigs[key].oilrig_hash, value)
               end
          end
     end)
end

function OilRigs:getByHash(oilrig_hash)
     for key, value in pairs(self.data_table) do
          if value.oilrig_hash == oilrig_hash then
               return value
          end
     end
     return false
end

function OilRigs:read(netId)
     return self.data_table[netId]
end

function OilRigs:readAll()
     return self.data_table
end

-- ===========================================
--          Spawn / object Control
-- ===========================================

-- create networked oilrigs
RegisterNetEvent('keep-oilrig:server:spawnOilrigsOnResourceStart', function()
     GetAllOilrigsFromDatabase()
     -- should add timeout!
     while Gotrigs == false do
          Wait(500)
     end
     for key, value in pairs(Oilrigs) do
          value.position = json.decode(value.position)
          local coord = value.position.coord
          local rotation = value.position.rotation
          local entity = CreateObject(rigmodel, coord.x, coord.y, coord.z, 1, 1, 0)
          while not DoesEntityExist(entity) do
               Wait(10)
          end
          SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 0.0, true)

          local PedNetId = NetworkGetNetworkIdFromEntity(entity)
          Oilrigs[key].netId = PedNetId
          OilRigs:add(Oilrigs[key])
     end
     Wait(75)
     globalOilrigsDataTracker()
     OilRigs:keep_updated()
end)

RegisterNetEvent('keep-oilrig:server:syncOilrigSpeed', function(netId, speed)
     TriggerClientEvent('keep-oilrig:client:syncOilrigSpeed', -1, netId, speed)
end)

-- ==========================================
--          Update / server Side
-- ==========================================

function globalOilrigsDataTracker()
     CreateThread(function()
          while true do
               for key, oilrig in pairs(OilRigs:readAll()) do
                    -- update oilrig data

               end
               Wait(serverUpdateInterval)
          end
     end)
end

RegisterNetEvent('keep-oilrig:server:updateSpeed', function(inputData, NetId)
     local player = QBCore.Functions.GetPlayer(source)
     if player ~= nil then
          -- validate speed for 0 - 100
          local speed = tonumber(inputData.speed)
          local PlayerData = player.PlayerData
          local oilrig = OilRigs:read(NetId)
          local anim_speed = math.floor(speed / 10)
          oilrig.metadata.speed = speed
          UpdateOilrigMetadata({
               citizenid = PlayerData.citizenid,
               oilrig_hash = oilrig.oilrig_hash,
               metadata = oilrig.metadata
          })
          TriggerClientEvent('keep-oilrig:client:syncOilrigSpeed', -1, NetId, anim_speed)
     else
          TriggerClientEvent('QBCore:Notify', source, "failed")
     end
end)

-- =======================================
--          Send Data / to Client
-- =======================================

---send oilrigs data to loaded player
---@param source integer
---@param cb table
QBCore.Functions.CreateCallback('keep-oilrig:server:getNetIDs', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local temp = {}
     for key, value in pairs(Oilrigs) do
          if value.citizenid == citizenid then
               value.isOwner = true
          end
          -- remove elemnts
          temp[key] = value
          temp[key].position = nil
          temp[key].citizenid = nil
          temp[key].id = nil
     end
     cb(temp)
end)

-- ======================================
--          Register / from Client
-- ======================================

--- create oilrig and initialize it's data into database
---@param source integer
---@param cb 'calback'
---@param coords 'vector3'
---@return 'NetId'
QBCore.Functions.CreateCallback('keep-oilrig:server:createNewOilrig', function(source, cb, coords)
     local oilrig = CreateObject(rigmodel, coords.x, coords.y, coords.z, 1, 1, 0)
     while not DoesEntityExist(oilrig) do
          Wait(50)
     end
     local NetId = NetworkGetNetworkIdFromEntity(oilrig)
     cb(NetId)
end)

---register oilrig to player by their current cid
---@param inputData any
---@param NetId any
RegisterNetEvent('keep-oilrig:server:regiserOilrig', function(inputData, NetId)
     local cid = tonumber(inputData.cid)
     local player = QBCore.Functions.GetPlayer(cid)
     if player ~= nil then
          local PlayerData = player.PlayerData
          local entity = NetworkGetEntityFromNetworkId(NetId)
          local coord = GetEntityCoords(entity)
          local rotation = GetEntityRotation(entity)
          local position = {
               coord = {
                    x = coord.x,
                    y = coord.y,
                    z = coord.z,
               },
               rotation = {
                    x = rotation.x,
                    y = rotation.y,
                    z = rotation.z,
               }
          }
          local metadata = {
               speed = 0,
               temp = 0,
               duration = 0,
               oil_storage = 0,
               part_info = {
                    belt = 0,
                    polish = 0,
                    clutch = 0,
               }
          }
          InsertInfromation({
               citizenid = PlayerData.citizenid,
               name = inputData.name,
               oilrig_hash = RandomHash(15),
               position = position,
               metadata = metadata
          })
     else
          TriggerClientEvent('QBCore:Notify', source, "failed")
     end
end)

-- ===========================
--          Commands
-- ===========================

QBCore.Commands.Add('spawn', 'spawn pet', {}, false, function(source, args)
     TriggerClientEvent('keep-oilrig:client:spawn', source, args[1])
end, 'admin')
