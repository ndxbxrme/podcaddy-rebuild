(function() {
  var FeedParser, ObjectID, S, fs, request;

  request = require('request');

  FeedParser = require('feedparser');

  ObjectID = require('bson-objectid');

  S = require('string');

  require('./heapdump.js').init('./');

  fs = require('fs');

  module.exports = function(database) {
    var fetchFeed, pollFeeds;
    fetchFeed = function(url) {
      var body, feed, feedError, feedparser, fid, req;
      console.log('fetchFeed');
      feedError = false;
      fid = null;
      feed = database.exec('SELECT _id, imageUrl FROM feeds WHERE url=?', [url]);
      if (feed && feed.length) {
        fid = feed[0]._id;
      } else {
        fid = ObjectID();
        database.exec('INSERT INTO feeds VALUES ?', [
          {
            _id: fid,
            url: url
          }
        ]);
      }
      console.log('fetching', url);
      feedparser = new FeedParser();
      req = request(url);
      body = '';
      req.on('response', function(res) {
        body = res.body;
        return this.pipe(feedparser);
      });
      req.on('error', function(e) {
        return feedError = true;
      });
      feedparser.on('readable', function() {
        var item, itemExists, pod, results;
        results = [];
        while (item = feedparser.read()) {
          if (item.enclosures && item.enclosures.length && item.enclosures[0].url && item.enclosures[0].url.indexOf('.mp3') !== -1) {
            pod = {
              _id: ObjectID(),
              title: S(item.title || '').stripTags().decodeHTMLEntities().truncate(255).s,
              slug: S(item.title || '').stripTags().decodeHTMLEntities().truncate(30).slugify().s,
              description: S(item.description || '').stripTags().decodeHTMLEntities().truncate(255).s,
              url: item.enclosures[0].url,
              length: item.enclosures[0].length,
              pubDate: new Date(item.pubDate).valueOf()
            };
            itemExists = database.exec('SELECT _id FROM items WHERE fid=? AND pubDate=?', [fid, pod.pubDate]);
            if (itemExists && itemExists.length) {
              results.push(database.exec('UPDATE items SET title=?, slug=?, description=?, url=?, length=? WHERE pubDate=?', [pod.title, pod.slug, pod.description, pod.url, pod.length, pod.pubDate]));
            } else {
              results.push(database.exec('INSERT INTO items VALUES ?', [pod]));
            }
          } else {
            results.push(void 0);
          }
        }
        return results;
      });
      feedparser.on('error', function(e) {
        feedError = true;
        fs.writeFileSync('./error' + (new Date().valueOf()) + '.xml', body, 'utf-8');
        return console.log('error', e);
      });
      return feedparser.on('end', function() {
        var updateFeed, uploadImage;
        console.log(feedparser.meta.title);
        updateFeed = function() {
          if (!feedError) {
            database.exec('UPDATE feeds SET updated=?, title=?, slug=?, description=?, link=?, image=?, imageUrl=?, categories=?, pubDate=? WHERE url=?', [new Date().valueOf(), S(feedparser.meta.title || '').stripTags().decodeHTMLEntities().truncate(255).s, S(feedparser.meta.title || '').stripTags().decodeHTMLEntities().truncate(30).slugify().s, S(feedparser.meta.description || '').stripTags().decodeHTMLEntities().truncate(255).s, feedparser.meta.link, feed[0].image, feed[0].imageUrl, feedparser.meta.categories, new Date(feedparser.meta.pubDate).valueOf(), url]);
          } else {
            database.exec('UPDATE feeds SET updated=? WHERE url=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), url]);
          }
          return setTimeout(pollFeeds, 100);
        };
        uploadImage = function() {
          console.log('upload image');
          return updateFeed();
        };
        if (feed[0].imageUrl) {
          return updateFeed();
        } else {
          return uploadImage();
        }
      });
    };
    pollFeeds = function() {
      var dateNow, feeds;
      global.gc();
      dateNow = new Date().setHours(new Date().getHours() - 4).valueOf();
      feeds = database.exec('SELECT url FROM feeds WHERE updated<? LIMIT 1', [dateNow]);
      if (feeds && feeds.length) {
        return fetchFeed(feeds[0].url);
      }
    };
    return pollFeeds();
  };

}).call(this);

//# sourceMappingURL=polling3.js.map
