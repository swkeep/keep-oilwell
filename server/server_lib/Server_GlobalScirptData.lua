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

function DataManipulations_metadata_blender(blender)
     if blender.metadata.state == false then
          return
     end

     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', blender.citizenid)

     if blender.metadata.heavy_naphtha <= 0.0 then
          blender.metadata.heavy_naphtha = 0.0
          blender.metadata.state = false
          return
     end

     if blender.metadata.light_naphtha <= 0.0 then
          blender.metadata.heavy_naphtha = 0.0
          blender.metadata.state = false
          return
     end

     if blender.metadata.other_gases <= 0.0 then
          blender.metadata.other_gases = 0.0
          blender.metadata.state = false
          return
     end
     local res = 0

     blender.metadata.heavy_naphtha = blender.metadata.heavy_naphtha - 0.5
     blender.metadata.light_naphtha = blender.metadata.light_naphtha - 0.4
     blender.metadata.other_gases = blender.metadata.other_gases - 0.9

     if blender.metadata.recipe.heavy_naphtha ~= 28.0 then
          res = res + 0.2
     else
          res = res + 0.1
     end

     if blender.metadata.recipe.light_naphtha ~= 36.0 then
          res = res + 0.5
     else
          res = res + 0.4
     end

     if blender.metadata.recipe.other_gases ~= 36.0 then
          res = res + 0.5
     else
          res = res + 0.4
     end
     storage.metadata.gasoline = storage.metadata.gasoline + res
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

     -- oil_storage > 1.0 min buffer
     -- CDU functions on current temp if we have something in oil_storage
     if CDU.metadata.oil_storage > 1.0 then
          -- get storage to export CDU products
          local blender = GlobalScirptData:getDeviceByCitizenId('oilrig_blender', CDU.citizenid)

          if CDU.metadata.temp < 20.0 and CDU.metadata.temp > 0.0 then
               CDU.metadata.oil_storage = CDU.metadata.oil_storage - 0.5
          elseif CDU.metadata.temp < 150.0 and CDU.metadata.temp > 20.0 then
               -- Butane & Propane
               -- other gases
               CDU.metadata.oil_storage = CDU.metadata.oil_storage - 0.5
               blender.metadata.other_gases = blender.metadata.other_gases + 0.75
          elseif CDU.metadata.temp < 200.0 and CDU.metadata.temp > 150.0 then
               -- Petrol
               CDU.metadata.oil_storage = CDU.metadata.oil_storage - 0.75
               blender.metadata.light_naphtha = blender.metadata.light_naphtha + 1.5
          elseif CDU.metadata.temp < 300.0 and CDU.metadata.temp > 200.0 then
               -- Diesel
               CDU.metadata.oil_storage = CDU.metadata.oil_storage - 0.75
               blender.metadata.light_naphtha = blender.metadata.light_naphtha + 1.0
          elseif CDU.metadata.temp < 370.0 and CDU.metadata.temp > 300.0 then
               -- Fuel Oil
               CDU.metadata.oil_storage = CDU.metadata.oil_storage - 0.75
               blender.metadata.heavy_naphtha = blender.metadata.heavy_naphtha + 1.0
          elseif CDU.metadata.temp < 400.0 and CDU.metadata.temp > 370.0 then
               -- Lubricating oil, Parrafin Wax, Asphalt
               CDU.metadata.oil_storage = CDU.metadata.oil_storage - 0.75
               blender.metadata.heavy_naphtha = blender.metadata.heavy_naphtha + 0.5
          end
     end
end

