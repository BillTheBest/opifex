#!/usr/bin/env coffee
mock = require './mock.coffee'
mockery = require 'mockery'
mockery.enable({ useCleanCache: true })
mockery.warnOnUnregistered(false)
mockery.registerMock('wot-logger', mock.logger)
mockery.registerMock('wot-amqplib/event_api', { AMQP: mock.AMQP })
test = require('tap').test

Opifex = require 'opifex'

setTimeout () ->
	test "self logs warning if send is called with null message", (t) ->
		t.ok(
			'tried to send with no message' in mock.logged['WARN']
			'called log.warn with expected message'
		)
		t.end()
	setTimeout process.exit, 1
, 100

mock.init()
msg = null
fun = () -> this.send msg
Opifex(null,'amqp://user:pass@host:5642/domain/resource/metadata', fun)
