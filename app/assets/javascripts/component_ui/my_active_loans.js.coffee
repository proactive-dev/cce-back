@MyActiveLoansUI = flight.component ->

  @attributes
    tbody: 'table > tbody'
    empty: '.empty-row'

  @getTemplate = (active_loan) -> $(JST["templates/my_active_loan"](active_loan))

  @checkEmpty = (event, data) ->
    if @select('tbody').find('tr.active_loan').length is 0
      @select('empty').fadeIn()
    else
      @select('empty').fadeOut()

  @activeLoanHandler = (event, active_loan) ->
    switch active_loan.state
      when 'done'
        @removeActiveLoan active_loan.id

  @updateActiveLoan = (tr) ->
    if confirm(loan_formatter.t('place_loan')['confirm_update'])
      $.ajax
        url: loan_formatter.loan_market_url tr.data('loan_market')
        method: 'put'
        data: {active_loan_id: tr.data('id')}

  @actionActiveLoan = (event) ->
    context = $(event.target).context
    tr = $(event.target).parents('tr')
    if context.className == "auto-renew offer"
      @updateActiveLoan(tr)

  @removeActiveLoan = (id) ->
    active_loan = @select('tbody').find("tr[data-id=#{id}]")
    active_loan.hide 'slow', =>
      active_loan.remove()
      @checkEmpty()

  @addOrUpdateActiveLoan = (active_loan) ->
    template = @getTemplate(active_loan)
    existsActiveLoan = @select('tbody').find("tr[data-id=#{active_loan.id}][data-kind=#{active_loan.kind}]")

    if existsActiveLoan.length
      existsActiveLoan.html template.html()
    else
      template.prependTo(@select('tbody')).show('slow')

    @checkEmpty()

  @populate = (event, data) ->
    if not _.isEmpty(data.active_loans)
      @addOrUpdateActiveLoan active_loan for active_loan in data.active_loans

    @checkEmpty()

  @.after 'initialize', ->
    @on document, 'active_loan::populate', @populate
    @on document, 'active_loan', (event, active_loan) =>
      @populate(event, active_loans: [active_loan])

    @on document, 'loan_market::active_loans',  @populate

    @on document, 'active_loan::done', @activeLoanHandler

    @on @select('tbody'), 'click', @actionActiveLoan
