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
     Sync_with_database()
end)
-- ==========================================
--          Update / server Side
-- ==========================================

QBCore.Functions.CreateCallback('keep-oilrig:server:pump_fueloil', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     if player == nil then
          TriggerClientEvent('QBCore:Notify', source, "failed to find player!")
          cb(false)
          return
     end
     SendOilFuelToStorage(player, source, cb)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:PumpOilToStorageCallback', function(source, cb, data)
     local player = QBCore.Functions.GetPlayer(source)
     if player == nil then
          TriggerClientEvent('QBCore:Notify', source, "failed to find player!")
          cb(false)
          return
     end
     local oilrig, id = GlobalScirptData:getByHash(data)
     if not oilrig then
          cb(false)
          return
     end
     local is_employee, is_owner = oilrig.is_employee(player.PlayerData.citizenid)
     if not is_employee and not is_owner then
          TriggerClientEvent('QBCore:Notify', source, "You do no have access to this part!")
          cb(false)
          return
     end
     if oilrig.metadata.oil_storage <= 0 then
          TriggerClientEvent('QBCore:Notify', source, "Oil storage is empty!")
          cb(false)
          return
     end
     SendOilToStorage(oilrig, source, cb)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:getStorageData', function(source, cb)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          }, cb)
          return
     end
     cb(storage)
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:Withdraw', function(source, cb, data)
     if not data then cb(false) return end
     if not data.amount then cb(false) return end
     if not data.type then cb(false) return end
     if type(data.amount) == "string" then data.amount = tonumber(data.amount) end
     if data.amount <= 0 then
          TriggerClientEvent('QBCore:Notify', source, "Withdraw must be more than 0!", 'error')
          return
     end

     if not data.truck then
          local barrel_max_size = Oilwell_config.Settings.capacity.oilbarell.size
          local stash_size = 5

          if data.amount > (barrel_max_size * stash_size) then
               TriggerClientEvent('QBCore:Notify', source, "Withdraw stash dont have enough space!", 'error')
               TriggerClientEvent('QBCore:Notify', source, "Maximum: " .. (barrel_max_size * stash_size) .. "/Gal",
                    'error')
               return
          end
     else
          if data.amount > 100000 then
               TriggerClientEvent('QBCore:Notify', source, "Maximum: 100,000/Gal",
                    'error')
               return
          end
     end

     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)

     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })
          TriggerClientEvent('QBCore:Notify', source, "Could not find connect to your stroage try again!", 'error')
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

     storage.metadata[data.type] = storage.metadata[data.type] - data.amount
     storage.metadata.queue[#storage.metadata.queue + 1] = {
          truck = data.truck,
          type = data.type,
          gal = data.amount,
          avg_gas_octane = storage.metadata.avg_gas_octane
     }

     if storage.metadata[data.type] < 1.0 then
          -- remove waste
          storage.metadata.avg_gas_octane = 87
          storage.metadata[data.type] = 0
     end
     TriggerClientEvent('QBCore:Notify', source, "We compeleted your withdraw request.", 'success')
     cb(true)
end)

local function isWithdrawStashEmpty(Player)
     local stash = 'Withdraw_' .. Player.PlayerData.citizenid
     local result = MySQL.Sync.fetchScalar("SELECT items FROM stashitems WHERE stash= ?", { stash })
     if result == nil then
          -- need to init stash
          return false, -1
     end
     result = json.decode(result)
     local size = Tablelength(result)
     if size >= 1 then
          return false, size
     else
          return true, size
     end
end

local function divide_barells(barrel)
     local barrel_max_size = Oilwell_config.Settings.capacity.oilbarell.size
     local divide = math.floor(barrel.gal / barrel_max_size)
     local leftover = barrel.gal % barrel_max_size

     local count = {
          full_size = 0,
          leftover = 0,
          leftover_value = 0
     }
     for i = 1, divide + 1, 1 do
          if i ~= (divide + 1) then
               count.full_size = count.full_size + 1
          else
               if leftover ~= 0 then
                    count.leftover = count.leftover + 1
                    count.leftover_value = leftover
               end
          end
     end
     return count
end

