CalculateWeekendDays = (fromDate, toDate) ->
  weekDayCount = 0
  fromDate = new Date(fromDate)
  toDate = new Date(toDate)
  while fromDate <= toDate
    date = fromDate.toISOString().substring(0,10);
    ++weekDayCount if not (fromDate.getDay() is 0 or fromDate.getDay() is 6 or findHolidayDate(date))
    fromDate.setDate fromDate.getDate() + 1
  $("#leave_application_number_of_days").val(weekDayCount)


@set_number_of_days = ->
  getHolidayList()
  $("#leave_application_start_at").on "change", ->
    CalculateWeekendDays($("#leave_application_start_at").val(),
     $("#leave_application_end_at").val()) if $("#leave_application_end_at").val()

  $("#leave_application_end_at").on "change", ->
    CalculateWeekendDays($("#leave_application_start_at").val(),
      $("#leave_application_end_at").val()) if $("#leave_application_start_at").val()

$(document).ready ->
  $('.leave_table').dataTable 'ordering' : false

getHolidayList = ->
  $.ajax
    dataType: 'json'
    type: 'GET'
    url: '/holiday_list'
    success: (response) ->
      localStorage.setItem 'items', JSON.stringify(response)

findHolidayDate = (fromDate) ->
  i = 0
  array = localStorage.items
  array = JSON.parse(array)
  data  = array.map (h) ->
            h.holiday_date
  while i < data.length
    if data[i] == fromDate
      return true
    i++
  false

$(document).ready ->
  $("#reset_filter").on 'click', ->
    $('#project_id').prop('selectedIndex',0);
    $('#user_id').prop('selectedIndex',0)
    document.getElementById("from").value = "";
    document.getElementById("to").value = "";
    $('#submit_btn').click();
  $('#project_id').on 'change', ->
    $('#user_id').attr("disabled", true);
  $('#user_id').on 'change', ->
    $('#project_id').attr("disabled", true);
