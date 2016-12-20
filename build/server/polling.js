(function() {
  'use strict';
  var ObjectID, S, request, xml2js;

  request = require('request');

  ObjectID = require('bson-objectid');

  S = require('string');

  xml2js = require('xml2js');

  require('./heapdump.js').init('./');

  module.exports = function(database) {
    var checkValidFeed, checkValidItem, extractImage, fetchFeed, pollFeeds, updateFeed, uploadImage;
    extractImage = function(feed) {
      if (feed.image && feed.image.length && feed.image[0].url && feed.image[0].url.length) {
        return feed.image[0].url;
      }
      if (feed['itunes:image'] && feed['itunes:image'].length && feed['itunes:image'][0].$ && feed['itunes:image'][0].$.href) {
        return feed['itunes:image'][0].$.href;
      }
      if (feed['media:thumbnail'] && feed['media:thumbnail'].length && feed['media:thumbnail'][0].$ && feed['media:thumbnail'][0].$.url && feed['media:thumbnail'][0].$.url.length) {
        return feed['media:thumbnail'][0].$.url[0];
      }
      if (feed['media:thumbnail'] && feed['media:thumbnail'].length && feed['media:thumbnail'][0].$ && feed['media:thumbnail'][0].$.media) {
        return feed['media:thumbnail'][0].$.media;
      }
    };
    checkValidItem = function(item) {
      return item.enclosure && item.enclosure.length && item.enclosure[0].$.url;
    };
    checkValidFeed = function(feed) {
      return feed && feed.rss && feed.rss.channel && feed.rss.channel.length && feed.rss.channel[0].item && feed.rss.channel[0].item.length;
    };
    updateFeed = function(url, parsedFeed, feedError, cb) {
      var categories, i, item, j, len, len1, ref, ref1;
      if (!feedError) {
        categories = [];
        if (parsedFeed['itunes:category']) {
          ref = parsedFeed['itunes:category'];
          for (i = 0, len = ref.length; i < len; i++) {
            item = ref[i];
            if (item && item.$ && item.$.text) {
              categories.push(item.$.text.toLowerCase());
            }
          }
        } else if (parsedFeed.category) {
          ref1 = parsedFeed.category;
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            item = ref1[j];
            if (item) {
              if (item.$ && item.$.text) {
                categories.push(item.$.text.toLowerCase());
              } else {
                categories.push(item.toString().toLowerCase());
              }
            }
          }
        }
        database.exec('UPDATE feeds SET updated=?, title=?, slug=?, description=?, link=?, image=?, imageUrl=?, categories=?, pubDate=? WHERE url=?', [new Date().valueOf(), S(parsedFeed.title).stripTags().decodeHTMLEntities().truncate(255).s, S(parsedFeed.title).stripTags().decodeHTMLEntities().truncate(30).slugify().s, S(parsedFeed.description).stripTags().decodeHTMLEntities().truncate(255).s, parsedFeed.link, parsedFeed.image, parsedFeed.imageUrl, categories, new Date(parsedFeed.pubDate).valueOf(), url]);
        categories = null;
      } else {
        database.exec('UPDATE feeds SET updated=? WHERE url=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), url]);
      }
      parsedFeed = null;
      if (typeof cb === "function") {
        cb(feedError);
      }
    };
    uploadImage = function(parsedFeed, cb) {
      var imgsrc;
      imgsrc = extractImage(parsedFeed);
      parsedFeed.image = imgsrc;
      parsedFeed.imageUrl = imgsrc;
      console.log('upload image');
      if (typeof cb === "function") {
        cb();
      }
    };
    fetchFeed = function(url, cb) {
      var feed, feedError, fid, options, parser;
      parser = new xml2js.Parser();
      feedError = false;
      fid = null;
      feed = database.exec('SELECT _id, imageUrl FROM feeds WHERE url=?', [url]);
      if (feed && feed.length) {
        fid = feed[0]._id;
        console.log('FOUND FEED', feed);
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
      options = {
        url: url
      };
      request(options, function(err, res, body) {
        res = null;
        if (err || !body) {
          console.log('body error');
          return updateFeed(url, null, true, cb);
        } else {
          console.log('body good');
          return parser.parseString(body, function(err, data) {
            var i, inserted, item, itemExists, len, parsedFeed, pod, ref, updated;
            body = null;
            if (err) {
              console.log('parser error', err);
              data = null;
              updateFeed(url, null, true, cb);
            } else {
              console.log('parser good');
              if (!checkValidFeed(data)) {
                console.log('not a valid feed');
                data = null;
                updateFeed(url, null, true, cb);
              } else {
                console.log('all good');
                parsedFeed = data.rss.channel[0];
                inserted = 0;
                updated = 0;
                ref = parsedFeed.item;
                for (i = 0, len = ref.length; i < len; i++) {
                  item = ref[i];
                  if (item.enclosure && item.enclosure.length && item.enclosure[0].$.url && item.enclosure[0].$.url.indexOf('.mp3') !== -1) {
                    pod = {
                      _id: ObjectID(),
                      title: S(item.title).replace(/<!\[CDATA|]]>/g, '').stripTags().decodeHTMLEntities().truncate(255).s,
                      slug: S(item.title).replace(/<!\[CDATA|]]>/g, '').stripTags().decodeHTMLEntities().truncate(30).slugify().s,
                      description: S(item.description).replace(/<!\[CDATA|]]>/g, '').stripTags().decodeHTMLEntities().truncate(255).s,
                      url: item.enclosure[0].$.url,
                      length: item.enclosure[0].$.length,
                      pubDate: new Date(item.pubDate).valueOf()
                    };
                    itemExists = database.exec('SELECT _id, url FROM items WHERE fid=? AND pubDate=?', [fid, pod.pubDate]);
                    if (itemExists && itemExists.length) {
                      if (itemExists[0].url !== pod.url) {
                        database.exec('UPDATE items SET title=?, slug=?, description=?, url=?, length=? WHERE pubDate=?', [pod.title, pod.slug, pod.description, pod.url, pod.length, pod.pubDate]);
                        updated++;
                      }
                    } else {
                      database.exec('INSERT INTO items VALUES ?', [pod]);
                      inserted++;
                    }
                    itemExists = null;
                    pod = null;
                  }
                }
                data = null;
                if (inserted) {
                  console.log('inserted', inserted);
                }
                if (updated) {
                  console.log('updated', updated);
                }
                if (feed[0].imageUrl) {
                  parsedFeed.image = extractImage(parsedFeed);
                  parsedFeed.imageUrl = feed[0].imageUrl;
                  updateFeed(url, parsedFeed, false, cb);
                } else {
                  uploadImage(parsedFeed, function() {
                    return updateFeed(url, parsedFeed, false, cb);
                  });
                }
                feed = null;
              }
            }
          });
        }
      });
    };
    pollFeeds = function() {
      var dateNow, feeds;
      global.gc();
      dateNow = new Date().setHours(new Date().getHours() - 4).valueOf();
      feeds = database.exec('SELECT url FROM feeds WHERE updated<? LIMIT 1', [dateNow]);
      if (feeds && feeds.length) {
        fetchFeed(feeds[0].url, pollFeeds);
      } else {
        pollFeeds();
      }
      feeds = null;
    };
    return pollFeeds();
  };

}).call(this);

//# sourceMappingURL=polling.js.map
