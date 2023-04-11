//-file:plus-string
from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let DataBlock = require("DataBlock")
let { format } = require("string")
let regexp2 = require("regexp2")
let { isPlatformSony, isPlatformXboxOne } = require("%scripts/clientState/platform.nut")
let { getUnlockLocName, getSubUnlockLocName, getUnlockDesc, getFullUnlockDesc, getUnlockCondsDescByCfg,
  getUnlockMultDescByCfg, getUnlockMainCondDesc, getUnlockMainCondDescByCfg, getUnlockMultDesc,
  getUnlockNameText, getUnlockTypeText, getUnlockCostText } = require("%scripts/unlocks/unlocksViewModule.nut")
let { getMainProgressCondition, getProgressBarData, loadMainProgressCondition,
  loadConditionsFromBlk, getMultipliersTable, isBitModeType, isTimeRangeCondition
} = require("%scripts/unlocks/unlocksConditions.nut")
let { getUnlockProgress, getUnlockTypeById } = require("unlocks")
let { getAllUnlocks, getAllUnlocksWithBlkOrder, getUnlockById
} = require("%scripts/unlocks/unlocksCache.nut")
let { getUnlockCost, getUnlockRewardCost } = require("%scripts/unlocks/unlocksModule.nut")

let getEmptyConditionsConfig = @() {
  id = ""
  unlockType = -1
  locId = ""
  locDescId = ""
  locStagesDescId = ""
  useSubUnlockName = false
  hideSubunlocks = false
  curVal = 0
  maxVal = 0
  stages = []
  curStage = -1
  link = ""
  forceExternalBrowser = false
  iconStyle = ""
  iconParams = null
  image = ""
  lockStyle = ""
  imgRatio = 1.0
  playback = null
  type = ""
  conditions = []
  hasCustomUnlockableList = false
  manualOpen = false
  isExpired = false
  needToFillStages = true
  needToAddCurStageToName = true
  useLastStageAsUnlockOpening = false
  additionalStagesDescAsItemCountLocId = ""
  additionalStagesDescAsItemCountId = 0
  additionalStagesDescAsItemCountMax = 0
  names = [] //bit progress names. better to rename it.

  showProgress = true
  getProgressBarData = function() {
    let res = getProgressBarData(this.type, this.curVal, this.maxVal)
    res.show = res.show && this.showProgress
    return res
  }
}

let showNextAwardModeTypes = { // modeTypeName = localizationId
  char_versus_battles_end_count_and_rank_test = "battle_participate_award"
  char_login_count                            = "day_login_award"
}

let function doesUnlockExist(unlockId) {
  return getUnlockTypeById(unlockId) != UNLOCKABLE_UNKNOWN
}

let function checkAwardsAmountPeerSession(res, config, streak, name) {
  local maxStreak = streak

  res.similarAwardNamesList <- {}
  foreach (simAward in config.similarAwards) {
    let simUnlock = getUnlockById(simAward.unlockId)
    let simStreak = simUnlock.stage.param.tointeger() + simAward.stage
    maxStreak = max(simStreak, maxStreak)
    let simAwName = format(name, simStreak)
    if (simAwName in res.similarAwardNamesList)
      res.similarAwardNamesList[simAwName]++
    else
      res.similarAwardNamesList[simAwName] <- 1
  }

  let mainAwName = format(name, streak)
  if (mainAwName in res.similarAwardNamesList)
    res.similarAwardNamesList[mainAwName]++
  else
    res.similarAwardNamesList[mainAwName] <- 1
  res.similarAwardNamesList.maxStreak <- maxStreak
}

let function setDescriptionByUnlockType(config, unlockBlk) {
  let unlockType = ::get_unlock_type(getTblValue("type", unlockBlk, ""))
  if (unlockType == UNLOCKABLE_MEDAL) {
    if (getTblValue("subType", unlockBlk) == "clan_season_reward") {
      let unlock = ::ClanSeasonPlaceTitle.createFromUnlockBlk(unlockBlk)
      config.desc <- unlock.desc()
    }
  }
  else if (unlockType == UNLOCKABLE_DECAL)
    config.desc <- loc("decals/" + unlockBlk.id + "/desc", "")
  else
    config.desc <- loc(unlockBlk.id + "/desc", "")
}

let function setImageByUnlockType(config, unlockBlk) {
  let unlockType = ::get_unlock_type(getTblValue("type", unlockBlk, ""))
  if (unlockType == UNLOCKABLE_MEDAL) {
    if (getTblValue("subType", unlockBlk) == "clan_season_reward") {
      let unlock = ::ClanSeasonPlaceTitle.createFromUnlockBlk(unlockBlk)
      config.iconStyle <- unlock.iconStyle()
      config.iconParams <- unlock.iconParams()
    }
    else
      config.image <- ::get_image_for_unlockable_medal(unlockBlk.id)

    return
  }
  else if (unlockType == UNLOCKABLE_CHALLENGE && unlockBlk?.showAsBattleTask)
    config.image <- unlockBlk?.image
  else if (unlockBlk?.battlePassSeason != null)
    config.image = "#ui/gameuiskin#item_challenge"

  let decoratorType = ::g_decorator_type.getTypeByUnlockedItemType(unlockType)
  if (decoratorType != ::g_decorator_type.UNKNOWN && !::is_in_loading_screen()) {
    let decorator = ::g_decorator.getDecorator(unlockBlk.id, decoratorType)
    config.image <- decoratorType.getImage(decorator)
    config.imgRatio <- decoratorType.getRatio(decorator)
  }
}

