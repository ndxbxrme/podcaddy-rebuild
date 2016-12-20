(function() {
  angular.module('pod').factory('auth', function($http, $q, $timeout) {
    var user;
    user = null;
    return {
      getUserPromise: function() {
        var defer;
        defer = $q.defer();
        if (user) {
          defer.resolve(user);
        } else {
          $http.post('/api/refresh-login').then(function(data) {
            if (data && data.data !== 'error') {
              user = data.data;
              return defer.resolve(user);
            } else {
              user = null;
              return defer.reject({});
            }
          }, function() {
            user = null;
            return defer.reject({});
          });
        }
        return defer.promise;
      },
      getUser: function() {
        return user;
      }
    };
  });

}).call(this);

//# sourceMappingURL=auth.js.map
