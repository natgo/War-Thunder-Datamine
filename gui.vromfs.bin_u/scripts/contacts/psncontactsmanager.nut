//checked for plus_string
from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let logS = log_with_prefix("[PSN: Contacts] ")

let DataBlock = require("DataBlock")
let { get_time_msec } = require("dagor.time")
let psn = require("%sonyLib/webApi.nut")
let { isPlatformSony, isPS4PlayerName } = require("%scripts/clientState/platform.nut")
let { requestUnknownPSNIds } = require("%scripts/contacts/externalContactsService.nut")
let { addContact, addContactGroup, EPLX_PS4_FRIENDS } = require("%scripts/contacts/contactsManager.nut")

let isContactsUpdated = persist("isContactsUpdated", @() Watched(false))

let LIMIT_FOR_ONE_TASK_GET_USERS = 200
let UPDATE_TIMER_LIMIT = 10000
local LAST_UPDATE_FRIENDS = -UPDATE_TIMER_LIMIT
let PSN_RESPONSE_FIELDS = psn.getPreferredVersion() == 2
  ? { friends = "friends", blocklist = "blocks" }
  : { friends = "friendList", blocklist = "blockingUsers" }

let convertPsnContact = (psn.getPreferredVersion() == 2)
  ? @(psnEntry) { accountId = psnEntry }
  : @(psnEntry) { accountId = psnEntry.user.accountId }

let pendingContactsChanges = {}
let checkGroups = []


let tryUpdateContacts = function(contactsBlk) {
  local haveAnyUpdate = false
  foreach (_group, usersList in contactsBlk)
    haveAnyUpdate = haveAnyUpdate || usersList.paramCount() > 0

  if (!haveAnyUpdate) {
    logS("Update: No changes. No need to server call")
    return
  }

  let result = ::request_edit_player_lists(contactsBlk, false)
  if (result) {
    foreach (group, playersBlock in contactsBlk) {
      foreach (uid, isAdding in playersBlock) {
        let contact = ::getContact(uid)
        if (!contact)
          continue

        if (isAdding)
          addContact(contact, group)
        else
          ::g_contacts.removeContact(contact, group)

        contact.updateMuteStatus()
      }
      ::broadcastEvent(contactEvent.CONTACTS_GROUP_UPDATE { groupName = group })
    }
  }
}

let function psnUpdateContactsList(usersTable) {
  //Create or update exist contacts
  let contactsTable = {}
  foreach (uid, playerData in usersTable)
    contactsTable[playerData.id] <- ::updateContact({
      uid = uid
      name = playerData.nick
      psnId = playerData.id
    })

  let contactsBlk = DataBlock()
  contactsBlk[EPLX_PS4_FRIENDS] <- DataBlock()
  contactsBlk[EPL_BLOCKLIST]  <- DataBlock()
  contactsBlk[EPL_FRIENDLIST] <- DataBlock()

  foreach (groupName, groupData in pendingContactsChanges) {
    let existedPSNContacts = ::get_contacts_array_by_filter_func(groupName, isPS4PlayerName)

    foreach (userInfo in groupData.users) {
      let contact = contactsTable?[userInfo.accountId]
      if (!contact)
        continue

      if (!contact.isInPSNFriends() && groupName == EPLX_PS4_FRIENDS) {
        contactsBlk[EPLX_PS4_FRIENDS][contact.uid] = true
        if (contact.isInBlockGroup())
          contactsBlk[EPL_BLOCKLIST][contact.uid] = false
      }

      if (!contact.isInBlockGroup() && groupName == EPL_BLOCKLIST) {
        contactsBlk[EPL_BLOCKLIST][contact.uid] = true
        if (contact.isInPSNFriends())
          contactsBlk[EPLX_PS4_FRIENDS][contact.uid] = false

        if (contact.isInFriendGroup())
          contactsBlk[EPL_FRIENDLIST][contact.uid] = false
      }

      //Check both lists, as there can be mistakes
      if (contact.isInPSNFriends() && contact.isInBlockGroup()) {
        if (groupName == EPLX_PS4_FRIENDS)
          contactsBlk[EPL_BLOCKLIST][contact.uid] = false
        else
          contactsBlk[EPLX_PS4_FRIENDS][contact.uid] = false
      }

      //Validate in-game contacts list
      //in case if in psn contacts list some players
      //are gone. So we need to clear then in game.
      for (local i = existedPSNContacts.len() - 1; i >= 0; i--)
        if (contact.isSameContact(existedPSNContacts[i].uid)) {
          existedPSNContacts.remove(i)
          break
        }
    }

    foreach (oldContact in existedPSNContacts)
      contactsBlk[groupName][oldContact.uid] = false
  }

  tryUpdateContacts(contactsBlk)
  pendingContactsChanges.clear()
}

