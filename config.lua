Config = Config or {}

Config.AnimationSpeedDivider = 20 -- higher value => less animation speed at 100%
Config.actionSpeed = 5 -- how fast oilpump actionspeed is updated to new action speed / just visual

Config.locations = {
     storage = {
          position = vector4(1494.84, -1867.98, 69.7, 68.09),
          model = 'prop_storagetank_06',
     },
     distillation = {
          position = vector4(1490.81, -1846.19, 69.7, 0),
          model = 'v_ind_cm_electricbox',
     },
     blender = {
          position = vector4(1498.41, -1848.11, 69.5, 230.33),
          model = 'prop_storagetank_01',
     },
     barrel_withdraw = {
          position = vector4(1470.83, -1871.23, 70.8, 338.01),
          model = 'imp_prop_groupbarrel_03',
     }
}
-- prop_barrel_exp_01a.yft ron
-- prop_barrel_exp_01b.yft glob oil

-- prop_oil_wellhead_01
-- prop_oilcan_02a
Config.Delivery = {
     TriggerLocation = vector3(1475.82, -1855.29, 72.05),
     SpawnLocation = vector4(1495.04, -1850.61, 71.2, 109.22),
     DinstanceToTrigger = 10.0,
     vehicleModel = 'CGT'
}

Config.Settings = {
     capacity = {
          oilbarell = {
               size = 5000, -- gal
               price = 500
          },
          gasoline = {
               size = 5000, -- gal
               price = 500
          },
     }
}

-- vector3(998.08, -1859.08, 30.89)
