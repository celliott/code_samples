# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  $('#charts').click()
  $('#habit_types').click()
  habit_undo = $("#flashMessage").find("p").text()
  if(habit_undo.indexOf("recorded!") >= 0)
    habit_undo = habit_undo.replace(/(\w+).*/,"$1")
    $("."+habit_undo).removeClass('undo_hide')