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

local function disableCombat()
     DisablePlayerFiring(PlayerId(), true) -- Disable weapon firing
     DisableControlAction(0, 24, true) -- disable attack
     DisableControlAction(0, 25, true) -- disable aim
     DisableControlAction(1, 37, true) -- disable weapon select
     DisableControlAction(0, 47, true) -- disable weapon
     DisableControlAction(0, 58, true) -- disable weapon
     DisableControlAction(0, 140, true) -- disable melee
     DisableControlAction(0, 141, true) -- disable melee
     DisableControlAction(0, 142, true) -- disable melee
     DisableControlAction(0, 143, true) -- disable melee
     DisableControlAction(0, 263, true) -- disable melee
     DisableControlAction(0, 264, true) -- disable melee
     DisableControlAction(0, 257, true) -- disable melee
end

function LoadAnim(dict)
     while not HasAnimDictLoaded(dict) do
          RequestAnimDict(dict)
          Wait(10)
     end
end

function LoadPropDict(model)
     while not HasModelLoaded(GetHashKey(model)) do
          RequestModel(GetHashKey(model))
          Wait(10)
     end
end

local active_prop = nil
function AttachProp(model, bone, x, y, z, rot1, rot2, rot3)
     local playerped = PlayerPedId()
     local model_hash = GetHashKey(model)
     local playercoord = GetEntityCoords(playerped)
     local bone_index = GetPedBoneIndex(playerped, bone)
     local _x, _y, _z = table.unpack(playercoord)

     if not HasModelLoaded(model) then
          LoadPropDict(model)
     end

     active_prop = CreateObject(model_hash, _x, _y, _z + 0.2, true, true, true)
     AttachEntityToEntity(active_prop, playerped, bone_index, x, y, z, rot1, rot2, rot3, true, true, false, true, 1, true)
     SetModelAsNoLongerNeeded(model)
end

local function start_barell_animation()
     local playerped = PlayerPedId()
     local dict = 'anim@heists@box_carry@'
     local anim = 'idle'
     local PropName = 'prop_barrel_exp_01a'
     local PropBone = 60309

     LoadAnim(dict)
     ClearPedTasks(playerped)
     RemoveAnimDict(dict)
     Wait(250)
     AttachProp(PropName, PropBone, 0.0, 0.41, 0.3, 130.0, 290.0, 0.0)
     CreateThread(function()
          while active_prop do
               local not_animation = IsEntityPlayingAnim(playerped, dict, anim, 3)
               if not_animation ~= 1 then
                    TaskPlayAnim(playerped, dict, anim, 2.0, 2.0, -1, 51, 0, false, false, false)
                    DisableControlAction(0, 22, true)
               end
               Wait(1500)
          end
     end)
     CreateThread(function()
          while active_prop do
               --disable combat while player have barell in their hands
               disableCombat()
               Wait(1)
          end
     end)
end

local function end_barell_animaiton()
     local playerped = PlayerPedId()
     local dict = 'anim@heists@box_carry@'
     local anim = 'idle'

     if active_prop then
          DeleteObject(active_prop)
          active_prop = nil
     end
     StopAnimTask(playerped, dict, anim, 1.0)
end

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
          -- start_barell_animation()
          QBCore.Functions.Progressbar("keep_oilwell_transport", 'Filling', Oilwell_config.Transport.duration * 1000,
               false, false, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true
               }, {}, {}, {}, function()
               QBCore.Functions.TriggerCallback('keep-oilrig:server:oil_transport:fillTransportWell', function(res)
                    -- end_barell_animaiton()
               end, inputData.amount)
          end)
     end
end)

local inventory_max_size = Oilwell_config.inventory_max_size

local function isBarellInInventory()
     local items = QBCore.Functions.GetPlayerData().items
     for slot = 1, inventory_max_size, 1 do
          if items[slot] and items[slot].name == 'oilbarell' then
               return true
          end
     end
     return false
end

local already_started = false
function StartBarellAnimation()
     if already_started then return end
     already_started = true
     CreateThread(function()
          while true do
               local b = isBarellInInventory()
               if b then
                    if not active_prop then
                         start_barell_animation()
                    end
               else
                    if active_prop then
                         end_barell_animaiton()
                    end
               end
               Wait(1500)
          end
     end)
end
