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

      enable_datepicker = (parent, selector) ->
        debugger
        $(selector, parent).daterangepicker(
          {
            singleDatePicker: true,
            timePicker: true,
            locale: {
              format: 'LLL',
              cancelLabel: 'Clear'
            }
          }
        )

      $(document).on 'change', "[name$='[field]']", ->
        parent = $(@).closest('.query')
        switch
          when $(@).val() in ['nickname', 'email', 'full_name']
            enable(parent, '.string-method')

            disable(parent, '.number-method')
            disable(parent, '.datetime-method')

          when $(@).val() in ['interaction_count']
            enable(parent, '.number-method')

            disable(parent, '.string-method')
            disable(parent, '.datetime-method')

          when $(@).val() in ['interacted_at']
            enable(parent, '.datetime-method')

            disable(parent, '.string-method')
            disable(parent, '.number-method')

        $("[name$='[method]']:visible").change()

      $(document).on 'change', "[name$='[method]']", ->
        parent = $(@).closest('.query')
        switch
          when $(@).val() in ['between']
            enable(parent, '.range-value')
            disable(parent, '.equal-value')

          else
            enable(parent, '.equal-value')
            disable(parent, '.range-value')

        if $(parent).find("[name$='[field]']").val() == 'interacted_at' && $(this).val() == 'between'
          enable_datepicker(parent, "[name$='_value]']:visible")

      $('.query-set').on 'cocoon:after-insert', ->
        $("[name$='[field]']:visible").change()

      $("[name$='[field]']:visible").change()
      $("[name$='[method]']:visible").change()

