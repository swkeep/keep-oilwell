local QBCore = exports['qb-core']:GetCoreObject()

local function isOwner(entity)
     local oilrig = OilRigs:getByEntityHandle(entity)
     if not oilrig then return print('failed to get oilwell') end
     local is_employee = nil
     local is_owner = nil
     -- await didn't work!
     QBCore.Functions.TriggerCallback('keep-oilwell:server:is_employee', function(_is_employee, _is_owner)
          is_employee, is_owner = _is_employee, _is_owner
     end, oilrig.oilrig_hash)
     for i = 1, 5, 1 do
          if is_employee ~= nil then
               break
          end
          Wait(50)
     end
     return is_employee, is_owner
end

local function Draw2DText(content, font, colour, scale, x, y)
     SetTextFont(font)
     SetTextScale(scale, scale)
     SetTextColour(colour[1], colour[2], colour[3], 255)
     SetTextEntry("STRING")
     SetTextDropShadow(0, 0, 0, 0, 255)
     SetTextDropShadow()
     SetTextEdge(4, 0, 0, 0, 255)
     SetTextOutline()
     AddTextComponentString(content)
     DrawText(x, y)
end

local function RotationToDirection(rotation)
     local adjustedRotation = {
          x = (math.pi / 180) * rotation.x,
          y = (math.pi / 180) * rotation.y,
          z = (math.pi / 180) * rotation.z
     }
     local direction = {
          x = -math.sin(adjustedRotation.z) *
              math.abs(math.cos(adjustedRotation.x)),
          y = math.cos(adjustedRotation.z) *
              math.abs(math.cos(adjustedRotation.x)),
          z = math.sin(adjustedRotation.x)
     }
     return direction
end

local function RayCastGamePlayCamera(distance)
     local cameraRotation = GetGameplayCamRot()
     local cameraCoord = GetGameplayCamCoord()
     local direction = RotationToDirection(cameraRotation)
     local destination = {
          x = cameraCoord.x + direction.x * distance,
          y = cameraCoord.y + direction.y * distance,
          z = cameraCoord.z + direction.z * distance
     }
     local a, b, c, d, e = GetShapeTestResult(
          StartShapeTestRay(cameraCoord.x, cameraCoord.y,
               cameraCoord.z, destination.x,
               destination.y, destination.z,
               -1, PlayerPedId(), 0))
     return c, e
end

function ChooseSpawnLocation()
     local plyped = PlayerPedId()
     local pedCoord = GetEntityCoords(plyped)
     local activeLaser = true
     local oilrig = CreateObject(GetHashKey('p_oil_pjack_03_s'), pedCoord.x, pedCoord.y, pedCoord.z, 1, 1, 0)
     SetEntityAlpha(oilrig, 150, true)

     while activeLaser do
          Wait(0)
          local color = {
               r = 2,
               g = 241,
               b = 181,
               a = 200
          }
          local position = GetEntityCoords(plyped)
          local coords, entity = RayCastGamePlayCamera(1000.0)
          Draw2DText('Press ~g~E~w~ To Place oilwell', 4, { 255, 255, 255 }, 0.4, 0.43,
               0.888 + 0.025)
          if IsControlJustReleased(0, 38) then
               activeLaser = false
               DeleteEntity(oilrig)
               return coords
          end
          DrawLine(position.x, position.y, position.z, coords.x, coords.y,
               coords.z, color.r, color.g, color.b, color.a)
          SetEntityCollision(oilrig, false, false)
          SetEntityCoords(oilrig, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0)
     end
end

function createCustom(coord, o)
     local blip = AddBlipForCoord(
          coord.x,
          coord.y,
          coord.z
     )
     SetBlipSprite(blip, o.sprite)
     SetBlipColour(blip, o.colour)
     if o.range == 'short' then
          SetBlipAsShortRange(blip, true)
     else
          SetBlipAsShortRange(blip, false)
     end
     BeginTextCommandSetBlipName("STRING")
     AddTextComponentString(replaceString(o))
     EndTextCommandSetBlipName(blip)
     return blip
end

function replaceString(o)
     local s = o.name
     if o.id ~= nil then
          --  oilwells
          local oilrig = OilRigs:getById(o.id)
          s = s:gsub("OILWELLNAME", oilrig.name)
          s = s:gsub("OILWELL_HASH", oilrig.oilrig_hash)
          s = s:gsub("DB_ID_RAW", o.id)
          s = s:gsub("TYPE", o.type)

     else
          s = s:gsub("TYPE", o.type)
     end
     return s
end

