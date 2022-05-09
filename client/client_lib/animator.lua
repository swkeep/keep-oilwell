local animationList = {
     ['p_oil_pjack_03_s'] = {
          animDictionary = 'p_v_lev_des_skin',
          animationName = 'p_oil_pjack_03_s'
     }
}
function playAnimation(entity, speed)
     -- local bagAnim = "p_oil_pjack_03_s"
     -- local dict = 'p_v_lev_des_skin'
     -- RequestAnimDict(dict)
     -- while not HasAnimDictLoaded(dict) do
     --      Wait(10)
     -- end
     -- if not IsEntityPlayingAnim(entity, bagAnim, dict, 3) then
     --      PlayEntityAnim(entity, bagAnim, dict, speed, 0, 0, 0, 0, 0)
     -- end
     SetObjectStuntPropSpeedup(
          entity--[[ Object ]] ,
          speed--[[ integer ]]
     )
end
