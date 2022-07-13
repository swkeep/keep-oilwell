local QBCore = exports['qb-core']:GetCoreObject()

GlobalScirptData = {
     oldTable = { 'deepcopy of oil_well' },
     oil_well = {
          ['id'] = {
               id = 'integer',
               citizenid = 'string',
               position = {
                    coord = { 'table' },
                    rotation = { 'table' }
               },
               name = 'string',
               metadata = {
                    temp = 'float',
                    secduration = 'integer',
                    speed = 'integer',
                    oil_storage = 'float',
                    part_info = {
                         belt = 'float',
                         clutch = 'float',
                         polish = 'float'
                    }
               },
               state = 'bool',
               oilrig_hash = 'string'
          }
     },
     devices = {
          oilrig_storage = {
               {
                    id = 0,
                    citizenid = '',
                    name = '',
                    metadata = {
                         avg_gas_octane = 0,
                         gasoline = 0.0,
                         crudeOil = 0.0
                    },
               }
          },
          oilrig_cdu = {
               {
                    id = 0,
                    citizenid = '',
                    metadata = {
                         temp = 0.0,
                         req_temp = 0.0,
                         state = false,
                         oil_storage = 0.0,
                    },
               }
          },
          oilrig_blender = {
               {
                    id = 0,
                    citizenid = '',
                    metadata = {
                         heavy_naphtha = 0.0,
                         light_naphtha = 0.0,
                         other_gases = 0.0,
                         state = false,
                         recipe = {
                              heavy_naphtha = 0.0,
                              light_naphtha = 0.0,
                              other_gases = 0.0,
                         }
                    },
               }
          },
     }
}

local serverUpdateInterval = 10000 --  database update interval

--class
function GlobalScirptData:startInit()
     InitilaizeAllDataByDatabaseValues_2()
end

function GlobalScirptData:initPhaseTwo(o)
     -- wont work without CreateThread
     Citizen.CreateThread(function()
          -- oil_well
          for key, value in pairs(o.oil_well) do
               self:newOilwell(value)
          end
          -- oilrig_storage
          for key, value in pairs(o.oilrig_storage) do
               self:newDevice(value, 'oilrig_storage')
          end
          -- oilrig_cdu
          for key, value in pairs(o.oilrig_cdu) do
               self:newDevice(value, 'oilrig_cdu')
          end
          -- -- oilrig_blender
          for key, value in pairs(o.oilrig_blender) do
               self:newDevice(value, 'oilrig_blender')
          end
          self:saveThread()
          createMetadataTrackers(self.oil_well, self.devices)
     end)
end

function GlobalScirptData:newOilwell(oilwell)
     if self.oil_well[oilwell] ~= nil then
          return
     end
     local id = oilwell.id
     self.oil_well[id] = {}
     oilwell.metadata = json.decode(oilwell.metadata)
     oilwell.position = json.decode(oilwell.position)
     self.oil_well[id] = oilwell
end

function GlobalScirptData:newDevice(device, Type)
     if self.devices[Type][device.id] == nil then
          self.devices[Type][device.id] = {}
     end

     if Type == 'oilrig_storage' then
          device.metadata = json.decode(device.metadata)
          self.devices.oilrig_storage[device.id] = device
     elseif Type == 'oilrig_cdu' then
          device.metadata = json.decode(device.metadata)
          self.devices.oilrig_cdu[device.id] = device
     elseif Type == 'oilrig_blender' then
          device.metadata = json.decode(device.metadata)
          self.devices.oilrig_blender[device.id] = device

     end
end

function GlobalScirptData:saveThread()
     CreateThread(function()
          while true do
               self.oldTable = deepcopy({
                    self.devices,
                    self.oil_well,
               })
               Wait(serverUpdateInterval)
               --- save metadata when we detected changes!
               if isTableChanged(self.oldTable, {
                    self.devices,
                    self.oil_well,
               }) == true then
                    for key, value in pairs(self.oil_well) do
                         GeneralUpdate_2({
                              type = 'oilrig_oilwell',
                              citizenid = value.citizenid,
                              oilrig_hash = value.oilrig_hash,
                              metadata = value.metadata
                         })
                    end
                    -- save storage data
                    for id, storage in pairs(self.devices.oilrig_storage) do
                         GeneralUpdate_2({
                              type = 'oilrig_storage',
                              citizenid = storage.citizenid,
                              metadata = storage.metadata
                         })
                    end
                    -- save CDU data
                    for id, storage in pairs(self.devices.oilrig_cdu) do
                         GeneralUpdate_2({
                              type = 'oilrig_cdu',
                              citizenid = storage.citizenid,
                              metadata = storage.metadata
                         })
                    end
                    -- save blender data
                    for id, blender in pairs(self.devices.oilrig_blender) do
                         GeneralUpdate_2({
                              type = 'oilrig_blender',
                              citizenid = blender.citizenid,
                              metadata = blender.metadata
                         })
                    end
               end
          end
     end)
