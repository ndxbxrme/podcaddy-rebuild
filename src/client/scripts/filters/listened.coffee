'use strict'

angular.module 'pod'
.filter 'listened', (player) ->
  (input, filter) ->
    filteredItems = [];
    angular.forEach input, (item) ->
      if player.getPod() and player.getPod()._id is item._id
        filteredItems.push item
      else
        if filter is 'all'
          filteredItems.push item
        else if filter is 'unlistened'
          if not item.listened
            filteredItems.push item
        else if filter is 'listened'
          if item.listened
            filteredItems.push item
    filteredItems