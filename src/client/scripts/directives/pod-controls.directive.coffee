'use strict'

angular.module 'pod'
.directive 'podControls', (player) ->
  restrict: 'E'
  templateUrl: 'views/pod-controls.html'
  replace: true
  link: (scope, elem) ->
    scope.controlsClick = (e) ->
      console.log e.layerX, $('.statusbar', elem).width()
      e.preventDefault()
      e.cancelBubble = true
      player.setPosition e.layerX/$('.statusbar', elem).width()
      console.log 'controls click'