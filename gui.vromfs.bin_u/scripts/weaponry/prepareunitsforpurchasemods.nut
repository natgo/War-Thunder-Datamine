//checked for plus_string
from "%scripts/dagui_library.nut" import *

let { Cost } = require("%scripts/money.nut")
//checked for explicitness
#no-root-fallback
#explicit-this

let { getAllModsCost } = require("%scripts/weaponry/itemInfo.nut")
let { weaponsPurchase } = require("%scripts/weaponry/weaponsPurchase.nut")

local unitsTable = {} //unitName - unitBlock

let function clear() { unitsTable = {} }
let function haveUnits() { return unitsTable.len() > 0 }

let function addUnit(unit) {
  if (!unit)
    return

  unitsTable[unit.name] <- unit
}

local purchaseModifications = @(_unitsArray) null
purchaseModifications = function(unitsArray) {
  if (unitsArray.len() == 0) {
    clear()
    ::showInfoMsgBox(loc("msgbox/all_researched_modifications_bought"), "successfully_bought_mods")
    return
  }

  let curUnit = unitsArray.remove(0)
  weaponsPurchase(
    curUnit,
    {
      afterSuccessfullPurchaseCb = Callback(@() purchaseModifications(unitsArray), this),
      silent = true
    }
  )
}

local checkUnboughtMods = @(_silent = false) null
checkUnboughtMods = function(silent = false) {
  if (!haveUnits())
    return

  local cost = Cost()
  let unitsWithNBMods = []
  let stringOfUnits = []

  foreach (_unitName, unit in unitsTable) {
    let modsCost = getAllModsCost(unit)
    if (modsCost.isZero())
      continue

    cost += modsCost
    unitsWithNBMods.append(unit)
    stringOfUnits.append(colorize("userlogColoredText", ::getUnitName(unit, true)))
  }

  if (unitsWithNBMods.len() == 0)
    return

  if (silent) {
    if (::check_balance_msgBox(cost, null, silent))
      purchaseModifications(unitsWithNBMods)
    return
  }

  ::scene_msg_box("buy_all_available_mods", null,
    loc("msgbox/buy_all_researched_modifications",
      { unitsList = ",".join(stringOfUnits, true), cost = cost.getTextAccordingToBalance() }),
    [["yes", function() {
        if (!::check_balance_msgBox(cost, @()checkUnboughtMods()))
          return

        purchaseModifications(unitsWithNBMods)
      }],
     ["no", @()clear() ]],
      "yes", { cancel_fn = @()clear() })
}

return {
  haveUnits         = haveUnits
  addUnit           = addUnit
  checkUnboughtMods = checkUnboughtMods
}