local function add_oilbarell_2(Player, divide_res, barrel_type, barrel_avg_gas_octane)
     -- send barells to withdraw stash
     local barrel_max_size = Oilwell_config.Settings.capacity.oilbarell.size
     local items = {}
     local stash = 'Withdraw_' .. Player.PlayerData.citizenid
     local result = MySQL.Sync.fetchAll("SELECT items FROM stashitems WHERE stash=?", { stash })
     local res = result[1]
     if res == nil then return false end
     if res.items == nil then return false end
     res.items = json.decode(res.items)
     if res.items == nil then return false end
     local item_name = 'oilbarell'
     local itemInfo = QBCore.Shared.Items[item_name:lower()]

     if barrel_type ~= 'gasoline' then
          barrel_avg_gas_octane = 0
     end

     for i = 1, divide_res.full_size, 1 do
          items[#items + 1] = {
               name = itemInfo["name"],
               amount = 1,
               label = itemInfo["label"],
               description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
               weight = itemInfo["weight"], -- can not set weight
               type = itemInfo["type"],
               unique = itemInfo["unique"],
               useable = itemInfo["useable"],
               image = itemInfo["image"],
               slot = #items + 1,
               info = {
                    type = barrel_type,
                    gal = barrel_max_size,
                    avg_gas_octane = barrel_avg_gas_octane
               }
          }
     end

     for i = 1, divide_res.leftover, 1 do
          items[#items + 1] = {
               name = itemInfo["name"],
               amount = 1,
               label = itemInfo["label"],
               description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
               weight = itemInfo["weight"], -- can not set weight
               type = itemInfo["type"],
               unique = itemInfo["unique"],
               useable = itemInfo["useable"],
               image = itemInfo["image"],
               slot = #items + 1,
               info = {
                    type = barrel_type,
                    gal = divide_res.leftover_value,
                    avg_gas_octane = barrel_avg_gas_octane
               }
          }
     end

     MySQL.Async.execute("UPDATE stashitems SET items = ? WHERE stash = ?", { json.encode(items), stash })
end

RegisterNetEvent('keep-oilwell:server:purgeWithdrawStash', function()
     local Player = QBCore.Functions.GetPlayer(source)
     local stash = 'Withdraw_' .. Player.PlayerData.citizenid
     MySQL.Async.execute("UPDATE stashitems SET items = '[]' WHERE stash = ?", { stash })
     TriggerClientEvent('QBCore:Notify', source, "Purge compeleted!", 'success')
end)

QBCore.Functions.CreateCallback('keep-oilrig:server:withdraw_from_queue', function(source, cb, Type)
     local player = QBCore.Functions.GetPlayer(source)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })
          TriggerClientEvent('QBCore:Notify', source, "Could not find connect to your stroage try again!", 'error')
          cb(false)
          return
     end
     if type(storage.metadata.queue) ~= "table" then
          -- failsafe
          storage.metadata.queue = {}
          cb(false)
          return
     end
     if type(storage.metadata.queue) == "table" and next(storage.metadata.queue) == nil then
          TriggerClientEvent('QBCore:Notify', source, "You don't have anything in queue!", 'error')
          cb(false)
          return
     end
     for key, barrel in pairs(storage.metadata.queue) do

          if barrel == nil then
               goto here
          end

          if not (barrel.truck == Type) then
               goto here
          end
          if not barrel.truck then
               local stashEmpty, size = isWithdrawStashEmpty(player)
               if not stashEmpty and not (size == -1) then
                    TriggerClientEvent('QBCore:Notify', source, "withdraw stash is not empty!", 'error')
                    cb(false)
                    return
               elseif not stashEmpty and size == -1 then
                    TriggerClientEvent('QBCore:Notify', source, "pls, open your withdraw stash for first time!",
                         'error')
                    cb(false)
                    return
               end
               local divide_res = divide_barells(barrel)

               -- calcualte barell cost
               local cost_of_1 = Oilwell_config.Settings.capacity.oilbarell.cost
               local total_cost = cost_of_1 * (divide_res.full_size + divide_res.leftover)

               local removemoeny = player.Functions.RemoveMoney('bank', total_cost, 'oil_barells')
               if removemoeny then
                    add_oilbarell_2(player, divide_res, barrel.type, barrel.avg_gas_octane)
                    TriggerClientEvent('QBCore:Notify', source, "Request compeleted!", 'success')
                    cb({ truck = false })
                    storage.metadata.queue[key] = nil
                    return
               else
                    TriggerClientEvent('QBCore:Notify', source, "No money!", 'error')
               end
               cb(storage)
               return
          elseif barrel.truck and barrel.truck == true then
               local divide_res = divide_barells(barrel)

               -- calcualte barell cost
               local removemoeny = player.Functions.RemoveMoney('bank', 25000, 'oil_barells')
               if removemoeny then
                    local items = Split_oilbarrel_size(divide_res, barrel.type, barrel.avg_gas_octane)
                    items.truck = true
                    TriggerClientEvent('QBCore:Notify', source, "Request compeleted!", 'success')
                    cb(items)
                    storage.metadata.queue[key] = nil
                    return
               else
                    TriggerClientEvent('QBCore:Notify', source, "No money!", 'error')
               end
               cb(storage)
               return
          end
          ::here::
     end
     TriggerClientEvent('QBCore:Notify', source, "You don't have anything in this queue!", 'error')
     cb(false)
