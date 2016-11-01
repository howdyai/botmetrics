#= require pages/app/base

window.App ||= {}

class App.RetentionIndex extends App.AppBase
  constructor: (@retentionNumbers, @start, @end, @groupBy) ->
    @startDate = new Date(@start)
    @endDate = new Date(@end)
    @start = moment(@start)
    @end = moment(@end)
    super()

  run: ->
    self = @
    $(document).ready ->
      container = document.getElementById('retention')

      timeInterval = switch self.groupBy
        when 'week'   then 'weekly'
        when 'day'    then 'daily'
        when 'month'  then 'monthly'
        else 'weekly'

      intervalString = "(#{self.startDate.toLocaleDateString()} - #{self.endDate.toLocaleDateString()})"
      title = switch self.groupBy
        when 'week'   then "Weekly Retention #{intervalString}"
        when 'day'    then "Daily Retention #{intervalString}"
        when 'month'  then "Monthly Retention #{intervalString}"

      Cornelius.draw
        initialDate: self.startDate
        container: container
        cohort: self.retentionNumbers
        title: title
        timeInterval: timeInterval

      cb = (start, end) ->
        $('#report-range span').html(start.format('MMM D, YYYY') + ' - ' + end.format('MMM D, YYYY'))
      cb(self.start, self.end)

      $('#report-range').daterangepicker
        ranges:
          'Last 4 weeks': [moment().subtract(4, 'weeks'), moment()]
          'Last 8 weeks': [moment().subtract(2, 'months'), moment()]
          'Last 16 weeks': [moment().subtract(4, 'months'), moment()]
          'Last 24 weeks': [moment().subtract(6, 'months'), moment()]
        , cb
      $('#report-range').on 'apply.daterangepicker', (ev, picker) ->
        start = picker.startDate.format('MMM DD, YYYY')
        end = picker.endDate.format('MMM DD, YYYY')
        uri = new Uri(window.location.href).
                replaceQueryParam('start', start).
                replaceQueryParam('end', end).toString()
        Turbolinks.visit(uri)
      $('.time-segmented-controls a').click (e) ->
        uri = new Uri(window.location.href).
                replaceQueryParam('group_by', $(this).attr('data-group')).toString()
        Turbolinks.visit(uri)
        e.preventDefault()

