(function() {
  'use strict';
  var ObjectID, S, async, fs, parser, socket;

  parser = require('parse-rss');

  require('./heapdump.js').init('./');

  S = require('string');

  ObjectID = require('bson-objectid');

  fs = require('fs');

  socket = require('./socket.js');

  async = require('async');

  module.exports = function(database) {
    return {
      subscribe: function(userId, feedId) {
        var alreadySubbed, nulls;
        alreadySubbed = database.exec('SELECT * FROM s WHERE u=? AND f=?', [userid, feedId]);
        if (alreadySubbed && alreadySubbed.length) {

        } else {
          nulls = database.exec('SELECT * FROM s WHERE u=? AND f=?', [userid, '.']);
          if (nulls && nulls.length) {
            console.log('updating a null');
            return database.exec('UPDATE s SET f=?, d=? WHERE d=?', [feedId, new Date().valueOf(), nulls[0].d]);
          } else {
            return database.exec('INSERT INTO s VALUES ?', [
              {
                u: userid,
                f: feedId,
                d: new Date().valueOf()
              }
            ]);
          }
        }
      },
      pollFeeds: function(pollCallback) {
        var count, dateNow, feeds;
        if (database.maintenance()) {
          return pollCallback();
        }
        count = 0;
        dateNow = new Date().valueOf();
        feeds = database.exec('SELECT i, u, iu, up FROM f WHERE up<? ORDER BY up ASC', [dateNow]);
        if (feeds && feeds.length) {
          async.eachSeries(feeds, function(feed, feedCallback) {
            var callbackCount;
            if (database.maintenance()) {
              return feedCallback();
            } else {
              global.gc();
              callbackCount = 0;
              database.exec('UPDATE f SET up=? WHERE i=?', [new Date().setMinutes(new Date().getMinutes() + 2000).valueOf(), feed.i]);
              console.log('-------------------', ++count, '/', feeds.length, '------', feed.u, feed.up);
              return parser({
                url: feed.u,
                headers: {
                  'User-Agent': 'Podcaddy'
                }
              }, function(err, data) {
                var inserted, inserts, pubDates, skipped, updated;
                if (!err && data && data.length) {
                  inserts = [];
                  inserted = 0;
                  updated = 0;
                  skipped = 0;
                  if (feed.iu) {
                    database.exec('UPDATE f SET up=?, t=?, s=?, d=?, l=?, im=?, iu=?, c=?, p=? WHERE u=?', [new Date().valueOf() + (2 * 60 * 60 * 1000), S(data[0].meta.title || '').stripTags().decodeHTMLEntities().truncate(255).s, S(data[0].meta.title || '').stripTags().decodeHTMLEntities().truncate(30).slugify().s, S(data[0].meta.description || '').stripTags().decodeHTMLEntities().truncate(255).s, data[0].meta.link, feed.im, feed.iu, data[0].meta.categories, new Date(data[0].meta.pubDate).valueOf(), feed.u]);
                  } else {
                    console.log('upload to cloudinary', feed);
                  }
                  pubDates = database.exec('SELECT DISTINCT(pubDate) AS pubDate FROM ?', [data]);
                  return async.eachSeries(pubDates, function(pubDate, callback) {
                    return setTimeout(function() {
                      var item, itemExists, pod;
                      item = database.exec('SELECT * FROM ? WHERE pubDate=?', [data, pubDate.pubDate]);
                      if (item && item.length && item[0].enclosures && item[0].enclosures.length && item[0].enclosures[0].type && item[0].enclosures[0].type.indexOf('audio') !== -1) {
                        pod = {
                          i: ObjectID.generate(),
                          f: feed.i,
                          t: S(item[0].title || '').replace(/<!\[CDATA|]]>/g, '').stripTags().decodeHTMLEntities().truncate(255).s,
                          s: S(item[0].title || '').replace(/<!\[CDATA|]]>/g, '').stripTags().decodeHTMLEntities().truncate(30).slugify().s,
                          d: S(item[0].description || '').replace(/<!\[CDATA|]]>/g, '').stripTags().decodeHTMLEntities().truncate(255).s,
                          u: item[0].enclosures ? item[0].enclosures[0].url : '',
                          l: item[0].enclosures ? item[0].enclosures[0].length : 0,
                          p: new Date(item[0].pubDate).valueOf()
                        };
                        itemExists = database.exec('SELECT i, u FROM i WHERE f=? AND (p=? OR u=?)', [pod.f, pod.p, pod.u]);
                        if (itemExists && itemExists.length) {
                          if (itemExists[0].u !== pod.u) {
                            console.log(itemExists[0].u);
                            console.log(pod.u);
                            database.exec('UPDATE i SET t=?, s=?, d=?, u=?, l=? WHERE p=?', [pod.t, pod.s, pod.d, pod.u, pod.l, pod.p]);
                            updated++;
                          } else {
                            skipped++;
                          }
                        } else {
                          inserts.push(pod);
                          inserted++;
                        }
                        itemExists = null;
                        item = null;
                      }
                      return callback();
                    }, 1);
                  }, function() {
                    var usersToNotify;
                    console.log('-----', inserted, 'inserted -----', updated, 'updated -----', skipped, 'skipped -----');
                    if (inserted) {
                      database.exec('INSERT INTO i SELECT * FROM ?', [inserts]);
                      usersToNotify = database.exec('SELECT DISTINCT(u._id) AS _id FROM u INNER JOIN s ON s.u=u._id WHERE s.f=?', [feed.i]);
                      if (usersToNotify && usersToNotify.length) {
                        console.log('there are peepz to notify', usersToNotify);
                        socket.emitToUsers(usersToNotify, 'feeds', 'updated');
                      }
                      usersToNotify = null;
                    }
                    data = null;
                    callbackCount++;
                    if (feed && callbackCount < 2) {
                      console.log('this one');
                      return feedCallback();
                    }
                  });
                } else {
                  console.log('error', err);
                  callbackCount++;
                  if (feed) {
                    database.exec('UPDATE f SET up=? WHERE i=?', [new Date().setHours(new Date().getHours() + 255).valueOf(), feed.i]);
                  }
                  data = null;
                  if (callbackCount < 2) {
                    console.log('theeeeez one');
                    return feedCallback();
                  }
                }
              });
            }
          }, function() {
            return pollCallback();
          });
        } else {
          if (!database.maintenance()) {
            count = 0;
          } else {
            console.log('Maintenance Mode');
          }
          global.gc();
          return pollCallback();
        }
      }
    };
  };

}).call(this);

//# sourceMappingURL=polling2.js.map
