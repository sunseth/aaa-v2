module.exports = (app) ->
  app.directive 'sortable', () ->
    return {
      templateUrl: 'templates/sortableHeader.html',
      scope: {
        config: '='
        parentFn: '&onClick'
      },
      replace: true,
      transclude: true,
      controller: ($scope) ->
        $scope.headers = _.keys($scope.config)
        $scope.source = _.values($scope.config)
        $scope.message = {
          order: ''
        }

        # to mark the sorted value. Initializes as the first element
        $scope.ascending = new Array($scope.headers.length + 1).join(0).split('').map (val) ->
          return val == "1"

        $scope.sort = (index) ->
          $scope.selected = index
          $scope.ascending[index] = !$scope.ascending[index]
          $scope.message.order = if $scope.ascending[index] then '+' else '-'
          $scope.message.order += $scope.source[index]

          $scope.parentFn($scope.message)
    }
  .directive 'eventForm', () ->
    setpicker = (event) ->
      date = if event == undefined then new Date else event.date

      # initialize date picker
      angular.element('.datepicker').datetimepicker({
        format: 'd M Y H:i'
        value: date
      })  

    return {
      templateUrl: 'templates/eventForm.html'
      replace: true
      scope: {
        parentFn: '&onSubmit'
        events: '&source'
      }
      link: (scope, elem) ->
        scope.$on 'showForm', (event, index) ->
          elem.modal 'show'
          scope._event = scope._events[index]          
          setpicker(scope._event)
          return
        scope.$on 'showNew', () ->
          elem.modal 'show'
          scope._event = null
          setpicker()
          return
        scope.$on 'loaded', () ->
          scope._events = angular.copy scope.events()
      controller: ($scope) ->
        $scope.submitEvent = () ->
          form = $scope.eventForm

          if !form.$valid
            $scope.showValidations = true
          else
            $scope.showValidations = false          
            $scope.status = 'Saving changes...'
            $scope.parentFn({
              event: $scope._event
            }).then (response) ->
              successType = response['type']
              index = response['index']
              changedEvent = response['event']

              if successType == 'create'
                $scope.status = 'Create success'
                $scope._events.push angular.copy changedEvent
                $scope._event = $scope._events[$scope._events.length - 1] 
              else if successType == 'edit'
                $scope.status = 'Edit success'
                $scope._events[index] = angular.copy changedEvent
                $scope._event = $scope._events[index]
            , (errorResponse) ->
              $scope.showServerValidations = true
              $scope._event.errors = errorResponse.data.errors
    }