::unlocks_punctuation_without_space <- ","

::is_unlocked_scripted <- function is_unlocked_scripted(unlockType, id) {
  local isUnlocked = ::is_unlocked(unlockType, id)
  if (isUnlocked) {
    if (unlockType < 0)
      unlockType = getUnlockTypeById(id)

    if (isPlatformSony && unlockType == UNLOCKABLE_TROPHY_PSN)
      isUnlocked = ::ps4_is_trophy_unlocked(id)
    else if (isPlatformXboxOne && unlockType == UNLOCKABLE_TROPHY_XBOXONE)
      isUnlocked = ::xbox_is_achievement_unlocked(id)
  }
  return isUnlocked
}

::build_unlock_desc <- function build_unlock_desc(item) {
  let mainCond = getMainProgressCondition(item.conditions)
  let progressText = getUnlockMainCondDesc(mainCond, item.curVal, item.maxVal)
  item.showProgress <- progressText != ""
  return item
}

::get_image_for_unlockable_medal <- function get_image_for_unlockable_medal(id, big = false) {
  return big ? $"!@ui/medals/{id}_big.ddsx" : $"!@ui/medals/{id}.ddsx"
}

::build_conditions_config <- function build_conditions_config(blk, showStage = -1) {
  let id = blk.getStr("id", "")
  let config = getEmptyConditionsConfig()
  config.id = id
  config.imgRatio = blk.getReal("aspect_ratio", 1.0)

  config.unlockType = ::get_unlock_type(blk?.type ?? "")
  config.locId = blk.getStr("locId", "")
  config.locDescId = blk.getStr("locDescId", "")
  config.locStagesDescId = blk.getStr("locStagesDescId", "")
  config.useSubUnlockName = blk?.useSubUnlockName ?? false
  config.hideSubunlocks = blk?.hideSubunlocks ?? false
  config.link = ::g_language.getLocTextFromConfig(blk, "link", "")
  config.forceExternalBrowser = blk?.forceExternalBrowser ?? false
  config.playback = blk?.playback
  config.needToFillStages = blk?.needToFillStages ?? true
  config.needToAddCurStageToName = blk?.needToAddCurStageToName ?? true
  config.useLastStageAsUnlockOpening = blk?.useLastStageAsUnlockOpening ?? false
  config.additionalStagesDescAsItemCountLocId = blk?.additionalStagesDescAsItemCountLocId ?? ""
  config.additionalStagesDescAsItemCountId = blk?.additionalStagesDescAsItemCountId ?? 0
  config.additionalStagesDescAsItemCountMax = blk?.additionalStagesDescAsItemCountMax ?? 0
  config.manualOpen = blk?.manualOpen ?? false

  config.iconStyle <- blk?.iconStyle ?? config?.iconStyle
  config.image = blk?.icon ?? ""
  if (config.image != "")
    config.lockStyle = blk?.lockStyle ?? "" // lock, darkened, desaturated, none

  let unlocked = ::is_unlocked_scripted(config.unlockType, id)
  if (config.image == "")
    ::g_unlocks.setRewardIconCfg(config, blk, unlocked)
  if (config.image == "" && !config?.iconData)
    ::g_unlocks.setUnlockIconCfg(config, blk)

  setDescriptionByUnlockType(config, blk)

  if (blk?.isRevenueShare)
    config.isRevenueShare <- true

  if (blk?._puType)
    config._puType <- blk._puType

  if (blk?._acceptTime)
    config._acceptTime <- blk._acceptTime

  if (blk?._controller)
    config._controller <- blk._controller

  foreach (mode in blk % "mode") {
    let modeType = mode?.type ?? ""
    config.type = modeType

    if (config.unlockType == UNLOCKABLE_TROPHY_PSN) {
      //do not show secondary conditions anywhere for psn trophies
      config.conditions = []
      let mainCond = loadMainProgressCondition(mode)
      if (mainCond)
        config.conditions.append(mainCond)
    }
    else
      config.conditions = loadConditionsFromBlk(mode, blk) //-param-pos

    let mainCond = getMainProgressCondition(config.conditions)

    config.hasCustomUnlockableList = getTblValue("hasCustomUnlockableList", mainCond, false)

    if (mainCond && mainCond.values && (mainCond.values.len() > 1 || config.hasCustomUnlockableList))
      config.names = mainCond.values //for easy support old values list

    config.maxVal = mainCond?.num ?? 1
    config.curVal = 0

    if (modeType == "rank")
      config.curVal = ::get_player_rank_by_country(config.country)
    else if (doesUnlockExist(id)) {
      let progress = getUnlockProgress(id)
      if (modeType == "char_player_exp") {
        config.maxVal = ::get_rank_by_exp(progress.maxVal)
        config.curVal = ::get_rank_by_exp(progress.curVal)
      }
      else {
        if (!::g_battle_tasks.isBattleTask(id)) {
          if (config.unlockType == UNLOCKABLE_STREAK) {
            config.minVal <- mode?.minVal ?? 0
            config.maxVal = mode?.maxVal ?? 0
            config.multiplier <- getMultipliersTable(mode)
          }
          else {
            config.maxVal = progress.maxVal
          }
        }
        else if (blk?.__numToControl) {
          config.maxVal = blk.__numToControl
          if (mainCond)
            mainCond.num = blk.__numToControl
        }

        config.curVal = progress.curVal
        config.curStage = (progress?.curStage ?? -1) + 1
      }
    }

    if (isBitModeType(modeType) && mainCond)
      config.curVal = ((1 << mainCond.values.len()) - 1) & config.curVal
    else if (config.curVal > config.maxVal)
      config.curVal = config.maxVal
  }

  if (!unlocked) {
    let cond = config.conditions.findvalue(@(c) isTimeRangeCondition(c.type))
    if (cond)
      config.isExpired = ::get_charserver_time_sec() >= cond.endTime
  }

  let haveBasicRewards = !blk?.aircraftPresentExtMoneyback
  foreach (stage in blk % "stage") {
    let sData = { val = config.type == "char_player_exp"
                          ? ::get_rank_by_exp(stage.getInt("param", 1))
                          : stage.getInt("param", 1)
                  }
    if (haveBasicRewards)
      sData.reward <- getUnlockRewardCost(stage)
    config.stages.append(sData)
  }

  if (showStage >= 0 && blk?.isMultiStage) { // isMultiStage means stages are auto-generated (used only for streaks).
    config.curStage = showStage
    config.maxVal = config.stages[0].val + showStage
  }
  else if (showStage >= 0 && showStage < config.stages.len()) {
    config.curStage = showStage
    config.maxVal = config.stages[showStage].val
  }
  else if (config.useLastStageAsUnlockOpening) {
    config.maxVal = config.stages.top().val
    config.curVal = min(config.curVal, config.maxVal)
  }
  else {
    foreach (stage in config.stages)
      if ((stage.val <= config.maxVal && stage.val > config.curVal)
          || (config.curStage < 0 && stage.val == config.maxVal && stage.val == config.curVal)) {
        config.maxVal = stage.val
      }
  }

  if (!::g_battle_tasks.isBattleTask(id) && config.unlockType != UNLOCKABLE_STREAK
    && blk?.mode.chardType != null && blk?.mode.num != null) {
    config.maxVal = ((blk?.mode.type ?? "") == "totalMissionScore")
      ? (blk.mode.num / 1000) /*PSEUDO_FLOAT_VALUE_MUL*/ : blk.mode.num
  }

  if (haveBasicRewards) {
    let reward = getUnlockRewardCost(blk)
    if (reward > ::zero_money)
      config.reward <- reward
  }

  if (config.unlockType == UNLOCKABLE_WARBOND) {
    let wbAmount = blk?.amount_warbonds
    if (wbAmount) {
      config.rewardWarbonds <- {
        wbName = blk?.userLogId ?? id
        wbAmount = wbAmount
      }
    }
  }

  return config
}

