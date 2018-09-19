$(window).load ->

  # clipboard
  $.subscribe 'deposit_address:create', (event, data) ->
    $('[data-clipboard-text], [data-clipboard-target]').each ->
      elem = @
      clipboard = new ClipboardJS (@)

      clipboard.on 'success', (e)->
        console.info('Text:', e.text)
        selectText(elem.getAttribute("data-select-target"))
      clipboard.on 'error', ->
        console.info('error:', e.action)

  # qrcode
  $.subscribe 'deposit_address:create', (event, data) ->
    code = if data then data else $('#deposit_address').attr("data-text")
    code = code.replace(/\s/g, "") if code

    $("#qrcode").attr('data-text', code)
    $("#qrcode").attr('title', code)
    $('.qrcode-container').each (index, el) ->
      $el = $(el)
      $("#qrcode img").remove()
      $("#qrcode canvas").remove()

      new QRCode el,
        text:   $("#qrcode").attr('data-text')
        width:  $el.data('width')
        height: $el.data('height')

  $.publish 'deposit_address:create'

  # flash message
  $.subscribe 'flash', (event, data) ->
    $('.flash-messages').show()
    $('#flash-content').html(data.message)
    setTimeout(->
      $('.flash-messages').hide(1000)
    , 10000)

  # init the two factor auth
  $.subscribe 'two_factor_init', (event, data) ->
    TwoFactorAuth.attachTo('.two-factor-auth-container')

  $.publish 'two_factor_init'

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
