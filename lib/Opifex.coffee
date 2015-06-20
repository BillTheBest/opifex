# Opifex.coffee
#
#	© 2013 Dave Goehrig <dave@dloh.org>
#
Amqp = require('wot-amqplib/event_api').AMQP
url = require 'wot-url'

Opifex = (SourceURI,SinkURI,Module,Args...) ->

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
	else
		SourceIsReady = true

	console.log "Source:", Source

	if SinkURI
		dst = url.parse SinkURI
		Sink = dst.sink || dst.resource
		Url = "#{dst.protocol}://#{dst.user}:#{dst.password}@#{dst.host}:#{dst.port}/#{dst.account}"
	else
		SinkIsReady = true

	console.log "Sink:", Sink


	# this is our message handler, takes a Buffer, and an object
	self = (message, headers)  ->
		console.log("got",message,headers)
		$ = arguments.callee

		return if not message

		# Raw mode. Try to dispatch to '*' with no examination or manipulation of message.
		if process.env['FORCE_RAW_MESSAGES']?
			if $.hasOwnProperty("*") and $["*"] instanceof Function
				$["*"].apply $, [ message ]
			else
				console.log '[opifex] could not dispatch raw to "*"'

		else
			# Try to interpret message as JSON. If it isn't, try to dispatch to '*'.
			try
				json = JSON.parse message.toString()
			catch e
				if $.hasOwnProperty("*") and $["*"] instanceof Function
					$["*"].apply $, [ message ]
				else
					console.log '[opifex] could not dispatch binary to "*"'
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
					console.log "[opifex] could not dispatch #{JSON.stringify json}"

			# Not an array, so no method matching. Try to dispatch to '*'.
			else if $.hasOwnProperty("*") and $["*"] instanceof Function
				$["*"].apply $, [ json ]
			else
				console.log "[opifex] could not dispatch #{JSON.stringify json}"

	self.send = (message) ->
		console.log "[opifex] send called with no output channel. message:#{message}"

	mixin = (module) ->
		return if not module
		if typeof(module) == 'function'
			console.log "mixing in function" #, module
			module.apply(self,Args)
		else
			console.log "mixing in opifex.#{module}"
			(require "opifex.#{module}").apply(self,Args)

	if not Source and not Sink
		mixin Module
	else
		# We require at least one channel. Connect to RabbitMQ, initialize channel(s), then mixin

		# connect to RabbitMQ
		console.log "Url:#{Url}"
		connection = new Amqp(Url)

		# bail on error
		connection.on 'error', (Message) ->
			console.log "[opifex] error #{Message }"
			process.exit 1
		
		# bail on loss of connectivity
		connection.on 'closed', () ->
			console.log "[opifex] got connection close"
			process.exit 2
	
		connection.on 'connected', () ->
			console.log "connected"

			if Source
				# the input channel will be used for all inbound messages
				input = connection.createChannel()
				console.log "created input"

				[ SourceExchange, SourceQueue, SourceKey ] = Source.split '/'
				SourceQueue ||= SourceExchange
				SourceKey ||= '#'

				# input error
				input.on 'error', (e) ->
					console.log "[opifex] input error #{e}"

				# once the channel is opened, we declare the input queue
				input.on 'channel_opened', () ->
					console.log "input opened"
					input.declareQueue SourceQueue, {}

				# once we have the queue declared, we will start the subscription
				input.on 'queue_declared', (m,queue) ->
					console.log "input queue declared"
					input.declareExchange SourceExchange, 'topic', {}

				# exchange declared
				input.on 'exchange_declared', (m,exchange) ->
					console.log "input exchange declared #{exchange}"
					if exchange == SourceExchange
						input.bindQueue SourceQueue, SourceExchange, SourceKey, {}
				
				# once we're bound, setup consumption
				input.on 'queue_bound', (m, a) ->
					console.log "input queue bound #{a}"
					input.consume a[0], { noAck: false }

				# once we have our subscription, we'll setup the message handler
				input.on 'subscribed', (m,queue) ->
					console.log "input subscribed"
					# Finally mix in the behaviors either by method or module
					SourceIsReady = true
					mixin Module if SinkIsReady

					input.on 'message', (m) ->
						self(m.content,m.fields.headers)
						input.ack(m)	 # NB: we ack after invoking our handler!
				
				# finally open the channel
				input.open()

			if Sink
				# the output channel will be used for all outbound messages
				output = connection.createChannel()
				console.log "output created"

				[ SinkExchange, SinkKey ] = Sink.split '/'
				SinkKey ||= '#'

				output.on 'error', (e) ->
					console.log "[opifex] output error #{e}"

				# by declaring our exchange we're assured that it will exist before we send
				output.on 'channel_opened', () ->
					console.log "output opened"
					output.declareExchange SinkExchange, 'topic', {}
				
				# Our opifex has a fixed route out.
				output.on 'exchange_declared', (m, exchange) ->
					console.log "output exchange declared #{exchange}"
					output.declareQueue exchange, {}

				output.on 'queue_declared', (m,queue) ->
					console.log "output queue declared #{queue}"
					output.bindQueue queue,SinkExchange,'#', {}

				output.on 'queue_bound', (m,a) ->
					console.log "output queue bound"

					# once our exchange is declared we can expose the send interface
					self.send = (msg, meta) ->
						meta ||= SinkKey
						console.log "sending message #{SinkExchange} #{meta} #{msg}"
						output.publish SinkExchange, meta, new Buffer(msg), {}

					# Finally mix in the behaviors either by method or module
					SinkIsReady = true
					mixin Module if SourceIsReady

				# now we open our channel
				output.open()

	self

module.exports = Opifex

