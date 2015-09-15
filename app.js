// Generated by CoffeeScript 1.9.3
(function() {
  var DataManager, Guid, HOSProcess, LocalProcess, SendFailResponceBack, amqp, createAction, log, name, parseMessage, retrieveAction;

  amqp = require('AMQP-boilerplate');

  Guid = require('guid');

  LocalProcess = require('./LocalProcess');

  HOSProcess = require('./HOSProcess');

  name = 'taskManager';

  DataManager = 'datamanager';


  amqp.Initialize(name, function() {
    var msgtest, msgtest2, msgtest3, msgtest4;
    amqp.CreateRequestQueue(name, function(message) {
      return parseMessage(message);
    });
    msgtest = {
      action: "create",
      type: "task",
      responceNeeded: true,
      sender: "someservice." + Guid.create(),
      id: Guid.create(),
      payload: {
        serviceName: "ping",
        servicePath: "",
        action: "start",
        startDate: Date.now(),
        args: ['google.com']
      }
    };
    msgtest2 = {
      action: "retrieve",
      type: "task",
      responceNeeded: true,
      sender: "someservice." + Guid.create(),
      id: Guid.create(),
      payload: {
        username: "ali",
        password: "alikh"
      }
    };
    msgtest3 = {
      action: "retrieve",
      type: "HOSProcess",
      responceNeeded: true,
      sender: "someservice." + Guid.create(),
      id: Guid.create()
    };
    return msgtest4 = {
      action: "kill",
      sender: "someservice." + Guid.create(),
      id: Guid.create()
    };
  });

  log = function(severity, msg, stack) {
    amqp.Log(severity, msg, stack);
  };

  SendFailResponceBack = function(message, reason) {
    if (message.responceNeeded) {
      message.error = reason;
      message.responceNeeded = false;
      if (message.sender) {
        return amqp.SendMessage(message.sender, message);
      }
    }
  };

  createAction = function(message) {
    if (message.payload.action === 'start') {
      return LocalProcess.startProcess(message, amqp);
    }
  };

  retrieveAction = function(message) {
    var recieverMessageId, sender;
    sender = message.sender;
    recieverMessageId = message.id;
    switch (message.type) {
      case "HOSProcess":
        return HOSProcess.getProcessList(amqp, message, function(res) {
          message.id = recieverMessageId;
          message.responceNeeded = false;
          message.payload = res;
          return amqp.SendMessage(sender, message);
        });
      case "task":
        message.responceNeeded = true;
        return amqp.SendMessage(DataManager, message, function(res) {
          message.id = recieverMessageId;
          message.responceNeeded = false;
          return amqp.SendMessage(sender, message);
        });
    }
  };

  parseMessage = function(message) {
    switch (message.action) {
      case 'create':
        return createAction(message);
      case 'retrieve':
        return retrieveAction(message);
      default:
        return SendFailResponceBack(message, "action found.");
    }
  };

}).call(this);