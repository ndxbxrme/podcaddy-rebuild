'use strict'
angular.module 'pod'
.factory 'database', ->
  alasql 'CREATE localStorage DATABASE IF NOT EXISTS podcaddy'
  alasql 'ATTACH localStorage DATABASE podcaddy'
  database = alasql.databases.podcaddy
  database.exec 'CREATE TABLE IF NOT EXISTS filter'
  database.exec 'CREATE TABLE IF NOT EXISTS direction'
  database.exec 'CREATE TABLE IF NOT EXISTS current'
  
  setFilter: (filter) ->
    database.exec 'DELETE FROM filter'
    database.exec 'INSERT INTO filter VALUES ?', [filter]
  getFilter: ->
    res = database.exec 'SELECT * FROM filter'
    if res and res.length
      return res[0]
    return null
  setDirection: (direction) ->
    database.exec 'DELETE FROM direction'
    database.exec 'INSERT INTO direction VALUES ?', [direction]
  getDirection: ->
    res = database.exec 'SELECT * FROM direction'
    if res and res.length
      return res[0]
    return null
  setCurrent: (current) ->
    database.exec 'DELETE FROM current'
    database.exec 'INSERT INTO current VALUES ?', [current]
  getCurrent: ->
    res = database.exec 'SELECT * FROM current'
    if res and res.length
      return res[0]
    return null