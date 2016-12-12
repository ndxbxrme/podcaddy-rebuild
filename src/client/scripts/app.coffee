'use strict'

angular.module 'pod', [
  'ngRoute'
  'afkl.ng.lazyImage'
]
.config ($routeProvider, $locationProvider) ->
  console.log 'made it'
  $routeProvider
  .when '/',
    templateUrl: '/views/main.html'
    controller: 'MainCtrl'
  $locationProvider.html5Mode true
.run (auth, socket) ->
  auth.getUserPromise()
  .then (user) ->
    console.log 'user', user
    if user
      socket.emit 'user', user._id
  , ->
    socket.emit 'user', ''