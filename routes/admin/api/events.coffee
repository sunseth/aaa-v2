module.exports = (app, dependencies) ->
  {config, auth, paths, data} = dependencies
  
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
      console.log file.originalname + ' is starting ...'
      return
    onFileUploadComplete: (file) ->
      console.log file.fieldname + ' uploaded to  ' + file.path
      done = true
      return
    onFieldsLimit: ->
      console.log 'Crossed fields limit!'
      return
  )

  bucket = config.s3.bucket
  Event = data.Event

  deletefromS3 = (imageUrl) ->
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
        console.log err
      else
        console.log 'deleted ' + key

  uploadToS3 = (file, separator) ->
    deferred = q.defer()

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
        deferred.reject(err)
      else
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
        rtnJson = {errors: []}
        errors = underscore.values(err.errors)

        underscore.each errors, (v, k) ->
          name = v.path
          rtnJson.errors.push
            name: v.name,
            message: v.message,
            path: v.path
  
        res.status(400).json rtnJson

      else
        next()

  eventApi.post '/', (req, res) ->
    file = req.files['image']
    createEvent = (event) ->
      event.save (err, result) ->
        if err
          res.send {err: err}
        else
          res.send result

    e = new Event req.body

    if file != undefined
      uploadToS3(file, req.user.email).then (data) ->
        e.image = data['Location']
        createEvent(e)
      , (err) ->
        console.log 'AWS error'
        console.log err
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
            next err
          else
            if deleteOld
              deletefromS3 old.image
            res.send event
      )

    if req.files['image'] != undefined
      deleteOld = true
      uploadToS3 req.files['image'], req.user.email.then (data) ->
        updatedEvent.image = data['Location']
        updateEvent updatedEvent, true
    else
      updateEvent updatedEvent, false

  return eventApi