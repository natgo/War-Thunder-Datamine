from "%scripts/dagui_library.nut" import *
//checked for explicitness
#explicit-this
#no-root-fallback

let statsd = require("statsd")
let { animBgLoad } = require("%scripts/loading/animBg.nut")
let showTitleLogo = require("%scripts/viewUtils/showTitleLogo.nut")
let { openUrl } = require("%scripts/onlineShop/url.nut")
let { setVersionText } = require("%scripts/viewUtils/objectTextUpdate.nut")
let twoStepModal = require("%scripts/login/twoStepModal.nut")
let exitGame = require("%scripts/utils/exitGame.nut")
let { setFocusToNextObj } = require("%sqDagui/daguiUtil.nut")
let loginWndBlkPath = require("%scripts/login/loginWndBlkPath.nut")
let { setGuiOptionsMode } = require_native("guiOptions")
let { havePlayerTag } = require("%scripts/user/userUtils.nut")
let { getDistr } = require("auth_wt")
let {dgs_get_settings} = require("dagor.system")
let { get_user_system_info } = require("sysinfo")
let { clearBorderSymbols } = require("%sqstd/string.nut")
let { register_command } = require("console")

const MAX_GET_2STEP_CODE_ATTEMPTS = 10
const GUEST_LOGIN_SAVE_ID = "guestLoginId"

local dbgGuestLoginIdPrefix = ""

let function getGuestLoginId() {
  let { uuid0 = "", uuid1 = "", uuid2 = "" } = get_user_system_info()
  return $"{dbgGuestLoginIdPrefix}{uuid0}_{uuid1}_{uuid2}"
}

let function setDbgGuestLoginIdPrefix(prefix) {
  dbgGuestLoginIdPrefix = $"{prefix}_"
  console_print(getGuestLoginId())
}
register_command(setDbgGuestLoginIdPrefix, "debug.set_guest_login_id_prefix")

