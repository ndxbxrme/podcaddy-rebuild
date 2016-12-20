'use strict'
angular.module 'pod'
.directive 'addfeed', (menu, $http) ->
  restrict: 'AE'
  templateUrl: '/views/addfeed.html'
  replace: true
  scope: {}
  link: (scope, elem) ->
    clear = ->
      scope.feed = null
      scope.error = null
      scope.success = null
      scope.feedUrl = null
    scope.getAddFeedOut = menu.getAddFeedOut
    scope.hideAddFeed = ->
      clear()
      menu.hideAddFeed()
    scope.addFeed = ->
      $http.post '/api/add-feed', feedUrl:scope.feedUrl
      .then (data) ->
        if data.data.t
          scope.feed = data.data
          scope.success = true
        else
          scope.error = data.data.error
    scope.ok = ->
      clear()
      menu.hideAddFeed()