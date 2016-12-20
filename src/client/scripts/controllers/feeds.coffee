angular.module 'pod'
.controller 'FeedsCtrl', ($scope, $http, $window) ->
  $http.post '/api/feeds'
  .then (res) ->
    $scope.feeds = res.data
    
  $scope.triggerScroll = ->
    $window.scrollTo $window.scrollX, window.scrollY + 1
    console.log 'scroll'