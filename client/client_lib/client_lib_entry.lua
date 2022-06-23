local QBCore = exports['qb-core']:GetCoreObject()

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
     local activeLaser = true
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
          Draw2DText('Press ~g~E~w~ To go there', 4, { 255, 255, 255 }, 0.4, 0.43,
               0.888 + 0.025)
          if IsControlJustReleased(0, 38) then
               activeLaser = false
               return coords
          end
          DrawLine(position.x, position.y, position.z, coords.x, coords.y,
               coords.z, color.r, color.g, color.b, color.a)
          DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0,
               0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a,
               false, true, 2, nil, nil, false)
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
          s = s:gsub("CITIZENID", oilrig.citizenid)
          s = s:gsub("OILWELL_HASH", oilrig.oilrig_hash)
          s = s:gsub("DB_ID_RAW", o.id)
          s = s:gsub("TYPE", o.type)

     else
          s = s:gsub("TYPE", o.type)
     end
     return s
end

function createOwnerQbTarget(entity)
     local coord = GetEntityCoords(entity)
     exports['qb-target']:AddBoxZone("oil-rig-" .. entity, coord, 3, 5, {
          name = "oil-rig-" .. entity,
          heading = GetEntityHeading(entity),
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
                         local oilrig = OilRigs:getByEntityHandle(entity)
                         if oilrig ~= nil and oilrig.isOwner == true then
                              return true
                         else
                              return false
                         end
                    end,
               },
               {
                    type = "client",
                    event = "keep-oilrig:client:show_oilwell_stash",
                    icon = "fa-solid fa-gears",
                    label = "Manange Parts",
                    canInteract = function(entity)
                         local oilrig = OilRigs:getByEntityHandle(entity)
                         if oilrig ~= nil and oilrig.isOwner == true then
                              return true
                         else
                              return false
                         end
                    end,
                    -- action = function(entity)
                    --      TriggerEvent('keep-oilrig:client:show_oilwell_stash', entity)
                    -- end
               },
          },
          distance = 2.5
     })
end

function addQbTargetToCoreEntities(entity, Type, PlayerJob)
     local key = Type
     local qbtarget_name = key .. entity

     if PlayerJob.name == 'oilwell' then
          if key == 'storage' then
               exports['qb-target']:AddEntityZone("storage" .. entity, entity, {
                    name = "storage" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = false,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "keep-oilrig:storage_menu:ShowStorage",
                              icon = "fa-solid fa-arrows-spin",
                              label = "View Storage",
                              canInteract = function(entity)
                                   print(OnDuty)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          elseif key == 'distillation' then
               exports['qb-target']:AddEntityZone("distillation" .. entity, entity, {
                    name = "distillation" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = false,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "keep-oilrig:CDU_menu:ShowCDU",
                              icon = "fa-solid fa-gear",
                              label = "Open CDU panel",
                              canInteract = function(entity)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          elseif key == 'blender' then
               exports['qb-target']:AddEntityZone("blender" .. entity, entity, {
                    name = "blender" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = false,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "keep-oilrig:blender_menu:ShowBlender",
                              icon = "fa-solid fa-gear",
                              label = "Open blender panel",
                              canInteract = function(entity)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          elseif key == 'barrel_withdraw' then
               exports['qb-target']:AddEntityZone("barrel_withdraw" .. entity, entity, {
                    name = "barrel_withdraw" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = false,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "keep-oilrig:client_lib:withdraw_from_queue",
                              icon = "fa-solid fa-boxes-packing",
                              label = "Send to invnetory",
                              canInteract = function(entity)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          elseif key == 'crude_oil_transport' then
               exports['qb-target']:AddEntityZone("crude_oil_transport" .. entity, entity, {
                    name = "crude_oil_transport" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = false,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "keep-oilwell:menu:show_transport_menu",
                              icon = "fa-solid fa-boxes-packing",
                              label = "Fill transport well",
                              canInteract = function(entity)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          end
     end

     if key == 'toggle_job' then
          exports['qb-target']:AddEntityZone("toggle_job" .. entity, entity, {
               name = "toggle_job" .. entity,
               heading = GetEntityHeading(entity),
               debugPoly = false,
          }, {
               options = {
                    {
                         type = "client",
                         event = "keep-oilrig:client:goOnDuty",
                         icon = "fa-solid fa-boxes-packing",
                         label = "Toggle Duty",
                         canInteract = function(entity)
                              return true
                         end,
                    },
               },
               distance = 2.5
          })
     end

     return qbtarget_name
end

RegisterNetEvent('keep-oilrig:client_lib:withdraw_from_queue', function()
     QBCore.Functions.TriggerCallback('keep-oilrig:server:withdraw_from_queue', function(result)

     end)
end)

---force remove objects in area
---@param coord table
RegisterNetEvent('keep-oilrig:client:clearArea', function(coord)
     ClearAreaOfObjects(
          coord.x,
          coord.y,
          coord.z,
          5.0,
          1
     )
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(PlayerJob)
     if PlayerJob.name == 'oilwell' then
          OnDuty = PlayerJob.onduty
     end
end)

RegisterNetEvent('keep-oilrig:client:goOnDuty', function(PlayerJob)
     TriggerServerEvent("QBCore:ToggleDuty")
     if PlayerJob.name == 'oilwell' and PlayerJob.onduty == false then
          OnDuty = true
     else
          OnDuty = false
     end
end)
