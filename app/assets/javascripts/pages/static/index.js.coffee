#= require pages/app/base

window.App ||= {}

class App.StaticIndex extends App.AppBase
  constructor: () ->
    @sources = ['slack', 'messenger', 'kik', 'telegram']
    @counter = 0
    super()

  run: ->
    $(document).ready ->
      $(document).on 'click', 'a[href^="#"]', (e) ->
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

    #setInterval =>
      #klass = @sources[@counter]
      #$("span.#{klass}").hide()
      #@counter = if @counter == 3 then 0 else @counter+1
      #klass = @sources[@counter]
      #$("span.#{klass}").css('display', 'inline-block')
    #, 2000

