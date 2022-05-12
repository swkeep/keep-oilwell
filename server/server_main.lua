local QBCore = exports['qb-core']:GetCoreObject()

Oilrigs = {
     oldTable = {},
     data_table = {},
}

local serverUpdateInterval = 10000 --  database update interval

--class
function Oilrigs:startInit()
     GetAllOilrigsFromDatabase('init')
end

function Oilrigs:initPhaseTwo(oilrigs)
     -- wont work without CreateThread
     Citizen.CreateThread(function()
          -- spawn objects
          for key, value in pairs(oilrigs) do
               self:add(value)
          end
          self:saveThread()
          metadataTracker(self.data_table)
     end)
end

function Oilrigs:add(oilrig)
     if self.data_table[oilrig] ~= nil then
          return
     end
     local id = oilrig.id
     self.data_table[id] = {}
     oilrig.metadata = json.decode(oilrig.metadata)
     oilrig.position = json.decode(oilrig.position)
     self.data_table[id] = oilrig
end

function Oilrigs:saveThread()
     CreateThread(function()
          while true do
               self.oldTable = deepcopy(self.data_table)
               Wait(serverUpdateInterval)
               ---save metadata when we detected they are changed!
               if isTableChanged(self.oldTable, self.data_table) == true then
                    for key, value in pairs(self.data_table) do
                         GeneralUpdate({
                              type = 'metadata',
                              citizenid = value.citizenid,
                              oilrig_hash = value.oilrig_hash,
                              metadata = value.metadata
                         })
                    end
               end
          end
     end)
end

function Oilrigs:getByHash(oilrig_hash)
     for key, value in pairs(self.data_table) do
          if value.oilrig_hash == oilrig_hash then
               return value, key
          end
     end
     return false
end

function Oilrigs:read(id)
     return self.data_table[id]
end

function Oilrigs:readAll()
     return self.data_table
end

-- ===========================================
--          Spawn / object Control
-- ===========================================
AddEventHandler('onResourceStart', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
          return
     end
     Oilrigs:startInit()
end)
-- ==========================================
--          Update / server Side
-- ==========================================

function metadataTracker(oilrigs)
     local pumpOverHeat = 327
     CreateThread(function()
          while true do
               for key, value in pairs(oilrigs) do
                    if value.metadata.speed ~= 0 then
                         value.metadata.duration = value.metadata.duration + 1
                         value.metadata.secduration = value.metadata.duration
                         if value.metadata.temp ~= nil and pumpOverHeat >= value.metadata.temp then
                              value.metadata.temp = tempGrowth(value.metadata.temp, value.metadata.speed, 'increase', pumpOverHeat)
                              value.metadata.temp = Round(value.metadata.temp, 2)
                         else
                              value.metadata.temp = pumpOverHeat
                         end
                         if value.metadata.temp > 50 and value.metadata.temp < (pumpOverHeat - 25) and value.metadata.oil_storage <= 300 then
                              value.metadata.oil_storage = value.metadata.oil_storage + (0.1 * (value.metadata.speed / 50))
                         end
                    else
                         -- reset duration
                         if value.metadata.duration ~= 0 then
                              value.metadata.duration = 0
                         end
                         -- start cooling procces
                         if value.metadata.secduration > 0 then
                              value.metadata.secduration = value.metadata.secduration - 1
                              value.metadata.temp = tempGrowth(value.metadata.temp, value.metadata.speed, 'decrease', pumpOverHeat)
                              value.metadata.temp = Round(value.metadata.temp, 2)
                         elseif value.metadata.secduration == 0 then
                              value.metadata.temp = 0
                         end
                    end
               end
               Wait(1000)
          end
     end)
end

QBCore.Functions.CreateCallback('keep-oilrig:client_lib:PumpOilToStorageCallback', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     if player == nil then
          TriggerClientEvent('QBCore:Notify', source, "failed to find player!")
          cb(false)
          return
     end
     local oilrig, id = Oilrigs:getByHash(data)
     if oilrig.citizenid ~= player.PlayerData.citizenid then
          TriggerClientEvent('QBCore:Notify', source, "You are not owner of Oilwell!")
          cb(false)
          return
     end
     if oilrig.metadata.oil_storage < 0 then
          TriggerClientEvent('QBCore:Notify', source, "Oil storage is empty!")
          cb(false)
          return
     end
     TriggerClientEvent('QBCore:Notify', source, oilrig.metadata.oil_storage .. " Gallon of Curde Oil pumped to storage")
     sendOilToStorage(oilrig, player)
     cb(true)
end)