end

--- wipes all data
function GlobalScirptData:wipeALL()
     self.oil_well = {}
     self.devices = {
          oilrig_storage = {},
          oilrig_cdu = {},
          oilrig_blender = {},
     }
     self.oldTable = {}
end

function GlobalScirptData:getByHash(oilrig_hash)
     for key, value in pairs(self.oil_well) do
          if value.oilrig_hash == oilrig_hash then
               return value, key
          end
     end
     return false
end

function GlobalScirptData:read(id)
     return self.oil_well[id]
end

function GlobalScirptData:readAll()
     return self.oil_well
end

function GlobalScirptData:getDeviceById(Type, id)
     return self.devices[Type][id]
end

function GlobalScirptData:getDeviceByCitizenId(Type, citizenid)
     for key, value in pairs(self.devices[Type]) do
          if value.citizenid == citizenid then
               return value
          end
     end
     return false
end

----------------------
-- Data Manipulations
----------------------

function createMetadataTrackers(oil_wells, devices)
     CreateThread(function()
          while true do
               for key, oil_well in pairs(oil_wells) do
                    DataManipulations_metadata_oil_well(oil_well)
               end
               for key, CDU in pairs(devices.oilrig_cdu) do
                    DataManipulations_metadata_CDU(CDU)
               end
               for key, blender in pairs(devices.oilrig_blender) do
                    DataManipulations_metadata_blender(blender)
               end
               Wait(1000)
          end
     end)
end

local function cal_avg_octane(res)
     local avg = 0
     for key, Type in pairs(res) do
          avg = avg + Type.octane
     end
     return math.ceil((avg / 5) + 0.5)
end

function DataManipulations_metadata_blender(blender)
     if blender.metadata.state == false then
          return
     end

     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', blender.citizenid)

     if storage == false then
          -- failsafe
          local player = QBCore.Functions.GetPlayerByCitizenId(blender.citizenid)
          TriggerClientEvent('QBCore:Notify', player.PlayerData.source,
               "Fetal error could not coonect to your storage!", 'error')
          TriggerClientEvent('QBCore:Notify', player.PlayerData.source,
               "Fail-safe triggerd shuting down!", 'primary')
          blender.metadata.state = false
          return
     end

     if blender.metadata.heavy_naphtha <= 0.0 then
          blender.metadata.heavy_naphtha = 0.0
          blender.metadata.state = false
          return
     end
     -- blender.metadata.diesel
     -- blender.metadata.kerosene
     if blender.metadata.light_naphtha <= 0.0 then
          blender.metadata.light_naphtha = 0.0
          blender.metadata.state = false
          return
     end

     if blender.metadata.other_gases <= 0.0 then
          blender.metadata.other_gases = 0.0
          blender.metadata.state = false
          return
     end

     if blender.metadata.diesel <= 0.0 then
          blender.metadata.diesel = 0.0
          blender.metadata.state = false
          return
     end

     if blender.metadata.kerosene <= 0.0 then
          blender.metadata.kerosene = 0.0
          blender.metadata.state = false
          return
     end

     if not blender.metadata.recipe.diesel then
          blender.metadata.recipe.diesel = 0
     end
     if not blender.metadata.recipe.kerosene then
          blender.metadata.recipe.kerosene = 0
     end

     local res = {
          light_naphtha = BalanceRecipe:Blender(tonumber(blender.metadata.recipe.light_naphtha), 'light_naphtha'),
          heavy_naphtha = BalanceRecipe:Blender(tonumber(blender.metadata.recipe.heavy_naphtha), 'heavy_naphtha'),
          other_gases = BalanceRecipe:Blender(tonumber(blender.metadata.recipe.other_gases), 'other_gases'),
          --new elements
          diesel = BalanceRecipe:Blender(tonumber(blender.metadata.recipe.diesel), 'diesel'),
          kerosene = BalanceRecipe:Blender(tonumber(blender.metadata.recipe.kerosene), 'kerosene'),
     }
     blender.metadata.light_naphtha = blender.metadata.light_naphtha - res.light_naphtha.usage
     blender.metadata.heavy_naphtha = blender.metadata.heavy_naphtha - res.heavy_naphtha.usage
     blender.metadata.other_gases = blender.metadata.other_gases - res.other_gases.usage
     -- new elements
     blender.metadata.diesel = blender.metadata.diesel - res.diesel.usage
     blender.metadata.kerosene = blender.metadata.kerosene - res.kerosene.usage

     res.avg_octane = cal_avg_octane(res)
     storage.metadata.avg_gas_octane = math.ceil((storage.metadata.avg_gas_octane + res.avg_octane) / 2)
     storage.metadata.gasoline = Round(storage.metadata.gasoline + 0.75, 2)
