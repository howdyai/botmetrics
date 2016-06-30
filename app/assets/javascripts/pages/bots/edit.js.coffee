#= require pages/app/base

window.App ||= {}

class App.BotsEdit extends App.AppBase
  constructor: () ->
    super()

  run: ->
    self = @
    $(document).ready ->
      $('.invite-teammember').click (e) ->
        $('.add-teammember').show()
        $('.invite-teammember').hide()
        e.stopPropagation()
        false
