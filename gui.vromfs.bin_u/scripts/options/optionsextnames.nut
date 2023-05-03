//checked for plus_string
from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { addOptionMode, addUserOption, setGuiOptionsMode, getGuiOptionsMode,
  set_gui_option, get_gui_option
} = require("guiOptions")

global enum optionControlType {
  LIST
  BIT_LIST
  SLIDER
  CHECKBOX
  EDITBOX
  HEADER
  BUTTON
}

global enum AIR_MOUSE_USAGE {
  NOT_USED    = 0x0001
  AIM         = 0x0002
  JOYSTICK    = 0x0004
  RELATIVE    = 0x0008
  VIEW        = 0x0010
}

::OPTIONS_MODE_GAMEPLAY <- 1
::OPTIONS_MODE_TRAINING <- 2
::OPTIONS_MODE_CAMPAIGN <- 3
::OPTIONS_MODE_SINGLE_MISSION <- 4
::OPTIONS_MODE_DYNAMIC <- 5
::OPTIONS_MODE_USER_MISSION <- 6
::OPTIONS_MODE_MP_DOMINATION <- 7
::OPTIONS_MODE_MP_SKIRMISH <- 8
::OPTIONS_MODE_SEARCH <- 9

::USEROPT_LANGUAGE <- 0
::USEROPT_VIEWTYPE <- 1
::USEROPT_INGAME_VIEWTYPE <- 2
    ///_INSERT_OPTIONS_HERE_
