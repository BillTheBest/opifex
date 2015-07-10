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
	test "opifex binds resource if SinkURI is <resource>/<metadata>", (t) ->
		t.same( mock.bound,
			[
				['resource','resource','#'],
			],
			"resource was bound")
		t.end()
	setTimeout process.exit, 1
, 100

mock.init()
fun = () -> this['*'] = () ->
self = Opifex(null,'amqp://user:pass@host:5642/domain/resource/metadata', fun)
