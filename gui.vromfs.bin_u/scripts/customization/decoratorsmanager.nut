//-file:plus-string
from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let skinLocations = require("%scripts/customization/skinLocations.nut")
let guidParser = require("%scripts/guidParser.nut")
let unitTypes = require("%scripts/unit/unitTypesList.nut")
let { getDownloadableSkins } = require("%scripts/customization/downloadableDecorators.nut")
let { isUnlockVisible } = require("%scripts/unlocks/unlocksModule.nut")

const DEFAULT_SKIN_NAME = "default"

//code callback
::on_dl_content_skins_invalidate <- function on_dl_content_skins_invalidate() {
  ::g_decorator.clearCache()
}

//code callback
::update_unit_skins_list <- function update_unit_skins_list(unitName) {
  let unit = ::getAircraftByName(unitName)
  if (unit)
    unit.resetSkins()
}

::g_decorator <- {
  cache = {}
  liveDecoratorsCache = {}
  previewedLiveSkinIds = []
  approversUnitToPreviewLiveResource = null

  waitingItemdefs = {}

  addDownloadableLiveSkins = function(skins, unit) {
    let downloadableSkins = getDownloadableSkins(unit.name)
    if (downloadableSkins.len() == 0)
      return skins

    skins = [].extend(skins)

    foreach (itemdefId in downloadableSkins) {
      let resource = ::ItemsManager.findItemById(itemdefId)?.getMetaResource()
      if (resource == null)
        continue

      if (guidParser.isGuid(resource)) { // Live skin
        let foundIdx = skins.findindex(@(s) s?.name == resource)
        let skin = (foundIdx != null)
          ? skins.remove(foundIdx) // Removing to preserve order, because cached skins are already listed.
          : {
              name = resource
              nameLocId = ""
              descLocId = ""

              isDownloadable = true // Needs to be downloaded and cached.
            }
        skin.forceVisible <- true
        skins.append(skin)
      }
      else { // Internal skin
        let skinName = ::g_unlocks.getSkinNameBySkinId(resource)
        let skin = skins.findvalue(@(s) s?.name == skinName)
        if (skin == null)
          continue
        skin.forceVisible <- true
      }
    }

    return skins
  }
}

::g_decorator.clearCache <- function clearCache() {
  ::g_decorator.cache.clear()
  ::g_decorator.clearLivePreviewParams()
}

::g_decorator.clearLivePreviewParams <- function clearLivePreviewParams() {
  ::g_decorator.previewedLiveSkinIds.clear()
  ::g_decorator.approversUnitToPreviewLiveResource = null
}

::g_decorator.getCachedDataByType <- function getCachedDataByType(decType, unitType = null) {
  let id = unitType ? $"proceedData_{decType.name}_{unitType}" : $"proceedData_{decType.name}"
  if (id in ::g_decorator.cache)
    return ::g_decorator.cache[id]

  let data = ::g_decorator.splitDecoratorData(decType, unitType)
  ::g_decorator.cache[id] <- data
  return data
}

::g_decorator.getCachedOrderByType <- function getCachedOrderByType(decType, unitType = null) {
  let data = ::g_decorator.getCachedDataByType(decType, unitType)
  return data.categories
}

::g_decorator.getCachedDecoratorsListByType <- function getCachedDecoratorsListByType(decType) {
  let data = ::g_decorator.getCachedDataByType(decType)
  return data.decoratorsList
}

::g_decorator.getDecorator <- function getDecorator(searchId, decType) {
  local res = null
  if (::u.isEmpty(searchId))
    return res

  res = decType.getSpecialDecorator(searchId)
    || ::g_decorator.getCachedDecoratorsListByType(decType)?[searchId]
    || decType.getLiveDecorator(searchId, this.liveDecoratorsCache)
  if (!res)
    log("Decorators Manager: " + searchId + " was not found in old cache, try update cache")
  return res
}

::g_decorator.getDecoratorById <- function getDecoratorById(searchId) {
  if (::u.isEmpty(searchId))
    return null

  foreach (t in ::g_decorator_type.types) {
    let res = this.getDecorator(searchId, t)
    if (res)
      return res
  }

  return null
}

::g_decorator.getDecoratorByResource <- function getDecoratorByResource(resource, resourceType) {
  return this.getDecorator(resource, ::g_decorator_type.getTypeByResourceType(resourceType))
}

