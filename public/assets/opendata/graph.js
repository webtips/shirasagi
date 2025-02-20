Opendata_Graph = function (canvas, controller) {
  this.$canvas = $(canvas);
  this.$container = $(canvas).parent("div");
  this.$controller = $(controller);
  this.chart = null;
};

Opendata_Graph.prototype.render = function(type, name, labels, datasets, opts) {
  if (opts == null) {
    opts = {};
  }

  this.type = type;
  this.name = name;
  this.labels = labels;
  this.datasets = datasets;
  this.headerIndex = opts["headerIndex"];

  this.destroy();
  if (this.headerIndex || this.headerIndex == 0) {
    var dataset = this.datasets[this.headerIndex];
    if (dataset) {
      this.datasets = [dataset];
    }
  }
  if (this.type == "bar") {
    this.drawBar();
  } else if(this.type == "line") {
    this.drawLine();
  } else if (this.type == "pie") {
    this.drawPie();
  }
};

Opendata_Graph.prototype.resizeContainer = function(width) {
  var baseWidth = this.$container.data("baseWidth");
  if (!baseWidth) {
    baseWidth = this.$container.width();
    this.$container.data("baseWidth", baseWidth);
  }
  if (width > baseWidth) {
    this.$container.css("width", width + "px");
  } else {
    this.$container.css("width", baseWidth + "px");
  }
};

Opendata_Graph.prototype.datasetsMinWidth = function() {
  return (this.datasets.length * 12) * this.labels.length;
};

Opendata_Graph.prototype.drawBar = function() {
  this.resizeContainer(this.datasetsMinWidth());
  this.chart = new Chart(this.$canvas, {
    type: 'bar',
    data: {
      labels: this.labels,
      datasets: this.datasets,
    },
    options: {
      title: {
        display: true,
        text: this.name,
        fontSize: 18
      },
      legend: {
        display: true,
        position: 'bottom',
        onClick: function () { return false; }
      },
      plugins: {
        colorschemes: {
          scheme: 'brewer.Paired12'
        }
      },
      scales: {
        xAxes: [{
          ticks: {
            autoSkip: false
          }
        }],
        yAxes: [{
          ticks: {
            beginAtZero: true,
            callback: function (label, index, labels) {
              return label.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
            }
          }
        }]
      },
      responsive: true,
      maintainAspectRatio: false,
      //animation: {
      //  onComplete: function () {}
      //}
    }
  });
};

Opendata_Graph.prototype.drawLine = function() {
  this.resizeContainer(this.datasetsMinWidth());
  this.chart = new Chart(this.$canvas, {
    type: 'line',
    data: {
      labels: this.labels,
      datasets: this.datasets,
    },
    options: {
      title: {
        display: true,
        text: this.name,
        fontSize: 18
      },
      legend: {
        display: true,
        position: 'bottom',
        onClick: function () { return false; }
      },
      plugins: {
        colorschemes: {
          scheme: 'brewer.Paired12'
        }
      },
      scales: {
        xAxes: [{
          ticks: {
            autoSkip: false
          }
        }],
        yAxes: [{
          ticks: {
            beginAtZero: true,
            callback: function(label, index, labels) {
              return label.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
            }
          }
        }]
      },
      responsive: true,
      maintainAspectRatio: false,
      //animation: {
      //  onComplete: function () {}
      //}
    }
  });
};

Opendata_Graph.prototype.drawPie = function() {
  this.resizeContainer(0);
  this.chart = new Chart(this.$canvas, {
    type: 'pie',
    data: {
      labels: this.labels,
      datasets: this.datasets,
    },
    options: {
      title: {
        display: true,
        text: this.name,
        fontSize: 18
      },
      legend: {
        display: true,
        position: 'bottom',
        onClick: function () { return false; }
      },
      tooltips: {
        callbacks: {
          label: function(tooltipItem, data) {
            var label = data["labels"][tooltipItem["index"]];
            var dataset = data["datasets"][tooltipItem["datasetIndex"]];

            data = dataset["data"][tooltipItem["index"]];
            data = data.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');

            label = label + "（" + dataset["label"] + "）: " + data;
            return label;
          }
        }
      },
      plugins: {
        colorschemes: {
          scheme: 'brewer.Paired12'
        }
      },
      scales: {
        xAxes: [{ display: false }],
        yAxes: [{ display: false }]
      },
      responsive: true,
      maintainAspectRatio: false,
      //animation: {
      //  onComplete: function () {}
      //}
    }
  });
};

Opendata_Graph.prototype.renderController = function(types, headers, callback) {
  var self = this;
  this.types = types;
  this.headers = headers;
  this.$controller.html("");

  // type bottons
  var graphTypes = {"bar":"棒グラフ","line":"線グラフ","pie":"円グラフ"};
  var divTypes = $('<div class="graph-types"></div>');
  $.each(this.types, function() {
    var button = $('<button type="button" data-type="' + this +'">' + graphTypes[this] + '</button>');

    if (self.type == this) {
      button.addClass("current");
    }
    $(button).on("click", function() {
      callback($(this).data("type"));
    })
    $(divTypes).append(button);
  });
  this.$controller.append(divTypes);

  // pie controller
  if (this.type == "pie" && this.headers && this.headers.length > 0) {
    var divHeader = $('<div class="graph-header-controller"></div>');
    var select = $('<select class="select-header" name="header-index"></select>');

    $.each(this.headers, function(i) {
      if (self.headerIndex == i) {
        $(select).append('<option value="' + i +'" selected="selected">' + this + '</option>');
      } else {
        $(select).append('<option value="' + i +'">' + this + '</option>');
      }
    });
    $(select).on("change", function() {
      callback("pie", $(this).val());
    });

    $(divHeader).append(select);
    this.$controller.append(divHeader);
  }

  this.$controller.show();
};

Opendata_Graph.prototype.destroy = function() {
  if (this.chart) {
    this.chart.destroy();
  }
  if (this.$controller) {
    this.$controller.html("");
  }
};

