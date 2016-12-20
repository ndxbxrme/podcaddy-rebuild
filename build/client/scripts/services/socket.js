(function() {
  'use strict';
  angular.module('pod').factory('socket', function(player, auth) {
    var socket;
    socket = io();
    socket.on('connect', function() {
      var user;
      console.log('socket connected');
      user = auth.getUser();
      if (user) {
        return socket.emit('user', user._id);
      }
    });
    socket.on('disconnect', function() {
      return console.log('disconnected');
    });
    socket.on('feeds', function() {
      return player.fetchPods();
    });
    return {
      emit: function(message, data) {
        return socket.emit(message, data);
      }
    };
  });

}).call(this);

//# sourceMappingURL=socket.js.map
