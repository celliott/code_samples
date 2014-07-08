# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  oTable = undefined
  oTable = $("#orders_datatable").dataTable(
    bDestroy: true,
    sDom: "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>"
    bProcessing: true
    bServerSide: true
    sAjaxSource: $("#orders_datatable").data("source")
    iDisplayLength: 50
    bStateSave: true
    aaSorting: [[1, "desc"]]
    fnDrawCallback:
      jQuery(".orders-content").fadeIn 200
    oLanguage:
      sProcessing: "<img src='/assets/images/loading.gif'>"
      sLengthMenu: "Show &nbsp;<select>" + "<option value=\"10\">10</option>" + "<option value=\"25\">25</option>" + "<option value=\"50\">50</option>" + "<option value=\"100\">100</option>" + "</select>"
      sInfo: "Showing _START_ to _END_ of _TOTAL_ orders"
      sInfoEmpty: "Showing _START_ to _END_ of _TOTAL_ orders"
      sZeroRecords: "No matching orders found"
      sInfoFiltered: "(filtered from _MAX_ total orders)"
    aoColumns: [
      sWidth: "10%"
    ,      
      sWidth: "20%"
    ,
      sWidth: "30%"
    ,
      sWidth: "20%"
    ,
      sWidth: "10%"
    ]
  )
