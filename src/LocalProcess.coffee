spawn = require('child_process').spawn

DataManager = 'datamanager'


log = (amqp, severity, msg, stack) ->
    amqp.Log severity, msg, stack
    console.log "--- loging --- " + severity + ": " + msg

SendFailResponceBack = (amqp, message, reason) ->
    if message.responceNeeded
        message.error = reason
        message.responceNeeded = false
        if message.sender
            amqp.SendMessage message.sender, message    
            console.log "--- loging --- " + reason + ": " + message


exports.startProcess = (message, amqp) ->
    serviceName = ""
    if message.payload.serviceName
        serviceName = message.payload.serviceName

    servicePath = ""
    if message.payload.servicePath
        servicePath = message.payload.servicePath

    args = []
    if message.payload.args
        args = message.payload.args

    prc = null

    cwd = process.cwd()
    if message.payload.cwd
        cwd = message.payload.cwd

    env = process.env
    if message.payload.env
        env = message.payload.env

    opt =
        cwd: cwd
        env: env

    try
        prc = spawn servicePath + serviceName,  args, opt
        sender = message.sender
        recieverMessageId = message.id

        prc.on 'error', (err) ->
            SendFailResponceBack amqp, "error happened on the task with error code: " + err.code , message

        tmsg = 
            action: "create"
            type: "task"
            responceNeeded: true
            payload:
                serviceName: message.payload.serviceName
                servicePath: message.payload.servicePath
                state: "started"
                startDate: new Date()
                args: message.payload.args
                pid: prc.pid

        amqp.SendMessage DataManager, tmsg

        prc.stdout.setEncoding 'utf8'

        prc.stdout.on 'data', (data) ->
            onData(message, prc, data, amqp)        

        prc.on 'close', (code) ->
            onClose(message, prc, code, tmsg, amqp)

        message.id = recieverMessageId
        message.responceNeeded = false
        message.payload = tmsg.payload
        amqp.SendMessage sender, message
        
        log amqp, "info", "request for start task from " + message.sender + " -- serviceName: " + serviceName + " -- Path: " + servicePath + " -- Args: " + args + " -- PID: " + prc.pid + " -- in Folder: " + cwd, ""


    catch e
        #SendFailResponceBack "couldn't start the task" + e.message , message
        return

onData = (message, prc, data, amqp) ->
    serviceName = message.payload.serviceName
    servicePath = message.payload.servicePath
    args = message.payload.args

    str = data.toString()
    lines = str.split /(\r?\n)/g
    log amqp, "info", data.toString(), ""
    #log amqp, "info", "task has printing data: " + " -- serviceName: " + serviceName + " -- Path: " + servicePath + " -- Args: " + args + " -- PID: " + prc.pid + " -- data: " + data.toString(), ""

    omsg = 
        action: "create"
        type: "output"
        payload:
            serviceName: message.payload.serviceName
            date: new Date()
            pid: prc.pid
            data: data

    amqp.SendMessage DataManager, omsg

onClose = (message, prc, code, tmsg, amqp) ->
    serviceName = message.payload.serviceName
    servicePath = message.payload.servicePath
    args = message.payload.args

    tmsg.payload.state
    log amqp, "info", "task has stopped: " + " -- serviceName: " + serviceName + " -- Path: " + servicePath + " -- Args: " + args + " -- PID: " + prc.pid + " -- exit code: " + code, ""
    console.log 'process exit code ' + code 

    tmsg.payload.state = "closed"
    tmsg.payload.closeCode = code
    tmsg.action = "update"
    amqp.SendMessage DataManager, tmsg#, (msg) ->
        #console.log msg
