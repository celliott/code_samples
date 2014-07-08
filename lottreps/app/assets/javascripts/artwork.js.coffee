# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  oTable = undefined
  oTable = $("#artworks_datatable").dataTable(
    bAutoWidth: false
    bDestroy: true
    sDom: "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>"
    sPaginationType: "bootstrap"
    bProcessing: true
    bServerSide: true
    sAjaxSource: $("#artworks_datatable").data("source")
    iDisplayLength: 50
    bStateSave: true
    oLanguage:
      sProcessing: "<img src='/assets/images/loading.gif'>"
      sLengthMenu: "show &nbsp;<select>" + "<option value=\"25\">25</option>" + "<option value=\"50\">50</option>" + "<option value=\"100\">100</option>" + "</select>"

    aoColumns: [
      sWidth: "10%"
    ,
      bSortable: false
      sWidth: "20%"
    ,
      sWidth: "20%"
    ,
      sWidth: "40%"
    ,
      bSortable: false
      sWidth: "5%"
    ]
  )
  $(".artwork-modal").on "hidden", ->
    oTable.fnReloadAjax()

  $("#modal-window").modal "hide"

  $(window).bind "resize", ->
    oTable.fnAdjustColumnSizing()

  $("#fileupload").fileupload
    disableImageResize: 'false'
    imageMaxWidth: '400'
    imageMaxHeight: '400'
    previewCrop: 'true'

    add: (e, data) ->   
      disableImageResize: 'false'
      imageMaxWidth: '400' 
      imageMaxHeight: '400'
      previewCrop: 'true'   
      file = undefined
      types = undefined
      types = /(\.|\/)(gif|jpe?g|png)$/i
      file = data.files[0]
      if types.test(file.type) or types.test(file.name)
        data.context = $(tmpl("template-upload", file))
        $("#fileupload").append data.context
        data.submit()
      else
        alert "" + file.name + " is not a gif, jpeg, or png image file"

    progress: (e, data) ->
      progress = undefined
      if data.context
        progress = parseInt(data.loaded / data.total * 100, 10)
        data.context.find(".bar").css "width", progress + "%"

    done: (e, data) ->
      content = undefined
      domain = undefined
      file = undefined
      path = undefined
      to = undefined
      file = data.files[0]
      domain = $("#fileupload").attr("action")
      path = $("#fileupload input[name=key]").val().replace("${filename}", file.name)
      to = $("#fileupload").data("post")
      content = {}
      content[$("#fileupload").data("as")] = domain + path
      $.post to, content
      data.context.remove()  if data.context
      oTable.fnReloadAjax()

    fail: (e, data) ->
      alert "" + data.files[0].name + " failed to upload."
      console.log "Upload failed:"
      console.log data