end)

QBCore.Functions.CreateUseableItem('oilbarell', function(source, item)
     local Player = QBCore.Functions.GetPlayer(source)
end)

QBCore.Functions.CreateUseableItem('oilwell', function(source, item)
     local Player = QBCore.Functions.GetPlayer(source)
     local RemovedItem = Player.Functions.RemoveItem('oilwell', 1)
     TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items['oilwell'], "remove")

     if item.amount >= 1 and RemovedItem == true then
          TriggerClientEvent('keep-oilrig:client:spawn', source)
     end
end)

function Split_oilbarrel_size(divide_res, barrel_type, barrel_avg_gas_octane)
     local barrel_max_size = Oilwell_config.Settings.capacity.oilbarell.size
     local item_name = 'oilbarell'
     local itemInfo = QBCore.Shared.Items[item_name:lower()]
     local items = {}

     for i = 1, divide_res.full_size, 1 do
          items[#items + 1] = {
               name = itemInfo["name"],
               amount = 1,
               label = itemInfo["label"],
               description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
               weight = itemInfo["weight"], -- can not set weight
               type = itemInfo["type"],
               unique = itemInfo["unique"],
               useable = itemInfo["useable"],
               image = itemInfo["image"],
               slot = #items + 1,
               info = {
                    type = barrel_type,
                    gal = barrel_max_size,
                    avg_gas_octane = barrel_avg_gas_octane
               }
          }
     end

     for i = 1, divide_res.leftover, 1 do
          items[#items + 1] = {
               name = itemInfo["name"],
               amount = 1,
               label = itemInfo["label"],
               description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
               weight = itemInfo["weight"], -- can not set weight
               type = itemInfo["type"],
               unique = itemInfo["unique"],
               useable = itemInfo["useable"],
               image = itemInfo["image"],
               slot = #items + 1,
               info = {
                    type = barrel_type,
                    gal = divide_res.leftover_value,
                    avg_gas_octane = barrel_avg_gas_octane
               }
          }
     end
     return items
end

RegisterNetEvent('keep-oilrig:server:updateSpeed', function(inputData, id)
     local player = QBCore.Functions.GetPlayer(source)
     if player == nil then return end
     -- validate speed for 0 - 100
     local oilrig = GlobalScirptData:read(id)
     local is_employee, is_owner = oilrig.is_employee(player.PlayerData.citizenid)
     if not is_employee and not is_owner then
          TriggerClientEvent('QBCore:Notify', source, "You do not have access to this oilwell!", 'error')
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
     local CDU = GlobalScirptData:getDeviceByCitizenId('oilrig_cdu', citizenid)

     if CDU == false then
          Init_CDU(citizenid, cb)
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
          TriggerClientEvent('QBCore:Notify', source, "Could not find connect to your stroage try again!", 'error')
          cb(false)
          return
     end

     if inputData.amount <= 0 then
          TriggerClientEvent('QBCore:Notify', source, "Must be more than 0", 'error')
          cb(CDU)
          return
     end

     if storage.metadata.crudeOil == 0.0 then
          TriggerClientEvent('QBCore:Notify', source, "Your storage is empty", 'error')
          cb(CDU)
          return
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
          Init_Blender(citizenid, cb)
          return
     end

     cb(blender)
end)

