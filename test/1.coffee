#!/usr/bin/env coffee
mock = require './mock.coffee'
mockery = require 'mockery'
mockery.enable({ useCleanCache: true })
mockery.warnOnUnregistered(false)
mockery.registerMock('wot-logger', mock.logger)
mockery.registerMock('wot-amqplib/event_api', { AMQP: mock.AMQP })
test = require('tap').test

Opifex = require 'opifex'

test "self is a function with no mixin", (t) ->
	mock.init()
	self = Opifex()
	t.equals(typeof(self), 'function', "self is a function")
	t.end()

test "send() calls log.warn if no output channel is defined", (t) ->
	mock.init()
	fun = () -> this.send "we are alive"
	self = Opifex(null, null, fun)
	self()
	t.ok(
		'send called with no output channel. message:we are alive' in mock.logged['WARN']
		'called log.warn with expected message'
	)
	t.end()

test "self returns if no message", (t) ->
	mock.init()
	fun = () -> this.send "we are alive"
	self = Opifex(null, null, fun)
	t.equals( self(), undefined, 'self returns undefined')
	t.end()

test "self can't dispatch binary to '*' if '*' not defined", (t) ->
	mock.init()
	fun = () -> x = 1
	self = Opifex(null, null, fun)
	self(new Buffer(10))
	t.ok(
		'could not dispatch binary to "*"' in mock.logged['WARN'],
		'called log.warn with expected message'
	)
	t.end()

test "self can't dispatch binary to '*' if '*' not a function", (t) ->
	mock.init()
	fun = () -> this['*'] = 1
	self = Opifex(null, null, fun)
	self(new Buffer(10))
	t.ok(
		'could not dispatch binary to "*"' in mock.logged['WARN'],
		'called log.warn with expected message'
	)
	t.end()

test "self dispatches binary to '*' if '*' is a function", (t) ->
	mock.init()
	fun = () -> this['*'] = () -> this.log.debug 'dispatched to "*"'
	self = Opifex(null, null, fun)
	self(new Buffer(10))
	t.ok(
		'dispatched to "*"' in mock.logged['DEBUG'],
		'called log.debug with expected message'
	)
	t.end()

test "self can't dispatch non-sexp JSON to '*' if '*' not defined", (t) ->
	mock.init()
	fun = () -> x = 1
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify {"hello": "world"})
	t.ok(
		'could not dispatch {"hello":"world"}' in mock.logged['WARN'],
		'called log.warn with expected message'
	)
	t.end()

test "self can't dispatch non-sexp JSON to '*' if '*' not a function", (t) ->
	mock.init()
	fun = () -> this['*'] = 1
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify {"hello": "world"})
	t.ok(
		'could not dispatch {"hello":"world"}' in mock.logged['WARN'],
		'called log.warn with expected message'
	)
	t.end()

test "self dispatches non-sexp JSON to '*' if '*' is a function", (t) ->
	mock.init()
	fun = () -> this['*'] = () -> this.log.debug 'dispatched to "*"'
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify {"hello": "world"})
	t.ok(
		'dispatched to "*"' in mock.logged['DEBUG'],
		'called log.debug with expected message'
	)
	t.end()

test "self dispatches empty array to '*' if '*' is a function", (t) ->
	mock.init()
	fun = () -> this['*'] = () -> this.log.debug 'dispatched to "*"'
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify [])
	t.ok(
		'dispatched to "*"' in mock.logged['DEBUG'],
		'called log.debug with expected message'
	)
	t.end()

test "self dispatches s-exp to '*' if method does not exist and '*' is a function", (t) ->
	mock.init()
	fun = () -> this['*'] = () -> this.log.debug 'dispatched to "*"'
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify ["hello", "world"])
	t.ok(
		'dispatched to "*"' in mock.logged['DEBUG'],
		'called log.debug with expected message'
	)
	t.end()

test "self dispatches s-exp to method if method exists and is a function", (t) ->
	mock.init()
	fun = () ->
		this.hello = (message...) ->
			this.log.debug JSON.stringify message
		this['*'] = () ->
			this.log.error 'dispatched to "*"'
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		'["there","world"]' in mock.logged['DEBUG'],
		'called log.debug with expected message'
	)
	t.end()

test "self dispatches s-exp to '*' if method does not exist and '*' is a function", (t) ->
	mock.init()
	fun = () -> this['*'] = (message...) -> this.log.debug JSON.stringify message
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		'["hello","there","world"]' in mock.logged['DEBUG'],
		'called log.debug with expected message'
	)
	t.end()

test "self logs error if s-exp and method does not exist and '*' is a not function", (t) ->
	mock.init()
	fun = () -> this['*'] = 1
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		'could not dispatch ["hello","there","world"]' in mock.logged['WARN'],
		'called log.warn with expected message'
	)
	t.end()

##test "opifex parses source if SourceURI is defined", (t) ->

##	mock.init()

