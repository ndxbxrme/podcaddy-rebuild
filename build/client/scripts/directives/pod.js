(function() {
  'use strict';
  angular.module('pod').directive('pod', function(player) {
    return {
      restrict: 'E',
      templateUrl: 'views/pod.html',
      replace: true,
      link: function(scope, elem) {
        scope.pod.displayed = true;
        scope.podClick = function(e) {
          if (e.target.tagName !== 'A' && e.target.parentNode.tagName !== 'A') {
            return player.podClick(scope.pod);
          }
        };
        return scope.$on('$destroy', function() {
          return scope.pod.displayed = false;
        });
      }
    };
  });

}).call(this);

//# sourceMappingURL=pod.js.map
