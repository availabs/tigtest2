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
//= require jquery.validate
//= require jquery.validate.additional-methods
//= require jquery.numeric
//= require bootstrap
//= require moment
//= require bootstrap-datetimepicker
//= require bootstrap-transfer
//= require dataTables/jquery.dataTables
//= require bootstrap.colorpicker
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require jquery_ujs
//= require jquery-ui/autocomplete
//= require jquery-ui/datepicker
//= require leaflet
//= require leaflet-providers
//= require leaflet.draw
//= require jshashtable-3.0
//= require jquery.numberformatter-1.2.4.min
//= require dataTable.colReorderWithResize
//= require dataTable.colVis
//= require underscore-min
//= require mapping/leaflet.label
//= require mapping/leaflet.fullscreen
//= require mapping/leaflet.sidebar
//= require mapping/leaflet.navbar
//= require mapping/Leaflet.MapboxVectorTile
//= require mapping/L.Control.Zoomslider
//= require mapping/chroma.min
//= require spin
//= require jquery.spin
//= require leaflet.spin
//= require mapping/wicket.src.js
//= require mapping/wicket-leaflet.src.js
//= require mapping/cs-leaflet-wrappers/leafletmap.js
//= require mapping/cs-leaflet-wrappers/leafletmap_googlemap_plugin.js
//= require mapping/cs-leaflet-wrappers/leafletmap_icons.js
//= require mapping/gateway-map/GatewayMapUtil
//= require mapping/gateway-map/GatewayMap
//= require mapping/gateway-map/GatewayMapApp
//= require bootstrap-slider
//= require bootstrap-multiselect
//= require selectize
//= require download
//= require_tree .

/*
 * global function to implement a delay timer
 * only execute callback when the final event is detected
 */
var waitForFinalEvent = (function() {
    var timers = {};
    return function(callback, ms, uniqueId) {
        if (!uniqueId) {
            uniqueId = "Don't call this twice without a uniqueId";
        }
        if (timers[uniqueId]) {
            clearTimeout(timers[uniqueId]);
        }
        timers[uniqueId] = setTimeout(callback, ms);
    };
})();

$(document).ready(function(){
  if ($('.breadcrumb_link:has(span.dropdown)')) {
    $('.breadcrumb_link:has(span.dropdown)').css('padding', '0')
    $('.breadcrumb_link:has(span.dropdown) > .dropdown > .dropdown-toggle').css('margin-top', '-0.15em');
  }
});

var checkForRangeChange = function(node) {

  var removeValue = function(nodeHtml, mapHtml) {
    if (nodeHtml.split(" ").length > 2) {
      newTxt = nodeHtml.replace(/\d*/g, '');
      $('.' + node + '_limit').html(newTxt);
    }
    if (mapHtml) {
      if (node === "upper") {
        if (mapHtml.match(/(to)\s+\d*/) !== null) {
          newTxt = mapHtml.replace(/(to)\s+\d*/, "to ");
          $('.map_range label').html(newTxt);
        }
      } else {
        if (mapHtml.match(/(from)\s+\d*/) !== null) {
          newTxt = mapHtml.replace(/(from)\s+\d*/, "from ");
          $('.map_range label').html(newTxt);
        }
      }
    }
  }

  $('#' + node).change(function(){
    var nodeHtml = $('.' + node + '_limit').html();
    var mapHtml = $('.map_range label').html();

    if (!$(this).val()) {
      removeValue(nodeHtml, mapHtml);

      if (!$('#lower').val() && !$('#upper').val()) {
        $('.map_range').css('display', 'none');
      }

      $('.' + node + '_limit').css('display', 'none');
    } else {
      removeValue(nodeHtml, mapHtml);
      $('.' + node + '_limit').append(" " + $(this).val()).show();

      if (mapHtml) {
        if (node === "upper") {
          newTxt = $('.map_range label').html().replace(/(to\s*)/, "to " + $(this).val());
          $('.map_range label').html(newTxt);
        } else {
          newTxt = $('.map_range label').html().replace(/(from\s*)/, "from " + $(this).val() + " ");
          $('.map_range label').html(newTxt);
        }
  
        $('.map_range').show();
      }
    }

    if (node === "upper") {
      $('#snapshot_range_high').val($('#' + node).val());
    } else {
      $('#snapshot_range_low').val($('#' + node).val());
    }
  });
}

