frame {
  id:t='select_unit_pane'
  size:t='380@sf/@pf, 350@sf/@pf'
  position:t='absolute'
  top='40@sf/@pf'
  right:t='pw-w'
  class:t='wndNav'
  total-input-transparent:t='yes'

  frame_header {
    activeText {
      text:t='#tankSight/changeSpectator'
      caption:t='yes'
    }
  }

  tdiv {
    size:t='pw,ph'
    flow:t='vertical'

    <<#unitSettings>>
    ComboBox {
      width:t='pw'
      margin:t='2@sf/@pf'
      <<@markup>>
    }
    <</unitSettings>>
  }

  navBar {
    navMiddle {
      Button_text {
        text:t='#mainmenu/btnReset'
        ButtonImg {}
        on_click='onReset'
      }
      Button_text {
        text:t='#save/btnSave'
        ButtonImg {}
        on_click='onSave'
      }
    }
  }
}

frame {
  id:t='settings_pane'
  size:t='400@sf/@pf, 650@sf/@pf'
  position:t='absolute'
  top='40@sf/@pf'
  left:t='pw-w'
  class:t='wndNav'
  total-input-transparent:t='yes'

  frame_header {
    activeText {
      text:t='#tankSight/presetSettings'
      caption:t='yes'
    }
  }

  tdiv {
    size:t='pw,ph'
    flow:t='vertical'
    overflow-y:t='auto'

    tdiv {
      width='pw'
      flow:t='vertical'

      textAreaCentered {
        text:t="#tankSight/choosePreset"
      }

      ComboBox {
        id:t= 'select_preset_combobox'
        width:t='pw'
        margin:t='2@sf/@pf'
        <<@presetsComboboxMarkup>>
      }
    }

    <<#presetSettings>>
      tankSightOptions {
        id:t='<<id>>'
        width:t='pw'
        flow:t='vertical'
        css-hier-invalidate:t='all'

        <<#initiallyExpand>>
        expanded='yes'
        <</initiallyExpand>>
        <<^initiallyExpand>>
        expanded='no'
        <</initiallyExpand>>

        tankSightOptionsTitle {
          width='pw'
          flow:t='horizontal'
          behavior:t='button'
          on_click:t='onOptionsTitleClick'

          textAreaCentered {
            text:t="<<title>>"
          }
        }

        tankSightOptionsList {
          width:t='pw'
          display:t='hide'
          overflow:t='hidden'
          flow:t='vertical'

          <<#controls>>
          ComboBox {
            id:t= '<<controlId>>'
            width:t='pw'
            margin:t='2@sf/@pf'
            <<@markup>>
          }
          <</controls>>
        }
      }
    <</presetSettings>>
  }
}

tdiv {
  position:t='absolute'
  pos:t='pw-w, sh-1@bh-h'

  Button_text {
    id:t='btn_toggle_preview'
    text:t='#mainmenu/btnPreview'
    btnName:t=''
    ButtonImg {}
    on_click='onToggleSightPreviewMode'
  }

  Button_text {
    id:t='btn_toggle_lighting'
    text:t=''
    ButtonImg {}
    on_click='onToggleLightingMode'
  }

  Button_text {
    id:t='btn_toggle_nv'
    text:t=''
    ButtonImg {}
    on_click='onToggleNightVisionMode'
  }

  Button_text {
    id:t='btn_toggle_thermal'
    text:t=''
    ButtonImg {}
    on_click='onToggleThermalMode'
  }

  Button_text {
    id:t='btn_back'
    text:t='#mainmenu/btnBack'
    btnName:t='B'
    ButtonImg {}
    _on_click:t='goBack'
  }
}

tdiv {
  behaviour='darg'
}