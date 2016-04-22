window.App ||= {}

class App.Base
  constructor: ->
    Turbolinks.enableProgressBar()
    self = this
    $(document).ready ->
      self.setupMixpanelTracking()

  setupMixpanelTracking: ->
    $('a').on 'click', (e) ->
      if (mixpanel_event = $(e.target).attr('data-mixpanel-event'))?
        mixpanel.track mixpanel_event
