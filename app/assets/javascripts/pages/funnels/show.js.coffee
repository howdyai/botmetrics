#= require pages/app/base

window.App ||= {}

class App.FunnelsShow extends App.AppBase
  constructor: (@xAxis, @yAxis, @start, @end) ->
    @start = moment(@start)
    @end = moment(@end)
    super()

  run: ->
    self = this
    ctx = $('#funnel-canvas')

    cb = (start, end) ->
      $('#report-range span').html(start.format('MMM D, YYYY') + ' - ' + end.format('MMM D, YYYY'))
    cb(self.start, self.end)

    $('#report-range').daterangepicker
      ranges:
        'Today': [moment(), moment()]
        'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')]
        'Last 7 Days': [moment().subtract(6, 'days'), moment()]
        'Last 30 Days': [moment().subtract(29, 'days'), moment()]
        'This Month': [moment().startOf('month'), moment().endOf('month')]
      , cb
    $('#report-range').on 'apply.daterangepicker', (ev, picker) ->
      start = picker.startDate.format('MMM DD, YYYY')
      end = picker.endDate.format('MMM DD, YYYY')
      uri = new Uri(window.location.href).
              replaceQueryParam('start', start).
              replaceQueryParam('end', end).toString()
      Turbolinks.visit(uri)

    new Chart ctx,
      type: 'bar'
      data:
        labels: self.xAxis
        datasets: [
          data: self.yAxis
          backgroundColor: 'rgba(54, 162, 235, 0.2)'
          borderColor: 'rgba(54, 162, 235, 1)'
          borderWidth: 1
        ]
      options:
        legend:
          display: false
        scales:
          yAxes: [
            ticks:
              beginAtZero:true
          ]

