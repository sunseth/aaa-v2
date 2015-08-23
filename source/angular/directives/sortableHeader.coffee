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

        $scope.callParent = (index) ->
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
        scope.$on 'showForm', (event) ->
          elem.modal 'show'
          scope._event = scope._events[scope.$parent.selectedIndex]          
          setpicker(scope._event)
          return
        scope.$on 'showNew', (event) ->
          elem.modal 'show'
          scope._event = null
          setpicker()
          return
      controller: ($scope) ->
        $scope.$on 'createSuccess', (event, arg)->
          $scope._events = angular.copy $scope.events()
          $scope.status = arg

        $scope.$on 'loaded', (event, arg) ->
          $scope._events = angular.copy $scope.events()
          $scope._event = $scope._events[$scope.$parent.selectedIndex]
          $scope.status = arg   

        $scope.submitEvent = () ->
          $scope.status = 'Saving changes...'
          $scope.parentFn({
            event: {
              form: $scope.eventForm
              event: $scope._event
            }
          })
    }