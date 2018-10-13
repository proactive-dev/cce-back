class LoanFormatter
  round: (str, fixed) ->
    BigNumber(str).round(fixed, BigNumber.ROUND_HALF_UP).toF(fixed)

  precision: (str) ->
    str = '0' unless $.isNumeric(str)
    @.round(str, gon.loan_market.precision)

  mask_rate: (rate) ->
    rate.replace(/\..*/, "<g>$&</g>")

  mask_fixed_rate: (rate) ->
    str = @mask_rate @precision(rate)
    str.concat("%")

  mask_fixed_amount: (amount) ->
    @.precision(amount).replace(/\..*/, "<g>$&</g>")

  mask_duration: (duration) ->
    days = if BigNumber(duration) > 1 then " Days" else " Day"
    "#{duration}".concat(days)

  fulltime: (timestamp) ->
    m = moment.unix(timestamp)
    "#{m.format("MM/DD HH:mm")}"

  check_trend: (type) ->
    if type == 'offer' or type == '_offer' or type == true
      true
    else if type == 'demand' or type == '_demand' or type == false
      false
    else
      throw "unknown trend symbol #{type}"

  trend: (type) ->
    if @.check_trend(type)
      "text-up"
    else
      "text-down"

  loan_market_url: (loan_market, loan_id) ->
    if loan_id?
      "/loan_markets/#{loan_market}/open_loans/#{loan_id}"
    else
      "/loan_markets/#{loan_market}"

  mask_auto_renew: (auto_renew) ->
    if auto_renew == true
      loan_formatter.t('on')
    else
      loan_formatter.t('off')

  type: (type) ->
    if type == 'offer'
      loan_formatter.t('offer')
    else if type == 'demand'
      loan_formatter.t('demand')
    else
      'n/a'

  t: (key) ->
    gon.i18n[key]

window.loan_formatter = new LoanFormatter()