::g_decorator.getCachedDecoratorByUnlockId <- function getCachedDecoratorByUnlockId(unlockId, decType) {
  if (::u.isEmpty(unlockId))
    return null

  let path = "decoratorByUnlockId"
  if (!(path in ::g_decorator.cache))
    ::g_decorator.cache[path] <- {}

  if (unlockId in ::g_decorator.cache[path])
    return this.getDecorator(::g_decorator.cache[path][unlockId], decType)

  let foundDecorator = ::u.search(::g_decorator.getCachedDecoratorsListByType(decType),
      (@(unlockId) function(d) {
        return d.unlockId == unlockId
      })(unlockId))

  if (foundDecorator == null)
    return null

  ::g_decorator.cache[path][unlockId] <- foundDecorator.id
  return foundDecorator
}

::g_decorator.splitDecoratorData <- function splitDecoratorData(decType, unitType) {
  let result = {
    categories = []
    decoratorsList = {}
    fullBlk = null
    catToGroupNames = {} // { [catName]: string[] }
    catToGroups = {}     // { [catName]: { [groupName]: Dec[] } }
  }

  let blk = decType.getBlk()
  if (::u.isEmpty(blk))
    return result

  result.fullBlk = blk

  let prevCategory = ""
  for (local c = 0; c < blk.blockCount(); c++) {
    let dblk = blk.getBlock(c)

    let decorator = ::Decorator(dblk, decType)
    if (unitType != null && !decorator.isAllowedByUnitTypes(unitType))
      continue

    let category = dblk?.category ?? prevCategory
    decorator.category = category

    if (decorator.getCouponItemdefId() != null && !::ItemsManager.findItemById(decorator.getCouponItemdefId()))
      this.waitingItemdefs[decorator.getCouponItemdefId()] <- decorator

    result.decoratorsList[decorator.id] <- decorator

    if (!decorator.isVisible())
      continue

    if (category not in result.catToGroups) {
      result.categories.append(category)
      result.catToGroups[category] <- {}
      result.catToGroupNames[category] <- []
    }

    let group = dblk?.group ?? "other"
    if (group not in result.catToGroups[category]) {
      result.catToGroups[category][group] <- []
      result.catToGroupNames[category].append(group)
    }

    decorator.catIndex = result.catToGroups[category][group].len()
    result.catToGroups[category][group].append(decorator)
  }

  foreach (groupNames in result.catToGroupNames) {
    let idx = groupNames.indexof("other")
    if (idx != null && idx != (groupNames.len() - 1))
      groupNames.append(groupNames.remove(idx))
  }

  return result
}

::g_decorator.getSkinSaveId <- function getSkinSaveId(unitName) {
  return "skins/" + unitName
}

::g_decorator.isAutoSkinAvailable <- function isAutoSkinAvailable(unitName) {
  return unitTypes.getByUnitName(unitName).isSkinAutoSelectAvailable()
}

::g_decorator.getLastSkin <- function getLastSkin(unitName) {
  let unit = ::getAircraftByName(unitName)
  if (!unit.isUsable() && unit.getPreviewSkinId() != "")
    return unit.getPreviewSkinId()
  if (!this.isAutoSkinAvailable(unitName))
    return ::hangar_get_last_skin(unitName)
  return ::load_local_account_settings(this.getSkinSaveId(unitName))
}

::g_decorator.isAutoSkinOn <- @(unitName) !this.getLastSkin(unitName)

::g_decorator.getRealSkin <- function getRealSkin(unitName) {
  let res = this.getLastSkin(unitName)
  return res || this.getAutoSkin(unitName)
}

::g_decorator.setLastSkin <- function setLastSkin(unitName, skinName, needAutoSkin = true) {
  if (!this.isAutoSkinAvailable(unitName))
    return skinName && ::hangar_set_last_skin(unitName, skinName)

  if (needAutoSkin || this.getLastSkin(unitName))
    ::save_local_account_settings(this.getSkinSaveId(unitName), skinName)
  if (!needAutoSkin || skinName)
    ::hangar_set_last_skin(unitName, skinName || this.getAutoSkin(unitName))
}

::g_decorator.setCurSkinToHangar <- function setCurSkinToHangar(unitName) {
  if (!this.isAutoSkinOn(unitName))
    ::hangar_set_last_skin(unitName, this.getRealSkin(unitName))
}

::g_decorator.setAutoSkin <- function setAutoSkin(unitName, needSwitchOn) {
  if (needSwitchOn != this.isAutoSkinOn(unitName))
    this.setLastSkin(unitName, needSwitchOn ? null : ::hangar_get_last_skin(unitName))
}

//default skin will return when no one skin match location
::g_decorator.getAutoSkin <- function getAutoSkin(unitName, isLockedAllowed = false) {
  let list = this.getBestSkinsList(unitName, isLockedAllowed)
  if (!list.len())
    return DEFAULT_SKIN_NAME
  return list[list.len() - 1 - (::SessionLobby.roomId % list.len())] //use last skin when no in session
}

