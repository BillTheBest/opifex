Opifex = require 'opifex'

Opifex('amqp://test:test@172.17.42.1:5672/wot/test01.source', 'amqp://test:test@172.17.42.1:5672/wot/test01.sink/test', () ->
	this.hello = (message...) ->
		console.log message
		this.send JSON.stringify message
	this['*'] = (message...) ->
		if message[0] instanceof Buffer
			console.log message.toString()
		else
			console.log JSON.stringify message
)
