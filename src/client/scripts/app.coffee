'use strict'

angular.module 'pod', [
  'ngRoute'
  'afkl.ng.lazyImage'
]
.config ($routeProvider, $locationProvider) ->
  $routeProvider
  .when '/feeds',
    templateUrl: '/views/feeds.html'
    controller: 'FeedsCtrl'
  .when '/:feedSlug?',
    templateUrl: '/views/main.html'
    controller: 'MainCtrl'
  .otherwise
    redirectTo: '/'
  $locationProvider.html5Mode true
.run ($rootScope, $window, $timeout, auth, socket, player) ->
  auth.getUserPromise()
  .then (user) ->
    if user
      socket.emit 'user', user._id
  , ->
    socket.emit 'user', ''
  $rootScope.$on '$routeChangeSuccess', ->
    $window.scrollTo 0, 1