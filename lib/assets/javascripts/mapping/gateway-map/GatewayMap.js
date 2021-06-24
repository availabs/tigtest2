/**
 * Define Map Class 
 * Library dependency
 *  Leaflet.js: mapping
 *  jQuery: utilities
 *  Chroma.js: color manipulation
 *  GatewayMapUtil.js: Gateway mapping utilities
 */

var CsLeaflet = CsLeaflet || {};

CsLeaflet.Leaflet = CsLeaflet.Leaflet || function(){};

CsLeaflet.Leaflet.prototype.exportParameters = function() {
  var params = {};

  var mapLayers = this.LMmap._layers;

  // find out the active basemap name
  if(this.layerControl) {
    var layersInLayerControl = this.layerControl._layers;
    for(var layerId in layersInLayerControl) {
      var tmpLayer = layersInLayerControl[layerId];
      if(!tmpLayer.overlay && mapLayers[layerId])  {// not an overlay, and this layer is rendered in map
        params["basemap"] = tmpLayer.name;
        break;
      }
    }
  }

  // zoom extent
  params["zoom"] = this.LMmap.getZoom();

  // center lat/lng
  var centerPt = this.LMmap.getCenter();
  params["lat"] = centerPt.lat;
  params["lng"] = centerPt.lng;

  // bounds
  var bounds = this.LMmap.getBounds();
  params["bounds"] = {
    ymin: bounds.getWest(),
    ymax: bounds.getEast(),
    xmin: bounds.getSouth(),
    xmax: bounds.getNorth()
  };

  // base_overlay visibility
  visible_baseoverlays = [];
  if(this.baseOverlayIds && this.baseOverlayIds.length > 0) {
    this.baseOverlayIds.forEach(function(id){
      if(mapLayers[id]) {
        visible_baseoverlays.push(mapLayers[id].name);
      }
    });
  }
  params["visible_baseoverlays"] = visible_baseoverlays;

  return params;

};

CsLeaflet.Leaflet.prototype.setZoomExtent = function(lat, lon, zoom) {
  this.LMmap.setView([lat, lon], zoom);
}

// dependency: Wkt parser
CsLeaflet.Leaflet.prototype.zoomToWKT = function(wktGeom) {
  var wkt = new Wkt.Wkt();
  var obj;
  wkt.read(wktGeom);
  obj = wkt.toObject();
  if (typeof obj.getBounds === "function"){
    this.LMmap.fitBounds(obj.getBounds());
  } else{
    this.LMmap.setZoom(15);
    this.LMmap.panTo(obj.getLatLng());
  };
}


CsLeaflet.Leaflet.prototype.addSidebar = function(sidebarId) {
  if(L.control.sidebar) {
    this.sidebarControl = L.control.sidebar(sidebarId).addTo(this.LMmap);
  }
}

CsLeaflet.Leaflet.prototype.addNavbar = function(options) {
  if(L.control.navbar) {
    options = options || {};
    this.navbarControl = L.control.navbar(options).addTo(this.LMmap);
  }
}

CsLeaflet.Leaflet.prototype.addFullscreenControl = function(fullScreenEl) {
  if(L.control.fullscreen) {
    this.fullscreenControl = L.control.fullscreen({
      title: 'Show map in fullscreen',
      fullScreenEl: fullScreenEl
    }).addTo(this.LMmap);
  }
}

CsLeaflet.Leaflet.prototype.addZoomSliderControl = function() {
  if(L.control.zoomslider) {
    //remove default zoomControl
    $('.leaflet-control-zoom').remove();
    this.zoomSliderControl = L.control.zoomslider().addTo(this.LMmap);
  }
}

CsLeaflet.Leaflet.prototype.addStudyAreaControl = function() {
  if(L.Control.Draw) {

    L.drawLocal.draw.toolbar.buttons.polygon = 'Define study area';
    
    var map = this.LMmap;

    var studyAreaEditingLayer = new L.FeatureGroup();
    map.addLayer(studyAreaEditingLayer);

    var studyAreaControl = new L.Control.Draw({
      draw: {
        polyline: false, 
        marker: false, 
        circle: false, 
        rectangle: false
      },
      edit: false,
      remove: false
    });

    map.addControl(studyAreaControl);

    this.studyAreaEditingLayer = studyAreaEditingLayer;
    this.studyAreaControl = studyAreaControl; 
  }
}

CsLeaflet.Leaflet.prototype.addLayerControl = function() {
  //add an empty layer switcher
  this.layerControl = L.control.layers().addTo(this.LMmap);
  // below is to avoid bottom-right panel on top of top-right panel
  // bottom-right is where legend is
  // *deprecated*, we moved legend to sidebar container
  //$('.leaflet-top.leaflet-right').css('z-index', 1001); 
}


CsLeaflet.Leaflet.prototype.getLayerControl = function() {
  if(!this.layerControl) {
    this.addLayerControl();
  }
  
  return this.layerControl;
}

CsLeaflet.Leaflet.prototype.getLegends = function() {
  if(!this.legends) {
    this.legends = {};
  }

  return this.legends;
}

CsLeaflet.Leaflet.prototype.getLabels = function() {
  if(!this.labels) {
    this.labels = {};
  }

  return this.labels;
}

CsLeaflet.Leaflet.prototype.registerAddOverlayEvent = function() {
  var _this = this;
  var _map = _this.LMmap;

  var labels = _this.getLabels();
  //show or hide labels&legends associated with an overlay layer
  _map.on('overlayadd', function(layer) {
    var layerId = layer.layer.layerId;
    var layerLegendId = '#layer-legend-' + layerId;
    if($(layerLegendId).length > 0) {
      $(layerLegendId).show();
    }
    if(_this.baseOverlayIds && _this.baseOverlayIds.indexOf(layerId) >=0) {
      layer.layer.bringToBack();
    }
    var layerName = layer.name;
    var layerLabels = labels[layerName];
    if(layerLabels instanceof Array) {
      for(var i=0, labelCount=layerLabels.length; i<labelCount; i++) {
        _map.showLabel(layerLabels[i]);
      }
    }
  });
}

CsLeaflet.Leaflet.prototype.registerRemoveOverlayEvent = function() {
  var _map = this.LMmap;

  var labels = this.getLabels();
  //hide labels&legends associated with an overlay layer
  _map.on('overlayremove', function(layer) {
    var layerId = layer.layer.layerId;
    var layerLegendId = '#layer-legend-' + layerId;
    if($(layerLegendId).length > 0) {
      $(layerLegendId).hide();
    }

    var layerName = layer.name;
    var layerLabels = labels[layerName];
    if(layerLabels instanceof Array) {
      for(var i=0, labelCount=layerLabels.length; i<labelCount; i++) {
        layerLabels[i].close();
      }
    }
  });
}

