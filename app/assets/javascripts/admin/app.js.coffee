$ ->
  $('input[name*=created_at]').datetimepicker()

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
