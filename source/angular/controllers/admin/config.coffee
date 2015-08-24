module.exports = (app) ->
  ###*
  # @class SomeClass
  # @constructor
  # @method alarm
  # @param {String} message The message
  # @result {Boolean} whatever
  ###
  app.config ($routeProvider, $locationProvider) ->
    $locationProvider.html5Mode(
      enabled: false,
      requireBase: false
    )
    $routeProvider.when('/index',
      templateUrl: '/partials/admin.html',
      controller: 'AdminIndexController'
    ).when('/events',
      templateUrl: '/partials/events.html',
      controller: 'AdminEventController'
    ).when('/blog',
      templateUrl: '/partials/blogs.html',
      controller: 'AdminBlogController'
    ).when('/cabinet',
      templateUrl: '/partials/cabinet.html',
      controller: 'AdminCabinetController'
    ).when('/committees',
      templateUrl: '/partials/committees.html',
      controller: 'AdminCommitteeController'
    ).when('/families',
      templateUrl: '/partials/families.html',
      controller: 'AdminFamilyController'
    ).otherwise(
      templateUrl: '/partials/dashboard.html',
      controller: 'AdminDashboardController'
    )
