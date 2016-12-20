'use strict'

angular.module 'pod'
.directive 'toolbar', (player, menu) ->
  restrict: 'AE'
  templateUrl: '/views/toolbar.html'
  replace: true
  scope: {}
  link: (scope, elem) ->
    scope.getPod = player.getPod
    scope.setVolume = player.setVolume
    scope.getVolume = player.getVolume
    scope.showMenu = menu.showMenu
    scope.togglePlay = ->
      player.podClick player.getPod()