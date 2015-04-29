fs = require 'fs'
csv = require 'csv'
trim = require 'trim'
_ = require 'underscore'

if (process.env.COUNTRY is undefined)
	console.log 'Error: No country has been passed in. Eg: start script with COUNTRY=<country> FILE=<file> node index.js'
	process.exit 1

console.log 'country >>', process.env.COUNTRY

baseUrl = 'http://ryac.ca/ns/adb/'
obj = {}

labels = [
	['revenueAndGrants', '^^xsd:float', 'GovernmentFinanceFor']
	['electricityProduction', '^^xsd:float', 'EnergyFor']
	['employedTotal', '^^xsd:float', 'LaborForceFor']
	['unemployedTotal', '^^xsd:float', 'LaborForceFor']
	['laborforcePercentChange', '^^xsd:float', 'LaborForceFor']
	['populationDensity', '^^xsd:float', 'PopulationFor']
	['populationPercentChange', '^^xsd:float', 'PopulationFor']
	['populationUrban', '^^xsd:float', 'PopulationFor']
]

file  = '@prefix owl: <http://www.w3.org/2002/07/owl#> .\n'
file += '@prefix dbpedia: <http://dbpedia.org/resource/> .\n'
file += '@prefix dbpprop: <http://dbpedia.org/property/> .\n'
file += '@prefix adb: <http://ryac.ca/ns/adb/> .\n'
file += '@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n\n'

parser = csv.parse (err, data) ->

	allData = extractData data
	years = setDataInYears allData
	output = ''
	yearStart = 1988
	years.forEach (item, index) ->
		y = yearStart + index
		output += createTurtle item, y
	# console.log output
	file += '<http://ryac.ca/ns/adb/country/' + process.env.COUNTRY + '> owl:sameAs dbpedia:' + process.env.COUNTRY + '\n'
	_.each obj, (item, idx) ->
		# console.log 'idx:', idx
		file += ' ; adb:' + idx + '\n'
		arr = _.uniq (item)
		addComma = '     '
		_.each arr, (el, index) ->
			# console.log el
			file += addComma + buildLink(baseUrl, 'country/' + process.env.COUNTRY + '/' + el) + '\n'
			addComma = '   , '
		# console.log '----'
	file += '. \n\n'
	file += output
	fs.writeFile 'output/' + process.env.COUNTRY + '.ttl', file, { encoding: 'utf-8' }, (err) ->
		if (err) then throw err
		console.log 'saved.'
	# console.log file


extractData = (data) ->
	allData = []
	i = 3
	while i <= 15
		column = data[i]
		j = 5
		d = []
		while j <= 32
			if column[j] is undefined
				j++
				continue
			d.push column[j]
			j++
		if (d.length > 0) then allData.push d
		i++
	return allData

setDataInYears = (data) ->
	years = []
	i = 0
	while i < 28
		year = []
		j = 0
		while j < 8
			year.push trim data[j][i]
			j++
		years.push year
		i++
	return years

createTurtle = (data, year) ->
	firstPred = true
	addSemi = ''
	nl = ''
	hasData = false
	output =  buildLink baseUrl, 'country/' + process.env.COUNTRY + '/' + year
	data.forEach (el, index) ->
		if (el isnt '...')
			hasData = true
			if (!firstPred)
				addSemi = '  ; '
				nl = '\n'
			output += addSemi + getPrefix() + labels[index][0] + ' "' + el + '"' + labels[index][1] + '\n'
			if (obj[labels[index][2]] is undefined)
				obj[labels[index][2]] = []	
			obj[labels[index][2]].push year
			firstPred = false
	if (hasData)
		output += addSemi + 'dbpprop:populationCensusYear "' + year + '"^^xsd:int' + '\n'
		output += '. \n\n'
		# console.log obj
	else
		output = ''
	return output
		
buildLink = (base, path) ->
	return '<' + base + path + '> '

getPrefix = ->
	return 'adb:'

fs.createReadStream('csv/country-' + process.env.COUNTRY.toLowerCase() + '.csv').pipe parser