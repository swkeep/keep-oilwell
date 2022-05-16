PlayerJob = {}
OnDuty = false
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
     end
     BeginTextCommandSetBlipName("STRING")
     AddTextComponentString(o.name)
     EndTextCommandSetBlipName(blip)
     return blip
end

function createOwnerQbTarget(entity)
     exports['qb-target']:AddEntityZone("oil-rig-" .. entity, entity, {
          name = "oil-rig-" .. entity,
          heading = GetEntityHeading(entity),
          debugPoly = true,
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
                    event = "",
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
               },
          },
          distance = 2.5
     })
end

function createEntityQbTarget()
     for key, value in pairs(Config.locations) do
          local position = {
               coord = {
                    x = value.position.x,
                    y = value.position.y,
                    z = value.position.z
               }
          }

          TriggerEvent('keep-oilrig:client:clearArea', position.coord)
          Wait(100)
          local entity = CreateObject(GetHashKey(value.model), position.coord.x, position.coord.y, position.coord.z, 0, 0, 0)
          SetEntityAsMissionEntity(entity, 0, 0)
          while not DoesEntityExist(entity) do
               Wait(10)
          end
          SetEntityHeading(entity, value.position.w)
          FreezeEntityPosition(entity, true)
          if key == 'storage' then
               createCustom(position.coord, {
                    sprite = 361,
                    colour = 5,
                    range = 'short',
                    name = 'Oil ' .. key
               })
               exports['qb-target']:AddEntityZone("oil-storage" .. entity, entity, {
                    name = "oil-storage" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = true,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "keep-oilrig:storage_menu:ShowStorage",
                              icon = "fa-solid fa-arrows-spin",
                              label = "View Storage",
                              canInteract = function(entity)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          elseif key == 'distillation' then
               createCustom(position.coord, {
                    sprite = 365,
                    colour = 5,
                    range = 'short',
                    name = 'Oil ' .. key
               })
               exports['qb-target']:AddEntityZone("oil-CDU" .. entity, entity, {
                    name = "oil-CDU" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = true,
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
               exports['qb-target']:AddEntityZone("oil-blender" .. entity, entity, {
                    name = "oil-blender" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = true,
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
               exports['qb-target']:AddEntityZone("oil-barrel_withdraw" .. entity, entity, {
                    name = "oil-barrel_withdraw" .. entity,
                    heading = GetEntityHeading(entity),
                    debugPoly = true,
               }, {
                    options = {
                         {
                              type = "client",
                              event = "",
                              icon = "fa-solid fa-boxes-packing",
                              label = "Send to invnetory",
                              canInteract = function(entity)
                                   return true
                              end,
                         },
                    },
                    distance = 2.5
               })
          end
     end
end

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


-- RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
--      PlayerJob = JobInfo
--      print_table(PlayerJob)
--      if PlayerJob.name == 'oilwell' then
--           OnDuty = PlayerJob.onduty
--           if PlayerJob.onduty then
--                -- TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
--           else
--                -- TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
--           end
--      end
-- end)
