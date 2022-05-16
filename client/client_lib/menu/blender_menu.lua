local QBCore = exports['qb-core']:GetCoreObject()

local function showblender(data)
     local state = ''

     state = 'inactive'

     local header = "Blender unit (" .. state .. ')'
     -- header
     local heavy_naphtha = 0.0
     local light_naphtha = 0.0
     local other_gases = 0.0

     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-blender'
          }, {
               header = 'Heavy Naphtha',
               icon = 'fa-solid fa-circle',
               txt = heavy_naphtha .. " Gallons",
          },
          {
               header = 'Light Naphtha',
               icon = 'fa-solid fa-circle',
               txt = light_naphtha .. " Gallons",
          },
          {
               header = 'Other Gases',
               icon = 'fa-solid fa-circle',
               txt = other_gases .. " Gallons",

          },
          {
               header = 'Start Blending',
               icon = 'fa-solid fa-arrows-spin',
               params = {
                    event = "keep-oilrig:CDU_menu:set_CDU_temp"
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
     showblender()
     -- QBCore.Functions.TriggerCallback('keep-oilrig:server:get_CDU_Data', function(result)

     -- end)
end)
