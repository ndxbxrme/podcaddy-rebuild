'use strict'

angular.module 'pod'
.factory 'menu', ($timeout) ->
  menuOut = false
  addFeedOut = false
  showHideMenu = ->
    if menuOut
      position = $('.menu-anchor').offset()
      $('.popout').css
        left: position.left + 'px'
        top: position.top + 'px'

  showMenu: ->
    $timeout ->
      menuOut = true
      showHideMenu()
  hideMenu: ->
    $timeout ->
      menuOut = false
      showHideMenu()
  getMenuOut: ->
    menuOut
  showAddFeed: ->
    $timeout ->
      addFeedOut = true
  hideAddFeed: ->
    $timeout ->
      addFeedOut = false
  getAddFeedOut: ->
    addFeedOut