local function inRange(x, min, max)
     return (x >= min and x <= max)
end

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

     for _, value in pairs(inputData) do
          local current_num = tonumber(value)
          if not inRange(current_num, 0, 100) then
               TriggerClientEvent('QBCore:Notify', source, "numbers must be between 0-100", 'error')
               return
          end
          inputData[_] = current_num
     end

     blender.metadata.recipe.heavy_naphtha = inputData.heavy_naphtha or blender.metadata.recipe.heavy_naphtha
     blender.metadata.recipe.light_naphtha = inputData.light_naphtha or blender.metadata.recipe.light_naphtha
     blender.metadata.recipe.other_gases = inputData.other_gases or blender.metadata.recipe.other_gases

     --new elements
     blender.metadata.recipe.diesel = inputData.diesel or blender.metadata.recipe.diesel
     blender.metadata.recipe.kerosene = inputData.kerosene or blender.metadata.recipe.kerosene

     cb(blender)
end)

local current_transport_stock = {
     crudeOil = 0,
     fuel_oil = 0,
     gasoline = 0
}
local TRANSPORT = Oilwell_config.Transport

local function change_item_info(Player, slot, info)
     if Player.PlayerData.items[slot] then
          Player.PlayerData.items[slot].info = info
     end
     Player.Functions.SetInventory(Player.PlayerData.items, true)
end

local function reachedMaxStock(Type)
     local max = TRANSPORT.max_stock
     return (current_transport_stock[Type] >= max)
end

local function canWeAcceptMoreStock(Type, amount)
     local max = TRANSPORT.max_stock
     return not (current_transport_stock[Type] + amount >= max)
end

local function remove_item(source, Player, name, slot)
     Player.Functions.RemoveItem(name, 1, slot)
     TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[name], "remove")
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

     if not current_info.type then
          TriggerClientEvent('QBCore:Notify', source, 'Failed to get oil type', 'error')
          return
     end

     if not (current_info.type == 'crudeOil' or current_info.type == 'fuel_oil' or current_info.type == 'gasoline') then
          TriggerClientEvent('QBCore:Notify', source, 'We dont export this type of oil!', 'error')
          return
     end

     if reachedMaxStock(current_info.type) then
          -- when we reached max stock
          TriggerClientEvent('QBCore:Notify', source, 'Currently we can not accept more offers pls come back later!',
               'primary')
          return
     end

     if not canWeAcceptMoreStock(current_info.type, amount) then
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

     local gender = Oilwell_config.Locale.info.mr
     if player.PlayerData.charinfo.gender == 1 then
          gender = Oilwell_config.Locale.info.mrs
     end
     local charinfo = player.PlayerData.charinfo

     local cost = TRANSPORT.prices[current_info.type] * amount
     if current_info.gal > amount then
          -- asking less than what they have
          current_info.gal = math.floor(current_info.gal - amount)
          -- this function can be called just once after conditions but this should prevent switching slots
          change_item_info(player, oil_barrel.slot, oil_barrel.info)

          player.Functions.AddMoney("bank", cost, 'crude_oil_transport')

          msg_string = 'You sold: %d gal for: %.2f$'
          msg_string = string.format(msg_string, amount, cost)
          TriggerClientEvent('QBCore:Notify', source, msg_string, 'success')

          TriggerClientEvent('keep-oilrig:client:local_mail_sender', source, {
               gender = gender,
               charinfo = charinfo,
               refund = 0,
               money = cost,
               amount = amount
          })
     elseif current_info.gal == amount and amount ~= 0 then
          -- asking for all they have
          current_info.gal = 0
          -- this function can be called just once after conditions but this should prevent switching slots
          change_item_info(player, oil_barrel.slot, oil_barrel.info)
          remove_item(source, player, 'oilbarell', oil_barrel.slot)
          -- money for what they sold
          local money = (cost) + TRANSPORT.barell_refund
          player.Functions.AddMoney("bank", money, 'crude_oil_transport')

          msg_string = 'You sold: %d gal for: %.2f$ + barrel refund: %.2f$'
          msg_string = string.format(msg_string, amount, cost, TRANSPORT.barell_refund)
          TriggerClientEvent('QBCore:Notify', source, msg_string, 'success')

          TriggerClientEvent('keep-oilrig:client:local_mail_sender', source, {
               gender = gender,
               charinfo = charinfo,
               refund = TRANSPORT.barell_refund,
               money = cost,
               amount = amount
          })
     else
          -- invalid
          -- or they ask for much more than they have
          TriggerClientEvent('QBCore:Notify', source, 'You either do not have a oil barell or its empty!', 'error')
          cb(false)
          return
     end

     current_transport_stock[current_info.type] = current_transport_stock[current_info.type] + amount
     cb(true)
