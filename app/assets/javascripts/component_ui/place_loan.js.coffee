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

  @confirmDialogMsg = ->
    confirmType = @select('submitButton').text()
    rate = @select('rateSel').val()
    amount = @select('amountSel').val()
    duration = @select('durationSel').val()
    auto_renew = @select('autoRenewSel').val()
    """
    #{gon.i18n.place_loan.confirm_submit} "#{confirmType}"?

    #{gon.i18n.place_loan.rate}: #{rate}
    #{gon.i18n.place_loan.amount}: #{amount}
    #{gon.i18n.place_loan.duration}: #{duration}
    #{gon.i18n.place_loan.auto_renew}: #{auto_renew}
    """

  @beforeSend = (event, jqXHR) ->
    if true #confirm(@confirmDialogMsg())
      @disableSubmit()
    else
      jqXHR.abort()

  @handleSuccess = (event, data) ->
    @cleanMsg()
    @select('successSel').append(JST["templates/hint_order_success"]({msg: data.message})).show()
    @resetForm(event)
    @enableSubmit()

  @handleError = (event, data) ->
    @cleanMsg()
    ef_class = 'shake shake-constant hover-stop'
    json = JSON.parse(data.responseText)
    @select('dangerSel').append(JST["templates/hint_order_warning"]({msg: json.message})).show()
      .addClass(ef_class).wait(500).removeClass(ef_class)
    @enableSubmit()

  @getBalance = ->
    BigNumber( @select('currentBalanceSel').data('balance') )

  @getLastRate = ->
    BigNumber(gon.ticker.last)

  @allIn = (event)->
    @trigger 'place_loan::input::rate', {rate: @getLastRate()}
    @trigger 'place_loan::input::amount', {amount: @getBalance()}

  @refreshBalance = (event, data) ->
    currency = gon.loan_market.id
    balance = gon.lending_accounts[currency]?.balance || 0

    @select('currentBalanceSel').data('balance', balance)
    @select('currentBalanceSel').text(loan_formatter.mask_balance(balance))

    @trigger 'place_loan::balance::change', balance: BigNumber(balance)
    @trigger 'place_loan::max::amount', max: BigNumber(balance)

  @updateAvailable = (event, loan) ->
    loan['amount'] = 0 unless loan['amount']
    available = loan_formatter.mask_balance @getBalance().minus(loan['amount'])

    @select('currentBalanceSel').text(available)

  @clear = (e) ->
    @resetForm(e)
    @trigger 'place_loan::focus::rate'

  @after 'initialize', ->

    PlaceLoanData.attachTo @$node
#    LoanRateUI.attachTo   @select('rateSel'),  form: @$node, type: type
#    LoanAmountUI.attachTo  @select('amountSel'), form: @$node, type: type

    @on 'place_loan::loan::updated', @updateAvailable
    @on 'place_loan::clear', @clear

    @on document, 'lending_account::update', @refreshBalance

    @on @select('formSel'), 'ajax:beforeSend', @beforeSend
    @on @select('formSel'), 'ajax:success', @handleSuccess
    @on @select('formSel'), 'ajax:error', @handleError

    @on @select('currentBalanceSel'), 'click', @allIn
