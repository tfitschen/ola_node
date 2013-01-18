{EventEmitter}  = require 'events'
http            = require 'http'
queryString     = require 'querystring'

class DMX

  constructor: (serverName, serverPort, universeId) ->
    @options = { host: serverName, port: serverPort, universeId: universeId }

  clearDMX: ->
    @dmx = null

  getDMX: (callback) ->
    return callback? null, @dmx if @dmx?
    return @testGetDMX callback if @inTestMode

    url = 'http://' + @options.host + ':' + @options.port + '/get_dmx?u=' + @options.universeId

    http
      .get url, (res) =>
        buffer = ''

        res.on 'data', (data) ->
          buffer += data.toString 'UTF-8'

        res.on 'end', =>
          buffer = JSON.parse buffer
          @setDMX buffer.dmx
          callback? null, @dmx

      .on 'error', (e) =>
        callback? e.message, null

    @

  setDMXObject: (obj, callback) ->
    if obj?

      @getDMX (err, dmx) =>
        for channel, value of obj
          c = parseInt channel, 10
          v = parseInt value, 10

          if c < 1 or c > @dmx.length
            callback? 'Channel not supported: Channel=' + channel, null
            return @
          else
            if v < 0 or v > 255
              callback? 'Value not suppoerted: Channel=' + channel + ', Value=' + value, null
              return @
            else
              dmx[c - 1] = v

        @_sendDMX dmx, callback
    @

  _sendDMX: (dmx, callback) ->
    return @testSendDMX dmx, callback if @inTestMode
    data = queryString.stringify {
      u: @options.universeId,
      dmx: dmx.join ','
    }

    options = {
      host: @options.host,
      port: @options.port
      path: '/set_dmx',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': data.length
      }
    }
    req = http.request options

    req.on 'error', (e) =>
      callbackl? 'Can not send dmx: ' + e.message, null

    req.write data
    req.end()

    req.on 'response', =>
      @dmx = dmx
      callback? null, @dmx

    @

  testMode: (@inTestMode) ->

  testSendDMX: (dmx, callback) ->
    @dmx = dmx
    callback? null, @dmx

  testGetDMX: (callback) ->
    @dmx = for num in [1..512]
      0

    callback? null, @dmx

module.exports = DMX
