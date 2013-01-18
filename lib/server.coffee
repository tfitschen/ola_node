fs      = require 'fs'
express = require 'express'
{_}     = require 'lodash'

class Server

  constructor: (@port, @dmx) ->

  run: ->
    @app = express()
    @app.use express.json()

    @app.get '/', _.bind @index, @
    @app.get '/dmx', _.bind @getDmx, @
    @app.post '/dmx', _.bind @setDmx, @

    @app.listen @port

    @

  index: (req, res) ->
    url = req.protocol + '://' + req.host + ':'  + @port;
    res.set 'Content-Type', 'text/html'

    fs.readFile 'assets/index.html', 'UTF-8', (err, data) ->
      page = if data instanceof Buffer then data.toString() else data
      page = page.replace(/\{URL\}/g, url);
      res.send page

    @

  getDmx: (req, res) ->
    res.set 'Content-Type', 'application/json'

    @dmx.getDMX (err, data) ->
      res.send { status: (if err then err else 'OK'), dmx: data }

    @

  setDmx: (req, res) ->
    res.set 'Content-Type', 'application/json'

    @dmx.setDMXObject req.body, (err, data) ->
      res.send { status: (if err then err else 'OK'), dmx: data }

    @

module.exports = Server