::get_icon_from_unlock_blk <- function get_icon_from_unlock_blk(unlockBlk) {
  let unlockType = ::get_unlock_type(unlockBlk.type)
  let decoratorType = ::g_decorator_type.getTypeByUnlockedItemType(unlockType)
  if (decoratorType != ::g_decorator_type.UNKNOWN && !::is_in_loading_screen()) {
    let decorator = ::g_decorator.getDecorator(unlockBlk.id, decoratorType)
    return decoratorType.getImage(decorator)
  }

  if (unlockType == UNLOCKABLE_AIRCRAFT) {
    let unit = ::getAircraftByName(unlockBlk.id)
    if (unit)
      return unit.getUnlockImage()
  }
  else if (unlockType == UNLOCKABLE_PILOT)
    return $"#ui/images/avatars/{unlockBlk.id}"

  return unlockBlk?.icon
}

::fill_unlock_block <- function fill_unlock_block(obj, config, isForTooltip = false) {
  if (isForTooltip) {
    let icoSize = config?.tooltipImageSize ?? "@profileUnlockIconSize, @profileUnlockIconSize"
    obj.findObject("award_image_sizer").size = icoSize
  }

  let icoObj = obj.findObject("award_image")
  if (config?.isLocked)
    icoObj.effectType = "desaturated"

  ::set_unlock_icon_by_config(icoObj, config, isForTooltip)

  let tObj = obj.findObject("award_title_text")
  tObj.setValue("title" in config ? config.title : "")

  let uObj = obj.findObject("unlock_name")
  uObj.setValue(getTblValue("name", config, ""))

  let amount = getTblValue("amount", config, 1)

  if ("similarAwardNamesList" in config) {
    let maxStreak = getTblValue("maxStreak", config.similarAwardNamesList, 1)
    local repeatText = loc("streaks/rewarded_count", { count = colorize("activeTextColor", amount) })
    if (!::g_unlocks.hasSpecialMultiStageLocId(config.id, maxStreak))
      repeatText = format(loc("streaks/max_streak_amount"), maxStreak.tostring()) + "\n" + repeatText
    obj.findObject("mult_awards_text").setValue(repeatText)
  }

  if (config?.isUnlockDesc ?? false) {
    obj.findObject("desc_text").setValue(getUnlockDesc(config.unlockCfg))
    obj.findObject("mainCond").setValue(getUnlockMainCondDescByCfg(config.unlockCfg))
    obj.findObject("multDesc").setValue(getUnlockMultDescByCfg(config.unlockCfg))
    obj.findObject("conds").setValue(getUnlockCondsDescByCfg(config.unlockCfg))
    obj.findObject("obtain_info").setValue(config?.obtainInfo ?? "")

    if (isForTooltip) {
      let view = ::g_unlock_view.getSubunlocksView(config.unlockCfg)
      if (view) {
        let markup = ::handyman.renderCached("%gui/unlocks/subunlocks.tpl", view)
        let nestObj = obj.findObject("subunlocks")
        nestObj.show(true)
        obj.getScene().replaceContentFromText(nestObj, markup, markup.len(), this)
      }
    }
  }
  else if (config?.type == UNLOCKABLE_STREAK) {
    local cond = ""
    if (config?.minVal && config.maxVal)
      cond = format(loc("streaks/min_max_limit"), config.minVal, config.maxVal)
    else if (config?.minVal)
      cond = format(loc("streaks/min_limit"), config.minVal)
    else if (config.maxVal)
      cond = format(loc("streaks/max_limit"), config.maxVal)

    let desc = ::g_string.implode([config?.desc ?? "", cond, getUnlockMultDesc(config)], "\n")
    obj.findObject("desc_text").setValue(desc)
  }
  else
    obj.findObject("desc_text").setValue(config?.desc ?? "")

  if (("progressBar" in config) && config.progressBar.show) {
    let pObj = obj.findObject("progress")
    pObj.setValue(config.progressBar.value)
    pObj.show(true)
  }

  if (config?.showAsTrophyContent) {
    let isUnlocked = ::is_unlocked_scripted(-1, config?.id)
    local text = loc(isUnlocked ? "mainmenu/itemReceived" : "mainmenu/itemCanBeReceived")
    if (isUnlocked)
      text += "\n" + colorize("badTextColor", loc("mainmenu/receiveOnlyOnce"))
    obj.findObject("state").show(true)
    obj.findObject("state_text").setValue(text)
    obj.findObject("state_icon")["background-image"] = isUnlocked ? "#ui/gameuiskin#favorite" : "#ui/gameuiskin#locked.svg"
  }

  let rObj = obj.findObject("award_text")
  rObj.setValue((config?.rewardText ?? "") != ""
    ? $"{loc("challenge/reward")} {config.rewardText}"
    : "")

  let awMultObj = obj.findObject("award_multiplier")
  if (checkObj(awMultObj)) {
    let show = amount > 1
    awMultObj.show(show)
    if (show)
      awMultObj.findObject("amount_text").setValue("x" + amount)
  }
}

