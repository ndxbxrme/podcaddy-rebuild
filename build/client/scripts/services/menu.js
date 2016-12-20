(function() {
  'use strict';
  angular.module('pod').factory('menu', function($timeout) {
    var addFeedOut, menuOut, showHideMenu;
    menuOut = false;
    addFeedOut = false;
    showHideMenu = function() {
      var position;
      if (menuOut) {
        position = $('.menu-anchor').offset();
        return $('.popout').css({
          left: position.left + 'px',
          top: position.top + 'px'
        });
      }
    };
    return {
      showMenu: function() {
        return $timeout(function() {
          menuOut = true;
          return showHideMenu();
        });
      },
      hideMenu: function() {
        return $timeout(function() {
          menuOut = false;
          return showHideMenu();
        });
      },
      getMenuOut: function() {
        return menuOut;
      },
      showAddFeed: function() {
        return $timeout(function() {
          return addFeedOut = true;
        });
      },
      hideAddFeed: function() {
        return $timeout(function() {
          return addFeedOut = false;
        });
      },
      getAddFeedOut: function() {
        return addFeedOut;
      }
    };
  });

}).call(this);

//# sourceMappingURL=menu.js.map
