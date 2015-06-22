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

test "self logs error if s-exp and method does not exist and '*' is a not function", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this['*'] = x

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		console.log.calledWith('[opifex] could not dispatch ["hello","there","world"]'),
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

test "self logs failure to dispatch to '*' if FORCE_RAW_MESSAGES is set and '*' is not a function", (t) ->

	process.env['FORCE_RAW_MESSAGES'] = 1
	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = () ->
		x = 1
		this.hello = (message...) ->
			console.log JSON.stringify message
		this['*'] = 1

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])
	t.ok(
		console.log.calledWith('[opifex] could not dispatch raw to "*"'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

test "mixin sees args if passed", (t) ->

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	fun = (args...) ->
		this.args = args

	self = Opifex(null, null, fun, 1,2,3)
	console.log self.args

	t.same([1,2,3], self.args, "self sees array of args passed in")

	console.log.restore()
	console.log = log
	t.end()

test "mixin as module", (t) ->

	mockery = require 'mockery'

	mockery.enable()

	hello = () ->
		console.log 'hello world'

	mockery.registerMock 'opifex.hello', hello

	log = console.log
	console.log = () ->
	sinon.spy(console, 'log')

	self = Opifex(null, null, "hello")

	t.ok(
		console.log.calledWith('hello world'),
		'called console.log with expected message'
	)

	console.log.restore()
	console.log = log
	t.end()

