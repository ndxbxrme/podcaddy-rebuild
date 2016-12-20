(function() {
  angular.module('pod').controller('FeedsCtrl', function($scope, $http, $window) {
    $http.post('/api/feeds').then(function(res) {
      return $scope.feeds = res.data;
    });
    return $scope.triggerScroll = function() {
      $window.scrollTo($window.scrollX, window.scrollY + 1);
      return console.log('scroll');
    };
  });

}).call(this);

//# sourceMappingURL=feeds.js.map
