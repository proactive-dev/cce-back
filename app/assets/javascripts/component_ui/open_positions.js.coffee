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
    if @position['state'] == 'open'
      @select('empty').fadeOut()
      @select('positionSel').fadeIn()
    else
      @select('empty').fadeIn()
      @select('positionSel').fadeOut()

  @update = (selector, value) ->
    selector.html(value)

  @updateWithCurrency = (selector, value, currency) ->
    @update(selector, "#{value} #{currency.toUpperCase()}")

  @updateWithCurrencyAndSign = (selector, value, currency) ->
    selector.removeClass('text-up').removeClass('text-down').addClass(formatter.check_sign(value))
    @updateWithCurrency(selector, value, currency)

  @updateDirection = (direction) ->
    @select('directionSel').removeClass('text-up').removeClass('text-down').addClass(formatter.check_direction(direction))
    @select('directionSel').html(formatter.direction(direction))

  @refresh = (event, data) ->
    @updateDirection(@position['direction']) if @position['direction']
    @updateWithCurrency(@select('amountSel'), @position['amount'], @ticker['base_unit']) if @position['direction'] && @ticker['base_unit']
    @update(@select('basePriceSel'), @position['base_price']) if @position['base_price']
    @update(@select('estLiqPriceSel'), @position['est_liq_price']) if @position['est_liq_price']
    @updateWithCurrencyAndSign(@select('unrealizedPnLSel'), @position['unrealized_pnl'], @ticker['quote_unit']) if @position['unrealized_pnl'] && @ticker['quote_unit']
    @updateWithCurrencyAndSign(@select('unrealizedLendingFeeSel'), @position['unrealized_lending_fee'], @ticker['quote_unit']) if @position['unrealized_lending_fee'] && @ticker['quote_unit']

    @checkEmpty()

  @refreshWithTicker = (event, data) ->
    if @position && @position['direction'] && @ticker && @ticker['last']
      price = if @position['direction'] == 'long' then @ticker['buy'] else @ticker['sell']
      @position['unrealized_pnl'] = formatter.fixBid(@position['volume'] - price * @position['amount'] -  @position['lending_fee'])
      @position['unrealized_lending_fee'] = formatter.fixBid(@position['unrealized_lending_fees'][0] * price + @position['unrealized_lending_fees'][1])
      @refresh()

  @refreshWithMarginInfo = (event, data) ->
    if BigNumber(@position['amount']).isZero()
      @position['est_liq_price'] = formatter.fixBid(0)
    else
      @position['est_liq_price'] = formatter.fixBid(Math.abs(@net_value / @position['amount']))
    @refresh()

  @refreshPosition = (position) ->
    @position['id'] = position.id
    @position['direction'] = position.direction
    @position['amount'] = formatter.fixAsk(position.amount)
    @position['base_price'] = formatter.fixBid(position.base_price)
    @position['unrealized_lending_fees'] = position.unrealized_lending_fees
    @position['volume'] = position.volume
    @position['lending_fee'] = position.lending_fees
    @position['state'] = position.state

    @refreshWithTicker()
    @refreshWithMarginInfo()

  @refreshTicker = (event, ticker) ->
    @ticker = ticker
    @refreshWithTicker()

  @promptDialogMsg = ->
    """
    #{formatter.t('position')['prompt_close']}

    #{formatter.t('position')['balance']}: #{@position['amount']} #{@ticker['base_unit'].toUpperCase()}

    #{formatter.t('position')['amount_close']}:
    """

  @confirmDialogMsg = (amount) ->
    """
    #{formatter.t('position')['confirm_close']}

    #{formatter.t('position')['amount_close']}: #{amount} #{@ticker['base_unit'].toUpperCase()}
    """

  @closePosition = (event) ->
    amount = prompt(@promptDialogMsg())
    if amount
      if $.isNumeric(amount) && BigNumber(amount).lessThanOrEqualTo(BigNumber(@position['amount']))
        if confirm(@confirmDialogMsg(amount))
          $.ajax
            url: formatter.position_url(@position['id'])
            method: 'put'
            data: {
              amount: amount
            }
      else
        alert formatter.t('position')['invalid_value']
    else
      alert formatter.t('position')['empty_value']

  @handleSuccess = (event, data) ->
    json = JSON.parse(data.message)

  @handleError = (event, data) ->
    json = JSON.parse(data.responseText)

  @after 'initialize', ->
    @ticker = gon.ticker
    @net_value = 0
    @position = {id: null, direction: null, amount: null, volume: null, base_price: null, est_liq_price: null, unrealized_pnl: null, unrealized_lending_fee: null, unrealized_lending_fees: null, lending_fee: null, state: null}

    @refreshPosition(gon.my_position) if gon.my_position

    @on document, 'market::ticker', @refreshTicker
    @on document, 'position::update', (event, data) =>
      @refreshPosition(data)

    @on document, 'margin_info::update', (event, data) =>
      @net_value = data['net_value']
      @refreshWithMarginInfo()

    @on @select('positionSel'), 'ajax:success', @handleSuccess
    @on @select('positionSel'), 'ajax:error', @handleError

    @on @select('actionSel'), 'click', @closePosition

    @refresh()