::set_unlock_icon_by_config <- function set_unlock_icon_by_config(obj, config, isForTooltip = false, containerSizePx = 0) {
  let iconStyle = ("iconStyle" in config) ? config.iconStyle : ""
  let iconParams = getTblValue("iconParams", config, null)
  let ratio = (("descrImage" in config) && ("descrImageRatio" in config)) ? config.descrImageRatio : 1.0
  local image = ("descrImage" in config) ? config.descrImage : ""
  if (isForTooltip)
    image = config?.tooltipImage ?? image
  ::LayersIcon.replaceIcon(obj, iconStyle, image, ratio, null, iconParams, config?.iconConfig, containerSizePx)
}

::build_unlock_tooltip_by_config <- function build_unlock_tooltip_by_config(obj, config, handler) {
  let guiScene = obj.getScene()
  guiScene.replaceContent(obj, "%gui/unlocks/unlockBlock.blk", handler)

  obj["min-width"] = "@unlockBlockWidth"

  ::fill_unlock_block(obj, config, true)
}

::default_unlock_data <- {
  id = ""
  type = -1
  title = ""
  name = ""
  image = "#ui/gameuiskin#unlocked.svg"
  image2 = ""
  rewardText = ""
  wp = 0
  gold = 0
  rp = 0
  frp = 0
  exp = 0
  amount = 1 //for multiple awards such as streaks x3, x4...
  aircraft = []
  stage = -1
  desc = ""
  link = ""
  forceExternalBrowser = false
}

::create_default_unlock_data <- function create_default_unlock_data() {
  return clone ::default_unlock_data
}

