local QBCore = exports['qb-core']:GetCoreObject()

--devices
-- ===========================================
--          Spawn / object Control
-- ===========================================
AddEventHandler('onResourceStart', function(resourceName)
     if (GetCurrentResourceName() ~= resourceName) then
          return
     end
     GlobalScirptData:wipeALL()
     GlobalScirptData:startInit()
end)
-- ==========================================
--          Update / server Side
-- ==========================================

QBCore.Functions.CreateCallback('keep-oilrig:server:PumpOilToStorageCallback', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     if player == nil then
          TriggerClientEvent('QBCore:Notify', source, "failed to find player!")
          cb(false)
          return
     end
     local oilrig, id = GlobalScirptData:getByHash(data)
     if oilrig.citizenid ~= player.PlayerData.citizenid then
          TriggerClientEvent('QBCore:Notify', source, "You are not owner of Oilwell!")
          cb(false)
          return
     end
     if oilrig.metadata.oil_storage <= 0 then
          TriggerClientEvent('QBCore:Notify', source, "Oil storage is empty!")
          cb(false)
          return
     end
     TriggerClientEvent('QBCore:Notify', source, oilrig.metadata.oil_storage .. " Gallon of Curde Oil pumped to storage")
     local res = SendOilToStorage(oilrig, player)
     cb(true)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:getStorageData', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage ~= false then
          cb(storage)
          return
     end
     cb(false)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:WithdrawWithBarrel', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage == false then
          cb(false)
          return
     end
     if data.type == 'crudeOil' then
          local value = storage.metadata.crudeOil
          storage.metadata.crudeOil = 0.0
          player.Functions.RemoveMoney('bank', Config.Settings.capacity.oilbarell.price, 'oil barell')
          player.Functions.AddItem('oilbarell', 1, 1, {
               gal = value,
               type = data.type
          })

     elseif data.type == 'gasoline' then
          print(storage.metadata.gasoline)
     end
     cb(true)
end)

QBCore.Functions.CreateUseableItem('oilbarell', function(source, item)
     local Player = QBCore.Functions.GetPlayer(source)
     print_table(item)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:WithdrawLoadInTruck', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     if player.PlayerData.citizenid == data.citizenid then
          local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
          local value = storage.metadata[data.type]
          if value == 0.0 then
               cb(false)
               return
          end
          -- storage.metadata[data.type] = 0.0
          local Barrel = {
               { description = 'Oil Barrel',
                    unique = true,
                    name = 'oilbarell',
                    image = 'oilBarrel.png',
                    weight = 1000,
                    slot = 1,
                    label = 'Oil barell',
                    info = {
                         gal = value,
                         type = data.type
                    },
                    amount = 1,
                    shouldClose = true,
                    useable = false,
                    type = 'item' }
          }
          cb(Barrel)
     end
end)

RegisterNetEvent('keep-oilrig:server:updateSpeed', function(inputData, id)
     local player = QBCore.Functions.GetPlayer(source)
     if player ~= nil then
          -- validate speed for 0 - 100
          local oilrig = GlobalScirptData:read(id)
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

QBCore.Functions.CreateCallback('keep-oilrig:server:get_CDU_Data', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     -- #TODO CDU
     local CDU = GlobalScirptData:getDeviceByCitizenId('oilrig_cdu', citizenid)
     if CDU == false then
          Init_CDU({
               citizenid = citizenid,
          })
     end

     -- callback must return CDU's object reason ==> reopen menu with new values
     cb(CDU)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:set_CDU_temp', function(source, cb, inputData)
     if type(inputData.temp) == "string" then
          inputData.temp = tonumber(inputData.temp)
     end
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local CDU = GlobalScirptData:getDeviceByCitizenId('oilrig_cdu', citizenid)
     CDU.metadata.req_temp = inputData.temp
     -- callback must return CDU's object reason ==> reopen menu with new values
     cb(CDU)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:switchPower_of_CDU', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local CDU = GlobalScirptData:getDeviceByCitizenId('oilrig_cdu', citizenid)
     if CDU.metadata.state == false then
          CDU.metadata.state = true
     else
          CDU.metadata.state = false
     end

     -- callback must return CDU's object reason ==> reopen menu with new values
     cb(CDU)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:pumpCrudeOil_to_CDU', function(source, cb, inputData)
     if type(inputData.amount) == "string" then
          inputData.amount = tonumber(inputData.amount)
     end
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local CDU = GlobalScirptData:getDeviceByCitizenId('oilrig_cdu', citizenid)
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)

     if storage.metadata.crudeOil >= inputData.amount then
          storage.metadata.crudeOil = storage.metadata.crudeOil - inputData.amount
          CDU.metadata.oil_storage = CDU.metadata.oil_storage + inputData.amount
     end
     -- callback must return CDU's object reason ==> reopen menu with new values
     cb(CDU)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:ShowBlender', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local blender = GlobalScirptData:getDeviceByCitizenId('oilrig_blender', citizenid)
     if blender == false then
          Init_Blender({
               citizenid = citizenid
          })
          blender = GlobalScirptData:getDeviceByCitizenId('oilrig_blender', citizenid)
     end

     cb(blender)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:toggle_blender', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local blender = GlobalScirptData:getDeviceByCitizenId('oilrig_blender', citizenid)
     if blender.metadata.state == false then
          blender.metadata.state = true
     else
          blender.metadata.state = false
     end
     cb(blender)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:recipe_blender', function(source, cb, inputData)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local blender = GlobalScirptData:getDeviceByCitizenId('oilrig_blender', citizenid)

     blender.metadata.recipe.heavy_naphtha = inputData.heavy_naphtha or blender.metadata.recipe.heavy_naphtha
     blender.metadata.recipe.light_naphtha = inputData.light_naphtha or blender.metadata.recipe.light_naphtha
     blender.metadata.recipe.other_gases = inputData.other_gases or blender.metadata.recipe.other_gases

     cb(blender)
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
     for key, value in pairs(GlobalScirptData:readAll()) do
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