//zoom to map extent
CsLeaflet.Leaflet.prototype.zoomToExtent = function(lat, lon, zoomLevel) {
  this.LMmap.setView([lat, lon], zoomLevel);
};

//add attribution to 'attribution' container
CsLeaflet.Leaflet.prototype.addAttribution = function(attrText, layerId) {
  if(attrText) {
    var idTag = '';
    if(layerId || layerId === 0) {
      idTag ="id='attribution-" + layerId + "'";
    }
    $('#attribution').append('<p ' + idTag + '>' + attrText + '</p>');
  }
};

CsLeaflet.Leaflet.prototype.deleteLayerAttribution = function(layerId) {
  if(layerId || layerId === 0) {
    $('#attribution-' + layerId).remove();
  }
};

//load basemap
//basemaps input param should be an array
//each basemap input format: {type: 'XXX', name: 'XXX', attribution: 'XXX'}
//NOTE: basemap tiles only start loading after a map extent is set.
CsLeaflet.Leaflet.prototype.addBasemaps = function(basemaps, defaultMapName) {
  if(!(basemaps instanceof Array)) {
    return;
  }
  
  var _this = this;
  var _map = _this.LMmap;
  var _layerControl = _this.getLayerControl();
  
  //internal function to load basemap
  var _loadBasemap = function(basemapObj) {
    var _baseLayer = null;
    switch(basemapObj.type) {
      case 'OpenStreetMap':
        _baseLayer = new L.TileLayer(
          'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
        );
        
        break;
      case 'CloudMade':
        _baseLayer = new L.TileLayer(
          'http://{s}.tile.cloudmade.com/' + basemapObj.key + '/{styleId}/' + basemapObj.resolution + '/{z}/{x}/{y}.png', 
          {
            styleId: basemapObj.styleId
          }
        );
        
        break;
      case 'Google':
        _baseLayer = new L.Google(basemapObj.layerName);
        
        break;

      case 'Esri':
        _baseLayer = new L.esri.BasemapLayer(basemapObj.layerName);
        
        break;
      default:
        break;
    }

    _this.addAttribution(basemapObj.attribution);
        
    return _baseLayer;
  };
  
  //loop basemaps
  var isDefaultLayerLoaded = false;
  for(var i=0, count=basemaps.length; i<count; i++) {
    var basemapObj = basemaps[i];
    if(!basemapObj.hasOwnProperty('type')) {
      continue;
    }

    var basemapName = basemapObj.name;
    if(!defaultMapName) {
      defaultMapName = basemapName;
    }
    
    //load each basemap
    var baseLayer = _loadBasemap(basemapObj);
    
    if(baseLayer) {
      if(!isDefaultLayerLoaded && basemapName === defaultMapName) {
        _map.addLayer(baseLayer);
        isDefaultLayerLoaded = true;
      }
      _layerControl.addBaseLayer(baseLayer, basemapName);
    }
  }
};

//load base overlays (means it's an overlay layer, but only for display purpose, e.g., boundary)
CsLeaflet.Leaflet.prototype.addBaseOverlay = function(layerConfig) {
  this.baseOverlayIds = this.baseOverlayIds || [];

  var _this = this;

  var _map = this.LMmap;
  _map.spin(true);

  //base overlay by default are not clickable (only for simple display)
  layerConfig.non_clickable = true;

  this.addOverlayLayer(layerConfig, function(layer){
    _map.spin(false);

    var layerId = layer.layerId;
    if(typeof(layerId) != 'number') { 
      layerId = layer._leaflet_id;
    } 
    if(_this.baseOverlayIds.indexOf(layerId) < 0) {
      _this.baseOverlayIds.push(layerId);
    }
  });
}

CsLeaflet.Leaflet.prototype.overwriteLayerStyleFromLegend = function(layerStyle, layerLegendDef, isPolygon) {
  layerStyle = layerStyle || {};
  layerLegendDef = layerLegendDef || {};

  if(layerLegendDef.field && layerLegendDef.colors) {
    if(layerLegendDef.symbology_type === 'unique_value') {
      var old_style = layerStyle;
      layerStyle = function(feature) {
        if(isPolygon) {
          old_style.fillColor = layerLegendDef.colors[feature.properties[layerLegendDef.field]];
        } else {
          old_style.color = layerLegendDef.colors[feature.properties[layerLegendDef.field]];
        }

        return old_style;
      }
    }
  }

  return layerStyle;
};

//load one overlay map layer
//each layerConfig input format: {type: 'XXX', url: 'XXX', name: 'XXX', attribution: 'XXX', style: {}}
//callbackFn: a callback function that accepts {overlay_map_layer} as params
CsLeaflet.Leaflet.prototype.addOverlayLayer = function(layerConfig, callbackFn) {
  if(!(layerConfig.hasOwnProperty('type'))) {
    return;
  }
  
  switch(layerConfig.type) {
    case 'Geojson':
      this.addGeojsonLayer(layerConfig, callbackFn);
      break;
    case 'PBF_TILE':
      this.addVectorTilePBF(layerConfig, callbackFn);
      break;
    default:
      break;
  }
};

CsLeaflet.Leaflet.prototype.addGeojsonLayer = function(layerConfig, callbackFn) {
  var _map = this.LMmap;
  var _layerControl = this.getLayerControl();
  var _layerGroup = this.overlayers;
  
  var _this = this;

  var layerName = layerConfig.name;
  var viewId = layerConfig.viewId;
  var isPolygon = layerConfig.geometry_type === 'POLYGON';

  var layerStyle = layerConfig.style;
  if(layerConfig.predefined_symbology) {
    layerStyle = _this.overwriteLayerStyleFromLegend(
      layerStyle, layerConfig.predefined_symbology, isPolygon);
  }
  var geojsonLayer = L.geoJson([], {
    style: layerStyle
  });

  if(!layerConfig.turn_off_by_default) {
    _map.addLayer(geojsonLayer);
  }

  geojsonLayer.layerId = geojsonLayer._leaflet_id || GatewayMapUtil.randString(6);

  geojsonLayer.name = layerName;
  geojsonLayer.geometryType = layerConfig.geometry_type;

  if(layerConfig.predefined_symbology) {
    _this.addSimpleLegend(
      geojsonLayer, 
      [{
        subject: layerName
      }],
      layerName, 
      layerConfig.predefined_symbology.colors,
      layerConfig.predefined_symbology.labels,
      layerConfig.turn_off_by_default
    )
  }
  
  //add to layer control
  _layerControl.addOverlay(geojsonLayer, layerName);

  if(typeof(layerConfig.attribution) === 'string') {
    _this.addAttribution(layerConfig.attribution, geojsonLayer.layerId);
  }

  var _loadLayerIntoMap = function(layerData) {
    geojsonLayer.clearLayers();
    geojsonLayer.addData(layerData);
    
    //callback to process layer
    if(typeof(callbackFn) === 'function') {
      callbackFn.apply(this, [geojsonLayer]);
    }
    _map.spin(false);
  };
  
  //ajax call to request data then load into map
  _map.spin(true);
  if(layerConfig.url) {
    if(GatewayMapUtil) {
      GatewayMapUtil.getData(layerConfig.url, _loadLayerIntoMap);
    }
  } else {
    _loadLayerIntoMap(layerConfig.data);
  }
};

