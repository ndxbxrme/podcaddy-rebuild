(function() {
  'use strict';
  angular.module('pod').factory('database', function() {
    var database;
    alasql('CREATE localStorage DATABASE IF NOT EXISTS podcaddy');
    alasql('ATTACH localStorage DATABASE podcaddy');
    database = alasql.databases.podcaddy;
    database.exec('CREATE TABLE IF NOT EXISTS filter');
    database.exec('CREATE TABLE IF NOT EXISTS direction');
    database.exec('CREATE TABLE IF NOT EXISTS current');
    return {
      setFilter: function(filter) {
        database.exec('DELETE FROM filter');
        return database.exec('INSERT INTO filter VALUES ?', [filter]);
      },
      getFilter: function() {
        var res;
        res = database.exec('SELECT * FROM filter');
        if (res && res.length) {
          return res[0];
        }
        return null;
      },
      setDirection: function(direction) {
        database.exec('DELETE FROM direction');
        return database.exec('INSERT INTO direction VALUES ?', [direction]);
      },
      getDirection: function() {
        var res;
        res = database.exec('SELECT * FROM direction');
        if (res && res.length) {
          return res[0];
        }
        return null;
      },
      setCurrent: function(current) {
        database.exec('DELETE FROM current');
        return database.exec('INSERT INTO current VALUES ?', [current]);
      },
      getCurrent: function() {
        var res;
        res = database.exec('SELECT * FROM current');
        if (res && res.length) {
          return res[0];
        }
        return null;
      }
    };
  });

}).call(this);

//# sourceMappingURL=database.js.map
