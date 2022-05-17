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

local rest = {
     description = 'Oil Barrel',
     unique = true,
     name = 'oilbarell',
     image = 'oilBarrel.png',
     weight = 1000,
     slot = 1,
     label = 'Oil barell',
     info = {
          gal = 169.85
     },
     amount = 1,
     shouldClose = true,
     useable = false, type = 'item' }

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
