'use strict'
crypto = require 'crypto-js'

postAuthenticate = (req, res, next) ->
  console.log 'post authenticate', req.user
  if req.user
    cookieText = req.user._id + '||' + new Date().toString()
    cookieText = crypto.Rabbit.encrypt(cookieText, process.env.SESSION_SECRET).toString()
    res.cookie 'podcaddy', cookieText, maxAge: 7 * 24 * 60 * 60 * 1000
  res.redirect '/'
module.exports = (app, passport) ->
  app.post '/api/signup', passport.authenticate('local-signup')
  , postAuthenticate
  app.post '/api/login', passport.authenticate('local-login')
  , postAuthenticate
  app.get '/api/twitter', passport.authenticate('twitter', scope: 'email')
  , postAuthenticate
  app.get '/api/twitter/callback', passport.authenticate('twitter')
  , postAuthenticate
  app.get '/api/facebook', passport.authenticate('facebook', scope: 'email')
  app.get '/api/facebook/callback', passport.authenticate('facebook')
  , postAuthenticate
  app.get '/api/github', passport.authenticate('github', scope: [
    'user'
    'user:email'
  ])
  app.get '/api/github/callback', passport.authenticate('github')
  , postAuthenticate
  #LOGIN CONNECT ACCOUNTS
  app.get '/api/connect/local', (req, res) ->
    #send flash message
    return
  app.post '/api/connect/local', passport.authorize('local-signup')
  app.get '/api/connect/twitter', passport.authorize('twitter',
    scope: 'email')
  app.get '/api/connect/facebook', passport.authorize('facebook',
    scope: 'email')
  app.get '/api/connect/github', passport.authorize('github',
    scope: [
      'user'
      'user:email'
    ]
    successRedirect: '/profile')
  #UNLINK ACCOUNTS
  app.get '/api/unlink/local', (req, res) ->
    user = req.user
    user.local.email = undefined
    user.local.password = undefined
    user.save (err) ->
      res.redirect '/profile'
      return
    return
  app.get '/api/unlink/twitter', (req, res) ->
    user = req.user
    user.twitter.token = undefined
    user.save (err) ->
      res.redirect '/profile'
      return
    return
  app.get '/api/unlink/facebook', (req, res) ->
    user = req.user
    user.facebook.token = undefined
    user.save (err) ->
      res.redirect '/profile'
      return
    return
  app.get '/api/unlink/github', (req, res) ->
    user = req.user
    user.github.token = undefined
    user.save (err) ->
      res.redirect '/profile'
      return
    return
  app.get '/api/logout', (req, res) ->
    res.clearCookie 'podcaddy'
    res.redirect '/'
    return