end)

RegisterNetEvent('keep-oilrig:server:oil_transport:checkPrice', function()
     local names      = {
          crudeOil = 'Crude Oil',
          gasoline = 'Gasoline',
          fuel_oil = 'Fuel Oil'
     }
     local msg_string = "Our Current Stock of [%s] is: %d/%d Price Per Gal: %.2f$"
     for key, value in pairs(current_transport_stock) do
          local s = string.format(msg_string, names[key], math.floor(value), TRANSPORT.max_stock, TRANSPORT.prices[key])
          TriggerClientEvent('QBCore:Notify', source, s, 'primary', 7500)
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
     for key, value in pairs(GlobalScirptData:readAll()) do
          temp[key] = deepcopy(value)
          temp[key].employees_list = nil
          temp[key].employees = nil
          temp[key].is_employee = nil
          temp[key].metadata = nil
          temp[key].citizenid = nil

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
               position = position,
               name = inputData.name,
               state = false,
               oilrig_hash = hash,
               metadata = metadata
          }, {})
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
     if not oil_well then cb(false) return end
     local is_employee, is_owner = oil_well.is_employee(Player.PlayerData.citizenid)
     if not is_employee and not is_owner then
          cb(false)
          return
     end
     for _, data in pairs(items) do
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
     MySQL.Async.execute("UPDATE stashitems SET items = '[]' WHERE stash = ?", { stash })
     cb(true)
end)

QBCore.Functions.CreateCallback('keep-oilwell:server:is_employee', function(source, cb, oilrig_hash)
     local Player = QBCore.Functions.GetPlayer(source)
     local oil_well = GlobalScirptData:getByHash(oilrig_hash)
     if not oil_well then cb(false) return end
     cb(oil_well.is_employee(Player.PlayerData.citizenid))
end)

QBCore.Functions.CreateCallback('keep-oilwell:server:employees_list', function(source, cb, oilrig_hash)
     local Player = QBCore.Functions.GetPlayer(source)
     local oil_well = GlobalScirptData:getByHash(oilrig_hash)
     if not oil_well then cb(false) return end
     local is_employee, is_owner = oil_well.is_employee(Player.PlayerData.citizenid)
     if not is_employee and not is_owner then
          TriggerClientEvent('QBCore:Notify', source, "You can not see this list!", 'error')
          cb(false)
          return
     end
     local list = deepcopy(oil_well.employees_list())
     for index, value in ipairs(list) do
          value.id = nil
          local Player = QBCore.Functions.GetPlayerByCitizenId(value.citizenid)
          if Player then
               value.charinfo = Player.PlayerData.charinfo
               value.online = true
          else
               Player = QBCore.Player.GetOfflinePlayer(value.citizenid)
               if not Player then
                    value.charinfo = {
                         firstname = 'deleted',
                         lastname = ''
                    }
                    value.online = false
               end
          end
     end
     cb(list)
end)

