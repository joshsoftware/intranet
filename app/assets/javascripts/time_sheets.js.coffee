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

update_project_list = ->
  previous_project = []
  $('select').each ->
    if $(this).attr('class').includes('project_id')
      input = $(this)
      $.each previous_project, (index, value) ->
        input.find('option[value=' + String(value) + ']').remove()
        return
      previous_project.push input.val()
    return
  return

$(document).ready ->
  $('.dropdown-submenu a.test').on 'click', (e) ->
    $(this).next('ul').toggle()
    e.stopPropagation()
    e.preventDefault()
    return

  on_duration_change()
  on_time_range_change()
  update_project_list()

  $("body").on "nested:fieldAdded", () ->
    on_duration_change()
    on_time_range_change()
    update_project_list()
  return
