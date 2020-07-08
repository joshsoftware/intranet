# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  $('.dropdown-submenu a.test').on 'click', (e) ->
    $(this).next('ul').toggle()
    e.stopPropagation()
    e.preventDefault()
    return

  $('.duration_select').on 'change', () ->
    str = this.id
    from_time_id = str.replace("duration", "from_time")
    to_time_id = str.replace("duration", "to_time")
    $("#" + from_time_id).val('')
    $("#" + to_time_id).val('')

  $('.time-range').on 'change', () ->
    str = this.id
    duration_id = str.replace("to_time", "duration")
    if duration_id == str
      duration_id = str.replace("from_time", "duration")
    $("#" + duration_id)[0].selectedIndex = '0'

  return