::g_decorator.getBestSkinsList <- function getBestSkinsList(unitName, isLockedAllowed) {
  let unit = ::getAircraftByName(unitName)
  if (!unit)
    return [DEFAULT_SKIN_NAME]

  let misBlk = ::is_in_flight() ? ::get_current_mission_info_cached()
    : ::get_mission_meta_info(unit.testFlight)
  let level = misBlk?.level
  if (!level)
    return [DEFAULT_SKIN_NAME]

  let skinsList = [DEFAULT_SKIN_NAME]
  foreach (skin in unit.getSkins()) {
    if (skin.name == "")
      continue
    if (isLockedAllowed) {
      skinsList.append(skin.name)
      continue
    }
    let decorator = ::g_decorator.getDecorator(unitName + "/" + skin.name, ::g_decorator_type.SKINS)
    if (decorator && decorator.isUnlocked())
      skinsList.append(skin.name)
  }
  return skinLocations.getBestSkinsList(skinsList, unitName, level)
}

::g_decorator.addSkinItemToOption <- function addSkinItemToOption(option, locName, value, decorator, shouldSetFirst = false, needIcon = false) {
  let idx = shouldSetFirst ? 0 : option.items.len()
  option.items.insert(idx, {
    text = locName
    textStyle = ::COLORED_DROPRIGHT_TEXT_STYLE
    image = needIcon ? decorator.getSmallIcon() : null
  })
  option.values.insert(idx, value)
  option.decorators.insert(idx, decorator)
  option.access.insert(idx, {
    isOwn = true
    unlockId  = ""
    canBuy    = false
    price     = ::zero_money
    isVisible = true
    isDownloadable = false
  })
  return option.access[idx]
}

::g_decorator.getSkinsOption <- function getSkinsOption(unitName, showLocked = false, needAutoSkin = true, showDownloadable = false) {
  let descr = {
    items = []
    values = []
    access = []
    decorators = []
    value = 0
  }

  let unit = ::getAircraftByName(unitName)
  if (!unit)
    return descr

  let needIcon = unit.esUnitType == ES_UNIT_TYPE_TANK

  local skins = unit.getSkins()
  if (showDownloadable)
    skins = this.addDownloadableLiveSkins(skins, unit)

  for (local skinNo = 0; skinNo < skins.len(); skinNo++) {
    let skin = skins[skinNo]
    let isDefault = skin.name.len() == 0
    let skinName = isDefault ? DEFAULT_SKIN_NAME : skin.name // skin ID (default skin stored in profile with name 'default')

    let skinBlockName = unitName + "/" + skinName

    let isPreviewedLiveSkin = hasFeature("EnableLiveSkins") && isInArray(skinBlockName, this.previewedLiveSkinIds)
    local decorator = ::g_decorator.getDecorator(skinBlockName, ::g_decorator_type.SKINS)
    if (!decorator) {
      if (isPreviewedLiveSkin)
        decorator = ::Decorator(skinBlockName, ::g_decorator_type.SKINS);
      else
        continue
    }

    let isUnlocked = decorator.isUnlocked()
    let isOwn = isDefault || isUnlocked

    if (!isOwn && !showLocked)
      continue

    let forceVisible = skin?.forceVisible || isPreviewedLiveSkin

    if (!decorator.isVisible() && !forceVisible)
      continue

    let cost = decorator.getCost()
    let hasPrice = !cost.isZero()
    let isVisible = isDefault || isOwn || hasPrice || forceVisible
      || decorator.canBuyCouponOnMarketplace(unit)
      || isUnlockVisible(decorator.unlockBlk)
    if (!isVisible && !::is_dev_version)
      continue

    let access = this.addSkinItemToOption(descr, decorator.getName(), skinName, decorator, false, needIcon)
    access.isOwn = isOwn
    access.unlockId  = !isOwn && decorator.unlockBlk ? decorator.unlockId : ""
    access.canBuy    = decorator.canBuyUnlock(unit)
    access.price     = cost
    access.isVisible = isVisible
    access.isDownloadable = skin?.isDownloadable ?? false
  }

  let hasAutoSkin = needAutoSkin && this.isAutoSkinAvailable(unitName)
  if (hasAutoSkin) {
    let autoSkin = this.getAutoSkin(unitName)
    let decorator = ::g_decorator.getDecorator(unitName + "/" + autoSkin, ::g_decorator_type.SKINS)
    let locName = loc("skins/auto", { skin = decorator ? decorator.getName() : "" })
    this.addSkinItemToOption(descr, locName, null, decorator, true, needIcon)
  }

  let curSkin = this.getLastSkin(unit.name)
  descr.value = ::find_in_array(descr.values, curSkin, -1)
  if (descr.value != -1 || !descr.values.len())
    return descr

  descr.value = 0
  if (curSkin && curSkin != "") //cur skin is not valid, need set valid skin
    this.setLastSkin(unit.name, descr.values[0], hasAutoSkin)

  return descr
}

