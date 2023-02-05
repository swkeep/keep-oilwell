local QBCore = exports['qb-core']:GetCoreObject()

local function showblender(data)
     local state = ''
     local start_btn = 'Start'
     local start_icon = 'fa-solid fa-square-caret-right'
     if type(data) == "table" and data.metadata.state == false then
          state = 'Inactive'
          start_btn = 'Start'
          start_icon = 'fa-solid fa-square-caret-right'
     else
          state = 'Active'
          start_btn = 'Stop'
          start_icon = "fa-solid fa-circle-stop"
     end

     local header = "Blender unit (" .. state .. ')'
     -- header
     local heavy_naphtha = data.metadata.heavy_naphtha
     local light_naphtha = data.metadata.light_naphtha
     local other_gases = data.metadata.other_gases
     -- new elements
     local diesel = data.metadata.diesel
     local kerosene = data.metadata.kerosene
     local fuel_oil = data.metadata.fuel_oil

     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-blender'
          }, {
               header = 'Heavy Naphtha',
               icon = 'fa-solid fa-circle',
               txt = heavy_naphtha .. " Gallons",
               disabled = true
          },
          {
               header = 'Light Naphtha',
               icon = 'fa-solid fa-circle',
               txt = light_naphtha .. " Gallons",
               disabled = true
          },
          {
               header = 'Other Gases',
               icon = 'fa-solid fa-circle',
               txt = other_gases .. " Gallons",
               disabled = true
          },
     }
     -- new elements
     if diesel then
          openMenu[#openMenu + 1] = {
               header = 'Diesel',
               icon = 'fa-solid fa-circle',
               txt = diesel .. " Gallons",
               disabled = true
          }
     end

     if kerosene then
          openMenu[#openMenu + 1] = {
               header = 'Kerosene',
               icon = 'fa-solid fa-circle',
               txt = kerosene .. " Gallons",
               disabled = true
          }
     end

     if fuel_oil then
          openMenu[#openMenu + 1] = {
               header = 'Fuel oil',
               icon = 'fa-solid fa-circle',
               txt = fuel_oil .. " Gallons (no use in blending process)",
               disabled = true
          }
     end

     openMenu[#openMenu + 1] = {
          header = 'Change Recipe',
          icon = 'fa-solid fa-scroll',
          params = {
               event = "keep-oilrig:blender_menu:recipe_blender"
          }
     }

     openMenu[#openMenu + 1] = {
          header = start_btn .. ' Blending',
          icon = start_icon,
          params = {
               event = "keep-oilrig:blender_menu:toggle_blender"
          }
     }

     openMenu[#openMenu + 1] = {
          header = 'Pump Fuel-Oil to Storage',
          icon = 'fa-solid fa-arrows-spin',
          params = {
               event = "keep-oilrig:blender_menu:pump_fueloil"
          }
     }

     openMenu[#openMenu + 1] = {
          header = 'leave',
          icon = 'fa-solid fa-circle-xmark',
          params = {
               event = "qb-menu:closeMenu"
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end

AddEventHandler('keep-oilrig:blender_menu:pump_fueloil', function()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:pump_fueloil', function(result)
          showblender(result)
     end)
end)

AddEventHandler('keep-oilrig:blender_menu:ShowBlender', function()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:ShowBlender', function(result)
          showblender(result)
     end)
end)

AddEventHandler('keep-oilrig:blender_menu:toggle_blender', function()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:toggle_blender', function(result)
          showblender(result)
     end)
end)

local function inRange(x, min, max)
     return (x >= min and x <= max)
end

AddEventHandler('keep-oilrig:blender_menu:recipe_blender', function()
     local inputData = exports['qb-input']:ShowInput({
          header = "Pump crude oil to CDU",
          submitText = "Enter",
          inputs = {
               {
                    type = 'number',
                    isRequired = true,
                    name = 'heavy_naphtha',
                    text = "Heavy Naphtha"
               },
               {
                    type = 'number',
                    isRequired = true,
                    name = 'light_naphtha',
                    text = "Light Naphtha"
               },
               {
                    type = 'number',
                    isRequired = true,
                    name = 'other_gases',
                    text = "Other Gases"
               },
               -- new elements

               {
                    type = 'number',
                    isRequired = true,
                    name = 'diesel',
                    text = "Diesel"
               },

               {
                    type = 'number',
                    isRequired = true,
                    name = 'kerosene',
                    text = "Kerosene"
               },
          }
     })
     if inputData then
          if not
              (
              inputData.heavy_naphtha
                  and inputData.light_naphtha
                  and inputData.other_gases
                  and inputData.diesel
                  and inputData.kerosene
              ) then
               return
          end

          for _, value in pairs(inputData) do
               if not inRange(tonumber(value), 0, 100) then
                    QBCore.Functions.Notify('numbers must be between 0-100', "primary")
                    return
               end
          end

          QBCore.Functions.TriggerCallback('keep-oilrig:server:recipe_blender', function(result)
               showblender(result)
          end, inputData)
     end
end)
