#= require es5-shim.min
#= require es5-sham.min
#= require jquery
#= require jquery_ujs
#= require jquery-timing.min
#= require bootstrap
#= require bootstrap-switch.min
#= require scrollIt
#= require moment
#= require underscore
#= require clipboard.min
#= require flight.min
#= require list
#= require jquery.mousewheel
#= require cookies.min

#= require ./lib/tiny-pubsub

#= require_tree ./helpers
#= require_tree ./component_ui
#= require_tree ./templates

$ ->
  $('[data-clipboard-text], [data-clipboard-target]').each ->
    elem = @

    clipboard = new ClipboardJS (@)

    clipboard.on 'success', (e)->
      console.info('Text:', e.text)
      selectText(elem.getAttribute("data-select-target"))
    clipboard.on 'error', ->
      console.info('error:', e.action)

  selectText = (containerid) ->
    if document.selection # IE
      range = document.body.createTextRange()
      range.moveToElementText(document.getElementById(containerid))
      range.select()
    else if window.getSelection
      range = document.createRange()
      range.selectNode(document.getElementById(containerid))
      window.getSelection().removeAllRanges()
      window.getSelection().addRange(range)

  FlashMessageUI.attachTo('.flash-message')
  SmsAuthVerifyUI.attachTo('#edit_sms_auth')
  TwoFactorAuth.attachTo('.two-factor-auth-container')
