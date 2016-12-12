'use strict'

parser = require 'parse-rss'
require('./heapdump.js').init('./')
S = require 'string'
ObjectID = require 'bson-objectid'
fs = require 'fs'
socket = require './socket.js'
async = require 'async'

module.exports = (database) ->
  noFeeds = database.exec 'SELECT count(url) as c FROM feeds'
  console.log noFeeds[0].c, 'feederz'
  count = 0
  pollFeeds = ->
    global.gc()
    feedError = 0
    dateNow = new Date().valueOf()
    feeds = database.exec 'SELECT _id, url, imageUrl, updated FROM feeds WHERE updated<? ORDER BY updated ASC LIMIT 1', [dateNow]
    if feeds and feeds.length and not database.maintenance
      database.exec 'UPDATE feeds SET updated=? WHERE _id=?', [new Date().setMinutes(new Date().getMinutes() + 2000).valueOf(), feeds[0]._id]
      console.log '-------------------', ++count, '/', noFeeds[0].c, '------', feeds[0].url, feeds[0].updated
      parser 
        url:feeds[0].url
        headers: 
          'User-Agent': 'Podcaddy'
      , (err, data) ->
        if not err and data and data.length
          inserted = 0
          updated = 0
          skipped = 0
          if feeds[0].imageUrl
            database.exec 'UPDATE feeds SET updated=?, title=?, slug=?, description=?, link=?, image=?, imageUrl=?, categories=?, pubDate=? WHERE url=?', [
              new Date().valueOf() + (2 * 60 * 60 * 1000)
              S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(255).s
              S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(30).slugify().s
              S(data[0].meta.description or '').stripTags().decodeHTMLEntities().truncate(255).s
              data[0].meta.link
              feeds[0].image
              feeds[0].imageUrl
              data[0].meta.categories
              new Date(data[0].meta.pubDate).valueOf()
              feeds[0].url
            ]
          else
            console.log 'upload to cloudinary', feeds[0]
          pubDates = database.exec 'SELECT DISTINCT(pubDate) AS pubDate FROM ?', [data]
          async.each pubDates, (pubDate, callback) ->
            console.log 'item'
            item = database.exec 'SELECT * FROM ? WHERE pubDate=?', [data, pubDate.pubDate]
            if item and item.length and item[0].enclosures and item[0].enclosures.length and item[0].enclosures[0].type and item[0].enclosures[0].type.indexOf('audio') isnt -1
              pod = 
                _id: ObjectID.generate()
                fid: feeds[0]._id
                title: S(item[0].title || '').replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(255).s
                slug: S(item[0].title || '').replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(30).slugify().s
                description: S(item[0].description || '').replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(255).s
                url: if item[0].enclosures then item[0].enclosures[0].url else ''
                length: if item[0].enclosures then item[0].enclosures[0].length else 0
                pubDate: new Date(item[0].pubDate).valueOf()
              itemExists = database.exec 'SELECT _id, url FROM items WHERE fid=? AND (pubDate=? OR url=?)', [pod.fid, pod.pubDate, pod.url]
              if itemExists and itemExists.length
                #update
                if itemExists[0].url isnt pod.url
                  console.log itemExists[0].url
                  console.log pod.url
                  database.exec 'UPDATE items SET title=?, slug=?, description=?, url=?, length=? WHERE pubDate=?', [
                    pod.title
                    pod.slug
                    pod.description
                    pod.url
                    pod.length
                    pod.pubDate
                  ]
                  updated++
                else
                  skipped++
              else
                #insert
                database.exec 'INSERT INTO items VALUES ?', [pod]
                inserted++
              itemExists = null
              pod = null
              item = null
              console.log 'dealt with'
              callback()
          , ->
            console.log '-----', inserted, 'inserted -----', updated, 'updated -----', skipped, 'skipped -----'
            if inserted
              usersToNotify = database.exec 'SELECT DISTINCT(users._id) AS _id FROM users INNER JOIN subs ON subs.uid=users._id WHERE subs.pid=?', [feeds[0]._id]
              if usersToNotify and usersToNotify.length
                console.log 'there are peepz to notify', usersToNotify
                socket.emitToUsers usersToNotify, 'feeds', 'updated'
              usersToNotify = null
            if feeds and feeds.length and feedError < 2
              setTimeout pollFeeds, 10
            data = null
            return
        else
          console.log 'error', err
          feedError++
          if feeds and feeds.length
            database.exec 'UPDATE feeds SET updated=? WHERE _id=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), feeds[0]._id]
          if feeds and feeds.length and feedError < 2
            setTimeout pollFeeds, 10
          data = null
    else
      if not database.maintenance
        count = 0
      else
        console.log 'Maintenance Mode'
      #fs.writeFileSync './podcaddy.json', JSON.stringify database
      #feeds = null
      global.gc()
      setTimeout pollFeeds, 60 * 1000
    return
  pollFeeds()