#= require es5-shim.min
#= require es5-sham.min
#= require jquery
#= require jquery_ujs
#= require jquery.mousewheel
#= require jquery-timing.min
#= require jquery.nicescroll.min

#= require bootstrap
#= require bootstrap-switch.min
#
#= require moment
#= require bignumber
#= require underscore
#= require cookies.min
#= require flight.min
#= require pusher.min

#= require ./lib/sfx
#= require ./lib/notifier
#= require ./lib/pusher_connection

#= require_tree ./helpers
#= require_tree ./component_mixin
#= require_tree ./component_data
#= require_tree ./component_ui
#= require_tree ./templates

#= require_self

$ ->
  window.notifier = new Notifier()

  BigNumber.config(ERRORS: false)

  LoanMarketsUI.attachTo('#loan_markets')
  PlaceLoanUI.attachTo('#loan_entry')

  LoanBookUI.attachTo('#loan_book')

  MyOpenLoansUI.attachTo('#my_open_loans')
  MyActiveLoansUI.attachTo('#my_active_loans')

  GlobalLoanData.attachTo(document, {pusher: window.pusher})
  MemberData.attachTo(document, {pusher: window.pusher}) if gon.lending_accounts

  $('.panel-body-content').niceScroll
    autohidemode: true
    cursorborder: "none"

@LoanMarketsUI = flight.component ->
  @attributes
    current_loan_market: '#current_loan_market'

  @after 'initialize', ->
    loan_market = gon.loan_market
    @loan_markets = gon.loan_markets
    @select('current_loan_market').text "#{loan_market.name.toUpperCase()}"