::USEROPT_SPEECH_TYPE <- 3
::USEROPT_USE_TRACKIR_ZOOM <- 4
::USEROPT_INDICATED_SPEED_TYPE <- 5
::USEROPT_INVERTY <- 6
::USEROPT_INVERTY_TANK <- 7
::USEROPT_INVERTY_SHIP <- 8
::USEROPT_INVERTY_HELICOPTER <- 9
::USEROPT_INVERTY_HELICOPTER_GUNNER <- 10
::USEROPT_INVERTY_SUBMARINE <- 13
::USEROPT_INVERTX <- 14
::USEROPT_GAMEPAD_ENGINE_DEADZONE <- 15
::USEROPT_GAMEPAD_VIBRATION_ENGINE <- 16
::USEROPT_GAMEPAD_GYRO_TILT_CORRECTION <- 17
::USEROPT_JOY_MIN_VIBRATION <- 18
::USEROPT_FIX_GUN_IN_MOUSE_LOOK <- 19
::USEROPT_INVERTY_SPECTATOR <- 20
::USEROPT_JOYFX <- 21
::USEROPT_INVERTCAMERAY <- 22
::USEROPT_AUTOMATIC_TRANSMISSION_TANK <- 23
::USEROPT_WHEEL_CONTROL_SHIP <- 24
::USEROPT_SEPERATED_ENGINE_CONTROL_SHIP <- 25
::USEROPT_BULLET_FALL_INDICATOR_SHIP <- 26
::USEROPT_BULLET_FALL_SOUND_SHIP <- 27
::USEROPT_SINGLE_SHOT_BY_TURRET <- 28
::USEROPT_SHIP_COMBINE_PRI_SEC_TRIGGERS <- 29
::USEROPT_AUTO_TARGET_CHANGE_SHIP <- 30
::USEROPT_REALISTIC_AIMING_SHIP <- 31
::USEROPT_FOLLOW_BULLET_CAMERA <- 32
::USEROPT_ZOOM_FOR_TURRET <- 33
::USEROPT_SUBTITLES <- 34
::USEROPT_SUBTITLES_RADIO <- 35
::USEROPT_VOICE_MESSAGE_VOICE <- 36
::USEROPT_MEASUREUNITS_SPEED <- 37
::USEROPT_MEASUREUNITS_ALT <- 38
::USEROPT_MEASUREUNITS_DIST <- 39
::USEROPT_MEASUREUNITS_CLIMBSPEED <- 40
::USEROPT_MEASUREUNITS_TEMPERATURE <- 41
::USEROPT_MEASUREUNITS_WING_LOADING <- 42
::USEROPT_MEASUREUNITS_POWER_TO_WEIGHT_RATIO <- 43
::USEROPT_AUTOSAVE_REPLAYS <- 44
::USEROPT_HIDE_MOUSE_SPECTATOR <- 45
::USEROPT_XRAY_DEATH <- 46
::USEROPT_XRAY_KILL <- 47
::USEROPT_CAMERA_SHAKE_MULTIPLIER <- 48
::USEROPT_VR_CAMERA_SHAKE_MULTIPLIER <- 49
::USEROPT_VIBRATION <- 50
::USEROPT_SOUND_ENABLE <- 51
::USEROPT_SOUND_SPEAKERS_MODE <- 52
::USEROPT_VOLUME_MASTER <- 53
::USEROPT_VOLUME_MUSIC <- 54
::USEROPT_VOLUME_MENU_MUSIC <- 55
::USEROPT_VOLUME_SFX <- 56
::USEROPT_VOLUME_GUNS <- 57
::USEROPT_VOLUME_TINNITUS <- 58
::USEROPT_HANGAR_SOUND <- 59
::USEROPT_VOLUME_RADIO <- 60
::USEROPT_VOLUME_DIALOGS <- 61
::USEROPT_VOLUME_ENGINE <- 62
::USEROPT_VOLUME_MY_ENGINE <- 63
::USEROPT_VOLUME_VOICE_IN <- 64
::USEROPT_VOLUME_VOICE_OUT <- 65
::USEROPT_AAA_TYPE <- 66
::USEROPT_SITUATION <- 67
::USEROPT_CLIME <- 68
::USEROPT_TIME <- 69
::USEROPT_ALTITUDE <- 70
::USEROPT_AIRCRAFT <- 71
::USEROPT_WEAPONS <- 72
::USEROPT_BULLETS0 <- 73
::USEROPT_BULLETS1 <- 74
::USEROPT_BULLETS2 <- 75
::USEROPT_BULLETS3 <- 76
::USEROPT_BULLETS4 <- 77
::USEROPT_BULLETS5 <- 78
::USEROPT_BULLET_COUNT0 <- 79
::USEROPT_BULLET_COUNT1 <- 80
::USEROPT_BULLET_COUNT2 <- 81
::USEROPT_BULLET_COUNT3 <- 82
::USEROPT_BULLET_COUNT4 <- 83
::USEROPT_BULLET_COUNT5 <- 84
::USEROPT_SKIN <- 85
::USEROPT_USER_SKIN <- 86
::USEROPT_TANK_SKIN_CONDITION <- 87
::USEROPT_TANK_CAMO_SCALE <- 88
::USEROPT_TANK_CAMO_ROTATION <- 89
::USEROPT_DIFFICULTY <- 90
::USEROPT_NUM_FRIENDLIES <- 91
::USEROPT_NUM_ENEMIES <- 92
::USEROPT_TIME_LIMIT <- 93
::USEROPT_KILL_LIMIT <- 94
::USEROPT_NUM_PLAYERS <- 95
::USEROPT_YEAR <- 96
::USEROPT_TIME_SPAWN <- 97
::USEROPT_DMP_MAP <- 98
::USEROPT_DYN_MAP <- 99
::USEROPT_DYN_ZONE <- 100
::USEROPT_DYN_ALLIES <- 101
::USEROPT_DYN_ENEMIES <- 102
::USEROPT_DYN_SURROUND <- 103
::USEROPT_DYN_FL_ADVANTAGE <- 104
::USEROPT_DYN_WINS_TO_COMPLETE <- 105
::USEROPT_NUM_ATTEMPTS <- 106
::USEROPT_LIMITED_FUEL <- 107
::USEROPT_LIMITED_AMMO <- 108
::USEROPT_FRIENDLY_SKILL <- 109
::USEROPT_ENEMY_SKILL <- 110
::USEROPT_MODIFICATIONS <- 111
::USEROPT_MP_TEAM <- 112
::USEROPT_MP_TEAM_COUNTRY <- 113
::USEROPT_MP_TEAM_COUNTRY_RAND <- 114
::USEROPT_TICKETS <- 115
::USEROPT_GAME_HUD <- 116
::USEROPT_FONTS_CSS <- 117
::USEROPT_ENABLE_CONSOLE_MODE <- 118
::USEROPT_SEARCH_GAMEMODE <- 119
::USEROPT_SEARCH_GAMEMODE_CUSTOM <- 120
::USEROPT_SEARCH_DIFFICULTY <- 121
::USEROPT_CONTROLS_PRESET <- 122
::USEROPT_AILERONS_MULTIPLIER <- 123
::USEROPT_ELEVATOR_MULTIPLIER <- 124
::USEROPT_RUDDER_MULTIPLIER <- 125
::USEROPT_GAMMA <- 126
::USEROPT_TIME_BETWEEN_RESPAWNS <- 127
::USEROPT_OPTIONAL_TAKEOFF <- 128
::USEROPT_LOAD_FUEL_AMOUNT <- 129
::USEROPT_GUN_TARGET_DISTANCE <- 130
::USEROPT_BOMB_ACTIVATION_TIME <- 131
::USEROPT_BOMB_SERIES <- 132
::USEROPT_DEPTHCHARGE_ACTIVATION_TIME <- 133
::USEROPT_COUNTERMEASURES_SERIES <- 134
::USEROPT_COUNTERMEASURES_SERIES_PERIODS <- 135
::USEROPT_COUNTERMEASURES_PERIODS <- 136
::USEROPT_USE_PERFECT_RANGEFINDER <- 137
::USEROPT_ROCKET_FUSE_DIST <- 138
::USEROPT_FRIENDS_ONLY <- 139
::USEROPT_ALLOW_JIP <- 140
::USEROPT_QUEUE_JIP <- 141
::USEROPT_AUTO_SQUAD <- 142
::USEROPT_ORDER_AUTO_ACTIVATE <- 143
::USEROPT_FORCE_GAIN <- 144
::USEROPT_COOP_MODE <- 145
::USEROPT_SEARCH_PLAYERMODE <- 146
::USEROPT_GUNNER_INVERTY <- 147
::USEROPT_XCHG_STICKS <- 148
::USEROPT_ZOOM_SENSE <- 149
::USEROPT_GUNNER_VIEW_SENSE <- 150
::USEROPT_GUNNER_VIEW_ZOOM_SENS <- 151
::USEROPT_MOUSE_SENSE <- 152
::USEROPT_MOUSE_AIM_SENSE <- 153
::USEROPT_MOUSE_SMOOTH <- 154
::USEROPT_LB_MODE <- 155
::USEROPT_LB_TYPE <- 156
::USEROPT_HUD_COLOR <- 157
::USEROPT_HUD_INDICATORS <- 158
::USEROPT_AI_GUNNER_TIME <- 159
::USEROPT_OFFLINE_MISSION <- 160
::USEROPT_VERSUS_NO_RESPAWN <- 161
::USEROPT_VERSUS_RESPAWN <- 162
::USEROPT_INVERT_THROTTLE <- 163
::USEROPT_COUNTRY <- 164
::USEROPT_RANDB_CLUSTER <- 165
::USEROPT_CLUSTER <- 166
::USEROPT_PLAY_INACTIVE_WINDOW_SOUND <- 167
::USEROPT_PILOT <- 168
::USEROPT_IS_BOTS_ALLOWED <- 169
::USEROPT_USE_TANK_BOTS <- 170
::USEROPT_USE_SHIP_BOTS <- 171
::USEROPT_KEEP_DEAD <- 172
::USEROPT_AUTOBALANCE <- 173
::USEROPT_MIN_PLAYERS <- 174
::USEROPT_MAX_PLAYERS <- 175
::USEROPT_DEDICATED_REPLAY <- 176
::USEROPT_SESSION_PASSWORD <- 177
::USEROPT_TAKEOFF_MODE <- 178
::USEROPT_LANDING_MODE <- 179
::USEROPT_ROUNDS <- 180
::USEROPT_DISABLE_AIRFIELDS <- 181
::USEROPT_ALLOW_EMPTY_TEAMS <- 182
::USEROPT_SPAWN_AI_TANK_ON_TANK_MAPS <- 183
::USEROPT_GUN_VERTICAL_TARGETING <- 184
::USEROPT_AEROBATICS_SMOKE_TYPE <- 185
::USEROPT_AEROBATICS_SMOKE_LEFT_COLOR <- 186
::USEROPT_AEROBATICS_SMOKE_RIGHT_COLOR <- 187
::USEROPT_AEROBATICS_SMOKE_TAIL_COLOR <- 188
::USEROPT_SHOW_PILOT <- 189
::USEROPT_AUTO_SHOW_CHAT <- 190
::USEROPT_CHAT_MESSAGES_FILTER <- 191
::USEROPT_CHAT_FILTER <- 192
::USEROPT_DAMAGE_INDICATOR_SIZE <- 193
::USEROPT_TACTICAL_MAP_SIZE <- 194
::USEROPT_CROSSHAIR_DEFLECTION <- 195
::USEROPT_CROSSHAIR_SPEED <- 196
::USEROPT_SHOW_INDICATORS <- 197
::USEROPT_HUD_SCREENSHOT_LOGO <- 198
::USEROPT_SAVE_ZOOM_CAMERA <- 199
::USEROPT_HUD_VISIBLE_STREAKS <- 200
::USEROPT_HUD_SHOW_FUEL <- 201
::USEROPT_HUD_SHOW_AMMO <- 202
::USEROPT_HUD_SHOW_TANK_GUNS_AMMO <- 203
::USEROPT_HUD_SHOW_TEMPERATURE <- 204
::USEROPT_MENU_SCREEN_SAFE_AREA <- 205
::USEROPT_HUD_SCREEN_SAFE_AREA <- 206
::USEROPT_SHOW_INDICATORS_TYPE <- 207
::USEROPT_SHOW_INDICATORS_NICK <- 208
::USEROPT_SHOW_INDICATORS_TITLE <- 209
::USEROPT_SHOW_INDICATORS_AIRCRAFT <- 210
::USEROPT_SHOW_INDICATORS_DIST <- 211
::USEROPT_MISSION_COUNTRIES_TYPE <- 212
::USEROPT_BIT_COUNTRIES_TEAM_A <- 213
::USEROPT_BIT_COUNTRIES_TEAM_B <- 214
::USEROPT_COUNTRIES_SET <- 215
::USEROPT_BIT_UNIT_TYPES <- 216
::USEROPT_BR_MIN <- 217
::USEROPT_BR_MAX <- 218
::USEROPT_REPLAY_ALL_INDICATORS <- 219
::USEROPT_REPLAY_LOAD_COCKPIT <- 220
::USEROPT_USE_KILLSTREAKS <- 221
::USEROPT_BIT_CHOOSE_UNITS_TYPE <- 222
::USEROPT_BIT_CHOOSE_UNITS_RANK <- 223
::USEROPT_BIT_CHOOSE_UNITS_OTHER <- 224
::USEROPT_BIT_CHOOSE_UNITS_SHOW_UNSUPPORTED_FOR_GAME_MODE <- 225
::USEROPT_BIT_CHOOSE_UNITS_SHOW_UNSUPPORTED_FOR_CUSTOM_LIST <- 226
::USEROPT_COMPLAINT_CATEGORY <- 227
::USEROPT_BAN_PENALTY <- 228
::USEROPT_BAN_TIME <- 229
::USEROPT_USERLOG_FILTER <- 230
::USEROPT_AUTOLOGIN <- 231
::USEROPT_PRELOADER_SETTINGS <- 232
::USEROPT_REVEAL_NOTIFICATIONS <- 233
::USEROPT_HDR_SETTINGS <- 234
::USEROPT_POSTFX_SETTINGS <- 235
::USEROPT_ONLY_FRIENDLIST_CONTACT <- 236
::USEROPT_MARK_DIRECT_MESSAGES_AS_PERSONAL <- 237
::USEROPT_SKIP_WEAPON_WARNING <- 238
::USEROPT_SKIP_LEFT_BULLETS_WARNING <- 239
::USEROPT_AUTOPILOT_ON_BOMBVIEW <- 240
::USEROPT_AUTOREARM_ON_AIRFIELD <- 241
::USEROPT_ENABLE_LASER_DESIGNATOR_ON_LAUNCH <- 242
::USEROPT_AUTO_AIMLOCK_ON_SHOOT <- 243
::USEROPT_AUTO_SEEKER_STABILIZATION <- 244
::USEROPT_ACTIVATE_AIRBORNE_RADAR_ON_SPAWN <- 245
::USEROPT_USE_RECTANGULAR_RADAR_INDICATOR <- 246
::USEROPT_RADAR_TARGET_CYCLING <- 247
::USEROPT_RADAR_AIM_ELEVATION_CONTROL <- 248
::USEROPT_USE_RADAR_HUD_IN_COCKPIT <- 249
::USEROPT_ACTIVATE_AIRBORNE_ACTIVE_COUNTER_MEASURES_ON_SPAWN <- 250
::USEROPT_SAVE_AI_TARGET_TYPE <- 251
::USEROPT_DEFAULT_AI_TARGET_TYPE <- 252
::USEROPT_TORPEDO_AUTO_SWITCH <- 408
::USEROPT_DEFAULT_TORPEDO_FORESTALL_ACTIVE <- 253
::USEROPT_ACTIVATE_AIRBORNE_WEAPON_SELECTION_ON_SPAWN <- 254
::USEROPT_AUTOMATIC_EMPTY_CONTAINERS_JETTISON <- 255

