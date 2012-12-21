var fs = require('fs');
var http = require('http');
var querystring = require('querystring');

if (!fs.existsSync('./config.json')) {
    console.log("config file not exists 'config.json'");
    return;
}
var config = require('./config.json');

var dmx = [];

var EventEmitter = require('events').EventEmitter;
var serverEvents = new EventEmitter();

var url = 'http://' + config.server_name + ':' + config.server_port + '/get_dmx?u=' + config.universe_id;
http.get(url, function(res){
    var buffer = "";
    res.on('data', function(data) {
        buffer += data.toString('utf-8');
    });

    res.on('end', function() {
        buffer = JSON.parse(buffer);
        dmx = buffer.dmx;
        serverEvents.emit('start');
    });

    res.on('error', function(e) {
        console.log('problem with request: ' + e.message);
    });
});

var express = require('express');
var app = express();

serverEvents.on('start', function() {
    app.use(express.json());

    app.post('/', function(req, res) {
        var requestBody = req.body;
        var status = "OK";

        var c;
        for (c in requestBody) {
            var channel = parseInt(c, 10);
            if (channel < 1 || channel > dmx.length) {
                status = "Channel not supported: Channel=" + c;
                break;
            } else {
                var val = parseInt(requestBody[c], 10);
                if (val < 0 || val > 255) {
                    status = "Value not supported: Channel=" + c + ", Value=" + requestBody[c];
                    break;
                } else {
                    dmx[channel - 1] = val;
                }
            }
        }

        var post_data = querystring.stringify({
            'u' : config.universe_id,
            'd': dmx.join(',')
        });

        var post_options = {
            host: config.server_name,
            port: config.server_port,
            path: '/set_dmx',
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': post_data.length
            }
        };

        var post_req = http.request(post_options, function(res) {
            // do nothing
        });
        post_req.on('error', function(e) {
            console.log('problem with request: ' + e.message);
        });

        // write parameters to post body
        post_req.write(post_data);
        post_req.end();

        res.send({
            status: status,
            dmx: dmx
       });
    });

    console.log('Start server on port ' + config.service_port);
    app.listen(config.service_port);
});
