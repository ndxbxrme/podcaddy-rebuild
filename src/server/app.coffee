database = require('./database.js')()
polling = require('./polling2.js')(database)
express = require 'express'
session = require 'express-session'
compression = require 'compression'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
passport = require 'passport'
flash = require 'connect-flash'
http = require 'http'
socket = require './socket.js'
token = require './token.js'
app = express()
port = process.env.PORT || 23232
app.use compression()
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

app.get '/maintenance-on', (req, res) ->
  database.maintenance = true
  res.end 'Maintenance Mode On'
  
app.get '/maintenance-off', (req, res) ->
  database.maintenance = false
  res.end 'Maintenance Mode Off'
  
app.post '/api/today', (req, res) ->
  data = []
  if not req.user
    data = database.exec 'SELECT items.title, items.description, items.url, items.length, items.pubDate, items.slug, feeds.title AS feedTitle, feeds.imageUrl as imageUrl, feeds.slug as feedSlug, feeds.cagegories FROM items LEFT JOIN feeds on items.fid=feeds._id WHERE items.pubDate > ? AND items.pubDate < ? ORDER BY items.pubDate DESC', [new Date().setHours(new Date().getHours() - 24).valueOf(), new Date().valueOf()]
  else
    data = database.exec 'SELECT items.title, items.description, items.url, items.length, items.pubDate, items.slug, feeds.title AS feedTitle, feeds.imageUrl as imageUrl, feeds.slug as feedSlug, feeds.cagegories FROM subs INNER JOIN items ON items.fid=subs.pid LEFT JOIN feeds on items.fid=feeds._id WHERE subs.uid=? AND items.pubDate > ? AND items.pubDate < ? ORDER BY items.pubDate DESC', [req.user._id, new Date().setHours(new Date().getHours() - (24 * 7)).valueOf(), new Date().valueOf()]
  res.end JSON.stringify data
  
app.post '/api/refresh-login', (req, res) ->
  if req.user
    res.end JSON.stringify req.user
  else
    res.end 'error'

require('./passport_routes.js') app, passport
require('./angular_routes.js') app

server = http.createServer app
socket.setup server

server.listen port, ->
  console.log 'api server listening on', port