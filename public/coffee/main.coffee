$ ->
  console.log 'ready..'
  baseEndpoint = 'http://192.168.2.10:8890/sparql/'
  dbpediaEndpoint = 'http://dbpedia.org/sparql/'
  ciaEndpoint = 'http://wifo5-03.informatik.uni-mannheim.de/factbook/sparql/'

  countries = []
  lineChart = null
  lineChartPercent = null

  init = ->
    $('.country-list select').on 'change', (e) ->
      loadCountryData $(this).val()
    $.ajax({
      method: 'GET'
      url: baseEndpoint
      headers: { Accept: 'application/json' }
      data: { query:'select distinct ?countryURI where { ?s <http://www.w3.org/2002/07/owl#sameAs> ?countryURI . filter (regex(?s, "pebbleroad", "i")) . }' }
    }).done((response) ->
      # console.log response
      countryURIs = []
      response.results.bindings.forEach (item, index) ->
        # console.log item.countryURI.value
        countryURIs.push item.countryURI.value
      getCountries countryURIs
      countries = countryURIs

    ).error((err) ->
      console.log 'there was an error:', error
    )

  getCountries = (data) ->
    # should load countries from data here..
    # not the best way to do this..
    console.log 'countryData', data
    $.when(
      $.ajax({
        method: 'GET'
        url: dbpediaEndpoint
        headers: { Accept: 'application/json' }
        data: { query:'select ?name where { <http://dbpedia.org/resource/Cambodia> foaf:name ?name . filter (lang(?name) = "en") . } limit 1' }
      }),
      $.ajax({
        method: 'GET'
        url: dbpediaEndpoint
        headers: { Accept: 'application/json' }
        data: { query:'select ?name where { <http://dbpedia.org/resource/Malaysia> foaf:name ?name . filter (lang(?name) = "en") . } limit 1' }
      })
      # $.ajax({
      #   method: 'GET'
      #   url: dbpediaEndpoint
      #   headers: { Accept: 'application/json' }
      #   data: { query:'select ?name where { <http://dbpedia.org/resource/Philippines> foaf:name ?name . filter (lang(?name) = "en") . } limit 1' }
      # })
    ).then (res1, res2) ->
      # console.log 'done', res1
      source = $('#select-option').html()
      template = Handlebars.compile(source)
      # console.log template
      # c = [{ country: res1[0].results.bindings[0].name.value }, { country: res2[0].results.bindings[0].name.value }, { country: 'Philippines' }]
      c = [{ country: res1[0].results.bindings[0].name.value }, { country: res2[0].results.bindings[0].name.value }]
      html = ''
      c.forEach (item) ->
        html += template item
      $('#country-select').append html
      $('.country-list').show()

  loadCountryData = (country) ->
    console.log 'country:', country

    ciaUrl = 'http://wifo5-04.informatik.uni-mannheim.de/factbook/resource/' + country


    lineChart.destroy() if lineChart?
    lineChartPercent.destroy() if lineChartPercent?
    $('.country-data').hide()

    dbpediaURI = _.find countries, (c) ->
      return new RegExp(country, "i").test(c)

    queryLabels = 'select distinct ?label where { <http://demos.pebbleroad.com/adb/Country/' + country + '> ?p ?o . filter (regex(?p, "pebbleroad", "i")) . ?p <http://www.w3.org/2000/01/rdf-schema#label> ?label . }'
    queryAdbData = 'select distinct ?year ?populationPercentChange ?populationDensity ?populationUrban ?revenueAndGrants ?laborforcePercentChange ?employedTotal ?unemployedTotal ?electricityProduction (sample(?p as ?pred)) where { <http://demos.pebbleroad.com/adb/Country/' + country + '> ?p ?o . ?o dbpprop:populationCensusYear ?year . optional { ?o adb:populationPercentChange ?populationPercentChange } . optional { ?o adb:populationUrban ?populationUrban } . optional { ?o adb:populationDensity ?populationDensity } . optional { ?o adb:revenueAndGrants ?revenueAndGrants } . optional { ?o adb:employedTotal ?employedTotal } . optional { ?o adb:unemployedTotal ?unemployedTotal } . optional { ?o adb:laborforcePercentChange ?laborforcePercentChange } . optional { ?o adb:electricityProduction ?electricityProduction } . } order by ?year'
    querydbpediaData = 'select ?name ?comment ?flagUrl ?motto ?capital ?lat ?long where { <' + dbpediaURI + '> foaf:name ?name . optional { <' + dbpediaURI + '> rdfs:comment ?comment . filter langMatches(lang(?comment), "en") . } optional { <' + dbpediaURI + '> foaf:depiction ?flagUrl . } optional { <' + dbpediaURI + '> dbpedia-owl:motto ?motto . } optional { <' + dbpediaURI + '> dbpprop:capital ?_capital . ?_capital foaf:name ?capital . filter langMatches(lang(?capital), "en") . } optional { <' + dbpediaURI + '> geo:lat ?lat . } optional { <' + dbpediaURI + '> geo:long ?long . } } limit 1'
    queryPeopleBirthPlace = 'select ?givenName ?surname ?shortDescription ?isPrimaryTopicOf where { ?person dbpedia-owl:birthPlace <' + dbpediaURI + '> . ?person foaf:givenName ?givenName . ?person foaf:surname ?surname . ?person dbpprop:shortDescription ?shortDescription . ?person foaf:isPrimaryTopicOf ?isPrimaryTopicOf }'
    queryCiaData = 'SELECT ?climate WHERE { <http://wifo5-04.informatik.uni-mannheim.de/factbook/resource/Cambodia> factbook:climate ?climate . } LIMIT 1'

    $.when(
      # $.ajax({
      #   method: 'GET'
      #   url: baseEndpoint
      #   headers: { Accept: 'application/json' }
      #   data: { query: queryLabels }
      # }),
      $.ajax({
        method: 'GET'
        url: baseEndpoint
        headers: { Accept: 'application/json' }
        data: { query: queryAdbData }
      }),
      $.ajax({
        method: 'GET'
        url: dbpediaEndpoint
        headers: { Accept: 'application/json' }
        data: { query: querydbpediaData }
      }),
      # $.ajax({
      #   method: 'GET'
      #   url: dbpediaEndpoint
      #   headers: { Accept: 'application/json' }
      #   data: { query: queryPeopleBirthPlace }
      # }),
      # $.ajax({
      #   method: 'GET'
      #   url: ciaEndpoint
      #   headers: { Accept: 'application/json' }
      #   data: { query: queryCiaData }
      # }),
    ).then (AdbData, dbpediaData, peopleBirthPlace) ->
      # console.log labels

      $('.country-data').show()

      # dbpedia data..
      console.log dbpediaData
      dbpediaTemplate = Handlebars.compile $('#dbpedia-data').html()
      $('.dbpedia-data').html dbpediaTemplate(dbpediaData[0].results.bindings[0])

      # map..
      lat = dbpediaData[0].results.bindings[0].lat.value
      long = dbpediaData[0].results.bindings[0].long.value
      if (lat? and long?)
        latLong = new google.maps.LatLng(lat, long)
        mapOptions = { center: latLong, zoom: 6 }
        new google.maps.Map document.getElementById('map-canvas'), mapOptions

      # console.log 'AdbData', AdbData
      years = []
      employedTotal = []
      unemployedTotal = []
      lbfChange = []
      html = ''
      source = $('#adb-row').html()
      template = Handlebars.compile(source)
      AdbData[0].results.bindings.forEach (item) ->
        # console.log 'item >>', item
        
        if (item.employedTotal? and item.unemployedTotal? and item.laborforcePercentChange?)
          years.push parseInt item.year.value
          employedTotal.push parseFloat(item.employedTotal.value).toFixed(1)
          unemployedTotal.push parseFloat(item.unemployedTotal.value).toFixed(1)
          lbfChange.push parseFloat(item.laborforcePercentChange.value).toFixed(1)

        html += template item
      $('.adb-data tbody').html html

      # ctx = document.getElementById('laborForceChart').getContext('2d')
      ctx = $('#laborForceChart').get(0).getContext('2d')
      data =
        labels: years
        datasets: [
          {
            name: "here too"
            label: "Employment (total)"
            fillColor : "rgba(220,220,220,0.2)"
            strokeColor : "rgba(220,220,220,1)"
            pointColor : "rgba(220,220,220,1)"
            pointStrokeColor : "#fff"
            pointHighlightFill : "#fff"
            pointHighlightStroke : "rgba(220,220,220,1)"
            data: employedTotal
          },
          {
            name: "here?"
            label: "Unemployment (total)"
            fillColor : "rgba(151,187,205,0.2)"
            strokeColor : "rgba(151,187,205,1)"
            pointColor : "rgba(151,187,205,1)"
            pointStrokeColor : "#fff"
            pointHighlightFill : "#fff"
            pointHighlightStroke : "rgba(151,187,205,1)"
            data: unemployedTotal
          }
        ]
      # console.log 'data >>', data
      lineChart = new Chart(ctx).Line(data, {
        responsive: true
        animation: false
        showScale: true
        pointHitDetectionRadius: 10
        legendTemplate: '<ul class="<%= name.toLowerCase() %>-legend"><% for (var i=0; i<datasets.length; i++){%><li><span style="background-color:<%=datasets[i].strokeColor%>"></span><%if(datasets[i].label){%><%=datasets[i].label%><%}%></li><%}%></ul>'
      })

      ctx = $('#laborForceChartPercent').get(0).getContext('2d')
      data = 
        labels: years
        datasets: [
          fillColor : "rgba(151,187,205,0.2)"
          strokeColor : "rgba(151,187,205,1)"
          pointColor : "rgba(151,187,205,1)"
          pointStrokeColor : "#fff"
          pointHighlightFill : "#fff"
          pointHighlightStroke : "rgba(151,187,205,1)"
          data: lbfChange
        ]

      lineChartPercent = new Chart(ctx).Line(data, {
        responsive: true
        animation: false
        showScale: true
        pointHitDetectionRadius: 10
      })

      # people's birthplace..
      # console.log peopleBirthPlace
      # peopleBirthPlaceHtml = ''
      # birthPlaceTemplate = Handlebars.compile $('#people-birthplace').html()
      # peopleBirthPlace[0].results.bindings.forEach (item) ->
      #   peopleBirthPlaceHtml += birthPlaceTemplate item
      # $('.people-birthplace').html peopleBirthPlaceHtml


      # $('.people-search').instaFilta {
      #   targets: '.person',
      #   sections: '.person-container'
      #   # beginsWith: true
      # }

      # console.log 'ciaData', ciaData

      # $('.country-data').show()



    # load data from local..
    # load data from dbpedia..
    # load data from cia factbook..

  init()