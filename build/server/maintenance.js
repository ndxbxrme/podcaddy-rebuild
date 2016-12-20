(function() {
  'use strict';
  module.exports = function(options) {
    var database;
    database = options.database;
    return function(req, res, next) {
      if (database.maintenance()) {
        if (req.originalUrl === '/maintenance-off' || req.originalUrl === '/api/upload/database' || req.originalUrl === '/api/getdb') {
          return next();
        } else if (req.originalUrl === '/dbupload') {
          res.writeHead(200, {
            'Content-type': 'text/html'
          });
          return res.end('<form action="api/upload/database" method="POST" enctype="multipart/form-data"><input type="file" name="podcaddyDatabase" /><input type="text" name="key" /><input type="submit" value="submit" /></form>');
        } else {
          return res.end('Database maintenance time, please come back later');
        }
      } else {
        return next();
      }
    };
  };

}).call(this);

//# sourceMappingURL=maintenance.js.map
