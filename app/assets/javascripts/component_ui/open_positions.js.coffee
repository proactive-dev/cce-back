@OpenPositionsUI = flight.component ->
  @attributes
    directionSel: '.direction'
    amountSel: '.amount'
    basePriceSel: '.base_price'
    estLiqPriceSel: '.est_liq_price'
    unrealizedPnLSel: '.unrealized_pnl'
    unrealizedLendingFeeSel: '.unrealized_lending_fee'
    actionSel: '.action'
    positionSel: '.position'
    empty: '.empty-row'

  @checkEmpty = (event, data) ->
    if @position['direction']
      @select('empty').fadeOut()
      @select('positionSel').fadeIn()
    else
      @select('empty').fadeIn()
      @select('positionSel').fadeOut()

  @update = (selector, value) ->
    selector.html(value)

  @updateWithNumberFormat = (selector, value) ->
    @update(selector, value)

  @updateWithCurrency = (selector, value, currency) ->
    @update(selector, "#{value} #{currency.toUpperCase()}")

  @updateWithCurrencyAndSign = (selector, value, currency) ->
    selector.removeClass('text-up').removeClass('text-down').addClass(formatter.check_sign(value))
    @updateWithCurrency(selector, value, currency)

  @updateDirection = (direction) ->
    @select('directionSel').removeClass('text-up').removeClass('text-down').addClass(formatter.check_direction(direction))
    @select('directionSel').html(formatter.direction(direction))

  @updateUnrealizedPnL = (est_liq_price) ->
    @select('estLiqPriceSel').html(est_liq_price)

  @refresh = (event, data) ->
    @updateDirection(@position['direction']) if @position['direction']
    @updateWithCurrency(@select('amountSel'), @position['amount'], @ticker['base_unit']) if @position['direction'] && @ticker['base_unit']
    @update(@select('basePriceSel'), @position['base_price']) if @position['base_price']
    @update(@select('estLiqPriceSel'), @position['est_liq_price']) if @position['est_liq_price']
    @updateWithCurrencyAndSign(@select('unrealizedPnLSel'), @position['unrealized_pnl'], @ticker['quote_unit']) if @position['unrealized_pnl'] && @ticker['quote_unit']
    @updateWithCurrencyAndSign(@select('unrealizedLendingFeeSel'), @position['unrealized_lending_fee'], @ticker['quote_unit']) if @position['unrealized_lending_fee'] && @ticker['quote_unit']

    @checkEmpty()

  @refreshData = (event, data) ->
    if @position && @position['direction'] && @ticker && @ticker['last']
      @position['est_liq_price'] = formatter.fixBid(if @position['direction'] == 'long' then @ticker['buy'] else @ticker['sell'])
      @position['unrealized_pnl'] = formatter.fixBid(-0.1) # TODO: REPLACE
      @position['unrealized_lending_fee'] = formatter.fixBid(0.1) # TODO: REPLACE

    @refresh()

  @refreshPosition = (event, position) ->
    @position['id'] = position.id
    @position['direction'] = position.direction
    @position['amount'] = formatter.fixAsk(position.amount)
    @position['base_price'] = formatter.fixBid(position.base_price)

    @refreshData()

  @refreshTicker = (event, ticker) ->
    @ticker['last'] = ticker.last
    @ticker['buy'] = ticker.buy
    @ticker['sell'] = ticker.sell
    @ticker['base_unit'] = ticker.base_unit
    @ticker['quote_unit'] = ticker.quote_unit

    @refreshData()

  @promptDialogMsg = ->
    """
    #{formatter.t('position')['prompt_close']}

    #{formatter.t('position')['balance']}: #{@position['amount']} #{@ticker['base_unit'].toUpperCase()}

    #{formatter.t('position')['amount_close']}:
    """

  @confirmDialogMsg = ->
    """
    #{formatter.t('position')['confirm_close']}

    #{formatter.t('position')['amount_close']}: #{@position['amount']} #{@ticker['base_unit'].toUpperCase()}
    """

  @closePosition = (event) ->
    amount = prompt(@promptDialogMsg())
    if amount
      if $.isNumeric(amount) && BigNumber(amount).lessThanOrEqualTo(BigNumber(@position['amount']))
        if confirm(@confirmDialogMsg())
          $.ajax
            url: formatter.position_url(@position['id'])
            method: 'put'
            data: {
              amount: amount
            }
          return
      alert formatter.t('position')['invalid_value']

  @handleSuccess = (event, data) ->
    json = JSON.parse(data.message)

  @handleError = (event, data) ->
    json = JSON.parse(data.responseText)

  @after 'initialize', ->
    @position = {id: null, direction: null, amount: null, base_price: null, est_liq_price: null, unrealized_pnl: null, unrealized_lending_fee: null, state: null}
    @ticker = {last: null, buy: null, sell: null, base_unit: null, quote_unit: null}

    @on document, 'market::ticker', @refreshTicker
    @on document, 'position::update', @refreshPosition

    @on @select('positionSel'), 'ajax:success', @handleSuccess
    @on @select('positionSel'), 'ajax:error', @handleError

    @on @select('actionSel'), 'click', @closePosition
