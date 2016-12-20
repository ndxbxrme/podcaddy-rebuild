(function() {
  'use strict';
  angular.module('pod').directive('clickscreen', function(player) {
    return {
      restrict: 'AE',
      replace: false,
      scope: {},
      link: function(scope, elem) {
        scope.setMenuOut = player.setMenuOut;
        return scope.getMenuOut = player.getMenuOut;
      }
    };
  });

}).call(this);

//# sourceMappingURL=clickscreen.js.map
