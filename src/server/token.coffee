'use strict'
crypto = require 'crypto-js'

module.exports = (options) ->
  database = options.database
  return (req, res, next) ->
    req.user = null
    if req.cookies.podcaddy
      decrypted = ''
      try
        decrypted = crypto.Rabbit.decrypt(req.cookies.podcaddy, process.env.SESSION_SECRET).toString(crypto.enc.Utf8)
      if decrypted.indexOf('||') isnt -1
        bits = decrypted.split '||'
        if bits.length is 2
          d = new Date bits[1]
          if d.toString() isnt 'Invalid Date'
            users = database.exec 'SELECT * FROM users WHERE _id=?', [bits[0]]
            if users and users.length
              req.user = users[0]
    ###
    console.log 'SESSION SECRET', process.env.SESSION_SECRET
    cookieText = '5464af915632880200ed93cf||' + new Date().toString()
    console.log cookieText
    cookieText = crypto.Rabbit.encrypt(cookieText, 'podcaddy').toString()
    res.cookie 'podcaddy', cookieText, maxAge: 24 * 60 * 60 * 1000
    ###
    next()