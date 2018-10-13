@LoanBookUI = flight.component ->
  Array::where = (query) ->
    return [] if typeof query isnt "object"
    hit = Object.keys(query).length
    @filter (item) ->
      match = 0
      for key, val of query
        match += 1 if item[key] is val
      if match is hit then true else false

  @attributes
    bookLimit: 30
    demandBookSel: 'table.demands'
    offerBookSel: 'table.offers'
    seperatorSelector: 'table.seperator'

  @update = (event, data) ->
    @updateLoans(@select('offerBookSel'), _.first(data.offers, @.attr.bookLimit), 'offer')
    @updateLoans(@select('demandBookSel'), _.first(data.demands, @.attr.bookLimit), 'demand')

  @appendRow = (book, template, data) ->
    data.classes = 'new'
    book.append template(data)

  @insertRow = (book, row, template, data) ->
    data.classes = 'new'
    row.before template(data)

  @updateRow = (row, v1, v2) ->
    return if v1.equals(v2)

    if v2.greaterThan(v1)
      row.addClass('text-up')
    else
      row.addClass('text-down')

    row.data('amount', v2)
    row.find('td.amount').html(loan_formatter.mask_fixed_amount(v2))

  @mergeUpdate = (offer_or_demand, book, loans, template) ->
    rows = book.find('tr')
    for i in [0...rows.length]
      row = rows[i]
      id = $(row).data('id')
      result = loans.where id:id
      $(row).addClass 'obsolete' unless result.length

    for loan in loans
      existsLoan = book.find("tr[data-id=#{loan.id}]")
      if existsLoan.length
        v1 = new BigNumber(existsLoan.data('amount'))
        v2 = new BigNumber(loan.amount)
        @updateRow(existsLoan, v1, v2)
      else
        is_inserted = false
        for i in [0...rows.length]
          row = rows[i]
          rate = new BigNumber($(row).data('rate'))
          loan_rate = new BigNumber(loan.rate)
          if rate == loan_rate
            duration = new BigNumber($(row).data('duration'))
            loan_duration = new BigNumber(loan.duration)
            if duration.greaterThanOrEqualTo(loan_duration)
              @insertRow(book, $(row), template,
                rate: loan.rate, amount: loan.amount, duration: loan.duration, id: loan.id)
              is_inserted = true
              break
          else if (offer_or_demand == 'demand' && rate.lessThan(loan_rate)) || (offer_or_demand == 'offer' && rate.greaterThan(loan_rate))
            @insertRow(book, $(row), template,
              rate: loan.rate, amount: loan.amount, duration: loan.duration, id: loan.id)
            is_inserted = true
            break

        if !is_inserted
          @appendRow(book, template,
            rate: loan.rate, amount: loan.amount, duration: loan.duration, id: loan.id)

  @clearMarkers = (book) ->
    book.find('tr.new').removeClass('new')
    book.find('tr.text-up').removeClass('text-up')
    book.find('tr.text-down').removeClass('text-down')

    obsolete = book.find('tr.obsolete')
    obsolete_divs = book.find('tr.obsolete div')
    obsolete_divs.slideUp 'slow', ->
      obsolete.remove()

  @updateLoans = (table, loans, offer_or_demand) ->
    book = @select("#{offer_or_demand}BookSel")

    @mergeUpdate offer_or_demand, book, loans, JST["templates/loan_book_#{offer_or_demand}"]

    book.find("tr.new div").slideDown('slow')
    setTimeout =>
      @clearMarkers(@select("#{offer_or_demand}BookSel"))
    , 900

  @after 'initialize', ->
    @on document, 'loan_market::loan_book::update', @update

