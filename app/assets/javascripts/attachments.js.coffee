# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $("#doc_show").click ->
    if $("#doc_show").text() == 'Show All'
      params = $.param({ all:"all" })
      $.ajax
        type: 'GET'
        dataType: 'script'
        url:'/attachments' + '?' + params
      $("#doc_show").text('Show Visible')
    else
      $.ajax
        type: 'GET'
        dataType: 'script'
        url:'/attachments'
      $("#doc_show").text('Show All')