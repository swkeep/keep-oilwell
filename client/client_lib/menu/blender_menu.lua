local QBCore = exports['qb-core']:GetCoreObject()

local function showblender(data)
     local state = ''
     if data.metadata.state == false then
          state = 'Inactive'
     else
          state = 'Active'
     end

     local header = "Blender unit (" .. state .. ')'
     -- header
     local heavy_naphtha = data.metadata.heavy_naphtha
     local light_naphtha = data.metadata.light_naphtha
     local other_gases = data.metadata.other_gases

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
          {
               header = 'Change Recipe',
               icon = 'fa-solid fa-scroll',
               params = {
                    event = "keep-oilrig:blender_menu:recipe_blender"
               }
          },
          {
               header = 'Start Blending',
               icon = 'fa-solid fa-arrows-spin',
               params = {
                    event = "keep-oilrig:blender_menu:toggle_blender"
               }
          },
          {
               header = 'leave',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

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
          }
     })
     if inputData then
          if not inputData.heavy_naphtha and not inputData.light_naphtha and not inputData.other_gases then
               return
          end
          QBCore.Functions.TriggerCallback('keep-oilrig:server:recipe_blender', function(result)
               showblender(result)
          end, inputData)
     end
end)
