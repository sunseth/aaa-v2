module.exports = (app, dependencies) ->
  {config, auth, paths, data} = dependencies

  admin = app.express.Router()

  # enforce clearance of 3 for admin site
  app.use paths.admin.base, admin
  adminPublic = app.express.Router()

  admin.use '/', adminPublic
  admin.use paths.admin.api.base, require('./api/index')(app, dependencies)
  app.get paths.admin.base, (req, res, next) ->
    res.render 'admin/dashboard'

  return admin