Config = Config or {}

Config.AnimationSpeedDivider = 20 -- higher value => less animation speed at 100%
Config.actionSpeed = 5 -- how fast oilpump actionspeed is updated to new action speed / just visual

-- Config.locations = {
--      storage = {
--           position = vector4(1494.84, -1867.98, 69.7, 68.09),
--           model = 'prop_storagetank_06',
--      },
--      distillation = {
--           position = vector4(1490.81, -1846.19, 69.7, 0),
--           model = 'v_ind_cm_electricbox',
--      },
--      blender = {
--           position = vector4(1498.41, -1848.11, 69.5, 230.33),
--           model = 'prop_storagetank_01',
--      },
--      barrel_withdraw = {
--           position = vector4(1470.83, -1871.23, 70.8, 338.01),
--           model = 'imp_prop_groupbarrel_03',
--      },
--      oil_wellhead = {
--           position = vector4(1480.9, -1850.85, 70.1, 246.85),
--           model = 'prop_oil_wellhead_01',
--      }
-- }
-- -- prop_barrel_exp_01a.yft ron
-- -- prop_barrel_exp_01b.yft glob oil

-- -- prop_oil_wellhead_01
-- -- prop_oilcan_02a
-- Config.Delivery = {
--      TriggerLocation = vector3(1475.82, -1855.29, 72.05),
--      SpawnLocation = vector4(1495.04, -1850.61, 71.2, 109.22),
--      DinstanceToTrigger = 10.0,
--      vehicleModel = 'CGT'
-- }


Config.locations = {
     storage = {
          position = vector4(1710.67, -1662.0, 110.8, 325.22),
          rotation = vector3(0.0, 0.0, 0.0),
          model = 'prop_storagetank_06',
     },
     distillation = {
          position = vector4(1672.77, -1649.9, 110.2, 10),
          rotation = vector3(0.0, 0.0, 0.0),
          model = 'v_ind_cm_electricbox',
     },
     blender = {
          position = vector4(1737.56, -1635.58, 111, 190),
          rotation = vector3(0.0, 0.0, 0.0),
          model = 'prop_storagetank_01',
     },
     barrel_withdraw = {
          position = vector4(1712.23, -1622.53, 111.48, 214.88),
          rotation = vector3(0.0, 0.0, 0.0),
          model = 'imp_prop_groupbarrel_03',
     },
     -- placeholder
     oil_wellhead = {
          position = vector4(1480.9, -1850.85, 70.1, 246.85),
          rotation = vector3(0.0, 0.0, 0.0),
          model = 'prop_oil_wellhead_01',
     },
     toggle_job = {
          position = vector4(1703.5, -1635, 111.49, 100.11),
          rotation = vector3(0.0, 0.0, 100.0),
          model = 'xm_base_cia_server_02',
     }
}
-- prop_barrel_exp_01a.yft ron
-- prop_barrel_exp_01b.yft glob oil

-- prop_oil_wellhead_01
-- prop_oilcan_02a
Config.Delivery = {
     TriggerLocation = vector3(1737.45, -1691.28, 112.73),
     SpawnLocation = vector4(1741.19, -1694.61, 112.73, 125.57),
     DinstanceToTrigger = 5.0,
     vehicleModel = 'rallytruck'
}

Config.Settings = {
     capacity = {
          oilbarell = {
               size = 5000, -- gal
               price = 500
          },
          truck = {
               size = 5000, -- gal placeholder
               price = 25000
          }
     }
}

-- vector3(998.08, -1859.08, 30.89)
