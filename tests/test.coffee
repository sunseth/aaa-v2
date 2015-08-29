EventController = require('../controllers/EventController')()
s3 = require '../s3'
moment = require 'moment'
chai = require 'chai'
expect = chai.expect
sinon = require 'sinon'
q = require 'q'
chaiAsPromise = require 'chai-as-promised'
chai.use chaiAsPromise
mongoose = require 'mongoose'
EventSchema = require '../data/schemas/Event'
EventModel = mongoose.model('Event', EventSchema)

config = require '../config'
_ = require 'underscore'

describe 'EventController', () ->
  conn = undefined
  eventController = undefined
  uploadStub = undefined
  deleteStub = undefined
  EventModel = undefined

  multerFile =
    fieldname: 'image',
    originalname: 'sample_2.jpg',
    name: 'sample_2.jpg',
    encoding: '7bit',
    mimetype: 'image/jpeg',
    path: 'sample/sample_2.jpg',
    extension: 'jpg'

  multerFile2 =
    fieldname: 'image',
    originalname: 'roi.jpg',
    name: 'roi.jpg',
    encoding: '7bit',
    mimetype: 'image/jpeg',
    path: 'sample/roi.jpg',
    extension: 'jpg'

  before (done) ->
    # establish database connection
    mongoose.connect('mongodb://localhost:27017/aaa-test', config.mongo.options)

    # why doesn't this work?
    # conn = mongoose.createConnection('mongodb://localhost:27017/aaa-test', config.mongo.options)
    # conn.on 'open', ->
    mongoose.connection.once 'open', ->
      EventModel = mongoose.model('Event', EventSchema)
      console.log 'connected to mongoose at /aaa-test'
      eventController = EventController
      done()

  after (done) ->
    # wipe the test database
    EventModel.remove().then () ->
      mongoose.disconnect () ->
        console.log 'disconnected all connections'
        done()

  describe 'simple events', () ->
    params = {name: 'auto-event'}
    it 'should be able to create a new event with just a name', () ->
      expect(eventController.create({name: 'auto-event'})).to.eventually.have.property('name', 'auto-event')

    it 'should be able to accept invalid keys', () ->
      params.foo = 'bar'
      # angular $resource can cause these to be in the form
      params['$$resolved'] = true
      params['$$promise'] = new Object
      promise = eventController.create(params)
      expect(promise).to.eventually.have.property('name', 'auto-event')

  describe 's3 services are called', () ->
    params = {name: 'auto-event-s3'}
    testImageUrl = 'https://aaa-dev.s3.amazonaws.com/tienv%40sfu.ca/blackbuck1440292647602.png'

    before () ->
      uploadStub = sinon.stub s3, 'upload', () ->
        defer = q.defer()
        defer.resolve {Location: testImageUrl}
        return defer.promise
      deleteStub = sinon.stub s3, 'delete', () ->
        return {}

    it 'should call s3 delete image on event delete', () ->
      eventController.create({name: 'to-be-deleted', imageFile: multerFile}).then (event) ->
        eventController.delete(event.id).then (d) ->
          expect(deleteStub.calledOnce).to.be.true

    it 'should accept an image upload', () ->
      params.imageFile = multerFile
      params.email = 'tienv@sfu.ca'
      eventController.create(params).then () ->
        expect(uploadStub.calledOnce).to.be.true

    it 'should replace s3 image on event edit', () ->
      params.imageFile = multerFile
      params.email = 'tienv@sfu.ca'
      eventController.create(params).then (event) ->
        event.imageFile = multerFile2
        eventController.edit(event).then () ->
          expect(uploadStub.calledTwice).to.be.true
          expect(deleteStub.calledOnce).to.be.true

    afterEach () ->
      uploadStub.reset()
      deleteStub.reset()

    after () ->
      s3.upload.restore()
      s3.delete.restore()

  describe 'multiple', () ->
    it 'should retrieve items after multiple insert', () ->
      promises = []
      params = {}
      for i in [3..1]
        params.name = 'auto-event-multiple-' + i
        promises.push eventController.create(params)
      q.all(promises).then (results) ->
        getAllPromise = eventController.getAll() 
        expect(getAllPromise).to.eventually.be.an.instanceof(Array)


  describe 'fail event creation', () ->
    it 'should reject a past Date', () ->
      params = {name: 'auto-event', date: moment(new Date).subtract(1, 'day')}
      expect(eventController.create(params)).to.eventually.be.rejected

    it 'should reject an invalid date format', () ->
      params = {name: 'auto-event', date: 'this-is-not-a-date'}
      expect(eventController.create(params)).to.eventually.be.rejected


  describe 'delete and edit are idempotent', () ->
    params = {
      name: 'auto-event-idempotent'
    }

    beforeEach (done) ->
      eventController.create(params).then (event) ->
        params.id = event.id
        done()

    it 'should have idempotent edit', () ->
      params.location = 'wonderville'
      eventController.edit(params).then (data) ->
        promise = eventController.edit(params)
        expect(promise).to.eventually.have.property('location', params.location)
        expect(promise).to.eventually.have.property('name', params.name)

    it 'should have idempotent delete', () ->
      eventController.delete(params.id).then () ->
        expect(eventController.delete(params.id)).to.eventually.be.resolved