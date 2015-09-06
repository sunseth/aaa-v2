module.exports = (err, req, res, next) ->
  _ = require 'underscore'

  if err.name == 'CastError'
    # additional error logic here
    console.log 'cast error'
  else if err.name == 'ValidationError'
    rtnJson = {errors: {}}
    errors = _.values(err.errors)

    _.each (errors), (v, k) ->
      key = v.path
      rtnJson.errors[key] = v.message

    res.status(400).json rtnJson
  else
    res.status(500).json err