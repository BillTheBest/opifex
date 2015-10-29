# Opifex.coffee
#
#	© 2013 Dave Goehrig <dave@dloh.org>
#

# Configure default service name for logging.
# Each opifex should override.
process.env['MODULE'] ||= 'opifex'

Amqp = require('wot-amqplib/event_api').AMQP
url = require 'wot-url'
logger = require 'wot-logger'

# Exchanges and queues are transient by default, configurable by env.
QueueOpts = 
	durable: false
	autoDelete: true

ExchangeOpts =
	durable: false
	autoDelete: false

# Default behavior is to try to interpret messages as s-expressions, configurable by env.
# If in raw mode, message handler will try to dispatch to '*' method.
ForceRawMessages = false

Opifex = (SourceURI,SinkURI,Module,Args...) ->

	log = logger()

	if process.env['FORCE_RAW_MESSAGES'] == 'true'
		ForceRawMessages = true

	QueueOpts.durable = true if process.env['AMQP_QUEUE_DURABLE'] == 'true'
	QueueOpts.autoDelete = false if process.env['AMQP_QUEUE_AUTODELETE']? and process.env['AMQP_QUEUE_AUTODELETE'] != 'true'
	ExchangeOpts.durable = true if process.env['AMQP_EXCHANGE_DURABLE'] == 'true'
	ExchangeOpts.autoDelete = true if process.env['AMQP_EXCHANGE_AUTODELETE'] == 'true'

	log.info "ForceRawMessages: #{ForceRawMessages}"
	log.info "QueueOpts.durable: #{QueueOpts.durable}"
	log.info "QueueOpts.autoDelete: #{QueueOpts.autoDelete}"
	log.info "ExchangeOpts.durable: #{ExchangeOpts.durable}"
	log.info "ExchangeOpts.autoDelete: #{ExchangeOpts.autoDelete}"

	bindings = {}

	# this is our message handler, takes a Buffer, and an object
	self = (message, headers, key)  ->

		$ = arguments.callee

		log.debug("got",message,headers,key)

		return if not message

		$.key = key
		$.headers = headers

		# Raw mode. Try to dispatch to '*' with no examination or manipulation of message.
		if ForceRawMessages
			log.debug 'forcing to raw mode'
			if $.hasOwnProperty("*") and $["*"] instanceof Function
				$["*"].apply $, [ message ]
			else
				log.error 'could not dispatch raw to "*"'

		else
			# Try to interpret message as JSON. If it isn't, try to dispatch to '*'.
			try
				json = JSON.parse message.toString()
			catch e
				if $.hasOwnProperty("*") and $["*"] instanceof Function
					$["*"].apply $, [ message ]
				else
					log.warn 'could not dispatch binary to "*"'
				return

			# If message is an array, try to interpret as s-exp.
			# In checking to see if the first element is a method, try to avoid accidental matches.
			# If no matching method is found, try to dispatch to '*'.
			if json instanceof Array
				if json.length > 0 and $.hasOwnProperty(json[0]) and $[json[0]] instanceof Function
					method = json.shift()
					$[method].apply $, json
				else if $.hasOwnProperty("*") and $["*"] instanceof Function
					$["*"].apply $, json
				else
					log.warn "could not dispatch #{JSON.stringify json}"

			# Not an array, so no method matching. Try to dispatch to '*'.
			else if $.hasOwnProperty("*") and $["*"] instanceof Function
				$["*"].apply $, [ json ]
			else
				log.warn "could not dispatch #{JSON.stringify json}"

	self.log = log

	self.bindings = bindings

	self.send = (message) ->
		log.warn "send called with no output channel. message:#{message}"

	mixin = (module) ->
		return if not module
		if typeof(module) == 'function'
			log.info "mixing in function"
			module.apply(self,Args)
		else
			log.info "mixing in opifex.#{module}"
			(require "opifex.#{module}").apply(self,Args)

	# We want to mixin after channels are initialized.
	# Since we don't know which are required, and it's a race to initialized,
	# we use flags to indicate status.
	SourceIsReady = false
	SinkIsReady = false

	# We currently only support connecting to a single vhost,
	# so it shouldn't matter if we get the AMQP URI from source or sink
	# Maybe we should check they're the same if both exist.
	if SourceURI
		src = url.parse SourceURI
		Source = src.source || src.resource
		Url = "#{src.protocol}://#{src.user}:#{src.password}@#{src.host}:#{src.port}/#{src.account}"
		bindings['domain'] = src.account
	else
		SourceIsReady = true

	log.info "Source:#{Source}"

	if SinkURI
		dst = url.parse SinkURI
		Sink = dst.sink || dst.resource
		Url = "#{dst.protocol}://#{dst.user}:#{dst.password}@#{dst.host}:#{dst.port}/#{dst.account}"
		bindings['domain'] = dst.account
	else
		SinkIsReady = true

	log.info "Sink:#{Sink}"

	if not Source and not Sink
		mixin Module
	else
		# We require at least one channel. Connect to RabbitMQ, initialize channel(s), then mixin

		# sets up a exchange / key / queue binding
		self.bind = (channel,exchange,key,queue) ->
			channel.on 'exchange_declared',  (m,ex) ->
				if ex == exchange
					channel.removeListener('exchange_declared', arguments.callee)
					channel.declareQueue queue, QueueOpts
			channel.on 'queue_declared', (m,q) ->
				if q == queue
					channel.removeListener('queue_declared', arguments.callee)
					channel.bindQueue queue, exchange, key, {}
			channel.on 'queue_bound', (m, a) ->
				if a[0] == queue && a[1] == exchange && a[2] == key
					channel.removeListener('queue_bound', arguments.callee)
					channel.emit 'bound', exchange, key, queue
			channel.declareExchange exchange, 'topic', ExchangeOpts

		# connect to RabbitMQ
		log.info "Url:#{Url}"
		connection = new Amqp(Url)

		# bail on error
		connection.on 'error', (Message) ->
			log.error "error #{Message }"
			process.exit 1
		
		# bail on loss of connectivity
		connection.on 'closed', () ->
			log.error "got connection close"
			process.exit 2
	
		connection.on 'connected', () ->
			log.info "connected"

			if Source
				# the input channel will be used for all inbound messages
				input = connection.createChannel()
				log.debug "created input"

				[ SourceExchange, SourceQueue, SourceKey ] = Source.split '/'
				SourceQueue ||= SourceExchange
				SourceKey ||= '#'
				bindings['source'] =
					exchange: SourceExchange
					key: SourceKey
					queue: SourceQueue

				# input error
				input.on 'error', (e) ->
					log.error "input error #{e}"
					process.exit 1

				# once the channel is opened, we declare the source bindings
				input.on 'channel_opened', () ->
					log.debug "input opened"
					# ensure the resources and binding exist
					self.bind input, SourceExchange, '#', SourceExchange
					if SourceExchange != SourceQueue
						self.bind input, SourceQueue, '#', SourceQueue
						self.bind input, SourceExchange, SourceKey, SourceQueue

				# once we're bound, setup consumption
				input.on 'bound', (exchange, key, queue) ->
					log.debug "input resource bound #{exchange}, #{key}, #{queue}"
					if not SourceIsReady and exchange == SourceExchange and queue == SourceQueue and key == SourceKey
						log.debug "source bound #{exchange}, #{key}, #{queue}"
						input.consume SourceQueue, { noAck: false }

				# once we have our subscription, we'll setup the message handler
				input.on 'subscribed', (m,queue) ->
					log.debug "input subscribed"

					# Finally mix in the behaviors either by method or module
					SourceIsReady = true
					mixin Module if SinkIsReady

					input.on 'message', (m) ->
						self(m.content,m.properties.headers,m.fields.routingKey)
						input.ack(m)	 # NB: we ack after invoking our handler!
				
				# finally open the channel
				input.open()

			if Sink
				# the output channel will be used for all outbound messages
				output = connection.createChannel()
				log.debug "output created"

				[ SinkExchange, SinkKey ] = Sink.split '/'
				SinkKey ||= '#'
				bindings['sink'] =
					exchange: SinkExchange
					key: SinkKey

				output.on 'error', (e) ->
					log.error "output error #{e}"
					process.exit 1

				# once the channel is opened, we declare the sink binding
				output.on 'channel_opened', () ->
					log.debug "output opened"
					# ensure the resource exists
					self.bind output, SinkExchange, '#', SinkExchange
				
				output.on 'bound', (exchange, key, queue) ->
					log.debug "output resource bound #{exchange}, #{key}, #{queue}"

					# once our exchange is declared we can expose the send interface
					self.send = (msg, meta) ->
						if msg is undefined or msg is null
							log.warn 'tried to send with no message'
							return
						try msg = JSON.stringify msg if typeof msg is 'object' and not Buffer.isBuffer(msg)
						meta ||= SinkKey
						# make sure our exchange is still there if it's autodelete
						output.declareExchange(SinkExchange, 'topic', ExchangeOpts) if ExchangeOpts.autoDelete
						log.debug "sending message #{SinkExchange} #{meta} #{msg}"
						output.publish SinkExchange, meta, new Buffer(msg), {}

					# Finally mix in the behaviors either by method or module
					SinkIsReady = true
					mixin Module if SourceIsReady

				# now we open our channel
				output.open()

	self

module.exports = Opifex

