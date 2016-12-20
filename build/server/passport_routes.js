(function() {
  'use strict';
  var crypto, postAuthenticate;

  crypto = require('crypto-js');

  postAuthenticate = function(req, res, next) {
    var cookieText;
    console.log('post authenticate', req.user);
    if (req.user) {
      cookieText = req.user._id + '||' + new Date().toString();
      cookieText = crypto.Rabbit.encrypt(cookieText, process.env.SESSION_SECRET).toString();
      res.cookie('podcaddy', cookieText, {
        maxAge: 7 * 24 * 60 * 60 * 1000
      });
    }
    return res.redirect('/');
  };

  module.exports = function(app, passport) {
    app.post('/api/signup', passport.authenticate('local-signup'), postAuthenticate);
    app.post('/api/login', passport.authenticate('local-login'), postAuthenticate);
    app.get('/api/twitter', passport.authenticate('twitter', {
      scope: 'email'
    }), postAuthenticate);
    app.get('/api/twitter/callback', passport.authenticate('twitter'), postAuthenticate);
    app.get('/api/facebook', passport.authenticate('facebook', {
      scope: 'email'
    }));
    app.get('/api/facebook/callback', passport.authenticate('facebook'), postAuthenticate);
    app.get('/api/github', passport.authenticate('github', {
      scope: ['user', 'user:email']
    }));
    app.get('/api/github/callback', passport.authenticate('github'), postAuthenticate);
    app.get('/api/connect/local', function(req, res) {});
    app.post('/api/connect/local', passport.authorize('local-signup'));
    app.get('/api/connect/twitter', passport.authorize('twitter', {
      scope: 'email'
    }));
    app.get('/api/connect/facebook', passport.authorize('facebook', {
      scope: 'email'
    }));
    app.get('/api/connect/github', passport.authorize('github', {
      scope: ['user', 'user:email'],
      successRedirect: '/profile'
    }));
    app.get('/api/unlink/local', function(req, res) {
      var user;
      user = req.user;
      user.local.email = void 0;
      user.local.password = void 0;
      user.save(function(err) {
        res.redirect('/profile');
      });
    });
    app.get('/api/unlink/twitter', function(req, res) {
      var user;
      user = req.user;
      user.twitter.token = void 0;
      user.save(function(err) {
        res.redirect('/profile');
      });
    });
    app.get('/api/unlink/facebook', function(req, res) {
      var user;
      user = req.user;
      user.facebook.token = void 0;
      user.save(function(err) {
        res.redirect('/profile');
      });
    });
    app.get('/api/unlink/github', function(req, res) {
      var user;
      user = req.user;
      user.github.token = void 0;
      user.save(function(err) {
        res.redirect('/profile');
      });
    });
    return app.get('/api/logout', function(req, res) {
      res.clearCookie('podcaddy');
      res.redirect('/');
    });
  };

}).call(this);

//# sourceMappingURL=passport_routes.js.map
