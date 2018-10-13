window.GlobalLoanData = flight.component ->

  @after 'initialize', ->
    loan_market_channel = @attr.pusher.subscribe("market-#{gon.loan_market.id}-global")

    loan_market_channel.bind 'update', (data) =>
      gon.demands = data.demands
      gon.offers = data.offers
      @trigger 'loan_market::loan_book::update', demands: data.demands, offers: data.offers

    # Initializing at bootstrap

    if gon.demands and gon.offers
      @trigger 'loan_market::loan_book::update', demands: gon.demands, offers: gon.offers

    if gon.active_loans # is in desc order initially
      # .reverse() will modify original array! It makes gon.active_loans sorted
      # in asc order afterwards
      @trigger 'loan_market::active_loans', active_loans: gon.active_loans.reverse()