::gui_handlers.LoginWndHandler <- class extends ::BaseGuiHandler
{
  sceneBlkName = loginWndBlkPath.value

  check2StepAuthCode = false
  availableCircuitsBlockName = "multipleAvailableCircuits"
  paramName = "circuit"
  shardItems = null
  localizationInfo = null

  initial_autologin = false
  stoken = "" //note: it's safe to keep it here even if it's dumped to log
  was_using_stoken = false
  isLoginRequestInprogress = false
  requestGet2stepCodeAtempt = 0
  isSteamAuth = false
  isGuestLogin = false

  defaultSaveLoginFlagVal = false
  defaultSavePasswordFlagVal = false
  defaultSaveAutologinFlagVal = false

  tabFocusArray = [
    "loginbox_username",
    "loginbox_password"
  ]

  function initScreen()
  {
    animBgLoad()
    setVersionText()
    ::setProjectAwards(this)
    showTitleLogo(this.scene, 128)
    this.initLanguageSwitch()
    this.checkShardingCircuits()
    setGuiOptionsMode(::OPTIONS_MODE_GAMEPLAY)

    ::enable_keyboard_layout_change_tracking(true)
    ::enable_keyboard_locks_change_tracking(true)

    let bugDiscObj = this.scene.findObject("browser_bug_disclaimer")
    if (checkObj(bugDiscObj))
      bugDiscObj.show(platformId == "linux64" && ::is_steam_big_picture()) //STEAM_OS

    let lp = ::get_login_pass()
    let isVietnamese = ::is_vietnamese_version()
    if (isVietnamese)
      lp.autoSave = lp.autoSave & AUTO_SAVE_FLG_LOGIN

    let disableSSLCheck = lp.autoSave & AUTO_SAVE_FLG_NOSSLCERT

    let unObj = this.scene.findObject("loginbox_username")
    if (checkObj(unObj))
      unObj.setValue(lp.login)

    let psObj = this.scene.findObject("loginbox_password")
    if (checkObj(psObj)) {
      psObj["password-smb"] = loc("password_mask_char", "*")
      psObj.setValue(lp.password)
    }

    let alObj = this.scene.findObject("loginbox_autosave_login")
    if (checkObj(alObj))
      alObj.setValue(lp.autoSave & AUTO_SAVE_FLG_LOGIN)

    let spObj = this.scene.findObject("loginbox_autosave_password")
    if (checkObj(spObj))
    {
      spObj.show(!isVietnamese)
      spObj.setValue(lp.autoSave & AUTO_SAVE_FLG_PASS)
      spObj.enable((lp.autoSave & AUTO_SAVE_FLG_LOGIN) != 0 && !isVietnamese)
      local text = loc("mainmenu/savePassword")
      if (!::is_platform_shield_tv())
        text += " " + loc("mainmenu/savePassword/unsecure")
      spObj.findObject("loginbox_autosave_password_text").setValue(text)
    }

    this.setDisableSslCertBox(disableSSLCheck)
    let isSteamRunning = ::steam_is_running()
    let showSteamLogin = isSteamRunning
    let showWebLogin = !isSteamRunning && ::webauth_start(this, this.onSsoAuthorizationComplete)
    local showGuestLogin = false
    //


    this.showSceneBtn("secondary_auth_block", showGuestLogin || showSteamLogin || showWebLogin)
    this.showSceneBtn("guest_login_action_button", showGuestLogin)
    this.showSceneBtn("steam_login_action_button", showSteamLogin)
    this.showSceneBtn("sso_login_action_button", showWebLogin)
    this.showSceneBtn("btn_signUp_link", !showSteamLogin)

    this.initial_autologin = ::is_autologin_enabled()

    let saveLoginAndPassMask = AUTO_SAVE_FLG_LOGIN | AUTO_SAVE_FLG_PASS
    let autoLoginEnable = (lp.autoSave & saveLoginAndPassMask) == saveLoginAndPassMask
    local autoLogin = (this.initial_autologin && autoLoginEnable) || (dgs_get_settings()?.yunetwork.forceAutoLogin ?? false)
    let autoLoginObj = this.scene.findObject("loginbox_autologin")
    if (checkObj(autoLoginObj))
    {
      autoLoginObj.show(!isVietnamese)
      autoLoginObj.enable(autoLoginEnable)
      autoLoginObj.setValue(autoLogin)
    }

    this.showSceneBtn("links_block", !::is_platform_shield_tv())

    if ("dgs_get_argv" in getroottable())
    {
      let s = ::dgs_get_argv("stoken")
      if (!::u.isEmpty(s))
        lp.stoken <- s
    }
    else if ("dgs_argc" in getroottable())
      for (local i = 1; i < ::dgs_argc(); i++)
      {
        let str = ::dgs_argv(i);
        let idx = str.indexof("-stoken:")
        if (idx != null)
          lp.stoken <- str.slice(idx+8)
      }

    if (("stoken" in lp) && lp.stoken != null && lp.stoken != "")
    {
      this.stoken = lp.stoken
      this.doLoginDelayed()
      return
    }

    let disableAutoRelogin = getroottable()?.disable_autorelogin_once ?? false
    if (!disableAutoRelogin && ::load_local_shared_settings(USE_GUEST_LOGIN_AUTO_SETTING_ID)) {
      this.onGuestAuthorization()
      return
    }
    autoLogin = autoLogin && !disableAutoRelogin
    if (autoLogin)
    {
      this.doLoginDelayed()
      return
    }

    ::select_editbox(this.scene.findObject(this.tabFocusArray[ lp.login != "" ? 1 : 0 ]))
  }

  function onDestroy()
  {
    ::webauth_stop()
    ::enable_keyboard_layout_change_tracking(false)
    ::enable_keyboard_locks_change_tracking(false)
  }

  function setDisableSslCertBox(value)
  {
    let dcObj = this.showSceneBtn("loginbox_disable_ssl_cert", value)
    if (checkObj(dcObj))
      dcObj.setValue(value)
  }

  function checkShardingCircuits()
  {
    local defValue = 0
    let networkBlk = ::get_network_block()
    let avCircuits = networkBlk.getBlockByName(this.availableCircuitsBlockName)

    let configCircuitName = ::get_cur_circuit_name()
    this.shardItems = [{
                    item = configCircuitName
                    text = loc("circuit/" + configCircuitName)
                 }]

    if (avCircuits && avCircuits.paramCount() > 0)
    {
      local defaultCircuit = loc("default_circuit", "")
      if (defaultCircuit == "")
        defaultCircuit = configCircuitName

      this.shardItems = []
      for(local i = 0; i < avCircuits.paramCount(); ++i)
      {
        let param = avCircuits.getParamName(i)
        let value = avCircuits.getParamValue(i)
        if (param == this.paramName && type(value) == "string")
        {
          if (value == defaultCircuit)
            defValue = i

          this.shardItems.append({
                              item = value
                              text = loc("circuit/" + value)
                           })
        }
      }
    }

    let show = this.shardItems.len() > 1
    let shardObj = this.showSceneBtn("sharding_block", show)
    if (show && checkObj(shardObj))
    {
      let dropObj = shardObj.findObject("sharding_dropright_block")
      let shardData = ::create_option_combobox("sharding_list", this.shardItems, defValue, null, true)
      this.guiScene.replaceContentFromText(dropObj, shardData, shardData.len(), this)
    }
  }

  function onChangeAutosave()
  {
    if (!this.isValid())
      return

    let remoteCompObj = this.scene.findObject("loginbox_remote_comp")
    let rememberDeviceObj = this.scene.findObject("loginbox_code_remember_this_device")
    let savePassObj = this.scene.findObject("loginbox_autosave_password")
    let saveLoginObj = this.scene.findObject("loginbox_autosave_login")
    let autoLoginObj = this.scene.findObject("loginbox_autologin")
    let disableCertObj = this.scene.findObject("loginbox_disable_ssl_cert")

    if (rememberDeviceObj.isVisible())
      remoteCompObj.setValue(!rememberDeviceObj.getValue())
    else
      rememberDeviceObj.setValue(!remoteCompObj.getValue())

    let isRemoteComp = remoteCompObj.getValue()
    let isAutosaveLogin = saveLoginObj.getValue()
    let isAutosavePass = savePassObj.getValue()

    this.setDisableSslCertBox(disableCertObj.getValue())

    saveLoginObj.enable(!isRemoteComp)
    savePassObj.enable(!isRemoteComp && isAutosaveLogin && !::is_vietnamese_version())
    autoLoginObj.enable(!isRemoteComp && isAutosaveLogin && isAutosavePass)

    if (isRemoteComp)
      saveLoginObj.setValue(false)
    if (isRemoteComp || !isAutosaveLogin)
      savePassObj.setValue(false)
    if (isRemoteComp || !isAutosavePass || !isAutosaveLogin)
      autoLoginObj.setValue(false)
  }

  function initLanguageSwitch()
  {
    let canSwitchLang = ::canSwitchGameLocalization()
    this.showSceneBtn("language_selector", canSwitchLang)
    if (!canSwitchLang)
      return

    this.localizationInfo = this.localizationInfo || ::g_language.getGameLocalizationInfo()
    let curLangId = ::get_current_language()
    local lang = this.localizationInfo[0]
    foreach (l in this.localizationInfo)
      if (l.id == curLangId)
        lang = l

    let objLangLabel = this.scene.findObject("label_language")
    if (checkObj(objLangLabel))
    {
      local title = loc("profile/language")
      let titleEn = loc("profile/language/en")
      title += (title == titleEn ? "" : loc("ui/parentheses/space", { text = titleEn })) + ":"
      objLangLabel.setValue(title)
    }
    let objLangIcon = this.scene.findObject("btn_language_icon")
    if (checkObj(objLangIcon))
      objLangIcon["background-image"] = lang.icon
    let objLangName = this.scene.findObject("btn_language_text")
    if (checkObj(objLangName))
      objLangName.setValue(lang.title)
  }

  function onPopupLanguages(obj)
  {
    if (::gui_handlers.ActionsList.hasActionsListOnObject(obj))
      return this.onClosePopups()

    this.localizationInfo = this.localizationInfo || ::g_language.getGameLocalizationInfo()
    if (!checkObj(obj) || this.localizationInfo.len() < 2)
      return

    let curLangId = ::get_current_language()
    let menu = {
      handler = this
      closeOnUnhover = true
      actions = []
    }
    for (local i = 0; i < this.localizationInfo.len(); i++)
    {
      let lang = this.localizationInfo[i]
      menu.actions.append({
        actionName  = lang.id
        text        = lang.title
        icon        = lang.icon
        action      = (@(lang) function () { this.onChangeLanguage(lang.id) })(lang)
        selected    = lang.id == curLangId
      })
    }
    ::gui_handlers.ActionsList.open(obj, menu)
  }

  function onClosePopups()
  {
    let obj = this.scene.findObject("btn_language")
    if (checkObj(obj))
      ::gui_handlers.ActionsList.removeActionsListFromObject(obj, true)
  }

  function onChangeLanguage(langId)
  {
    let no_dump_login = this.scene.findObject("loginbox_username").getValue() || ""
    let no_dump_pass = this.scene.findObject("loginbox_password").getValue() || ""
    let isRemoteComp = this.scene.findObject("loginbox_remote_comp").getValue()
    let code_remember_this_device = this.scene.findObject("loginbox_code_remember_this_device").getValue()
    let isAutosaveLogin = this.scene.findObject("loginbox_autosave_login").getValue()
    let isAutosavePass = this.scene.findObject("loginbox_autosave_password").getValue()
    let autologin = this.scene.findObject("loginbox_autologin").getValue()
    let shardingListObj = this.scene.findObject("sharding_list")
    let shard = shardingListObj ? shardingListObj.getValue() : -1

    ::g_language.setGameLocalization(langId, true, true)

    let handler = ::handlersManager.findHandlerClassInScene(::gui_handlers.LoginWndHandler)
    this.scene = handler ? handler.scene : null
    if (!checkObj(this.scene))
      return

    this.scene.findObject("loginbox_username").setValue(no_dump_login)
    this.scene.findObject("loginbox_password").setValue(no_dump_pass)
    this.scene.findObject("loginbox_remote_comp").setValue(isRemoteComp)
    this.scene.findObject("loginbox_code_remember_this_device").setValue(code_remember_this_device)
    this.scene.findObject("loginbox_autosave_login").setValue(isAutosaveLogin)
    this.scene.findObject("loginbox_autosave_password").setValue(isAutosavePass)
    this.scene.findObject("loginbox_autologin").setValue(autologin)
    handler.onChangeAutosave()
    if (shardingListObj)
      shardingListObj.setValue(shard)
  }

  function requestLogin(no_dump_login)
  {
    return this.requestLoginWithCode(no_dump_login, "");
  }

  function requestLoginWithCode(no_dump_login, code)
  {
    statsd.send_counter("sq.game_start.request_login", 1, {login_type = "regular"})
    log("Login: check_login_pass")
    return ::check_login_pass(no_dump_login,
                              ::get_object_value(this.scene, "loginbox_password", ""),
                              this.check2StepAuthCode ? "" : this.stoken, //after trying use stoken it's set to "", but to be sure - use "" for 2stepAuth
                              code,
                              this.check2StepAuthCode
                                ? ::get_object_value(this.scene, "loginbox_code_remember_this_device", false)
                                : !::get_object_value(this.scene, "loginbox_disable_ssl_cert", false),
                              ::get_object_value(this.scene, "loginbox_remote_comp", false)
                             )
  }

  function continueLogin(no_dump_login)
  {
    if (this.shardItems)
    {
      if (this.shardItems.len() == 1)
        ::set_network_circuit(this.shardItems[0].item)
      else if (this.shardItems.len() > 1)
        ::set_network_circuit(this.shardItems[this.scene.findObject("sharding_list").getValue()].item)
    }

    let autoSaveLogin = ::get_object_value(this.scene, "loginbox_autosave_login", this.defaultSaveLoginFlagVal)
    let autoSavePassword = ::get_object_value(this.scene, "loginbox_autosave_password", this.defaultSavePasswordFlagVal)
    let disableSSLCheck = ::get_object_value(this.scene, "loginbox_disable_ssl_cert", false)
    local autoSave = (autoSaveLogin     ? AUTO_SAVE_FLG_LOGIN     : 0) |
                     (autoSavePassword  ? AUTO_SAVE_FLG_PASS      : 0) |
                     (disableSSLCheck   ? AUTO_SAVE_FLG_NOSSLCERT : 0)

    if (this.was_using_stoken || this.isSteamAuth || this.isGuestLogin)
      autoSave = autoSave | AUTO_SAVE_FLG_DISABLE

    if (this.isGuestLogin)
      ::save_local_shared_settings(GUEST_LOGIN_SAVE_ID, getGuestLoginId())

    ::set_login_pass(no_dump_login.tostring(), ::get_object_value(this.scene, "loginbox_password", ""), autoSave)
    if (!checkObj(this.scene)) //set_login_pass start onlineJob
      return

    let autoLogin = (autoSaveLogin && autoSavePassword) ?
                ::get_object_value(this.scene, "loginbox_autologin", this.defaultSaveAutologinFlagVal)
                : false
    ::set_autologin_enabled(autoLogin)
    if (this.initial_autologin != autoLogin)
      ::save_profile(false)

    ::g_login.addState(LOGIN_STATE.AUTHORIZED)
  }

  function onOk()
  {
    if (!this.isLoginEditsFilled())
      return

    this.isLoginRequestInprogress = true
    this.requestGet2stepCodeAtempt = MAX_GET_2STEP_CODE_ATTEMPTS
    this.doLoginWaitJob()
  }

  function doLoginDelayed()
  {
    this.isLoginRequestInprogress = true
    this.guiScene.performDelayed(this, this.doLoginWaitJob)
  }

  function doLoginWaitJob()
  {
    ::disable_autorelogin_once <- false
    let no_dump_login = ::get_object_value(this.scene, "loginbox_username", "")
    local result = this.requestLogin(no_dump_login)
    this.proceedAuthorizationResult(result, no_dump_login)
  }

  function onSteamAuthorization(steamSpecCode = null)
  {
    this.isSteamAuth = true
    steamSpecCode = steamSpecCode || "steam"
    this.isLoginRequestInprogress = true
    ::disable_autorelogin_once <- false
    statsd.send_counter("sq.game_start.request_login", 1, {login_type = "steam"})
    log("Steam Login: check_login_pass with code " + steamSpecCode)
    let result = ::check_login_pass("", "", "steam", steamSpecCode, false, false)
    this.proceedAuthorizationResult(result, "")
  }

  function onSsoAuthorization()
  {
    let no_dump_login = ::get_object_value(this.scene, "loginbox_username", "")
    let no_dump_url = ::webauth_get_url(no_dump_login)
    openUrl(no_dump_url)
    ::browser_set_external_url(no_dump_url)
  }

  function onSsoAuthorizationComplete(params)
  {
    ::close_browser_modal()

    if (params.success)
    {
      let no_dump_login = ::get_object_value(this.scene, "loginbox_username", "")
      ::load_local_settings()
      this.continueLogin(no_dump_login);
    }
  }

  function onEventProceedGetTwoStepCode(data)
  {
    if (!this.isValid() || this.isLoginRequestInprogress)
    {
      return
    }

    let result = data.status
    let code = data.code
    let no_dump_login = ::get_object_value(this.scene, "loginbox_username", "")

    if (result == YU2_TIMEOUT && this.requestGet2stepCodeAtempt-- > 0)
    {
      this.doLoginDelayed()
      return
    }

    if (result == YU2_OK)
    {
      this.isLoginRequestInprogress = true
      let loginResult = this.requestLoginWithCode(no_dump_login, code)
      this.proceedAuthorizationResult(loginResult, no_dump_login)
    }
  }

  function needTrySteamLink()
  {
    return ::steam_is_running()
           && hasFeature("AllowSteamAccountLinking")
           && ::load_local_shared_settings(USE_STEAM_LOGIN_AUTO_SETTING_ID) == null
  }

  function proceedAuthorizationResult(result, no_dump_login)
  {
    this.isLoginRequestInprogress = false
    if (!checkObj(this.scene)) //check_login_pass is not instant
      return

    this.was_using_stoken = (this.stoken != "")
    this.stoken = ""
    switch (result)
    {
      case YU2_OK:
        if (::steam_is_running()
            && !hasFeature("AllowSteamAccountLinking")
            && !havePlayerTag("steam"))
        {
          this.msgBox("steam_relogin_request",
            loc("mainmenu/login/steamRelogin"),
          [
            ["ok", ::restart_without_steam],
            ["cancel"]
          ],
          "ok", { cancel_fn = @() null })
          return
        }

        if (this.needTrySteamLink())
        {
          let isRemoteComp = ::get_object_value(this.scene, "loginbox_remote_comp", false)
          statsd.send_counter("sq.game_start.request_login", 1, {login_type = "steam_link"})
          log("Steam Link Login: check_login_pass")
          let res = ::check_login_pass("", "", "steam", "steam", true, isRemoteComp)
          log("Steam Link Login: link existing account, result = " + res)
          if (res == YU2_OK)
            ::save_local_shared_settings(USE_STEAM_LOGIN_AUTO_SETTING_ID, true)
          else if (res == YU2_ALREADY)
            ::save_local_shared_settings(USE_STEAM_LOGIN_AUTO_SETTING_ID, false)
        }
        else if (::steam_is_running() && !hasFeature("AllowSteamAccountLinking"))
          ::save_local_shared_settings(USE_STEAM_LOGIN_AUTO_SETTING_ID, this.isSteamAuth)

        ::save_local_shared_settings(USE_GUEST_LOGIN_AUTO_SETTING_ID, this.isGuestLogin)

        this.continueLogin(no_dump_login)
        break

      case YU2_2STEP_AUTH: //error, received if user not logged, because he have 2step authorization activated
        {
          this.check2StepAuthCode = true
          this.showSceneBtn("loginbox_code_remember_this_device", true)
          this.showSceneBtn("loginbox_remote_comp", false)
          twoStepModal.open({
            loginScene           = this.scene,
            continueLogin        = this.continueLogin.bindenv(this)
          })
          this.onChangeAutosave()
          this.guiScene.performDelayed(this, (@(scene) function() {
            if (!checkObj(scene))
              return

            if ("get_two_step_code_async2" in getroottable())
              ::get_two_step_code_async2("ProceedGetTwoStepCode")
            else
              ::get_two_step_code_async(this, this.onEventProceedGetTwoStepCode)
          })(this.scene))
        }
        break

      case YU2_PSN_RESTRICTED:
        {
          this.msgBox("psn_restricted", loc("yn1/login/PSN_RESTRICTED"),
             [["exit", exitGame ]], "exit")
        }
        break;

      case YU2_WRONG_LOGIN:
      case YU2_WRONG_PARAMETER:
        if (this.was_using_stoken)
          return;
        ::error_message_box("yn1/connect_error", result, // auth error
        [
          ["recovery", function() {openUrl(loc("url/recovery"), false, false, "login_wnd")}],
          ["exit", exitGame],
          ["tryAgain", Callback(this.onLoginErrorTryAgain, this)]
        ], "tryAgain", { cancel_fn = Callback(this.onLoginErrorTryAgain, this) })
        break

      case YU2_SSL_CACERT:
        if (this.was_using_stoken)
          return;
        ::error_message_box("yn1/connect_error", result,
        [
          ["disableSSLCheck", Callback(function() { this.setDisableSslCertBox(true) }, this)],
          ["exit", exitGame],
          ["tryAgain", Callback(this.onLoginErrorTryAgain, this)]
        ], "tryAgain", { cancel_fn = Callback(this.onLoginErrorTryAgain, this) })
        break

      case YU2_DOI_INCOMPLETE:
        ::showInfoMsgBox(loc("yn1/login/DOI_INCOMPLETE"), "verification_email_to_complete")
        break

      default:
        if (this.was_using_stoken)
          return;
        ::error_message_box("yn1/connect_error", result,
        [
          ["exit", exitGame],
          ["tryAgain", Callback(this.onLoginErrorTryAgain, this)]
        ], "tryAgain", { cancel_fn = Callback(this.onLoginErrorTryAgain, this) })
    }
  }

  function onLoginErrorTryAgain() {}

  function onKbdWrapDown()
  {
    setFocusToNextObj(this.scene, this.tabFocusArray, 1)
  }

  function onEventKeyboardLayoutChanged(params)
  {
    let layoutIndicator =
      this.scene.findObject("loginbox_password_layout_indicator")

    if (!checkObj(layoutIndicator))
      return

    local layoutCode = params.layout.toupper()
    if (layoutCode.len() > 2)
      layoutCode = layoutCode.slice(0, 2)

    layoutIndicator.setValue(layoutCode)
  }

  function onEventKeyboardLocksChanged(params)
  {
    let capsIndicator = this.scene.findObject("loginbox_password_caps_indicator")
    if (checkObj(capsIndicator))
      capsIndicator.show((params.locks & 1) == 1)
  }

  function onSignUp()
  {
    local urlLocId
    if (::steam_is_running())
      urlLocId = "url/signUpSteam"
    else if (::is_platform_shield_tv())
      urlLocId = "url/signUpShieldTV"
    else
      urlLocId = "url/signUp"

    openUrl(loc(urlLocId, {distr = getDistr()}), false, false, "login_wnd")
  }

  function onForgetPassword()
  {
    openUrl(loc("url/recovery"), false, false, "login_wnd")
  }

  function onChangeLogin(obj)
  {
    //Don't save value to local, so it doens't appear in logs.
    let res = !::g_string.validateEmail(obj.getValue()) && (this.stoken == "")
    obj.warning = res? "yes" : "no"
    obj.warningText = res? "yes" : "no"
    obj.tooltip = res? loc("tooltip/invalidEmail/possibly") : ""
    this.setLoginBtnState()
  }

  function onDoneEnter()
  {
    if (!this.check2StepAuthCode)
      this.doLoginWaitJob()
  }

  function onDoneCode()
  {
    this.doLoginWaitJob()
  }

  function onExit()
  {
    this.msgBox("login_question_quit_game", loc("mainmenu/questionQuitGame"),
      [
        ["yes", exitGame],
        ["no", @() null]
      ], "no", { cancel_fn = @() null})
  }

  isLoginEditsFilled = @() ::get_object_value(this.scene, "loginbox_username", "") != ""
    && ::get_object_value(this.scene, "loginbox_password", "") != ""

  function setLoginBtnState ()
  {
    let loginBtnObj = this.scene.findObject("login_action_button")
    if (!checkObj(loginBtnObj))
      return false

    loginBtnObj.enable = this.isLoginEditsFilled() ? "yes" : "no"
  }

  function goBack()
  {
    this.onExit()
  }

  function guestProceedAuthorization(guestLoginId, nick = "") {
    this.isGuestLogin = true
    this.isLoginRequestInprogress = true
    ::disable_autorelogin_once <- false
    statsd.send_counter("sq.game_start.request_login", 1, {login_type = "guest"})
    log("Guest Login: check_login_pass")
    let result = ::check_login_pass(guestLoginId, nick, "guest", "guest", false, false)
    this.proceedAuthorizationResult(result, "")
  }

  function onGuestAuthorization() {
    let guestLoginId = getGuestLoginId()
    if (guestLoginId == ::load_local_shared_settings(GUEST_LOGIN_SAVE_ID)) {
      this.guestProceedAuthorization(guestLoginId)
      return
    }

    ::gui_modal_editbox_wnd({
      title = loc("mainmenu/chooseName")
      maxLen = 16
      validateFunc = @(nick) clearBorderSymbols(nick, [" "])
      canCancel = true
      owner = this
      okFunc = @(nick) this.guestProceedAuthorization(guestLoginId, nick)
    })
  }
}
