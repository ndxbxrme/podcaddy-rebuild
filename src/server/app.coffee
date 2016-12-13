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
  
app.get '/test', (req, res) ->
  data = database.exec 'SELECT * FROM i INNER JOIN f ON f.i=i.f'
  res.end JSON.stringify data
  
app.post '/api/today', (req, res) ->
  data = []
  if not req.user
    data = database.exec 'SELECT i.t as title, i.d as description, i.u as url, i.l as length, i.p as pubDate, i.s as slug, f.t AS feedTitle, f.iu as imageUrl, f.s as feedSlug, f.c as categories FROM i LEFT JOIN f on i.f=f.i WHERE i.p > ? AND i.p < ? ORDER BY i.p DESC', [new Date().setHours(new Date().getHours() - 24).valueOf(), new Date().valueOf()]
  else
    data = database.exec 'SELECT i.t as title, i.d as description, i.u as url, i.l as length, i.p as pubDate, i.s as slug, f.t AS feedTitle, f.iu as imageUrl, f.s as feedSlug, f.c as categories FROM s INNER JOIN i ON i.f=s.f LEFT JOIN f on i.f=f.i WHERE s.u=? AND i.p > ? AND i.p < ? ORDER BY i.p DESC', [req.user._id, new Date().setHours(new Date().getHours() - (24 * 7)).valueOf(), new Date().valueOf()]
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