function createOwnerQbTarget(hash, coord)
     exports['qb-target']:RemoveZone("oil-rig-" .. hash)
     exports['qb-target']:AddBoxZone("oil-rig-" .. hash, coord, 4, 5, {
          name = "oil-rig-" .. hash,
          debugPoly = false,
          minZ = coord.z,
          maxZ = coord.z + 3,
     }, {
          options = {
               {
                    type = "client",
                    event = "keep-oilrig:client:viewPumpInfo",
                    icon = "fa-solid fa-info",
                    label = "View Pump Info",
                    canInteract = function(entity)
                         return true
                    end,
               },
               {
                    type = "client",
                    event = "keep-oilrig:client:changeRigSpeed",
                    icon = "fa-solid fa-gauge-high",
                    label = "Modifiy Pump Settings",
                    canInteract = function(entity)
                         if not CheckJob() then return false end
                         if not CheckOnduty() then return false end
                         return isOwner(entity)
                    end,
               },
               {
                    type = "client",
                    event = "keep-oilrig:client:show_oilwell_stash",
                    icon = "fa-solid fa-gears",
                    label = "Manange Parts",
                    canInteract = function(entity)
                         if not CheckJob() then return false end
                         if not CheckOnduty() then return false end
                         return isOwner(entity)
                    end,
               },
               {
                    type = "client",
                    event = "keep-oilwell:client:remove_oilwell",
                    icon = "fa-regular fa-file-lines",
                    label = "Remove Oilwell",
                    canInteract = function(entity)
                         if not CheckJob() then
                              return false
                         end
                         if not (PlayerJob.grade.level == 4) then
                              return false
                         end
                         if not CheckOnduty() then
                              return false
                         end
                         return true
                    end,
               },
          },
          distance = 2.5
     })
end

RegisterNetEvent('keep-oilwell:client:remove_oilwell', function(data)
     local oilwell = OilRigs:getByEntityHandle(data.entity)
     for i = 1, 3, 1 do
          local value = RandomHash(4)
          local inputData = exports['qb-input']:ShowInput({
               header = 'Enter This Values (' .. value .. ')',
               inputs = {
                    {
                         type = 'text',
                         isRequired = true,
                         name = 'RandomHash',
                         text = ''
                    },
               }
          })
          if not inputData then
               QBCore.Functions.Notify('Canceled', "primary")
               return
          end
          if inputData.RandomHash ~= value then
               QBCore.Functions.Notify('Failed', "primary")
               return
          end
     end
     TriggerServerEvent('keep-oilwell:server:remove_oilwell', oilwell.oilrig_hash)
end)

