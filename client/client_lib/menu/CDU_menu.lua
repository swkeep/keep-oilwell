local QBCore = exports['qb-core']:GetCoreObject()

local function showCDU(data)
     if not data then return end
     local state = ''
     if data.metadata.state == true then
          state = 'Active'
     else
          state = 'inactive'
     end
     local header = "Crude oil distillation unit (" .. state .. ')'
     -- header
     local CDU_Temperature = data.metadata.temp
     local CDU_Gal = data.metadata.oil_storage
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
               header = 'Curde Oil inside CDU',
               icon = 'fa-solid fa-oil-can',
               txt = CDU_Gal .. " Gallons",
          },
          {
               header = 'Pump Curde Oil to CDU',
               icon = 'fa-solid fa-arrows-spin',
               params = {
                    event = "keep-oilrig:CDU_menu:pumpCrudeOil_to_CDU"
               }
          },
          {
               header = 'Change Temperature',
               icon = 'fa-solid fa-temperature-arrow-up',
               params = {
                    event = "keep-oilrig:CDU_menu:set_CDU_temp"
               }
          },
          {
               header = 'Toggle CDU',
               icon = 'fa-solid fa-sliders',
               params = {
                    event = "keep-oilrig:CDU_menu:switchPower_of_CDU"
               }
          },
          {
               header = 'leave',
               icon = 'fa-solid fa-circle-xmark',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }
     exports['qb-menu']:openMenu(openMenu)
end

AddEventHandler('keep-oilrig:CDU_menu:ShowCDU', function()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:get_CDU_Data', function(result)
          showCDU(result)
     end)
end)

AddEventHandler('keep-oilrig:CDU_menu:switchPower_of_CDU', function()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:switchPower_of_CDU', function(result)
          showCDU(result)
     end)
end)

AddEventHandler('keep-oilrig:CDU_menu:set_CDU_temp', function()
     local inputData = exports['qb-input']:ShowInput({
          header = "CDU Temperature",
          submitText = "Assign new temperature",
          inputs = { {
               type = 'number',
               isRequired = true,
               name = 'temp',
               text = "Enter new temperature"
          },
          }
     })
     if inputData then
          if not inputData.temp then
               return
          end
          QBCore.Functions.TriggerCallback('keep-oilrig:server:set_CDU_temp', function(result)
               showCDU(result)
          end, inputData)
     end
end)

AddEventHandler('keep-oilrig:CDU_menu:pumpCrudeOil_to_CDU', function()
     local inputData = exports['qb-input']:ShowInput({
          header = "Pump crude oil to CDU",
          submitText = "Enter",
          inputs = { {
               type = 'number',
               isRequired = true,
               name = 'amount',
               text = "Enter Value"
          },
          }
     })
     if inputData then
          inputData.amount = tonumber(inputData.amount)
          if not inputData.amount then
               return
          end

          if inputData.amount <= 0 then
               QBCore.Functions.Notify('Amount must be more than 0', "error")
               return
          end
          QBCore.Functions.TriggerCallback('keep-oilrig:server:pumpCrudeOil_to_CDU', function(result)
               showCDU(result)
          end, inputData)
     end
end)
