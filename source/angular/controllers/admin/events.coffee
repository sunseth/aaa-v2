module.exports = (app) ->
  ###*
  # wtf?
  # @module SomeModulee
  # @main yuidoc
  ###
  app.controller 'AdminEventController', ($scope, $resource, $rootScope, $location, $q, routeTraverse, eventsApi) ->
    $scope.order = ''

    eventsPath = routeTraverse.resolve('admin.api.events')
    eventPath = routeTraverse.resolve('admin.api.events.event') + ':id'

    Resource = new eventsApi()
    eventsResource = Resource.events(eventsPath)
    eventResource = Resource.event(eventPath)

    eventsResource.query '', (results) ->
      $scope.events = results
      $scope.events.selectedIndex = 0

      # initialize the imageUrl field as the link of the picture
      # as image will be the actual file instead
      _.each $scope.events, (elem, index) ->
        elem['imageUrl'] = elem['image']
        elem['index'] = index

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
      deferred = $q.defer()
      if $scope.create
        if event.date in ['', undefined]
          event.date = new Date

        event = new eventsResource(event)
        eventsResource.create event, (response)->
          event = response
          event.imageUrl = event.image
          event.index = $scope.events.length
          delete event['image']

          $scope.events.push event
          deferred.resolve {type: 'create', event: event}

        , (error) ->
          deferred.reject error
      else 
        eventResource.put {id: event._id}, event, (response) =>
          response.imageUrl = response.image
          response.index = event.index
          $scope.events[$scope.selectedIndex] = response

          deferred.resolve {type: 'edit', index: $scope.selectedIndex, event: response}
        , (error) ->
          deferred.reject error

      return deferred.promise

    $scope.changeOrder = (order) ->
      $scope.order = order

    $scope.showForm = (index) ->
      if index != undefined
        $scope.selectedIndex = index
        $scope.create = false
        $rootScope.$broadcast 'showForm', index
      else
        $scope.create = true
        $rootScope.$broadcast 'showNew'

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