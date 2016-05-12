#= require pages/app/base

window.App ||= {}

class App.NotificationSendingProgress extends App.AppBase
  constructor: (@notificationId, @pusherAPIKey) ->
    super()

  run: ->
    self = @

    $(document).ready ->
      set_progress_bar = ->
        sent  = parseInt($('.progress-bar').data('sent'))
        total = parseInt($('.progress-bar').data('total'))

        if sent == total
          $('.progress').removeClass('progress-striped')

        $('.progress-bar').css('width', "#{sent/total*100}%" )
        $('.progress-sent').html(sent)

      set_sent_count = (sentCount) ->
        sent = parseInt($('.progress-bar').data('sent'))
        $('.progress-bar').data('sent', sentCount)

      # Set Progress Bar on Page Load
      set_progress_bar()

      pusher = new Pusher(self.pusherAPIKey)
      channel = pusher.subscribe "notification"
      channel.bind "notification-#{self.notificationId}", (data) ->
        d = JSON.parse(data.message)

        if d.ok
          set_sent_count(d.sent)
          set_progress_bar()
        else
          $('.failures ul').append("<li>Failed to send message to #{d.recipient}</li>")