function DataManipulations_metadata_oil_well(oil_well)
     local pumpOverHeat = 327

     if oil_well.metadata.speed ~= 0 then
          oil_well.metadata.duration = oil_well.metadata.duration + 1
          oil_well.metadata.secduration = oil_well.metadata.duration
          if oil_well.metadata.temp ~= nil and pumpOverHeat >= oil_well.metadata.temp then
               oil_well.metadata.temp = tempGrowth(oil_well.metadata.temp, oil_well.metadata.speed, 'increase', pumpOverHeat)
               oil_well.metadata.temp = Round(oil_well.metadata.temp, 2)
          else
               oil_well.metadata.temp = pumpOverHeat
          end
          if oil_well.metadata.temp > 50 and oil_well.metadata.temp < (pumpOverHeat - 25) and oil_well.metadata.oil_storage <= 300 then
               oil_well.metadata.oil_storage = oil_well.metadata.oil_storage + (0.1 * (oil_well.metadata.speed / 50))
          end
     else
          -- reset duration
          if oil_well.metadata.duration ~= 0 then
               oil_well.metadata.duration = 0
          end
          -- start cooling procces
          if oil_well.metadata.secduration > 0 then
               oil_well.metadata.secduration = oil_well.metadata.secduration - 1
               oil_well.metadata.temp = tempGrowth(oil_well.metadata.temp, oil_well.metadata.speed, 'decrease', pumpOverHeat)
               oil_well.metadata.temp = Round(oil_well.metadata.temp, 2)
          elseif oil_well.metadata.secduration == 0 then
               oil_well.metadata.temp = 0
          end

          if oil_well.metadata.secduration > 0 and oil_well.metadata.temp == 0 then
               oil_well.metadata.secduration = 0
          end
     end
end

-- Storage
SendOilToStorage = function(oilrig, player)
     local citizenid = player.PlayerData.citizenid
     local storage = GlobalScirptData:getDeviceByCitizenId('oilrig_storage', citizenid)
     if storage == false then
          local state = InitStorage({
               citizenid = citizenid,
               name = player.PlayerData.name .. "'s storage",
          })
          if state == false then
               return false
          end
     end
     -- add to storage
     storage.metadata.crudeOil = Round(storage.metadata.crudeOil + oilrig.metadata.oil_storage, 2)
     -- remove from oilwell
     oilrig.metadata.oil_storage = 0.0
     return true
end

InitStorage = function(o)
     local sqlQuery = 'INSERT INTO oilrig_storage (citizenid,name,metadata) VALUES (?,?,?)'
     local metadata = {
          queue = {},
          avg_gas_octane = 0,
          gasoline = 0.0,
          crudeOil = 0.0
     }
     local QueryData = {
          o.citizenid,
          o.name,
          json.encode(metadata),
     }
     local res = MySQL.Sync.insert(sqlQuery, QueryData)
     if res ~= 0 then
          -- inject into runtime
          GlobalScirptData:newDevice({
               id = res,
               citizenid = o.citizenid,
               name = o.name,
               metadata = json.encode(metadata)
          }, 'oilrig_storage')
          return true
     end
     return false
end
-- End Storage

-- CDU
Init_CDU = function(o)
     local sqlQuery = 'INSERT INTO oilrig_cdu (citizenid,metadata) VALUES (?,?)'
     local metadata = {
          temp = 0.0,
          req_temp = 0.0,
          state = false,
          oil_storage = 0.0
     }
     local QueryData = {
          o.citizenid,
          json.encode(metadata),
     }
     local res = MySQL.Sync.insert(sqlQuery, QueryData)
     if res ~= 0 then
          -- inject into runtime
          GlobalScirptData:newDevice({
               id = res,
               citizenid = o.citizenid,
               metadata = json.encode(metadata)
          }, 'oilrig_cdu')
          return true
     end
     return false
end

-- End CDU

-- Blender

Init_Blender = function(o)
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
     local QueryData = {
          o.citizenid,
          json.encode(metadata),
     }
     local res = MySQL.Sync.insert(sqlQuery, QueryData)
     if res ~= 0 then
          -- inject into runtime
          GlobalScirptData:newDevice({
               id = res,
               citizenid = o.citizenid,
               metadata = json.encode(metadata)
          }, 'oilrig_blender')
          return true
     end
     return false
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
     if options.type == nil then
          return
     end
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
               json.encode(options.metadata),
               options.citizenid,
               json.encode(options.metadata)
          }
     elseif options.type == 'oilrig_oilwell' then
          sqlQuery = 'UPDATE oilrig_position SET metadata = ? WHERE citizenid = ? AND oilrig_hash = ? AND metadata <> ?'
          QueryData = {
               json.encode(options.metadata),
               options.citizenid,
               options.oilrig_hash,
               json.encode(options.metadata)
          }
     end
     MySQL.Async.execute(sqlQuery, QueryData, function(e)
     end)
end
