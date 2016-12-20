(function() {
  var request;

  request = require('request');

  request({
    url: 'http://grizzlybearcafe.com/podcast/rss.xml',
    headers: {
      'User-Agent': 'Podcaddy'
    }
  }, function(err, res, body) {
    return console.log(body);
  });

}).call(this);

//# sourceMappingURL=test.js.map
