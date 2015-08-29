module.exports = (app, dependencies) ->
  {config, auth, paths, data, logger} = dependencies
  
  aws = require 'aws-sdk'
  multer = require 'multer'  
  fs = require 'fs'
  url = require 'url'
  underscore = require 'underscore'
  q = require 'q'

  eventApi = app.express.Router()
  eventApi.use require('../../../middleware/dbError')

  eventApi.use multer(
    limit:
      fieldNameSize: 100
      fieldSize: 5
    dest: './uploads/'
    rename: (fieldname, filename) ->
      filename + Date.now()
    onFileUploadStart: (file) ->
      logger.info 'Uploading %s is starting', file.originalname
      return
    onFileUploadComplete: (file) ->
      logger.info '%s uploaded to %s', file.fieldname, file.path
      done = true
      return
  )

  eventController = require('../../../controllers/EventController')()
  EventController = eventController
  # returns the events collection
  eventApi.get '/', (req, res) ->
    EventController.getAll().then (results) ->
      res.send(results)
    , (err) ->
      next(err)

  # id specific routes for single event R, U, D
  eventApi.get /^\/(\w+$)/, (req, res, next) ->
    EventController.get(req.params[0]).then (result) ->
      res.send result
    , (err) ->
      next(err)

  eventApi.delete /^\/(\w+$)/, (req, res, next) ->
    EventController.delete(req.params[0]).then (result) ->
      res.send result
    , (err) ->
      next(err)

  eventApi.post '/', (req, res) ->
    params = req.body
    params.imageFile = req.files['image']
    EventController.create(params).then (success) ->
      res.send success
    , (err) ->
      next(err)

  eventApi.put /^\/(\w+$)/, (req, res, next) ->
    params = req.body
    params.imageFile = req.files['image']
    params.id = req.params[0]
    EventController.edit(params).then (success) ->
      res.send success
    , (err) ->
      next(err)

  return eventApi