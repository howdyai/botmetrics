#= require pages/app/base

window.App ||= {}

class App.BotInstancesSetup extends App.AppBase
  constructor: (@botId, @instanceId, @provider, @pusherAPIKey) ->
    super()

  showSuccess: ->
    $('.create-new-instance').hide()
    $('.setup-done').show()
    $('p.intro').html("We have completed setting up your bot!")

  showError: (error) ->
    $('p.intro').html("There was a problem setting up your bot...")

    $('p.api').hide()
    $('pre.api').hide()
    $('h3.api').hide()
    $('div.api').hide()
    $('.go-to-dashboard').hide()

    if error == 'invalid_auth' || error == 'disabled' || error.match(/invalid oauth access token/i)
      $('p.status').html("Oops, looks like this is an invalid authentication token")
    else if error == 'account_inactive'
      $('p.status').html("Oops, this authentication token is for a bot that has been disabled")
    else
      $('p.status').html("Oops, an unexpected error happened while trying to set up your bot")
    $('p.status').addClass('text-danger')
    $('.setup-done').show()
    $('.update-instance').show()

  poll: ->
    self = @

    $.getJSON "/bots/#{self.botId}/instances/#{self.instanceId}", (data, success) ->
      if data.state == 'pending'
        setTimeout ->
          self.poll()
        , 1000
      else
        $('.progress-bar').css('width', "100%")
        if data.state == 'enabled'
          self.showSuccess()
        else
          self.showError(data.state)

  run: ->
    self = @

    $(document).ready ->
      pusher = new Pusher(self.pusherAPIKey)
      hljs.initHighlightingOnLoad()

      self.poll()
      channel = pusher.subscribe "setup-bot"
      channel.bind "setup-bot-#{self.instanceId}", (data) ->
        $('.progress-bar').css('width', "100%")
        d = JSON.parse(data.message)
        if d.ok
          self.showSuccess()
        else
          self.showError(d.error)
