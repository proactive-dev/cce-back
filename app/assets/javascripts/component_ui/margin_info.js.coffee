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
    @updateWithCurrency(@select('totalSel'), @margin_info['total_margin'], @margin_info['quote_unit'])
    @updateWithCurrency(@select('netValueSel'), @margin_info['net_value'], @margin_info['quote_unit'])
    @updateWithCurrency(@select('totalBorrowedSel'), @margin_info['total_borrowed'], @margin_info['quote_unit'])
    @updateWithCurrencyAndSign(@select('unrealizedPnLSel'), @margin_info['unrealized_pnl'], @margin_info['quote_unit'])
    @updateWithCurrencyAndSign(@select('unrealizedLendingFeeSel'), @margin_info['unrealized_lending_fee'], @margin_info['quote_unit'])
    @update(@select('currentMarginSel'), @margin_info['current_margin'])

  @after 'initialize', ->
    @margin_info = {
      total_margin: 0,
      unrealized_pnl: 0,
      unrealized_lending_fee: 0,
      net_value: 0,
      total_borrowed: 0,
      current_margin: 100,
      quote_unit: 'btc'
    }

    @on document, 'margin_info::update', (event, data) =>
      @margin_info = data
      @refresh()

    @refresh()