end

function DataManipulations_metadata_CDU(CDU)
     if CDU.metadata.state == false then
          if CDU.metadata.temp > 0 then
               CDU.metadata.temp = CDU.metadata.temp - 15.0
          else
               CDU.metadata.temp = 0.0
          end
          return
     end

     -- increase temp until reach requestd temp
     if CDU.metadata.req_temp > CDU.metadata.temp then
          CDU.metadata.temp = CDU.metadata.temp + 15.0
     elseif CDU.metadata.req_temp == CDU.metadata.temp then
          CDU.metadata.temp = CDU.metadata.req_temp
     end

     -- a little bit of fun xd
     if CDU.metadata.temp >= 1000 then
          local player = QBCore.Functions.GetPlayerByCitizenId(CDU.citizenid)
          CDU.metadata.temp = 0
          CDU.metadata.state = false
          TriggerClientEvent('keep-oilwell:server_lib:AddExplosion', player.PlayerData.source, 'distillation')
          return
     end
     -- oil_storage > 1.0 min buffer
     -- CDU functions on current temp if we have something in oil_storage
     if CDU.metadata.oil_storage > 1.0 then
          -- get storage to export CDU products
          local blender = GlobalScirptData:getDeviceByCitizenId('oilrig_blender', CDU.citizenid)
          if blender == false then
               -- CUD's failsafe
               local player = QBCore.Functions.GetPlayerByCitizenId(CDU.citizenid)
               local source = player.PlayerData.source
               TriggerClientEvent('QBCore:Notify', source, "Fetal error could not coonect to your blender!", 'error')
               TriggerClientEvent('QBCore:Notify', source, "Fail-safe triggerd shuting down!", 'primary')
               CDU.metadata.state = false
               return
          end

          local multi, o_type = BalanceRecipe:CDU(CDU.metadata.temp)
          if multi and o_type then
               CDU.metadata.oil_storage = CDU.metadata.oil_storage - multi
               if blender.metadata[o_type] == nil then
                    blender.metadata[o_type] = 0
               end
               blender.metadata[o_type] = blender.metadata[o_type] + multi
          end
     end
end

