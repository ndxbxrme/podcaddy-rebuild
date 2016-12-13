'use strict'

parser = require 'parse-rss'
require('./heapdump.js').init('./')
S = require 'string'
ObjectID = require 'bson-objectid'
fs = require 'fs'
socket = require './socket.js'
async = require 'async'

module.exports = (database) ->
  noFeeds = database.exec 'SELECT count(u) as c FROM f'
  console.log noFeeds[0].c, 'feederz'
  count = 0
  pollFeeds = ->
    global.gc()
    feedError = 0
    dateNow = new Date().setHours(new Date().getHours()+2).valueOf()
    feeds = database.exec 'SELECT i, u, iu, up FROM f WHERE up<? ORDER BY up ASC LIMIT 1', [dateNow]
    if feeds and feeds.length and not database.maintenance
      database.exec 'UPDATE f SET up=? WHERE i=?', [new Date().setMinutes(new Date().getMinutes() + 2000).valueOf(), feeds[0].i]
      console.log '-------------------', ++count, '/', noFeeds[0].c, '------', feeds[0].u, feeds[0].up
      parser 
        url:feeds[0].u
        headers: 
          'User-Agent': 'Podcaddy'
      , (err, data) ->
        if not err and data and data.length
          inserted = 0
          updated = 0
          skipped = 0
          if feeds[0].iu
            database.exec 'UPDATE f SET up=?, t=?, s=?, d=?, l=?, im=?, iu=?, c=?, p=? WHERE u=?', [
              new Date().valueOf() + (2 * 60 * 60 * 1000)
              S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(255).s
              S(data[0].meta.title or '').stripTags().decodeHTMLEntities().truncate(30).slugify().s
              S(data[0].meta.description or '').stripTags().decodeHTMLEntities().truncate(255).s
              data[0].meta.link
              feeds[0].im
              feeds[0].iu
              data[0].meta.categories
              new Date(data[0].meta.pubDate).valueOf()
              feeds[0].u
            ]
          else
            console.log 'upload to cloudinary', feeds[0]
          pubDates = database.exec 'SELECT DISTINCT(pubDate) AS pubDate FROM ?', [data]
          inserts = []
          async.each pubDates, (pubDate, callback) ->
            item = database.exec 'SELECT * FROM ? WHERE pubDate=?', [data, pubDate.pubDate]
            if item and item.length and item[0].enclosures and item[0].enclosures.length and item[0].enclosures[0].type and item[0].enclosures[0].type.indexOf('audio') isnt -1
              pod = 
                i: ObjectID.generate()
                f: feeds[0].i
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
                inserted++
              itemExists = null
              item = null
            callback()
          , ->
            console.log '-----', inserted, 'inserted -----', updated, 'updated -----', skipped, 'skipped -----'
            if inserted
              console.log inserts.length
              database.exec 'SELECT * INTO i FROM ?', [inserts]
              #inserts = null
              usersToNotify = database.exec 'SELECT DISTINCT(u._id) AS _id FROM u INNER JOIN s ON s.u=u._id WHERE s.f=?', [feeds[0].i]
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
            database.exec 'UPDATE f SET u=? WHERE i=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), feeds[0].i]
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