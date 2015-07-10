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
	test "opifex creates resource and explicit bindings if SourceURI is an explicit binding", (t) ->
		t.same( mock.bound,
			[
				['source','source','#'],
				['dest','dest','#'],
				['dest','source','pattern']
			],
			"resource was bound")
		t.end()
	setTimeout process.exit, 1
, 100

mock.init()
fun = () -> this['*'] = () ->
self = Opifex('amqp://user:pass@host:5642/domain/source/dest/pattern', null, fun)
