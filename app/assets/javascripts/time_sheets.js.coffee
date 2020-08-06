# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

on_duration_change = ->
  $('.duration_select').on 'change', () ->
    str = this.id
    from_time_id = str.replace("duration", "from_time")
    to_time_id = str.replace("duration", "to_time")
    $("#" + from_time_id).val('')
    $("#" + to_time_id).val('')

on_time_range_change = ->
  $('.time-range').on 'change', () ->
    str = this.id
    duration_id = str.replace("to_time", "duration")
    if duration_id == str
      duration_id = str.replace("from_time", "duration")
    $("#" + duration_id)[0].selectedIndex = '0'

validate_timesheet = ->
  $('.custom-error').each ->
    $(this).closest('.control-group')[0].classList.remove('error')
    $(this).remove()

  tr_elements = $('tbody tr')
  length = tr_elements.length - 1
  value = true

  tr_elements.each (index, element) ->
    if $(element).find('.custom-error').length == 0 &&
       $(element).is(':visible')
      
      project = $(this).find('.project_id').val()
      date = $(this).find('.date-picker').val()
      
      for x in [index...length]
        next_row = $(tr_elements[x + 1])
        if next_row.is(':visible') &&
           project == next_row.find('.project_id').val() &&
           date == next_row.find('.date-picker').val()
          
          value = false
          if next_row.find('.custom-error').length == 0 
            next_project = next_row.find('.project_id')
            next_row.find('.control-group')[0].classList.add('error')
            span_text = 'Cannot add multiple timesheets for same project on same date'
            $("<span class='help-inline custom-error'>" + span_text + "</span>").insertAfter(next_project);
  return value

$(document).ready ->
  $('.dropdown-submenu a.test').on 'click', (e) ->
    $(this).next('ul').toggle()
    e.stopPropagation()
    e.preventDefault()
    return

  on_duration_change()
  on_time_range_change()

  $('.timesheet').on 'submit', (e) ->
    if validate_timesheet() 
    else
      e.preventDefault()
      e.stopPropagation()
      
  $("body").on "nested:fieldAdded", () ->
    on_duration_change()
    on_time_range_change()
  return
