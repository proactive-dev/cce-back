@MyMarginOrdersUI = flight.component ->
  flight.compose.mixin @, [MarginItemListMixin]

  @getTemplate = (order) -> $(JST["templates/margin_order_active"](order))

  @orderHandler = (event, order) ->
    return unless order.market == gon.market.id

    switch order.state
      when 'wait'
        @addOrUpdateItem order
      when 'cancel'
        @removeItem order
      when 'done'
        @removeItem order

  @cancelOrder = (event) ->
    tr = $(event.target).parents('tr')
    if confirm(formatter.t('place_order')['confirm_cancel'])
      if tr.data('kind').search(/trigger/) == -1
        $.ajax
          url: formatter.market_url gon.market.id, tr.data('id')
          method: 'delete'
      else
        $.ajax
          url: formatter.margin_market_url gon.market.id, tr.data('id')
          method: 'delete'

  @.after 'initialize', ->
    @on document, 'margin_order::wait::populate', @populate
    @on document, 'margin_order::wait margin_order::cancel margin_order::done', @orderHandler
    @on document, 'order::wait::populate', @populate
    @on document, 'order::wait order::cancel order::done', @orderHandler
    @on @select('tbody'), 'click', @cancelOrder
