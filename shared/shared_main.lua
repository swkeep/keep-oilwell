function RandomHash(length)
     local res = ""
     for i = 1, length do
          res = res .. string.char(math.random(97, 122))
     end
     return res
end

---print tables : debug
---@param node table
function print_table(node)
     local cache, stack, output = {}, {}, {}
     local depth = 1
     local output_str = "{\n"

     while true do
          local size = 0
          for k, v in pairs(node) do
               size = size + 1
          end

          local cur_index = 1
          for k, v in pairs(node) do
               if (cache[node] == nil) or (cur_index >= cache[node]) then

                    if (string.find(output_str, "}", output_str:len())) then
                         output_str = output_str .. ",\n"
                    elseif not (string.find(output_str, "\n", output_str:len())) then
                         output_str = output_str .. "\n"
                    end

                    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                    table.insert(output, output_str)
                    output_str = ""

                    local key
                    if (type(k) == "number" or type(k) == "boolean") then
                         key = "[" .. tostring(k) .. "]"
                    else
                         key = "['" .. tostring(k) .. "']"
                    end

                    if (type(v) == "number" or type(v) == "boolean") then
                         output_str = output_str .. string.rep('\t', depth) .. key .. " = " .. tostring(v)
                    elseif (type(v) == "table") then
                         output_str = output_str .. string.rep('\t', depth) .. key .. " = {\n"
                         table.insert(stack, node)
                         table.insert(stack, v)
                         cache[node] = cur_index + 1
                         break
                    else
                         output_str = output_str .. string.rep('\t', depth) .. key .. " = '" .. tostring(v) .. "'"
                    end

                    if (cur_index == size) then
                         output_str = output_str .. "\n" .. string.rep('\t', depth - 1) .. "}"
                    else
                         output_str = output_str .. ","
                    end
               else
                    -- close the table
                    if (cur_index == size) then
                         output_str = output_str .. "\n" .. string.rep('\t', depth - 1) .. "}"
                    end
               end

               cur_index = cur_index + 1
          end

          if (size == 0) then
               output_str = output_str .. "\n" .. string.rep('\t', depth - 1) .. "}"
          end

          if (#stack > 0) then
               node = stack[#stack]
               stack[#stack] = nil
               depth = cache[node] == nil and depth + 1 or depth - 1
          else
               break
          end
     end

     -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
     table.insert(output, output_str)
     output_str = table.concat(output)

     print(output_str)
end

function Round(num, dp)
     --[[
     round a number to so-many decimal of places, which can be negative, 
     e.g. -1 places rounds to 10's,  
     
     examples
         173.2562 rounded to 0 dps is 173.0
         173.2562 rounded to 2 dps is 173.26
         173.2562 rounded to -1 dps is 170.0
     ]] --
     local mult = 10 ^ (dp or 0)
     return math.floor(num * mult + 0.5) / mult
end

function Tablelength(T)
     local count = 0
     for _ in pairs(T) do count = count + 1 end
     return count
end

Colors = {
     red = "\027[31m",
     green = "\027[32m",
     orange = "\027[33m",
     cyan = "\027[36m",
     gray = "\027[90m",
     grey = "\027[90m",
     light_green = "\027[92m",
     yellow = "\027[93m",
     blue = "\027[94m",
}
