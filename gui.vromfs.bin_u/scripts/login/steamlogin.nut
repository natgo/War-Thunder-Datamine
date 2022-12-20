from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { animBgLoad } = require("%scripts/loading/animBg.nut")
let showTitleLogo = require("%scripts/viewUtils/showTitleLogo.nut")
let { setVersionText } = require("%scripts/viewUtils/objectTextUpdate.nut")
let exitGame = require("%scripts/utils/exitGame.nut")
let { setGuiOptionsMode } = require_native("guiOptions")
let { is_running } = require_native("steam")
let userstat = require("userstat")
let { APP_ID } = require("app")

::gui_handlers.LoginWndHandlerSteam <- class extends ::gui_handlers.LoginWndHandler
{
  sceneBlkName = "%gui/loginBoxSimple.blk"

  function initScreen()
  {
    animBgLoad()
    setVersionText()
    ::setProjectAwards(this)
    showTitleLogo(this.scene, 128)
    setGuiOptionsMode(::OPTIONS_MODE_GAMEPLAY)

    let lp = ::get_login_pass()
    this.defaultSaveLoginFlagVal = lp.login != ""
    this.defaultSavePasswordFlagVal = lp.password != ""
    this.defaultSaveAutologinFlagVal = ::is_autologin_enabled()

    //Called init while in loading, so no need to call again authorization.
    //Just wait, when the loading will be over.
    if (::g_login.isAuthorized())
      return

    let useSteamLoginAuto = ::load_local_shared_settings(USE_STEAM_LOGIN_AUTO_SETTING_ID)
    if (!hasFeature("AllowSteamAccountLinking"))
    {
      if (!useSteamLoginAuto) //can be null or false
        this.goToLoginWnd(useSteamLoginAuto == null)
      else
        this.authorizeSteam()
      return
    }

    if (useSteamLoginAuto == true)
    {
      this.authorizeSteam("steam-known")
      return
    }
    else if (useSteamLoginAuto == false)
    {
      this.goToLoginWnd(false)
      return
    }

    this.showSceneBtn("button_exit", true)
    this.showLoginProposal()
  }

  function showLoginProposal()
  {
    ::scene_msg_box("steam_link_method_question",
      this.guiScene,
      loc("steam/login/linkQuestion" + (hasFeature("AllowSteamAccountLinking")? "" : "/noLink")),
      [["#mainmenu/loginWithGaijin", Callback(this.goToLoginWnd, this) ],
       ["#mainmenu/loginWithSteam", Callback(this.authorizeSteam, this)],
       ["exit", exitGame]
      ],
      "#mainmenu/loginWithGaijin"
    )
  }

  function userstatRequestSyncUnlocks() {
    userstat.request({
      add_token = true
      headers = { appid = APP_ID }
      action = "SyncUnlocksWithSteam"
    }, @(_res) null)
  }

  function proceedAuthorizationResult(result, no_dump_login)
  {
    switch(result)
    {
      case YU2_NOT_FOUND:
        this.goToLoginWnd()
        break
      case YU2_OK:
        if (is_running() && !hasFeature("AllowSteamAccountLinking"))
          ::save_local_shared_settings(USE_STEAM_LOGIN_AUTO_SETTING_ID, true)
        this.userstatRequestSyncUnlocks()
          // no break!
      default:  // warning disable: -missed-break
        base.proceedAuthorizationResult(result, no_dump_login)
    }
  }

  function onLoginErrorTryAgain()
  {
    this.showLoginProposal()
  }

  function authorizeSteam(steamKey = "steam")
  {
    this.onSteamAuthorization(steamKey)
  }

  function goToLoginWnd(disableAutologin = true)
  {
    if (disableAutologin)
      ::disable_autorelogin_once <- true
    ::handlersManager.loadHandler(::gui_handlers.LoginWndHandler)
  }

  function goBack(_obj)
  {
    ::scene_msg_box("steam_question_quit_game",
      this.guiScene,
      loc("mainmenu/questionQuitGame"),
      [
        ["yes", exitGame],
        ["no", @() null]
      ],
      "no",
      { cancel_fn = @() null}
    )
  }
}
