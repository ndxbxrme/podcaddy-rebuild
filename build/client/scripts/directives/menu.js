(function() {
  'use strict';
  angular.module('pod').directive('menu', function(menu, $location, player, auth) {
    return {
      restrict: 'AE',
      templateUrl: '/views/menu.html',
      replace: true,
      scope: {},
      link: function(scope, elem) {
        scope.hideMenu = menu.hideMenu;
        scope.getMenuOut = menu.getMenuOut;
        scope.goTo = function(url) {
          menu.hideMenu();
          return $location.path(url);
        };
        scope.getDirection = player.getDirection;
        scope.setDirection = function(dir) {
          player.setDirection(dir);
          return menu.hideMenu();
        };
        scope.getFilter = player.getFilter;
        scope.setFilter = function(filter) {
          player.setFilter(filter);
          return menu.hideMenu();
        };
        scope.getUser = auth.getUser;
        return scope.addFeed = function() {
          menu.showAddFeed();
          return menu.hideMenu();
        };
      }
    };
  });

}).call(this);

//# sourceMappingURL=menu.js.map