function addQbTargetToCoreEntities(coord, Type)
     local key = Type
     local debugPoly = false
     local tmp_coord = vector3(coord.x, coord.y, coord.z) -- to fix qb-target not showing up
     if key == 'storage' then
          exports['qb-target']:AddBoxZone(key, tmp_coord, 3, 3, {
               name = key,
               heading = coord.w,
               debugPoly = debugPoly,
               minZ = tmp_coord.z,
               maxZ = tmp_coord.z + 3
          }, {
               options = {
                    {
                         type = "client",
                         event = "keep-oilrig:storage_menu:ShowStorage",
                         icon = "fa-solid fa-arrows-spin",
                         label = "View Storage",
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              if not CheckOnduty() then
                                   QBCore.Functions.Notify('You must be on duty!', "error")
                                   Wait(2000)
                                   return false
                              end
                              return true
                         end,
                    },
               },
               distance = 2.5
          })
     elseif key == 'distillation' then
          exports['qb-target']:AddBoxZone(key, tmp_coord, 2, 4, {
               name = key,
               heading = coord.w,
               debugPoly = debugPoly,
               minZ = tmp_coord.z,
               maxZ = tmp_coord.z + 3
          }, {
               options = {
                    {
                         type = "client",
                         event = "keep-oilrig:CDU_menu:ShowCDU",
                         icon = "fa-solid fa-gear",
                         label = "Open CDU panel",
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              if not CheckOnduty() then
                                   QBCore.Functions.Notify('You must be on duty!', "error")
                                   Wait(2000)
                                   return false
                              end
                              return true
                         end,
                    },
               },
               distance = 1.5
          })
     elseif key == 'blender' then
          exports['qb-target']:AddBoxZone(key, tmp_coord, 4, 6, {
               name = key,
               heading = coord.w,
               debugPoly = debugPoly,
               minZ = tmp_coord.z,
               maxZ = tmp_coord.z + 3
          }, {
               options = {
                    {
                         type = "client",
                         event = "keep-oilrig:blender_menu:ShowBlender",
                         icon = "fa-solid fa-gear",
                         label = "Open blender panel",
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              if not CheckOnduty() then
                                   QBCore.Functions.Notify('You must be on duty!', "error")
                                   Wait(2000)
                                   return false
                              end
                              return true
                         end,
                    },
               },
               distance = 2.5
          })
     elseif key == 'barrel_withdraw' then
          exports['qb-target']:AddBoxZone(key, tmp_coord, 1.5, 1.5, {
               name = key,
               heading = coord.w,
               debugPoly = debugPoly,
               minZ = tmp_coord.z,
               maxZ = tmp_coord.z + 2
          }, {
               options = {
                    {
                         type = "client",
                         event = "keep-oilrig:client_lib:withdraw_from_queue",
                         icon = "fa-solid fa-boxes-packing",
                         label = "Transfer withdraw to stash",
                         truck = false,
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              if not CheckOnduty() then
                                   QBCore.Functions.Notify('You must be on duty!', "error")
                                   Wait(2000)
                                   return false
                              end
                              return true
                         end,
                    },
                    {
                         type = "client",
                         event = "keep-oilwell:client:openWithdrawStash",
                         icon = "fa-solid fa-boxes-packing",
                         label = "Open Withdraw Stash",
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              if not CheckOnduty() then
                                   QBCore.Functions.Notify('You must be on duty!', "error")
                                   Wait(2000)
                                   return false
                              end
                              return true
                         end,
                    },
                    {
                         type = "client",
                         event = "keep-oilwell:client:open_purge_menu",
                         icon = "fa-solid fa-trash-can",
                         label = "Purge Withdraw Stash",
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              if not CheckOnduty() then
                                   QBCore.Functions.Notify('You must be on duty!', "error")
                                   Wait(2000)
                                   return false
                              end
                              return true
                         end,
                    },
               },
               distance = 2.5
          })
     elseif key == 'crude_oil_transport' then
          exports['qb-target']:AddBoxZone(key, tmp_coord, 2, 2, {
               name = key,
               heading = coord.w,
               debugPoly = debugPoly,
               minZ = tmp_coord.z,
               maxZ = tmp_coord.z + 2
          }, {
               options = {
                    {
                         type = "client",
                         event = "keep-oilwell:menu:show_transport_menu",
                         icon = "fa-solid fa-boxes-packing",
                         label = "Fill transport well",
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              if not CheckOnduty() then
                                   QBCore.Functions.Notify('You must be on duty!', "error")
                                   Wait(2000)
                                   return false
                              end
                              return true
                         end,
                    },
               },
               distance = 2.5
          })
     elseif key == 'toggle_job' then
          exports['qb-target']:AddBoxZone(key, tmp_coord, 1, 1, {
               name = key,
               heading = coord.w,
               debugPoly = debugPoly,
               minZ = tmp_coord.z,
               maxZ = tmp_coord.z + 2
          }, {
               options = {
                    {
                         type = "client",
                         event = "keep-oilrig:client:goOnDuty",
                         icon = "fa-solid fa-boxes-packing",
                         label = "Toggle Duty",
                         canInteract = function(entity)
                              if not CheckJob() then return false end
                              return true
                         end,
                    },
               },
               distance = 2.5
          })
     end
end

RegisterNetEvent('keep-oilrig:client_lib:withdraw_from_queue', function(data)
     QBCore.Functions.TriggerCallback('keep-oilrig:server:withdraw_from_queue', function(result)
          -- res >> table of items
          if result == false then
               return
          end
          if not result.truck then
               return
          end
          local SpawnLocation = Oilwell_config.Delivery.SpawnLocation
          local TriggerLocation = Oilwell_config.Delivery.TriggerLocation
          local DinstanceToTrigger = Oilwell_config.Delivery.DinstanceToTrigger
          local model = Oilwell_config.Delivery.vehicleModel

          MakeVehicle(model, SpawnLocation, TriggerLocation, DinstanceToTrigger, result)
     end, data.truck)
end)

---force remove objects in area
---@param coord table
RegisterNetEvent('keep-oilrig:client:clearArea', function(coord)
     ClearAreaOfObjects(coord.x, coord.y, coord.z, 5.0, 1)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(PlayerJob)
     if CheckJob() then
          OnDuty = CheckOnduty()
     end
end)

RegisterNetEvent('keep-oilrig:client:goOnDuty', function(PlayerJob)
     TriggerServerEvent("QBCore:ToggleDuty")
     if CheckJob() and CheckOnduty() == false then
          OnDuty = true
     else
          OnDuty = false
     end
end)
