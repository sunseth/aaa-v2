util = require 'util'

config = require '../config'
paths = require '../paths'

module.exports = (app) ->
  app.use (err, req, res, next) ->
    statusCode = err.status || err.statusCode || 500

    if statusCode == 403 || statusCode == 401 && req.accepts('html', 'json') == 'html'
      return res.status(statusCode).render '403.ejs', {
        message: "Unauthorized - #{req.method} #{req.url}"
        redirectUrl: paths.public.home.index }

    res.status statusCode
    try
      res.send err
    catch e
      res.send util.inspect err

  app.use (req, res, next) ->
    if req.accepts('html', 'json') == 'html'
      res.status(404).render paths.notFound,
        message: "Unavailable - #{req.method} #{req.url}"
        redirectUrl: paths.public.home.index
    else
      res.status(404).send
        statusCode: 404
        message: "Unavailable - #{req.method} #{req.url}"