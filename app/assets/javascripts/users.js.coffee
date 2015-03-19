# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#

$(document).ready ->
  $.get("/users/#{user_id}/get_feed/github.js", ()->
  ).done( ->
  ).fail ->
   alert("Some error occurred while fetching github feed")
   $("#github").html("")
  $.get("/users/#{user_id}/get_feed/blog.js", ()->
  ).done( ->
  ).fail ->
   alert("Some error occurred while fetching blog feed")
   $("#blog").html("")
  $.get("/users/#{user_id}/get_feed/bonusly.js", ()->
  ).done( ->
  ).fail ->
   alert("Some error occurred while fetching bonusly feed")
   $("#bonus-received").html("");
   $("#bonus-given").html("");

