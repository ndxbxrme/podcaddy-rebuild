'use strict'
request = require 'request'
ObjectID = require 'bson-objectid'
S = require 'string'
xml2js = require 'xml2js'
require('./heapdump.js').init('./')

module.exports = (database) ->
  extractImage = (feed) ->
    if feed.image and feed.image.length and feed.image[0].url and feed.image[0].url.length
      return feed.image[0].url
    if feed['itunes:image'] and feed['itunes:image'].length and feed['itunes:image'][0].$ and feed['itunes:image'][0].$.href
      return feed['itunes:image'][0].$.href
    if feed['media:thumbnail'] and feed['media:thumbnail'].length and feed['media:thumbnail'][0].$ and feed['media:thumbnail'][0].$.url and feed['media:thumbnail'][0].$.url.length
      return feed['media:thumbnail'][0].$.url[0]
    if feed['media:thumbnail'] and feed['media:thumbnail'].length and feed['media:thumbnail'][0].$ and feed['media:thumbnail'][0].$.media
      return feed['media:thumbnail'][0].$.media
  checkValidItem = (item) ->
    item.enclosure and item.enclosure.length and item.enclosure[0].$.url
  checkValidFeed = (feed) ->
    feed and feed.rss and feed.rss.channel and feed.rss.channel.length and feed.rss.channel[0].item and feed.rss.channel[0].item.length           
  updateFeed = (url, parsedFeed, feedError, cb) ->
    if not feedError
      categories = []
      if parsedFeed['itunes:category']
        for item in parsedFeed['itunes:category']
          if item and item.$ and item.$.text
            categories.push item.$.text.toLowerCase()
      else if parsedFeed.category
        for item in parsedFeed.category
          if item
            if item.$ and item.$.text
              categories.push item.$.text.toLowerCase()
            else
              categories.push item.toString().toLowerCase()
      database.exec 'UPDATE feeds SET updated=?, title=?, slug=?, description=?, link=?, image=?, imageUrl=?, categories=?, pubDate=? WHERE url=?', [
        new Date().valueOf()
        S(parsedFeed.title).stripTags().decodeHTMLEntities().truncate(255).s
        S(parsedFeed.title).stripTags().decodeHTMLEntities().truncate(30).slugify().s
        S(parsedFeed.description).stripTags().decodeHTMLEntities().truncate(255).s
        parsedFeed.link
        parsedFeed.image
        parsedFeed.imageUrl
        categories
        new Date(parsedFeed.pubDate).valueOf()
        url
      ]
      categories = null
    else
      database.exec 'UPDATE feeds SET updated=? WHERE url=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), url]
    parsedFeed = null
    cb?(feedError)
    return
  uploadImage = (parsedFeed, cb) ->
    imgsrc = extractImage parsedFeed
    parsedFeed.image = imgsrc
    parsedFeed.imageUrl = imgsrc
    console.log 'upload image'
    cb?()
    return
  fetchFeed = (url, cb) ->
    parser = new xml2js.Parser()
    feedError = false
    fid = null
    feed = database.exec 'SELECT _id, imageUrl FROM feeds WHERE url=?', [url]
    if feed and feed.length
      fid = feed[0]._id
      console.log 'FOUND FEED', feed
    else
      fid = ObjectID()
      database.exec 'INSERT INTO feeds VALUES ?', [{
        _id: fid
        url: url
      }]
    console.log 'fetching', url
    options = 
      url: url
    request options, (err, res, body) ->
      res = null
      if err or not body
        console.log 'body error'
        updateFeed url, null, true, cb
      else
        console.log 'body good'
        parser.parseString body, (err, data) ->
          body = null
          if(err)
            console.log 'parser error', err
            data = null
            updateFeed url, null, true, cb
          else
            console.log 'parser good'
            if not checkValidFeed data
              console.log 'not a valid feed'
              data = null
              updateFeed url, null, true, cb
            else
              console.log 'all good'
              # all good
              parsedFeed = data.rss.channel[0]
              inserted = 0
              updated = 0
              
              for item in parsedFeed.item
                #for key of item
                #  console.log key
                if item.enclosure and item.enclosure.length and item.enclosure[0].$.url and item.enclosure[0].$.url.indexOf('.mp3') isnt -1
                  pod = 
                    _id: ObjectID()
                    title: S(item.title).replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(255).s
                    slug: S(item.title).replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(30).slugify().s
                    description: S(item.description).replace(/<!\[CDATA|]]>/g,'').stripTags().decodeHTMLEntities().truncate(255).s
                    url: item.enclosure[0].$.url
                    length: item.enclosure[0].$.length
                    pubDate: new Date(item.pubDate).valueOf()
                  itemExists = database.exec 'SELECT _id, url FROM items WHERE fid=? AND pubDate=?', [fid, pod.pubDate]
                  if itemExists and itemExists.length
                    #update
                    if itemExists[0].url isnt pod.url
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
                    #insert
                    database.exec 'INSERT INTO items VALUES ?', [pod]
                    inserted++
                  itemExists = null
                  pod = null
              data = null
              if inserted then console.log 'inserted', inserted
              if updated then console.log 'updated', updated
              
              if feed[0].imageUrl
                parsedFeed.image = extractImage parsedFeed
                parsedFeed.imageUrl = feed[0].imageUrl
                updateFeed(url, parsedFeed, false, cb)
              else
                uploadImage parsedFeed, ->
                  updateFeed url, parsedFeed, false, cb
              feed = null
          return
    return
  pollFeeds = ->
    global.gc()
    dateNow = new Date().setHours(new Date().getHours()-4).valueOf()
    feeds = database.exec 'SELECT url FROM feeds WHERE updated<? LIMIT 1', [dateNow]
    if feeds and feeds.length
      fetchFeed feeds[0].url, pollFeeds
    else
      pollFeeds()
    feeds = null
    return
  pollFeeds()
  