var checkForMapFilterChange = function() {
  $('#filters').change(function(ev){
    if (ev.target.name !== "upper" && ev.target.name !== "lower") {
      key = ":" + ev.target.id + "=>";
      regex = new RegExp(key + "(\")?(\\d*\\s?)*(\")?");
      if (ev.target.id == "day_of_week") {
        $('#snapshot_filters').val($('#snapshot_filters').val().replace(regex, key + "\"" + ev.target.value + "\""));
      } else {
        $('#snapshot_filters').val($('#snapshot_filters').val().replace(regex, key + ev.target.value));
      }
    }
  });
}

var checkForChartSliderChange = function(slider_value) {
  if($('#snapshot_filters').length == 0) {
    return;
  }
  
  key = ":slider_value=>";
  regex = new RegExp(key + "(\")?(\\d*\\s?)*(\")?");
  $('#snapshot_filters').val($('#snapshot_filters').val().replace(regex, key + slider_value));
}

var getAdditionalFilterValues = function(addedLayers, viewId) {
  var toSend = {};

  for (i=0; i < addedLayers.length; i++) {
    key = $(addedLayers[i]).closest('.checkbox').attr('data-view-id');

    if ($("#filter-form-" + key)) {

      // If the filter form exists, then it will at least have a range filter
      lowVal = $("#filter-form-" + key).find('.number_range_filter#lower').val();
      highVal = $("#filter-form-" + key).find('.number_range_filter#upper').val();

      // If the filter form has a vehicle_class field, it is a SpeedFact
      if ($("#filter-form-" + key + " #vehicle_class")) {
        year = $("#filter-form-" + key).find('#year').val();
        month = $("#filter-form-" + key).find('#month').val();
        hour = $("#filter-form-" + key).find('#hour').val();
        day_of_week = $("#filter-form-" + key).find('#day_of_week').val();
        vehicle_class = $("#filter-form-" + key).find('#vehicle_class').val();

        toSend["year" + key] = year;
        toSend["month" + key] = month;
        toSend["hour" + key] = hour;
        toSend["day_of_week" + key] = day_of_week;
        toSend["vehicle_class" + key] = vehicle_class;
      }

      // If the filter form has a transit_mode, it is a CountFact
      if ($("#filter-form-" + key + " #transit_mode")) {
        year = $("#filter-form-" + key).find('#year').val();
        hour = $("#filter-form-" + key).find('#hour').val();
        transit_mode = $("#filter-form-" + key).find('#transit_mode').val();
        transit_direction = $("#filter-form-" + key).find('#transit_direction').val();

        toSend["year" + key] = year;
        toSend["hour" + key] = hour;
        toSend["transit_mode" + key] = transit_mode;
        toSend["transit_direction" + key] = transit_direction;
      }

      // Store the lower/upper values in a hash, unless they belong to the main view
      toSend["lower" + key] = lowVal;
      toSend["upper" + key] = highVal;
    }

    // Store the year from the slider, if present
    if ($('#yearSlider')) {
      toSend["year"] = $('#yearSlider').val();
    }
  }

  $('#snapshot_filters').val(JSON.stringify(toSend));
}

var getUrlParam = function(name) {
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return "";
  else
    return results[1].replace("+", " ");
}

function show_alert(message, type) {
  var alert_type = "alert-" + (type || 'danger');

  $('#messages').html('<div class="alert ' + alert_type + ' fade in"><a class="close" data-dismiss="alert">x</a><div id="flash_notice">' + message + '</div></div>');
}

function hide_alert () {
  $('#flash_notice').parents('.alert').hide();
}

function toggleShowMoreLink() {
  $('#source_views, #contributors, #users, #librarians').on('shown.bs.collapse hidden.bs.collapse', function () {
    if ($(this).hasClass('in')) {
      $(this).siblings('a').text('show less');
    } else {
      $(this).siblings('a').text('show more');
    }
  });
}

