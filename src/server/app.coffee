database = require('./database.js')()
database.attachDatabase()
feedsCtrl = require('./feeds.js')(database)
doPoll = ->
  feedsCtrl.pollFeeds ->
    console.log 'POLL CALLBACK'
    setTimeout doPoll, 60 * 1000
doPoll()
express = require 'express'
session = require 'express-session'
fileupload = require 'express-fileupload'
compression = require 'compression'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
passport = require 'passport'
flash = require 'connect-flash'
http = require 'http'
fs = require 'fs'
socket = require './socket.js'
token = require './token.js'
maintenance = require './maintenance.js'
app = express()
port = process.env.PORT || 23232
app.use compression()
.use fileupload()
.use maintenance
  database: database
.use cookieParser 'P04caddy'
.use bodyParser.json()
.use session
  secret: process.env.SESSION_SECRET
  saveUninitialized: true
  resave: true
.use passport.initialize()
.use passport.session()
.use flash()
.use token
  database: database

require('./passport.js')(passport, database)

app.post '/maintenance-on', (req, res) ->
  if req.body.key is process.env.CLOUDINARY_SECRET
    database.maintenanceOn()
    res.end 'Maintenance Mode On'
  else
    res.end 'OK'
  
app.post '/maintenance-off', (req, res) ->
  if req.body.key is process.env.CLOUDINARY_SECRET
    database.maintenanceOff()
    res.end 'Maintenance Mode Off'
  else
    res.end 'OK'
  
app.get '/test', (req, res) ->
  data = database.exec 'SELECT * FROM f WHERE t LIKE "%ogelnest%"', 'robably'
  res.json data
  
app.post '/api/pods', (req, res) ->
  data = []
  props = []
  where = ''
  subsJoin = ''
  if req.body.feedSlug
    props.push new Date('2001/01/01').valueOf()
    props.push new Date().valueOf()
    props.push req.body.feedSlug
    where = ' AND f.s=? '
  else
    if req.user
      props.push new Date().setHours(new Date().getHours() - (24 * 7)).valueOf()
      props.push new Date().valueOf()
      props.push req.user._id
      where = ' AND s.u=? '
      subsJoin = ' LEFT JOIN s ON i.f=s.f '
    else
      props.push new Date().setHours(new Date().getHours() - 24).valueOf()
      props.push new Date().valueOf()
      where = ''
  
  if not req.user
    data = database.exec 'SELECT i.t as title, i.d as description, i.u as url, i.l as length, i.p as pubDate, i.s as slug, f.t AS feedTitle, f.iu as imageUrl, f.s as feedSlug, f.c as categories FROM i LEFT JOIN f on i.f=f.i WHERE i.p > ? AND i.p < ? ' + where + ' ORDER BY i.p DESC', props
  else
    data = database.exec 'SELECT i.i as _id, i.t as title, i.d as description, i.u as url, i.l as length, i.p as pubDate, i.s as slug, f.t AS feedTitle, f.iu as imageUrl, f.s as feedSlug, f.c as categories, l.d as listened FROM i LEFT JOIN f on i.f=f.i ' + subsJoin + ' LEFT JOIN l ON l.p=i.i WHERE i.p > ? AND i.p < ? ' + where + ' ORDER BY i.p DESC', props
  res.json data
  
app.post '/api/feeds', (req, res) ->
  props = []
  if req.user
    props.push req.user._id
  else
    props.push 'nobody'
  data = database.exec 'SELECT f.i AS feedId, f.t AS feedTitle, f.d AS feedDescription, f.iu as imageUrl, f.s as feedSlug, f.c as categories, s.d as subscribed FROM f LEFT JOIN s ON s.f=f.i AND s.u=? ORDER BY f.t ASC', props
  res.json data
  
app.post '/api/report-listen', (req, res) ->
  if req.user and req.body.podId
    prevListen = database.exec 'SELECT * FROM l WHERE p=? AND u=?', [req.body.podId, req.user._id]
    if prevListen and prevListen.length
      #do nothing
    else
      database.exec 'INSERT INTO l VALUES ?', [{
        p: req.body.podId
        u: req.user._id
        d: new Date().valueOf()
      }]
  res.end 'OK'
  
app.post '/api/subscribe', (req, res) ->
  if req.user and req.body.feedId
    feedsCtrl.subscribe req.user._id, req.body.feedId
  res.end 'OK'
app.post '/api/unsubscribe', (req, res) ->
  if req.user and req.body.feedId
    database.exec 'UPDATE s SET f=? WHERE u=? AND f=?', ['.', req.user._id, req.body.feedId]
  res.end 'OK'
  
app.post '/api/add-feed', (req, res) ->
  if req.user._id and req.body.feedUrl
    feedsCtrl.addFeed req.user._id, req.body.feedUrl, (err, feed) ->
      if err
        if feed
          feed.error = err
          res.json feed
        else
          res.json
            error: err
      else
        res.json feed
  else
    res.end 'OK'
  
app.post '/api/refresh-login', (req, res) ->
  if req.user
    res.end JSON.stringify req.user
  else
    res.end 'error'
    
app.post '/api/upload/database', (req, res) ->
  if req.body.key is process.env.CLOUDINARY_SECRET
    req.files.podcaddyDatabase.mv './podcaddy.json', (err) ->
      if err
        res.status 500
        .send err
      else
        database.attachDatabase()
        res.send 'File Uploaded'
  else
    res.end 'OK'
      
app.post '/api/getdb', (req, res) ->
  console.log 'key', req.body.key
  if database.maintenance and req.body.key and req.body.key is process.env.CLOUDINARY_SECRET
    res.sendFile 'podcaddy.json', root:'./'
  else
    res.end 'OK'
    
app.post '/api/memory', (req, res) ->
  if req.body.key and req.body.key is process.env.CLOUDINARY_SECRET
    res.end (process.memoryUsage().rss / 1048576).toString()
  else
    res.end 'OK'

require('./passport_routes.js') app, passport
require('./angular_routes.js') app

server = http.createServer app
socket.setup server

server.listen port, ->
  console.log 'api server listening on', port