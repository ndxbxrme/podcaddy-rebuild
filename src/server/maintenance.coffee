'use strict'

module.exports = (options) ->
  database = options.database
  (req, res, next) ->
    if database.maintenance()
      if req.originalUrl is '/maintenance-off' or req.originalUrl is '/api/upload/database' or req.originalUrl is '/api/getdb'
        next()
      else if req.originalUrl is '/dbupload'
        res.writeHead 200,
          'Content-type': 'text/html'
        res.end '<form action="api/upload/database" method="POST" enctype="multipart/form-data"><input type="file" name="podcaddyDatabase" /><input type="text" name="key" /><input type="submit" value="submit" /></form>'
      else
        res.end 'Database maintenance time, please come back later'
    else
      next()