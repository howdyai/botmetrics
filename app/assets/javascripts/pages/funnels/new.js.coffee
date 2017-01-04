#= require pages/app/base

window.App ||= {}

class App.FunnelsNew extends App.AppBase
  constructor: (@dashboards) ->
    super()

  run: ->
    self = this

    $(document).ready ->
      $(document).on 'click', 'a.remove-step', (e) ->
        $(e.target).parents("div.funnel_dashboards").remove()
        $("label[for='funnel_dashboards']").each (i, label) ->
          $(label).html("Step #{i+1}")
        if $("label[for='funnel_dashboards']").length < 3
          $('.add-step').show()

      $('a.add-step').click (e) ->
        html = """
<div class="form-group select required funnel_dashboards">
  <label class="select required" for="funnel_dashboards">
    Step 2
  </label>
  <div class="controls">
    <select name="funnel[dashboards][]" class="select required form-control">
        """
        totalSteps = $("label[for='funnel_dashboards']").length

        for elem, i in self.dashboards
          html += "<option #{if i == totalSteps then "selected='selected'" else ""}' value='#{elem[1]}'>#{elem[0]}</option>"
        html += "</select>"
        html += "<a class='remove-step'><i class='fa fa-times'/></a>"
        html += "</div></div>"

        $('.steps').append(html)

        $("label[for='funnel_dashboards']").each (i, label) ->
          $(label).html("Step #{i+1}")

        if $("label[for='funnel_dashboards']").length == 3
          $('.add-step').hide()

        false

