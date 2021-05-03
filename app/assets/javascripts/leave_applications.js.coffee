CalculateWeekendDays = (fromDate, toDate) ->
  weekDayCount = 0
  fromDate = new Date(fromDate)
  toDate = new Date(toDate)

  holiday_list = JSON.parse(localStorage.items)
  holiday_dates  = holiday_list.filter (h) -> h.holiday_type == 'MANDATORY'
  holiday_dates  = holiday_dates.map (h) -> h.holiday_date

  optional_holiday_list = JSON.parse(localStorage.userOptionalItems)
  optional_holiday_list = optional_holiday_list.user_optional_holiday.map (h) ->
                            new Date(h).toLocaleDateString('fr-CA')
  holiday_dates = holiday_dates.concat(optional_holiday_list)

  while fromDate <= toDate
    date = fromDate.toISOString().substring(0,10);
    ++weekDayCount if not (fromDate.getDay() is 0 or fromDate.getDay() is 6 or holiday_dates.includes(date))
    fromDate.setDate fromDate.getDate() + 1
  $("#leave_application_number_of_days").val(weekDayCount)

@set_number_of_days = (location) ->
  getHolidayList(location)
  getHolidayOptionalList(location)
  getEmpOptionalList()

  $("#leave_application_start_at").on "change", ->
    CalculateWeekendDays($("#leave_application_start_at").val(),
     $("#leave_application_end_at").val()) if $("#leave_application_end_at").val()

  $("#leave_application_end_at").on "change", ->
    CalculateWeekendDays($("#leave_application_start_at").val(),
      $("#leave_application_end_at").val()) if $("#leave_application_start_at").val()

getHolidayList = (location) ->
  $.ajax
    dataType: 'json'
    type: 'GET'
    url: '/holiday_list'
    data: {location: location}
    success: (response) ->
      localStorage.setItem 'items', JSON.stringify(response)

getEmpOptionalList = () ->
  $.ajax
    dataType: 'json'
    type: 'GET'
    url: '/users_optional_holiday_list'
    success: (response) ->
      localStorage.setItem 'userOptionalItems', JSON.stringify(response)

getHolidayOptionalList = (location) ->
  $.ajax
    dataType: 'json'
    type: 'GET'
    url: '/holiday_list'
    data: {location: location, leave_type: 'OPTIONAL'}
    success: (response) ->
      localStorage.setItem 'optional_items', JSON.stringify(response)

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
  $('#leave_application_reason').val('Optional Holiday - ' + reason)
  $('#leave_application_reason').attr('readOnly', true)
  if (reason == 'No Optional Holiday')
    $('#leave_application_reason').val('Optional Holiday - ')
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
    options = '<option value="">No Optional Holidays</option>'

  return '<div class="control-group select required leave_application_leave_list">' +
            '<label class="select required control-label" for="leave_application_leave_list">' +
              '<abbr title="required">*</abbr> Leave List</label>' +
              '<div class="controls">' +
                '<select class="select required" id="leave_application_leave_list" aria-invalid="false" onChange="updateOptionalHolidayUI(this.value, this.selectedOptions[0].innerText, 1)">' + options +
                '</select>' +
              '<div class="help-block">' +
            '</div>' +
          '</div>'

updateUserList = (active_or_all) ->
  if active_or_all == 'all'
    $("select option[id*='pending']").prop('hidden', false);
    $("select option[id*='created']").prop('hidden', false);
    $("select option[id*='resigned']").prop('hidden', false);
  else
    $("select option[id*='pending']").prop('hidden', true);
    $("select option[id*='created']").prop('hidden', true);
    $("select option[id*='resigned']").prop('hidden', true);

$(document).ready ->
  $('.leave_table').dataTable 'ordering' : false
  $('#leave-table').dataTable({'pageLength': 50})
  $('#reset_filter').on 'click', ->
    $('#project_id').prop('selectedIndex',0);
    $('#user_id').prop('selectedIndex',0)
    $('#active_or_all').prop('selectedIndex',0)
    $('#leave_search_from_date').val('');
    $('#leave_search_to_date').val('');
    $('#submit_btn').click();
  $('#project_id').on 'change', ->
    $('#user_id').attr('disabled', true);
  $('#user_id').on 'change', ->
    $('#project_id').attr('disabled', true);
  $('#leave_application_leave_type').on 'change', ->
    if $(this).val() == 'OPTIONAL HOLIDAY'
      $('#leave_list').html(input_leave_list)
      $('#leave_application_leave_list').prop('selectedIndex', 0).change()
    else
      removeOptionalHolidayUI()
  updateUserList($('#active_or_all').val())
  $('#active_or_all').on 'change', ->
    updateUserList($('#active_or_all').val())

@check_Browser_Version = () ->
  `var raw`
  CHROME_STABLE_VERSION = 85
  FIREFOX_STABLE_VERSION = 79
  SAFARI_STABLE_VERSION = 14
  userAgent = navigator.userAgent

  if userAgent.includes('Firefox/')
    raw = userAgent.split('Firefox/')[1]
    browser_version = if raw then parseFloat(raw.toString().split('.')[0]) else false
    checkVersion browser_version, FIREFOX_STABLE_VERSION
  else if userAgent.includes('Chrome/')
    raw = navigator.userAgent.match(/Chrom(e|ium)\/([0-9]+)\./)
    browser_version = if raw then parseInt(raw[2], 10) else false
    checkVersion browser_version, CHROME_STABLE_VERSION
  else if userAgent.includes('Safari/')
    raw = userAgent.split('Version/')[1]
    browser_version = if raw then parseFloat(raw.toString().split('.')[0]) else false
    checkVersion browser_version, SAFARI_STABLE_VERSION
  return

checkVersion = (current_version, stable_version) ->
  if current_version < stable_version
    alert 'We\'re sorry, but this browser is not supported. Please update your browser version!!'
    window.location.href = '/view/leave_applications'
    return
  return
