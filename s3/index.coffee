aws = require 'aws-sdk'
fs = require 'fs'
url = require 'url'
multer = require 'multer'
underscore = require 'underscore'
q = require 'q'
logger = require '../middleware/logger'
bucket = 'aaa-dev'

module.exports.upload = (file, separator) ->
  # debugger
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

module.exports.delete = (imageUrl) ->
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