$(document).ready ->
  $('a').on 'click', ->
    $('.icon', this)
      .toggleClass('icon-chevron-right')
      .toggleClass('icon-chevron-down')
