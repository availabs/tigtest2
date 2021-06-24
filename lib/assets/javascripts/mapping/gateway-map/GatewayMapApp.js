/**
 * Application class as starting point to create a map for gateway data
 *
 * Dependency:
 *  1. CsLeaflet.Leaflet: a leaflet wrapper to create a map with basic map operations
 *  2. GatewayMap: extention to CsLeaflet.Leaflet to attach Gateway application specific map supports to the map, including:
 *    - a Layer switcher: basemaps, overlays
 *    - render Gateway data on map as color gradient thematic layer
 *    - show thematic layer legends
 *    - show labels in each feature on map
 *  3. GatewayMapUtil: a utility class. (ajax to request data, clone JavaScript object, etc)
 */

/**
 * @param {string}: mapId, the id of the map container
 * @param {object}: mapOptions, the options to CsLeaflet.Leaflet to create a map
 * @param {object}: mapBaseConfigs, a look-up hash object that lists available basemaps, areas, base area file info
 */
function GatewayMapApp(mapId, mapOptions, mapBaseConfigs, viewConfigs, snapshotParams) {
		var _mapId = mapId || 'map';
		var _mapOptions = mapOptions || {};
		var _mapBaseConfigs = mapBaseConfigs || {};
    var _defaultBasemapName = mapBaseConfigs.default_basemap;
    var _homeMapViewOptions = viewConfigs.home_map_view_options;

    var _defaultMapBounds = mapBaseConfigs.map_bounds || null; // this represents whole area extent
    var _initMapBounds = _defaultMapBounds; // initial map bounds, could be overwritten by snapshot bounds
    var _basemaps = mapBaseConfigs.basemaps || [];
    var _overlays = mapBaseConfigs.overlays || [];
    var _map = null;
    var _overlayLayers = {};
    var _viewConfigs = viewConfigs || {};
    var _area_id = _viewConfigs.area_id;
    var _year = _viewConfigs.year_slider_value;
    if(snapshotParams && snapshotParams.exported_at) {
      // check if params expired
      var exported_at = new Date(Date.parse(snapshotParams.exported_at));
      var exported_since = new Date() - exported_at;
      if(exported_since > 24 * 60 * 60 * 1000) {
        //expires in one day
        snapshotParams = {};
      }
    }
    var _snapshotParams = snapshotParams || {};
    var _overlaySnapshotParams = _snapshotParams.overlays || {};
    var _isCaching = true; //by default, we do automatic chaching on map parameters
    
    var requestBaseOverlayConfigs = function(baseUrl) {
      _overlays.forEach(function(params){
        _map.LMmap.spin(true);
        $.ajax({
          url: baseUrl,
          data: params
        }).done(function(layerConfig){
          _map.LMmap.spin(false);
          layerConfig = layerConfig || {};
          layerConfig.turn_off_by_default = updateBaseOverlayVisibilityBySnapshotParams(layerConfig.name, layerConfig.turn_off_by_default);
          _map.addBaseOverlay(layerConfig);   
        }).fail(function(ex){
          console.log(ex);
          _map.LMmap.spin(false);
        });
      });
    };

    var addDataOverlay = function(viewId, dataConfig, layerParams) {
      _map.LMmap.spin(true);
      var whetherZoomToAreaExtent = (_area_id !=  _snapshotParams.area_id) && isMapEmpty();
      var previsouLayerParams = null;
      if(!dataConfig.value_column_changed) {
        previsouLayerParams = layerParams || _overlaySnapshotParams[viewId];
      }
      var newOverlayLayer = new GatewayOverlayLayer(
        _map, 
        dataConfig,
        previsouLayerParams,
        whetherZoomToAreaExtent,
        viewId
      );

      _overlayLayers[viewId] = newOverlayLayer;

      if(whetherZoomToAreaExtent && _area_id == -1 && _defaultMapBounds) {
        _map.setMapBounds(_defaultMapBounds.xmin, _defaultMapBounds.ymin, _defaultMapBounds.xmax, _defaultMapBounds.ymax);
        _map.LMmap.fitBounds(_map.LMbounds);
      }

      newOverlayLayer.render();

      newOverlayLayer.renderSymbologyPanel();

      _map.LMmap.spin(false);
    }

    var requestDataOverlayConfigs = function(viewId, baseUrl, hasYearSlider) {
      _map.LMmap.spin(true);

      var params = {
        url: baseUrl
      };
      
      if(_area_id === 0 || _area_id) {
        params.data = params.data || {};
        params.data.area_id = _area_id;
      }

      if(hasYearSlider) {
        params.data = params.data || {};
        params.data.year = _year;
      }

      $.ajax(params).done(function(dataConfig){
        _map.LMmap.spin(false);
        updateViewLayer(viewId, dataConfig);  
      }).fail(function(ex){
        console.log(ex);
        show_alert('The attempt to load map data has failed. Please try again.');
        _map.LMmap.spin(false);
      });
    };

    var getOverlayLayer = function(layerId) {
      var layer = null;
      for(var viewId in _overlayLayers) {
        var viewLayer = _overlayLayers[viewId];
        var layers = viewLayer.getLayers();
        for(var tmpLayerId in layers) {
          var tmpLayer = layers[tmpLayerId];

          if(tmpLayer && tmpLayer.layerId === layerId) {
            layer = viewLayer;
            break;
          }
        }
      }

      return layer;
    };

    var getViewLayer = function(viewId) {
      return _overlayLayers[viewId];
    };

    var removeViewLayer = function(viewId) {
      var viewLayer = _overlayLayers[viewId];
      if(viewLayer) {
        viewLayer.removeFromMap();
      }

      delete _overlayLayers[viewId]; // free memory
    };

    var updateViewLayer = function(viewId, dataConfig) {
      dataConfig = dataConfig || {};
      var layerParams;
      if(!dataConfig.value_column_changed) {
        var viewLayer = getViewLayer(viewId);
        if(viewLayer) {
          layerParams = viewLayer.exportParameters();
        }
      }

      removeViewLayer(viewId);
      
      addDataOverlay(viewId, dataConfig, layerParams); 
    };

    var switchLayerSymbology = function(layerId, symbologyIndex) {
    	var viewLayer = getOverlayLayer(layerId);
      if(viewLayer) {
        viewLayer.switchLayerSymbology(layerId, symbologyIndex);
      }
    };

    var switchYearColumn = function(year) {
      _year = year;
      for(var viewId in _overlayLayers) {
        var overlay = _overlayLayers[viewId];
        if(overlay.include_year_slider) {
          overlay.switchDisplayColumn(year.toString());
        }
      }
    };


    var getFeatureGeometry = function(layerName, key) {
      $.ajax({
        url: _viewConfigs.feature_geometry_path,
        data: {
          view_name: layerName,
          key: key
        }
      }).done(function(geom){
        _map.zoomToWKT(geom);
      }).fail(function(ex){
        console.log(ex);
      });
    };  

    var formatDemoStatVal = function(val) {
      if(val % 1 != 0) {
        return $.formatNumber(val);
      } else {
        return $.formatNumber(val, {format:"#,##0", locale:"us"});
      }
    };

    var getTMCRoadName = function(tmcName, viewId) {
      $.ajax({
        url: _viewConfigs.tmc_roadname_path,
        data: {
          tmc_name: tmcName,
          view_id: viewId
        }
      }).done(function(resp){
        if(resp && resp.name) {
          $('#tmcRoadName').html("<b>Road Name: </b><span>" + resp.name + "</span>");
        }
      }).fail(function(ex){
        console.log(ex);
      });
    };  

    var getLinkRoadName = function(linkId, viewId) {
      $.ajax({
        url: _viewConfigs.link_roadname_path,
        data: {
          link_id: linkId,
          view_id: viewId
        }
      }).done(function(resp){
        if(resp && resp.name) {
          $('#linkRoadName').html("<b>Road Name: </b><span>" + resp.name + "</span>");
        }
      }).fail(function(ex){
        console.log(ex);
      });
    };  

    var getDemoStatistics = function(areaName, areaType, year) {
      $.ajax({
        url: _viewConfigs.demo_statistics_path,
        data: {
          area_name: areaName,
          area_type: areaType,
          year: year
        }
      }).done(function(stats){
        if(stats) {
          $('#allStats').hide();
          $('#hideAllStats').show();
          var tableTags = "<div  class='row demo-stats' style='padding: 5px 10px;'>" + 
            "<h4>All Statistics for Year " + year + "</h4>" + 
            "<div style='max-height: 130px; overflow-y: scroll;'>" + 
            "<table class='table table-condensed' style='margin: 0px;'>";
          stats.forEach(function(stat) {
            tableTags += "<tr><td style='text-align: right;'><b>" + stat.name + "</b></td>" + 
              "<td style='text-align:right; padding-left: 10px;'>" + formatDemoStatVal(stat.value) + "</td></tr>";
          });

          tableTags += "</table></div></div>";

          $('.info-window div:first').append(tableTags);
        }
      }).fail(function(ex){
        console.log(ex);
      });
    };  

    var getAllYearStatistics = function(areaName, areaType, stats) {
      if(stats) {
        $('#allYears').hide();
        $('#hideAllYears').show();
        var tableTags = "<div  class='row all-year-stats' style='padding: 5px 10px;'>" + 
          "<h4>All Year Statistics for " + areaType.toUpperCase() + " " + areaName + "</h4>" + 
          "<div style='max-height: 130px; overflow-y: scroll;'>" + 
          "<table class='table table-condensed' style='margin: 0px;'>";
        for(var key in stats) {
          if(key != 'area_type' && key != 'area') {
            tableTags += "<tr><td style='text-align: right;'><b>" + key + "</b></td>" + 
            "<td style='text-align:right; padding-left: 10px;'>" + formatDemoStatVal(stats[key]) + "</td></tr>";
          }
        }

        tableTags += "</table></div></div>";

        $('.info-window div:first').append(tableTags);
      }
    };  

    var addDisplayInfo = function() {
      var info = L.control();

      var lmMap = _map.LMmap;
      
      info.onAdd = function () {
        this._div = L.DomUtil.create('div', 'info info-window');
        this.update();
        return this._div;
      };

      info.update = function (infoProps) {
        $(info.getContainer()).show();
        if(typeof(infoProps) === 'object') {
          var titleTags = '';
          if(infoProps.title) {
            titleTags = '<h4>' + infoProps.title + '</h4>';
          }

          var typeLabel = "";
          switch(infoProps.type) {
            case 'taz':
              typeLabel = "TAZ ID";
              break;
            case 'tcc':
              typeLabel = "TCC";
              break;
            default:
              var typeParts = (infoProps.type || "").split("_");
              var convertedParts = [];
              // titleize
              typeParts.forEach(function(str) {
                convertedParts.push(str.charAt(0).toUpperCase() + str.slice(1).toLowerCase());
              });

              typeLabel = convertedParts.join(' ');

              if(infoProps.showTMCStats) {
                typeLabel = "TMC ID";
              } else if(infoProps.showLinkStats) {
                typeLabel = "Link ID";
              } 
              
              break;
          }

          var areaTypeTags = '';
          if(infoProps.key) {
            areaTypeTags = '<b>' + typeLabel + '</b>: ' + infoProps.key;
          }
          var demoStatsTags = '';
          var tmcStatsTags = '';
          var linkStatsTags = '';
          if(infoProps.showDemoStats) {
            demoStatsTags += "<button id='allStats' style='margin: 3px;' class='btn btn-xs btn-primary pull-left'>All Stats...</button>";
            demoStatsTags += "<button id='hideAllStats' style='display: none; margin: 3px;' class='btn btn-xs btn-primary pull-left'>Hide All Stats...</button>";
            demoStatsTags += "<button id='allYears' style='margin: 3px;' class='btn btn-xs btn-primary pull-left'>All Years...</button>";
            demoStatsTags += "<button id='hideAllYears' style='display: none; margin: 3px;' class='btn btn-xs btn-primary pull-left'>Hide All Years...</button>";
          }else if(infoProps.showTMCStats) {
            tmcStatsTags += "<div id='tmcRoadName' class='row' style='padding: 5px 10px;'></div>";
            var directions = {
              'N': 'Northbound',
              'S': 'Southbound',
              'W': 'Westbound',
              'E': 'Eastbound'
            };

            var rawDir = infoProps.attributes["direction"];
            var direction = directions[rawDir] || rawDir;
            if(direction) {
              tmcStatsTags += "<div id='tmcDirName' class='row' style='padding: 5px 10px;'><b>Direction: </b><span>" + direction + "</span></div>";
            }
            console.log(infoProps);
            getTMCRoadName(infoProps.key, infoProps.viewId);
          } else if(infoProps.showLinkStats) {
            linkStatsTags += "<div id='linkRoadName' class='row' style='padding: 5px 10px;'></div>";
            var directions = {
              'N': 'Northbound',
              'S': 'Southbound',
              'W': 'Westbound',
              'E': 'Eastbound'
            };

            var rawDir = infoProps.attributes["direction"];
            var direction = directions[rawDir] || rawDir;
            if(direction) {
              linkStatsTags += "<div id='linkDirName' class='row' style='padding: 5px 10px;'><b>Direction: </b><span>" + direction + "</span></div>";
            }
            getLinkRoadName(infoProps.key, infoProps.viewId);
          }
          var zoomToTags = "<button id='zoomToFeature' style='margin: 3px;' title='zoom to' class='btn btn-xs btn-primary fa fa-search-plus pull-right'/>";

          this._div.innerHTML = '<div style="padding: 6px 8px;">' + 
            titleTags + 
            "<div id='baseInfo' class='row' style='padding: 10px 10px 5px 10px;'>" +
              "<span style='font-size: large;'>" + infoProps.value + 
                (infoProps.showTMCStats || infoProps.showLinkStats ? ' mph' : '') +
              "</span>" +
              "<p>" + areaTypeTags + "</p>" +
              "</div>" +
            tmcStatsTags + 
            linkStatsTags + 
            "<div class='row' style='padding: 5px 10px;'>" +
              demoStatsTags +
              zoomToTags +
              "</div>" + 
          '</div>';
        } else {
          this._div.innerHTML = '';
        }

        info.properties = infoProps;
      };
      
      info.addTo(lmMap);

      var disableMapNavigation = function() {
        lmMap.dragging.disable();
        lmMap.touchZoom.disable();
        lmMap.doubleClickZoom.disable();
        lmMap.scrollWheelZoom.disable();
        if (lmMap.tap) lmMap.tap.disable();
      };

      var enableMapNavigation = function() {
        lmMap.dragging.enable();
        lmMap.touchZoom.enable();
        lmMap.doubleClickZoom.enable();
        lmMap.scrollWheelZoom.enable();
        if (lmMap.tap) lmMap.tap.enable();
      };

      var container = info.getContainer();
      container.addEventListener('mouseover', function () {
        disableMapNavigation();
      });

      container.addEventListener('touchstart', function () {
        disableMapNavigation();
      });

      // Re-enable dragging when user's cursor leaves the element
      container.addEventListener('mouseout', function () {
        enableMapNavigation();
      });

      container.addEventListener('touchend', function () {
        enableMapNavigation();
      });

      L.DomEvent
        .addListener(container, 'click', L.DomEvent.stopPropagation)
        .addListener(container, 'click', L.DomEvent.preventDefault);
      
      lmMap.displayInfo = info;

      // zoom to button
      $(container).on('click', '#zoomToFeature', function(){
        if(info.properties.layerName && info.properties.key) {
          getFeatureGeometry(info.properties.layerName, info.properties.key);
        }
      });

      $(container).on('click', '#allStats', function(){
        if($('.demo-stats').length > 0) {
          $('.demo-stats').show();

          $(this).hide();
          $('#hideAllStats').show();
        } else {
          getDemoStatistics(info.properties.key, info.properties.type, info.properties.column);
        }
      });

      $(container).on('click', '#hideAllStats', function(){
        if($('.demo-stats').length > 0) {
          $('.demo-stats').hide();
        }

        $(this).hide();
        $('#allStats').show();
      });

      $(container).on('click', '#allYears', function(){
        if($('.all-year-stats').length > 0) {
          $('.all-year-stats').show();

          $(this).hide();
          $('#hideAllYears').show();
        } else {
          getAllYearStatistics(info.properties.key, info.properties.type, info.properties.attributes);
        }
      });

      $(container).on('click', '#hideAllYears', function(){
        if($('.all-year-stats').length > 0) {
          $('.all-year-stats').hide();
        }

        $(this).hide();
        $('#allYears').show();
      });
    };

    var updateMapBaseOptionsBySnapshotParams = function() {
      var mapParams = _snapshotParams.map || {};
      _defaultBasemapName = mapParams.basemap || _defaultBasemapName;

      _initMapBounds = mapParams.bounds || _initMapBounds;
    };

    var updateBaseOverlayVisibilityBySnapshotParams = function(layerName, defaultValue) {
      var mapParams = _snapshotParams.map || {};
      if (mapParams.hasOwnProperty('visible_baseoverlays')) {
        defaultValue = !(mapParams.visible_baseoverlays.indexOf(layerName) >= 0);
      }
      return defaultValue;
    };

    var updateYearSliderValue = function() {
      var sliderParams = _snapshotParams.yearSlider || {};
      if(sliderParams.hasYearSlider) {
        _year = sliderParams.year;
      }
    };

    var processDataOverlaysFromSnapshot = function() {
      var overlayParams = _snapshotParams.overlays || {};
      for(var viewId in overlayParams) {
        if(viewId != _viewConfigs.id) { // base view layer is handled in init()
          $('#layers .checkbox[data-view-id=' + viewId + '] input').attr('checked', true).change();
        }
      }
    };

    // consturctor
    var _init = function() {
      // overwrite default options by snapshot parameters
      updateMapBaseOptionsBySnapshotParams();

      // overwrite year slider value if available from snapshot parameters
      updateYearSliderValue();

      //empty map container
      var CsMaps = CsMaps || {};
      CsMaps[_mapId] = Object.create(CsLeaflet.Leaflet);
      _map = CsMaps[_mapId];
      _map.init(_mapId, _mapOptions);

      //remove default attribution control
      _map.LMmap.removeControl(_map.LMmap.attributionControl);

      var mapBounds = _initMapBounds;
      if(mapBounds) {
        _map.setMapBounds(mapBounds.xmin, mapBounds.ymin, mapBounds.xmax, mapBounds.ymax);
      }
      _map.showMap();
    
      _map.LMmap.on('updateDisplayInfo', function(evt){
        var _info = this.displayInfo;
        if(!(_info instanceof L.Control)) {
          addDisplayInfo();
          _info = this.displayInfo;
        }
        
        _info.update(evt.info);
      });

      _map.LMmap.on('click', function(evt){
        evt.originalEvent.preventDefault();    
      });

      //basemaps
      _map.addBasemaps(_basemaps, _defaultBasemapName);
      //base overlays
      requestBaseOverlayConfigs(_viewConfigs.base_overlay_path);
      //data overlays
      requestDataOverlayConfigs(_viewConfigs.id, _viewConfigs.data_overlay_path);

      //add customized controls
      _map.addZoomSliderControl();
      _map.addFullscreenControl(document.getElementById('mapContainer'));
      _map.addNavbar({
        home_center: new L.latLng(_homeMapViewOptions.center_x, _homeMapViewOptions.center_y),
        home_zoom: _homeMapViewOptions.zoom
      });
      _map.addSidebar('sidebar');

      if(_mapBaseConfigs['study_area_control_enabled']) {
        _map.addStudyAreaControl();
        _map.LMmap.on('draw:created', function (e) {
          var studyArea = e.layer;

          if(_map.studyAreaEditingLayer) {
            _map.studyAreaEditingLayer.clearLayers();
            _map.studyAreaEditingLayer.addLayer(studyArea); 

            $('#studyAreaModal').modal('show');
          } 
        });
      }

      _map.registerAddOverlayEvent();
      _map.registerRemoveOverlayEvent();
    }();

    var getMap = function() {
      return _map;
    };

    var isMapEmpty = function() {
      for(var viewId in _overlayLayers) {
        return false;
      }
      return true;
    };

    var getDataOverlays = function() {
      return _overlayLayers;
    };

    var showAreaBoundary = function(viewId, isVisible) {
      var viewLayer = getViewLayer(viewId);
      if(viewLayer) {
        viewLayer.setViewAreaBoundaryVisibility(isVisible);
        var mapLayers = viewLayer.getLayers();
        for(var lyId in mapLayers) {
          var ly = mapLayers[lyId];
          if(ly) {
            ly.showAreaBoundary = isVisible;
            ly.setStyle(ly.options.style);
          }
        }
      }
    };

    var checkYearSlider = function() {
      var hasYearSlider = false;
      for(var viewId in _overlayLayers) {
        if(_overlayLayers[viewId].include_year_slider) {
          hasYearSlider = true;
          break;
        }
      }

      return hasYearSlider;
    };

    var exportParameters = function() {
      // map general
      var mapParams = _map.exportParameters();

      // overlays
      var overlayParams = {};
      for(var viewId in _overlayLayers) {
        overlayParams[viewId] = _overlayLayers[viewId].exportParameters();
      }

      // filters
      var yearSlider = {
        hasYearSlider: checkYearSlider(),
        year: _year
      };

      var params = {
        area_id: _area_id,
        map: mapParams,
        yearSlider: yearSlider,
        overlays: overlayParams
      };

      return params;
    };

    var isCaching = function() {
      return _isCaching;
    };

    var disableCache = function() {
      _isCaching = false;
    };

    var resetViewSymbology = function(viewId, subject) {
      console.log('resetting symbology');
      var viewLayer = getViewLayer(viewId);
      if(viewLayer) {
        viewLayer.resetViewSymbology(subject);
      }
    };

    var updateViewSymbology = function(viewId, settings) {
      console.log('updating symbology');
      var viewLayer = getViewLayer(viewId);
      if(viewLayer) {
        viewLayer.updateViewSymbology(settings);
      }
    };

    var searchViewLayer = function(viewId, keyword) {
      var viewLayer = getViewLayer(viewId);
      if(viewLayer) {
        viewLayer.searchMap(keyword);
      }
    };

    var getStudyAreaWkt = function() {
      var areaWkt = null;

      var editingLayer = getMap().studyAreaEditingLayer;
      if(editingLayer) {
        var areas = editingLayer.getLayers()
        if(areas.length > 0) {
          areaWkt = new Wkt.Wkt().fromObject(areas[0]).write();
        }
      }

      return areaWkt;
    };

    var clearStudyArea = function() {
      var editingLayer = getMap().studyAreaEditingLayer;
      if(editingLayer) {
        editingLayer.clearLayers();
      }
    };

    //public accessible
    return {
      getMap: getMap,
      exportParameters: exportParameters,
      isCaching: isCaching,
      disableCache: disableCache,
      getDataOverlays: getDataOverlays,
    	addDataOverlay: addDataOverlay,
      getViewLayer: getViewLayer,
      removeViewLayer: removeViewLayer,
      updateViewLayer: updateViewLayer,
      checkYearSlider: checkYearSlider,
      requestDataOverlayConfigs: requestDataOverlayConfigs,
      processDataOverlaysFromSnapshot: processDataOverlaysFromSnapshot,
			switchYearColumn: switchYearColumn,
      switchLayerSymbology: switchLayerSymbology,
      updateViewSymbology: updateViewSymbology,
      resetViewSymbology: resetViewSymbology,
      showAreaBoundary: showAreaBoundary,
      searchViewLayer: searchViewLayer,
      getStudyAreaWkt: getStudyAreaWkt,
      clearStudyArea: clearStudyArea
    };
};

