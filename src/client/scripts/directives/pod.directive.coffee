'use strict'

angular.module 'pod'
.directive 'pod', (player) ->
  restrict: 'E'
  templateUrl: 'views/pod.html'
  replace: true
  link: (scope, elem) ->
    scope.pod.displayed = true
    scope.podClick = (e) ->
      player.podClick scope.pod
    scope.$on '$destroy', ->
      scope.pod.displayed = false