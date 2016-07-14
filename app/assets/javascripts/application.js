// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

$( document ).ready(function() {

//http://www.w3schools.com/jquery/css_position.asp
//$(".plot_chart_btn").click(function(){
//    var x = $("#chart").position();
//    //alert("Top: " + x.top + " Left: " + x.left);
//    $(".circle").css({top: x.top, left: x.left, position:'absolute'});
//});


	$( ".circle" ).mouseover(function() {
	  $( this  ).children(".hidden-info").toggle();
	});

});