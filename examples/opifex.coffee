Opifex = require 'opifex'

module = () ->
	this.hello = (message...) ->
		console.log message
	this['*'] = (message...) ->
		if message[0] instanceof Buffer
			console.log message.toString()
		else
			console.log JSON.stringify message


process.env['APP'] = 'opifex'
source = process.env['SOURCE'] || 'amqp://test:test@172.17.42.1:5672/wot/test01.source'
sink = process.env['SINK'] || 'amqp://test:test@172.17.42.1:5672/wot/test01.sink'
args = []

Opifex.apply(Opifex,[ source, sink, module, args ])
