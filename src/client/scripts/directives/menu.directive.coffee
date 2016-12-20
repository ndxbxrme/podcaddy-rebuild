'use strict'

angular.module 'pod'
.directive 'menu', (menu, $location, player, auth) ->
  restrict: 'AE'
  templateUrl: '/views/menu.html'
  replace: true
  scope: {}
  link: (scope, elem) ->
    scope.hideMenu = menu.hideMenu
    scope.getMenuOut = menu.getMenuOut
    scope.goTo = (url) ->
      menu.hideMenu()
      $location.path url
    scope.getDirection = player.getDirection
    scope.setDirection = (dir) ->
      player.setDirection dir
      menu.hideMenu()
    scope.getFilter = player.getFilter
    scope.setFilter = (filter) ->
      player.setFilter filter
      menu.hideMenu()
    scope.getUser = auth.getUser
    scope.addFeed = ->
      menu.showAddFeed()
      menu.hideMenu()