::USEROPT_PTT <- 256
::USEROPT_VOICE_CHAT <- 257
::USEROPT_VOICE_DEVICE_IN <- 258
::USEROPT_VOICE_DEVICE_OUT <- 259
::USEROPT_SOUND_DEVICE_OUT <- 260
::USEROPT_CROSSHAIR_TYPE <- 261
::USEROPT_CROSSHAIR_COLOR <- 262

::USEROPT_RACE_LAPS <- 263
::USEROPT_RACE_WINNERS <- 264
::USEROPT_RACE_CAN_SHOOT <- 265

::USEROPT_HELPERS_MODE <- 266
::USEROPT_MOUSE_USAGE <- 267
::USEROPT_MOUSE_USAGE_NO_AIM <- 268
::USEROPT_INSTRUCTOR_ENABLED <- 269
::USEROPT_AUTOTRIM <- 270

::USEROPT_INSTRUCTOR_GROUND_AVOIDANCE <- 271
::USEROPT_INSTRUCTOR_GEAR_CONTROL <- 272
::USEROPT_INSTRUCTOR_FLAPS_CONTROL <- 273
::USEROPT_INSTRUCTOR_ENGINE_CONTROL <- 274
::USEROPT_INSTRUCTOR_SIMPLE_JOY <- 275