::g_decorator.onEventSignOut <- function onEventSignOut(_p) {
  ::g_decorator.clearCache()
}

::g_decorator.onEventLoginComplete <- function onEventLoginComplete(_p) {
  ::g_decorator.clearCache()
}

::g_decorator.onEventDecalReceived <- function onEventDecalReceived(p) {
  if (p?.id)
    this.updateDecalVisible(p, ::g_decorator_type.DECALS)
}

::g_decorator.onEventAttachableReceived <- function onEventAttachableReceived(p) {
  if (p?.id)
    this.updateDecalVisible(p, ::g_decorator_type.ATTACHABLES)
}

let function addDecoratorToCachedData(decorator, data) {
  let category = decorator.category
  if (category not in data.catToGroups) {
    data.categories.append(category)
    data.catToGroups[category] <- {}
    data.catToGroupNames[category] <- []
  }

  let group = decorator.group != "" ? decorator.group : "other"
  if (group not in data.catToGroups[category]) {
    data.catToGroups[category][group] <- []
    data.catToGroupNames[category].append(group)
  }

  let groupArr = data.catToGroups[category][group]
  if (groupArr.findindex(@(d) d.id == decorator.id) == null) {
    decorator.catIndex = groupArr.len()
    groupArr.append(decorator)
  }
}

::g_decorator.updateDecalVisible <- function updateDecalVisible(params, decType) {
  let decorId = params.id
  let data = this.getCachedDataByType(decType)
  let decorator = data.decoratorsList?[decorId]

  if (!decorator || !decorator.isVisible())
    return

  addDecoratorToCachedData(decorator, data)

  foreach (unitType in unitTypes.types) {
    if (decorator.isAllowedByUnitTypes(unitType.tag)) {
      let dataByUnitType = this.getCachedDataByType(decType, unitType.tag)
      addDecoratorToCachedData(decorator, dataByUnitType)
    }
  }
}

::g_decorator.onEventUnitBought <- function onEventUnitBought(p) {
  this.applyPreviewSkin(p)
}

::g_decorator.onEventUnitRented <- function onEventUnitRented(p) {
  this.applyPreviewSkin(p)
}

::g_decorator.applyPreviewSkin <- function applyPreviewSkin(params) {
  let unit = ::getAircraftByName(params?.unitName)
  if (!unit)
    return

  let previewSkinId = unit.getPreviewSkinId()
  if (previewSkinId == "")
    return

  this.setLastSkin(unit.name, previewSkinId, false)

  ::save_online_single_job(3210)
  ::save_profile(false)
}

::g_decorator.isPreviewingLiveSkin <- function isPreviewingLiveSkin() {
  return hasFeature("EnableLiveSkins") && ::g_decorator.previewedLiveSkinIds.len() > 0
}

::g_decorator.buildLiveDecoratorFromResource <- function buildLiveDecoratorFromResource(resource, resourceType, itemDef, params) {
  if (!resource || !resourceType)
    return
  let decoratorId = (params?.unitId != null && resourceType == "skin")
    ? ::g_unlocks.getSkinId(params.unitId, resource)
    : resource
  if (decoratorId in ::g_decorator.liveDecoratorsCache)
    return

  let decorator = ::Decorator(decoratorId, ::g_decorator_type.getTypeByResourceType(resourceType))
  decorator.updateFromItemdef(itemDef)
  ::add_rta_localization($"{decoratorId}", itemDef.name)
  ::add_rta_localization($"{decoratorId}/desc", itemDef.description)

  ::g_decorator.liveDecoratorsCache[decoratorId] <- decorator

  // Also replacing a fake skin decorator created by item constructor
  if (resource != decoratorId)
    ::g_decorator.liveDecoratorsCache[resource] <- decorator
}

::g_decorator.onEventItemsShopUpdate <- function onEventItemsShopUpdate(_p) {
  foreach (itemDefId, decorator in this.waitingItemdefs) {
    let couponItem = ::ItemsManager.findItemById(itemDefId)
    if (couponItem) {
      decorator.updateFromItemdef(couponItem.itemDef)
      this.waitingItemdefs[itemDefId] = null
    }
  }
  this.waitingItemdefs = this.waitingItemdefs.filter(@(v) v != null)
}

::subscribe_handler(::g_decorator, ::g_listener_priority.CONFIG_VALIDATION)
