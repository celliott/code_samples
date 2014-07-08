// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery-easing
//= require raphael
//= require morris
//= require jstz.min
//= require_tree .

//<![CDATA[
$(document).ready(function() {

  // show hide menu
  $('#user_menu').click(function(event){
    event.stopPropagation();
		if($('#user_drop').hasClass('not_open')){
			   $('#user_drop').animate({height:'50px'},{queue:false, duration:200, easing: 'swing'}).show();
			   $('#user_drop').removeClass('not_open');
         $('#user_menu').addClass('open');
			   $('#user_drop').addClass('open');
		}else if($('#user_drop').hasClass('open')){
				$('#user_drop').fadeOut(200);
			  $('#user_drop').addClass('not_open');
			  $('#user_drop').removeClass('open');
			  $('#user_menu').removeClass('open');
		    setTimeout(function(){
          $('#user_drop').height('0px');
        }, 300);  
		}
  });
  
  // dismisses menu when clicked anywhere on page
  $('html').click(function(){
		if($('#user_drop').hasClass('open')){
		    $('#user_drop').hide();
		    $('#user_drop').height('0px');
			  $('#user_drop').addClass('not_open');
			  $('#user_drop').removeClass('open');
			  $('#user_menu').removeClass('open');
		}
  });
  
  // fades flash message
  timer = setTimeout(fadeOut, 2500);
  $("#flashMessage").hide();
  $("#flashMessage p").removeClass('hide');
  $("#flashMessage").fadeIn(500);

  // set's timezone in a cookie 
  var timezone = jstz.determine();
  document.cookie = 'time_zone='+timezone.name()+';';
  
  // keeps web app links in the same window
  $("a").click(function (event) {
    event.preventDefault();
    if($(this).attr("href") == '/settings/habit_types'){
      window.location.top= $(this).attr("href");
    } else {  
      window.location = $(this).attr("href");
    }
  });
  
  // disallows cut and paste into email confirmation on delete account page
  $('#email_delete_user').bind("cut copy paste",function(e) {
      e.preventDefault();
  });
  
});

// funcion to fadout flash message
function fadeOut() {
  $("#flashMessage").fadeOut(500);
}

// resizes trend_graph on window resize
$(window).bind('resize',function() {
  $('#chart_refresh').click();
});

// sets trend cookie after trend dropdown selection
function setTrendCookie() {
  var trend = $("#trends_dropdown").val();
  document.cookie = 'trend='+trend;
}	
//]]>