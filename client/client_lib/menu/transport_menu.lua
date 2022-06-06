local QBCore = exports['qb-core']:GetCoreObject()

local function show_transport_menu()

     -- header
     local openMenu = {
          {
               header = 'Transport',
               txt = "sell your curde oil to make a profit",
               isMenuHeader = true,
               icon = 'fa-solid fa-ship'
          },
          {
               header = 'Check Current Price/Stock',
               icon = 'fa-solid fa-hand-holding-dollar',
               txt = "",
               params = {
                    event = 'keep-oilwell:menu:show_transport_menu:ask_stock_price',
               }
          },
          {
               header = 'Request Sell Order',
               icon = 'fa-solid fa-diagram-successor',
               txt = "",
               params = {
                    event = 'keep-oilwell:menu:show_transport_menu:ask_to_sell_amount',
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

AddEventHandler('keep-oilwell:menu:show_transport_menu', function()
     show_transport_menu()
end)

AddEventHandler('keep-oilwell:menu:show_transport_menu:ask_stock_price', function()
     TriggerServerEvent('keep-oilrig:server:oil_transport:checkPrice')
end)

AddEventHandler('keep-oilwell:menu:show_transport_menu:ask_to_sell_amount', function()
     local inputData = exports['qb-input']:ShowInput({
          header = "Enter number of Barrels",
          submitText = "Sell",
          inputs = {
               {
                    type = 'number',
                    isRequired = true,
                    name = 'amount',
                    text = "amount"
               },
          }
     })
     if inputData then
          if not inputData.amount then
               return
          end
          if type(inputData.amount) == 'string' then
               inputData.amount = math.floor(tonumber(inputData.amount))
          end
          QBCore.Functions.TriggerCallback('keep-oilrig:server:oil_transport:fillTransportWell', function(res)
               print(res)
          end, inputData.amount)
     end
end)
