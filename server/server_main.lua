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
     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })
          storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
          cb(storage)
     end
     cb(storage)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:WithdrawWithBarrel', function(source, cb, data)
     if type(data.amount) == "string" then
          data.amount = tonumber(data.amount)
     end
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })

          storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     end
     if data.type == nil then
          cb(false)
          return
     end
     local value = storage.metadata[data.type]

     if value < data.amount then
          TriggerClientEvent('QBCore:Notify', source, "You can not withdraw this much!", 'error')
          TriggerClientEvent('QBCore:Notify', source, "Requested: " .. data.amount .. " Current: " .. value, 'error')
          cb(false)
          return
     end
     -- #TODO revert back to 0.0
     storage.metadata[data.type] = storage.metadata[data.type] - data.amount
     storage.metadata.queue[#storage.metadata.queue + 1] = {
          type = data.type,
          gal = storage.metadata[data.type],
          avg_gas_octane = 87 -- #TODO replace avg_gas_octane placeholder
     }
     TriggerClientEvent('QBCore:Notify', source, "We compeleted your withdraw request.", 'success')
     cb(true)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:withdraw_from_queue', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })

          storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     end
     if type(storage.metadata.queue) == "table" and next(storage.metadata.queue) == nil then
          TriggerClientEvent('QBCore:Notify', source, "You don't have anything in queue!", 'error')
          cb(false)
          return
     end

     local barrel_max_size = Oilwell_config.Settings.capacity.oilbarell.size
     for key, barrel in pairs(storage.metadata.queue) do
          player.Functions.RemoveMoney('bank', Oilwell_config.Settings.capacity.oilbarell.price, 'oil barell')

          local divide = math.floor(barrel.gal / barrel_max_size)
          local remainder = barrel.gal % barrel_max_size

          for i = 1, divide + 1, 1 do
               if i ~= (divide + 1) then
                    player.Functions.AddItem('oilbarell', 1, 1, {
                         type = barrel.type,
                         gal = barrel_max_size,
                         avg_gas_octane = barrel.avg_gas_octane
                    })
               else
                    if remainder ~= 0 then
                         player.Functions.AddItem('oilbarell', 1, 1, {
                              type = barrel.type,
                              gal = remainder,
                              avg_gas_octane = barrel.avg_gas_octane
                         })
                    end
               end
          end

          TriggerClientEvent('QBCore:Notify', source, "Request compeleted!", 'success')
          cb(storage)
          -- storage.metadata.queue[key] = nil
          return
     end
end)

QBCore.Functions.CreateUseableItem('oilbarell', function(source, item)
     local Player = QBCore.Functions.GetPlayer(source)
     print_table(item)
end)

QBCore.Functions.CreateUseableItem('oilwell', function(source, item)
     local Player = QBCore.Functions.GetPlayer(source)
     local RemovedItem = Player.Functions.RemoveItem('oilwell', 1)

     if item.amount >= 1 and RemovedItem == true then
          TriggerClientEvent('keep-oilrig:client:spawn', source)
     end
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:WithdrawLoadInTruck', function(source, cb, data)
     if type(data.amount) == "string" then
          data.amount = tonumber(data.amount)
     end
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     if player.PlayerData.citizenid == data.citizenid then
          local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
          local value = storage.metadata[data.type]

          if value == 0.0 then
               TriggerClientEvent('QBCore:Notify', source, "Your storage is empty!", 'error')
               cb(false)
               return
          end

          if data.amount <= 0.0 or value < data.amount then
               TriggerClientEvent('QBCore:Notify', source, "You don't have that much in your storage!", 'error')
               TriggerClientEvent('QBCore:Notify', source, "Requested: " .. data.amount .. " Current: " .. value)
               cb(false)
               return
          end

          local RemoveMoney = player.Functions.RemoveMoney('bank', Oilwell_config.Settings.capacity.truck.price,
               'oil barell truck')
          if RemoveMoney ~= true then
               TriggerClientEvent('QBCore:Notify', source, "you don't have enough money in your bank!", 'error')
               cb(false)
               return
          end
          storage.metadata[data.type] = storage.metadata[data.type] - data.amount
          local items = split_oilbarrel_size(data.amount, data)
          cb(items)
     end
end)

