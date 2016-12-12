alasql = require 'alasql'
fs = require 'fs'
filename = './podcaddy1.json'

module.exports = ->
  console.log 'meee'
  res = fs.existsSync filename
  if not res
    alasql 'CREATE DATABASE podcaddy'
    fs.writeFileSync filename, JSON.stringify alasql.databases.podcaddy
    alasql 'ATTACH FILESTORAGE DATABASE podcaddy("' + filename + '")'
    alasql 'USE podcaddy'
    alasql 'CREATE TABLE users'
    alasql 'CREATE TABLE feeds'
    alasql 'CREATE TABLE subs'
    alasql 'CREATE TABLE items'
    alasql 'CREATE TABLE listens'
    users = JSON.parse fs.readFileSync './data/users.json'
    for user in users
      alasql 'INSERT INTO users VALUES ?', [user]
    feeds = JSON.parse fs.readFileSync './data/pods_processed.json'
    for feed in feeds
      alasql 'INSERT INTO feeds VALUES ?', [feed]
    subs = JSON.parse fs.readFileSync './data/subs_processed.json'
    for sub in subs
      alasql 'INSERT INTO subs VALUES ?', [sub]
    #res = alasql 'SELECT pods.* FROM users JOIN subs ON subs.uid=users._id JOIN pods ON subs.pid=pods._id WHERE users.facebook->email LIKE "rainstorm%"'
  else
    alasql 'ATTACH FILESTORAGE DATABASE podcaddy("' + filename + '")'
    alasql 'USE podcaddy'
  db = alasql.databases.podcaddy
  return alasql.databases.podcaddy