/**
 * @param {object}: map, a GatewayMap instance
 * @param {object}: mapBaseConfigs, a look-up hash object that lists available basemaps, areas, base area file info
 * @param {object}: dataConfig, overlay data specific configurations (data to render, symbology etc)
 */
function GatewayOverlayLayer(map, dataConfig, layerSnapshotParams, whetherZoomToAreaExtent, viewId) {
    // snapshot params
    _layerSnapshotParams = layerSnapshotParams || {};
    
    var _overlay = this;
    dataConfig = dataConfig || {};

    // data configuration
    var layerName = dataConfig.name;
    var data = dataConfig.data || [];
    var layerConfig = dataConfig.referenceLayerConfig || {};
    layerConfig.is_demo = dataConfig.is_demo;
    layerConfig.is_tmc = dataConfig.is_tmc;
    layerConfig.is_link = dataConfig.is_link;
    layerConfig.showAreaBoundary = _layerSnapshotParams.hasOwnProperty('showAreaBoundary') ?
     _layerSnapshotParams.showAreaBoundary : dataConfig.showAreaBoundary;
     _overlay.showAreaBoundary = layerConfig.showAreaBoundary;
    var areaColumn = dataConfig.referenceColumn || '';
    var zoomExtentWKT = dataConfig.zoomExtentWKT || null;

    // symbology
    var _symbologyList = dataConfig.symbologies || [];
    var _defaultSymbologyList = [];
    _symbologyList.forEach(function(sym) {
      _defaultSymbologyList.push(GatewayMapUtil.cloneObject(sym));
    });
    
    var getFirstSymbology = function() {
      return _symbologyList.length > 0 ? _symbologyList[0] : {};
    };
    var symbology = getFirstSymbology();

    var getSymbologyList = function() {
      return _symbologyList;
    };

    var resetSymbologyList = function(newSymList) {
      _symbologyList = newSymList || [];

      _defaultSymbologyList = [];
      _symbologyList.forEach(function(sym) {
        _defaultSymbologyList.push(GatewayMapUtil.cloneObject(sym));
      });

      renderDefaultSymbology();
    };

    var addSymbology = function(sym) {
      _symbologyList.push(sym);
      _defaultSymbologyList.push(GatewayMapUtil.cloneObject(sym));
    };

    var deleteSymbology = function(subject) {
      var sym = getSymbologyBySubject(subject);
      var symIndex = _symbologyList.indexOf(sym);
      if(symIndex >= 0) {
        _symbologyList.slice(symIndex, 1);
      }

      var originalSym = getDefaultSymbologyBySubject(subject);
      var originalSymIndex = _defaultSymbologyList.indexOf(sym);
      if(originalSymIndex >= 0) {
        _defaultSymbologyList.slice(originalSymIndex, 1);
      }

      renderDefaultSymbology();
    };

    var renderDefaultSymbology = function() {
      _overlay.symbology = getFirstSymbology();
      updateViewSymbology(_overlay.symbology);
    };

    var getSymbologyBySubject = function(subject) {
      var sym = null;
      var symbologyList = getSymbologyList();
      for(var i=0, symCount=symbologyList.length; i<symCount; i++) {
        if(symbologyList[i].subject === subject) {
          sym = symbologyList[i];
          break;
        }
      }

      return sym;
    };

    var getDefaultSymbologyBySubject = function(subject) {
      var sym = null;
      var symbologyList = _defaultSymbologyList;
      for(var i=0, symCount=symbologyList.length; i<symCount; i++) {
        if(symbologyList[i].subject === subject) {
          sym = symbologyList[i];
          break;
        }
      }

      return sym;
    };

    var getSymbologyById = function(symId) {
      var sym = null;
      var symbologyList = getSymbologyList();
      for(var i=0, symCount=symbologyList.length; i<symCount; i++) {
        if(symbologyList[i].id === symId) {
          sym = symbologyList[i];
          break;
        }
      }

      return sym;
    };

    // update symbology column index based on previous snapshot parameter
    if(_layerSnapshotParams.symbology) {
      var layerSymbologyParam = _layerSnapshotParams.symbology[layerName] || {};
      var sym = getSymbologyBySubject(layerSymbologyParam.subject);
      if(sym) {
        symbology = sym;
      }

      var layerSymbologyIndex = layerSymbologyParam.columnIndex;
      if(layerSymbologyIndex != symbology.default_column_index && (layerSymbologyIndex || layerSymbologyIndex === 0)) {
        symbology.default_column_index = layerSymbologyIndex;
      }

      if(layerSymbologyParam.symbology_type)
        symbology.symbology_type = layerSymbologyParam.symbology_type;
      if(layerSymbologyParam.color_scheme)
        symbology.color_scheme = layerSymbologyParam.color_scheme;
    }

    // update layer default visibility based on previous snapshot parameter
    if(_layerSnapshotParams.visibility) {
      if(_layerSnapshotParams.visibility[layerName] === false) {
        layerConfig.turn_off_by_default = true;
      }
    }

    var getColumns = function() {
      return symbology.columns || [];
    };

    var getDefaultDisplayColumnIndex = function() {
      var columns = getColumns();
      var defaultColumnIndex = symbology.default_column_index;
      if(!defaultColumnIndex && columns.length ==0) {
        return null;
      }

      return defaultColumnIndex ? defaultColumnIndex : columns[0].index;
    };

    //case insensitive
    var compareStringValues = function(valA, valB) {
      if(typeof(valA) === 'string' && typeof(valB) === 'string') {
          return valA.toUpperCase() === valB.toUpperCase();
      } else {
          return valA === valB;
      }
    };
    
    //find data of a given area
    var findFeatureValue = function(attrData, columnIndex) {
      if(!attrData || !columnIndex) {
          return null;
      }
      
      var value=null;
      var colConfig = getDisplayColumnConfig(columnIndex);
      if(colConfig && typeof(colConfig) === 'object') {
        value = attrData[colConfig.column];
      }

      return value;
    };
    
    //return: {MinValue: xxx, MaxValue: xxx}
    var calculateValueBounds = function(layer) {
      var layerSymbology = layer.symbology;


      var inputData = data.features;
      if(!(inputData instanceof Array) || inputData.length === 0) {
          return null;
      }
      
      var columns = getColumns();

      switch(layerSymbology.symbology_type) {
        case 'geometric_breaks':
        case 'natural_breaks':
          var minValue, maxValue;
          for(var i=0, dataCount=inputData.length; i<dataCount; i++) {
            var dataRow = inputData[i].properties;
            for(var j=0, columnCount=columns.length; j<columnCount; j++) {
              var breakColName = columns[j].column;
              var cellValue = parseFloat(dataRow[breakColName]);
              if(isNaN(cellValue)) {
                continue;
              }
              
              if(typeof(minValue) !== 'number' || cellValue < minValue) {
                minValue = cellValue;
              }
              
              if(typeof(maxValue) !== 'number' || cellValue > maxValue) {
                maxValue = cellValue;
              }
            }
          }
          
          if(typeof(minValue) === 'number' && typeof(maxValue) === 'number') {
              layerSymbology.minValue = minValue;
              layerSymbology.maxValue = maxValue;
          }
          break;

        case 'quantile_breaks':
          var rawValues = [];
          for(var i=0, dataCount=inputData.length; i<dataCount; i++) {
            var dataRow = inputData[i].properties;
            for(var j=0, columnCount=columns.length; j<columnCount; j++) {
              var breakColName = columns[j].column;
              var cellValue = parseFloat(dataRow[breakColName]);
              if(isNaN(cellValue)) {
                continue;
              }
              
              rawValues.push(cellValue);
            }
          }

          var valueCounts = {};
          var uniqueValues = [];
          var totalCount = rawValues.length;
          for(i = 0; i < totalCount; ++i) {
              var val = rawValues[i];
              if(!valueCounts[val]) {
                uniqueValues.push(val);
                valueCounts[val] = 0;
              }
              ++valueCounts[val];
          }

          function sortNumber(a,b) {
              return a - b;
          }
          uniqueValues = uniqueValues.sort(sortNumber);

          var sortedValueCounts = [];
          uniqueValues.forEach(function(val){
            sortedValueCounts.push([val, valueCounts[val]]);
          });

          symbology.values = {
            totalCount: totalCount,
            minValue: uniqueValues[0],
            maxValue: uniqueValues[uniqueValues.length - 1],
            valueCounts: sortedValueCounts
          };

          break;

        default:
          break;
      }
      
    };

    //find the column configuration
    var getDisplayColumnConfig = function(columnIndex) {
      var colConfig = null;
      var columns = getColumns();
      for(var i=0, colCount=columns.length; i<colCount; i++) {
        var tmpColConfig = columns[i];
        if(tmpColConfig.index === columnIndex) {
          colConfig = tmpColConfig;
          break;
        }
      }
      
      return colConfig;
    };
    
    var renderLayer = function(layer) {
      var columnIndex = layer.displayColumnIndex;
      var displayConfig = getDisplayColumnConfig(columnIndex);
      var displayTitle = "";
      if(displayConfig) {
          displayTitle = displayConfig.title;
      }
      
      //update display properties
      map.updateLayerDisplayProperties(layer, "displayTitle", displayTitle);
      map.updateLayerDisplayProperties(layer, "displayLabelPropertyName", areaColumn);

      //render
      map.renderThematicColor(layer, symbology);
    };
    
    //render layer based on data values
    var thematicRenderLayer = function(layer) {
      if(layerConfig.type === 'Geojson') {
        calculateValueBounds(layer);

        map.prepareLayerSymbologyValues(layer, layer.symbology || symbology);
      
        renderLayer(layer);
      } else {
        map.calculateTileFeatureValueBounds(layer);

        map.prepareLayerSymbologyValues(layer, layer.symbology || symbology);

        if(symbology.show_legend) {
          var symbologyList = getSymbologyList();
          map.addColorGradientLegend(layer, symbologyList, layerConfig.turn_off_by_default);
        }

        layer.setStyle(layer.options.style);
      }
    };

    var removeMapLayer = function(layerObj) {
      var layerControl = map.getLayerControl();
      if(layerControl) {
        layerControl.removeLayer(layerObj); // remove from layer control
      }
      map.LMmap.removeLayer(layerObj); // remove from map
      map.deleteLayerLegendContainer(layerObj.layerId); //remove legend
      map.deleteLayerAttribution(layerObj.layerId);
    }

    var removeFromMap = function() {
      var layers = this.getLayers();
      if(layers) {
        for(var layerId in layers) {
          var layerObj = layers[layerId];
          if(layerObj) {
            removeMapLayer(layerObj);
          }
        }
      }

      delete this; // free memory
    };
    
    //load layer
    var layerCallbackFn = function(layer) {
      layer.symbology = symbology;
      _overlay.layer = layer;
      map.setAreaColumnNameForLayer(layer, areaColumn);
      //add legend
      if(symbology.show_legend) {
        var symbologyList = getSymbologyList();
        map.addColorGradientLegend(layer, symbologyList, layerConfig.turn_off_by_default);
      }
      
      if(layerConfig.type === 'Geojson') {
        var displayColumnIndex = getDefaultDisplayColumnIndex();
        map.setDisplayColumnIndexForLayer(layer, displayColumnIndex);
      
      
        if (layerConfig.showLabel) {
          map.showLabel(layer, areaColumn, layerConfig.labelOptions);
        }
        map.setValueLocaterForLayer(layer, findFeatureValue);


        thematicRenderLayer(layer);
      
        //register events(mousehover, click)
        map.registerEventsForLayer(layer, layerConfig);
      }
    };

    var updateSelectedFeatureInfo = function(layer) {
      if(layerConfig.type === 'PBF_TILE') {  
        var selectedFeture = layer._selectedFeature;
        if(selectedFeture) {
          selectedFeture.deselect();
          selectedFeture.select();
        }
      } else {
        console.log('TODO: feature popup change along with column change for layer type ' + layerConfig.type);
      }
    };
      
    //function to display data of another column
    var switchDisplayColumn = function(columnName) {
      var layers = getLayers();
      for(var lyId in layers) {
        var layer = layers[lyId];
        if(layer && layer.symbology) {
          var columnIndex = map.getColumnIndex(layer.symbology.columns, columnName);
          map.setDisplayColumnIndexForLayer(layer, columnIndex);
          if(layerConfig.type === 'Geojson') {  
            renderLayer(layer);
          } else {
            layer.setStyle(layer.options.style);
          }

          updateSelectedFeatureInfo(layer);
        }
      }
    };

    var switchLayerSymbology = function(layerId, symbologyIndex) {
      symbology = getSymbologyById(symbologyIndex);

      if(symbology) {
        var ly = getLayers()[layerId];
        ly.displayColumnIndex = getDefaultDisplayColumnIndex(symbology);
        updateLayerSymbology(ly, symbology);

        updateSelectedFeatureInfo(ly);
      }
    };

    var updateLayerSymbology = function(layer, symbology) {
      if(layer && symbology) {
        if(dataConfig.addCountFactPoint) { // Re-draw count fact layer
          var layerVisibility = layer._map ? true : false;
          removeMapLayer(layer);
          _overlay.layer = map.addCountFactPoints(
            data, 
            symbology,
            dataConfig.baseUrl || '', 
            layerName,
            layerVisibility,
            dataConfig.request_data,
            dataConfig.hub_bound_file_path
          );
        } else { // Update layer symbology
          layer.symbology = symbology;
          map.setDisplayColumnIndexForLayer(layer, symbology.default_column_index);

          thematicRenderLayer(layer);
        }
      }
    };

    var renderSymbologyPanel = function() {
      var showAreaBoundary = dataConfig.showAreaBoundary;
      if(_layerSnapshotParams && _layerSnapshotParams.hasOwnProperty('showAreaBoundary')) {
        showAreaBoundary = _layerSnapshotParams.showAreaBoundary;
      }

      var symUrl = "/views/" + viewId + "/symbology";

      var isPolygon = dataConfig.geometry_type === 'POLYGON' || 
        (dataConfig.referenceLayerConfig && dataConfig.referenceLayerConfig.geometry_type === 'POLYGON');
      
      var params = {};
      if(isPolygon) {
        params["show_area_boundary"] = showAreaBoundary;
      }

      var layerSymbology = null;
      var lyrs = getLayers();
      for(var lyId in lyrs) {
        layerSymbology = lyrs[lyId].symbology;
        break;
      }

      if(layerSymbology) {
        params['symbology_subject'] = layerSymbology.subject;
        params['color_scheme'] = layerSymbology.color_scheme;
      }

      $.ajax({ 
        url: symUrl,
        method: 'POST',
        data: params
      });
    };

    var resetViewSymbology = function(subject) {
      var layers = getLayers();
      for(var lyId in layers) {
        updateLayerSymbology(layers[lyId], getDefaultSymbologyBySubject(subject));
      }

      renderSymbologyPanel();
    };

    var updateViewSymbology = function(settings) {
      settings = settings || {};

      var sym = getSymbologyBySubject(settings.subject);
      if(sym) {
        sym.symbology_type = settings.symbology_type;
        sym.color_scheme = settings.color_scheme;

        var layers = getLayers();
        for(var lyId in layers) {
          updateLayerSymbology(layers[lyId], sym);
        }
      }
    };


    //extentWKT: an envelope in WKT format
    //[(MINX, MINY), (MAXX, MINY), (MAXX, MAXY), (MINX, MAXY), (MINX, MINY)].
    var zoomToExtent = function(extentWKT) {
      if(!extentWKT) {
        return;
      }
      try {
        var obj = new Wkt.Wkt().read(extentWKT);
        var southWest = L.latLng(obj[0][0].y, obj[0][0].x),
          northEast = L.latLng(obj[0][2].y, obj[0][2].x),
          bounds = L.latLngBounds(southWest, northEast);
        map.LMmap.fitBounds(bounds);
      }
      catch (ex) {
        console.log(ex);
      }
    }; 

    var render = function() {
      if(whetherZoomToAreaExtent && zoomExtentWKT) {
        zoomToExtent(zoomExtentWKT);
      }
      layerConfig.referenceColumn = areaColumn;
      layerConfig.symbology = symbology;
      // check if to display county data
      layerConfig.data = data;
      if(layerName) {
        layerConfig.name = layerName;
      }
      

      // check if to display wkt data
      if(dataConfig.addRTPWkt) {
        _overlay.layer = map.addRTPWkt(
          dataConfig.name,
          data, 
          symbology,
          dataConfig.baseUrl || '', 
          dataConfig.zoom_to_rtp_id || null,
          _layerSnapshotParams.visibility
        );
      } else if(dataConfig.addCountFactPoint) {
        _overlay.layer = map.addCountFactPoints(
          data, 
          symbology,
          dataConfig.baseUrl || '', 
          layerName,
          (_layerSnapshotParams.visibility || {})[layerName],
          dataConfig.request_data,
          dataConfig.hub_bound_file_path
        );
      } else {
        map.addOverlayLayer(
          layerConfig, 
          layerCallbackFn
        );
      }
      
    };

    var getLayers = function() {
      var layers = _overlay.layer;
      if(!(layers instanceof Array)) {
        layers = [layers];
      }

      var outputLayers = {};
      layers.forEach(function(lyr){
        if(lyr) {
          outputLayers[lyr.layerId] = lyr;
        }
      });
      return outputLayers;
    };

    var setViewAreaBoundaryVisibility = function(isVisible) {
      return _overlay.showAreaBoundary = isVisible;
    };

    var exportParameters = function() {
      var symbologyParams = {};
      var visibilityParams = {};
      var layers = getLayers();
      for(var layerId in layers) {
        var lyr = layers[layerId];
        if(lyr) {

          symbologyParams[lyr.name] = {
            subject: (lyr.symbology ? lyr.symbology.subject : ''),
            columnIndex: lyr.displayColumnIndex,
            symbology_type: (lyr.symbology ? lyr.symbology.symbology_type : null),
            color_scheme: (lyr.symbology ? lyr.symbology.color_scheme : null)
          };
          visibilityParams[lyr.name] = (lyr._map ? true: false);
        }
      }

      return {
        symbology: symbologyParams,
        visibility: visibilityParams,
        include_year_slider: dataConfig.include_year_slider || false,
        showAreaBoundary: _overlay.showAreaBoundary
      };

    };

    var searchMap = function(keyword) {
      keyword = (keyword || '').toLowerCase();

      if(dataConfig.addRTPWkt) {
        var isFound = false;
        if(keyword != '') {
          var layers = this.getLayers();
          for(var tmpLayerId in layers) {
            var layer = layers[tmpLayerId];
            var features = layer.getLayers();
            for(var i=0, featCount=features.length; i<featCount; i++) {
              var feat = features[i];
              var featProp = feat.properties;
              if(featProp) {
                var featId = featProp.hasOwnProperty('rtp_id') ? featProp['rtp_id'] : featProp['tip_id'];
                if((featId || "").toLowerCase().indexOf(keyword) >= 0 || (featProp['description'] || "").toLowerCase().indexOf(keyword) >= 0) {                  
                  map.zoomToWKT(featProp['geography']);
                  feat.openPopup();
                  isFound = true;
                  break;
                }
              }
            }
          }
        }

        if(!isFound) {
          map.closePopup();
        }
      } else {
        if(layerConfig.type === 'Geojson') {
          // TODO: geojson layer search
          console.log('geojson layer search to be implemented');
        } else if(layerConfig.type === 'PBF_TILE') {
          // PBF vector tile
          var tileLayerName = layerConfig.tileName;
          var searchColumnName = layerConfig.geomReferenceColumn;
          var layers = this.getLayers();
          for(var tmpLayerId in layers) {
            var layer = layers[tmpLayerId];
            if(layer._selectedFeature) {
              layer._selectedFeature.deselect();
            }
            if(keyword != '') {
              var tileLayer = layer.layers[tileLayerName];
              if(tileLayer) {
                for(var featId in tileLayer.features) {
                  var feat = tileLayer.features[featId];
                  var featKey = feat.properties[searchColumnName].toString().toLowerCase();
                  if(featKey == keyword) {
                    feat.select();
                    $('#zoomToFeature').click();
                    break;
                  }
                }
              }
            }
          }
        }
      }
    };
    
    //public accessible
    return {
      include_year_slider: dataConfig.include_year_slider || false,

      render: render,
      switchDisplayColumn: switchDisplayColumn,
      switchLayerSymbology: switchLayerSymbology,
      resetViewSymbology: resetViewSymbology,
      addSymbology: addSymbology,
      deleteSymbology: deleteSymbology,
      resetSymbologyList: resetSymbologyList,
      renderSymbologyPanel: renderSymbologyPanel,
      updateViewSymbology: updateViewSymbology,
      setViewAreaBoundaryVisibility: setViewAreaBoundaryVisibility,
      removeFromMap: removeFromMap,
      getLayers: getLayers,
      searchMap: searchMap,
      exportParameters: exportParameters
    };
};
