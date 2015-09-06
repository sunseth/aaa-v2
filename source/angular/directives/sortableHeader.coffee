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
      angular.element('.datepicker').datetimepicker({
        format: 'd M Y H:i'
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
            scope.success = undefined
            scope.status = undefined
            elem.modal 'show'
            scope._event = scope._events[scope.index]
            setpicker(scope._event)
            return
        scope.$watch '_event', () ->
          if scope._event != undefined 
            if scope._event.date not in [undefined, '']
              scope._event.date = moment(new Date(scope._event.date)).format('DD MMM YYYY HH:mm')
            else
              scope._event.date = moment(new Date()).format('DD MMM YYYY HH:mm') 
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
              isEdit = $scope.index != undefined
              $scope.success = true
              $scope.status = if isEdit then 'Edit success' else 'Create success'

              if isEdit
                $scope._events[$scope.index] = angular.copy response
                $scope._event = $scope._events[$scope.index] 
              else
                $scope._events.push angular.copy response
                $scope._event = $scope._events[$scope._events.length - 1] 
            , (errorResponse) ->
              $scope.success = false
              $scope.status = 'There were validation errors, please correct them before proceeding'
              $scope.showServerValidations = true
              $scope._event.errors = errorResponse.data.errors
    }