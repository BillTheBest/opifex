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
	test "self.send stringifies message if message is an array", (t) ->
		t.same( mock.published.metadata[0].toString(), '["hello","world"]', "message was sent")
		t.end()
	setTimeout process.exit, 1
, 100

mock.init()
fun = () -> this.send ["hello","world"]
Opifex(null,'amqp://user:pass@host:5642/domain/resource/metadata', fun)
