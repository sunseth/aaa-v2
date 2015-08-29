passport = require('passport')

module.exports = (app, dependencies) ->
  {config, auth, paths, data} = dependencies
  {User} = data

  loginOptions = {failureFlash: 'Invalid username or password.'}
  app.post paths.public.login, passport.authenticate('local', loginOptions), (req, res) ->
    res.redirect paths.public.home.index

  app.post paths.public.logout, (req, res, next) ->
    req.session.destroy()
    res.redirect paths.public.home.index

  app.post paths.public.signup, (req, res, next) ->
    return next({status: 400, message: "Invalid email address"}) unless req.body.email && /^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/.test(req.body.email)
    return next({status: 400, message: "Password must be at least 8 characters"}) unless req.body.password?.length >= 8
    return next({status: 400, message: "Password and confirmation do not match"}) unless req.body.password == req.body.confirm

    userQuery =
      email: req.body.email

    User.findOne(userQuery).exec (err, user) ->
      return next(err) if err
      return next({status: 400, message: "User already exists with this email"}) if user
      user = new User
        email: req.body.email
        firstName: req.body.firstName
        lastName: req.body.lastName
        clearance: auth.clearance.user
      user.setPassword(req.body.password)
      user.save (err) ->
        return next(err) if err
        req.login user, (err) ->
          return next(err) if err
          res.sendStatus(200)