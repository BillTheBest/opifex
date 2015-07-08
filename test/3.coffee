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

##test "self sends message to sink if SinkURI is defined", (t) ->

##	mock.init()

##	fun = () ->
##		this['*'] = () ->
##		#this.send "we are alive"

##	self = Opifex(null,'amqp://user:pass@host:5642/domain/resource', fun)

##	self('["hello", "world"]')

##	t.ok(
##		'Sink:resource' in logged['INFO'],
##		'called log.info with expected message'
##	)

##	t.end()

##test "opifex parses sink if SinkURI is <resource>/<metadata>", (t) ->

##	mock.init()

##	bindings = null

##	fun = () ->
##		this['*'] = () ->

##	try self = Opifex(null,'amqp://user:pass@host:5642/domain/resource/metadata', fun)

##	t.ok(
##		'Sink:resource/metadata' in logged['INFO'],
##		'called log.info with expected message'
##	)

##	t.end()