RegisterNetEvent('keep-oilwell:server:add_employee', function(oilrig_hash, state_id)
     state_id = tonumber(state_id)
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     local oil_well = GlobalScirptData:getByHash(oilrig_hash)
     if not oil_well then return end
     local _, is_owner = oil_well.is_employee(Player.PlayerData.citizenid)
     if not is_owner then
          TriggerClientEvent('QBCore:Notify', src, "You must be owner of this oilwell!", 'error')
          return
     end
     local new_employee = QBCore.Functions.GetPlayer(state_id)
     if not new_employee then
          TriggerClientEvent('QBCore:Notify', src, "Wrong state id!", 'error')
          return
     end

     if new_employee.PlayerData.citizenid == oil_well.citizenid then
          TriggerClientEvent('QBCore:Notify', src, "You can not add owner as an employee", 'error')
          return
     end

     local sqlQuery = 'INSERT INTO oilcompany_employees (citizenid, oilrig_hash) VALUES (:citizenid, :oilrig_hash)'
     local QueryData = {
          ['citizenid']   = new_employee.PlayerData.citizenid,
          ['oilrig_hash'] = oilrig_hash,
     }
     MySQL.Async.execute(sqlQuery, QueryData, function()
          local e_sql = 'SELECT * FROM oilcompany_employees WHERE oilrig_hash = ?'
          oil_well.employees = MySQL.Sync.fetchAll(e_sql, { oilrig_hash })
          local id = #oil_well.employees + 1
          oil_well.employees[id] = {
               id = id,
               oilrig_hash = oil_well.oilrig_hash,
               citizenid = oil_well.citizenid
          }
          TriggerClientEvent('QBCore:Notify', src, "New employee added to the list", 'success')
     end)
end)

RegisterNetEvent('keep-oilwell:server:remove_employee', function(oilrig_hash, citizenid)
     if type(oilrig_hash) ~= 'string' or type(citizenid) ~= 'string' then
          print('wrong type')
          return
     end
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     local oil_well = GlobalScirptData:getByHash(oilrig_hash)
     if not oil_well then return end
     if not citizenid then return end
     local _, is_owner = oil_well.is_employee(Player.PlayerData.citizenid)
     if not is_owner then
          TriggerClientEvent('QBCore:Notify', src, "You must be owner of this oilwell!", 'error')
          return
     end

     if citizenid == oil_well.citizenid then
          TriggerClientEvent('QBCore:Notify', src, "You can not fire yourself", 'error')
          return
     end

     local sqlQuery = 'DELETE FROM oilcompany_employees WHERE citizenid = ?'
     local QueryData = {
          citizenid
     }
     MySQL.Async.execute(sqlQuery, QueryData, function()
          local e_sql = 'SELECT * FROM oilcompany_employees WHERE oilrig_hash = ?'
          oil_well.employees = MySQL.Sync.fetchAll(e_sql, { oilrig_hash })
          local id = #oil_well.employees + 1
          oil_well.employees[id] = {
               id = id,
               oilrig_hash = oil_well.oilrig_hash,
               citizenid = oil_well.citizenid
          }
          TriggerClientEvent('QBCore:Notify', src, "Employee fired!", 'success')
     end)
end)

QBCore.Functions.CreateCallback('keep-oilwell:server:oilwell_metadata', function(source, cb, oilrig_hash)
     local oil_well = GlobalScirptData:getByHash(oilrig_hash)
     if not oil_well then cb(false) return end
     cb(oil_well.metadata)
end)

RegisterNetEvent('keep-oilwell:server:remove_oilwell', function(oilrig_hash)
     -- flag a oilwell as deleted
     local src = source
     local Player = QBCore.Functions.GetPlayer(src)
     local oil_well = GlobalScirptData:getByHash(oilrig_hash)
     if not oil_well then return print('oilwell not found', src, oilrig_hash) end
     if not Player.PlayerData.job.isboss then
          DropPlayer(src, 'you are not CEO')
          return
     end

     local sqlQuery = 'UPDATE oilrig_position SET deleted = ? WHERE oilrig_hash = ?'
     MySQL.Async.execute(sqlQuery, { 1, oil_well.oilrig_hash }, function()
          TriggerClientEvent('QBCore:Notify', src,
               "The deconstruction request is accepted it will be removed after the tsunami!",
               'success'
          )
     end)
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
