#= require pages/app/base

window.App ||= {}

class App.Filter extends App.AppBase
  constructor: () ->
    super()

  run: ->
    $(document).ready ->
      enable = (parent, selector) ->
        $(selector, parent).removeClass('hide')
        $(selector, parent).find('input').removeAttr('disabled')
        $(selector, parent).find('select').removeAttr('disabled')

      disable = (parent, selector) ->
        $(selector, parent).addClass('hide')
        $(selector, parent).find('input').attr('disabled', 'disabled')
        $(selector, parent).find('select').attr('disabled', 'disabled')

      $(document).on 'change', "[name$='[field]']", ->
        parent = $(@).closest('.query')
        if $(@).val() in ['nickname', 'email', 'full_name']
          enable(parent, '.string-query')
          enable(parent, '.target-value')

          disable(parent, '.number-query')
          disable(parent, '.min-max-values')

        else
          enable(parent, '.number-query')
          enable(parent, '.min-max-values')

          disable(parent, '.string-query')
          disable(parent, '.target-value')

      $('.query-set').on 'cocoon:after-insert', ->
        console.log("ok:")
        $("[name$='[field]']").change()

      $("[name$='[field]']").change()
