module.exports = (app) ->
  app.controller 'AdminEventController', ($scope, $resource, $rootScope, $location, routeTraverse, eventsApi) ->
    _ = require 'underscore'
    moment = require 'moment'

    $scope.order = ''

    eventsPath = routeTraverse.resolve('admin.api.events')
    eventPath = routeTraverse.resolve('admin.api.events.event') + ':id'

    eventsResource = eventsApi.events(eventsPath)
    eventResource = eventsApi.event(eventPath)

    eventsResource.query '', (results) ->
      $scope.events = results
      $scope.events.selectedIndex = 0

      # initialize the imageUrl field as the link of the picture
      # as image will be the actual file instead
      _.each $scope.events, (elem, index) ->
        elem['imageUrl'] = elem['image']

      $rootScope.$broadcast 'loaded'

    $scope.createEvent = (newEvent) ->
      if newEvent.date in ['', undefined]
        newEvent.date = new Date

      event = new eventsResource(newEvent)
      event.$create {}, (response) ->
        newEvent = response.data
        newEvent.imageUrl = newEvent.image
        delete newEvent['image']

        $scope.events.push newEvent
      , (error) ->
        console.log error

    $scope.deleteEvent = (event, index) ->
      eventResource.remove {id: event._id}, (response) ->
        $scope.events.splice(index, 1)

    $scope.update = (event) ->
      form = event.form
      event = event.event

      if !form.$valid
        form.showValidations = true
      else
        form.showValidations = false
        if $scope.create
          if event.date in ['', undefined]
            event.date = new Date

          event = new eventsResource(event)
          eventsResource.create event, (response)->
            event = response
            event.imageUrl = event.image
            delete event['image']

            $scope.events.push event
            $rootScope.$broadcast 'createSuccess', 'Create success'

          , (error) ->
            console.log error
        else 
          eventResource.put {id: event._id}, event, (response) =>
            response.imageUrl = response.image
            $scope.events[$scope.selectedIndex] = response
            $rootScope.$broadcast 'loaded', 'Save success'
          , (error) ->
            console.log error

    $scope.changeOrder = (order) ->
      $scope.order = order

    $scope.showForm = (index) ->
      console.log index
      if index != undefined
        $scope.selectedIndex = index
        $scope.create = false
        $rootScope.$broadcast 'showForm', index
      else
        $scope.create = true
        $rootScope.$broadcast 'showNew', index

    $scope.selectedIndex = 0

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