(function() {
  'use strict';
  angular.module('pod').filter('listened', function(player) {
    return function(input, filter) {
      var filteredItems;
      filteredItems = [];
      angular.forEach(input, function(item) {
        if (player.getPod() && player.getPod()._id === item._id) {
          return filteredItems.push(item);
        } else {
          if (filter === 'all') {
            return filteredItems.push(item);
          } else if (filter === 'unlistened') {
            if (!item.listened) {
              return filteredItems.push(item);
            }
          } else if (filter === 'listened') {
            if (item.listened) {
              return filteredItems.push(item);
            }
          }
        }
      });
      return filteredItems;
    };
  });

}).call(this);

//# sourceMappingURL=listened.js.map