::build_log_unlock_data <- function build_log_unlock_data(config) {
  let showLocalState = config?.showLocalState ?? true
  let showProgress   = showLocalState && (config?.showProgress ?? false)
  let needTitle      = config?.needTitle ?? true

  let res = ::create_default_unlock_data()
  let realId = config?.unlockId ?? config?.id ?? ""
  let unlockBlk = getUnlockById(realId)

  local uType = config?.unlockType ?? config?.type ?? -1
  if (uType < 0)
    uType = unlockBlk?.type != null ? ::get_unlock_type(unlockBlk.type) : -1
  local stage = ("stage" in config) ? config.stage : -1
  let isMultiStage = unlockBlk?.isMultiStage ? true : false // means stages are auto-generated (used only for streaks).
  let id = config?.displayId ?? realId

  res.desc = null
  local unlockCfg = null
  if (unlockBlk) {
    unlockCfg = ::build_conditions_config(unlockBlk, stage)
    let isProgressing = showProgress
      && (stage == -1 || stage == unlockCfg.curStage)
      && unlockCfg.curVal < unlockCfg.maxVal
    let progressData = isProgressing ? unlockCfg.getProgressBarData() : null
    let haveProgress = getTblValue("show", progressData, false)
    if (haveProgress)
      res.progressBar <- progressData
    unlockCfg = ::build_unlock_desc(unlockCfg)
    unlockCfg.showProgress = unlockCfg.showProgress && haveProgress
    res.link = unlockCfg.link
    res.forceExternalBrowser = unlockCfg.forceExternalBrowser
  }

  res.id = id
  res.type = uType
  res.rewardText = ""
  res.amount = getTblValue("amount", config, res.amount)

  let battleTask = ::g_battle_tasks.getTaskById(realId)
  let isBattleTask = ::g_battle_tasks.isBattleTask(battleTask)
  if (isBattleTask) {
    if (needTitle)
      res.title = loc("unlocks/battletask")
    res.name = ::g_battle_tasks.getLocalizedTaskNameById(battleTask)
    res.image = ::g_battle_task_difficulty.getDifficultyTypeByTask(battleTask).image
    if (::g_battle_tasks.isTaskDone(battleTask))
      res.image2 <- "#ui/gameuiskin#icon_primary_ok.svg"
    else if (::g_battle_tasks.isTaskTimeExpired(battleTask))
      res.image2 <- "#ui/gameuiskin#icon_primary_fail.svg"
  }
  else {
    res.name = getUnlockNameText(uType, id)
    if (needTitle)
      res.title = getUnlockTypeText(uType, id)
  }

  if (config?.showAsTrophyContent)
    res.showAsTrophyContent <- true

  switch (uType) {
    case UNLOCKABLE_SKIN:
    case UNLOCKABLE_ATTACHABLE:
    case UNLOCKABLE_DECAL:
      let decoratorType = ::g_decorator_type.getTypeByUnlockedItemType(uType)
      res.image = decoratorType.userlogPurchaseIcon
      res.name = decoratorType.getLocName(id)

      let decorator = ::g_decorator.getDecorator(id, decoratorType)
      if (decorator && !::is_in_loading_screen()) {
        res.image = decoratorType.getImage(decorator)
        res.descrImage <- res.image
        res.descrImageSize <- decoratorType.getImageSize(decorator)
        res.descrImageRatio <- decoratorType.getRatio(decorator)
      }
      break

    case UNLOCKABLE_MEDAL:
      if (id != "") {
        let imagePath = ::get_image_for_unlockable_medal(id)
        res.image = imagePath
        res.descrImage <- imagePath
        res.descrImageSize <- "128, 128"
        res.tooltipImage <- ::get_image_for_unlockable_medal(id, true)
        res.tooltipImageSize <- "@profileMedalSize, @profileMedalSize"
      }
      break

    case UNLOCKABLE_CHALLENGE:
      let challengeDescription = loc(id + "/desc", "")
      if (challengeDescription && challengeDescription != "")
        res.desc = challengeDescription
      res.image = "#ui/gameuiskin#unlock_challenge"
      res.isLocked <- !::is_unlocked_scripted(-1, id)
      break

    case UNLOCKABLE_SINGLEMISSION:
      res.image = "#ui/gameuiskin#unlock_mission"
      break

    case UNLOCKABLE_TITLE:
    case UNLOCKABLE_ACHIEVEMENT:
      let challengeDescription = loc(id + "/desc", "")
      if (challengeDescription && challengeDescription != "")
        res.desc = challengeDescription
      if (unlockBlk?.battlePassSeason != null) {
       res.descrImage <- "#ui/gameuiskin#item_challenge"
       res.descrImageSize <- "@profileMedalSize, @profileMedalSize"
       res.isLocked <- !::is_unlocked_scripted(-1, id)
      }
      res.image = "#ui/gameuiskin#unlock_achievement"
      break

    case UNLOCKABLE_TROPHY_STEAM:
      res.image = "#ui/gameuiskin#unlock_achievement"
      break

    case UNLOCKABLE_PILOT:
      if (id != "") {
        res.descrImage <- $"#ui/images/avatars/{id}"
        res.descrImageSize <- "100, 100"
        res.needFrame <- true
      }
      break

    case UNLOCKABLE_STREAK:
      local name = loc("streaks/" + id)
      local desc = loc("streaks/" + id + "/desc", "")
      local iconStyle = "streak_" + id

      if (isMultiStage && stage >= 0 && unlockBlk?.stage.param != null) {
        res.stage = stage
        local maxStreak = unlockBlk.stage.param.tointeger() + stage
        if ((config?.similarAwards.len() ?? 0) > 0) {
          checkAwardsAmountPeerSession(res, config, maxStreak, name)
          maxStreak = res.similarAwardNamesList.maxStreak
          name = loc("streaks/" + id + "/multiple", name)
          desc = loc("streaks/" + id + "/multiple/desc", desc)
        }
        else if (::g_unlocks.isUnlockMultiStageLocId(id)) {
          let stageId = ::g_unlocks.getMultiStageId(id, maxStreak)
          name = loc("streaks/" + stageId)
          iconStyle = "streak_" + stageId
        }

        name = format(name, maxStreak)
        desc = format(desc, maxStreak)
      }
      else {
        if (name.indexof("%d") != null)
          name = loc("streaks/" + id + "/multiple")
        if (desc.indexof("%d") != null) {
          let descValue = unlockBlk?.stage ? (unlockBlk?.stage.param ?? 0) : (unlockBlk?.mode.num ?? 0)
          if (descValue > 0)
            desc = format(desc, descValue)
          else
            desc = loc("streaks/" + id + "/multiple/desc", desc)
        }
      }

      res.name = name
      res.desc = desc
      res.image = "#ui/gameuiskin#unlock_streak"
      res.iconStyle <- iconStyle
      res.minVal <- unlockCfg?.minVal ?? 0
      res.maxVal <- unlockCfg?.maxVal ?? 0
      res.multiplier <- unlockCfg?.multiplier ?? {}
      break

    case UNLOCKABLE_AWARD:
      if (isBattleTask)
        break

      res.desc = loc("award/" + id + "/desc", "")
      if (id == "money_back") {
        let unitName = config?.unit
        if (unitName)
          res.desc = "".concat(res.desc, (res.desc == "") ? "" : "\n",
            loc("award/money_back/unit", { unitName = ::getUnitName(unitName) }))
      }
      if (config?.isAerobaticSmoke) {
        res.name = ::ItemsManager.smokeItems.value.findvalue(@(inst) inst.id = config.unlockId)
            ?.getDescriptionTitle() ?? ""
        res.image = "#ui/gameuiskin#item_type_aerobatic_smoke.svg"
      }
      break

    case UNLOCKABLE_AUTOCOUNTRY:
      res.rewardText = loc("award/autocountry")
      break

    case UNLOCKABLE_SLOT:
      let slotNum = getTblValue("slot", config, 0)
      res.name = (slotNum > 0)
        ? loc("options/crewName") + slotNum.tostring()
        : loc("options/crew")
      res.desc = loc("slot/" + id + "/desc", "")
      res.image = "#ui/gameuiskin#log_crew"
      break;

    case UNLOCKABLE_DYNCAMPAIGN:
    case UNLOCKABLE_YEAR:
      if (unlockBlk?.mode.country)
        res.image = ::get_country_icon(unlockBlk.mode.country)
      break

    case UNLOCKABLE_SKILLPOINTS:
      let slotId = getTblValue("slot", config, -1)
      let crew = ::get_crew_by_id(slotId)
      let crewName = crew ? ::g_crew.getCrewName(crew) : loc("options/crew")
      let country = crew ? crew.country : config?.country ?? ""
      let skillPoints = getTblValue("sp", config, 0)
      let skillPointsStr = ::getCrewSpText(skillPoints)

      if (::checkCountry(country, "userlog EULT_*_CREW"))
        res.image2 = ::get_country_icon(country)

      res.desc = crewName + loc("unlocks/skillpoints/desc") + skillPointsStr
      res.image = "#ui/gameuiskin#log_crew"
      break

    case UNLOCKABLE_TROPHY:
      let item = ::ItemsManager.findItemById(id)
      if (item) {
        res.title = getUnlockTypeText(uType, realId)
        res.name = getUnlockNameText(uType, realId)
        res.image = item.getSmallIconName()
        res.desc = item.getDescription()
        res.rewardText = item.getName()
      }
      break

    case UNLOCKABLE_INVENTORY:
      let item = ::ItemsManager.isItemdefId(id) ? ::ItemsManager.getItemOrRecipeBundleById(::to_integer_safe(id)) : null
      if (item) {
        res.title = getUnlockTypeText(uType, realId)
        res.name = item.getName()
        res.image = item.getSmallIconName()
        res.desc = item.getDescription()
      }
      break

    case UNLOCKABLE_WARBOND:
      let wbAmount = config?.warbonds
      let wbStageName = config?.warbondStageName
      let wb = ::g_warbonds.findWarbond(id, wbStageName)
      if (wb != null && wbAmount != null)
        res.rewardText = wb.getPriceText(wbAmount, true, false)
      break
    case UNLOCKABLE_AIRCRAFT:
      let unit = ::getAircraftByName(id)
      if (unit)
        res.image = unit.getUnlockImage()
      break
  }

  if (unlockBlk?.useSubUnlockName)
    res.name = getSubUnlockLocName(unlockBlk)
  else if (unlockBlk?.locId)
    res.name = getUnlockLocName(unlockBlk)

  if ((unlockBlk?.customDescription ?? "") != "")
    res.desc = loc(unlockBlk.customDescription, "")

  if (res.desc == null) {
    let unlockDesc = unlockCfg ? getFullUnlockDesc(unlockCfg) : ""
    if (unlockDesc != "") {
      res.desc = unlockDesc
      res.isUnlockDesc <- true
      res.unlockCfg <- unlockCfg
    }
    else
      res.desc = (id != realId) ? loc($"{id}/desc", "") : ""
  }

  if (uType == UNLOCKABLE_PILOT
      && (unlockBlk?.marketplaceItemdefId || !getUnlockCost(unlockBlk.id).isZero())
      && id != "" && !::is_unlocked_scripted(-1, id)) {
    res.obtainInfo <- unlockBlk?.marketplaceItemdefId
      ? colorize("userlogColoredText", loc("shop/pilot/coupon/info"))
      : getUnlockCostText(unlockCfg)
    res.desc = "\n".join([res.desc, res.obtainInfo], true)
  }

  let rewards = { wp = "amount_warpoints", exp = "amount_exp", gold = "amount_gold" }
  local rewardsWasLoadedFromLog = false;
  foreach (nameInConfig, _nameInBlk in rewards) //try load rewards data from log first because
    if (nameInConfig in config) {                //award message can haven't appropriate unlock
      res[nameInConfig] = config[nameInConfig]
      rewardsWasLoadedFromLog = true;
    }
  if ("exp" in config) {
    res.frp = config.exp
    rewardsWasLoadedFromLog = true;
  }

  if ("userLogId" in config) {
    let itemId = config.userLogId
    let item = ::ItemsManager.findItemById(itemId)
    if (item) {
      res.rewardText += item.getName()
      res.rewardText += "\n" + item.getNameMarkup()
    }
  }

  //check rewards and stages
  if (unlockBlk) {
    local rBlock = DataBlock()
    rewardsWasLoadedFromLog = rewardsWasLoadedFromLog || unlockBlk?.aircraftPresentExtMoneyback == true

    // stage >= 0 means there are stages.
    // isMultiStage=false means stages are hard-coded (usually used for challenges and achievements).
    // isMultiStage=true means stages are auto-generated (usually used only for streaks).
    // there are streaks with stages and isMultiStage=false and they should have own name, icon, etc
    if (stage >= 0 && !isMultiStage && uType != UNLOCKABLE_STREAK) {
      local curStage = -1
      for (local j = 0; j < unlockBlk.blockCount(); j++) {
        let sBlock = unlockBlk.getBlock(j)
        if (sBlock.getBlockName() != "stage")
          continue

        curStage++
        if (curStage == stage) {
          rBlock = sBlock
          if (unlockCfg.needToAddCurStageToName)
            res.name = $"{res.name} {::get_roman_numeral(stage + 1)}"
          res.stage <- stage
          res.unlocked <- true
          res.iconStyle <- "default_unlocked"
        }
        else if (curStage > stage) {
          if (stage >= 0) {
            res.unlocked = false
            res.iconStyle <- "default_locked_stage_" + (stage + 1)
          }
          break
        }
      }
      if (curStage != stage)
        stage = -1
    }
    if (stage < 0)  //no stages
      rBlock = unlockBlk

    if (rBlock?.iconStyle)
      res.iconStyle <- rBlock.iconStyle

    if (getTblValue("descrImage", res, "") == "") {
      let icon = ::get_icon_from_unlock_blk(unlockBlk)
      if (icon)
        res.descrImage <- icon
      else if (getTblValue("iconStyle", res, "") == "")
        res.iconStyle <- !showLocalState || ::is_unlocked_scripted(uType, id) ? "default_unlocked"
          : "default_locked"
    }

    if (!rewardsWasLoadedFromLog) {
      foreach (nameInConfig, nameInBlk in rewards) {
        res[nameInConfig] = rBlock?[nameInBlk] ?? 0
        if (type(res[nameInConfig]) == "instance")
          res[nameInConfig] = res[nameInConfig].x
      }
      if (rBlock?.amount_exp)
        res.frp = (type(rBlock.amount_exp) == "instance") ? rBlock.amount_exp.x : rBlock.amount_exp
    }

    let popupImage = ::g_language.getLocTextFromConfig(rBlock, "popupImage", "")
    if (popupImage != "")
      res.popupImage <- popupImage
  }

  if (showLocalState) {
    let cost = ::Cost(getTblValue("wp", res, 0),
                        getTblValue("gold", res, 0),
                        getTblValue("frp", res, 0),
                        getTblValue("rp", res, 0))

    res.rewardText = colorize("activeTextColor", res.rewardText + cost.tostring())
    res.showShareBtn <- true
  }

  if ("miscMsg" in config) //for misc params from userlog
    res.miscParam <- config.miscMsg
  return res
}

