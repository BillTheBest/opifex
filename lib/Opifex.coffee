# Opifex.coffee
#
#	© 2013 Dave Goehrig <dave@dloh.org>
#

# Configure default service name for logging.
# Each opifex should override.
process.env['APP'] ||= 'opifex'

QueueOpts = 
	durable: Boolean process.env['AMQP_QUEUE_DURABLE'] || false
	autoDelete: Boolean process.env['AMQP_QUEUE_AUTODELETE'] || true

ExchangeOpts = 
	durable: Boolean process.env['AMQP_EXCHANGE_DURABLE'] || false
	autoDelete: Boolean process.env['AMQP_EXCHANGE_AUTODELETE'] || true

Amqp = require('wot-amqplib/event_api').AMQP
url = require 'wot-url'
logger = require 'wot-logger'

Opifex = (SourceURI,SinkURI,Module,Args...) ->

	log = logger()

	bindings = {}

	# this is our message handler, takes a Buffer, and an object
	self = (message, headers, key)  ->

		$ = arguments.callee

		log.debug("got",message,headers,key)

		return if not message

		$.key = key
		$.headers = headers

		# Raw mode. Try to dispatch to '*' with no examination or manipulation of message.
		if process.env['FORCE_RAW_MESSAGES']?
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

				DestinationResourceIsBound = false
				SourceResourceIsBound = false

				# input error
				input.on 'error', (e) ->
					log.error "input error #{e}"

				# once the channel is opened, we declare the input queue
				input.on 'channel_opened', () ->
					log.debug "input opened"
					input.declareQueue SourceQueue, QueueOpts

				# once we have the queue declared, we will start the subscription
				input.on 'queue_declared', (m,queue) ->
					log.debug "input queue declared #{queue}"
					# Ensure that we have the default resource binding for the queue
					if queue == SourceQueue and not DestinationResourceIsBound
						input.on 'exchange_declared', (m,exchange) ->
							log.debug "input exchange declared #{exchange}"
							if exchange == SourceQueue
								input.bindQueue SourceQueue, SourceQueue, '#', {}
					
						# once we're bound, setup consumption
						input.on 'queue_bound', (m, a) ->
							DestinationResourceIsBound = true
							log.debug "input resource bound #{a}"
							if a[0] == SourceQueue and a[1] == SourceQueue
								log.debug "subscribing to #{a}"
								input.consume a[0], { noAck: false }

						input.declareExchange SourceQueue, 'topic', ExchangeOpts

				# once we have our subscription, we'll setup the message handler
				input.on 'subscribed', (m,queue) ->
					log.debug "input subscribed"
					# If source and dest don't match,
					# we need to ensure the default resource binding for the exchange
					if SourceExchange != SourceQueue
						input.on 'queue_declared', (m,queue) ->
							log.debug "input queue declared #{queue}"
							input.on 'exchange_declared', (m,exchange) ->
								log.debug "input exchange declared #{exchange}"
								if queue == SourceExchange and not SourceResourceIsBound
									input.on 'queue_bound', (m, a) ->
										if a[0] == SourceExchange and a[1] == SourceExchange and a[2] == '#'
											SourceResourceIsBound = true
											log.debug "input source resource bound #{a}"
											# We also need the explicit binding of source and dest
											input.bindQueue SourceQueue, SourceExchange, SourceKey, {}
									input.bindQueue SourceExchange, SourceExchange, '#', {}

							input.declareExchange SourceExchange, 'topic', ExchangeOpts

						input.declareQueue SourceExchange, QueueOpts

					# Finally mix in the behaviors either by method or module
					SourceIsReady = true
					mixin Module if SinkIsReady

					input.on 'message', (m) ->
						self(m.content,m.fields.headers,m.fields.routingKey)
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

				# by declaring our exchange we're assured that it will exist before we send
				output.on 'channel_opened', () ->
					log.debug "output opened"
					output.declareExchange SinkExchange, 'topic', ExchangeOpts
				
				# Our opifex has a fixed route out.
				output.on 'exchange_declared', (m, exchange) ->
					log.debug "output exchange declared #{exchange}"
					output.declareQueue exchange, QueueOpts

				output.on 'queue_declared', (m,queue) ->
					log.debug "output queue declared #{queue}"
					output.bindQueue queue,SinkExchange,'#', {}

				output.on 'queue_bound', (m,a) ->
					log.debug "output queue bound"

					# once our exchange is declared we can expose the send interface
					self.send = (msg, meta) ->
						meta ||= SinkKey
						log.debug "sending message #{SinkExchange} #{meta} #{msg}"
						output.publish SinkExchange, meta, new Buffer(msg), {}

					# Finally mix in the behaviors either by method or module
					SinkIsReady = true
					mixin Module if SourceIsReady

				# now we open our channel
				output.open()

	self

module.exports = Opifex

