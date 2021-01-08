CalculateWeekendDays = (fromDate, toDate) ->
  weekDayCount = 0
  fromDate = new Date(fromDate)
  toDate = new Date(toDate)
  while fromDate <= toDate
    ++weekDayCount if not checkWeekendOrHoliday(fromDate)
    fromDate.setDate fromDate.getDate() + 1
  $('#leave_application_number_of_days').val(weekDayCount)

@set_number_of_days = (location) ->
  getHolidayList(location)
  getHolidayOptionalList(location)
  $("#leave_application_start_at").on "change", ->
    CalculateWeekendDays($("#leave_application_start_at").val(),
     $("#leave_application_end_at").val()) if $("#leave_application_end_at").val()

  $("#leave_application_end_at").on "change", ->
    CalculateWeekendDays($("#leave_application_start_at").val(),
      $("#leave_application_end_at").val()) if $("#leave_application_start_at").val()

checkWeekendOrHoliday = (fromDate) ->
  date = fromDate.toISOString().substring(0,10);

  fromDate.getDay() == 0 ||
  fromDate.getDay() == 6 ||
  (findHolidayDate(date) && fromDate.getFullYear() == getCurrentYear())

getCurrentYear = () ->
  return new Date().getFullYear()

updateLeaveType = (startDate) ->
  if startDate.getFullYear() > getCurrentYear()
    $("select option[value*='LWP']").prop('disabled', true);
    $("select option[value*='OPTIONAL']").prop('disabled', true);
  else
    $("select option[value*='LWP']").prop('disabled', false);
    $("select option[value*='OPTIONAL']").prop('disabled', false);

getHolidayList = (location) ->
  $.ajax
    dataType: 'json'
    type: 'GET'
    url: '/holiday_list'
    data: {location: location}
    success: (response) ->
      localStorage.setItem 'items', JSON.stringify(response)

getHolidayOptionalList = (location) ->
  $.ajax
    dataType: 'json'
    type: 'GET'
    url: '/holiday_list'
    data: {location: location, leave_type: 'OPTIONAL'}
    success: (response) ->
      localStorage.setItem 'optional_items', JSON.stringify(response)

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

setLeaveDate = (min, max) ->
  $('#leave_application_start_at').attr('min', min)
  $('#leave_application_end_at').attr('min', min)
  $('#leave_application_start_at').attr('max', max)
  $('#leave_application_end_at').attr('max', max)

@updateOptionalHolidayUI = (date='', reason='', days='') ->
  setLeaveDate(date, date)
  $('.date-picker').val(date)
  $('#leave_application_end_at').attr('readOnly', true)
  $('#leave_application_start_at').attr('readOnly', true)
  $('#leave_application_number_of_days').val(days)
  $('#leave_application_reason').val('Optional Leave - ' + reason)
  $('#leave_application_reason').attr('readOnly', true)
  if (reason == 'No Optional Leaves')
    $('#leave_application_reason').val('Optional Leave - ')
    $('#leave_application_number_of_days').val(0)
    $('.leave_submit').attr('disabled', true)

removeOptionalHolidayUI = () ->
  year = new Date().getFullYear()
  setLeaveDate(year + '-01-01', year + '-12-31')
  $('.date-picker').val('')
  $('#leave_application_end_at').attr('readOnly', false)
  $('#leave_application_start_at').attr('readOnly', false)
  $('#leave_application_number_of_days').val('')
  $('#leave_application_reason').val('')
  $('#leave_application_reason').attr('readOnly', false)
  $('.leave_application_leave_list').remove()
  $('.leave_submit').attr('disabled', false)


@input_leave_list = () ->
  list = JSON.parse(localStorage.optional_items)
  if (list.length != 0)
    options = list.map (h) ->
                '<option value="'+ h.holiday_date + '">' + h.reason + '</option>'
  else
    options = '<option value="">No Optional Leaves</option>'

  return '<div class="control-group select required leave_application_leave_list">' +
            '<label class="select required control-label" for="leave_application_leave_list">' +
              '<abbr title="required">*</abbr> Leave List</label>' +
              '<div class="controls">' +
                '<select class="select required" id="leave_application_leave_list" aria-invalid="false" onChange="updateOptionalHolidayUI(this.value, this.selectedOptions[0].innerText, 1)">' + options +
                '</select>' +
              '<div class="help-block">' +
            '</div>' +
          '</div>'

$(document).ready ->
  $('.leave_table').dataTable 'ordering' : false
  $('#leave-table').dataTable({'pageLength': 50})
  $('#reset_filter').on 'click', ->
    $('#project_id').prop('selectedIndex',0);
    $('#user_id').prop('selectedIndex',0)
    document.getElementById('from').value = '';
    document.getElementById('to').value = '';
    $('#submit_btn').click();
  $('#project_id').on 'change', ->
    $('#user_id').attr('disabled', true);
  $('#user_id').on 'change', ->
    $('#project_id').attr('disabled', true);

  $('#leave_application_start_at').on 'change', ->
    startDate = new Date($('#leave_application_start_at').val())
    $('#leave_application_end_at').attr('min', startDate.toLocaleDateString('fr-CA'))
    $('#leave_application_end_at').val(startDate.toLocaleDateString('fr-CA'))
    updateLeaveType(startDate)

  $('#leave_application_leave_type').on 'change', ->
    if $(this).val() == 'OPTIONAL'
      $('#leave_list').html(input_leave_list)
      $('#leave_application_leave_list').prop('selectedIndex', 0).change()
    else
      removeOptionalHolidayUI()
