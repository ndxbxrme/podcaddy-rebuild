(function() {
  'use strict';
  angular.module('pod').directive('toolbar', function(player, menu) {
    return {
      restrict: 'AE',
      templateUrl: '/views/toolbar.html',
      replace: true,
      scope: {},
      link: function(scope, elem) {
        scope.getPod = player.getPod;
        scope.setVolume = player.setVolume;
        scope.getVolume = player.getVolume;
        scope.showMenu = menu.showMenu;
        return scope.togglePlay = function() {
          return player.podClick(player.getPod());
        };
      }
    };
  });

}).call(this);

//# sourceMappingURL=toolbar.js.map
