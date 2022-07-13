local menu = MenuV:CreateMenu(false, 'Swkeep Oilwell Menu', 'topright', 0, 0, 0, 'size-125', 'default', 'menuv',
     'swkeep_oilwell')
menu.Title = ('Entity: %s'):format(OBJECT)

local slider = menu:AddSlider({ icon = '❓', label = 'Accuracy', value = '', values = {
     { label = 'X1', value = 1 },
     { label = 'X2', value = 2 },
     { label = 'X3', value = 3 },
     { label = 'X4', value = 4 },
     { label = 'X5', value = 5 },
     { label = 'X6', value = 6 }
} })

local range = menu:AddRange({
     icon = '↔️',
     label = 'Rotate on Z',
     min = -10,
     max = 10,
     value = 0,
     saveOnUpdate = true
})
local range2 = menu:AddRange({
     icon = '↕️',
     label = 'Rotate on Y',
     min = -10,
     max = 10,
     value = 0,
     saveOnUpdate = true
})

local range3 = menu:AddRange({
     icon = '↕️',
     label = 'Rotate on X',
     min = -10,
     max = 10,
     value = 0,
     saveOnUpdate = true
})

--- Events

slider:On('change', function(item, newValue, oldValue)
     local m = 10 * newValue
     range.Max = m
     range.Min = -m

     range2.Max = m
     range2.Min = -m

     range3.Max = m
     range3.Min = -m
end)

range:On('change', function(item, newValue, oldValue)
     menu.Title = ('Entity: %s'):format(OBJECT)
     range.Description = ('current value (x) : %s'):format(newValue)
     local roration = GetEntityRotation(OBJECT, 0)
     SetEntityRotation(OBJECT, roration.x, roration.y, 0.0 + newValue * 6, 0.0, true)
end)

range2:On('change', function(item, newValue, oldValue)
     menu.Title = ('Entity: %s'):format(OBJECT)
     range2.Description = ('current value (y) : %s'):format(newValue)
     local roration = GetEntityRotation(OBJECT, 0)
     SetEntityRotation(OBJECT, roration.x, 0.0 + newValue * 6, roration.z, 0.0, true)
end)

range3:On('change', function(item, newValue, oldValue)
     menu.Title = ('Entity: %s'):format(OBJECT)
     range3.Description = ('current value (z) : %s'):format(newValue)
     local roration = GetEntityRotation(OBJECT, 0)
     SetEntityRotation(OBJECT, 0.0 + newValue * 3, roration.y, roration.z, 0.0, true)
end)

local isOpen = false
AddEventHandler('keep-oilwell:menu:OPENMENU', function()
     if not IsPauseMenuActive() and IsNuiFocused() ~= 1 and not isOpen then
          MenuV:OpenMenu(menu)
          isOpen = true
     elseif isOpen == true then
          MenuV:CloseMenu(menu)
          isOpen = false
     end
end)
