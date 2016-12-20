(function() {
  'use strict';
  angular.module('pod').directive('feed', function($location, $http, $timeout) {
    return {
      restrict: 'AE',
      templateUrl: '/views/feed.html',
      link: function(scope, elem) {
        scope.goTo = function() {
          return $location.path('/' + scope.feed.feedSlug);
        };
        scope.subscribe = function() {
          $http.post('/api/subscribe', {
            feedId: scope.feed.feedId
          });
          return $timeout(function() {
            return scope.feed.subscribed = new Date().valueOf();
          });
        };
        return scope.unsubscribe = function() {
          $http.post('/api/unsubscribe', {
            feedId: scope.feed.feedId
          });
          return $timeout(function() {
            return scope.feed.subscribed = null;
          });
        };
      }
    };
  });

}).call(this);

//# sourceMappingURL=feed.js.map
