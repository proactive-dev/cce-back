@MyOpenLoanOffersUI = flight.component ->
  flight.compose.mixin @, [LoanListMixin]

  @getTemplate = (loan) -> $(JST["templates/my_open_loan_offer"](loan))

  @loanHandler = (event, loan) ->
    if loan.kind.search(/offer/) != -1 # accept offer only
      switch loan.state
        when 'wait'
          @addOrUpdateLoan loan
        when 'cancel'
          @removeLoan loan.id
        when 'reject'
          @removeLoan loan.id
        when 'done'
          @removeLoan loan.id

  @cancelLoan = (tr) ->
    if confirm(loan_formatter.t('place_loan')['confirm_cancel'])
      $.ajax
        url: loan_formatter.loan_market_url tr.data('loan_market'), tr.data('id')
        method: 'delete'

  @updateLoan = (tr) ->
    if confirm(loan_formatter.t('place_loan')['confirm_update'])
      $.ajax
        url: loan_formatter.loan_market_url tr.data('loan_market'), tr.data('id')
        method: 'put'

  @actionLoan = (event) ->
    context = $(event.target).context
    tr = $(event.target).parents('tr')
    if context.className == "cancel"
      @cancelLoan(tr)
    else if context.className == "auto-renew offer"
      @updateLoan(tr)

  @.after 'initialize', ->
    @on document, 'loan::wait::populate', @populate
    @on document, 'loan::wait loan::cancel loan::reject loan::done', @loanHandler
    @on @select('tbody'), 'click', @actionLoan