::USEROPT_HELPERS_MODE_GM <- 276
::USEROPT_MAP_ZOOM_BY_LEVEL <- 277
::USEROPT_SHOW_COMPASS_IN_TANK_HUD <- 278

::USEROPT_TTV_USER_NAME <- 279
::USEROPT_TTV_PASSWORD <- 280
::USEROPT_TTV_USE_AUDIO <- 281
::USEROPT_TTV_VIDEO_SIZE <- 282
::USEROPT_TTV_VIDEO_BITRATE <- 283

::USEROPT_INTERNET_RADIO_ACTIVE <- 284
::USEROPT_INTERNET_RADIO_STATION <- 285

::USEROPT_CONTENT_ALLOWED_PRESET_ARCADE <- 286
::USEROPT_CONTENT_ALLOWED_PRESET_REALISTIC <- 287
::USEROPT_CONTENT_ALLOWED_PRESET_SIMULATOR <- 288
::USEROPT_CONTENT_ALLOWED_PRESET <- 289

::USEROPT_CD_ENGINE <- 290
::USEROPT_CD_GUNNERY <- 291
::USEROPT_CD_DAMAGE <- 292
::USEROPT_CD_STALLS <- 293
::USEROPT_CD_REDOUT <- 294
::USEROPT_CD_MORTALPILOT <- 295
::USEROPT_CD_FLUTTER <- 296
::USEROPT_CD_BOMBS <- 297
::USEROPT_CD_BOOST <- 298
::USEROPT_CD_TPS <- 299
::USEROPT_CD_AIM_PRED <- 300
::USEROPT_CD_MARKERS <- 301
::USEROPT_CD_ARROWS <- 302
::USEROPT_CD_AIRCRAFT_MARKERS_MAX_DIST <- 303
::USEROPT_CD_INDICATORS <- 304
::USEROPT_CD_SPEED_VECTOR <- 305
::USEROPT_CD_TANK_DISTANCE <- 306
::USEROPT_CD_MAP_AIRCRAFT_MARKERS <- 307
::USEROPT_CD_MAP_GROUND_MARKERS <- 308
::USEROPT_CD_RADAR <- 309
::USEROPT_CD_DAMAGE_IND <- 310
::USEROPT_CD_LARGE_AWARD_MESSAGES <- 311
::USEROPT_CD_WARNINGS <- 312
::USEROPT_CD_AIR_HELPERS <- 313
::USEROPT_CD_COLLECTIVE_DETECTION <- 314
::USEROPT_CD_MARKERS_BLINK <- 315
::USEROPT_CD_ALLOW_CONTROL_HELPERS <- 316
::USEROPT_CD_FORCE_INSTRUCTOR <- 317
::USEROPT_CD_DISTANCE_DETECTION <- 318
::USEROPT_GRASS_IN_TANK_VISION <- 319
::USEROPT_PITCH_BLOCKER_WHILE_BRACKING <- 320
::USEROPT_COMMANDER_CAMERA_IN_VIEWS <- 321
::USEROPT_SAVE_DIR_WHILE_SWITCH_TRIGGER <- 322


