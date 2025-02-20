this.Googlemaps_Map = (function () {
  function Googlemaps_Map() {
  }

  Googlemaps_Map.map = null;

  Googlemaps_Map.form = null;

  Googlemaps_Map.center = null; // null means auto

  Googlemaps_Map.zoom = null; // null means auto

  Googlemaps_Map.defaultCenter = [36.204824, 138.252924];

  Googlemaps_Map.defaultZoom = 13;

  Googlemaps_Map.markers = null;

  Googlemaps_Map.markerIcon = "/assets/img/googlemaps/marker1.png";

  Googlemaps_Map.clickIcon = "/assets/img/googlemaps/marker17.png";

  Googlemaps_Map.openedInfo = null;

  Googlemaps_Map.resized = null;

  Googlemaps_Map.kmlLayer = null;

  Googlemaps_Map.showGoogleMapsSearch = false;

  Googlemaps_Map.mapsSearchUrl = "https://www.google.co.jp/maps/search/";

  Googlemaps_Map.attachMessage = function (id) {
    google.maps.event.addListener(Googlemaps_Map.markers[id]["marker"], 'click', function (event) {
      if (Googlemaps_Map.openedInfo) {
        Googlemaps_Map.openedInfo.close();
      }
      if (Googlemaps_Map.markers[id]["window"]) {
        Googlemaps_Map.markers[id]["window"].open(Googlemaps_Map.markers[id]["marker"].getMap(), Googlemaps_Map.markers[id]["marker"]);
      }
      Googlemaps_Map.openedInfo = Googlemaps_Map.markers[id]["window"];
    });
    return google.maps.event.addListener(Googlemaps_Map.markers[id]["window"], 'closeclick', function (event) {
      Googlemaps_Map.openedInfo = null;
    });
  };

  Googlemaps_Map.setForm = function (form) {
    return this.form = form;
  };

  Googlemaps_Map.load = function (selector, options) {
    if (!options) {
      options = {}
    }

    if (options["zoom"]) {
      if (Googlemaps_Map.validateZoom(options["zoom"])) {
        Googlemaps_Map.zoom = options["zoom"];
      }
    }
    if (options["center"]) {
      if (Googlemaps_Map.validateLatLon(options["center"][1], options["center"][0])) {
        Googlemaps_Map.center = options["center"].reverse();
      }
    }
    if (options["showGoogleMapsSearch"]) {
      Googlemaps_Map.showGoogleMapsSearch = true;
    }

    var center = Googlemaps_Map.getCenter();
    var mapOptions = {
      center: new google.maps.LatLng(center[0], center[1]),
      zoom: Googlemaps_Map.getZoom(),
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      panControl: false,
      zoomControl: true,
      zoomControlOptions: {
        style: google.maps.ZoomControlStyle.LARGE
      },
      mapTypeControl: true,
      scaleControl: true,
      scrollwheel: true,
      streetViewControl: true,
      overviewMapControl: true,
      overviewMapControlOptions: {
        opened: true
      }
    };
    Googlemaps_Map.map = new google.maps.Map($(selector).get(0), mapOptions);
  };

  Googlemaps_Map.getCenter = function () {
    return (Googlemaps_Map.center ? Googlemaps_Map.center : Googlemaps_Map.defaultCenter);
  }

  Googlemaps_Map.getZoom = function () {
    return (Googlemaps_Map.zoom ? Googlemaps_Map.zoom : Googlemaps_Map.defaultZoom);
  }

  Googlemaps_Map.resize = function () {
    google.maps.event.trigger(this.map, "resize");
    if (!this.resized) {
      var center = Googlemaps_Map.getCenter();
      this.map.setCenter(new google.maps.LatLng(center[0], center[1]));
      if (this.form) {
        this.form.renderMarkers();
      }
    }
    return this.resized = true;
  };

  Googlemaps_Map.renderMarkers = function () {
    if (this.form) {
      return this.form.renderMarkers();
    }
  };

  Googlemaps_Map.renderEvents = function () {
    if (this.form) {
      return this.form.renderEvents();
    }
  };

  Googlemaps_Map.setMarkers = function (markers) {
    var markerBounds, zoomChangeBoundsListener;
    Googlemaps_Map.markers = markers;
    markerBounds = new google.maps.LatLngBounds();
    $.each(Googlemaps_Map.markers, function (id, value) {
      var name, text, opts;

      opts = {
        position: new google.maps.LatLng(value["loc"][1], value["loc"][0]),
        map: Googlemaps_Map.map
      };
      if (value["image"]) {
        opts["icon"] = value["image"];
      } else {
        opts["icon"] = Googlemaps_Map.markerIcon;
      }
      Googlemaps_Map.markers[id]["marker"] = new google.maps.Marker(opts);
      markerBounds.extend(new google.maps.LatLng(value["loc"][1], value["loc"][0]));

      var markerHtml = "";
      if (value["html"]) {
        markerHtml = value["html"];
      } else if (value["name"] || value["text"]) {
        name = value["name"];
        text = value["text"];
        markerHtml = '<div class="marker-info">';
        if (name && name !== "") {
          markerHtml += '<p>' + name + '</p>';
          if (text && text !== "") {
            $.each(text.split(/[\r\n]+/), function () {
              if (this.match(/^https?:\/\//)) {
                return markerHtml += '<p><a href="' + this + '">' + this + '</a></p>';
              } else {
                return markerHtml += '<p>' + this + '</p>';
              }
            });
          }
        }
        markerHtml += '</div>';
      }

      if (Googlemaps_Map.showGoogleMapsSearch) {
        markerHtml += Googlemaps_Map.getMapsSearchHtml(value["loc"][1], value["loc"][0]);
      }
      if (markerHtml) {
        Googlemaps_Map.markers[id]["window"] = new google.maps.InfoWindow({
          content: markerHtml
        });
        Googlemaps_Map.attachMessage(id);
      }
    });

    Googlemaps_Map.adjustMarkerBounds(Googlemaps_Map.markers.length, markerBounds);
  };

  Googlemaps_Map.setKmlLayer = function (url) {
    Googlemaps_Map.kmlLayer = new google.maps.KmlLayer({
      url: url,
      suppressInfoWindows: true,
      preserveViewport: false
    });
    Googlemaps_Map.kmlLayer.setMap(Googlemaps_Map.map);
  };

  Googlemaps_Map.setGeoJson = function (url) {
    Googlemaps_Map.map.data.setStyle({
      fillColor: "#b2c9e8",
      strokeColor: "#5A88C6",
      strokeWeight: 1
    });
    Googlemaps_Map.map.data.loadGeoJson(url, {}, function(data) {
      var bounds = new google.maps.LatLngBounds();
      var locs = [];

      data.forEach(function (feature) {
        feature.getGeometry().forEachLatLng(function (LatLng) {
          bounds.extend(LatLng);
          locs.push(LatLng);
        });
      });

      Googlemaps_Map.adjustMarkerBounds(locs.length, bounds);
    });
  };

  Googlemaps_Map.adjustMarkerBounds = function(pointCount, bounds) {
    if (pointCount > 0) {
      // marker exists
      // set manually options or do fit
      var manuallyAdjust = false;

      if (Googlemaps_Map.center) {
        var center = Googlemaps_Map.getCenter();
        Googlemaps_Map.map.setCenter(new google.maps.LatLng(center[0], center[1]));
        manuallyAdjust = true;
      }

      if (Googlemaps_Map.zoom) {
        Googlemaps_Map.map.setZoom(Googlemaps_Map.getZoom());
        manuallyAdjust = true;
      }

      if (!manuallyAdjust) {
        google.maps.event.addListenerOnce(Googlemaps_Map.map, "idle", function(){
          if (Googlemaps_Map.map.getZoom() > Googlemaps_Map.getZoom()) {
            Googlemaps_Map.map.setZoom(Googlemaps_Map.getZoom());
          }
        })
        Googlemaps_Map.map.fitBounds(bounds);
      }
    } else {
      // marker not exists
      // set manually or default options
      var center = Googlemaps_Map.getCenter();
      Googlemaps_Map.map.setCenter(new google.maps.LatLng(center[0], center[1]));
      Googlemaps_Map.map.setZoom(Googlemaps_Map.getZoom());
    }
  };

  Googlemaps_Map.validateZoom = function (zoom) {
    if (zoom >= 1 && zoom <= 21) {
      return true;
    } else {
      return false;
    }
  };

  Googlemaps_Map.validateLatLon = function (lat, lon) {
    if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      return true;
    } else {
      return false;
    }
  };

  Googlemaps_Map.getMapsSearchHtml = function(lat, lng) {
    var url = Googlemaps_Map.mapsSearchUrl + lat + "," + lng;
    return '<p><a href="' + url + '">' + "Googleマップで見る" + '</a></p>';
  };

  return Googlemaps_Map;
})();
