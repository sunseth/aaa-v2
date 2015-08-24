

module.exports = (app) ->

  app.controller 'AdminMainController', ($scope, $location) ->
    $location.path ('/index')
    $scope.change = (path) ->
      $location.path(path)
      $scope.activeTab = path.slice(1)