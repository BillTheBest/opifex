# opifex

Opifex is a coffeescript module providing base functionality for adapters integrating with the [wot.io](http://wot.io) operating environment.

-----

## Usage

First write a script like:

	Opifex = require 'opifex'
	Opifex('amqp://user:password@host:port/domain/source', 'amqp://user:password@host:port/domain/destination', () ->
		@facit = (command) ->
			console.log "Got command #{command}"
	)


And then on the given host send to the appropriate vhost on the given exchange a message:

	[ "facit", "some command" ]

And it will log "Got command some command" to the console!

Alternatively, a module name may be used instead of a function:

	Opifex = require 'opifex'
	Opifex('amqp://user:password@host:port/domain/source', 'amqp://user:password@host:port/domain/destination', 'myModule')

Will require 'opifex.myModule'

Additional arguments may be passed after either the function or module name, if required by the adapter.

Source and destination URIs may be null or undefined.

## Facilities provided by opifex

Opifex uses the provided function or module as a mixin to its message handler.

In addition Opifex:

* Initializes and manages the specified source and destination bus connections.
* Provides a message-handling method dispatch mechanism. By default, opifex will attempt to interpret JSON arrays as s-expressions and dispatch to the method named in the first array element, if it exists, else to the `*` method. If the message is an s-expression, the array will be passed as a list of arguments to the dispatched method. If configured for raw mode, opifex will always try to dispatch to `*`, with the raw message as the only argument.
* Exposes the following attributes:

  * @log: logger object. See wot-logger for usage.
  * @key: routing key of the current message
  * @headers: headers of the current message
  * @bindings: an object whose attributes describe the configured channels:

			bindings['domain']
			bindings['source']
				exchange: <source exchange>
				key: <binding pattern>
				queue: <queue>
			bindings['sink']
				exchange: <destination exchange>
				key: <routing key>

* Exposes the following methods:
*   @send takes arguments: message[, key]. Sends a message to the configured output exchange. If no key argument, routing key defaults to the configured routing key. If no ouput channel is defined, @send logs a warning. To enable sending binary data over the bus, @send converts message to a Buffer prior to publishing. Serializable javascript objects will be converted to JSON before being encoded as a Buffer. 

bin/opifex is a wrapper script provided as a convenience. It can be called with the function arguments as command-line parameters, in order, or configured with environment variables as below.

## Configuration

All opifex adapters can be configured via the following common environment variables (default values shown):

	`APP`=opifex				Service name override for logging. opifex will use MODULE by default, if set, else 'opifex'. If MODULE is set, and it is desirable for the service name to be different in logs, APP will override MODULE.
	`AMQP_QUEUE_DURABLE`=false		Queues declared are transient unless set to true.
	`AMQP_QUEUE_AUTODELETE`=true		Queues declared are autodelete unless set to false.
	`AMQP_EXCHANGE_DURABLE`=false		Exchanges declared are transient unless set to true.
	`AMQP_EXCHANGE_AUTODELETE`=false	Exchanges declared are not autodelete unless set to true.
	`FORCE_RAW_MESSAGES`=false		Messages will be dispatched to the `*` method with no examination or manipulation if true.

See individual opifex adapter documentation for adapter-specific configuration.

bin/opifex environment variables:

	
	`MODULE`=		Name of module to load (after prepending opifex. - i.e. MODULE=example will require opifex.example)
	`SOURCE_URI`=		Full URI of AMQP source. If undefined, no source channel will be created.
	`DEST_URI`=		Full URI of AMQP destination. If undefined, no destination channel will be created.
	`ARGS`=			Whitespace-separated list of additional arguments, e.g. ARGS='one two three'
	`SOURCE`		DEPRECATED in favor of `SOURCE_URI`.
	`SINK`			DEPRECATED in favor of `DEST_URI`.

