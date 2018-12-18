@PlaceLoanUI = flight.component ->
  @attributes
    formSel: 'form'
    successSel: '.status-success'
    infoSel: '.status-info'
    dangerSel: '.status-danger'

    rateSel: 'input[id$=rate]'
    amountSel: 'input[id$=amount]'
    durationSel: 'input[id$=duration]'
    autoRenewSel: 'input[id$=auto_renew]'

    currentBalanceSel: 'span.current-balance'
    submitButton: ':submit'

  @cleanMsg = ->
    @select('successSel').text('')
    @select('infoSel').text('')
    @select('dangerSel').text('')

  @resetForm = (event) ->
    @trigger 'place_loan::reset::rate'
    @trigger 'place_loan::reset::amount'
    @trigger 'place_loan::reset::duration'
    @trigger 'place_loan::reset::auto_renew'

  @disableSubmit = ->
    @select('submitButton').addClass('disabled').attr('disabled', 'disabled')

  @enableSubmit = ->
    @select('submitButton').removeClass('disabled').removeAttr('disabled')

  @validate = (selector, max) ->
    val = selector.val()
    if max && $.isNumeric(val)
      value = BigNumber(val)
      if value.greaterThan(BigNumber(max))
        selector.val(max)
        false
      else if value.lessThan(0)
        selector.val(null)
        false
      else
        true
    else
      false

  @validateAll = ->
    unless @validate(@select('rateSel'), 100)
      @error_msg = "Invalid rate."
      return false
    unless @validate(@select('amountSel'), @getBalance())
      @error_msg = "Invalid amount."
      return false
    unless @validate(@select('durationSel'), 60)
      @error_msg = "Invalid duration."
      return false
    true

  @showError = (error) ->
    ef_class = 'shake shake-constant hover-stop'
    @select('dangerSel').append(JST["templates/hint_order_warning"]({msg: error})).show()
      .addClass(ef_class).wait(500).removeClass(ef_class)
    @enableSubmit()

  @beforeSend = (event, jqXHR) ->
    if @validateAll()
      @disableSubmit()
    else
      jqXHR.abort()
      @cleanMsg()
      @showError(@error_msg)

  @handleSuccess = (event, data) ->
    @cleanMsg()
    @select('successSel').append(JST["templates/hint_order_success"]({msg: data.message})).show()
    @resetForm(event)
    @enableSubmit()

  @handleError = (event, data) ->
    @cleanMsg()
    json = JSON.parse(data.responseText)
    @showError(json.message)

  @getBalance = ->
    BigNumber( @select('currentBalanceSel').data('balance') )

  @getLastRate = ->
    BigNumber(gon.ticker.last)

  @allIn = (event)->
    @select('rateSel').val(@getLastRate())
    @select('amountSel').val(@getBalance())
    @select('durationSel').val(2)

  @refreshBalance = (event, data) ->
    currency = gon.loan_market.id
    balance = gon.lending_accounts[currency]?.balance || 0

    @select('currentBalanceSel').data('balance', balance)
    @select('currentBalanceSel').text(loan_formatter.mask_balance(balance))

  @updateAvailable = (event, loan) ->
    loan['amount'] = 0 unless loan['amount']
    available = loan_formatter.mask_balance @getBalance().minus(loan['amount'])

    @select('currentBalanceSel').text(available)

  @clear = (e) ->
    @resetForm(e)
    @trigger 'place_loan::focus::rate'

  @after 'initialize', ->
    @error_msg = null
    @on 'place_loan::loan::updated', @updateAvailable
    @on 'place_loan::clear', @clear

    @on document, 'lending_account::update', @refreshBalance

    @on @select('formSel'), 'ajax:beforeSend', @beforeSend
    @on @select('formSel'), 'ajax:success', @handleSuccess
    @on @select('formSel'), 'ajax:error', @handleError

    @on @select('currentBalanceSel'), 'click', @allIn
