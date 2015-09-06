
module.exports = (app) ->

  app.controller 'HomeController', class HomeController
    constructor: (@$scope, @$http, @$rootScope, @$route) ->
      @$scope.date = new Date()

    openLoginModal: ->
      @$scope.loginModal.modal('show')
      return

    openSignupModal: ->
      @$scope.signupModal.modal('show')
      return

    logout: ->
      @$http.post(@$rootScope.paths.public.logout, {})
        .success (res) =>
          return location.reload()
        .error (err) =>
          return @$scope.error = err