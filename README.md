# opifex

Opifex is a node.js module providing base functionality for adapters integrating with the [wot.io](http://wot.io) operating environment.

## Usage

```
opifex = require 'opifex'
opifex 'amqp://user:password@host:port/domain/source', 'amqp://user:password@host:port/domain/destination', () ->
	@foo = (args...) ->
		console.log "Got foo message with args: #{JSON.stringify args}"
```

## Facilities provided by opifex

* Accepts a function or module and apply it as a mixin to its message handler.
* Initializes and manages the specified source and destination bus connections.
* Provides a message-handling method dispatch mechanism. By default, opifex will attempt to interpret JSON arrays as s-expressions and dispatch to the method named in the first array element, if it exists, else to the `*` method. If the message is an s-expression, the array will be passed as a list of arguments to the dispatched method. If configured for raw mode, opifex will always try to dispatch to `*`, with the raw message as the only argument.

## Properties

* `log` - logger object. See `wot-logger` for usage.
* `key` - routing key of the current message. Note that this can differ from the configured routing key. See `bindings`.
* `headers` - headers of the current message.
* `bindings` - an object whose attributes describe the configured channels. The bindings property is an object with the following keys
```
{
	"domain": "",
	"source": {
		"exchange": "configured source exchange",

		"key": "configured binding pattern",
		o = (args...) ->¬
		"queue": "configured source queue"
	},
	"sink": {
		"exchange": "configured destination exchange",
		"key": "configured routing key"
	}
}
```

## Methods

* `send(message[, key])` - Sends a message to the configured output exchange.
If no key argument, routing key defaults to the configured routing key.
If no ouput channel is defined, `send` logs a warning.
To enable sending binary data over the bus, `send` converts message to a `Buffer` prior to publishing.
Serializable javascript objects will be converted to JSON before being encoded as a `Buffer`.

## Scripts

The `bin/opifex` wrapper script has been provided as a convenience.
It can be called with the function arguments as command-line parameters, in order, or configured with environment variables as below.

## Environment

All opifex adapters can be configured via the following common environment variables (default values shown)

| Name | Default | Description |
| ---- | ------- | ----------- |
| `APP` | opifex | Service name override for logging. opifex will use the value of `MODULE` by default, if set, else `'opifex'`. If `MODULE` is set, and it is desirable for the service name to be different in logs, `APP` will override `MODULE`. |
| `AMQP_QUEUE_DURABLE` | false | Queues declared are transient unless set to true. |
| `AMQP_QUEUE_AUTODELETE` | true | Queues declared are autodelete unless set to false. |
| `AMQP_EXCHANGE_DURABLE` | false | Exchanges declared are transient unless set to true. |
| `AMQP_EXCHANGE_AUTODELETE` | false | Exchanges declared are not autodelete unless set to true. |
| `DEBUG_LOG_MESSAGE_CONTENT` | false | `send(message)` will debug log the contents of message if true. false is convenient with binary data. |
| `FORCE_RAW_MESSAGES` | false | Messages will be dispatched to the `*` method with no examination or manipulation if true. |

See individual adapter documentation for adapter-specific configuration.

In addition, `bin/opifex` also respects the following environment variables

| Name | Default | Description |
| ---- | ------- | ----------- |
| `MODULE` | | Name of module to load after prepending with "opifex." For example, `MODULE=example` would result in `require 'opifex.example'` |
| `SOURCE_URI` | | Full URI of AMQP source. If undefined, no source channel will be created. |
| `DEST_URI` | | Full URI of AMQP destination. If undefined, no destination channel will be created. |
| `ARGS` | | Whitespace-separated list of additional arguments, e.g. `ARGS='one two three'` |
| `SOURCE` | | **Deprecated** in favor of `SOURCE_URI`. |
| `SINK` | | **Deprecated**  in favor of `DEST_URI`. |

## Example

Create a node.js module named `opifex.test` with an `index.coffee` something like

```
module.exports = opifex = () ->
	@hello = (name) -> console.log "Hello, #{name}"
	@
```

and then run it as the opifex mixin via something like 


```
$ bin/opifex 'amqp://user:password@host:port/account/source', 'amqp://user:password@host:port/account/destination' 'test'
```

And then send a message like this to the appropriate vhost on the given exchange:

```
[ "hello", "world" ]
```

And it will log the obligatory `Hello, world` message to the console.

Alternatively, a function could be passed directly instead of a module.
