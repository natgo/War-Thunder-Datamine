from "%scripts/dagui_library.nut" import *

//--------------------------------------------------------------------//
//----------------------OBSOLETTE SCRIPT FUNCTIONS--------------------//
//-- Do not use them. Use null operators or native functons instead --//
//--------------------------------------------------------------------//

//--------------------------------------------------------------------//
//----------------------COMPATIBILITIES BY VERSIONS-------------------//
// -----------can be removed after version reach all platforms--------//
//--------------------------------------------------------------------//

let {apply_compatibilities} = require("%sqStdLibs/helpers/backCompatibility.nut")

//----------------------------wop_2_37_0_X---------------------------------//
apply_compatibilities({
  EULT_COMPLAINT_UPHELD = 61
})
