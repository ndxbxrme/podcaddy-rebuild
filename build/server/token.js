(function() {
  'use strict';
  var crypto;

  crypto = require('crypto-js');

  module.exports = function(options) {
    var database;
    database = options.database;
    return function(req, res, next) {
      var bits, d, decrypted, users;
      req.user = null;
      if (req.cookies.podcaddy && !database.maintenance()) {
        decrypted = '';
        try {
          decrypted = crypto.Rabbit.decrypt(req.cookies.podcaddy, process.env.SESSION_SECRET).toString(crypto.enc.Utf8);
        } catch (undefined) {}
        if (decrypted.indexOf('||') !== -1) {
          bits = decrypted.split('||');
          if (bits.length === 2) {
            d = new Date(bits[1]);
            if (d.toString() !== 'Invalid Date') {
              users = database.exec('SELECT * FROM u WHERE _id=?', [bits[0]]);
              if (users && users.length) {
                req.user = users[0];
              }
            }
          }
        }
      }

      /*
      console.log 'SESSION SECRET', process.env.SESSION_SECRET
      cookieText = '5464af915632880200ed93cf||' + new Date().toString()
      console.log cookieText
      cookieText = crypto.Rabbit.encrypt(cookieText, 'podcaddy').toString()
      res.cookie 'podcaddy', cookieText, maxAge: 24 * 60 * 60 * 1000
       */
      return next();
    };
  };

}).call(this);

//# sourceMappingURL=token.js.map