let function proceedPlayersList() {
  foreach (groupName in checkGroups)
    if (!(groupName in pendingContactsChanges) || !pendingContactsChanges[groupName].isFinished)
      return

  let playersList = []
  foreach (_groupName, data in pendingContactsChanges)
    playersList.extend(data.users)

  let knownUsers = {}
  for (local i = playersList.len() - 1; i >= 0; i--) {
    let contact = ::g_contacts.findContactByPSNId(playersList[i].accountId)
    if (contact) {
      knownUsers[contact.uid] <- {
        nick = contact.name
        id = playersList.remove(i).accountId
      }
    }
  }

  requestUnknownPSNIds(
    playersList.map(@(u) u.accountId),
    knownUsers,
    psnUpdateContactsList
  )
}

let function onReceviedUsersList(groupName, responseInfoName, response, err) {
  let size = (response?.size || 0) + (response?.start || 0)
  let total = response?.totalResults || size

  if (!(groupName in pendingContactsChanges))
    pendingContactsChanges[groupName] <- {
      isFinished = false
      users = []
    }

  if (!err) {
    foreach (_idx, playerData in (response?[responseInfoName] || []))
        pendingContactsChanges[groupName].users.append(convertPsnContact(playerData))
  }
  else {
    logS($"Update {groupName}: received error: {toString(err)}")
    if (::u.isString(err.code) || err.code < 500 || err.code >= 600)
      logerr($"[PSN: Contacts] Update {groupName}: received error: {toString(err)}")
  }

  pendingContactsChanges[groupName].isFinished = err || size >= total
  proceedPlayersList()
}

let function fetchFriendlist() {
  checkGroups.append(EPLX_PS4_FRIENDS)
  addContactGroup(EPLX_PS4_FRIENDS)
  psn.fetch(
    psn.profile.listFriends(),
    @(response, err) onReceviedUsersList(EPLX_PS4_FRIENDS, PSN_RESPONSE_FIELDS.friends, response, err),
    LIMIT_FOR_ONE_TASK_GET_USERS
  )
}

let function fetchBlocklist() {
  checkGroups.append(EPL_BLOCKLIST)
  psn.fetch(
    psn.profile.listBlockedUsers(),
    @(response, err) onReceviedUsersList(EPL_BLOCKLIST, PSN_RESPONSE_FIELDS.blocklist, response, err),
    LIMIT_FOR_ONE_TASK_GET_USERS
  )
}

let function fetchContactsList() {
  pendingContactsChanges.clear()
  checkGroups.clear()

  fetchFriendlist()
  fetchBlocklist()
}

let function updateContacts(needIgnoreInitedFlag = false) {
  if (!isPlatformSony)
    return

  if (!::isInMenu()) {
    if (needIgnoreInitedFlag && isContactsUpdated.value)
      isContactsUpdated(false)
    return
  }

  if (!needIgnoreInitedFlag && isContactsUpdated.value) {
    if (get_time_msec() - LAST_UPDATE_FRIENDS > UPDATE_TIMER_LIMIT)
      LAST_UPDATE_FRIENDS = get_time_msec()
    else
      return
  }

  isContactsUpdated(true)
  fetchContactsList()
}

::add_event_listener("LoginComplete", function(_p) {
  updateContacts(true)

  psn.subscribe.friendslist(function() {
    updateContacts(true)
  })

  psn.subscribe.blocklist(function() {
    updateContacts(true)
  })
})

::add_event_listener("SignOut", function(_p) {
  pendingContactsChanges.clear()
  isContactsUpdated(false)

  psn.unsubscribe.friendslist()
  psn.unsubscribe.blocklist()
  psn.abortAllPendingRequests()
})

return {
  updateContacts
}
