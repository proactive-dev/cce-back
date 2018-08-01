@OrderPriceUI = flight.component ->
  flight.compose.mixin @, [OrderInputMixin]

  @attributes
    precision: gon.market.bid.fixed
    variables:
      input: 'price'
      known: 'volume'
      output: 'total'

  @getLastPrice = ->
    Number gon.ticker.last

  @getConfig = ->
    gon.price_config

  @getConfigType = ->
    @getConfig().price_type

  @getConfigPrice = ->
    BigNumber @getConfig().price

  @toggleAlert = (event) ->
    switch @getConfigType()
      when 'min_limit'
        limitPrice = @getConfigPrice()

        switch
          when @value >= limitPrice
            @trigger 'place_order::price_alert::hide'
          else
            @trigger 'place_order::price_alert::show', {label: 'price_min_limit'}
            @$node.val limitPrice
      else
        lastPrice = @getLastPrice()

        switch
          when !@value
            @trigger 'place_order::price_alert::hide'
          when @value > (lastPrice * 1.1)
            @trigger 'place_order::price_alert::show', {label: 'price_high'}
          when @value < (lastPrice * 0.9)
            @trigger 'place_order::price_alert::show', {label: 'price_low'}
          else
            @trigger 'place_order::price_alert::hide'

  @onOutput = (event, order) ->
    price = order.total.div order.volume
    @$node.val price

  @after 'initialize', ->
    @on 'focusout', @toggleAlert

    switch @getConfigType()
      when 'fixed'
        @$node.val @getConfigPrice()
        @trigger 'place_order::input::price', {price: @getConfigPrice()}
        @$node.attr('disabled', 'disabled')
      when 'min_limit'
        @$node.val @getConfigPrice()
        @trigger 'place_order::input::price', {price: @getConfigPrice()}
      else
        @trigger 'place_order::price_alert::hide'
