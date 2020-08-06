$(document).ready ->
  table = $('.resource').dataTable
    ordering : false
    dom: 'frtlp'
    initComplete : ->
      this.api().columns([6, 7, 9]).every ->
          column = this;
          labelNames = { 6: 'Billable?', 7: 'Technical skills', 9: 'Projects' }
          select = $('<select style="width:160; margin-left:10; margin-right:20"><option value=""></option></select>')
              .on( 'change', ->
                val = $(this).val()
                column.search(val).draw();
                return
              );
          label = $('<label style="float:left">' + labelNames[column[0][0]] + '</label>')
          $(label).append($(select))
          $(label).insertBefore($('#DataTables_Table_0_filter'))
          select.append( '<option value="">All</option>' )
          if(column[0][0] == 7 || column[0][0] == 9)
            if column[0][0] == 7
              $(select).select2({ placeholder: 'Technical Skills'})
              columnData = technical_skills
            else
              $(select).select2({ placeholder: 'Project'})
              columnData = projects
            columnData.forEach (d) ->
              select.append( '<option value="'+d+'">'+d+'</option>' )
              return
          else
            $(select).select2({ placeholder: 'Yes/No'})
            column.data().unique().sort().each (d, j) ->
              select.append( '<option value="'+d+'">'+d+'</option>' )
              return

  $('tr[hidden]').attr("hide", "true")
  $('#show').click ->
    if $(this).text() == 'Show All'
      params = $.param({ all:"all" })
      $.ajax
        type: 'GET'
        dataType: 'script'
        url:'/users' + '?' + params
      $(this).text('Show Approved')
      $(this).attr('aria-label', 'Click here to show all approved users')
      $('tr[hide]').removeAttr('hidden')
      $('#show_text').text('Showing all- active & Inactive users.')
    else
      $.ajax
        type: 'GET'
        dataType: 'script'
        url:'/users'
      $(this).text('Show All')
      $(this).attr('aria-label', 'Click here to show all users')
      $('tr[hide]').attr('hidden', 'true')
      $('#show_text').text('Showing active users only.')

  $('#download_btn').click -> 
    if $('#show').text() == 'Show All'
      window.location.href = '/users.xlsx' 
    else
      window.location.href = '/users.xlsx'+'?'+ 'status=all'

