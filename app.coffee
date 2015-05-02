express = require 'express'
path = require 'path'
# logger = require 'morgan'
# cookieParser = require 'cookie-parser'
# bodyParser = require 'body-parser'

index = require('./routes/index')

app = express()

# view engine setup
app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'
app.set 'view options', { pretty: true }

# app.use logger 'dev'
# app.use bodyParser.json()
# app.use bodyParser.urlencoded()
# app.use cookieParser()
app.use express.static path.join(__dirname, 'public')

app.use '/', index

# catch 404 and forward to error handler
app.use (req, res, next)->
	err = new Error 'Not Found'
	err.status = 404
	next err

# error handlers
# development error handler will print stacktrace
if app.get('env') is 'development'
	app.use (err, req, res, next)->
		res.status err.status || 500
		res.render 'error', { message: err.message, error: err }
	app.set 'title', 'ADB Linked Data Demo'
	app.locals.pretty = true

# production error handler no stacktraces leaked to user
app.use (err, req, res, next)->
	res.status(err.status || 500)
	res.render 'error', {
		message: err.message,
		error: {}
	}

app.set 'port', process.env.PORT || 3000

server = app.listen app.get('port'), ()->
  console.log 'express server listening on port ' + server.address().port