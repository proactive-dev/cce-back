@LoanListMixin = ->
  @attributes
    tbody: 'table > tbody'
    empty: '.empty-row'

  @checkEmpty = (event, data) ->
    if @select('tbody').find('tr.loan').length is 0
      @select('empty').fadeIn()
    else
      @select('empty').fadeOut()

  @addOrUpdateLoan = (loan) ->
    template = @getTemplate(loan)
    existsLoan = @select('tbody').find("tr[data-id=#{loan.id}][data-kind=#{loan.kind}]")

    if existsLoan.length
      existsLoan.html template.html()
    else
      template.prependTo(@select('tbody')).show('slow')

    @checkEmpty()

  @removeLoan = (id) ->
    loan = @select('tbody').find("tr[data-id=#{id}]")
    loan.hide 'slow', =>
      loan.remove()
      @checkEmpty()

  @populate = (event, data) ->
    if not _.isEmpty(data.loans)
      @addOrUpdateLoan loan for loan in data.loans

    @checkEmpty()

