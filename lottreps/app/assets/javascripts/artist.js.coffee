# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  oTable = undefined
  oTable = $("#artists_datatable").dataTable(
    bDestroy: true,
    sDom: "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>"
    sPaginationType: "bootstrap"
    bProcessing: true
    bServerSide: true
    sAjaxSource: $("#artists_datatable").data("source")
    iDisplayLength: 25
    bStateSave: true
    oLanguage:
      sProcessing: "<img src='/assets/images/loading.gif'>"
      sLengthMenu: "show &nbsp;<select>" + "<option value=\"25\">25</option>" + "<option value=\"50\">50</option>" + "<option value=\"100\">100</option>" + "</select>"

    aoColumns: [
      sWidth: "10%"
    ,
      sWidth: "30%"
    ,
      bSortable: false
      sWidth: "20%"
    ,
      bSortable: false
      sWidth: "30%"
    ,
      bSortable: false
    ,
      bSortable: false
    ,
      bSortable: false
    ]
  )
  $(".artist-modal").on "hidden", ->
    oTable.fnReloadAjax()

  $(window).bind "resize", ->
    oTable.fnAdjustColumnSizing()

  $(".artist-modal").modal "hide"