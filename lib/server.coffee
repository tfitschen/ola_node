fs      = require 'fs'
http    = require 'http'
express = require 'express'
{_}     = require 'lodash'
io      = require 'socket.io'

class Server

  constructor: (@port, @dmx) ->

  run: ->
    @app = express()
    @server = http.createServer @app
    @io = io.listen @server

    @app.use express.json()

    @app.get '/', _.bind @index, @
    @app.get '/dmx', _.bind @getDmx, @
    @app.post '/dmx', _.bind @setDmx, @
    @app.delete '/dmx', _.bind @clearDmx, @

    @dmx.getDMX (err, data) =>
      if err
        console.log 'Can not get data: ' + err
        process.exit 1
        return

      @server.listen @port

    @io.sockets.on 'connection', (socket) =>
        @dmx.getDMX (err, data) ->
          socket.emit 'data', { status: (if err then err else 'OK'), dmx: data }

        socket.on 'set', (data) =>
          @dmx.setDMXObject data, (err, data) ->
            socket.emit 'sets', { status: (if err then err else 'OK'), dmx: data }

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

  clearDmx: (req, res) ->
    clearData = {};
    for num in [1..512]
      clearData[num] = 0;

    res.set 'Content-Type', 'application/json'

    @dmx.setDMXObject clearData, (err, data) ->
      res.send { status: (if err then err else 'OK'), dmx: data }

    @

module.exports = Server
