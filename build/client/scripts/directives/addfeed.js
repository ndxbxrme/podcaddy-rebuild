(function() {
  'use strict';
  angular.module('pod').directive('addfeed', function(menu, $http) {
    return {
      restrict: 'AE',
      templateUrl: '/views/addfeed.html',
      replace: true,
      scope: {},
      link: function(scope, elem) {
        var clear;
        clear = function() {
          scope.feed = null;
          scope.error = null;
          scope.success = null;
          return scope.feedUrl = null;
        };
        scope.getAddFeedOut = menu.getAddFeedOut;
        scope.hideAddFeed = function() {
          clear();
          return menu.hideAddFeed();
        };
        scope.addFeed = function() {
          return $http.post('/api/add-feed', {
            feedUrl: scope.feedUrl
          }).then(function(data) {
            if (data.data.t) {
              scope.feed = data.data;
              return scope.success = true;
            } else {
              return scope.error = data.data.error;
            }
          });
        };
        return scope.ok = function() {
          clear();
          return menu.hideAddFeed();
        };
      }
    };
  });

}).call(this);

//# sourceMappingURL=addfeed.js.map