local function SetCarItemsInfo(ouritems)
     local items = {}
     for k, item in pairs(ouritems) do
          local itemInfo = QBCore.Shared.Items[item.name:lower()]
          items[item.slot] = {
               name = itemInfo["name"],
               amount = tonumber(item.amount),
               info = item.info,
               label = itemInfo["label"],
               description = itemInfo["description"] and itemInfo["description"] or "",
               weight = itemInfo["weight"],
               type = itemInfo["type"],
               unique = itemInfo["unique"],
               useable = itemInfo["useable"],
               image = itemInfo["image"],
               slot = item.slot,
          }
     end
     return items
end

function split_oilbarrel_size(size, data)
     local barrel_max_size = Oilwell_config.Settings.capacity.oilbarell.size

     local divide = math.floor(size / barrel_max_size)
     local remainder = size % barrel_max_size

     local items_table = {}
     for i = 1, divide + 1, 1 do
          local index = #items_table + 1
          items_table[index] = {
               name = "oilbarell",
               amount = 1,
               type = "item",
               slot = i,
               weight = 1000,
          }

          if i ~= (divide + 1) then
               items_table[index].info = {
                    gal = barrel_max_size,
                    type = data.type,
                    avg_gas_octane = 87
               }
          else
               if remainder ~= 0 then
                    items_table[index].info = {
                         gal = remainder,
                         type = data.type,
                         avg_gas_octane = 87
                    }
               end
          end
     end
     return SetCarItemsInfo(items_table)
end

RegisterNetEvent('keep-oilrig:server:updateSpeed', function(inputData, id)
     local player = QBCore.Functions.GetPlayer(source)
     if player == nil then return end
     -- validate speed for 0 - 100
     local oilrig = GlobalScirptData:read(id)
     if player.PlayerData.citizenid ~= oilrig.citizenid then
          TriggerClientEvent('QBCore:Notify', source, "You are not owner of oil pump!")
          return
     end

     local speed = tonumber(inputData.speed)
     if not (0 <= speed and speed <= 100) then
          TriggerClientEvent('QBCore:Notify', source, 'speed must be between 0 to 100', "error")
          return
     end

     oilrig.metadata.speed = speed
     -- sync speed on other clients
     TriggerClientEvent('keep-oilrig:client:syncSpeed', -1, id, speed)
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
          CDU = GlobalScirptData:getDeviceByCitizenId('oilrig_cdu', citizenid)
          cb(CDU)
          return
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

     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })

          storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     end

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

local current_transport_stock = 0
local TRANSPORT = Oilwell_config.Transport

local function change_item_info(Player, slot, info)
     if Player.PlayerData.items[slot] then
          Player.PlayerData.items[slot].info = info
     end
     Player.Functions.SetInventory(Player.PlayerData.items, true)
end

