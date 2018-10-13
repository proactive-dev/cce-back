@PlaceLoanData = flight.component ->

  @onInput = (event, data) ->
    {input: @input, known: @known, output: @output} = data.variables
    @loan[@input] = data.value

    return unless @loan[@input] && @loan[@known]
    @trigger "place_loan::output::#{@output}", @loan

  @onReset = (event, data) ->
    {input: @input, known: @known, output: @output} = data.variables
    @loan[@input] = @loan[@output] = null

    @trigger "place_loan::reset::#{@output}"
    @trigger "place_loan::loan::updated", @loan

  @after 'initialize', ->
    @loan = {rate: null, amount: null, duration: null, auto_renew: 0}

    @on 'place_loan::input', @onInput
    @on 'place_loan::reset', @onReset