::get_next_award_text <- function get_next_award_text(unlockId) {
  local res = ""
  if (!hasFeature("ShowNextUnlockInfo"))
    return res

  let unlockBlk = getUnlockById(unlockId)
  if (!unlockBlk)
    return res

  local modeType = null
  local num = 0
  foreach (mode in unlockBlk % "mode") {
    let mType = mode.getStr("type", "")
    if (mType in showNextAwardModeTypes) {
      modeType = mType
      num = mode.getInt("num", 0)
      break
    }
    if (mType == "char_unlocks") { //for unlocks unlocked by other unlock
      foreach (uId in mode % "unlock") {
        res = ::get_next_award_text(uId)
        if (res != "")
          return res
      }
      break
    }
  }
  if (!modeType)
    return res

  local nextUnlock = null
  local nextStage = -1
  local nextNum = -1
  foreach (cb in getAllUnlocksWithBlkOrder())
    if (!cb.hidden || (cb.type && ::get_unlock_type(cb.type) == UNLOCKABLE_AUTOCOUNTRY))
      foreach (modeIdx, mode in cb % "mode")
        if (mode.getStr("type", "") == modeType) {
          let n = mode.getInt("num", 0)
          if (n > num && (!nextUnlock || n < nextNum)) {
            nextUnlock = cb
            nextNum = n
            nextStage = modeIdx
            break
          }
        }
  if (!nextUnlock)
    return res

  let diff = nextNum - num
  local locId = showNextAwardModeTypes[modeType]
  locId += "/" + ((diff == 1) ? "one_more" : "several")

  let unlockData = ::build_log_unlock_data({ id = nextUnlock.id, stage = nextStage })
  res = loc("next_award", { awardName = unlockData.name })
  if (unlockData.rewardText != "")
    res += loc("ui/colon") + "\n" + loc(locId, { amount = diff
                                                     reward = unlockData.rewardText
                                                   })
  return res
}