QBCore.Functions.CreateCallback('keep-oilrig:server:oil_transport:fillTransportWell', function(source, cb, amount)
     amount = tonumber(amount) -- just in case
     local player = QBCore.Functions.GetPlayer(source)
     local oil_barrel = player.Functions.GetItemByName('oilbarell')
     local msg_string = ""

     if not oil_barrel then
          TriggerClientEvent('QBCore:Notify', source, 'You do not have a oil barrel!', 'error')
          return
     end

     local current_info = oil_barrel.info
     local do_we_need_more_stock = current_transport_stock + amount

     if not current_info.type then
          TriggerClientEvent('QBCore:Notify', source, 'Failed to get oil type', 'error')
          return
     end

     if not current_info.type == 'crudeOil' then
          TriggerClientEvent('QBCore:Notify', source, 'We are experts in crude oil transportation!', 'error')
          return
     end

     if TRANSPORT.max_stock <= current_transport_stock then
          -- when we reached max stock
          TriggerClientEvent('QBCore:Notify', source, 'Currently we can not accept more offers pls come back later!',
               'primary')
          current_transport_stock = TRANSPORT.max_stock
          return
     end

     if do_we_need_more_stock > TRANSPORT.max_stock then
          -- when buying results in more oil than what we need
          local max_amount = math.floor(TRANSPORT.max_stock - current_transport_stock)
          msg_string = "We can only accept maximum amount of %d gallons"
          msg_string = string.format(msg_string, max_amount)
          TriggerClientEvent('QBCore:Notify', source, '', 'error')
          return
     end

     if current_info.gal < amount then
          -- when they don't have what they want to sell
          msg_string = 'You asked to sell:  %d but only have: %d'
          msg_string = string.format(msg_string, amount, current_info.gal)
          TriggerClientEvent('QBCore:Notify', source, msg_string, 'error')
          cb(false)
          return
     end

     if current_info.gal > amount then
          -- asking less than what they have
          current_info.gal = math.floor(current_info.gal - amount)
          -- this function can be called just once after conditions but this should prevent switching slots
          change_item_info(player, oil_barrel.slot, oil_barrel.info)

          player.Functions.AddMoney("bank", TRANSPORT.price * amount, 'crude_oil_transport')

          msg_string = 'You sold: %d gal for: %.2f$'
          msg_string = string.format(msg_string, amount, TRANSPORT.price * amount)
          TriggerClientEvent('QBCore:Notify', source, msg_string, 'success')
     elseif current_info.gal == amount and amount ~= 0 then
          -- asking for all they have
          current_info.gal = 0
          -- this function can be called just once after conditions but this should prevent switching slots
          change_item_info(player, oil_barrel.slot, oil_barrel.info)

          player.Functions.AddMoney("bank", TRANSPORT.price * amount, 'crude_oil_transport')
          msg_string = 'You sold: %d gal for: %.2f$'
          msg_string = string.format(msg_string, amount, TRANSPORT.price * amount)
          TriggerClientEvent('QBCore:Notify', source, msg_string, 'success')
     else
          -- invalid
          -- or they ask for much more than they have
          TriggerClientEvent('QBCore:Notify', source, 'You either do not have a oil barell or its empty!', 'error')
          cb(false)
          return
     end

     local gender = Oilwell_config.Locale.info.mr
     if player.PlayerData.charinfo.gender == 1 then
          gender = Oilwell_config.Locale.info.mrs
     end
     local charinfo = player.PlayerData.charinfo

     TriggerClientEvent('keep-oilrig:client:local_mail_sender', source, {
          gender = gender,
          charinfo = charinfo,
          transport_price = TRANSPORT.price,
          amount = amount
     })
     current_transport_stock = current_transport_stock + amount
     cb(true)
end)

RegisterServerEvent('keep-oilrig:server:oil_transport:fillTransportWell:give_money')
AddEventHandler('keep-oilrig:server:oil_transport:fillTransportWell:give_money', function(cid, amount)
     local player = QBCore.Functions.GetPlayer(cid)
     player.Functions.AddMoney("bank", TRANSPORT.price * amount, 'crude_oil_transport')
end)

