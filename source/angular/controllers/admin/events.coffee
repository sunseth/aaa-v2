module.exports = (app) ->
  app.controller 'AdminEventController', ($scope, $resource, $rootScope, $location, routeTraverse, eventsApi) ->
    _ = require 'underscore'

    $scope.order = ''

    # initialize accordion
    angular.element('.ui.accordion').accordion()

    eventsPath = routeTraverse.resolve('admin.api.events')
    eventPath = routeTraverse.resolve('admin.api.events.event') + ':id'

    eventsResource = eventsApi.events(eventsPath)
    eventResource = eventsApi.event(eventPath)

    # initialize datetimepicker of the new event form
    angular.element(document).ready () ->
      setTimeout () ->
        angular.element('#newEventDate').datetimepicker ({
          format: 'd M Y H:i',
          value: new Date
        })
      , 0

    eventsResource.query '', (results) ->
      $scope.events = results

      # prevent the title updating as the form gets typed out
      for event in $scope.events
        event.title = event.name
        event.imageUrl = event.image

      i = 0

      # initialize the datetimepickers for the events
      angular.element(document).ready () ->
        setTimeout () ->
          for event in $scope.events
            angular.element('.datepicker:eq(' + i.toString() + ')').datetimepicker({
              format: 'd M Y H:i',
              value: new Date event.date
            })
            i++
        , 0

    $scope.createEvent = () ->
      if $scope.newEvent.date in ['', undefined]
        $scope.newEvent.date = new Date

      event = new eventsResource($scope.newEvent)
      event.$create {}, (response) ->
        newEvent = response.data
        newEvent.title = newEvent.name
        newEvent.imageUrl = newEvent.image
        delete newEvent['image']

        $scope.events.push newEvent
      , (error) ->
        console.log error

    $scope.deleteEvent = (event, index) ->
      eventResource.remove {id: event._id}, (response) ->
        $scope.events.splice(index, 1)

    $scope.put = (form) ->
      if !form.$valid
        this.event.showValidations = true
      else
        this.event.showValidations = false
        eventResource.put {id: this.event._id}, this.event, (response) =>
          console.log response
          this.event.imageUrl = response.image
          this.event.title = this.event.name
        , (error) ->
          console.log error

    $scope.changeOrder = (order) ->
      $scope.order = order

    $scope.sortConfig = {
      Name: 'name',
      Description: 'description',
      Date: 'date',
      "Image Link": 'image'
    }
  .directive 'longname', () ->
    return {
      require: 'ngModel',
      link: (scope, elm, attrs, ctrl) ->
        ctrl.$validators.longname = (modelVal, viewVal) ->
          if viewVal.length > 5
            return true

          return false
    }