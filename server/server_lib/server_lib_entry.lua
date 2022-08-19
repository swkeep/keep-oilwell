BalanceRecipe = {}

function GeneralInsert(options)
     local sqlQuery = 'INSERT INTO oilrig_position (citizenid,name,oilrig_hash,position,metadata,state) VALUES (?,?,?,?,?,?)'
     local QueryData = {
          options.citizenid,
          options.name,
          options.oilrig_hash,
          json.encode(options.position),
          json.encode(options.metadata),
          options.state
     }
     return MySQL.Sync.insert(sqlQuery, QueryData)
end

function isTableChanged(oldTable, newTable)
     if equals(oldTable, newTable, true) == false then
          return true
     else
          return false
     end
end

function equals(o1, o2, ignore_mt)
     if o1 == o2 then return true end
     local o1Type = type(o1)
     local o2Type = type(o2)
     if o1Type ~= o2Type then return false end
     if o1Type ~= 'table' then return false end

     if not ignore_mt then
          local mt1 = getmetatable(o1)
          if mt1 and mt1.__eq then
               --compare using built in method
               return o1 == o2
          end
     end

     local keySet = {}

     for key1, value1 in pairs(o1) do
          local value2 = o2[key1]
          if value2 == nil or equals(value1, value2, ignore_mt) == false then
               return false
          end
          keySet[key1] = true
     end

     for key2, _ in pairs(o2) do
          if not keySet[key2] then return false end
     end
     return true
end

function deepcopy(orig, copies)
     copies = copies or {}
     local orig_type = type(orig)
     local copy
     if orig_type == 'table' then
          if copies[orig] then
               copy = copies[orig]
          else
               copy = {}
               copies[orig] = copy
               for orig_key, orig_value in next, orig, nil do
                    copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
               end
               setmetatable(copy, deepcopy(getmetatable(orig), copies))
          end
     else -- number, string, boolean, etc
          copy = orig
     end
     return copy
end

local function inRange(x, min, max)
     return (x >= min and x <= max)
end

local function getCurrentSpeed_maxTemp(speed)
     if inRange(speed, 0, 10) then return 75
     elseif inRange(speed, 10, 20) then return 100
     elseif inRange(speed, 30, 40) then return 125
     elseif inRange(speed, 40, 50) then return 170
     elseif inRange(speed, 50, 60) then return 215
     elseif inRange(speed, 60, 70) then return 260
     elseif inRange(speed, 70, 80) then return 305
     elseif inRange(speed, 80, 100) then return 327
     else return 0
     end
end

local function isOverHeatTemp(temp, max)
     return (temp >= max)
end

function GetSpeedProdoctionMulti(speed)
     local logic = {
          [1] = { range = { 0, 10 }, multi = 0.02 },
          [2] = { range = { 10, 20 }, multi = 0.03 },
          [3] = { range = { 20, 30 }, multi = 0.04 },
          [4] = { range = { 30, 40 }, multi = 0.05 },
          [5] = { range = { 40, 50 }, multi = 0.06 },
          [6] = { range = { 50, 60 }, multi = 0.07 },
          [7] = { range = { 60, 70 }, multi = 0.08 },
          [8] = { range = { 70, 80 }, multi = 0.09 },
          [9] = { range = { 80, 90 }, multi = 0.1 },
          [10] = { range = { 90, 100 }, multi = 0.12 },
     }
     for key, value in pairs(logic) do
          if inRange(speed, value.range[1], value.range[2]) then
               return value.multi
          end
     end
     return 0
end

