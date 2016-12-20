(function() {
  var alasql, filename, fs;

  alasql = require('alasql');

  fs = require('fs');

  filename = './podcaddy.json';

  module.exports = function() {
    var database, maintenanceMode;
    database = null;
    maintenanceMode = false;
    return {
      attachDatabase: function() {
        var res;
        console.log('meee');
        res = fs.existsSync(filename);
        if (!res) {
          return maintenanceMode = true;

          /*
          alasql 'CREATE DATABASE podcaddy'
          fs.writeFileSync filename, JSON.stringify alasql.databases.podcaddy
          alasql 'ATTACH FILESTORAGE DATABASE podcaddy("' + filename + '")'
          alasql 'USE podcaddy'
          alasql 'CREATE TABLE u'
          alasql 'CREATE TABLE f'
          alasql 'CREATE TABLE s'
          alasql 'CREATE TABLE i'
          alasql 'CREATE TABLE l'
          users = JSON.parse fs.readFileSync './data/users.json'
          for user in users
            alasql 'INSERT INTO u VALUES ?', [user]
          feedsJson = JSON.parse fs.readFileSync './data/pods_processed.json'
          distinctUrls = alasql 'SELECT DISTINCT(title + description) AS url FROM ?', [feedsJson]
          for url in distinctUrls
            #console.log 'gettin', url
            feed = alasql 'SELECT _id as i, title as t, slug as s, description as d, url as u, link as l, image as im, imageUrl as iu, categories as c, pubDate as p, updated as up FROM ? WHERE (title+description)=?', [feedsJson, url.url]
            if feed and feed.length
              feedExists = alasql 'SELECT * FROM f WHERE t=? AND d=?', [feed.t, feed.d]
              if feedExists and feedExists.length
                console.log 'DUPLICATE:', feed.t
              else
                #console.log 'got feed', feed[0].title
                alasql 'INSERT INTO f VALUES ?', [feed[0]]
                if feed.length > 1
                  console.log feed[0].t
          subsJson = JSON.parse fs.readFileSync './data/subs_processed.json'
          subs = alasql 'SELECT pid as f, uid as u, d FROM ?', [subsJson]
          for sub in subs
            alasql 'INSERT INTO s VALUES ?', [sub]
          database = alasql.databases.podcaddy
           */
        } else {
          console.log('attaching database');
          alasql('ATTACH FILESTORAGE DATABASE podcaddy("' + filename + '")');
          alasql('USE podcaddy');
          database = alasql.databases.podcaddy;
          return maintenanceMode = false;
        }
      },
      exec: function(sql, props) {
        if (maintenanceMode) {
          return [];
        }
        return database.exec(sql, props);
      },
      maintenanceOn: function() {
        return maintenanceMode = true;
      },
      maintenanceOff: function() {
        return maintenanceMode = false;
      },
      maintenance: function() {
        return maintenanceMode;
      }
    };
  };

}).call(this);

//# sourceMappingURL=database.js.map
