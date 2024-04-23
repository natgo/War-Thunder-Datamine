from "%rGui/globals/ui_library.nut" import *

let { gameType, timeLeft, timeLimitWarn, customHUD } = require("%rGui/missionState.nut")
let { HasCompass } = require("%rGui/compassState.nut")
let { safeAreaSizeHud, safeAreaSizeMenu } = require("%rGui/style/screenState.nut")
let { secondsToTimeSimpleString } = require("%sqstd/time.nut")
let football = require("football.ui.nut")
let deathmatch = require("deathmatch.ui.nut")
let po2OpMission = require("po2OpMission.ui.nut")
let convoyHunting = require("convoyHunting.nut")
let mkBattleMissionHud = require("battleMissionHud/mkBattleMissionHud.ui.nut")
let { isInSpectatorMode, isInRespawnWnd } = require("%rGui/respawnWndState.nut")
let { fontSizeMultiplier } = require("%rGui/style/fontsState.nut")
let extraction = require("extraction.nut")

let getNoRespTextSize = @() fpx(22)

let timerComponent = @() {
  watch = [timeLeft, isInRespawnWnd]
  rendObj = ROBJ_TEXT
  font = Fonts.medium_text_hud
  color = Color(255, 255, 255)
  pos = [0, isInRespawnWnd.get() ? 0 : hdpx(40)]
  text = secondsToTimeSimpleString(timeLeft.value)
}

let hasTimerComponent = Computed(@() timeLimitWarn.value > 0 && timeLeft.value < timeLimitWarn.value)

let customHudNameToComp = { deathmatch, convoyHunting, po2OpMission, extraction }

function getScoreBoardChildren() {
  if ((gameType.value & GT_FOOTBALL) != 0)
    return football

  if (customHUD.get() == "battleMission")
    return mkBattleMissionHud()

  let customHudComp = customHudNameToComp?[customHUD.get()]
  if (customHudComp)
    return customHudComp

  if (hasTimerComponent.value)
    return timerComponent

  return null
}

return function mkScoreboard() {
  let hudScale = Computed(@() isInRespawnWnd.get()
    ? min(fontSizeMultiplier.get(), 1)
    : 1)

  let yPos = Computed(function() {
    if (!isInRespawnWnd.get())
      return HasCompass.get() ? hdpx(50) : 0
    if (isInSpectatorMode.get())
      return getNoRespTextSize() + hdpx(4)
    return 0
  })

  let margin = Computed(@() isInRespawnWnd.get() ? safeAreaSizeMenu.get().borders : safeAreaSizeHud.get().borders)

  return @() {
    watch = [gameType, margin, hasTimerComponent, customHUD, HasCompass, yPos, hudScale, isInRespawnWnd]
    size = flex()
    pos = [0, yPos.get()]
    margin = margin.get()
    halign = ALIGN_CENTER
    children = getScoreBoardChildren()

    transform = {
      scale = [hudScale.get(), hudScale.get()]
      pivot = [0.5, 0]
    }
  }
}