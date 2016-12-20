'use strict'

angular.module 'pod'
.directive 'pod', (player) ->
  restrict: 'E'
  templateUrl: 'views/pod.html'
  replace: true
  link: (scope, elem) ->
    scope.pod.displayed = true
    scope.podClick = (e) ->
      if e.target.tagName isnt 'A' and e.target.parentNode.tagName isnt 'A'
        player.podClick scope.pod
    scope.$on '$destroy', ->
      scope.pod.displayed = false