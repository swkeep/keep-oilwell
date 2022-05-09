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
     local selected_oilrig = qbtarget.s_res.metadata
     print_table(selected_oilrig)
     local header = "Name: " .. qbtarget.s_res.name
     local leave = "leave"
     local partInfoString = "Belt: " .. selected_oilrig.part_info.belt .. " Polish: " .. selected_oilrig.part_info.polish .. " Clutch: " .. selected_oilrig.part_info.clutch

     -- header
     local openMenu = {
          {
               header = header,
               isMenuHeader = true
          }, {
               header = 'Speed:',
               txt = "" .. selected_oilrig.speed,

          },
          --  {
          --      header = 'Duration:',
          --      txt = "" .. selected_oilrig.duration,
          -- },
          {
               header = 'Temperature:',
               txt = "" .. selected_oilrig.temp,
          },
          {
               header = 'Oil Storage:',
               txt = "" .. selected_oilrig.oil_storage,
          },
          {
               header = 'Part Info:',
               txt = partInfoString,
          },
          {
               header = 'Pump oil to storage:',
               txt = "",
          },
          {
               header = leave,
               txt = "",
               params = {
                    event = "qb-menu:closeMenu"
               }
          }
     }

     exports['qb-menu']:openMenu(openMenu)
end)

-- AddEventHandler('keep-oilrig:client:viewPumpInfo', function()
--      local header = "Name: "
--      local leave = "leave"

--      -- header
--      local openMenu = {
--           {
--                header = header,
--                txt = "pet under control",
--                isMenuHeader = true
--           }, {
--                header = '>',
--                txt = "",
--                params = {
--                     event = "keep-oilrig:client:rotate",
--                     args = {
--                          side = 'right'
--                     }
--                }

--           }, {
--                header = '<',
--                txt = "",
--                params = {
--                     event = "keep-oilrig:client:rotate",
--                     args = {
--                          side = 'left'
--                     }
--                }
--           }, {
--                header = leave,
--                txt = "",
--                params = {
--                     event = "qb-menu:closeMenu"
--                }
--           }
--      }

--      exports['qb-menu']:openMenu(openMenu)
-- end)
