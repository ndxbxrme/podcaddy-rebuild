(function() {
  'use strict';
  var LocalStrategy, ObjectID, TwitterStrategy, bcrypt;

  LocalStrategy = require('passport-local').Strategy;

  TwitterStrategy = require('passport-twitter').Strategy;

  ObjectID = require('bson-objectid');

  bcrypt = require('bcrypt-nodejs');

  module.exports = function(passport, database) {
    var generateHash, validPassword;
    generateHash = function(password) {
      return bcrypt.hashSync(password, bcrypt.genSaltSync(8), null);
    };
    validPassword = function(password, localPassword) {
      return bcrypt.compareSync(password, localPassword);
    };
    passport.serializeUser(function(user, done) {
      return done(null, user._id);
    });
    passport.deserializeUser(function(id, done) {
      return done(null, id);
    });
    passport.use('local-signup', new LocalStrategy({
      usernameField: 'email',
      passwordField: 'password',
      passReqToCallback: true
    }, function(req, email, password, done) {
      var newUser, users;
      users = database.exec('SELECT * FROM u WHERE local->email=?', [email]);
      if (users && users.length) {
        return done(null, false, req.flash('signupMessage', 'That email is already taken.'));
      } else {
        newUser = {
          _id: ObjectID.generate(),
          local: {
            email: email,
            password: generateHash(password)
          }
        };
        database.exec('INSERT INTO u VALUES ?', [newUser]);
        return done(null, newUser);
      }
    }));
    passport.use('local-login', new LocalStrategy({
      usernameField: 'email',
      passwordField: 'password',
      passReqToCallback: true
    }, function(req, email, password, done) {
      var users;
      users = database.exec('SELECT * FROM u WHERE local->email=?', [email]);
      if (users && users.length) {
        if (!validPassword(password, users[0].local.password)) {
          return done(null, false, req.flash('loginMessage', 'Wrong password'));
        }
        return done(null, users[0]);
      } else {
        return done(null, false, req.flash('loginMessage', 'No user found'));
      }
    }));
    console.log(process.env.TWITTER_KEY);
    return passport.use(new TwitterStrategy({
      consumerKey: process.env.TWITTER_KEY,
      consumerSecret: process.env.TWITTER_SECRET,
      callbackURL: process.env.TWITTER_CALLBACK,
      passReqToCallback: true
    }, function(req, token, tokenSecret, profile, done) {
      return process.nextTick(function() {
        var newUser, users;
        if (!req.user) {
          users = database.exec('SELECT * FROM u WHERE twitter->id=?', [profile.id]);
          if (users && users.length) {
            if (!users[0].twitter.token) {
              database.exec('UPDATE u SET twitter=? WHERE _id=?', [
                {
                  id: profile.id,
                  token: token,
                  username: profile.username,
                  displayName: profile.displayName
                }, users[0]._id
              ]);
              return done(null, users[0]);
            }
            return done(null, users[0]);
          } else {
            newUser = {
              _id: ObjectID.generate(),
              twitter: {
                id: profile.id,
                token: token,
                username: profile.username,
                displayName: profile.displayName
              }
            };
            database.exec('INSERT INTO u VALUES ?', [newUser]);
            return done(null, newUser);
          }
        } else {
          database.exec('UPDATE u SET twitter=? WHERE _id=?', [
            {
              id: profile.id,
              token: token,
              username: profile.username,
              displayName: profile.displayName
            }, req.user._id
          ]);
          return done(null, req.user);
        }
      });
    }));
  };

}).call(this);

//# sourceMappingURL=passport.js.map
