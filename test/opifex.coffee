# Set up mocking of wot-logger in opifex
logged = {
	"ERROR": [],
	"WARN":  [],
	"INFO":  [],
	"DEBUG": []
}
proxyquire = require('proxyquire').noCallThru()
proxyquire.load 'opifex', {"wot-logger":
	() ->
		log: (level, message) ->
			logged[level.toUpperCase()].push message
		error: (message) ->
               		this.log 'error', message
		warn: (message) ->
               		this.log 'warn', message
		info: (message) ->
               		this.log 'info', message
		debug: (message) ->
               		this.log 'debug', message
}

Opifex = require 'opifex'

test = require('tap').test

test "self is a function with no mixin", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }
	self = Opifex()
	t.equals(typeof(self), 'function', "self is a function")
	t.end()

test "send() calls log.warn if no output channel is defined", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		this.send "we are alive"

	self = Opifex(null, null, fun)

	self()
	
	t.ok(
		'send called with no output channel. message:we are alive' in logged['WARN']
		'called log.warn with expected message'
	)

	t.end()

test "self returns if no message", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		this.send "we are alive"

	self = Opifex(null, null, fun)

	t.equals( self(), undefined, 'self returns undefined')

	t.end()

test "self can't dispatch binary to '*' if '*' not defined", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1

	self = Opifex(null, null, fun)

	self(new Buffer(10))

	t.ok(
		'could not dispatch binary to "*"' in logged['WARN'],
		'called log.warn with expected message'
	)

	t.end()

test "self can't dispatch binary to '*' if '*' not a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = x

	self = Opifex(null, null, fun)

	self(new Buffer(10))

	t.ok(
		'could not dispatch binary to "*"' in logged['WARN'],
		'called log.warn with expected message'
	)

	t.end()

test "self dispatches binary to '*' if '*' is a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = () ->
			this.log.debug 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer(10))

	t.ok(
		'dispatched to "*"' in logged['DEBUG'],
		'called log.debug with expected message'
	)

	t.end()

test "self can't dispatch non-sexp JSON to '*' if '*' not defined", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify {"hello": "world"})

	t.ok(
		'could not dispatch {"hello":"world"}' in logged['WARN'],
		'called log.warn with expected message'
	)

	t.end()

test "self can't dispatch non-sexp JSON to '*' if '*' not a function", (t) ->


	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = x

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify {"hello": "world"})

	t.ok(
		'could not dispatch {"hello":"world"}' in logged['WARN'],
		'called log.warn with expected message'
	)

	t.end()

test "self dispatches non-sexp JSON to '*' if '*' is a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = () ->
			this.log.debug 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify {"hello": "world"})

	t.ok(
		'dispatched to "*"' in logged['DEBUG'],
		'called log.debug with expected message'
	)

	t.end()

test "self dispatches empty array to '*' if '*' is a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = () ->
			this.log.debug 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify [])

	t.ok(
		'dispatched to "*"' in logged['DEBUG'],
		'called log.debug with expected message'
	)

	t.end()

test "self dispatches s-exp to '*' if method does not exist and '*' is a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = () ->
			this.log.debug 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "world"])

	t.ok(
		'dispatched to "*"' in logged['DEBUG'],
		'called log.debug with expected message'
	)

	t.end()

test "self dispatches s-exp to method if method exists and is a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this.hello = (message...) ->
			this.log.debug JSON.stringify message
		this['*'] = () ->
			this.log.error 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])

	t.ok(
		'["there","world"]' in logged['DEBUG'],
		'called log.debug with expected message'
	)

	t.end()

test "self dispatches s-exp to '*' if method does not exist and '*' is a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = (message...) ->
			console.log 'YOU ARE HERE', message
			this.log.debug JSON.stringify message

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])

	t.ok(
		'["hello","there","world"]' in logged['DEBUG'],
		'called log.debug with expected message'
	)

	t.end()

test "self logs error if s-exp and method does not exist and '*' is a not function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = () ->
		x = 1
		this['*'] = x

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])

	t.ok(
		'could not dispatch ["hello","there","world"]' in logged['WARN'],
		'called log.warn with expected message'
	)

	t.end()

test "self dispatches to '*' if FORCE_RAW_MESSAGES is set and '*' is a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	process.env['FORCE_RAW_MESSAGES'] = 1

	fun = () ->
		x = 1
		this.hello = (message...) ->
			this.log.error JSON.stringify message
		this['*'] = () ->
			this.log.debug 'dispatched to "*"'

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])

	t.ok(
		'dispatched to "*"' in logged['DEBUG'],
		'called log.debug with expected message'
	)

	t.end()

test "self logs failure to dispatch to '*' if FORCE_RAW_MESSAGES is set and '*' is not a function", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	process.env['FORCE_RAW_MESSAGES'] = 1

	fun = () ->
		x = 1
		this.hello = (message...) ->
			this.log.debug JSON.stringify message
		this['*'] = 1

	self = Opifex(null, null, fun)

	self(new Buffer JSON.stringify ["hello", "there", "world"])

	t.ok(
		'could not dispatch raw to "*"' in logged['ERROR'],
		'called log.error with expected message'
	)

	t.end()

test "mixin sees args if passed", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	fun = (args...) ->
		this.args = args

	self = Opifex(null, null, fun, 1,2,3)

	t.same([1,2,3], self.args, "self sees array of args passed in")

	t.end()

test "mixin as module", (t) ->

	logged = { "ERROR": [], "WARN":  [], "INFO":  [], "DEBUG": [] }

	ran = false

	mockery = require 'mockery'

	mockery.enable()

	hello = () ->
		ran = true

	mockery.registerMock 'opifex.hello', hello

	self = Opifex(null, null, "hello")

	t.ok( ran, 'ran mixin required as module')

	t.end()

