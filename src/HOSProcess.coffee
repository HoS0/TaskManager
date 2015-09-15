util        = require 'util'
request     = require 'request'
moment      = require 'moment'

url = 'http://195.143.229.153:15672/api/queues'
auth = "ali:alikh"

amqp = null
datamanager = 'datamanager'

SendFailResponceBack = (amqp, message, reason) ->
    if message.responceNeeded
        message.error = reason
        message.responceNeeded = false
        if message.sender
            amqp.SendMessage message.sender, message    
            console.log "--- loging --- " + reason + ": " + message

exports.getProcessList = (amqp, message, callback) ->
    request
      method: 'GET',
      url: url,
      headers:
        'Authorization': 'Basic ' + new Buffer(auth, "utf8").toString('base64')
      body: ""
    , (error, response, body) ->

        try
            json = JSON.parse body;
            if response.statusCode isnt 200
                 return SendFailResponceBack amqp, message, "fail to connect to RabbitMQ server"

            services = []
            taskExchanges = []

            for queue in json
                serviceName = queue.name
                serviceNameArray = serviceName.split(".");

                if(serviceNameArray[1])
                    if(queue.consumers isnt 0)
                        services.push {name: serviceNameArray[0], id: serviceNameArray[1]}
                else
                    if(queue.consumers isnt 0)
                        taskExchanges.push {name: serviceNameArray[0]}

                for ex in taskExchanges
                    numInstance = 0
                    for ser in services
                        if ser.name is ex.name
                            numInstance += 1

                    ex.numInstance = numInstance


            res =
                taskExchanges: taskExchanges
                services: services

            if callback
                callback res

        catch e
            SendFailResponceBack amqp, message, "an internal error happened"