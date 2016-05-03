Chartkick.options = {
  height: '100px',
  colors: ['#3bafda'],
  library: {
    elements: {
      point: {
        radius: 0
      },
      line: {
        borderWidth: 6,
        lineTension: 0.0
      },
    },
    scales: {
      xAxes: [{display: false}],
      yAxes: [
        {
          color: '#fff',
          ticks: {
            fontSize: 8,
            fontColor: '#fff'
          },
          gridLines: {
            drawOnChartArea: false,
            color: '#fff',
            drawTicks: false
          },
          scaleLabel: {
            fontSize: 0,
            fontColor:'#fff'
          }
        }
      ]
    }
  },
  content_for: :charts_js
}
