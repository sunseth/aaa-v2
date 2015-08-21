module.exports = (app) ->
  app.config ($routeProvider, $locationProvider) ->
    $locationProvider.html5Mode({
      enabled: false,
      requireBase: false
    });
    $routeProvider.when('/events', {
      templateUrl: '/partials/events.html',
      controller: 'AdminEventController'
    }).when('/blog', {
      templateUrl: '/partials/blogs.html',
      controller: 'AdminBlogController'
    }).when('/cabinet', {
      templateUrl: '/partials/cabinet.html',
      controller: 'AdminCabinetController'
    }).when('/committees', {
      templateUrl: '/partials/committees.html',
      controller: 'AdminCommitteeController'
    }).when('/families', {
      templateUrl: '/partials/families.html',
      controller: 'AdminFamilyController'
    }).otherwise({
      templateUrl: '/partials/dashboard.html',
      controller: 'AdminDashboardController'
    })
  .controller 'AdminMainController', ($scope, $location) ->
    $scope.change = (path) ->
      $location.path(path)
  .controller 'AdminDashboardController', () -> {}
  .controller 'AdminBlogController', () -> {}
  .controller 'AdminCommitteeController', () -> {}
  .controller 'AdminCabinetController', () -> {}
  .controller 'AdminFamilyController', () -> {}