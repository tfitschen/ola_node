#!/usr/bin/env coffee

fs      = require 'fs'
if !fs.existsSync __dirname + '/../config.json'
  console.log 'config file not exists: config.json';
  console.log 'cp config.json.tpl config.json'
  process.exit 1

OLA     = require '..'
config  = require '../config.json'
npm     = require '../package.json'

dmx = new OLA.DMX config.server_name, config.server_port, config.universe_id
server = new OLA.Server config.service_port, dmx

status = ' '
for arg in process.argv
  if arg is '-t' or arg is '--test'
    dmx.testMode true
    status = ' into test mode '

console.log "Start server v#{npm.version}#{status}on port #{config.service_port}"
console.log 'Exit with ^C'
server.run()