::combineSimilarAwards <- function combineSimilarAwards(awardsList) {
  let res = []

  foreach (award in awardsList) {
    local found = false
    if ("unlockType" in award && award.unlockType == UNLOCKABLE_STREAK) {
      let unlockId = award.unlockId
      let isMultiStageLoc = ::g_unlocks.isUnlockMultiStageLocId(unlockId)
      let stage = getTblValue("stage", award, 0)
      let hasSpecialMultiStageLoc = ::g_unlocks.hasSpecialMultiStageLocIdByStage(unlockId, stage)
      foreach (approvedAward in res) {
        if (unlockId != approvedAward.unlockId)
          continue
        if (isMultiStageLoc) {
          let approvedStage = getTblValue("stage", approvedAward, 0)
          if (stage != approvedStage
            && (hasSpecialMultiStageLoc || ::g_unlocks.hasSpecialMultiStageLocIdByStage(unlockId, approvedStage)))
           continue
        }
        approvedAward.amount++
        approvedAward.similarAwards.append(award)
        foreach (name in ["wp", "exp", "gold"])
          if (name in approvedAward && name in award)
            approvedAward[name] += award[name]
        found = true
        break
      }
    }

    if (found)
      continue

    res.append(award)
    let tbl = res.top()
    tbl.amount <- 1
    tbl.similarAwards <- []
  }

  return res
}