function GetSpeed_degradationMulti(speed)
     local logic = {
          [1] = { range = { 0, 10 }, multi = 0.025 },
          [2] = { range = { 10, 20 }, multi = 0.03 },
          [3] = { range = { 20, 30 }, multi = 0.035 },
          [4] = { range = { 30, 40 }, multi = 0.040 },
          [5] = { range = { 40, 50 }, multi = 0.045 },
          [6] = { range = { 50, 60 }, multi = 0.050 },
          [7] = { range = { 60, 70 }, multi = 0.055 },
          [8] = { range = { 70, 80 }, multi = 0.06 },
          [9] = { range = { 80, 90 }, multi = 0.068 },
          [10] = { range = { 90, 100 }, multi = 0.075 },
     }
     for key, value in pairs(logic) do
          if inRange(speed, value.range[1], value.range[2]) then
               return value.multi
          end
     end
     return 0
end

function BalanceRecipe:SpeedRelated(type, condition)
     local data = {
          ['OilwellTemperatureGrowth'] = {
               [1] = { range = { 0, 10 }, multi = 0.02 },
               [2] = { range = { 10, 20 }, multi = 0.03 },
               [3] = { range = { 20, 30 }, multi = 0.04 },
               [4] = { range = { 30, 40 }, multi = 0.05 },
               [5] = { range = { 40, 50 }, multi = 0.06 },
               [6] = { range = { 50, 60 }, multi = 0.07 },
               [7] = { range = { 60, 70 }, multi = 0.08 },
               [8] = { range = { 70, 80 }, multi = 0.09 },
               [9] = { range = { 80, 90 }, multi = 0.1 },
               [10] = { range = { 90, 100 }, multi = 0.12 },
          },
          ['OilwellProdoction'] = {
               [1] = { range = { 0, 10 }, multi = 0.02 },
               [2] = { range = { 10, 20 }, multi = 0.03 },
               [3] = { range = { 20, 30 }, multi = 0.04 },
               [4] = { range = { 30, 40 }, multi = 0.05 },
               [5] = { range = { 40, 50 }, multi = 0.06 },
               [6] = { range = { 50, 60 }, multi = 0.07 },
               [7] = { range = { 60, 70 }, multi = 0.08 },
               [8] = { range = { 70, 80 }, multi = 0.09 },
               [9] = { range = { 80, 90 }, multi = 0.1 },
               [10] = { range = { 90, 100 }, multi = 0.12 },
          },
          ['OilwellClutchDegradation'] = {
               [1] = { range = { 0, 10 }, multi = 0.025 },
               [2] = { range = { 10, 20 }, multi = 0.03 },
               [3] = { range = { 20, 30 }, multi = 0.035 },
               [4] = { range = { 30, 40 }, multi = 0.040 },
               [5] = { range = { 40, 50 }, multi = 0.045 },
               [6] = { range = { 50, 60 }, multi = 0.050 },
               [7] = { range = { 60, 70 }, multi = 0.055 },
               [8] = { range = { 70, 80 }, multi = 0.06 },
               [9] = { range = { 80, 90 }, multi = 0.065 },
               [10] = { range = { 90, 100 }, multi = 0.07 },
          },
          ['OilwellPolishDegradation'] = {
               [1] = { range = { 0, 10 }, multi = 0.02 },
               [2] = { range = { 10, 20 }, multi = 0.025 },
               [3] = { range = { 20, 30 }, multi = 0.03 },
               [4] = { range = { 30, 40 }, multi = 0.035 },
               [5] = { range = { 40, 50 }, multi = 0.04 },
               [6] = { range = { 50, 60 }, multi = 0.045 },
               [7] = { range = { 60, 70 }, multi = 0.05 },
               [8] = { range = { 70, 80 }, multi = 0.055 },
               [9] = { range = { 80, 90 }, multi = 0.060 },
               [10] = { range = { 90, 100 }, multi = 0.065 },
          },
          ['OilwellBeltDegradation'] = {
               [1] = { range = { 0, 10 }, multi = 0.025 },
               [2] = { range = { 10, 20 }, multi = 0.03 },
               [3] = { range = { 20, 30 }, multi = 0.035 },
               [4] = { range = { 30, 40 }, multi = 0.040 },
               [5] = { range = { 40, 50 }, multi = 0.045 },
               [6] = { range = { 50, 60 }, multi = 0.050 },
               [7] = { range = { 60, 70 }, multi = 0.055 },
               [8] = { range = { 70, 80 }, multi = 0.06 },
               [9] = { range = { 80, 90 }, multi = 0.065 },
               [10] = { range = { 90, 100 }, multi = 0.07 },
          },
     }

     for key, value in pairs(data[type]) do
          if inRange(condition, value.range[1], value.range[2]) then
               return value.multi
          end
     end
     return 0
