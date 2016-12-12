'use strict'
angular.module 'pod'
.factory 'socket', (player, auth) ->
  socket = io()
  socket.on 'connect', ->
    console.log 'socket connected'
    user = auth.getUser()
    if user
      socket.emit 'user', user._id
  socket.on 'disconnect', ->
    console.log 'disconnected'
  socket.on 'feeds', ->
    player.fetchPods()
  emit: (message, data) ->
    socket.emit message, data