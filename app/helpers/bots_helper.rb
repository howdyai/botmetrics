module BotsHelper
  def solo_chartjs_opts(group_by)
    {
      library: {
        elements: {
          point: {
            radius: 6
          },
          line: {
            borderWidth: 5,
            lineTension: 0.0
          },
        },
        scales: {
          yAxes: [
            {
              ticks: {
                fontSize: 16
              }
            }
          ],
          xAxes: [
            {
              ticks: {
                fontSize: group_by == 'hour' ? 10 : 16
              },
              time: {
                displayFormats: {
                  'day': 'MMM D',
                  'week': 'MMM D',
                  'hour': 'MMM D, HH:mm'
                }
              }
            }
          ]
        }
      }
    }
  end

  def dashboard_chartjs_opts
    {
      height: '60px',
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
      }
    }
  end

  def formatted_growth(growth)
    if growth.present?
      growth = growth * 100
      klass = growth > 0 ? 'positive' : 'negative'

      icon = if growth.to_f == 0.0
               "<i class='fa fa-arrows-h'></i>"
             elsif growth.to_f > 0.0
               "<i class='fa fa-arrow-up'></i>"
             else
               "<i class='fa fa-arrow-down'></i>"
             end

      "<p class='growth #{klass}'>#{icon}#{number_to_percentage(growth, precision: 0)}</p>".html_safe
    else
      nil
    end
  end

  def formatted_elapsed_time(time)
    time > 1 ? "#{"%.2f" % time} secs" : "#{"%.2f" % (time * 1000)} ms"
  end

  def webhook_label(bot)
    return 'Webhook URL' if bot.webhook_url.blank?

    if bot.webhook_status
      'Webhook URL <i class="fa fa-check webhook-success"></i>'.html_safe
    else
      'Webhook URL <i class="fa fa-exclamation-triangle webhook-failed"></i>'.html_safe
    end
  end
end