CsLeaflet.Leaflet.prototype.getColumnIndex = function(columns, name) {
  var colIndex = null;
  var columns = columns || [];
  for(var i=0, colCount=columns.length; i<colCount; i++) {
    var tmpColConfig = columns[i];
    if(tmpColConfig.name === name) {
      colIndex = tmpColConfig.index;
      break;
    }
  }

  return colIndex;
};

CsLeaflet.Leaflet.prototype.getDisplayColumnConfig = function(columns, columnIndex) {
  var colConfig = null;
  var columns = columns || [];
  for(var i=0, colCount=columns.length; i<colCount; i++) {
    var tmpColConfig = columns[i];
    if(tmpColConfig.index === columnIndex) {
      colConfig = tmpColConfig;
      break;
    }
  }

  return colConfig;
};

CsLeaflet.Leaflet.prototype.getLayerDisplayColumnConfig = function(layer, defaultSymbology) {
  if(!layer.displayConfig) {
    this.setLayerDisplayColumnConfig(layer, defaultSymbology);
  }
  return layer.displayConfig;
};

CsLeaflet.Leaflet.prototype.setLayerDisplayColumnConfig = function(layer, defaultSymbology) {
  var symbology = layer.symbology || defaultSymbology || {};

  var colIndex = layer.displayColumnIndex;
  if(!colIndex && colIndex != 0) {
    colIndex = symbology.default_column_index;
  }

  layer.displayConfig = this.getDisplayColumnConfig(symbology.columns,  colIndex);
 };

//generate an array of break values
CsLeaflet.Leaflet.prototype.calculateNaturalValueBreaks = function(minValue, maxValue, breakCount) {
  var breaks = [];
  var delta = (maxValue - minValue) / (breakCount-1);
  var startValue = minValue;
  while(startValue <= maxValue) {
      breaks.push(startValue);
      startValue += delta;
  }
  
  return breaks;
};

//generate an array of break values
CsLeaflet.Leaflet.prototype.calculateEqualValueBreaks = function(minValue, maxValue, breakValue) {
  var breaks = [];
  var delta = breakValue;
  var startValue = minValue - (minValue % breakValue);
  while(startValue < maxValue) {
      breaks.push(startValue);
      startValue += breakValue;
  }
  
  if(startValue >= maxValue) {
      breaks.push(startValue);
  }
  
  return breaks;
};

// generate an array of pusdo-quantile break values
// if the count of one specific value exceeds bin count, then take this value as one bin
// values: { value: count}
CsLeaflet.Leaflet.prototype.calculateQuantileBreaks = function(values, classCount) {
  if (!values || values.totalCount == 0)
    return [];
  var binCount = Math.round(values.totalCount / classCount);
  var minValue = values.minValue;
  var breaks = [minValue];
  var valueCounts = values.valueCounts;
  var counter=valueCounts.length;
  
  var minValueCount = valueCounts[0][1];
  var isMinValueOneBin = false;
  // there are a lot of min_value, we take it as one bin
  if(minValueCount >= binCount) {
    isMinValueOneBin = true;
    breaks.push(minValue);
    binCount = Math.round((values.totalCount - minValueCount) / (classCount-1));
  }

  var baseCount = 0;
  for(var i=0; i<counter; i++) {
    var valCount = valueCounts[i];

    var value = valCount[0];
    
    //min_value is in one bin, which was handled separately in above
    if(isMinValueOneBin && value == minValue) {
      continue;
    }

    var count = valCount[1];
    baseCount += count;

    if(baseCount >= binCount) {
      breaks.push(value);
      baseCount = 0;
    }

    //last bin take all the remaining values
    if(breaks.length == classCount ) {
      break;
    }

  }

  if(breaks.indexOf(values.maxValue) < 0) {
    breaks.push(values.maxValue);
  }

  return breaks;

};

//generate an array of break values
CsLeaflet.Leaflet.prototype.calculateGeometricBreaks = function(minValue, maxValue, breakValue, multiplier) {
  var breaks = [];
  var startValue = minValue - (minValue % breakValue);
  var currentMultiple = multiplier
  while(startValue <= maxValue) {
      breaks.push(startValue);
      startValue = breakValue * currentMultiple;
      currentMultiple *= multiplier;
  }
  
  if(startValue > maxValue) {
      breaks.push(startValue);
  }
  
  return breaks;
};

