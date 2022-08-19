local QBCore = exports['qb-core']:GetCoreObject()

local function showInfo(data)
     QBCore.Functions.TriggerCallback('keep-oilwell:server:oilwell_metadata', function(selected_oilrig)
          local header = "Name: " .. data.name
          local partInfoString = "Belt: " ..
              selected_oilrig.part_info.belt ..
              " Polish: " .. selected_oilrig.part_info.polish .. " Clutch: " .. selected_oilrig.part_info.clutch
          local duration = math.floor(selected_oilrig.duration / 60)
          -- header
          local openMenu = {
               {
                    header = header,
                    isMenuHeader = true,
                    icon = 'fa-solid fa-oil-well'
               }, {
                    header = 'Speed',
                    icon = 'fa-solid fa-gauge',
                    txt = "" .. selected_oilrig.speed .. " RPM",
                    disabled = true,
               },
               {
                    header = 'Duration',
                    icon = 'fa-solid fa-clock',
                    txt = "" .. duration .. " Min",
                    disabled = true,
               },
               {
                    header = 'Temperature',
                    icon = 'fa-solid fa-temperature-high',
                    txt = "" .. selected_oilrig.temp .. " °C",
                    disabled = true,
               },
               {
                    header = 'Oil Storage',
                    icon = 'fa-solid fa-oil-can',
                    txt = "" .. selected_oilrig.oil_storage .. "/Gal",
                    disabled = true,
               },
               {
                    header = 'Part Info',
                    icon = 'fa-solid fa-oil-can',
                    txt = partInfoString,
                    disabled = true,
               },
               {
                    header = 'Pump oil to storage',
                    icon = 'fa-solid fa-arrows-spin',
                    params = {
                         event = 'keep-oilrig:storage_menu:PumpOilToStorage',
                         args = {
                              oilrig_hash = data.oilrig_hash
                         }
                    }
               },
               {
                    header = 'Manage Employees',
                    icon = 'fa-solid fa-people-group',
                    params = {
                         event = 'keep-oilwell:menu:ManageEmployees',
                         args = data.oilrig_hash

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
     end, data.oilrig_hash)
end

RegisterNetEvent('keep-oilwell:menu:ManageEmployees', function(oilrig_hash)
     QBCore.Functions.TriggerCallback('keep-oilwell:server:employees_list', function(result)
          if not result then return end
          -- header
          local Menu = {
               {
                    header = 'Oilwell Employees',
                    isMenuHeader = true,
                    icon = 'fa-solid fa-vest'
               },
          }

          Menu[#Menu + 1] = {
               header = 'Add A New Employee',
               icon = 'fa-solid fa-person-circle-plus',
               params = {
                    event = "keep-oilwell:client:add_employee",
                    args = {
                         oilrig_hash = oilrig_hash,
                         state_id = 1
                    }
               }
          }

          for index, employee in ipairs(result) do
               local name = employee.charinfo.firstname .. ' ' .. employee.charinfo.lastname
               local gender = (employee.charinfo.gender == 0 and 'Male' or employee.charinfo.gender ~= 0 and 'Female')
               local information = 'Name: %s </br> Phone: %s </br> Gender: %s </br>'
               local other = ' (Online: %s)'
               local online = (employee.online and '🟢' or not employee.online and '🔴')

               Menu[#Menu + 1] = {
                    header = 'Employes #' .. index .. string.format(other, online),
                    txt = string.format(information, name, employee.charinfo.phone, gender),
                    icon = 'fa-solid fa-person',
                    params = {
                         event = "keep-oilwell:menu:remove_employee",
                         args = {
                              employee = employee,
                              oilrig_hash = oilrig_hash
                         }
                    }
               }
          end

          Menu[#Menu + 1] = {
               header = 'leave',
               icon = 'fa-solid fa-circle-xmark',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }

          exports['qb-menu']:openMenu(Menu)
     end, oilrig_hash)
end)

RegisterNetEvent('keep-oilwell:client:add_employee', function(data)
     local inputData = exports['qb-input']:ShowInput({
          header = 'Enter Employee State Id',
          inputs = {
               {
                    type = 'number',
                    isRequired = true,
                    name = 'stateId',
                    text = 'enter state id'
               },
          }
     })
     if inputData then
          if not inputData.stateId then return end
          inputData.stateId = tonumber(inputData.stateId)
          TriggerServerEvent('keep-oilwell:server:add_employee', data.oilrig_hash, inputData.stateId)
     end
end)

RegisterNetEvent('keep-oilwell:menu:remove_employee', function(data)
     local employee = data.employee
     local name = employee.charinfo.firstname .. ' ' .. employee.charinfo.lastname
     -- header
     local Menu = {
          {
               header = 'Back',
               icon = 'fa-solid fa-angle-left',
               params = {
                    event = "keep-oilwell:menu:ManageEmployees",
                    args = data.oilrig_hash
               }
          },
          {
               header = 'Fire Employee',
               txt = 'Name: ' .. name,
               isMenuHeader = true,
               icon = 'fa-solid fa-vest'
          },
          {
               header = 'Yes',
               icon = 'fa-solid fa-circle-check',
               params = {
                    event = "keep-oilwell:menu:fire_employee",
                    args = {
                         employee = data.employee,
                         oilrig_hash = data.oilrig_hash
                    }
               }
          }
     }

     Menu[#Menu + 1] = {
          header = 'Cancel',
          icon = 'fa-solid fa-circle-xmark',
          params = {
               event = "qb-menu:closeMenu"
          }
     }

     exports['qb-menu']:openMenu(Menu)
end)

RegisterNetEvent('keep-oilwell:menu:fire_employee', function(data)
     TriggerServerEvent('keep-oilwell:server:remove_employee', data.oilrig_hash, data.employee.citizenid)
end)

local function show_oilwell_stash(data)
     QBCore.Functions.TriggerCallback('keep-oilwell:server:oilwell_metadata', function(selected_oilrig)
          local header = "Name: " .. data.name
          local partInfoString = "Belt: " ..
              selected_oilrig.part_info.belt ..
              " Polish: " .. selected_oilrig.part_info.polish .. " Clutch: " .. selected_oilrig.part_info.clutch
          -- header
          local openMenu = {
               {
                    header = header,
                    isMenuHeader = true,
                    icon = 'fa-solid fa-oil-well'
               },
               {
                    header = 'Part Info',
                    icon = 'fa-solid fa-oil-can',
                    txt = partInfoString,
                    disabled = true,
               },
               {
                    header = 'Open Stash',
                    icon = 'fa-solid fa-cart-flatbed',
                    params = {
                         event = 'keep-oilwell:client:openOilPump',
                         args = {
                              oilrig_hash = data.oilrig_hash
                         }
                    }
               },
               {
                    header = 'Fix Oilwell',
                    icon = 'fa-solid fa-screwdriver-wrench',

                    params = {
                         event = 'keep-oilwell:client:fix_oilwell',
                         args = {
                              oilrig_hash = data.oilrig_hash
                         }
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
     end, data.oilrig_hash)
end

-- Events
AddEventHandler('keep-oilrig:storage_menu:PumpOilToStorage', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:PumpOilToStorageCallback', function(result)

     end, data.oilrig_hash)
end)

AddEventHandler('keep-oilrig:client:viewPumpInfo', function(qbtarget)
     -- ask for updated data
     OilRigs:startUpdate(function()
          showInfo(OilRigs:getByEntityHandle(qbtarget.entity))
     end)
end)


AddEventHandler('keep-oilrig:client:show_oilwell_stash', function(qbtarget)
     -- ask for updated data
     OilRigs:startUpdate(function()
          show_oilwell_stash(OilRigs:getByEntityHandle(qbtarget.entity))
     end)
end)

-- Open oil pump stash.
RegisterNetEvent("keep-oilwell:client:openOilPump", function(data)
     if not data then return end
     TriggerServerEvent("inventory:server:OpenInventory", "stash", "oilPump_" .. data.oilrig_hash,
          { maxweight = 100000, slots = 5 })
     TriggerEvent("inventory:client:SetCurrentStash", "oilPump_" .. data.oilrig_hash)
end)

AddEventHandler('keep-oilwell:client:fix_oilwell', function(data)
     -- ask for updated data
     QBCore.Functions.TriggerCallback('keep-oilwell:server:fix_oil_well', function(result)
          print(result)
     end, data.oilrig_hash)

end)
