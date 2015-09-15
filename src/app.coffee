amqp            = require 'AMQP-boilerplate'
Guid            = require 'guid'
LocalProcess    = require('./LocalProcess')
HOSProcess      = require('./HOSProcess')

name = 'taskManager'
DataManager = 'datamanager'

console.log "------------ " + name + " - " + "has started"

amqp.Initialize name, () ->
    amqp.CreateRequestQueue name, (message) ->
        #console.log message
        parseMessage message

    msgtest =
        action: "create"
        type: "task"
        responceNeeded: true,
        sender: "someservice."+Guid.create()
        id: Guid.create()
        payload: 
            serviceName: "ping"
            servicePath: ""
            action: "start"
            startDate: Date.now()
            args: ['google.com']

    msgtest2 =
        action: "retrieve"
        type: "task"
        responceNeeded: true,
        sender: "someservice."+Guid.create()
        id: Guid.create()
        payload: 
            username: "ali"
            password: "alikh"

    msgtest3 =
        action: "retrieve"
        type: "HOSProcess"
        responceNeeded: true,
        sender: "someservice."+Guid.create()
        id: Guid.create()

    msgtest4 =
        action: "kill"
        sender: "someservice."+Guid.create()
        id: Guid.create()

    #parseMessage(msgtest) 

log = (severity, msg, stack) ->
    amqp.Log severity, msg, stack
    console.log "--- loging --- " + severity + ": " + msg

SendFailResponceBack = (message, reason) ->
    if message.responceNeeded
        message.error = reason
        message.responceNeeded = false
        if message.sender
            amqp.SendMessage message.sender, message    

createAction = (message) ->
    if(message.payload.action is 'start')
        LocalProcess.startProcess(message, amqp)

retrieveAction = (message) ->
    sender = message.sender
    recieverMessageId = message.id
    switch message.type
        when "HOSProcess"
            HOSProcess.getProcessList amqp, message, (res) ->
                message.id = recieverMessageId
                message.responceNeeded = false
                message.payload = res
                amqp.SendMessage sender, message

        when "task"
            message.responceNeeded = true
            amqp.SendMessage DataManager, message, (res) ->
                message.id = recieverMessageId
                message.responceNeeded = false
                amqp.SendMessage sender, message


parseMessage = (message) ->
    switch message.action
        when 'create' then createAction message
        when 'retrieve' then retrieveAction message
        else SendFailResponceBack message, "action found."