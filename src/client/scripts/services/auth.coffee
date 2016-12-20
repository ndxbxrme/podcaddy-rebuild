angular.module 'pod'
.factory 'auth', ($http, $q, $timeout) ->
  user = null
  getUserPromise: ->
    defer = $q.defer()
    if user
      defer.resolve user
    else
      $http.post '/api/refresh-login'
      .then (data) ->
        if data and data.data isnt 'error'
          user = data.data
          defer.resolve user
        else 
          user = null
          defer.reject {}
      , ->
        user = null
        defer.reject {}
    defer.promise
  getUser: ->
    user