end

function BalanceRecipe:CDU(condition)
     local data = {
          [1] = { range = { 20, 50 }, multi = 0.65, o_type = 'other_gases' },
          [2] = { range = { 50, 100 }, multi = 0.3, o_type = 'light_naphtha' },
          [3] = { range = { 100, 150 }, multi = 0.5, o_type = 'light_naphtha' },
          [4] = { range = { 150, 175 }, multi = 0.2, o_type = 'kerosene' },
          [5] = { range = { 175, 200 }, multi = 0.25, o_type = 'heavy_naphtha' },
          [6] = { range = { 200, 230 }, multi = 0.3, o_type = 'heavy_naphtha' },
          [7] = { range = { 230, 260 }, multi = 0.35, o_type = 'diesel' },
          [8] = { range = { 260, 30 }, multi = 0.4, o_type = 'diesel' },
          [9] = { range = { 300, 600 }, multi = 0.8, o_type = 'fuel_oil' },
     }

     for key, value in pairs(data) do
          if inRange(condition, value.range[1], value.range[2]) then
               return value.multi, value.o_type
          end
     end
     return 0, 'other_gases'
end

function BalanceRecipe:Blender(condition, Type)
     local data = {
          ['other_gases'] = {
               [1] = { range = { 0, 10 }, octane = 93, usage = 0.1 },
               [2] = { range = { 10, 20 }, octane = 91, usage = 0.2 },
               [3] = { range = { 20, 25 }, octane = 89, usage = 0.25 },
          },
          ['kerosene'] = {
               [1] = { range = { 5, 10 }, octane = 89, usage = 0.1 },
               [2] = { range = { 10, 15 }, octane = 91, usage = 0.15 },
               [3] = { range = { 15, 25 }, octane = 93, usage = 0.25 },
          },
          ['diesel'] = {
               [1] = { range = { 0, 0 }, octane = 93, usage = 0.0 },
               [2] = { range = { 10, 20 }, octane = 91, usage = 0.25 },
               [3] = { range = { 15, 25 }, octane = 89, usage = 0.35 },
          },
          ['light_naphtha'] = {
               [1] = { range = { 10, 20 }, octane = 89, usage = 0.06 },
               [2] = { range = { 20, 40 }, octane = 91, usage = 0.16 },
               [3] = { range = { 40, 60 }, octane = 93, usage = 0.39 },
          },
          ['heavy_naphtha'] = {
               [1] = { range = { 80, 60 }, octane = 93, usage = 0.24 },
               [2] = { range = { 60, 40 }, octane = 91, usage = 0.24 },
               [3] = { range = { 40, 0 }, octane = 89, usage = 0.26 },
          },
     }

     for key, value in pairs(data[Type]) do
          if inRange(condition, value.range[1], value.range[2]) then
               return { octane = value.octane, usage = value.usage }
          end
     end
     return { octane = 87, usage = 0.4 }
end

function tempGrowth(tmp, speed, Type, max)
     if tmp == nil then return 0 end

     if Type == 'increase' then
          if isOverHeatTemp(tmp, max) then return tmp end

          if inRange(speed, 0, 100) then
               local max_temp = getCurrentSpeed_maxTemp(speed)
               tmp = tmp + BalanceRecipe:SpeedRelated('OilwellTemperatureGrowth', speed)
               if tmp >= max_temp then
                    tmp = max_temp
               end
               return tmp
          else
               return 0
          end
          return 0
     end
     -- decrease
     if tmp > 0 then
          tmp = tmp - 10
     else
          tmp = 0
     end
     return tmp
end
