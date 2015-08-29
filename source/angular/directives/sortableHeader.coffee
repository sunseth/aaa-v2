module.exports = (app) ->
  app.directive 'sortable', () ->
    return {
      # template: '<p>foobar</p>'
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
        index: '=trackBy'
        show: '='
      }
      link: (scope, elem) ->
        scope.$watch 'show', (newVal, oldVal) ->
          if newVal != undefined and newVal != oldVal
            elem.modal 'show'
            scope._event = scope._events[scope.index]
            setpicker(scope._event)
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
              isEdit = $scope.index 
              $scope.status = if isEdit then 'Edit success' else 'Create success'

              if isEdit
                $scope._events[$scope.index] = angular.copy response
                $scope._event = $scope._events[$scope.index] 
              else
                $scope._events.push angular.copy response
                $scope._event = $scope._events[$scope._events.length - 1] 
            , (errorResponse) ->
              $scope.showServerValidations = true
              $scope._event.errors = errorResponse.data.errors
    }