#!/usr/bin/env coffee

# force our mock channel to emit an error
process.env['MOCK_CONNECTION_EMIT_ERROR'] = 'true'
mock = require './mock.coffee'
mockery = require 'mockery'
mockery.enable({ useCleanCache: true })
mockery.warnOnUnregistered(false)
mockery.registerMock('wot-logger', mock.logger)
mockery.registerMock('wot-amqplib/event_api', { AMQP: mock.AMQP })
test = require('tap').test

Opifex = require 'opifex'

setTimeout () ->

# save process.exit so we can monkey-patch it
xit = process.exit

# just in case, we hang...
setTimeout xit, 2000

# if opifex calls process.exit, we'll end up in our test
process.exit = (code) ->
	test "self exits on connection error event", (t) ->
		t.same(mock.logged.ERROR[0], 'error test', "logged expected error")
		t.same(code, '1', "exit code is 1")
		t.end()
	setTimeout xit, 1

mock.init()
fun = () ->
Opifex('amqp://user:pass@host:5642/domain/resource', null, fun)
