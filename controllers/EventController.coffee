q = require 'q'
s3 = require '../s3'
mongoose = require 'mongoose'
logger = require '../middleware/logger'
EventSchema = require '../data/schemas/Event'
EventModel = mongoose.model('Event', EventSchema)
_ = require 'underscore'

module.exports = () ->
  class EventController
    @create: (params) ->
      return EventModel.create(params)

    @get: (id) ->
      return EventModel.findById(id).exec()

    @getAll: () ->
      return EventModel.find().exec()

    @edit: (params) ->
      EventModel.findById(params.id).then (event) ->
        if event == null
          deferred = q.defer()
          deferred.reject('Id :id cannot be found'.replace(/:id/, params.id))
          return deferred.promise

        properties = _.keys EventSchema.paths

        # mass update the properties, instead of doing event.name = param.name...
        _.each _.keys(params), (k) ->
          if k in properties
            event[k] = params[k]

        return event.save()
      , (err) ->
        deferred = q.defer()
        deferred.reject(err)
        return deferred.promise

    @delete: (id) ->
      # must call remove from document object for hook to be triggered
      EventModel.findById(id).exec().then (event) ->
        if event == null
          deferred = q.defer()
          deferred.resolve {}
          return deferred.promise

        return event.remove()

  return EventController