#= require pages/app/base

window.App ||= {}

class App.DashboardsIndex extends App.Base
  constructor: () ->
    super()

  run: ->
    self = @
    $(document).ready ->
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

