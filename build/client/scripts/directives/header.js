(function() {
  'use strict';
  angular.module('pod').directive('header', function() {
    return {
      restrict: 'AE',
      templateUrl: '/views/header.html',
      replace: true,
      scope: {},
      link: function(scope, elem) {}
    };
  });

}).call(this);

//# sourceMappingURL=header.js.map
