$(function() {
  var baseEndpoint, ciaEndpoint, countries, dbpediaEndpoint, getCountries, init, loadCountryData;
  console.log('ready..');
  baseEndpoint = 'http://192.168.2.10:8890/sparql/';
  dbpediaEndpoint = 'http://dbpedia.org/sparql/';
  ciaEndpoint = 'http://wifo5-03.informatik.uni-mannheim.de/factbook/sparql/';
  countries = [];
  init = function() {
    $('.country-list select').on('change', function(e) {
      return loadCountryData($(this).val());
    });
    return $.ajax({
      method: 'GET',
      url: baseEndpoint,
      headers: {
        Accept: 'application/json'
      },
      data: {
        query: 'select distinct ?countryURI where { ?s <http://www.w3.org/2002/07/owl#sameAs> ?countryURI . filter (regex(?s, "pebbleroad", "i")) . }'
      }
    }).done(function(response) {
      var countryURIs;
      countryURIs = [];
      response.results.bindings.forEach(function(item, index) {
        return countryURIs.push(item.countryURI.value);
      });
      getCountries(countryURIs);
      return countries = countryURIs;
    }).error(function(err) {
      return console.log('there was an error:', error);
    });
  };
  getCountries = function(data) {
    console.log('countryData', data);
    return $.when($.ajax({
      method: 'GET',
      url: dbpediaEndpoint,
      headers: {
        Accept: 'application/json'
      },
      data: {
        query: 'select ?name where { <http://dbpedia.org/resource/Cambodia> foaf:name ?name . filter (lang(?name) = "en") . } limit 1'
      }
    }), $.ajax({
      method: 'GET',
      url: dbpediaEndpoint,
      headers: {
        Accept: 'application/json'
      },
      data: {
        query: 'select ?name where { <http://dbpedia.org/resource/Malaysia> foaf:name ?name . filter (lang(?name) = "en") . } limit 1'
      }
    })).then(function(res1, res2) {
      var c, html, source, template;
      source = $('#select-option').html();
      template = Handlebars.compile(source);
      c = [
        {
          country: res1[0].results.bindings[0].name.value
        }, {
          country: res2[0].results.bindings[0].name.value
        }
      ];
      html = '';
      c.forEach(function(item) {
        return html += template(item);
      });
      $('#country-select').append(html);
      return $('.country-list').show();
    });
  };
  loadCountryData = function(country) {
    var ciaUrl, dbpediaURI, queryAdbData, queryCiaData, queryLabels, queryPeopleBirthPlace, querydbpediaData;
    console.log('country:', country);
    ciaUrl = 'http://wifo5-04.informatik.uni-mannheim.de/factbook/resource/' + country;
    dbpediaURI = _.find(countries, function(c) {
      return new RegExp(country, "i").test(c);
    });
    queryLabels = 'select distinct ?label where { <http://demos.pebbleroad.com/adb/Country/' + country + '> ?p ?o . filter (regex(?p, "pebbleroad", "i")) . ?p <http://www.w3.org/2000/01/rdf-schema#label> ?label . }';
    queryAdbData = 'select distinct ?year ?populationPercentChange ?populationDensity ?populationUrban ?revenueAndGrants ?laborforcePercentChange ?employedTotal ?unemployedTotal ?electricityProduction (sample(?p as ?pred)) where { <http://demos.pebbleroad.com/adb/Country/' + country + '> ?p ?o . ?o dbpprop:populationCensusYear ?year . optional { ?o adb:populationPercentChange ?populationPercentChange } . optional { ?o adb:populationUrban ?populationUrban } . optional { ?o adb:populationDensity ?populationDensity } . optional { ?o adb:revenueAndGrants ?revenueAndGrants } . optional { ?o adb:employedTotal ?employedTotal } . optional { ?o adb:unemployedTotal ?unemployedTotal } . optional { ?o adb:laborforcePercentChange ?laborforcePercentChange } . optional { ?o adb:electricityProduction ?electricityProduction } . } order by ?year';
    querydbpediaData = 'select ?name ?comment ?flagUrl ?motto ?capital ?lat ?long where { <' + dbpediaURI + '> foaf:name ?name . optional { <' + dbpediaURI + '> rdfs:comment ?comment . filter langMatches(lang(?comment), "en") . } optional { <' + dbpediaURI + '> foaf:depiction ?flagUrl . } optional { <' + dbpediaURI + '> dbpedia-owl:motto ?motto . } optional { <' + dbpediaURI + '> dbpprop:capital ?_capital . ?_capital foaf:name ?capital . filter langMatches(lang(?capital), "en") . } optional { <' + dbpediaURI + '> geo:lat ?lat . } optional { <' + dbpediaURI + '> geo:long ?long . } } limit 1';
    queryPeopleBirthPlace = 'select ?givenName ?surname ?shortDescription ?isPrimaryTopicOf where { ?person dbpedia-owl:birthPlace <' + dbpediaURI + '> . ?person foaf:givenName ?givenName . ?person foaf:surname ?surname . ?person dbpprop:shortDescription ?shortDescription . ?person foaf:isPrimaryTopicOf ?isPrimaryTopicOf }';
    queryCiaData = 'SELECT ?climate WHERE { <http://wifo5-04.informatik.uni-mannheim.de/factbook/resource/Cambodia> factbook:climate ?climate . } LIMIT 1';
    return $.when($.ajax({
      method: 'GET',
      url: baseEndpoint,
      headers: {
        Accept: 'application/json'
      },
      data: {
        query: queryAdbData
      }
    }), $.ajax({
      method: 'GET',
      url: dbpediaEndpoint,
      headers: {
        Accept: 'application/json'
      },
      data: {
        query: querydbpediaData
      }
    }), $.ajax({
      method: 'GET',
      url: dbpediaEndpoint,
      headers: {
        Accept: 'application/json'
      },
      data: {
        query: queryPeopleBirthPlace
      }
    })).then(function(AdbData, dbpediaData, peopleBirthPlace) {
      var birthPlaceTemplate, ctx, data, dbpediaTemplate, employedTotal, html, lat, latLong, lbfChange, lineChart, lineChartPercent, long, mapOptions, peopleBirthPlaceHtml, source, template, unemployedTotal, years;
      $('.country-data').show();
      console.log(dbpediaData);
      dbpediaTemplate = Handlebars.compile($('#dbpedia-data').html());
      $('.dbpedia-data').html(dbpediaTemplate(dbpediaData[0].results.bindings[0]));
      lat = dbpediaData[0].results.bindings[0].lat.value;
      long = dbpediaData[0].results.bindings[0].long.value;
      if ((lat != null) && (long != null)) {
        latLong = new google.maps.LatLng(lat, long);
        mapOptions = {
          center: latLong,
          zoom: 6
        };
        new google.maps.Map(document.getElementById('map-canvas'), mapOptions);
      }
      years = [];
      employedTotal = [];
      unemployedTotal = [];
      lbfChange = [];
      html = '';
      source = $('#adb-row').html();
      template = Handlebars.compile(source);
      AdbData[0].results.bindings.forEach(function(item) {
        years.push(parseInt(item.year.value));
        employedTotal.push(parseFloat(item.employedTotal.value).toFixed(1));
        unemployedTotal.push(parseFloat(item.unemployedTotal.value).toFixed(1));
        lbfChange.push(parseFloat(item.laborforcePercentChange.value).toFixed(1));
        return html += template(item);
      });
      $('.adb-data tbody').html(html);
      ctx = $('#laborForceChart').get(0).getContext('2d');
      data = {
        labels: years,
        datasets: [
          {
            name: "here too",
            label: "Employment (total)",
            fillColor: "rgba(220,220,220,0.2)",
            strokeColor: "rgba(220,220,220,1)",
            pointColor: "rgba(220,220,220,1)",
            pointStrokeColor: "#fff",
            pointHighlightFill: "#fff",
            pointHighlightStroke: "rgba(220,220,220,1)",
            data: employedTotal
          }, {
            name: "here?",
            label: "Unemployment (total)",
            fillColor: "rgba(151,187,205,0.2)",
            strokeColor: "rgba(151,187,205,1)",
            pointColor: "rgba(151,187,205,1)",
            pointStrokeColor: "#fff",
            pointHighlightFill: "#fff",
            pointHighlightStroke: "rgba(151,187,205,1)",
            data: unemployedTotal
          }
        ]
      };
      lineChart = new Chart(ctx).Line(data, {
        responsive: true,
        animation: false,
        showScale: true,
        pointHitDetectionRadius: 10,
        legendTemplate: '<ul class="<%= name.toLowerCase() %>-legend"><% for (var i=0; i<datasets.length; i++){%><li><span style="background-color:<%=datasets[i].strokeColor%>"></span><%if(datasets[i].label){%><%=datasets[i].label%><%}%></li><%}%></ul>'
      });
      ctx = $('#laborForceChartPercent').get(0).getContext('2d');
      data = {
        labels: years,
        datasets: [
          {
            fillColor: "rgba(151,187,205,0.2)",
            strokeColor: "rgba(151,187,205,1)",
            pointColor: "rgba(151,187,205,1)",
            pointStrokeColor: "#fff",
            pointHighlightFill: "#fff",
            pointHighlightStroke: "rgba(151,187,205,1)",
            data: lbfChange
          }
        ]
      };
      lineChartPercent = new Chart(ctx).Line(data, {
        responsive: true,
        animation: false,
        showScale: true,
        pointHitDetectionRadius: 10
      });
      console.log(peopleBirthPlace);
      peopleBirthPlaceHtml = '';
      birthPlaceTemplate = Handlebars.compile($('#people-birthplace').html());
      peopleBirthPlace[0].results.bindings.forEach(function(item) {
        return peopleBirthPlaceHtml += birthPlaceTemplate(item);
      });
      $('.people-birthplace').html(peopleBirthPlaceHtml);
      return $('.people-search').instaFilta({
        targets: '.person',
        sections: '.person-container'
      });
    });
  };
  return init();
});