function setupTreeview(selected) {
  $.get("/sources/state.json", function(data) {
    if (data) {
      console.log('setupTreeview', selected, data)
      toClick = [];
      for(i=0; i < data.length; i++) { toClick.push($("#" + data[i])); }
      toClick.forEach(function(item){ item.click(); });
      setTimeout(function(){ 
        if (selected) {
          parentSource = $('#view' + selected).closest('ul').siblings('.source-name');
          if (parentSource.hasClass('collapsed')) { parentSource.click(); }
          $('#view' + selected).click();
        }
      }, 200);
    }
  });

  $('.btn-link').click(function(){
    existing = $(this).html();
    prevClick = $('.btn-link:has(strong)');

    if ( existing.match(/<\/?(strong|u)>/g) == null ) {
      if (prevClick.length > 0) {
        prevClickHtml = prevClick.html();
        $('.btn-link:has(strong)').html(prevClickHtml.replace(/<\/?(strong|u)>/g, ''));
        $(this).html("<strong><u>" + existing + "</u></strong>");
      }
      $(this).html("<strong><u>" + existing + "</u></strong>");
      $(this).click();
    }
  });

  $("ul.tree").on('shown.bs.collapse hidden.bs.collapse', function () {
    header = $(this).parent().children('h4');
    txt = header.text();

    if ($(this).hasClass('in')) {  
      if ( header.has('em').length > 0 ) {
        header.html("<strong><em>" + txt.replace(/(\.\.\.)/, '') + "</em></strong>");
      } else {
        header.html("<strong>" + txt.replace(/(\.\.\.)/, '') + "</strong>");
      }
    } else {
      if (txt.match(/(\.\.\.)/) == null) {
        if ( header.has('em').length > 0 ) {
          header.html("<strong><em>" + txt + "...</em></strong>");
        } else {
          header.html("<strong>" + txt + "...</strong>");
        }
      } else {
        if ( header.has('em').length > 0 ) {
          header.html("<strong><em>" + txt + "</em></strong>");
        } else {
          header.html("<strong>" + txt + "</strong>");
        }
      }
    }

    expanded = $("h4:not(.collapsed)");
    dataToSend = {state: [] };

    for(i=0;i < expanded.length; i++) {
      dataToSend["state"].push($(expanded)[i].id);
    }

    currentState = dataToSend;
    $.ajax({
      type: "patch",
      url: '/sources/update_state',
      data: currentState,
      dataType: "script"
    });
  });
}

function expandAllSources() {
  $(".treeview h4.source-name.collapsed").click();
}

function collapseAllSources() {
  $(".treeview h4.source-name:not(.collapsed)").click();
}

function fadeModal(modalId, objName, existing) {
  modal = $('#' + modalId);
  form = modal.find('form');
  modalBody = modal.find('.modal-body');
  modalContent = modal.find('.modal-content');
  successMsg = "<div id='successMsg' class='text-center'><label>" + objName + " saved.</label></div>";

  if (existing) {
    detachedBody = modalBody.detach();
    modalContent.append(successMsg);
  } else {
    form.toggle()
    modalBody.prepend(successMsg);
  }
  
  setTimeout(function(){ modal.modal('hide') }, 2000);
  modal.on('hidden.bs.modal', function(e){
    if (existing) {
      modalContent.empty().append(detachedBody);
    } else {
      form.toggle().trigger('reset');
      form.find('select.multiselect').multiselect('refresh');
      $('#successMsg').remove();
    }
    $(this).off(e);
  });
}

function sortAlpha(a,b) {
  crossBrowserA = a.textContent || a.innerText;
  crossBrowserB = b.textContent || b.innerText;
  return crossBrowserA.toLowerCase() > crossBrowserB.toLowerCase() ? 1 : -1;
}

function drawGoogleChart(data_arr, elementId, chartType) {
  var chart;
  var data;
  var options;

  google.load('visualization', '1', {packages: ["corechart"]});
  google.setOnLoadCallback(drawChart);

  function drawChart() {
    data = google.visualization.arrayToDataTable(data_arr);
    if (chartType == 'pie') {
      chart = new google.visualization.PieChart(document.getElementById(elementId));  
    } else {
      chart = new google.visualization.BarChart(document.getElementById(elementId));
    }
    chart.draw(data, options);
  }

  $(function() {
    $(window).resize(function(){
      chart.draw(data, options);
    });
  });
}

