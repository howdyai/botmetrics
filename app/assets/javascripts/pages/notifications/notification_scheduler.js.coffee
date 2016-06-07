#= require pages/app/base

window.App ||= {}

class App.NotificationScheduler extends App.AppBase
  constructor: ()->
    super()

  run: ->
    self = @

    $(document).ready ->
      $('input[id=send_now]').on 'click', ->
        $('#notification_scheduled_at').val('').attr('readonly', 'readonly')

      $('input[id=send_later]').on 'click', ->
        $('#notification_scheduled_at').removeAttr('readonly')

      $('#notification_scheduled_at').daterangepicker(
        {
          autoUpdateInput: false,
          singleDatePicker: true,
          timePicker: true,
          timePickerIncrement: 30,
          minDate: self.getMinDate(),
          opens: 'center',
          drops: 'up',
          locale: {
            format: 'LLL',
            cancelLabel: 'Clear'
          }
        }
      )

      $('#notification_scheduled_at').on 'apply.daterangepicker hide.daterangepicker', (ev, picker)->
        $(this).val picker.startDate.format('LLL')

      $('#notification_scheduled_at').on 'cancel.daterangepicker', (ev, picker)->
        $(this).val ''

      $('.clear-scheduler').on 'click', (e)->
        $('#notification_scheduled_at').val('')
        e.preventDefault()

      if($('#notification_scheduled_at').val() != undefined && $('#notification_scheduled_at').val() != '')
        $('input[id=send_later]').click()

  getMinDate: ->
    minDate = new Date();
    minDate.setHours(minDate.getHours() + 1)
    minDate.setMinutes(minDate.getMinutes() + 30)
    minDate.setMinutes (0)
    minDate
