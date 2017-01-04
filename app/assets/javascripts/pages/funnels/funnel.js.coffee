window.App ||= {}

class App.Funnel
  @hsvToRgb: (h, s, v) ->
    h_i = parseInt(h*6)
    f = h*6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)
    [r, g, b] = [v, t, p] if h_i==0
    [r, g, b] = [q, v, p] if h_i==1
    [r, g, b] = [p, v, t] if h_i==2
    [r, g, b] = [p, q, v] if h_i==3
    [r, g, b] = [t, p, v] if h_i==4
    [r, g, b] = [v, p, q] if h_i==5
    [parseInt(r*256), parseInt(g*256), parseInt(b*256)]

  @colors: _.map [1...50], (v) ->
    goldenRatioConjugate = 0.618033988749895
    h = Math.random()
    h += goldenRatioConjugate
    h %= 1
    Funnel.hsvToRgb(h, 0.5, 0.95)

  constructor: (@botId, @funnelId, @step, @startDate, @endDate, @miniature = true) ->

  constructChartJsData: (insights) ->
    count = 0
    datasets = []

    # rgb(59,175,218) is the botmetrics color
    _.each insights, (pair, i) ->
      [k,v] = pair
      [r,g,b] = Funnel.colors[count]
      datasets.push({data: [v], backgroundColor: "rgb(#{r},#{g},#{b})", label: k})
      count = (count + 1) % 49
    datasets

  renderChart: (datasets) ->
    self = this
    ctx = document.getElementById("step-#{self.step}").getContext("2d")
    ctx.canvas.height = 40

    new Chart ctx,
      type: 'horizontalBar'
      data:
        labels: []
        datasets: datasets
      options:
        tooltips:
          bodyFontSize: if self.miniature then 11 else 16
          callbacks:
            label: (tooltipItem, data) ->
              datasetIndex = tooltipItem.datasetIndex
              dataItem = data.datasets[datasetIndex]
              steps = parseInt(dataItem.label)
              numUsers = parseInt(dataItem.data[0])
              if steps == 0
                "#{numUsers} use#{if numUsers == 1 then 'r' else 'rs'} performed the next action immediately"
              else
                "#{numUsers} use#{if numUsers == 1 then 'r' else 'rs'} went through #{steps} ste#{if steps == 1 then 'p' else 'ps'} before the next action"

        legend:
          display: false
        scales:
          tooltips:
            enabled: false
          yAxes: [
            display: false
            stacked: true
            gridLines:
              display: false
          ]
          xAxes: [
            display: true
            gridLines:
              drawTicks: false
              tickMarkLength: 2
              drawBorder: false
            ticks:
              beginAtZero: true
              fontSize: if self.miniature then 10 else 14
            stacked: true
          ]

  renderInsightAsync: ->
    self = this
    url = "/bots/#{self.botId}/paths/#{self.funnelId}/insights?step=#{self.step}&start=#{self.startDate}&end=#{self.endDate}"

    $.getJSON url, (json) ->
      $("#step-col-#{self.step}").removeClass('loading')
      self.renderChart(self.constructChartJsData(json.insights))

      $("#step-#{self.step}").click (e) ->
        Turbolinks.visit(url)