RegisterNetEvent('keep-oilrig:server:oil_transport:checkPrice', function()
     local msg_string = "Our Current Stock is: %d/%d Price Per Gal: %.2f$"
     msg_string = string.format(msg_string, math.floor(current_transport_stock), TRANSPORT.max_stock, TRANSPORT.price)
     TriggerClientEvent('QBCore:Notify', source, msg_string)
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
---@param coords table
---@return 'NetId'
QBCore.Functions.CreateCallback('keep-oilrig:server:createNewOilrig', function(source, cb, coords)
     local rigmodel = GetHashKey('p_oil_pjack_03_s')

     local oilrig = CreateObject(rigmodel, coords.x, coords.y, coords.z, 1, 1, 0)
     while not DoesEntityExist(oilrig) do
          Wait(50)
     end
     local NetId = NetworkGetNetworkIdFromEntity(oilrig)
     cb(NetId)
end)

---register oilrig to player by their current cid
QBCore.Functions.CreateCallback('keep-oilrig:server:regiserOilrig', function(source, cb, inputData)
     -- get player by entered cid
     local cid = tonumber(inputData.cid)
     local player = QBCore.Functions.GetPlayer(cid)
     if player ~= nil then
          local PlayerData = player.PlayerData
          local entity = NetworkGetEntityFromNetworkId(inputData.netId)
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
               secduration = 0,
               oil_storage = 0,
               part_info = {
                    belt = 0,
                    polish = 0,
                    clutch = 0,
               }
          }
          local hash = RandomHash(15)
          local id = GeneralInsert({
               citizenid = PlayerData.citizenid,
               name = inputData.name,
               oilrig_hash = hash,
               position = position,
               metadata = metadata,
               state = false
          })
          GlobalScirptData:newOilwell({
               id = id,
               citizenid = PlayerData.citizenid,
               position = json.encode(position),
               name = inputData.name,
               state = false,
               oilrig_hash = hash,
               metadata = json.encode(metadata)
          })
          TriggerClientEvent('keep-oilwell:client:force_reload', -1)
          cb(true)
     else
          TriggerClientEvent('QBCore:Notify', source, "Could not find player by it cid!")
          cb(false)
     end
end)

function GetOilPumpItems(oilrig_hash)
     local items = {}
     local stash = 'oilPump_' .. oilrig_hash
     local result = MySQL.Sync.fetchAll("SELECT items FROM stashitems WHERE stash=?", { stash })
     local res = result[1]
     if res == nil then return false end
     if res.items == nil then return false end
     res.items = json.decode(res.items)
     if res.items == nil then return false end

     for k, item in pairs(res.items) do
          local itemInfo = QBCore.Shared.Items[item.name:lower()]
          items[item.slot] = {
               name = itemInfo["name"],
               amount = tonumber(item.amount),
               info = item.info ~= nil and item.info or "",
               label = itemInfo["label"],
               description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
               weight = itemInfo["weight"],
               type = itemInfo["type"],
               unique = itemInfo["unique"],
               useable = itemInfo["useable"],
               image = itemInfo["image"],
               slot = item.slot,
          }
     end
     return items
end

local function isOneOfItems(item)
     local s = {
          ['oilfilter'] = 'polish',
          ['reliefvalvestring'] = 'polish',
          ['skewgear'] = 'clutch',
          ['timingchain'] = 'belt',
          ['driveshaft'] = 'clutch'
     }

     for _, part in pairs(s) do
          if item.name == _ then
               return item, part
          end
     end
     return nil
end

QBCore.Functions.CreateCallback('keep-oilwell:server:fix_oil_well', function(source, cb, oilrig_hash)
     local Player = QBCore.Functions.GetPlayer(source)
     local items = GetOilPumpItems(oilrig_hash)
     local stash = 'oilPump_' .. oilrig_hash
     local oil_well = GlobalScirptData:getByHash(oilrig_hash)

     for item, data in pairs(items) do
          local _item, part = isOneOfItems(data)
          if _item then
               local increase = oil_well.metadata.part_info[part] + 10 * _item.amount
               if increase >= 0 and increase <= 100 then
                    oil_well.metadata.part_info[part] = increase
               elseif increase >= 100 then
                    oil_well.metadata.part_info[part] = 100
               else
                    oil_well.metadata.part_info[part] = 0
               end
          end
     end

     TriggerClientEvent('QBCore:Notify', source, "Items used to fix oilwell.", 'primary')
     MySQL.Sync.fetchAll("UPDATE stashitems SET items = '[]' WHERE stash = ?", { stash })
     cb(true)
end)

-- ===========================
--          Commands
-- ===========================

QBCore.Commands.Add('create', 'create new oilwell', {}, false, function(source, args)
     if args[1] == 'oilwell' then
          TriggerClientEvent('keep-oilrig:client:spawn', source, args[1])
     end
end, 'admin')

QBCore.Commands.Add('togglejob', 'togglejob', {}, false, function(source, args)
     local PlayerJob = QBCore.Functions.GetPlayer(source).PlayerData.job
     TriggerClientEvent('keep-oilrig:client:goOnDuty', source, PlayerJob)
end, 'admin')
