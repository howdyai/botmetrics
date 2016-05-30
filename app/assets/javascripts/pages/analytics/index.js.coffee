#= require pages/app/base

window.App ||= {}

class App.AnalyticsIndex extends App.AppBase
  constructor: () ->
    super()

  run: ->
    $(document).ready ->
