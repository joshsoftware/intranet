CalculateWeekendDays = (fromDate, toDate) ->
    weekDayCount = 0
    while fromDate < toDate
        fromDate.setDate fromDate.getDate() + 1
        ++weekDayCount  if not (fromDate.getDay() is 0 or fromDate.getDay() is 6)
    $("#leave_application_number_of_days").val(weekDayCount+1)

@set_number_of_days = ->
    $("#leave_application_start_at").on "change", ->
        CalculateWeekendDays($("#leave_application_start_at").datepicker('getDate'), $("#leave_application_end_at").datepicker('getDate')) if $("#leave_application_end_at").val() 

    $("#leave_application_end_at").on "change", ->
        CalculateWeekendDays($("#leave_application_start_at").datepicker('getDate'), $("#leave_application_end_at").datepicker('getDate')) if $("#leave_application_start_at").val() 