##	bindings = null

##	fun = () ->
##		this['*'] = () ->

##	self = Opifex('amqp://user:pass@host:5642/domain/resource', null, fun)

##	t.ok(
##		'Source:resource' in logged['INFO'],
##		'called log.info with expected message'
##	)

##	t.end()

##test "opifex parses source if SourceURI is an explicit binding", (t) ->

##	mock.init()

##	bindings = null

##	fun = () ->
##		this['*'] = () ->

##	self = Opifex('amqp://user:pass@host:5642/domain/source/dest/pattern', null, fun)

##	t.ok(
##		'Source:source/dest/pattern' in logged['INFO'],
##		'called log.info with expected message'
##	)

##	t.end()

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

test "defaults correctly set if env vars undefined", (t) ->
	mock.init()
	fun = () -> this['*'] = () -> this.log.debug 'dispatched to "*"'
	self = Opifex(null, null, fun)
	self(new Buffer 0)
	t.ok( 'ForceRawMessages: false' in mock.logged['INFO'], 'ForceRawMessages == false')
	t.ok( 'QueueOpts.durable: false' in mock.logged['INFO'], 'QueueOpts.durable == false')
	t.ok( 'QueueOpts.autoDelete: true' in mock.logged['INFO'], 'QueueOpts.autoDelete == true')
	t.ok( 'ExchangeOpts.durable: false' in mock.logged['INFO'], 'ExchangeOpts.durable == false')
	t.ok( 'ExchangeOpts.autoDelete: true' in mock.logged['INFO'], 'ExchangeOpts.autoDelete == true')
	t.end()

test "env vars override defaults", (t) ->
	mock.init()
	fun = () -> this['*'] = () -> this.log.debug 'dispatched to "*"'
	process.env['FORCE_RAW_MESSAGES'] = 'true'
	process.env['AMQP_QUEUE_DURABLE'] = 'true'
	process.env['AMQP_QUEUE_AUTODELETE'] = 'false'
	process.env['AMQP_EXCHANGE_DURABLE'] = 'true'
	process.env['AMQP_EXCHANGE_AUTODELETE'] = 'false'
	self = Opifex(null, null, fun)
	self(new Buffer 0)
	t.ok( 'ForceRawMessages: true' in mock.logged['INFO'], 'ForceRawMessages == true')
	t.ok( 'QueueOpts.durable: true' in mock.logged['INFO'], 'QueueOpts.durable == true')
	t.ok( 'QueueOpts.autoDelete: false' in mock.logged['INFO'], 'QueueOpts.autoDelete == false')
	t.ok( 'ExchangeOpts.durable: true' in mock.logged['INFO'], 'ExchangeOpts.durable == true')
	t.ok( 'ExchangeOpts.autoDelete: false' in mock.logged['INFO'], 'ExchangeOpts.autoDelete == false')
	delete process.env['FORCE_RAW_MESSAGES']
	delete process.env['AMQP_QUEUE_DURABLE']
	delete process.env['AMQP_QUEUE_AUTODELETE']
	delete process.env['AMQP_EXCHANGE_DURABLE']
	delete process.env['AMQP_EXCHANGE_AUTODELETE']
	t.end()

test "self dispatches to '*' if FORCE_RAW_MESSAGES is true and '*' is a function", (t) ->
	mock.init()
	process.env['FORCE_RAW_MESSAGES'] = 'true'
	fun = () ->
		this.hello = (message...) ->
			this.log.error JSON.stringify message
		this['*'] = () ->
			this.log.debug 'dispatched to "*"'
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		'dispatched to "*"' in mock.logged['DEBUG'],
		'called log.debug with expected message'
	)
	delete process.env['FORCE_RAW_MESSAGES']
	t.end()

test "self logs failure to dispatch to '*' if FORCE_RAW_MESSAGES is true and '*' is not a function", (t) ->
	mock.init()
	process.env['FORCE_RAW_MESSAGES'] = 'true'
	fun = () ->
		this.hello = (message...) ->
			this.log.debug JSON.stringify message
		this['*'] = 1
	self = Opifex(null, null, fun)
	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		'could not dispatch raw to "*"' in mock.logged['ERROR'],
		'called log.error with expected message'
	)
	delete process.env['FORCE_RAW_MESSAGES']
	t.end()

test "mixin sees args if passed", (t) ->
	mock.init()
	fun = (args...) -> this.args = args
	self = Opifex(null, null, fun, 1,2,3)
	t.same([1,2,3], self.args, "self sees array of args passed in")
	t.end()

test "mixin as module", (t) ->
	mock.init()
	ran = false
	mockery = require 'mockery'
	mockery.enable()
	hello = () -> ran = true
	mockery.registerMock 'opifex.hello', hello
	self = Opifex(null, null, "hello")
	t.ok(ran, 'ran mixin required as module')
	mockery.deregisterMock 'opifex.hello'
	t.end()
