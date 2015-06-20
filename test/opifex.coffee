Opifex = require 'opifex'
sinon = require 'sinon'
test = require('tap').test

test "self is a function with no mixin", (t) ->

	log = console.log
	console.log = () ->

	self = Opifex()

	t.equals(typeof(self), 'function', "self is a function")
	console.log = log
	t.end()

test "send() calls console.log if no output channel is defined", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		this.send "we are alive"

	self = Opifex(null, null, fun)

	self(new Buffer(10))
	t.ok(
		console.log.calledWith("[opifex] send called with no output channel. message:we are alive"),
		'called console.log with expected error'
	)
	console.log.restore()
	console.log = log
	t.end()

test "self returns if no message", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		this.send "we are alive"

	self = Opifex(null, null, fun)

	self()
	t.equals( self(), undefined, 'self returns undefined')
	console.log.restore()
	console.log = log
	t.end()

test "self can't dispatch binary to '*' if '*' not defined", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1

	self = Opifex(null, null, fun)

	self(new Buffer(10))
	t.ok(
		console.log.calledWith('[opifex] could not dispatch binary to "*"'),
		'called console.log with expected error'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self can't dispatch binary to '*' if '*' not a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = x

	self = Opifex(null, null, fun)

	self(new Buffer(10))
	t.ok(
		console.log.calledWith('[opifex] could not dispatch binary to "*"'),
		'called console.log with expected error'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self dispatches binary to '*' if '*' is a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = () ->
			console.log 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer(10))
	t.ok(
		console.log.calledWith('dispatched to "*"'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self can't dispatch non-sexp JSON to '*' if '*' not defined", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify {"hello": "world"})
	t.ok(
		console.log.calledWith('[opifex] could not dispatch {"hello":"world"}'),
		'called console.log with expected error'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self can't dispatch non-sexp JSON to '*' if '*' not a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = x

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify {"hello": "world"})
	t.ok(
		console.log.calledWith('[opifex] could not dispatch {"hello":"world"}'),
		'called console.log with expected error'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self dispatches non-sexp JSON to '*' if '*' is a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = () ->
			console.log 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify {"hello": "world"})
	t.ok(
		console.log.calledWith('dispatched to "*"'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self dispatches empty array to '*' if '*' is a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = () ->
			console.log 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify [])
	t.ok(
		console.log.calledWith('dispatched to "*"'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self dispatches s-exp to '*' if method does not exist and '*' is a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = () ->
			console.log 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "world"])
	t.ok(
		console.log.calledWith('dispatched to "*"'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self dispatches s-exp to method if method exists and is a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this.hello = (message...) ->
			console.log JSON.stringify message
		this['*'] = () ->
			console.log 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		console.log.calledWith('["there","world"]'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self dispatches s-exp to '*' if method does not exist and '*' is a function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = (message...) ->
			console.log JSON.stringify message

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		console.log.calledWith('["hello","there","world"]'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

test "self dispatches to '*' if FORCE_RAW_MESSAGES is set and '*' is a function", (t) ->

	process.env['FORCE_RAW_MESSAGES'] = 1
	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this.hello = (message...) ->
			console.log JSON.stringify message
		this['*'] = () ->
			console.log 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		console.log.calledWith('dispatched to "*"'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

