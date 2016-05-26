#= require pages/app/base

window.App ||= {}

class App.VerifyingWebhook extends App.AppBase
  constructor: (@botId, @pusherAPIKey) ->
    super()

  run: ->
    self = @

    $(document).ready ->
      pusher = new Pusher(self.pusherAPIKey)
      channel = pusher.subscribe 'webhook-validate-bot'
      channel.bind "webhook-validate-bot-#{self.botId}", (data) ->
        $('.progress-bar').css('width', '100%')
        response = JSON.parse(data.message)

        if response.ok
          $('.setup-done').show()
          $('.verified-failed').hide()
        else
          $('.setup-done').show()
          $('.verified-success').hide()
