Config = Config or {}

Config.AnimationSpeedDivider = 20 -- higher value => less animation speed at 100%
Config.actionSpeed = 5 -- how fast oilpump actionspeed is updated to new action speed / just visual

Config.Settings = {
     oil_well = {
          blip = {
               sprite = 436,
               colour = 5,
               range = 'short',
               -- CITIZENID | OILWELLNAME | DB_ID_RAW | TYPE | OILWELL_HASH
               -- if scirpt detect this keywords inside string it will replace them.
               name = 'Oil DB_ID_RAW'
          }
     },
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

Config.locations = {
     storage = {
          position = vector4(1710.67, -1662.0, 110.8, 325.22),
          rotation = vector3(0.0, 0.0, 0.0),
          model = 'prop_storagetank_06',
          blip = {
               sprite = 478,
               colour = 5,
               range = 'short',
               name = 'Oil TYPE'
          }
     },
     distillation = {
          position = vector4(1674, -1649.7, 110.2, 10),
          rotation = vector3(0.0, 0.0, 10.0),
          model = 'v_ind_cm_electricbox',
          blip = {
               sprite = 467,
               colour = 5,
               range = 'short',
               name = 'Oil TYPE'
          }
     },
     blender = {
          position = vector4(1737.56, -1635.58, 110.88, 190),
          rotation = vector3(0.0, 0.0, 190.0),
          model = 'prop_storagetank_01',
          blip = {
               sprite = 365,
               colour = 5,
               range = 'short',
               name = 'Oil TYPE'
          }
     },
     barrel_withdraw = {
          position = vector4(1712.23, -1622.53, 111.48, 214.88),
          rotation = vector3(0.0, 0.0, 0.0),
          model = 'imp_prop_groupbarrel_03',
          blip = {
               sprite = 549,
               colour = 5,
               range = 'short',
               name = 'Oil TYPE'
          }
     },
     -- placeholder
     -- oil_wellhead = {
     --      position = vector4(1480.9, -1850.85, 70.1, 246.85),
     --      rotation = vector3(0.0, 0.0, 0.0),
     --      model = 'prop_oil_wellhead_01',
     -- },
     toggle_job = {
          position = vector4(1703.5, -1635, 111.49, 100.11),
          rotation = vector3(0.0, 0.0, 100.0),
          model = 'xm_base_cia_server_02',
          blip = {
               sprite = 306,
               colour = 5,
               range = 'short',
               name = 'Oil TYPE'
          }
     }
}

Config.Delivery = {
     TriggerLocation = vector3(1737.45, -1691.28, 112.73),
     SpawnLocation = vector4(1741.19, -1694.61, 112.73, 125.57),
     DinstanceToTrigger = 5.0,
     vehicleModel = 'rallytruck'
}

-- prop_barrel_exp_01a.yft ron
-- prop_barrel_exp_01b.yft glob oil

-- prop_oil_wellhead_01
-- prop_oilcan_02a

-- vector3(998.08, -1859.08, 30.89)
