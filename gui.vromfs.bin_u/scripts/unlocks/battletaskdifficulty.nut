//-file:plus-string
from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let enums = require("%sqStdLibs/helpers/enums.nut")
let { secondsToHours, hoursToString } = require("%scripts/time.nut")

::g_battle_task_difficulty <- {
  types = []
  template = {}
  cache = {
    byName = {}
    byExecOrder = {}
    byId = {}
  }
}

::g_battle_task_difficulty.template <- {
  getLocName = @() loc($"battleTasks/{this.timeParamId}/name")
  getDifficultyGroup = @() this.timeParamId

  name = ""
  timeParamId = ""
  userlogHeaderName = ""
  image = null
  executeOrder = -1
  lastGenerationId = 0
  lastGenTimeSuccess = -1
  lastGenTimeFailure = -1
  generationPeriodSec = -1
  lastGenExpireTime = -1
  expireTimeByGen = null
  isTimeExpired = @(task) this.hasTimer && this.getTimeLeft(task) < 0
  showSeasonIcon = false
  hasTimer = true
  userstatUnlockId = ""

  expireProcessed = null
  function notifyTimeExpired(task) {
    let generationId = ::g_battle_tasks.getGenerationIdInt(task)
    if (this.expireProcessed?[generationId] ?? false)
      return

    if (generationId != 0) {
      this.expireProcessed = this.expireProcessed ?? {}
      this.expireProcessed[generationId] <- true
    }
    ::broadcastEvent("BattleTasksTimeExpired")
  }

  function getTimeLeft(task) {
    let generationId = ::g_battle_tasks.getGenerationIdInt(task)
    let expireTime = this.expireTimeByGen?[generationId] ?? this.lastGenExpireTime
    return expireTime - ::get_charserver_time_sec()
  }

  function getTimeLeftText(task) {
    let timeLeft = this.getTimeLeft(task)
    if (timeLeft < 0)
      return ""

    return hoursToString(secondsToHours(timeLeft), false, true, true)
  }
}

enums.addTypesByGlobalName("g_battle_task_difficulty", {
  EASY = {
    image = "#ui/gameuiskin#battle_tasks_easy.svg"
    timeParamId = "daily"
    executeOrder = 0
    userstatUnlockId = "easy_tasks_streak"
  }

  MEDIUM = {
    image = "#ui/gameuiskin#battle_tasks_middle.svg"
    timeParamId = "daily"
    executeOrder = 1
    userstatUnlockId = "medium_tasks_streak"
  }

  HARD = {
    image = "#ui/gameuiskin#hard_task_medal3.svg"
    showSeasonIcon = true
    timeParamId = "specialTasks"
    hasTimer = false
    userstatUnlockId = "hard_tasks_streak"
  }

  UNKNOWN = {
    hasTimer = false
    getTimeLeft = @(_task) -1
  }
}, null, "name")

::g_battle_task_difficulty.types.sort(@(a, b) a.executeOrder <=> b.executeOrder)

::g_battle_task_difficulty.getDifficultyTypeByName <- function getDifficultyTypeByName(typeName) {
  return enums.getCachedType("name", typeName, ::g_battle_task_difficulty.cache.byName,
    ::g_battle_task_difficulty, ::g_battle_task_difficulty.UNKNOWN)
}

::g_battle_task_difficulty.getDifficultyFromTask <- function getDifficultyFromTask(task) {
  return getTblValue("_puType", task, "").toupper()
}

::g_battle_task_difficulty.getDifficultyTypeByTask <- function getDifficultyTypeByTask(task) {
  return this.getDifficultyTypeByName(this.getDifficultyFromTask(task))
}

//Not recomended to use. Only for deleted tasks in which we cannot identify difficulty
::g_battle_task_difficulty.getDifficultyTypeById <- function getDifficultyTypeById(taskId) {
  if (taskId in this.cache.byId)
    return this.getDifficultyTypeByName(this.cache.byId[taskId])

  let res = this.types.findvalue(function(v) {
    let n = v.name.tolower()
    let m = taskId.slice(0, n.len()).tolower()
    return n == m
  })

  this.cache.byId[taskId] <- res != null ? res.name : this.UNKNOWN.name
  return res
}