::is_any_award_received_by_mode_type <- function is_any_award_received_by_mode_type(modeType) {
  foreach (cb in getAllUnlocks())
    foreach (mode in cb % "mode") {
      if (mode.type == modeType && cb.id && ::is_unlocked_scripted(-1, cb.id))
        return true
      break
    }
  return false
}

::req_unlock_by_client <- function req_unlock_by_client(id, disableLog) {
  let unlock = getUnlockById(id)
  let featureName =  getTblValue("check_client_feature", unlock, null)
  if (featureName == null || hasFeature(featureName))
      return ::req_unlock(id, disableLog)

  return -1
}

::g_unlocks <- {
  unitNameReg = regexp2(@"[.*/].+")
  skinNameReg = regexp2(@"^[^/]*/")

  multiStageLocId =
  {
    multi_kill_air =    { [2] = "double_kill_air",    [3] = "triple_kill_air",    def = "multi_kill_air" }
    multi_kill_ship =   { [2] = "double_kill_ship",   [3] = "triple_kill_ship",   def = "multi_kill_ship" }
    multi_kill_ground = { [2] = "double_kill_ground", [3] = "triple_kill_ground", def = "multi_kill_ground" }
  }

  function setRewardIconCfg(cfg, blk, unlocked) {
    if (!blk?.userLogId)
      return

    let item = ::ItemsManager.findItemById(blk.userLogId)
    if (item?.iType != itemType.TROPHY)
      return

    let content = item.getContent()
    if (content.len() > 1) {
      cfg.iconData <- item.getIcon()
      cfg.isTrophyLocked <- !unlocked
      if (!unlocked)
        cfg.trophyId <- item.id
      return
    }

    let prize = item.getTopPrize()
    if (prize?.unlock && getUnlockTypeById(prize.unlock) ==  UNLOCKABLE_PILOT) {
      cfg.image <- $"#ui/images/avatars/{prize.unlock}"
      cfg.isTrophyLocked <- !unlocked
      return
    }

    if (prize?.resourceType && prize?.resource) {
      let decType = ::g_decorator_type.getTypeByResourceType(prize.resourceType)
      let decorator = ::g_decorator.getDecorator(prize.resource, decType)
      let image = decType.getImage(decorator)
      if (image == "")
        return

      cfg.image <- image
      cfg.isTrophyLocked <- !unlocked
    }
  }

  function setUnlockIconCfg(cfg, blk) {
    let icon = ::get_icon_from_unlock_blk(blk)
    if (icon)
      cfg.image = icon
    else
      setImageByUnlockType(cfg, blk)
  }
}

::g_unlocks.getPlaneBySkinId <- function getPlaneBySkinId(id) {
  return this.unitNameReg.replace("", id)
}

::g_unlocks.getSkinNameBySkinId <- function getSkinNameBySkinId(id) {
  return this.skinNameReg.replace("", id)
}

::g_unlocks.getSkinId <- function getSkinId(unitName, skinName) {
  return unitName + "/" + skinName
}

::g_unlocks.isDefaultSkin <- function isDefaultSkin(id) {
  return this.getSkinNameBySkinId(id) == "default"
}

::g_unlocks.isUnlockMultiStageLocId <- function isUnlockMultiStageLocId(unlockId) {
  return unlockId in this.multiStageLocId
}

::g_unlocks.getUnlockRepeatInARow <- function getUnlockRepeatInARow(unlockId, stage) {
  return stage + (getUnlockById(unlockId)?.stage.param ?? 0)
}

//has not default multistage id. Used to combine similar unlocks.
::g_unlocks.hasSpecialMultiStageLocId <- function hasSpecialMultiStageLocId(unlockId, repeatInARow) {
  return this.isUnlockMultiStageLocId(unlockId) && repeatInARow in this.multiStageLocId[unlockId]
}

::g_unlocks.hasSpecialMultiStageLocIdByStage <- function hasSpecialMultiStageLocIdByStage(unlockId, stage) {
  return this.hasSpecialMultiStageLocId(unlockId, this.getUnlockRepeatInARow(unlockId, stage))
}

::g_unlocks.getMultiStageId <- function getMultiStageId(unlockId, repeatInARow) {
  if (!this.isUnlockMultiStageLocId(unlockId))
    return unlockId
  let config = this.multiStageLocId[unlockId]
  return getTblValue(repeatInARow, config) || getTblValue("def", config, unlockId)
}