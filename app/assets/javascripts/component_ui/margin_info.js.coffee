@MarginInfoUI = flight.component ->
  @attributes
    totalSel: '.total .value'
    unrealizedPnLSel: '.unrealized_pnl .value'
    unrealizedLendingFeeSel: '.unrealized_lending_fee .value'
    netValueSel: '.net_value .value'
    totalBorrowedSel: '.total_borrowed .value'
    currentMarginSel: '.current_margin .value b'

  @update = (selector, value) ->
    selector.html(value)

  @updateWithCurrency = (selector, value, currency) ->
    @update(selector, "#{formatter.fixAsk(value)} #{currency.toUpperCase()}")

  @updateWithCurrencyAndSign = (selector, value, currency) ->
    selector.removeClass('text-up').removeClass('text-down').addClass(formatter.check_sign(value))
    @updateWithCurrency(selector, value, currency)

  @refresh = (event, data) ->
    @updateWithCurrency(@select('totalSel'), data['total_margin'], data['quote_unit']) && data['quote_unit']
    @updateWithCurrency(@select('netValueSel'), data['net_value'], data['quote_unit']) && data['quote_unit']
    @updateWithCurrency(@select('totalBorrowedSel'), data['total_borrowed'], data['quote_unit'])
    @updateWithCurrencyAndSign(@select('unrealizedPnLSel'), data['unrealized_pnl'], data['quote_unit'])
    @updateWithCurrencyAndSign(@select('unrealizedLendingFeeSel'), data['unrealized_lending_fee'], data['quote_unit'])
    @update(@select('currentMarginSel'), data['current_margin'])

  @after 'initialize', ->
    @on document, 'margin_info::update', @refresh