::g_battle_task_difficulty.getRequiredDifficultyTypeDone <- function getRequiredDifficultyTypeDone(diff) {
  local res = null
  if (diff.executeOrder > 0)
    res = ::u.search(this.types, @(t) t.executeOrder == (diff.executeOrder - 1))

  return res ?? ::g_battle_task_difficulty.UNKNOWN
}

::g_battle_task_difficulty.getRefreshTimeForAllTypes <- function getRefreshTimeForAllTypes(tasksArray, overrideStatus = false) {
  let processedTimeParamIds = []
  if (!overrideStatus)
    foreach (task in tasksArray) {
      let t = this.getDifficultyTypeByTask(task)
      ::u.appendOnce(t.timeParamId, processedTimeParamIds)
    }

  let resultArray = []
  foreach (t in this.types) {
    if (isInArray(t.timeParamId, processedTimeParamIds))
      continue

    processedTimeParamIds.append(t.timeParamId)

    let timeText = t.getTimeLeftText(null)
    if (timeText != "")
      resultArray.append(t.getLocName() + loc("ui/parentheses/space", { text = timeText }))
  }

  return resultArray
}

::g_battle_task_difficulty.canPlayerInteractWithDifficulty <- function canPlayerInteractWithDifficulty(diff, tasksArray, overrideStatus = false) {
  if (overrideStatus)
    return true

  let reqDiffDone = this.getRequiredDifficultyTypeDone(diff)
  if (reqDiffDone == ::g_battle_task_difficulty.UNKNOWN)
    return true

  foreach (task in tasksArray) {
    let taskDifficulty = this.getDifficultyTypeByTask(task)
    if (taskDifficulty != reqDiffDone)
      continue

    if (!::g_battle_tasks.isBattleTask(task) || !::g_battle_tasks.isTaskActual(task))
      continue

    if (::g_battle_tasks.isTaskDone(task))
      continue

    if (diff.executeOrder <= taskDifficulty.executeOrder)
      continue

    return false
  }

  return true
}

::g_battle_task_difficulty.updateTimeParamsFromBlk <- function updateTimeParamsFromBlk(blk) {
  foreach (t in this.types) {
    t.lastGenerationId    = blk?[$"{t.timeParamId}PersonalUnlocks_lastGenerationId"]            ?? 0
    t.lastGenTimeSuccess  = blk?[$"{t.timeParamId}PersonalUnlocks_lastGenerationTimeOnSuccess"] ?? -1
    t.lastGenTimeFailure  = blk?[$"{t.timeParamId}PersonalUnlocks_lastGenerationTimeOnFailure"] ?? -1
    t.generationPeriodSec = blk?[$"{t.timeParamId}PersonalUnlocks_CUSTOM_generationPeriodSec"]  ?? -1

    t.lastGenExpireTime = (t.lastGenTimeSuccess != -1 && t.generationPeriodSec != -1)
      ? (t.lastGenTimeSuccess + t.generationPeriodSec)
      : -1

    if (t.lastGenerationId != 0 && t.lastGenExpireTime != -1) {
      t.expireTimeByGen = t.expireTimeByGen ?? {}
      t.expireTimeByGen[t.lastGenerationId] <- t.lastGenExpireTime

      t.expireProcessed = t.expireProcessed ?? {}
      t.expireProcessed[t.lastGenerationId] <- t.lastGenExpireTime < ::get_charserver_time_sec()
    }
  }
}

::g_battle_task_difficulty.withdrawTasksArrayByDifficulty <- function withdrawTasksArrayByDifficulty(diff, tasks) {
  return ::u.filter(tasks, @(task) diff == ::g_battle_task_difficulty.getDifficultyTypeByTask(task))
}

::g_battle_task_difficulty.getDefaultDifficultyGroup <- function getDefaultDifficultyGroup() {
  return this.EASY.getDifficultyGroup()
}
