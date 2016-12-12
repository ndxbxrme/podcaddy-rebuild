request = require 'request'

request 
  url:'http://grizzlybearcafe.com/podcast/rss.xml'
  headers: 
    'User-Agent': 'Podcaddy'
, (err, res, body) ->
  console.log body