#!/usr/bin/env coffee
module.exports.published = {}
module.exports.bound = []
module.exports.subscribed = []
module.exports.logged = {
	"ERROR": [],
	"WARN":  [],
	"INFO":  [],
	"DEBUG": []
}

module.exports.init = () ->
	module.exports.published = {}
	module.exports.bound = []
	module.exports.subscribed = []
	module.exports.logged = {
		"ERROR": [],
		"WARN":  [],
		"INFO":  [],
		"DEBUG": []
	}

module.exports.logger = () ->
	{
		log: (level, message) ->
			module.exports.logged[level.toUpperCase()].push message
		error: (message) ->
			@log 'error', message
		warn: (message) ->
			@log 'warn', message
		info: (message) ->
			@log 'info', message
		debug: (message) ->
			@log 'debug', message
	}


EventEmitter = (require 'events').EventEmitter
inherits = require 'inherits'

Channel = () ->
	self = this

	self.nack = (message, allUpTo, requeue) ->
	self.nackAll = (requeue) ->
	self.rpc = (method, fields, expect, response, args) ->
	self.open = () ->
		self.emit 'channel_opened'
	self.close = () ->
		self.emit('channel_closed')
	self.declareQueue = (queue, options) ->
		self.emit 'queue_declared', undefined, queue
	self.checkQueue = (queue) ->
	self.deleteQueue = (queue, options) ->
	self.purgeQueue = (queue) ->
	self.bindQueue = (queue, source, pattern, argt) ->
		module.exports.bound.push [queue, source, pattern]
		self.emit 'queue_bound', undefined, [queue, source, pattern]
	self.unbindQueue = (queue, source, pattern, argt) ->
	self.declareExchange = (exchange, type, options) ->
		self.emit 'exchange_declared', undefined, exchange
	self.checkExchange = (exchange) ->
	self.deleteExchange = (exchange, options) ->
	self.bindExchange = (dest, source, pattern, argt) ->
	self.unbindExchange = (dest, source, pattern, argt) ->
	self.publish = (exchange, routingKey, content, options) ->
		module.exports.published[routingKey] = [] if not module.exports.published[routingKey]?
		module.exports.published[routingKey].push content
	self.sendToQueue = (queue, message, options) ->
	self.consume = (queue, options) ->
		module.exports.subscribed.push queue
		self.emit 'subscribed', {fields:{}} ,queue
	self.cancel = (consumerTag) ->
	self.get = (queue, options) ->
	self.ack = (message, allUpTo) ->
	self.ackAll = () ->
	self.nack = (message, allUpTo, requeue) ->
	self.nackAll = (requeue) ->
	self.reject = (message, requeue) ->
	self.prefetch = (count, global) ->
	self.recover = () ->
	self.error = () ->
		self.emit('error', 'test')
	self.confirmSelect = (nowait) ->

	# conditionally emit error event for tests
	if process.env['MOCK_CHANNEL_EMIT_ERROR'] == 'true'
		setTimeout self.error, 100

	return self

inherits(Channel, EventEmitter)

# This is a real bare-bones AMQP
module.exports.AMQP = (url) ->
	self = this

	self.connect = () ->
		self.emit('connected')
	self.close = () ->
		self.emit('closed')
	self.error = () ->
		self.emit('error', 'test')
	self.createChannel = () ->
		new Channel()

	# connect event need to fire after new() and sets up the listeners.
	setTimeout self.connect, 10

	# conditionally emit closed and error events for tests
	if process.env['MOCK_CONNECTION_EMIT_CLOSED'] == 'true'
		setTimeout self.close, 100

	if process.env['MOCK_CONNECTION_EMIT_ERROR'] == 'true'
		setTimeout self.error, 100

	# force the event loop to run until we want to exit
	require('net').createServer().listen()

	return self

inherits(module.exports.AMQP, EventEmitter)
