winston = require 'winston'
moment = require 'moment'
logger = new winston.Logger { 
  exitOnError: false,
  transports: [
    new winston.transports.File {
      filename: 'serverLog.txt'
      timestamp: () ->
        return moment(new Date).format 'h:mm:ss a'
      json: false
      levels: {
        info: 0
        error: 1
        critical: 2
      }
    }
  ]
}

module.exports = logger