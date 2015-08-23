module.exports = (app, dependencies) ->
  {config, auth, paths, data, logger} = dependencies
  
  aws = require 'aws-sdk'
  fs = require 'fs'
  url = require 'url'
  multer = require 'multer'
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

  bucket = config.s3.bucket
  Event = data.Event

  deletefromS3 = (imageUrl) ->
    logger.log 'debug', 'S3 attempting to delete %s', imageUrl
    tmp = url.parse unescape(imageUrl)
    key = tmp.pathname.slice 1

    photoBucket = new aws.S3 {
      params: {
        Bucket: bucket,
        Key: ''
      }
    }
    photoBucket.deleteObject {
      Key: key
    }, (err, data) ->
      if err
        logger.log 'error', 'S3 delete failed, reason: %s', err.message
      else
        logger.log 'info', 'S3 delete success for key %s', key

  uploadToS3 = (file, separator) ->
    deferred = q.defer()

    logger.info 'S3 attempting to upload file %s', file.name
    photoBucket = new aws.S3.ManagedUpload {
      params: {
        Bucket: bucket,
        Key: separator + '/' + file.name,
        ACL: "public-read",
        Body: fs.createReadStream file.path,
        ContentType: file.mimetype,
        ContentEncoding: file.encoding
      }
    }
    photoBucket.send (err, data) ->
      if err
        logger.info 'S3 upload file failed, reason: %s', err
        deferred.reject(err)
      else
        logger.info 'S3 upload file success, URL: %s', data['Location']
        deferred.resolve(data)

    return deferred.promise

  # returns the events collection
  eventApi.get '/', (req, res) ->
    Event.find (err, results) ->
      if err
        next err

      else
        res.send results

  # id specific routes for single event R, U, D
  eventApi.get /^\/(\w+$)/, (req, res, next) ->
    eventId = req.params[0]
    Event
    .findOne(
      _id: eventId
    , (err, results) ->
      if err
        next err
      else
        res.send results
    )

  eventApi.delete /^\/(\w+$)/, (req, res, next) ->
    eventId = req.params[0]

    Event
    .findOneAndRemove(
      _id: eventId
    , (err, event) ->
      if err
        next err
      else
        deletefromS3 event.image
        res.send event
    )

  # for creating or editing an event, validate first
  eventApi.all '*', (req, res, next) ->
    newEvent = req.body

    # mongoose validator treats these values as valid
    underscore.each newEvent, (v, k) ->
      if v in ['undefined', 'null', '']
        delete newEvent[k]

    new Event(newEvent).validate (err) ->
      if err
        rtnJson = {errors: {}}
        errors = underscore.values(err.errors)

        underscore.each errors, (v, k) ->
          key = v.path
          rtnJson.errors[key] = v.message

        res.status(400).json rtnJson

      else
        next()

  # filter properties not in the schema
  eventApi.all '*', (req, res, next) ->
    formData = req.body
    eventSchema = require('../../../data/schemas/Event')
    properties = underscore.keys eventSchema.paths
    
    underscore.each formData, (v, k) ->
      if k not in properties
        delete formData[k]
    next()

  eventApi.post '/', (req, res) ->
    file = req.files['image']
    createEvent = (event) ->
      event.save (err, result) ->
        if err
          logger.error 'EventsApi failed to create, reason: %s', err.message
          res.send {err: err}
        else
          logger.info 'EventsApi successfully created %s', result.name
          res.send result

    e = new Event req.body

    if file != undefined
      uploadToS3(file, req.user.email).then (data) ->
        e.image = data['Location']
        createEvent(e)
      , (err) ->
        console.log 'AWS error'
    else
      createEvent(e)

  eventApi.put /^\/(\w+$)/, (req, res, next) ->
    eventId = req.params[0]
    updatedEvent = req.body

    updateEvent = (event, deleteOld) ->
      Event
      .findOneAndUpdate(
        _id: eventId,
        event,
        {new: false},
        (err, old) ->
          if err
            logger.info 'EventsApi failed update, reason: %s', err.message
            next
          else
            if deleteOld
              deletefromS3 old.image
            logger.info 'EventsApi successfully updated %s', event.name
            res.send event
      )

    if req.files['image'] != undefined
      deleteOld = true
      uploadToS3(req.files['image'], req.user.email).then (data) ->
        updatedEvent.image = data['Location']
        updateEvent updatedEvent, true
    else
      updateEvent updatedEvent, false

  return eventApi