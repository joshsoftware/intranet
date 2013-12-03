# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('.company_name').hover(
    ->  $(this).children('.actions').show() 
    ->  $(this).children('.actions').hide()
  )
  
  $("#csv_file").on 'change', ->
    $('#import_csv_file').submit()
    
