#= require es5-shim.min
#= require es5-sham.min
#= require jquery
#= require jquery_ujs
#= require jquery.mousewheel
#= require jquery-timing.min
#= require jquery.nicescroll.min
#
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

#= require highstock
#= require_tree ./highcharts/

#= require_tree ./helpers
#= require_tree ./component_mixin
#= require_tree ./component_data
#= require_tree ./component_ui
#= require_tree ./templates

#= require_self

$ ->
  window.notifier = new Notifier()

  BigNumber.config(ERRORS: false)

  HeaderUI.attachTo('header')

  FloatUI.attachTo('.float')
  KeyBindUI.attachTo(document)
  AutoMarginWindowUI.attachTo(window)

  PlaceMarginOrderUI.attachTo('#bid_entry')
  PlaceMarginOrderUI.attachTo('#ask_entry')
  OrderBookUI.attachTo('#order_book')
  DepthUI.attachTo('#depths_wrapper')

  MyMarginOrdersUI.attachTo('#my_orders')
  MarketTickerUI.attachTo('#ticker')
  MarginMarketSwitchUI.attachTo('#market_list_wrapper')
  MarketTradesUI.attachTo('#market_trades_wrapper')

  MarketData.attachTo(document)
  GlobalData.attachTo(document, {pusher: window.pusher})
  MemberData.attachTo(document, {pusher: window.pusher})

  OpenPositionsUI.attachTo('#open_positions')
  MarginInfoUI.attachTo('#margin_info')

  CandlestickUI.attachTo('#candlestick')
  SwitchUI.attachTo('#range_switch, #indicator_switch, #main_indicator_switch, #type_switch')

  $('.panel-body-content').niceScroll
    autohidemode: true
    cursorborder: "none"
