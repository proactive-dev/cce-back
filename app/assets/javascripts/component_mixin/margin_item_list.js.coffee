@MarginItemListMixin = ->
  @attributes
    tbody: 'table > tbody'
    empty: '.empty-row'

  @checkEmpty = (event, data) ->
    if @select('tbody').find('tr.order').length is 0
      @select('empty').fadeIn()
    else
      @select('empty').fadeOut()

  @addOrUpdateItem = (item) ->
    template = @getTemplate(item)
    if item.rate
      kind = "trigger_" + item.kind
    else
      kind = item.kind

    existsItem = @select('tbody').find("tr[data-id=#{item.id}][data-kind=#{kind}]")

    if existsItem.length
      existsItem.html template.html()
    else
      template.prependTo(@select('tbody')).show('slow')

    @checkEmpty()

  @removeItem = (item) ->
    if item.rate
      kind = "trigger_" + item.kind
    else
      kind = item.kind

    existsItem = @select('tbody').find("tr[data-id=#{item.id}][data-kind=#{kind}]")
    existsItem.hide 'slow', =>
      existsItem.remove()
      @checkEmpty()

  @populate = (event, data) ->
    if not _.isEmpty(data.orders)
      @addOrUpdateItem item for item in data.orders

    @checkEmpty()

