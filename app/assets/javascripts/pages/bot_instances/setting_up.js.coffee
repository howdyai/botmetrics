#= require pages/app/base

window.App ||= {}

class App.BotInstancesSetup extends App.AppBase
  constructor: (@instanceId, @pusherAPIKey) ->
    super()

  run: ->
    self = @

    $(document).ready ->
      pusher = new Pusher(self.pusherAPIKey)
      channel = pusher.subscribe "setup-bot"
      channel.bind "setup-bot-#{self.instanceId}", (data) ->
        $('.progress-bar').css('width', "100%")
        d = JSON.parse(data.message)
        if d.ok
          $('.create-new-instance').hide()
          $('.setup-done').show()
        else
          $('p.api').hide()
          $('pre.api').hide()
          $('.go-to-dashboard').hide()
          if d.error == 'invalid_auth'
            $('p.status').html("Oops, looks like this is an invalid authentication token")
          else if d.error == 'account_inactive'
            $('p.status').html("Oops, this authentication token is for a bot that has been disabled")
          else
            $('p.status').html("Oops, an unexpected error happened while trying to set up your bot")
          $('p.status').addClass('text-danger')
          $('.setup-done').show()
