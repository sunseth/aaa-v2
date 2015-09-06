module.exports = (app) ->
  app.controller 'AdminEventController', ($scope, $resource, $rootScope, $location, $q, routeTraverse, eventsApi) ->
    $scope.order = ''

    eventsPath = routeTraverse.resolve('admin.api.events')
    eventPath = routeTraverse.resolve('admin.api.events.event') + ':id'

    eventsResource = eventsApi.events(eventsPath)
    eventResource = eventsApi.event(eventPath)

    $scope.initialize = () ->
      deferred = $q.defer()

      eventsResource.query '', (results) ->
        $scope.events = results
        $scope.events.selectedIndex = 0

        # initialize the imageUrl field as the link of the picture
        # as image will be the actual file instead
        _.each $scope.events, (elem, index) ->
          elem['imageUrl'] = elem['image']
          elem['index'] = index
        deferred.resolve($scope.events)
        $rootScope.$broadcast 'loaded'

      return deferred.promise

    $scope.initialize()

    $scope.deleteEvent = (event, index) ->
      deferred = $q.defer()
      eventResource.remove {id: event._id}, (response) ->
        $scope.events.splice(index, 1)
        deferred.resolve()

      return deferred.promise

    $scope.createOrEdit = (event) ->
      deferred = $q.defer()
      if $scope.selectedIndex == undefined
        if event.date in ['', undefined]
          event.date = new Date

        event = new eventsResource(event)
        eventsResource.create event, (response) ->
          response.imageUrl = event.image
          response.index = $scope.events.length
          delete event['image']

          $scope.events.push response
          deferred.resolve(response)
        , (error) ->
          deferred.reject error
      else
        eventResource.put {id: event._id}, event, (response) =>
          response.imageUrl = response.image
          response.index = event.index
          $scope.events[$scope.selectedIndex] = response

          deferred.resolve(response)
        , (error) ->
          deferred.reject error

      return deferred.promise

    $scope.changeOrder = (order) ->
      $scope.order = order

    # to keep track of when the form gets shown, as the modal opens on $watch
    $scope.show = false
    $scope.showForm = (index) ->
      $scope.selectedIndex = index
      $scope.show = !$scope.show

    # configuration for the sort headers: display label: event field
    $scope.sortConfig = {
      Name: 'name',
      Description: 'description',
      Location: 'location',
      Date: 'date',
      "Image Link": 'image',
    }