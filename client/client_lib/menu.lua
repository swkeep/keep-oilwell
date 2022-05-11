local QBCore = exports['qb-core']:GetCoreObject()

local menu = MenuV:CreateMenu(false, 'Welcome to MenuV', 'topright', 255, 0, 0, 'size-125', 'none', 'menuv', 'example_namespace')
local range = menu:AddRange({
     icon = '↔️',
     label = 'Rotate on Z',
     min = -30,
     max = 30,
     value = 0,
     saveOnUpdate = true
})
local range2 = menu:AddRange({
     icon = '↕️',
     label = 'Rotate on Y',
     min = -30,
     max = 30,
     value = 0,
     saveOnUpdate = true
})
local range3 = menu:AddRange({
     icon = '↕️',
     label = 'Rotate on X',
     min = -60,
     max = 60,
     value = 0,
     saveOnUpdate = true
})

local range4 = menu:AddRange({
     icon = '⚡',
     label = 'speed',
     min = 0,
     max = 15,
     value = 0,
     saveOnUpdate = true
})

local btn = menu:AddButton({
     icon = '😃',
     label = 'Confirm',
     value = menu,
     description = 'Confirm'
})
--- Events

range:On('change', function(item, newValue, oldValue)
     menu.Title = ('MenuV %s'):format(newValue)
     local roration = GetEntityRotation(OBJECT, 0)
     SetEntityRotation(OBJECT, roration.x, roration.y, 0.0 + newValue * 6, 0.0, true)
end)

range2:On('change', function(item, newValue, oldValue)
     menu.Title = ('MenuV %s'):format(newValue)
     local roration = GetEntityRotation(OBJECT, 0)
     SetEntityRotation(OBJECT, roration.x, 0.0 + newValue * 6, roration.z, 0.0, true)
end)

range3:On('change', function(item, newValue, oldValue)
     menu.Title = ('MenuV %s'):format(newValue)
     local roration = GetEntityRotation(OBJECT, 0)

     SetEntityRotation(OBJECT, 0.0 + newValue * 3, roration.y, roration.z, 0.0, true)
end)

range4:On('change', function(item, newValue, oldValue)
     menu.Title = ('MenuV %s'):format(newValue)
     local netId = NetworkGetNetworkIdFromEntity(OBJECT)
     TriggerServerEvent('keep-oilrig:server:syncOilrigSpeed', netId, newValue)
end)

btn:On('select', function(item, value)
     playAnimation(OBJECT, speed)
end)

menu:OpenWith('KEYBOARD', 'o')

AddEventHandler('keep-oilrig:client:viewPumpInfo', function(qbtarget)
     -- ask for updated data
     OilRigs:startUpdate(function()
          showInfo(OilRigs:getByEntity(qbtarget.entity))
     end)
end)

function showInfo(data)
     local selected_oilrig = data.metadata
     local header = "Name: " .. data.name
     local partInfoString = "Belt: " .. selected_oilrig.part_info.belt .. " Polish: " .. selected_oilrig.part_info.polish .. " Clutch: " .. selected_oilrig.part_info.clutch
     local duration = math.floor(selected_oilrig.duration / 60)
     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true,
               icon = 'fa-solid fa-pump'
          }, {
               header = 'Speed',
               icon = 'fa-solid fa-gauge',
               txt = "" .. selected_oilrig.speed .. " RPM",
          },
          {
               header = 'Duration',
               icon = 'fa-solid fa-clock',
               txt = "" .. duration .. " Min",
          },
          {
               header = 'Temperature',
               icon = 'fa-solid fa-temperature-high',
               txt = "" .. selected_oilrig.temp .. " °C",
          },
          {
               header = 'Oil Storage',
               icon = 'fa-solid fa-oil-can',
               txt = "" .. selected_oilrig.oil_storage .. "/Gal"
          },
          {
               header = 'Part Info',
               icon = 'fa-solid fa-oil-can',
               txt = partInfoString,
          },
          {
               header = 'Pump oil to storage',
               icon = 'fa-solid fa-arrows-spin',
               params = {
                    event = 'keep-oilrig:client_lib:PumpOilToStorage',
                    args = {
                         oilrig_hash = data.oilrig_hash
                    }
               }
          },
          {
               header = 'leave',
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end

RegisterNetEvent('keep-oilrig:client_lib:PumpOilToStorage', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:client_lib:PumpOilToStorageCallback', function(result)

     end, data.oilrig_hash)
end)
