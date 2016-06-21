#= require pages/app/base

window.App ||= {}

class App.NotificationScheduler extends App.AppBase
  constructor: ()->
    super()

  run: ->
    self = @

    $(document).ready ->
      $('input[id=send_now]').on 'click', ->
        $('.scheduler-options.once input[name="notification[scheduled_at]"]').val('').attr('readonly', 'readonly')
        $('.scheduler-options.recurring input[name="notification[scheduled_at]"]').val('').attr('readonly', 'readonly')
        $('.scheduler-options.once input[name="notification[scheduled_at]"]').val('').attr('disabled', 'disabled')
        $('.scheduler-options.recurring input[name="notification[scheduled_at]"]').val('').attr('disabled', 'disabled')
        $('input[name="notification[recurring]"]').val(false)

      $('input[id=send_later_once]').on 'click', ->
        $('.scheduler-options.once input[name="notification[scheduled_at]"]').removeAttr('readonly')
        $('.scheduler-options.recurring input[name="notification[scheduled_at]"]').val('').attr('readonly', 'readonly')
        $('.scheduler-options.once input[name="notification[scheduled_at]"]').val('').removeAttr('disabled')
        $('.scheduler-options.recurring input[name="notification[scheduled_at]"]').val('').attr('disabled', 'disabled')
        $('input[name="notification[recurring]"]').val(false)

      $('input[id=send_later_recurring]').on 'click', ->
        $('.scheduler-options.once input[name="notification[scheduled_at]"]').val('').attr('readonly', 'readonly')
        $('.scheduler-options.recurring input[name="notification[scheduled_at]"]').removeAttr('readonly')
        $('.scheduler-options.once input[name="notification[scheduled_at]"]').val('').attr('disabled', 'disabled')
        $('.scheduler-options.recurring input[name="notification[scheduled_at]"]').removeAttr('disabled')

        $('input[name="notification[recurring]"]').val(true)

      $('.scheduler-options.once input[name="notification[scheduled_at]"]').daterangepicker(
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

      $('.scheduler-options.recurring input[name="notification[scheduled_at]"]').timepicker()

      $('.scheduler-options.once input[name="notification[scheduled_at]"]').on 'apply.daterangepicker hide.daterangepicker', (ev, picker)->
        $(this).val picker.startDate.format('LLL')

      $('.scheduler-options.once input[name="notification[scheduled_at]"]').on 'cancel.daterangepicker', (ev, picker)->
        $(this).val ''

      #if($('#notification_notification[scheduled_at]').val() != undefined && $('#notification_notification[scheduled_at]').val() != '')
        #$('input[id=send_later]').click()

  getMinDate: ->
    minDate = new Date();
    minDate.setHours(minDate.getHours() + 1)
    minDate.setMinutes(minDate.getMinutes() + 30)
    minDate.setMinutes (0)
    minDate
