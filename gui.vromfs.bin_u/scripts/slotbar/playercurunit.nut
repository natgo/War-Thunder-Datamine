local { loadModel } = require("scripts/hangarModelLoadManager.nut")
local unitTypes = require("scripts/unit/unitTypesList.nut")

local isFallbackUnitInHangar = null
local hangarDefaultUnits = {}

local function getCountryHangarDefaultUnit(countryId, esUnitType) {
  if (hangarDefaultUnits?[countryId] == null) {
    hangarDefaultUnits[countryId] <- {}
    foreach (needReserveUnit in [ true, false ]) {
      foreach (u in ::all_units)
        if (u.isVisibleInShop() && u.shopCountry == countryId
            && (!needReserveUnit || ::isUnitDefault(u))
            && hangarDefaultUnits[countryId]?[u.esUnitType] == null)
          hangarDefaultUnits[countryId][u.esUnitType] <- u
      if (hangarDefaultUnits[countryId].len() == unitTypes.types.len() - 1)
        break
    }
  }
  return hangarDefaultUnits[countryId]?[esUnitType]
    ?? hangarDefaultUnits[countryId].findvalue(@(u) true)
}

local function getFallbackUnitForHangar(params) {
  // Trying a currently loaded hangar unit
  local countryId = params?.country ?? ::get_profile_country_sq()
  local curHangarUnit = ::getAircraftByName(::hangar_get_current_unit_name())
  if (curHangarUnit?.shopCountry == countryId
      && (params?.slotbarUnits ?? []).indexof(curHangarUnit) != null)
    return curHangarUnit

  // Trying any other unit from country slotbar
  local esUnitType = curHangarUnit?.esUnitType ?? ::ES_UNIT_TYPE_AIRCRAFT
  foreach (needCheckUnitType in [ true, false ])
    foreach (unit in (params?.slotbarUnits ?? []))
      if (!needCheckUnitType || unit.esUnitType == esUnitType)
        return unit

  // Country default unit (for countries with empty slotbar)
  return getCountryHangarDefaultUnit(countryId, esUnitType)
}

local showedUnit = persist("showedUnit", @() ::Watched(null))

local getShowedUnitName = @() showedUnit.value?.name ??
  (isFallbackUnitInHangar ? "" : ::hangar_get_current_unit_name())

local getShowedUnit = @() showedUnit.value ??
  (isFallbackUnitInHangar ? null : ::getAircraftByName(::hangar_get_current_unit_name()))

local function setShowUnit(unit, params = null) {
  showedUnit(unit)
  isFallbackUnitInHangar = unit == null
  loadModel(unit?.name ?? getFallbackUnitForHangar(params)?.name ?? "")
}

local function getPlayerCurUnit() {
  local unit = null
  if (::is_in_flight())
    unit = ::getAircraftByName(::get_player_unit_name())
  if (!unit || unit.name == "dummy_plane")
    unit = showedUnit.value ?? ::getAircraftByName(::hangar_get_current_unit_name())
  return unit
}


return {
  showedUnit
  getShowedUnitName
  getShowedUnit
  setShowUnit
  getPlayerCurUnit
}


