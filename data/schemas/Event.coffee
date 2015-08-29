mongoose = require 'mongoose'
_ = require 'underscore'
Schema = mongoose.Schema
s3 = require '../../s3'

EventSchema = new Schema(
  name: {type: String, required: [true, 'Name is required'], minlength: [5, 'Event name must be longer than ({MINLENGTH}) characters']}
  date: {type: Date, default: Date.now, min: [new Date, 'Date cannot be in the past']}
  location: String
  description: String
  link: String
  image: {type: String, required: false, match: [/^https?:\/\/(?:[a-z0-9\-]+\.)+[a-z]{2,6}(?:\/[^\/#?]+)+\.(?:jpg|gif|png)$/, 'Image must be of type .jpg|.gif|.png']}
  imageFile: Object
)

EventSchema.pre 'save', (next) ->
  # remove fields not in the schema, as angular can return stuff like `$$resolved` that breaks mongoose
  properties = _.keys EventSchema.paths
  
  _.each this, (v, k) ->
    if k not in properties
      delete this[k]
    
  if this.imageFile != undefined
    # remove from s3
    if this.image != undefined
      s3.delete this.image

    s3.upload(this.imageFile, 'tienv@sfu.ca').then (s3response) =>
      this.image = s3response['Location']
      this.imageFile = undefined
      next()
  else
    next()


EventSchema.pre 'remove', (next) ->
  # delete the image from s3
  if this.image != undefined
    s3.delete this.image

  next()

module.exports = EventSchema