from "%scripts/dagui_library.nut" import *

let { showMsgboxIfEacInactive } = require("%scripts/penitentiary/antiCheat.nut")
let { showMsgboxIfSoundModsNotAllowed } = require("%scripts/penitentiary/soundMods.nut")
let { isMeBanned } = require("%scripts/penitentiary/penalties.nut")
let { isInBattleState } = require("%scripts/clientState/clientStates.nut")
let { addListenersWithoutEnv } = require("%sqStdLibs/helpers/subscriptions.nut")
let { matchingApiFunc } = require("%scripts/matching/api.nut")

let isReconnectChecking = mkWatched(persist, "isReconnectChecking", false)

function reconnect(roomId, gameModeName) {
  let event = ::events.getEvent(gameModeName)
  if (!showMsgboxIfEacInactive(event) || !showMsgboxIfSoundModsNotAllowed(event))
    return

  ::SessionLobby.joinRoom(roomId)
}

function onCheckReconnect(response) {
  isReconnectChecking(false)

  let roomId = response?.roomId
  let gameModeName = response?.game_mode_name
  if (!roomId || !gameModeName)
    return

  scene_msg_box("backToBattle_dialog", null, loc("msgbox/return_to_battle_session"), [
    ["yes", @() reconnect(roomId, gameModeName)],
    ["no"]], "yes")
}

function checkReconnect() {
  if (isReconnectChecking.value || !::g_login.isLoggedIn() || isInBattleState.value || isMeBanned())
    return

  isReconnectChecking(true)
  matchingApiFunc("match.check_reconnect", onCheckReconnect)
}

addListenersWithoutEnv({
  MatchingConnect = @(_) checkReconnect()
})

return checkReconnect