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
            disable(parent, '.ago-method')

          when $(@).val() in ['interaction_count']
            enable(parent, '.number-method')

            disable(parent, '.string-method')
            disable(parent, '.datetime-method')
            disable(parent, '.ago-method')

          when $(@).val() in ['interacted_at', 'user_created_at']
            enable(parent, '.datetime-method')

            disable(parent, '.string-method')
            disable(parent, '.number-method')
            disable(parent, '.ago-method')

          when $(@).val() in ['interacted_at_ago']
            enable(parent, '.ago-method')

            disable(parent, '.string-method')
            disable(parent, '.number-method')
            disable(parent, '.datetime-method')

        $("[name$='[method]']:visible").change()

      $(document).on 'change', "[name$='[method]']", ->
        parent = $(@).closest('.query')
        field  = $("[name$='[field]']", parent)

        switch
          when field.val() in ['interacted_at_ago']
            enable(parent, '.ago-value')
            disable(parent, '.equal-value')
            disable(parent, '.range-value')

          when $(@).val() in ['between']
            enable(parent, '.range-value')
            disable(parent, '.equal-value')
            disable(parent, '.ago-value')

          else
            enable(parent, '.equal-value')
            disable(parent, '.range-value')
            disable(parent, '.ago-value')

        if $(parent).find("[name$='[field]']").val() in ['interacted_at', 'user_created_at'] && $(this).val() == 'between'
          enable_datepicker(parent, "[name$='_value]']:visible")

      $('.query-set').on 'cocoon:after-insert', ->
        $("[name$='[field]']:visible").change()

      $("[name$='[field]']:visible").change()
      $("[name$='[method]']:visible").change()
