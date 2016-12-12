angular.module 'pod'
.controller 'MainCtrl', ($scope, $http, $window, player) ->
  $scope.getPods = ->
    player.getPods()
  player.fetchPods()
  
  $scope.triggerScroll = ->
    console.log 'scroll'
    $window.scrollTo $window.scrollX, window.scrollY + 1