::USEROPT_HEADTRACK_ENABLE <- 323
::USEROPT_HEADTRACK_SCALE_X <- 324
::USEROPT_HEADTRACK_SCALE_Y <- 325

::USEROPT_HUE_ALLY <- 326
::USEROPT_HUE_ENEMY <- 327
::USEROPT_STROBE_ALLY <- 328
::USEROPT_STROBE_ENEMY <- 329
::USEROPT_HUE_SQUAD <- 330
::USEROPT_HUE_SPECTATOR_ALLY <- 331
::USEROPT_HUE_SPECTATOR_ENEMY <- 332
::USEROPT_HUE_RELOAD <- 333
::USEROPT_HUE_RELOAD_DONE <- 334
::USEROPT_AIR_DAMAGE_DISPLAY <- 335
::USEROPT_GUNNER_FPS_CAMERA <- 336

::USEROPT_HUE_HELICOPTER_PARAM_HUD <- 337
::USEROPT_HUE_HELICOPTER_CROSSHAIR <- 338
::USEROPT_HUE_HELICOPTER_HUD <- 339
::USEROPT_HUE_HELICOPTER_HUD_ALERT <- 340
::USEROPT_HUE_HELICOPTER_MFD <- 341

::USEROPT_HUE_AIRCRAFT_PARAM_HUD <- 342
::USEROPT_HUE_AIRCRAFT_HUD <- 343
::USEROPT_HUE_AIRCRAFT_HUD_ALERT <- 344

