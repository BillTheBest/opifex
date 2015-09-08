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
	test "self sends embedded buffer as JSON", (t) ->
		t.same( (new Buffer (JSON.parse mock.published.metadata[0].toString()).data.data).toString(), "we are alive", "message was sent")
		t.end()
	setTimeout process.exit, 1
, 100

mock.init()
fun = () -> this.send {data: new Buffer "we are alive"}
Opifex(null,'amqp://user:pass@host:5642/domain/resource/metadata', fun)