if(!(window.console && console.log)) {
  console = {
    log: function(){},
    debug: function(){},
    info: function(){},
    warn: function(){},
    error: function(){}
  };
}

function createPopover(node_id) {
  $(node_id).popover({
      'html': true,
      'container': 'body',
      'template': '<div class="popover"><div class="arrow"></div><div class="popover-inner"><div class="popover-content"><p></p></div></div></div>',
      'trigger': 'manual focus',
      'animation': false,
      'placement': 'auto'
  })
  .on("show.bs.popover", function () {
    $(node_id).not(this).popover('hide');
  })
  .on("mouseenter", function () {
    var _this = this;
    $(this).popover("show");
    $(".popover").on("mouseleave", function () {
        $(_this).popover('hide');
    });
  })
  .on("mouseleave", function () {
    var _this = this;
    setTimeout(function () {
        if (!$(".popover:hover").length) {
            $(_this).popover("hide");
        }
    }, 0);
  });
}

function showSymbologySaveAsDialog(symbologyData) {
  var dialog = $('#symbologySaveAsDialog');
  var form = dialog.find('form');

  form.find('input[name=base_symbology_id]').val(symbologyData['base_symbology_id']);
  form.find('input[name=color_schemes]').val(JSON.stringify(symbologyData['color_schemes']));

  dialog.modal('show');
}

function makeColumnsInteractive() {
  $(document).on("click", ".remove_col", function(){
    var columnNum = $(this).parent().index();
    var columnToTheRight = $("#column_data tr td:nth-child(" + (columnNum + 2) + ")");
    var columnHeader = $("tr th:nth-child(" + (columnNum + 2) + ")");

    columnToTheRight.remove();
    columnHeader.remove();

  }).on("click", ".add_col", function(){
    var columnNum = $(this).parent().index();
    var wholeColumn = $("#column_data tr td:nth-child(" + (columnNum + 1) + ")");
    var columnHeader = $("tr th:nth-child(" + (columnNum + 1) + ")");
    var newInput = "<td><input class='string required form-control-mock' name='view[columns][new_col_" + (columnNum + 2) + "]' type='text' value=''></td>";
    var plusMinus = "<th class='text-center'><a class='add_col' style='padding-right:5px;'><div class='fa fa-plus'></div></a><a class='remove_col'><div class='fa fa-minus'></div></a></th>";
    var newCheckbox = "<td class='text-center'><label class='checkbox'><input class='boolean optional' name='view[value_columns][new_col_" + (columnNum + 2) + "]' type='checkbox' value='0'></label></td>";

    if (wholeColumn.length == 0) { // If you are adding something before the first column
      wholeColumn = $("#column_data tr td:nth-child(" + (columnNum + 2) + ")");
      if (wholeColumn.length == 0) { // If there are no existing columns with inputs
        wholeColumn = $("#column_data tr th:gt(0)");
        wholeColumn.after(newInput);
        if (wholeColumn.length == 4) { wholeColumn.last().siblings().first().replaceWith(newCheckbox); }
      } else {
        wholeColumn.before(newInput);
        if (wholeColumn.length == 4) { wholeColumn.last().prev('td').replaceWith(newCheckbox); }
      }
      columnHeader.first().after(plusMinus);
    } else {
      clone = wholeColumn.clone();
      $.each(wholeColumn, function(idx, col){
        clonedInput = $(clone[idx]).find("input");
        clonedName = $(clonedInput).attr("name").replace(/(col_)\d+/g, ("new_col_" + Math.floor(Math.random() * 1000000)));
        cleanInput = clonedInput.is(':checkbox') ? clonedInput.removeAttr('checked').attr("name", clonedName).end() : clonedInput.val("").attr("name", clonedName).end();
        $(col).after(cleanInput);
      });
      columnHeader.after(plusMinus);
    }
  });
}