::USEROPT_HUE_ARBITER_HUD <- 345

::USEROPT_HUE_TANK_THERMOVISION <- 346
::USEROPT_HORIZONTAL_SPEED <- 347
::USEROPT_HELICOPTER_HELMET_AIM <- 348
::USEROPT_HELICOPTER_AUTOPILOT_ON_GUNNERVIEW <- 349

::USEROPT_MISSION_NAME_POSTFIX <- 350
::USEROPT_SHOW_DESTROYED_PARTS <- 351
::USEROPT_ACTIVATE_GROUND_RADAR_ON_SPAWN <- 352
::USEROPT_GROUND_RADAR_TARGET_CYCLING <- 353
::USEROPT_ACTIVATE_GROUND_ACTIVE_COUNTER_MEASURES_ON_SPAWN <- 354
::USEROPT_FPS_CAMERA_PHYSICS <- 355
::USEROPT_FPS_VR_CAMERA_PHYSICS <- 356
::USEROPT_FREE_CAMERA_INERTIA <- 357
::USEROPT_REPLAY_CAMERA_WIGGLE <- 358

::USEROPT_USE_CONTROLLER_LIGHT <- 359

::USEROPT_SHOW_DECORATORS <- 360

::USEROPT_CLAN_REQUIREMENTS_MIN_AIR_RANK <- 361
::USEROPT_CLAN_REQUIREMENTS_MIN_TANK_RANK <- 362
::USEROPT_CLAN_REQUIREMENTS_ALL_MIN_RANKS <- 363
::USEROPT_CLAN_REQUIREMENTS_MIN_ARCADE_BATTLES <- 364
::USEROPT_CLAN_REQUIREMENTS_MIN_SYM_BATTLES <- 365
::USEROPT_CLAN_REQUIREMENTS_MIN_REAL_BATTLES <- 366
::USEROPT_CLAN_REQUIREMENTS_AUTO_ACCEPT_MEMBERSHIP <- 367

::USEROPT_TANK_GUNNER_CAMERA_FROM_SIGHT <- 368
::USEROPT_TANK_ALT_CROSSHAIR <- 369

::USEROPT_GAMEPAD_CURSOR_CONTROLLER <- 370

::USEROPT_RANK <- 371
::USEROPT_QUEUE_EVENT_CUSTOM_MODE <- 372

::USEROPT_PS4_CROSSPLAY <- 373
::USEROPT_PS4_CROSSNETWORK_CHAT <- 374
::USEROPT_PS4_ONLY_LEADERBOARD <- 375
    //



