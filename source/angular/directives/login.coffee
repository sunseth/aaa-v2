module.exports = (app) ->
  app.directive 'aaaLoginModal', ($http, $rootScope, $q) ->
    return {
      restrict: 'E'
      templateUrl: 'templates/login.html'
      link: (scope, elem, attrs) ->
        modal = elem.find('.ui.login.modal')
        scope.showModal = () ->
          modal.modal 'show'
          return

        scope.submit = (form) ->
          return if scope.loading
          deferred = $q.defer()
          scope.loading = true
          $http.post($rootScope.paths.public.login, form)
            .success (res) =>
              modal.modal 'hide'
              deferred.resolve res
              location.reload()
            .error (err) =>
              deferred.reject err 
              scope.error = err
            .finally () =>
              delete scope.loading

          return deferred.promise
      scope:
        page: '='
    }