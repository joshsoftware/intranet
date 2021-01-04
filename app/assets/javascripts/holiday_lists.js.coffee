# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

update_holiday_list = () ->
  params = $.param({
      year: $('#date_year').val(),
      country: $('#country').val()
    })
  $.ajax
    type: 'GET'
    dataType: 'script'
    url:'/holiday_lists'+ '?' + params

$(document).ready ->
  $('#date_year, #country').on 'change', ->
    update_holiday_list()

