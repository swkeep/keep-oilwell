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
               icon = 'fa-solid fa-oil-well'
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

-- Events

AddEventHandler('keep-oilrig:client:viewPumpInfo', function(qbtarget)
     -- ask for updated data
     OilRigs:startUpdate(function()
          showInfo(OilRigs:getByEntityHandle(qbtarget.entity))
     end)
end)
