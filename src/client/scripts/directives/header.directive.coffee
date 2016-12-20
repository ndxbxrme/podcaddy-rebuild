'use strict'

angular.module 'pod'
.directive 'header', () ->
  restrict: 'AE'
  templateUrl: '/views/header.html'
  replace: true
  scope: {}
  link: (scope, elem) ->