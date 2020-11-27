# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('[data-toggle="popover"]').popover()
  $("#add-members").select2();
  $('#image-upload').on 'change', ->
    readURL this, '#project-image'
    return
  $('#logo-upload').on 'change', ->
    readURL this, '#project-logo'
    return

  $('#toggle-projects-btn').bind 'ajax:beforeSend', ->
    showSpinner();
    return

  $('#toggle-projects-btn').bind 'ajax:complete', ->
    hideSpinner();
    return

  $('body').on 'click', (e) ->
    $('[data-toggle="popover"]').each ->
      if !$(this).is(e.target) and $(this).has(e.target).length == 0 and $('.popover').has(e.target).length == 0
        $(this).popover 'hide'
      return
    return

  if $('#sortable').length > 0
    table_width = $('#sortable').width()
    cells = $('.table').find('tr')[0].cells.length
    desired_width = table_width / cells + 'px'
    $('.table td').css('width', desired_width)

    $('#sortable').sortable(
      axis: 'y'
      items: '.item'
      cursor: 'move'

      sort: (e, ui) ->
        ui.item.addClass('active-item-shadow')
      stop: (e, ui) ->
        ui.item.removeClass('active-item-shadow')
        # highlight the row on drop to indicate an update
        ui.item.children('td').effect('highlight', {}, 1000)
      update: (e, ui) ->
        item_id = ui.item.data('item-id')
        position = ui.item.index() # this will not work with paginated items, as the index is zero on every page
        $.ajax(
          type: 'POST'
          url: '/projects/'+ item_id + '/update_sequence_number'
          dataType: 'json'
          data: { position: position + 1 }
        )
   )

  $('.usecode').click ->
    code = $(this).data('code')
    $('#project_code').val code
    $('#existing-code').modal 'hide'
    return
  return

readURL = (input, src_id) ->
  if input.files and input.files[0]
    reader = new FileReader

    reader.onload = (e) ->
      $(src_id).attr 'src', e.target.result
      return

    reader.readAsDataURL input.files[0]
  return
