(function() {
  'use strict';
  angular.module('pod').directive('login', function(auth) {
    return {
      restrict: 'AE',
      templateUrl: '/views/login.html',
      replace: true,
      scope: {},
      link: function(scope, elem) {
        var login, signup;
        scope.getUser = auth.getUser;
        login = function() {
          scope.submitted = true;
          if (scope.loginForm.$valid) {
            return $http.post('/api/login', {
              email: scope.email,
              password: scope.password
            }).success(function() {
              return $location.path('/');
            }).error(function() {
              return scope.submitted = false;
            });
          }
        };
        return signup = function() {
          scope.submitted = true;
          if (scope.loginForm.$valid) {
            return $http.post('/api/signup', {
              email: scope.email,
              password: scope.password
            }).success(function() {
              return $location.path('/');
            }).error(function() {
              return scope.submitted = false;
            });
          }
        };
      }
    };
  });

}).call(this);

//# sourceMappingURL=login.js.map
