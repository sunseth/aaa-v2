module.exports = (app) ->
  app.controller 'EventsController', ($scope, $rootScope, $http, routeTraverse, eventsApi) ->
    eventsPath = routeTraverse.resolve('admin.api.events')
    eventsApi.events(eventsPath).query '', (results) ->
      $scope.events = results

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