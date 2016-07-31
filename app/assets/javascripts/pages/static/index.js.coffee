#= require pages/app/base

window.App ||= {}

class App.StaticIndex extends App.AppBase
  constructor: () ->
    @sources = ['slack', 'messenger', 'kik', 'telegram']
    @counter = 0
    super()

  run: ->
    $(document).ready ->
      mixpanel.track 'Viewed Home Page'
      hljs.initHighlightingOnLoad()

      $('#signup-modal').on 'shown.bs.modal', (e) ->
        $('#user_email').val($('.signup-email').val())
        if($('#user_email').val().trim() == '')
          $('#user_email').focus()
        else
          $('#user_password').focus()

      $(document).on 'click', 'a[href^="#benefits"]', (e) ->
        # target element id
        id = $(@).attr('href')
        # target element
        $id = $(id)
        if($id.length == 0)
          return
        # prevent standard hash navigation (avoid blinking in IE)
        e.preventDefault()
        # top position relative to the document
        pos = $(id).offset().top;
        # animated top scrolling
        $('body, html').animate scrollTop: pos
      $('#user_timezone').selectTimeZone()
