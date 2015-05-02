$ ->
  console.log 'ready..'
  baseEndpoint = 'http://192.168.2.10:8890/sparql/'
  dbpediaEndpoint = 'http://dbpedia.org/sparql/'

  countries = []

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
    ).then (res1, res2) ->
      # console.log 'done', res1
      source = $('#select-option').html()
      template = Handlebars.compile(source)
      # console.log template
      c = [{ country: res1[0].results.bindings[0].name.value }, { country: res2[0].results.bindings[0].name.value }]
      html = ''
      c.forEach (item) ->
        html += template item
      $('#country-select').append html
      $('.country-list').show()

  loadCountryData = (country) ->
    console.log 'country:', country

    dbpediaURI = _.find countries, (c) ->
      return new RegExp(country, "i").test(c)

    queryLabels = 'select distinct ?label where { <http://demos.pebbleroad.com/adb/Country/' + country + '> ?p ?o . filter (regex(?p, "pebbleroad", "i")) . ?p <http://www.w3.org/2000/01/rdf-schema#label> ?label . }'
    queryAdbData = 'select distinct ?year ?populationPercentChange ?populationDensity ?populationUrban ?revenueAndGrants ?laborforcePercentChange ?employedTotal ?unemployedTotal ?electricityProduction (sample(?p as ?pred)) where { <http://demos.pebbleroad.com/adb/Country/' + country + '> ?p ?o . ?o dbpprop:populationCensusYear ?year . optional { ?o adb:populationPercentChange ?populationPercentChange } . optional { ?o adb:populationUrban ?populationUrban } . optional { ?o adb:populationDensity ?populationDensity } . optional { ?o adb:revenueAndGrants ?revenueAndGrants } . optional { ?o adb:employedTotal ?employedTotal } . optional { ?o adb:unemployedTotal ?unemployedTotal } . optional { ?o adb:laborforcePercentChange ?laborforcePercentChange } . optional { ?o adb:electricityProduction ?electricityProduction } . } order by ?year'
    querydbpediaData = 'select ?name ?comment ?flagUrl ?motto ?capital where { <' + dbpediaURI + '> foaf:name ?name . optional { <' + dbpediaURI + '> rdfs:comment ?comment . filter langMatches(lang(?comment), "en") . } optional { <' + dbpediaURI + '> foaf:depiction ?flagUrl . } optional { <' + dbpediaURI + '> dbpedia-owl:motto ?motto . } optional { <' + dbpediaURI + '> dbpprop:capital ?_capital . ?_capital foaf:name ?capital . filter langMatches(lang(?capital), "en") . } } limit 1'
    queryPeopleBirthPlace = 'select ?givenName ?surname ?shortDescription ?isPrimaryTopicOf where { ?person dbpedia-owl:birthPlace <' + dbpediaURI + '> . ?person foaf:givenName ?givenName . ?person foaf:surname ?surname . ?person dbpprop:shortDescription ?shortDescription . ?person foaf:isPrimaryTopicOf ?isPrimaryTopicOf }'
    
    $.when(
      $.ajax({
        method: 'GET'
        url: baseEndpoint
        headers: { Accept: 'application/json' }
        data: { query: queryLabels }
      }),
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
      $.ajax({
        method: 'GET'
        url: dbpediaEndpoint
        headers: { Accept: 'application/json' }
        data: { query: queryPeopleBirthPlace }
      }),
    ).then (labels, AdbData, dbpediaData, peopleBirthPlace) ->
      # console.log labels

      # dbpedia data..
      console.log dbpediaData
      dbpediaTemplate = Handlebars.compile $('#dbpedia-data').html()
      $('.dbpedia-data').html dbpediaTemplate(dbpediaData[0].results.bindings[0])

      console.log 'AdbData', AdbData
      html = ''
      source = $('#adb-row').html()
      template = Handlebars.compile(source)
      AdbData[0].results.bindings.forEach (item) ->
        html += template item
      $('.adb-data tbody').html html

      # people's birthplace..
      console.log peopleBirthPlace
      peopleBirthPlaceHtml = ''
      birthPlaceTemplate = Handlebars.compile $('#people-birthplace').html()
      peopleBirthPlace[0].results.bindings.forEach (item) ->
        peopleBirthPlaceHtml += birthPlaceTemplate item
      $('.people-birthplace').html peopleBirthPlaceHtml

      $('.country-data').show()



    # load data from local..
    # load data from dbpedia..
    # load data from cia factbook..

  init()