::USEROPT_DISPLAY_MY_REAL_NICK <- 377
::USEROPT_SHOW_SOCIAL_NOTIFICATIONS <- 378
::USEROPT_ALLOW_ADDED_TO_CONTACTS <- 379
::USEROPT_ALLOW_ADDED_TO_LEADERBOARDS <- 380

::USEROPT_ENABLE_SOUND_SPEED <- 381
::USEROPT_SOUND_RESET_VOLUMES <- 382
::USEROPT_AIR_RADAR_SIZE <- 383
::USEROPT_ATGM_AIM_SENS_HELICOPTER <- 384
::USEROPT_ATGM_AIM_ZOOM_SENS_HELICOPTER <- 385

::USEROPT_TORPEDO_DIVE_DEPTH <- 386
::USEROPT_DELAYED_DOWNLOAD_CONTENT <- 387
::USEROPT_REPLAY_SNAPSHOT_ENABLED <- 388
::USEROPT_RECORD_SNAPSHOT_PERIOD <- 389

::USEROPT_BULLET_FALL_SPOT_SHIP <- 390
::USEROPT_HOLIDAYS <- 391
    //




::USEROPT_ALTERNATIVE_TPS_CAMERA <- 395

::USEROPT_CLAN_REQUIREMENTS_MIN_BLUEWATER_SHIP_RANK <- 396
::USEROPT_CLAN_REQUIREMENTS_MIN_COASTAL_SHIP_RANK <- 397

::USEROPT_GYRO_SIGHT_DEFLECTION <- 398

::USEROPT_HUD_VISIBLE_ORDERS <- 399
::USEROPT_HUD_VISIBLE_REWARDS_MSG <- 400
::USEROPT_HUD_VISIBLE_KILLLOG <- 401
::USEROPT_HUD_VISIBLE_CHAT_PLACE <- 402
::USEROPT_HIT_INDICATOR_RADIUS <- 403
::USEROPT_HIT_INDICATOR_SIMPLIFIED <- 404
::USEROPT_HIT_INDICATOR_ALPHA <- 405
::USEROPT_HIT_INDICATOR_SCALE <- 406
::USEROPT_HIT_INDICATOR_FADE_TIME <- 407
::USEROPT_FREE_CAMERA_ZOOM_SPEED <- 408
::USEROPT_REPLAY_FOV <- 409

::user_option_name_by_idx <- {}

let sortedoptmodes = []
foreach (modeName, idx in getroottable()) {
  if (!modeName.startswith("OPTIONS_MODE_"))
    continue
  sortedoptmodes.append({ modeName, idx })
}
sortedoptmodes.sort(@(a, b) a.idx <=> b.idx)

foreach (modeNameIdx in sortedoptmodes) {
  let { modeName, idx } = modeNameIdx
  let res = addOptionMode(modeName)
  let realIdx = (res != null) ? res : idx
  getroottable()[modeName] <- realIdx
}

let sorted_useropt = []
foreach (useropt, idx in getroottable()) {
  if (!useropt.startswith("USEROPT_"))
    continue
  sorted_useropt.append({ useropt, idx })
}
sorted_useropt.sort(@(a, b) a.idx <=> b.idx)

foreach (uidx in sorted_useropt) {
  let { useropt, idx } = uidx
  let res = addUserOption(useropt)
  let realIdx = (res != null) ? res : idx
//  log("DD:", useropt, "idx:", idx, "realIdx:", realIdx)
  getroottable()[useropt] <- realIdx
  ::user_option_name_by_idx[realIdx] <- useropt
}


::get_option_in_mode <- function get_option_in_mode(optionId, mode) {
  let mainOptionsMode = getGuiOptionsMode()
  setGuiOptionsMode(mode)
  let res = ::get_option(optionId)
  setGuiOptionsMode(mainOptionsMode)
  return res
}

::get_gui_option_in_mode <- function get_gui_option_in_mode(optionId, mode, defaultValue = null) {
  let mainOptionsMode = getGuiOptionsMode()
  setGuiOptionsMode(mode)
  let res = get_gui_option(optionId)
  if (mainOptionsMode >= 0)
    setGuiOptionsMode(mainOptionsMode)
  if (defaultValue != null && res == null)
    return defaultValue
  return res
}

::set_gui_option_in_mode <- function set_gui_option_in_mode(optionId, value, mode) {
  let mainOptionsMode = getGuiOptionsMode()
  setGuiOptionsMode(mode)
  set_gui_option(optionId, value)
  setGuiOptionsMode(mainOptionsMode)
}
