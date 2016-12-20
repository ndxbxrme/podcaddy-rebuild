'use strict'

parser = require 'parse-rss'
#require('./heapdump.js').init('./')
S = require 'string'
ObjectID = require 'bson-objectid'
fs = require 'fs'
socket = require './socket.js'
async = require 'async'
cloudinary = require 'cloudinary'
validUrl = require 'valid-url'

cloudinary.config
  cloud_name: process.env.CLOUDINARY_NAME
  api_key: process.env.CLOUDINARY_KEY
  api_secret: process.env.CLOUDINARY_SECRET

module.exports = (database) ->
  subscribe = (userId, feedId) ->
    alreadySubbed = database.exec 'SELECT * FROM s WHERE u=? AND f=?', [userId, feedId]
    if alreadySubbed and alreadySubbed.length
      #do nothing
    else
      nulls = database.exec 'SELECT * FROM s WHERE u=? AND f=?', [userId, '.']
      if nulls and nulls.length
        console.log 'updating a null'
        database.exec 'UPDATE s SET f=?, d=? WHERE d=?', [feedId, new Date().valueOf(), nulls[0].d]
      else
        database.exec 'INSERT INTO s VALUES ?', [{
          u: userId
          f: feedId
          d: new Date().valueOf()
        }]
  uploadImage = (imageUrl, callback) ->
    cloudinary.uploader.upload imageUrl, (cRes) ->
      if not cRes.error
        callback null, cRes.secure_url
      else
        cloudinary.uploader.upload 'https://unsplash.it/200/200/?random', (cRes) ->
          if not cRes.error
            callback null, cRes.secure_url
          else
            callback 'Upload Error', ''
    ,
      crop: 'thumb'
      width: 200
      height: 200
      tags: [
        'podcast'
        'feed_image'
      ]
  #public api
  subscribe: subscribe
  addFeed: (userId, url, callback) ->
    callbackCount = 0
    if database.maintenance()
      return callback 'Database Maintenance'
    if not validUrl.isUri url
      return callback 'Not a URL'
    parser
      url:url
      headers:
        'User-Agent': 'Podcaddy'
    , (err, data) ->
      if err
        if callbackCount++ < 1
          return callback 'Could not parse document'
      if data and data.length
        console.log 'got feed'
        feed =
          i: ObjectID.generate()
          u: url
          up: new Date().setHours(new Date().getHours() - 2).valueOf()
          t:S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(255).s
          s:S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(30).slugify().s
          d:S(data[0].meta.description or '').stripTags().decodeHTMLEntities().truncate(255).s
          l:data[0].meta.link
          im:data[0].meta.image.url
          iu:null
          c:data[0].meta.categories
          p:new Date(data[0].meta.pubDate).valueOf()
        feedExists = database.exec 'SELECT * FROM f WHERE (t+d)=?', [feed.t + feed.d]
        if feedExists and feedExists.length
          subscribe userId, feedExists[0].i
          if callbackCount++ < 1
            return callback 'Feed already exists', feedExists[0]
        else
          if data[0].meta and data[0].meta.image and data[0].meta.image.url
            uploadImage data[0].meta.image.url, (err, imageUrl) ->
              if err
                if callbackCount++ < 1
                  return callback err
              console.log 'uploaded image'
              feed.iu = imageUrl
              database.exec 'INSERT INTO f VALUES ?', [feed]
              subscribe userId, feed.i
              if callbackCount++ < 1
                return callback null, feed
          else
            if callbackCount++ < 1
              return callback 'No Image'
      else
        if callbackCount++ < 1
          return callback 'No Data'
  pollFeeds: (pollCallback) ->
    if database.maintenance()
      return pollCallback()
    count = 0
    dateNow = new Date().valueOf()
    feeds = database.exec 'SELECT i, u, iu, up FROM f WHERE up<? ORDER BY up ASC', [dateNow]
    if feeds and feeds.length
      async.eachSeries feeds, (feed, feedCallback) ->
        if database.maintenance()
          return feedCallback()
        else
          global.gc()
          callbackCount = 0
          #database.exec 'UPDATE f SET up=? WHERE i=?', [new Date().setMinutes(new Date().getMinutes() + 2000).valueOf(), feed.i]
          console.log '-------------------', ++count, '/', feeds.length, '------', feed.u, feed.up
          parser 
            url:feed.u
            headers: 
              'User-Agent': 'Podcaddy'
          , (err, data) ->
            if not err and data and data.length
              inserts = []
              inserted = 0
              updated = 0
              skipped = 0
              if feed.iu
                database.exec 'UPDATE f SET up=?, t=?, s=?, d=?, l=?, im=?, iu=?, c=?, p=? WHERE u=?', [
                  new Date().valueOf() + (2 * 60 * 60 * 1000)
                  S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(255).s
                  S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(30).slugify().s
                  S(data[0].meta.description or '').stripTags().decodeHTMLEntities().truncate(255).s
                  data[0].meta.link
                  feed.im
                  feed.iu
                  data[0].meta.categories
                  new Date(data[0].meta.pubDate).valueOf()
                  feed.u
                ]
              else
                console.log 'upload to cloudinary', feed
              pubDates = database.exec 'SELECT DISTINCT(pubDate) AS pubDate FROM ?', [data]
              async.eachSeries pubDates, (pubDate, callback) ->
                setTimeout ->
                  item = database.exec 'SELECT * FROM ? WHERE pubDate=?', [data, pubDate.pubDate]
                  if item and item.length and item[0].enclosures and item[0].enclosures.length and item[0].enclosures[0].type and item[0].enclosures[0].type.indexOf('audio') isnt -1
                    pod = 
                      i: ObjectID.generate()
                      f: feed.i
                      t: S(item[0].title || '').replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(255).s
                      s: S(item[0].title || '').replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(30).slugify().s
                      d: S(item[0].description || '').replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(255).s
                      u: if item[0].enclosures then item[0].enclosures[0].url else ''
                      l: if item[0].enclosures then item[0].enclosures[0].length else 0
                      p: new Date(item[0].pubDate).valueOf()
                    itemExists = database.exec 'SELECT i, u FROM i WHERE f=? AND (p=? OR u=?)', [pod.f, pod.p, pod.u]
                    if itemExists and itemExists.length
                      #update
                      if itemExists[0].u isnt pod.u
                        console.log itemExists[0].u
                        console.log pod.u
                        database.exec 'UPDATE i SET t=?, s=?, d=?, u=?, l=? WHERE p=?', [
                          pod.t
                          pod.s
                          pod.d
                          pod.u
                          pod.l
                          pod.p
                        ]
                        updated++
                      else
                        skipped++
                    else
                      #insert
                      inserts.push pod
                      #database.exec 'INSERT INTO i VALUES ?', [pod]
                      inserted++
                    itemExists = null
                    #pod = null
                    item = null
                  callback()
                , 1
              , ->
                console.log '-----', inserted, 'inserted -----', updated, 'updated -----', skipped, 'skipped -----'
                if inserted
                  #console.log inserts
                  database.exec 'INSERT INTO i SELECT * FROM ?', [inserts]
                  usersToNotify = database.exec 'SELECT DISTINCT(u._id) AS _id FROM u INNER JOIN s ON s.u=u._id WHERE s.f=?', [feed.i]
                  if usersToNotify and usersToNotify.length
                    console.log 'there are peepz to notify', usersToNotify
                    socket.emitToUsers usersToNotify, 'feeds', 'updated'
                  usersToNotify = null
                data = null
                callbackCount++
                if feed and callbackCount < 2
                  console.log 'this one'
                  return feedCallback()
                return
            else
              console.log 'error', err
              callbackCount++
              if feed
                database.exec 'UPDATE f SET up=? WHERE i=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), feed.i]
              data = null
              if callbackCount < 2
                console.log 'theeeeez one'
                return feedCallback()
      , ->
        return pollCallback()
    else
      if not database.maintenance()
        count = 0
      else
        console.log 'Maintenance Mode'
      #fs.writeFileSync './podcaddy.json', JSON.stringify database
      #feeds = null
      global.gc()
      return pollCallback()
    return