'use strict'

angular.module 'pod'
.directive 'login', (auth) ->
  restrict: 'AE'
  templateUrl: '/views/login.html'
  replace: true
  scope: {}
  link: (scope, elem) ->
    scope.getUser = auth.getUser
    
    login = ->
      scope.submitted = true
      if scope.loginForm.$valid
        $http.post '/api/login',
          email: scope.email
          password: scope.password
        .success ->
          $location.path '/'
        .error ->
          scope.submitted = false
    signup = ->
      scope.submitted = true
      if scope.loginForm.$valid
        $http.post '/api/signup',
          email: scope.email
          password: scope.password
        .success ->
          $location.path '/'
        .error ->
          scope.submitted = false