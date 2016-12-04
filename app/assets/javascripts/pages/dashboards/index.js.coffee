#= require pages/app/base

window.App ||= {}

class App.DashboardsIndex extends App.Base
  constructor: (@botId, @dashboardIds, @groupBy) ->
    super()

  dashboardChartConfig: ->
    height: '55px'
    colors: ['#3bafda']
    library:
      elements:
        point:
          radius: 0
        line:
          borderWidth: 6
          lineTension: 0.0
      scales:
        yAxes: [display: false]
        xAxes: [display: false]

  run: ->
    self = @
    $(document).ready ->
      renderGrowth = (growth) ->
        klass = if growth > 0 then 'positive' else 'negative'
        growthString = numeral(growth).format('0%')

        icon = if growth == 0
          "<i class='fa fa-arrows-h'></i>"
        else if growth > 0
          "<i class='fa fa-arrow-up'></i>"
        else
          "<i class='fa fa-arrow-down'></i>"

        "<p class='growth #{klass}'>#{icon}#{growthString}</p>"

      renderDashboard = (did) ->
        url = "/bots/#{self.botId}/dashboards/#{did}/load_async"
        url += "?group_by=#{self.groupBy}" if self.groupBy && self.group_by != ""

        $.getJSON url, (json) ->
          console.log("#{did} -------> ", json)

          if json.growth
            $("#dashboard-#{did}").append(renderGrowth(json.growth))
          $("#dashboard-#{did}").append("<p class='number'>#{numeral(json.count).format('0,0')}</p>")
          $("#dashboard-#{did}").removeClass('loading')
          new Chartkick.LineChart("chart-#{did}", json.data, self.dashboardChartConfig())

      for dashboardId in self.dashboardIds
        renderDashboard(dashboardId)

      $('.stat').click (e) ->
        stat = $(e.target)
        # Button Press
        if stat.parents('form.button_to').length > 0
          return true

        if !stat.hasClass('stat')
          stat = stat.parents('div.stat')

        Turbolinks.visit(stat.attr('data-ref'))
        return false

      $('.stat').mouseenter (e) ->
        stat = $(e.target)
        if !stat.hasClass('stat')
          stat = stat.parents('div.stat')

        stat.css('cursor', 'pointer')
        stat.children('form.button_to').css('visibility', 'visible')
        stat.addClass('active')

      $('.stat').mouseleave (e) ->
        stat = $(e.target)
        if !stat.hasClass('stat')
          stat = stat.parents('div.stat')

        stat.css('cursor', 'auto')
        stat.children('form.button_to').css('visibility', 'hidden')
        stat.removeClass('active')

