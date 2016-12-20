'use strict'
angular.module 'pod'
.directive 'feed', ($location, $http, $timeout) ->
  restrict: 'AE'
  templateUrl: '/views/feed.html'
  link: (scope, elem) ->
    scope.goTo = ->
      $location.path '/' + scope.feed.feedSlug
    scope.subscribe = ->
      $http.post '/api/subscribe', feedId:scope.feed.feedId
      $timeout ->
        scope.feed.subscribed = new Date().valueOf()
    scope.unsubscribe = ->
      $http.post '/api/unsubscribe', feedId:scope.feed.feedId
      $timeout ->
        scope.feed.subscribed = null