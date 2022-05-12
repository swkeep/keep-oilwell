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
}
