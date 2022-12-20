from "%rGui/globals/ui_library.nut" import *

let globalState = require("globalState.nut")
let widgetsState = require("widgetsState.nut")
let hudState = require("hudState.nut")
let hudUnitType = require("hudUnitType.nut")
let shipHud = require("shipHud.nut")
let shipHudTouch = require("%rGui/hud/shipHudTouch.nut")
let shipExHud = require("shipExHud.nut")
let tankExHud = require("tankExHud.nut")
let shipObstacleRf = require("shipObstacleRangefinder.nut")
let shipDeathTimer = require("shipDeathTimer.nut")
let scoreboard = require("hud/scoreboard/scoreboard.nut")
let aircraftHud = require("aircraftHud.nut")
let helicopterHud = require("helicopterHud.nut")
let tankHud = require("tankHud.nut")
let changelog = require("changelog/changelog.ui.nut")

let widgetsMap = {
  [DargWidgets.HUD] = function() {
    if (!globalState.isInFlight.value)
      return null

    if (hudUnitType.isHelicopter())
      return helicopterHud
    else if (hudUnitType.isAir())
      return aircraftHud
    else if (hudUnitType.isTank())
      return tankHud.Root
    else if (hudUnitType.isShip() && !hudState.isPlayingReplay.value)
      return shipHud
    else if (hudUnitType.isSubmarine() && !hudState.isPlayingReplay.value)
      return shipExHud
    //



    else
      return null
  },

  [DargWidgets.HUD_TOUCH] = function() {
    if (!globalState.isInFlight.value)
      return null

    if (hudUnitType.isShip())
      return shipHudTouch
    else
      return this[DargWidgets.HUD]()
  },

  [DargWidgets.SHIP_OBSTACLE_RF] = function () {
    return {
      size = flex()
      pos = [0, shHud(2)]
      halign = ALIGN_CENTER
      children = [shipObstacleRf, shipDeathTimer]
    }
  },

  [DargWidgets.SCOREBOARD] = @ () {
    size = flex()
    halign = ALIGN_CENTER
    children = scoreboard
  },

  [DargWidgets.CHANGE_LOG] = @() {
    size = flex()
    children = changelog
  },

  [DargWidgets.DAMAGE_PANEL] = @() tankHud.tankDmgIndicator
}


let widgets = @() {
  watch = [
    globalState.isInFlight
    hudState.unitType
    hudState.isPlayingReplay
    widgetsState
  ]
  children = widgetsState.value.map(@(widget) {
    size = widget?.transform?.size ?? [sw(100), sh(100)]
    pos = widget?.transform?.pos ?? [0, 0]
    children = widgetsMap?[widget.widgetId]()
  })
}


return widgets