#= require pages/app/base

window.App ||= {}

class App.BotsNewBots extends App.AppBase
  constructor: () ->
    super()

  run: ->
    self = @
    $(document).ready ->
      cb = (start, end) ->
        $('#report-range span').html(start.format('MMMM D, YYYY') + ' - ' + end.format('MMMM D, YYYY'))
      cb(moment().subtract(29, 'days'), moment())
      $('#report-range').daterangepicker
        ranges:
          'Today': [moment(), moment()]
          'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')]
          'Last 7 Days': [moment().subtract(6, 'days'), moment()]
          'Last 30 Days': [moment().subtract(29, 'days'), moment()]
          'This Month': [moment().startOf('month'), moment().endOf('month')]
        , cb

