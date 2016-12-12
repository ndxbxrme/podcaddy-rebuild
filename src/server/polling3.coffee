request = require 'request'
FeedParser = require 'feedparser'
ObjectID = require 'bson-objectid'
S = require 'string'
require('./heapdump.js').init('./')
fs = require('fs')

module.exports = (database) ->
  fetchFeed = (url) ->
    console.log 'fetchFeed'
    feedError = false
    fid = null
    feed = database.exec 'SELECT _id, imageUrl FROM feeds WHERE url=?', [url]
    if feed and feed.length
      fid = feed[0]._id
      #console.log 'FOUND FEED', feed
    else
      fid = ObjectID()
      database.exec 'INSERT INTO feeds VALUES ?', [{
        _id: fid
        url: url
      }]
    console.log 'fetching', url
    feedparser = new FeedParser()
    req = request url
    body = ''
    req.on 'response', (res) ->
      body = res.body
      @pipe feedparser
    req.on 'error', (e) ->
      feedError = true
    feedparser.on 'readable', ->
      while item = feedparser.read()
        #for key of item
        #  console.log key
        if item.enclosures and item.enclosures.length and item.enclosures[0].url and item.enclosures[0].url.indexOf('.mp3') isnt -1
          pod = 
            _id: ObjectID()
            title: S(item.title or '').stripTags().decodeHTMLEntities().truncate(255).s
            slug: S(item.title or '').stripTags().decodeHTMLEntities().truncate(30).slugify().s
            description: S(item.description or '').stripTags().decodeHTMLEntities().truncate(255).s
            url: item.enclosures[0].url
            length: item.enclosures[0].length
            pubDate: new Date(item.pubDate).valueOf()
          itemExists = database.exec 'SELECT _id FROM items WHERE fid=? AND pubDate=?', [fid, pod.pubDate]
          if itemExists and itemExists.length
            #update
            database.exec 'UPDATE items SET title=?, slug=?, description=?, url=?, length=? WHERE pubDate=?', [
              pod.title
              pod.slug
              pod.description
              pod.url
              pod.length
              pod.pubDate
            ]
            #console.log 'updated'
          else
            #insert
            database.exec 'INSERT INTO items VALUES ?', [pod]
            #console.log 'inserted'
    feedparser.on 'error', (e) ->
      feedError = true
      fs.writeFileSync './error' + (new Date().valueOf()) + '.xml', body, 'utf-8'
      console.log 'error', e
    feedparser.on 'end', ->
      console.log feedparser.meta.title
      updateFeed = ->
        if not feedError
          database.exec 'UPDATE feeds SET updated=?, title=?, slug=?, description=?, link=?, image=?, imageUrl=?, categories=?, pubDate=? WHERE url=?', [
            new Date().valueOf()
            S(feedparser.meta.title or '').stripTags().decodeHTMLEntities().truncate(255).s
            S(feedparser.meta.title or '').stripTags().decodeHTMLEntities().truncate(30).slugify().s
            S(feedparser.meta.description or '').stripTags().decodeHTMLEntities().truncate(255).s
            feedparser.meta.link
            feed[0].image
            feed[0].imageUrl
            feedparser.meta.categories
            new Date(feedparser.meta.pubDate).valueOf()
            url
          ]
        else
          database.exec 'UPDATE feeds SET updated=? WHERE url=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), url]
        setTimeout pollFeeds, 100
      uploadImage = ->
        console.log 'upload image'
        updateFeed()
      if feed[0].imageUrl
        updateFeed()
      else
        uploadImage()
  pollFeeds = ->
    global.gc()
    dateNow = new Date().setHours(new Date().getHours()-4).valueOf()
    feeds = database.exec 'SELECT url FROM feeds WHERE updated<? LIMIT 1', [dateNow]
    if feeds and feeds.length
      fetchFeed feeds[0].url
  pollFeeds()
  