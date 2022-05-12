AddEventHandler('keep-oilrig:client_lib:ShowCDU', function()
     showCDU(data)
end)

function showCDU(data)
     local header = "Crude oil distillation unit (" .. 'inactive' .. ')'
     -- header
     local CDU_Temperature = 50
     local CDU_Gal = 250
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-gear'
          }, {
               header = 'Temperature',
               icon = 'fa-solid fa-temperature-high',
               txt = "" .. CDU_Temperature .. " °C",
          },
          {
               header = 'Curde Oil',
               icon = 'fa-solid fa-oil-can',
               txt = CDU_Gal .. " Gallons",
          },
          {
               header = 'Pump Curde Oil',
               icon = 'fa-solid fa-arrows-spin',
               params = {
                    event = "keep-oilrig:client_lib:StorageActions"
               }
          },
          {
               header = 'Change Temperature',
               icon = 'fa-solid fa-temperature-arrow-up',
               params = {
                    event = "keep-oilrig:client_lib:StorageActions"
               }
          },
          {
               header = 'Toggle CDU',
               icon = 'fa-solid fa-sliders',
               params = {
                    event = "fa-solid fa-sliders"
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
