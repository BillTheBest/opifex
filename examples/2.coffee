Opifex = require 'opifex'

process.env['LOG_LEVEL'] = 'debug'

Opifex('amqp://test:test@172.17.42.1:5672/wot/test01.source/test02.source/test', 'amqp://test:test@172.17.42.1:5672/wot/test01.sink/test', () ->
	this.hello = (message...) ->
		this.log.debug 'bindings:', this.bindings
		this.log.debug 'message:', message
		this.log.debug 'key:', this.key
		this.send JSON.stringify message
	this['*'] = (message...) ->
		if message[0] instanceof Buffer
			console.log message.toString()
		else
			console.log JSON.stringify message
)
