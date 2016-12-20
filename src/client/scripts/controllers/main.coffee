angular.module 'pod'
.controller 'MainCtrl', ($scope, $http, $window, $route, player) ->
  $scope.getPods = ->
    player.getPods()
  player.setFeedSlug $route.current.params.feedSlug
  player.fetchPods()
  $scope.getFilter = player.getFilter
  
  $scope.triggerScroll = ->
    $window.scrollTo $window.scrollX, window.scrollY + 1
    console.log 'scroll'