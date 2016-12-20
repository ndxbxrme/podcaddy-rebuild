(function() {
  'use strict';
  angular.module('pod').directive('sidebar', function() {
    return {
      restrict: 'AE',
      templateUrl: '/views/sidebar.html',
      replace: true,
      link: function(scope, elem) {
        return console.log('sidebar');
      }
    };
  });

}).call(this);

//# sourceMappingURL=sidebar.js.map
