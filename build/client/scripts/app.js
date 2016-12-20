(function() {
  'use strict';
  angular.module('pod', ['ngRoute', 'afkl.ng.lazyImage']).config(function($routeProvider, $locationProvider) {
    $routeProvider.when('/feeds', {
      templateUrl: '/views/feeds.html',
      controller: 'FeedsCtrl'
    }).when('/:feedSlug?', {
      templateUrl: '/views/main.html',
      controller: 'MainCtrl'
    }).otherwise({
      redirectTo: '/'
    });
    return $locationProvider.html5Mode(true);
  }).run(function($rootScope, $window, $timeout, auth, socket, player) {
    auth.getUserPromise().then(function(user) {
      if (user) {
        return socket.emit('user', user._id);
      }
    }, function() {
      return socket.emit('user', '');
    });
    return $rootScope.$on('$routeChangeSuccess', function() {
      return $window.scrollTo(0, 1);
    });
  });

}).call(this);

//# sourceMappingURL=app.js.map