function DataManipulations_metadata_oil_well(oil_well)
     local pumpOverHeat = 327
     local sotrage_size = Oilwell_config.Settings.size.oilwell_storage

     if oil_well.metadata.speed > 0 then
          oil_well.metadata.duration = oil_well.metadata.duration + 1
          oil_well.metadata.secduration = oil_well.metadata.duration
          if oil_well.metadata.temp ~= nil and pumpOverHeat >= oil_well.metadata.temp then
               local temp = oil_well.metadata.temp
               local speed = oil_well.metadata.speed
               oil_well.metadata.temp = Round(tempGrowth(temp, speed, 'increase', pumpOverHeat), 2)
          else
               oil_well.metadata.temp = pumpOverHeat
          end

          if oil_well.metadata.speed <= 0 then return end
          -- parts functions
          if oil_well.metadata.part_info.belt > 0 then
               local res = BalanceRecipe:SpeedRelated('OilwellBeltDegradation', oil_well.metadata.speed)
               oil_well.metadata.part_info.belt = Round((oil_well.metadata.part_info.belt - res), 2)
          elseif oil_well.metadata.part_info.belt <= 0 then
               oil_well.metadata.part_info.belt = 0
               oil_well.metadata.speed = 0
               TriggerClientEvent('keep-oilrig:client:syncSpeed', -1, oil_well.id, 0)
          end

          if oil_well.metadata.part_info.polish > 0 then
               local res = BalanceRecipe:SpeedRelated('OilwellPolishDegradation', oil_well.metadata.speed)
               oil_well.metadata.part_info.polish = Round((oil_well.metadata.part_info.polish - res), 2)
          elseif oil_well.metadata.part_info.polish <= 0 then
               oil_well.metadata.part_info.polish = 0
               oil_well.metadata.speed            = 0
               TriggerClientEvent('keep-oilrig:client:syncSpeed', -1, oil_well.id, 0)
          end

          if oil_well.metadata.part_info.clutch > 0 then
               local res = BalanceRecipe:SpeedRelated('OilwellClutchDegradation', oil_well.metadata.speed)
               oil_well.metadata.part_info.clutch = Round((oil_well.metadata.part_info.clutch - res), 2)
          elseif oil_well.metadata.part_info.clutch <= 0 then
               oil_well.metadata.part_info.clutch = 0
               oil_well.metadata.speed = 0
               TriggerClientEvent('keep-oilrig:client:syncSpeed', -1, oil_well.id, 0)
          end

          -- skip player oil if player one part is 0
          if oil_well.metadata.part_info.clutch == 0 or oil_well.metadata.part_info.polish == 0 or
              oil_well.metadata.part_info.belt == 0 then
               return
          end
          if oil_well.metadata.temp > 0 and oil_well.metadata.temp < pumpOverHeat and
              oil_well.metadata.oil_storage <= sotrage_size then
               local res = BalanceRecipe:SpeedRelated('OilwellProdoction', oil_well.metadata.speed)
               oil_well.metadata.oil_storage = oil_well.metadata.oil_storage + res
          end
     else
          -- reset duration
          oil_well.metadata.duration = 0
          -- start cooling procces
          if oil_well.metadata.secduration > 0 then
               local temp = oil_well.metadata.temp
               local speed = oil_well.metadata.speed
               oil_well.metadata.secduration = oil_well.metadata.secduration - 1
               oil_well.metadata.temp = Round(tempGrowth(temp, speed, 'decrease', pumpOverHeat), 2)
          elseif oil_well.metadata.secduration == 0 then
               oil_well.metadata.temp = 0
          end

          if oil_well.metadata.secduration > 0 and oil_well.metadata.temp == 0 then
               oil_well.metadata.secduration = 0
          end
     end
end

-- Storage
SendOilToStorage = function(oilrig, player, src, cb)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })
          TriggerClientEvent('QBCore:Notify', src, "Could not connect to your stroage try again!", 'error')
          cb(false)
          return
     end
     -- add to storage
     storage.metadata.crudeOil = Round(storage.metadata.crudeOil + oilrig.metadata.oil_storage, 2)
     TriggerClientEvent('QBCore:Notify', src, oilrig.metadata.oil_storage .. " Gallon of Curde Oil pumped to storage")
     -- remove from oilwell
     oilrig.metadata.oil_storage = 0.0
     cb(true)
end

SendOilFuelToStorage = function(player, src, cb)
     local citizenid = player.PlayerData.citizenid
     local blender = GlobalScirptData:getDeviceByCitizenId('oilrig_blender', citizenid)
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)

     if storage == false then
          InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })
          TriggerClientEvent('QBCore:Notify', src, "Could not connect to your stroage try again!", 'error')
          cb(false)
          return
     end

     if not blender then
          TriggerClientEvent('QBCore:Notify', src, "Could not connect to your blender try again!", 'error')
          cb(false)
          return
     end

     if not storage.metadata.fuel_oil then
          storage.metadata.fuel_oil = 0
     end

     if not blender.metadata.fuel_oil then
          blender.metadata.fuel_oil = 0
     end

     if blender.metadata.fuel_oil == 0 then
          TriggerClientEvent('QBCore:Notify', src, "You don't have any fuel oil!", 'error')
          return
     end
     -- add to storage
     storage.metadata.fuel_oil = Round((storage.metadata.fuel_oil + blender.metadata.fuel_oil), 2)
     TriggerClientEvent('QBCore:Notify', src, blender.metadata.fuel_oil .. " Gallon of fuel oil pumped to storage")
     -- remove from oilwell
     blender.metadata.fuel_oil = 0.0
     cb(true)
end

InitStorage = function(o, cb)
     local sqlQuery = 'INSERT INTO oilrig_storage (citizenid,name,metadata) VALUES (?,?,?)'
     local metadata = {
          queue = {},
          avg_gas_octane = 0,
          gasoline = 0.0,
          crudeOil = 0.0
     }

     MySQL.Async.fetchAll('SELECT * FROM oilrig_storage WHERE citizenid = ?', { o.citizenid }, function(res)
          if next(res) then cb(false) return false end

          local QueryData = {
               o.citizenid,
               o.name,
               json.encode(metadata),
          }
          res = MySQL.Sync.insert(sqlQuery, QueryData)
          if res ~= 0 then
               -- inject into runtime
               GlobalScirptData:newDevice({
                    id = res,
                    citizenid = o.citizenid,
                    name = o.name,
                    metadata = json.encode(metadata)
               }, 'oilrig_storage')

               if cb then
                    cb(GlobalScirptData:getDeviceByCitizenId('oilrig_storage', o.citizenid))
               end
               return true
          end
          cb(false)
          return false
     end)
