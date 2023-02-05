local QBCore = exports['qb-core']:GetCoreObject()

function isOwner(entity)
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
     Targets.qb_target.oilwell(coord, hash)
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

function Add_3rd_eye(coord, Type)
     local key = Type
     if key == 'storage' then
          Targets.qb_target.storage(coord, key)
     elseif key == 'distillation' then
          Targets.qb_target.distillation(coord, key)
     elseif key == 'blender' then
          Targets.qb_target.blender(coord, key)
     elseif key == 'barrel_withdraw' then
          Targets.qb_target.barrel_withdraw(coord, key)
     elseif key == 'crude_oil_transport' then
          Targets.qb_target.crude_oil_transport(coord, key)
     elseif key == 'toggle_job' then
          Targets.qb_target.toggle_job(coord, key)
     end
end

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