function sendOilToStorage(oilrig, player)
     local citizenid = player.PlayerData.citizenid
     MySQL.Async.fetchSingle('SELECT * FROM oilrig_storage WHERE citizenid = ?', { citizenid }, function(res)
          if res == nil then
               initStorage({
                    citizenid = citizenid,
                    name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname .. "'s Storage",
                    metadata = {
                         crudeOil = 0,
                         gasoline = 0
                    }
               })
               return
          end
          local metadata = json.decode(res.metadata)
          metadata.crudeOil = metadata.crudeOil + oilrig.metadata.oil_storage
          oilrig.metadata.oil_storage = 0.0

          local sqlQuery = 'UPDATE oilrig_storage SET metadata = ? WHERE citizenid = ?'
          local QueryData = {
               json.encode({
                    crudeOil = Round(metadata.crudeOil, 2),
                    gasoline = 0
               }),
               citizenid,
          }
          MySQL.Async.execute(sqlQuery, QueryData, function(e)
          end)
     end)
end

function initStorage(o)
     local sqlQuery = 'INSERT INTO oilrig_storage (citizenid,name,metadata) VALUES (?,?,?)'
     local QueryData = {
          o.citizenid,
          o.name,
          json.encode(o.metadata),
     }
     MySQL.Async.insert(sqlQuery, QueryData)
end

QBCore.Functions.CreateCallback('keep-oilrig:server:getStorageData', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     MySQL.Async.fetchSingle('SELECT * FROM oilrig_storage WHERE citizenid = ?', { citizenid }, function(res)
          res.metadata = json.decode(res.metadata)
          cb(res)
     end)

end)

QBCore.Functions.CreateCallback('keep-oilrig:server:WithdrawWithBarrel', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     print_table(data)
     print('Withdraw barrel')
     cb(player)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:WithdrawLoadInTruck', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     print_table(data)
     print('Withdraw Truck')
     cb(player)
end)

function tempGrowth(tmp, speed, Type, max)
     if tmp == nil then
          return 0
     end
     if Type == 'increase' then
          if tmp >= 0 and tmp < (max / 4) then
               tmp = tmp + (1 * speed / 20)
          elseif tmp >= (max / 4) and tmp < max then
               tmp = tmp + (1 * speed / 75)
          else
               tmp = max
          end
     else
          if tmp > 0 then
               tmp = tmp - 10
          else
               tmp = 0
          end
     end
     return tmp
end

RegisterNetEvent('keep-oilrig:server:updateSpeed', function(inputData, id)
     local player = QBCore.Functions.GetPlayer(source)
     if player ~= nil then
          -- validate speed for 0 - 100
          local oilrig = Oilrigs:read(id)
          if player.PlayerData.citizenid == oilrig.citizenid then
               local speed = tonumber(inputData.speed)
               oilrig.metadata.speed = speed
               -- sync speed on other clients
               TriggerClientEvent('keep-oilrig:client:syncSpeed', -1, id, speed)
          else
               TriggerClientEvent('QBCore:Notify', source, "You are not owner of oil pump!")
          end
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
     for key, value in pairs(Oilrigs:readAll()) do
          temp[key] = deepcopy(value)
          if value.citizenid == citizenid then
               temp[key].isOwner = true
          else
               temp[key].isOwner = false
          end
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
     -- get player by entered cid
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
          GeneralInsert({
               citizenid = PlayerData.citizenid,
               name = inputData.name,
               oilrig_hash = RandomHash(15),
               position = position,
               metadata = metadata,
               state = 0
          })
     else
          TriggerClientEvent('QBCore:Notify', source, "Could not find player by it cid!")
     end
end)

-- ===========================
--          Commands
-- ===========================

QBCore.Commands.Add('spawn', 'spawn pet', {}, false, function(source, args)
     TriggerClientEvent('keep-oilrig:client:spawn', source, args[1])
end, 'admin')