CsLeaflet.Leaflet.prototype.calculateTileFeatureValueBounds = function(layer) {
  var features = layer.options.features;
  if(!features) {
      return null;
  }
  
  var symbology = layer.symbology;
  var columns = symbology.columns;

  switch(symbology.symbology_type) {
    case 'geometric_breaks':
    case 'natural_breaks':
  
      var minValue, maxValue;
      for(var key in features) {
        var dataRow = features[key];
        for(var j=0, columnCount=columns.length; j<columnCount; j++) {
          var breakColName = columns[j].name;
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
        symbology.minValue = minValue;
        symbology.maxValue = maxValue;
      }

      break;

    case 'quantile_breaks':
      
      var rawValues = [];
      for(var key in features) {
        var dataRow = features[key];
        for(var j=0, columnCount=columns.length; j<columnCount; j++) {
          var breakColName = columns[j].name;
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

CsLeaflet.Leaflet.prototype.prepareLayerSymbologyValues = function(layer, symbology) {

  var colorScheme = symbology.color_scheme;
  if(!colorScheme) {
      return;
  }
  var type = symbology.symbology_type;

  //generate breaks
  switch(type) {
    case 'quantile_breaks':

      symbology.breaks = this.calculateQuantileBreaks(symbology.values, colorScheme.class_count);

      var breaks = symbology.breaks.slice();
      if(breaks.length > 1 && breaks[0] == breaks[1]) {
        breaks[0] = breaks[1] - 1;
      }

      symbology.scale = chroma.scale([colorScheme.start_color, colorScheme.end_color])
        .domain(breaks).mode('hsv');
      symbology.colors = symbology.scale.colors();
      
      break;

    case 'geometric_breaks':
      var breakValue = colorScheme.gap_value;
      var multiplier = colorScheme.multiplier;

      if (multiplier){
        symbology.breaks = this.calculateGeometricBreaks(0, symbology.maxValue, breakValue, multiplier);
      }else{
        symbology.breaks = this.calculateEqualValueBreaks(0, symbology.maxValue, breakValue); //start from 0
      }

      symbology.scale = chroma.scale([colorScheme.start_color, colorScheme.end_color])
        .domain(symbology.breaks).mode('hsv');
      symbology.colors = symbology.scale.colors();

      break;

    case 'natural_breaks':
      symbology.breaks = this.calculateNaturalValueBreaks(0, maxValue, colorScheme.class_count); //start from 0
      symbology.scale = chroma.scale([colorScheme.start_color, colorScheme.end_color])
        .domain(symbology.breaks).mode('hsv');
      symbology.colors = symbology.scale.colors();
      
      break;

    default:
      break;
  }

};

CsLeaflet.Leaflet.prototype.addVectorTilePBF = function(layerConfig, callbackFn) {
  var _map = this.LMmap;
  var _layerControl = this.getLayerControl();
  var _layerGroup = this.overlayers;
  
  var _this = this;

  var _loadLayerIntoMap = function(layerData) {
    
    layerData = layerData || [];
    var features = {};
    var hasAttributeData = false;
    var refColumn = layerConfig.referenceColumn;

    $.grep(layerData, function(item) {
      if(!hasAttributeData) {
        hasAttributeData = true;
      }
      features[item[refColumn]] = item;
    });

    var layerName = layerConfig.name;
    var viewId = layerConfig.viewId;
    var tileRefColumn = layerConfig.geomReferenceColumn;
    var defSymbology = layerConfig.symbology || {};

    var clickableLayers = [];
    if(!layerConfig.non_clickable) {
      clickableLayers.push(layerConfig.tileName);
    }
    
    var layer = new L.TileLayer.MVTSource({
      features: features,
      url: layerConfig.url,
      clickableLayers: clickableLayers,
      mutexToggle: true,
      onSelect: function(feature) {
        //show feature info
        if(feature && hasAttributeData) {
          var symbology = layer.symbology || defSymbology;
          var displayConfig = _this.getLayerDisplayColumnConfig(layer, defSymbology);
          var showVal = 'n/a';
          var featVal = "";
          var displayTitle = "";
          var featProp = features[feature.properties[tileRefColumn]];

          if(displayConfig) {
              displayTitle = displayConfig.title;
              featVal = featProp[displayConfig.name];
          }
          if (featVal == 0 || featVal) {
            showVal = GatewayMapUtil.formatNumber(featVal, symbology.number_formatter); //{format:"#,##0", locale:"us"}
          }

          _map.fireEvent('updateDisplayInfo', {
            info: {
              layerName: layerName,
              viewId: viewId,
              title: displayTitle,
              attributes: featProp,
              key: featProp[refColumn],
              type: featProp["area_type"],
              column: displayConfig.name,
              value: showVal,
              showDemoStats: layerConfig.is_demo,
              showTMCStats: layerConfig.is_tmc,
              showLinkStats: layerConfig.is_link
            }
          });
        }

        layer.fireEvent('featureSelected', {feature: feature});
      },
      onDeselect: function(feature) {
        _map.fireEvent('updateDisplayInfo');
      },
      onClick: function(evt) {
        if(!evt.feature && layer._selectedFeature) { //if no feature clicked, then cancel existing selection
          layer._selectedFeature.deselect();
        }
      },
      getIDForLayerFeature: function(feature) {
        return feature.properties[tileRefColumn];
      },

      filter: function(feature, context) {
        var visible = true;
        if(hasAttributeData) {
          var featProp = features[feature.properties[tileRefColumn]];
          
          visible =  featProp || false;
        }
        if(!layerConfig.showLabel && feature.layer.name.indexOf('_LabelPoint') > -1) {
          visible = false;
        }
        return visible;
      },

      layerLink: function(layerName) {
        if (layerName.indexOf('_LabelPoint') > -1) {
          returnedLayerName = layerName.replace('_LabelPoint','');
        } else {
          returnedLayerName = layerName + '_LabelPoint';
        }
        return returnedLayerName;
      },

      style: function(feature) {
        if(!layer.hasOwnProperty('showAreaBoundary')) {
          layer.showAreaBoundary = layerConfig.showAreaBoundary; 
        }
        var style = GatewayMapUtil.cloneObject(layerConfig.style) || {};
        if(layerConfig.highlightStyle) {
          style.selected = GatewayMapUtil.cloneObject(layerConfig.highlightStyle);
        }
        var layerLegendDef = layerConfig.predefined_symbology;
        if(layerLegendDef) { //for base_overlays: base_overlay doesnt have attribute data associated but usually has a legend pre-configured
          if(layerLegendDef.field && layerLegendDef.colors) {
            if(layerLegendDef.symbology_type === 'unique_value') {
              style.color = layerLegendDef.colors[feature.properties[layerLegendDef.field]];
            }
          }
        } else if (!layerConfig.non_clickable) { // if non_clickable, then no need to care about attribute data
          var displayConfig = _this.getLayerDisplayColumnConfig(layer, defSymbology);
          var featVal = null;
          var featProp = null;
          if(hasAttributeData) {
            featProp = features[feature.properties[tileRefColumn]];
          }

          if(featProp && displayConfig) {
            featVal = featProp[displayConfig.name];
          }

          // hide invalid values
          if(!(featVal || featVal == 0)) {
            return {
              color: 'transparent',
              fillColor: 'transparent',
              size: 0,
              radius: 0,
              outline: {
                color: 'transparent',
                size: 0
              }
            };
          }

          var symbology = layer.symbology || defSymbology;
          if(!layer.displayColumnIndex && layer.displayColumnIndex != 0) {
            _this.calculateTileFeatureValueBounds(layer);
            _this.prepareLayerSymbologyValues(layer, symbology);
            layer.displayColumnIndex = symbology.default_column_index;
          }

          var column = _this.getDisplayColumnConfig(symbology.columns, layer.displayColumnIndex || symbology.default_column_index);
          if(!column) {
            return {};
          }
          var color = _this.findColor(layer, symbology, featProp[column.name], 0.5);
          if(!color) {
            return {};
          }

          style.color = color;
        }

        if(feature.type === 3) {
          if(layer.showAreaBoundary) {
            style.outline = {
              color: "rgb(119,119,119)",
              size: 0.8
            };
          } else {
            style.outline = {
              color: "transparent",
              size: 0.1
            };
          }

          style.selected = {
            color: color,
            outline: {
              color: "rgb(0,0,0)",
              size: 1.5
            }
          };
        }

        if(layerConfig.showLabel && layerConfig.labelColumnName && feature.layer.name.indexOf('_LabelPoint') > -1) {
          style.staticLabel = function() { 
            style.radius = 0;
            var labelStyle = {
              html: feature.properties[layerConfig.labelColumnName],
              iconSize: [125,30]
            };
            return labelStyle;
          };
        }

        return style;
      }

    });
  
    if(!layerConfig.turn_off_by_default) {
      _map.addLayer(layer);
    }
    layer.layerId = layer._leaflet_id || GatewayMapUtil.randString(6);
    layer.name = layerName;
    layer.geometryType = layerConfig.geometry_type;

    if(layerConfig.predefined_symbology) {
      var predefined_symbology = layerConfig.predefined_symbology;
      _this.addSimpleLegend(
        layer, 
        [{
          subject: layerName
        }],
        layerName, 
        predefined_symbology.colors,
        predefined_symbology.labels,
        layerConfig.turn_off_by_default
      );
    } else {
      layer.symbology = defSymbology;
      if(!layer.displayColumnIndex && layer.displayColumnIndex != 0) {
        _this.calculateTileFeatureValueBounds(layer);
        _this.prepareLayerSymbologyValues(layer, defSymbology);
        layer.displayColumnIndex = defSymbology.default_column_index;
      }
    }
    
    //add to layer control
    _layerControl.addOverlay(layer, layerName);

    if(typeof(layerConfig.attribution) === 'string') {
      _this.addAttribution(layerConfig.attribution, layer.layerId);
    }

    if(typeof(callbackFn) === 'function') {
      callbackFn.apply(this, [layer]);
    }

    _map.spin(false);
  };
  
  //ajax call to request data then load into map
  _map.spin(true);
  _loadLayerIntoMap(layerConfig.data);
};

//add label for overlay layer
CsLeaflet.Leaflet.prototype.showLabel = function(layer, labelColumnName, options) {
  if(!layer || typeof(labelColumnName) != 'string' || !labelColumnName) {
    return;
  }
  
  var _map = this.LMmap;
  if(!_map) {
    return;
  } 
  
  var labels = [];
  var features = layer.getLayers();
  for(var i=0, featCount=features.length; i<featCount; i++) {
    var feat = features[i];
    var label = new L.Label(options)
    label.setContent(feat.feature.properties[labelColumnName])
    label.setLatLng(feat.getBounds().getCenter())
    _map.showLabel(label);
    labels.push(label);
  }
  
  this.getLabels()[layer.name] = labels;
};

//update layer display property configs
CsLeaflet.Leaflet.prototype.updateLayerDisplayProperties = function(layer, propertyName, value) {
  if(!layer || typeof(propertyName) !== 'string') {
    return;
  }
  
  layer[propertyName] = value;
};

//register mouse events for county layer
//layerConfig: {highlighStyle: {}, titlePropertyName: 'XXX', labelPropertyName: 'XXX', valuePropertyName: 'XXX'}
CsLeaflet.Leaflet.prototype.registerEventsForLayer = function(layer, layerConfig) {
  var _map = this.LMmap;
  var _info = _map.displayInfo;
  
  var gatewayMap = this; 
  //highlight and update display highlighted feature info
  var highlightStyle = layerConfig.highlightStyle;
  var displayInfoConfig = layerConfig.displayInfoConfig;
  function highlightFeature(feat) {
    if(!feat) {
      return;
    }

    var numberFormatOptions = layer.symbology.number_formatter; 

    if(highlightStyle)
      feat.setStyle(highlightStyle);

    if (!L.Browser.ie && !L.Browser.opera) {
      feat.bringToFront();
    }

    var feature = feat.feature;
    if(typeof(feature) === 'object' && 
      feature.hasOwnProperty('properties')) {
      var showVal = 'n/a';
      if (feat.displayValue == 0 || feat.displayValue) {
        showVal = GatewayMapUtil.formatNumber(feat.displayValue, numberFormatOptions); //{format:"#,##0", locale:"us"}
        var displayConfig = gatewayMap.getLayerDisplayColumnConfig(layer);
        _map.fireEvent('updateDisplayInfo',{
          info: {
            layerName: layer.name,
            title: layer["displayTitle"],
            attributes: feature.properties,
            key: feature.properties[layer["displayLabelPropertyName"]],
            type: featProp.properties["area_type"],
            column: displayConfig.name,
            value: showVal
          }
        });
      }
    }
  }

  //reset highlight and display info
  function resetHighlight(highlightFeat) {
    if(!highlightFeat) {
      return;
    }
    //need to use prevStyle to explicitly store previous style (after thematic rendering)
    //otherwise, will display original non-thematic color
    if(highlightFeat.hasOwnProperty('prevStyle')) {
      highlightFeat.setStyle(highlightFeat.prevStyle);
    } else {
      layer.resetStyle(highlightFeat);
    }
    _map.fireEvent('updateDisplayInfo', {});
  }
  

  //zoom to feature
  function zoomToFeature(feature) {
    if(feature)
      _map.fitBounds(feature.getBounds());
  }

  var _currentHighlightFeat = null;
  var onFeatureClick = function(e) {
    //reset previous highlight
    resetHighlight(_currentHighlightFeat);

    //update current highlight
    _currentHighlightFeat = e.target;
    highlightFeature(_currentHighlightFeat);
    zoomToFeature(_currentHighlightFeat);
  }
  //this is to reset highlights after clicking at map (i.e., not clicking at a feature)
  _map.on('click', function(e){
    resetHighlight(_currentHighlightFeat);
  });

  var onFeatureMouseover = function(e) {
    highlightFeature(e.target);
  };

  var onFeatureMouseout = function(e) {
    resetHighlight(e.target);
  };
  //register on each feature basis
  function onEachFeature(feature) {
    feature.on({
      click: onFeatureClick,
      mouseover: onFeatureMouseover,
      mouseout: onFeatureMouseout
    });
  }
  
  var features = layer.getLayers();
  for(var i=0, featCount=features.length; i<featCount; i++) {
    onEachFeature(features[i]);
  }
};

CsLeaflet.Leaflet.prototype.setAreaColumnNameForLayer = function(layer, areaColumnName) {
  if(!layer || typeof(areaColumnName) != 'string') {
    return;
  }
  
  layer.areaColumnName = areaColumnName;
};

CsLeaflet.Leaflet.prototype.setExternalDataForLayer = function(layer, data) {
  if(!layer) {
    return;
  }
  
  layer.externalData = data;
};

CsLeaflet.Leaflet.prototype.setDisplayColumnIndexForLayer = function(layer, columnIndex) {
  if(!layer) {
    return;
  }
  
  layer.displayColumnIndex = columnIndex;

  // update display column configuration
  this.setLayerDisplayColumnConfig(layer);
};

CsLeaflet.Leaflet.prototype.setValueLocaterForLayer = function(layer, valueLocatorFn) {
  if(!layer || typeof(valueLocatorFn) !== 'function') {
    return;
  }
  
  layer.valueLocatorFn = valueLocatorFn;
};

//get color based on value
CsLeaflet.Leaflet.prototype.findColor = function(layer, symbology, value, opacity) {
  var layerSymbology = layer.symbology || symbology; 
  var colorScheme = layerSymbology.color_scheme;
  var color = null;
  switch(layerSymbology.symbology_type) {
    case 'quantile_breaks':
      if(value == symbology.breaks[0]) {
        color = chroma.color(symbology.colors[0]).alpha(opacity).css();
      } else {
        color = symbology.scale(value).alpha(opacity).css();
      }
      break;
    case 'geometric_breaks':
    case 'natural_breaks':

      color = symbology.scale(value).alpha(opacity).css();

      break;

    case 'custom_breaks':
      var colorSchemes = colorScheme;
      for(var i=0, colorCount=colorSchemes.length; i<colorCount; i++) {
        var colorObj = colorSchemes[i];
        var minV = colorObj.min_value;
        var maxV = colorObj.max_value;
        if(
          ((!minV && minV !=0) || value >= minV) && 
          ((!maxV && maxV !=0) || value < maxV)
          ) {
          color = colorObj.color;
          break;
        }
      }

      break;

    case 'unique_value':
      var colorSchemes = colorScheme;
      for(var i=0, colorCount=colorSchemes.length; i<colorCount; i++) {
        var colorObj = colorSchemes[i];
        
        if( colorObj.value == value ) {
          color = colorObj.color;
          break;
        }
      }

      break;

    default:
      break;
  }

  return color;
};

//render each feature by using thematic color
CsLeaflet.Leaflet.prototype.renderThematicColor = function(layer, symbology) {
  if(!GatewayMapUtil || !layer || typeof(layer.getLayers) !== 'function') {
    return;
  }
  
  var defaultStyle = layer.options.style;
  if(!defaultStyle) {
    defaultStyle = {};
  }

  //function to find the value for each feature, then based on the value to assign color
  var valueLocatorFn = layer.valueLocatorFn;
  if(typeof(valueLocatorFn) !== 'function') {
    return;
  }
  
  var isPolygon = (layer.geometryType === 'POLYGON');
  var areaColumnName = layer.areaColumnName;
  var features = layer.getLayers();
  for(var i=0, featCount=features.length; i<featCount; i++) {
    var newStyle = GatewayMapUtil.cloneObject(defaultStyle);
    var feat = features[i];
    var featProp = feat.feature.properties;
    var featAreaValue = featProp[areaColumnName];
    var displayValue = valueLocatorFn(featProp, layer.displayColumnIndex);
    color = this.findColor(layer, symbology, displayValue, 0.5);
    if (isPolygon) {
      newStyle.fillColor = color;
      if (color != null){
        newStyle.fillOpacity = 0.4;
      } else{
        newStyle.opacity = 0.2;
      }
    } else {
      newStyle.color = color;
      if (color === null){
        newStyle.opacity = 0.2;
      }
    }
    
    feat.setStyle(newStyle);
    feat.displayValue = displayValue; //used in display_info
    feat.prevStyle = newStyle; //used to get back previous style when hover in/out
  }
};

CsLeaflet.Leaflet.prototype.deleteLayerLegendContainer = function(layerId) {
  var layerLegendId = 'layer-legend-' + layerId;
  $('#legend #' + layerLegendId).remove();
};

CsLeaflet.Leaflet.prototype.addLayerLegendContainer = function(layer, symbologyList, currentSymbologySubject, isHidden) {
  var layerLegendId = 'layer-legend-' + layer.layerId;

  if($('#legend #' + layerLegendId).length === 0) {
    var hiddenStyle = '';
    if(isHidden) {
      hiddenStyle = 'style="display: none;"';
    }
    var geomType = (layer.geometryType || '').toLowerCase();

    var legendClass = 'info legend ' + geomType;
    var div = "<div id='" + layerLegendId + "' data-layer-id='" + layer.layerId + "' class='" + legendClass + "' " +  hiddenStyle + ">"+
    "<h4><b>" + layer.name + "</b></h4>" +
    "<div class='legend-title'></div>" +
    "<div class='legend-body'></div>" +
    "</div>";
    $('#legend').append(div);

    $('#' + layerLegendId + ' .legend-title').append("<h5><b>" + currentSymbologySubject + "</b></h5>");
  }
};

//add legend
CsLeaflet.Leaflet.prototype.addColorGradientLegend = function(layer, symbologyList, visibility) {
  this.addLayerLegendContainer(layer, symbologyList, layer.symbology.subject, visibility);

  var symbology = layer.symbology;
  var numberFormatOptions = symbology.number_formatter;
  var div = "";
  var labels = [];

  var symbologyType = symbology.symbology_type;

  switch(symbologyType) {
    case 'quantile_breaks':
      var colors = (symbology.colors || []).slice();
      var breaks = (symbology.breaks || []).slice();
      if(breaks.length > 1 && breaks[0] == breaks[1]) {
        labels.push(
          '<h5><i style="background:' + colors[0] + '"></i> ' +
          GatewayMapUtil.formatNumber(breaks[0], numberFormatOptions) + '</h5>');
        breaks.shift();
        colors.shift();
      }
     
      for (var i = 0; i < breaks.length - 1; i++) {
        var from = breaks[i];
        var to = breaks[i + 1];

        labels.push(
          '<h5><i style="background:' + colors[i] + '"></i> ' +
          GatewayMapUtil.formatNumber(from, numberFormatOptions) +
          ' &ndash; ' + GatewayMapUtil.formatNumber(to, numberFormatOptions) + '</h5>');
      }

      break;

    case 'geometric_breaks':
    case 'natural_breaks':
      var colors = symbology.colors || [];
      var breaks = symbology.breaks || [];

      if(colors.length != (breaks.length - 1)) {
        return;
      }
      for (var i = 0; i < breaks.length - 1; i++) {
        var from = breaks[i];
        var to = breaks[i + 1];

        labels.push(
          '<h5><i style="background:' + colors[i] + '"></i> ' +
          GatewayMapUtil.formatNumber(from, numberFormatOptions) +
          '&ndash;' + GatewayMapUtil.formatNumber(to, numberFormatOptions) + '</h5>');
      }

      break;
    case 'unique_value':
    case 'custom_breaks':
      var colorSchemes = symbology.color_scheme;
      for (var i = 0, colorCount=colorSchemes.length; i < colorCount; i++) {
        var colorObj = colorSchemes[i];
        labels.push(
          '<h5><i style="background:' + colorObj.color + '"></i> ' +
          colorObj.label + '</h5>');
      }

      break;

    default:
      break;
  }
   

  div += labels.join('');

  var legendId = 'layer-legend-' + layer.layerId;
  $('#legend #' + legendId + ' .legend-body').empty();
  $('#legend #' + legendId + ' .legend-body').append(div);
  $('#' + legendId + ' .legend-title').empty();
  $('#' + legendId + ' .legend-title').append("<h5><b>" + symbology.subject + "</b></h5>");
};

CsLeaflet.Leaflet.prototype.addSimpleLegend = function(layer, symbologyList, legendTitle, colorMap, labelMap, isHidden, isHollow, iconList) {
  this.addLayerLegendContainer(layer, symbologyList, legendTitle, isHidden);

  var div = "";
  var labels = [];
  for (var label in colorMap){
    var labelText = label;
    if(labelMap) {
      labelText = labelMap[label];
    }
    var style = '';
    if(isHollow) {
      style = 'style="background:transparent; border: 2px solid ' + colorMap[label] + '"';
    } else {
      style = 'style="background:' + colorMap[label] + '"';
    }

    var icon = null
      if(iconList){
          icon = iconList[label];
      }

    labels.push(
        '<h5><i ' + style + '></i> ' +
        (icon ? '<div class="' + icon.options.className + ' image-legend"></div>' : '') +
        labelText + '</h5>'
    );
  }

  div += labels.join('') + '</div>';

  var legendId = 'layer-legend-' + layer.layerId;
  $('#legend #' + legendId + ' .legend-body').empty();
  $('#legend #' + legendId + ' .legend-body').append(div);

};

//function to add RTP wkt layer to map
CsLeaflet.Leaflet.prototype.addRTPWkt = function(layerName, data, symbology, baseUrl, zoom_to_project_id, visibility){
  var iconKey = symbology.default_column_index;
  var map = this.LMmap;
  data = data || [];
  var wkt = new Wkt.Wkt();
  var obj;

  var colors = {};
  var colorLabels = {};
  symbology.color_scheme.forEach(function(colorObj) {
    colors[colorObj.value] = colorObj.color;
    colorLabels[colorObj.label] = colorObj.color;
  });

  var divIcons ={};

  for (var label in colors){
    divIcons[label] = L.divIcon({
    className: label.replace(/\s+/g, '-') + '-div-image',
        iconSize: null
    });
  }
  divIcons['fallback'] = L.divIcon({
    className: 'project-div-icon',
    iconSize: null
  });
  
  var projectLayer = L.layerGroup();
  var zoomFeatures = [];

  data.forEach(function(row){
    if (row.geography == 'MULTILINESTRING EMPTY') return;
    if (row.geography == '') {
      console.log("WARNING: empty geography.");
      console.log(row);
      return;
    }
    var divIcon = divIcons[row[iconKey]];

    if (divIcon == null)
      divIcon = divIcons['fallback'];

    wkt.read(row.geography);

    obj = wkt.toObject({
        riseOnHover: true,
        icon: divIcon,
        weight: 4,
        color: colors[row[iconKey]],
        lineCap: 'butt'
    });

    obj.properties = row;
    var insertItem = function(label, value) {
      return '<tr><td style="text-align: right;"><b>' + label + '</b> </td>' + '<td style="text-align:left; padding-left: 10px;">' + value + '</span></td></tr>'; 
    };

    var getTableLink = function(tableUrl) {
      return "<a target='_blank' href=" + tableUrl + ">View in Table</a>";
    };

    var base_tpl = "";

    if(row.rtp_id){
      var tableUrl = baseUrl +'?search=' + row.rtp_id;
      var cost = row.estimated_cost;
      if(cost) {
        cost = '$' + cost + 'M';
      }
      base_tpl = getTableLink(tableUrl) + 
      '<table>'+
      insertItem('Project ID:', row.rtp_id) + 
      insertItem('Year:', row.year) + 
      insertItem('Plan Portion:', row.plan_portion) + 
      insertItem('Sponsor:', row.sponsor) +
      insertItem('Project Type:', row.ptype) +
      insertItem('Cost:', cost) +
      insertItem('Description:', row.description) +
      '</table>';
      
    }else if(row.tip_id){
      var tableUrl = baseUrl +'?search=' + row.tip_id;
      var cost = row.cost;
      if(cost) {
        cost = '$' + cost + 'M';
      }
      base_tpl = getTableLink(tableUrl) + 
      '<table>'+
      insertItem('Project ID:', row.tip_id) + 
      insertItem('Sponsor:', row.sponsor) +
      insertItem('MPO:', row.mpo) +
      insertItem('Project Type:', row.ptype) +
      insertItem('Cost:', cost) +
      insertItem('Description:', row.description) +
      '</table>';
    }

    obj.bindPopup(base_tpl);

    projectLayer.addLayer(obj);

    if (zoom_to_project_id && (zoom_to_project_id == row.rtp_id || zoom_to_project_id == row.tip_id)){
      zoomFeatures.push(obj);
    }
  });

  projectLayer.name = layerName;

  projectLayer.layerId = projectLayer._leaflet_id || GatewayMapUtil.randString(6);
  this.layerControl.addOverlay(projectLayer, projectLayer.name);

  projectLayer.addTo(map);

  projectLayer.geometryType = 'MULTIPLE';

  if(zoomFeatures.length > 0) {
    map.fitBounds(new L.featureGroup(zoomFeatures).getBounds().pad(0.25));
  }
  
  this.addSimpleLegend(
      projectLayer,
    [{
      subject: symbology.subject
    }],
    symbology.subject,
    colorLabels,
    null,
    false,
    false,
    divIcons
  );

  this.addAttribution('Project data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>', projectLayer.layerId);

  return [projectLayer];
};

//function to add CountFact wkt layer to map
CsLeaflet.Leaflet.prototype.addCountFactPoints = function(data, symbology, baseUrl, layerName, visibility, requestData, hub_bound_file_path){
  var map = this.LMmap;

  var countLayer = L.layerGroup();

  data = data || [];

  requestData = requestData || {};
  direction = requestData.direction;
  transit_mode = requestData.transit_mode;
  year = requestData.year;
  hour = requestData.hour;

  var sectorColors = {};
  var sectorColorLabels = {};
  symbology.color_scheme.forEach(function(colorObj) {
    sectorColors[colorObj.value] = colorObj.color;
    sectorColorLabels[colorObj.label] = colorObj.color;
  });
  
  var displayConfig = this.getLayerDisplayColumnConfig(countLayer, symbology)

  // grouping by location_id
  var location_data = {};
  data.forEach(function(row) {
    var loc_id = row.loc_id;

    if(!location_data[loc_id]) {
      location_data[loc_id] = {
        location_name: row.loc_name,
        sector_name: row.sector_name,
        mode_name: row.mode_name,
        lat: row.lat,
        lng: row.lng,
        routes: {},
        route_count: 0
      };
    }

    var routes = location_data[loc_id].routes;
    var route_name = row.route_name;
    var route_entry = {};
    if(!routes[route_name]) {
      routes[route_name] = route_entry;
      location_data[loc_id].route_count ++;
    } else {
      route_entry = routes[route_name];
    }

    var var_name = row.var_name;
    var new_count = parseFloat(row.count.toString().split(',').join(''));
    // Average occupancy rates
    if(var_name == 'Occupancy Rates') {
      if(!route_entry[var_name]) {
        route_entry[var_name] = {
          value: new_count,
          total: new_count,
          counter: 1
        };
      } else {
        var prevData = route_entry[var_name];
        var counter = prevData.counter + 1;
        var newTotal = prevData.total + new_count;
        var avgValue = newTotal / counter;
        route_entry[var_name] = {
          value: avgValue,
          total: newTotal,
          counter: counter
        };
      }
    } else { // Sum up other variables
      if(!route_entry[var_name]) {
        route_entry[var_name] = new_count;
      } else {
        route_entry[var_name] += new_count;
      }
    }
  });

  var isInbound = (direction == 'Inbound');
  var colName = displayConfig.name;
  for(var loc_id in location_data) {
    var row = location_data[loc_id];
    var color = sectorColors[row[colName]];

    var marker = L.circleMarker(new L.LatLng(row.lat, row.lng), {
      fill: true,
      radius: isInbound ? 4 : 5,
      fillColor: isInbound ? color : 'transparent',
      fillOpacity: 1,
      opacity: 1,
      weight: 2,
      color: color
    });

    var insertItem = function(label, value) {
      return '<tr><td style="text-align: right;"><b>' + label + '</b> </td>' + '<td style="text-align:left; padding-left: 10px;">' + value + '</span></td></tr>'; 
    };

    var tableUrl = baseUrl + "?year=" + year + 
      "&hour=" + hour +
      "&transit_mode=" + encodeURIComponent(transit_mode) + 
      "&direction=" + direction +
      "&location=" + encodeURIComponent(row.location_name); 

    var tableLink = "<a target='_blank' href=" + tableUrl + ">View in Table</a>";

    var base_tpl = 
      tableLink + 
      '<table>'+
      insertItem('Facility Name:', row.location_name) + 
      insertItem('Sector:', row.sector_name) +
      insertItem('Mode:', row.mode_name) +
      '</table>';

    if(row.route_count > 7) {
      base_tpl += "<p><b style='margin-top: 10px;'>Too many routes to display. Please </b>" + tableLink + "</p>";
    } else {
      for(var route_name in row.routes) {
        base_tpl += '<table style="margin-top: 10px;">';
        base_tpl += insertItem(' ', ' ');
        base_tpl += insertItem('Route:', route_name);
        var route_entry = row.routes[route_name];
        for(var var_name in route_entry) {
          var val = route_entry[var_name];
          if(var_name == 'Occupancy Rates') {
            val = val.value.toFixed(2);
          }
          base_tpl += insertItem(var_name + ":", GatewayMapUtil.formatNumber(val, {
              type: 'number',
              options: {
                format:"#,##0.##", 
                locale:"us"
              }
            }));
        }
        base_tpl += '</table>';
      }
    }

    marker.bindPopup(base_tpl);

    countLayer.addLayer(marker);
  }
      
  
  countLayer.name = layerName;
  countLayer.layerId = countLayer._leaflet_id || GatewayMapUtil.randString(6);
  countLayer.symbology = symbology;
  this.layerControl.addOverlay(countLayer, layerName);

  var countLayerVisible = !(visibility == false);
  if(countLayerVisible) {
    countLayer.addTo(map);
  }
  countLayer.geometryType = 'POINT';
  this.addSimpleLegend(
    countLayer,
    [{
      subject: layerName
    }],
    symbology.subject + ' (' + direction + ')',
    sectorColorLabels,
    null,
    !countLayerVisible,
    !isInbound
  );

  this.addAttribution(layerName + ' data &copy; <a href="http://nymtc.org/">NY Metropolitan Transportation Council</a>', countLayer.layerId);

  return [countLayer];
};

CsLeaflet.Leaflet.prototype.getBoundsInWKT = function() {
  var bounds = this.LMmap.getBounds();
  var xmin = bounds.getWest();
  var xmax = bounds.getEast();
  var ymin = bounds.getSouth();
  var ymax = bounds.getNorth();

  var wktCoords = xmin + " " + ymin + ", " +
    xmin + " " + ymax + ", " +
    xmax + " " + ymax + ", " +
    xmax + " " + ymin + ", " +
    xmin + " " + ymin;

  return "POLYGON ((" + wktCoords + "))";
};

CsLeaflet.Leaflet.prototype.addAreaBoundaryLayerFromWKT = function(layerBoundaryWkt) {
  try{
    var wkt = new Wkt.Wkt();
    var obj;
    wkt.read(layerBoundaryWkt);
    obj = wkt.toObject({
      fill: false,
      color: 'red',
      weight: 2,
      clickable: false,
      className: 'area-boundary'
    });

    var map = this.LMmap;
    var areaBoundaryLayer = L.layerGroup();
    areaBoundaryLayer.addLayer(obj);
    areaBoundaryLayer.name = "Area Boundary";
    areaBoundaryLayer.layerId = areaBoundaryLayer._leaflet_id || GatewayMapUtil.randString(6);
    this.layerControl.addOverlay(areaBoundaryLayer, areaBoundaryLayer.name);
    areaBoundaryLayer.addTo(map);
    areaBoundaryLayer.geometryType = 'POLYGON';
  }
  catch(err) {
    console.log(err);
  }
};
