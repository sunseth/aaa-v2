

module.exports =  (app) ->
  app.controller 'AdminFamilyController', ($scope, $location) ->
    angular.element('.ui.accordion').accordion()