end
-- End Storage

-- CDU

Init_CDU = function(citizenid, cb)
     local sqlQuery = 'INSERT INTO oilrig_cdu (citizenid,metadata) VALUES (?,?)'
     local metadata = {
          temp = 0.0,
          req_temp = 0.0,
          state = false,
          oil_storage = 0.0
     }

     MySQL.Async.fetchAll('SELECT * FROM oilrig_cdu WHERE citizenid = ?', { citizenid }, function(res)
          if next(res) then cb(false) return end
          local QueryData = { citizenid, json.encode(metadata) }
          res = MySQL.Sync.insert(sqlQuery, QueryData)
          if res ~= 0 then
               -- inject into runtime
               GlobalScirptData:newDevice({
                    id = res,
                    citizenid = citizenid,
                    metadata = json.encode(metadata)
               }, 'oilrig_cdu')
               cb(GlobalScirptData:getDeviceByCitizenId('oilrig_cdu', citizenid))
               return
          end
          cb(false)
     end)
end

-- End CDU

-- Blender

Init_Blender = function(citizenid, cb)
     local sqlQuery = 'INSERT INTO oilrig_blender (citizenid,metadata) VALUES (?,?)'
     local metadata = {
          heavy_naphtha = 0.0,
          light_naphtha = 0.0,
          other_gases = 0.0,
          state = false,
          recipe = {
               heavy_naphtha = 0.0,
               light_naphtha = 0.0,
               other_gases = 0.0,
          }
     }
     MySQL.Async.fetchAll('SELECT * FROM oilrig_blender WHERE citizenid = ?', { citizenid }, function(res)
          if next(res) then cb(false) end

          local QueryData = {
               citizenid,
               json.encode(metadata),
          }
          res = MySQL.Sync.insert(sqlQuery, QueryData)

          if res ~= 0 then
               -- inject into runtime
               GlobalScirptData:newDevice({
                    id = res,
                    citizenid = citizenid,
                    metadata = json.encode(metadata)
               }, 'oilrig_blender')
               cb(GlobalScirptData:getDeviceByCitizenId('oilrig_blender', citizenid))
               return
          end
          cb(false)
     end)
end

-- End Blender
--------------------
-- DATABASE WRAPPER
--------------------
function InitilaizeAllDataByDatabaseValues_2()
     local oil_well = MySQL.Sync.fetchAll('SELECT * FROM oilrig_position', {})
     local oilrig_storage = MySQL.Sync.fetchAll('SELECT * FROM oilrig_storage', {})
     local oilrig_cdu = MySQL.Sync.fetchAll('SELECT * FROM oilrig_cdu', {})
     local oilrig_blender = MySQL.Sync.fetchAll('SELECT * FROM oilrig_blender', {})
     GlobalScirptData:initPhaseTwo({
          oil_well = oil_well,
          oilrig_storage = oilrig_storage,
          oilrig_cdu = oilrig_cdu,
          oilrig_blender = oilrig_blender
     })
end

function GeneralUpdate_2(options)
     if options.type == nil then return end
     local sqlQuery = ''
     local QueryData = {}
     for key, value in pairs(options.metadata) do
          if type(value) == "number" then
               options.metadata[key] = Round(value, 2)
          end
     end
     if options.type == 'oilrig_storage' or options.type == 'oilrig_cdu' or options.type == 'oilrig_blender' then
          sqlQuery = 'UPDATE ' .. options.type .. ' SET metadata = ? WHERE citizenid = ? AND metadata <> ?'
          QueryData = {
               json.encode(options.metadata), -- check if data is cahnged
               options.citizenid,
               json.encode(options.metadata) -- check if data is cahnged
          }
     elseif options.type == 'oilrig_oilwell' then
          sqlQuery = 'UPDATE oilrig_position SET metadata = ? WHERE citizenid = ? AND oilrig_hash = ? AND metadata <> ?'
          QueryData = {
               json.encode(options.metadata), -- check if data is cahnged
               options.citizenid,
               options.oilrig_hash,
               json.encode(options.metadata) -- check if data is cahnged
          }
     end
     MySQL.Async.execute(sqlQuery, QueryData, function(e)
     end)
end
