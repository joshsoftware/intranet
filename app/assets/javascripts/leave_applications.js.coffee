calculate_numeber_of_days = ->
    days = ($("#leave_application_end_at").datepicker('getDate').getTime() - $("#leave_application_start_at").datepicker('getDate').getTime() ) / (24 * 60 * 60 * 1000) + 1
    $("#leave_application_number_of_days").val(days)


@set_number_of_days = ->
    $("#leave_application_start_at").on "change", ->
        calculate_numeber_of_days() if $("#leave_application_end_at").val() 

    $("#leave_application_end_at").on "change", ->
        calculate_numeber_of_days() if $("#leave_application_start_at").val() 
