alasql = require 'alasql'
fs = require 'fs'
filename = './podcaddy.json'

module.exports = ->
  console.log 'meee'
  res = fs.existsSync filename
  if not res
    alasql 'CREATE DATABASE podcaddy'
    fs.writeFileSync filename, JSON.stringify alasql.databases.podcaddy
    alasql 'ATTACH FILESTORAGE DATABASE podcaddy("' + filename + '")'
    alasql 'USE podcaddy'
    alasql 'CREATE TABLE u'
    alasql 'CREATE TABLE f'
    alasql 'CREATE TABLE s'
    alasql 'CREATE TABLE i (i string, f string, t string, s string, d string, u string, l string, p number)'
    alasql 'CREATE TABLE l'
    users = JSON.parse fs.readFileSync './data/users.json'
    for user in users
      alasql 'INSERT INTO u VALUES ?', [user]
    feedsJson = JSON.parse fs.readFileSync './data/pods_processed.json'
    feeds = alasql 'SELECT _id as i, title as t, slug as s, description as d, url as u, link as l, image as im, imageUrl as iu, categories as c, pubDate as p, updated as up FROM ?', [feedsJson]
    for feed in feeds
      alasql 'INSERT INTO f VALUES ?', [feed]
    subsJson = JSON.parse fs.readFileSync './data/subs_processed.json'
    subs = alasql 'SELECT pid as f, uid as u, d FROM ?', [subsJson]
    for sub in subs
      alasql 'INSERT INTO s VALUES ?', [sub]
    #res = alasql 'SELECT pods.* FROM users JOIN subs ON subs.uid=users._id JOIN pods ON subs.pid=pods._id WHERE users.facebook->email LIKE "rainstorm%"'
  else
    alasql 'ATTACH FILESTORAGE DATABASE podcaddy("' + filename + '")'
    alasql 'USE podcaddy'
  db = alasql.databases.podcaddy
  return alasql.databases.podcaddy