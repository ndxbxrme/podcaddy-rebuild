(function() {
  angular.module('pod').controller('MainCtrl', function($scope, $http, $window, $route, player) {
    $scope.getPods = function() {
      return player.getPods();
    };
    player.setFeedSlug($route.current.params.feedSlug);
    player.fetchPods();
    $scope.getFilter = player.getFilter;
    return $scope.triggerScroll = function() {
      $window.scrollTo($window.scrollX, window.scrollY + 1);
      return console.log('scroll');
    };
  });

}).call(this);

//# sourceMappingURL=main.js.map
