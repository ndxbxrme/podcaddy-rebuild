(function() {
  'use strict';
  angular.module('pod').factory('player', function($timeout, $http, $window, database) {
    var current, data, direction, events, filter, getDurationEstimate, getTime, lastPod, lastSound, pods, scrollABit, skip, sortPods, togglePlay, volume;
    soundManager.setup({
      flashVersion: 9,
      preferFlash: false,
      debugMode: false,
      url: 'bower/SoundManager2/swf/'
    });
    pods = [];
    lastPod = {};
    lastSound = null;
    volume = 66;
    data = {
      feedSlug: ''
    };
    soundManager.setVolume(volume);
    events = {
      play: function() {
        return $timeout(function() {
          lastPod.paused = false;
          return lastPod.playing = true;
        });
      },
      stop: function() {
        return $timeout(function() {
          lastPod.paused = false;
          return lastPod.playing = false;
        });
      },
      pause: function() {
        return $timeout(function() {
          return lastPod.paused = true;
        });
      },
      resume: function() {
        return $timeout(function() {
          lastPod.paused = false;
          return lastPod.playing = true;
        });
      },
      finish: function() {
        return $timeout(function() {
          lastPod.paused = false;
          lastPod.playing = false;
          lastPod.position = '';
          return skip(lastPod);
        });
      },
      whileplaying: function() {
        return $timeout(function() {
          lastPod.playPercent = lastSound.position / getDurationEstimate(lastSound) * 100;
          lastPod.position = getTime(lastSound.position) + ' / ' + getTime(getDurationEstimate(lastSound));
          if (lastPod.playPercent > 10 && !lastPod.reportedListen) {
            lastPod.reportedListen = true;
            return $http.post('/api/report-listen', {
              podId: lastPod._id
            });
          }
        });
      },
      whileloading: function() {
        return $timeout(function() {
          return lastPod.loadPercent = lastSound.bytesLoaded / lastSound.bytesTotal * 100;
        });
      },
      error: function(err) {
        return console.log(err);
      }
    };
    getTime = function(nMSec) {
      var min, nSec, sec;
      nSec = Math.floor(nMSec / 1000);
      min = Math.floor(nSec / 60);
      sec = nSec - (min * 60);
      return min + ':' + (sec < 10 ? '0' + sec : sec);
    };
    getDurationEstimate = function(oSound) {
      if (oSound.instanceOptions.isMovieStar) {
        return oSound.duration;
      } else {
        return oSound.durationEstimate || 0;
      }
    };
    skip = function(pod) {
      var foundPod, j, len, mpod;
      foundPod = false;
      if (!pod) {
        foundPod = true;
        pod = {
          url: ''
        };
      }
      for (j = 0, len = pods.length; j < len; j++) {
        mpod = pods[j];
        if (mpod.url === pod.url) {
          foundPod = true;
        } else {
          if (foundPod && mpod.displayed) {
            return togglePlay(mpod);
          }
        }
      }
    };
    togglePlay = function(pod) {
      if (lastSound && lastSound.id === pod.url) {
        if (lastSound.readyState !== 2) {
          if (lastSound.playState !== 1) {
            return lastSound.play();
          } else {
            return lastSound.togglePause();
          }
        }
      } else {
        if (lastSound) {
          soundManager.stop(lastSound.id);
          soundManager.unload(lastSound.id);
        }
        if (lastPod) {
          lastPod.playing = false;
          lastPod.position = '';
        }
        lastSound = soundManager.createSound({
          id: pod.url,
          url: decodeURI(pod.url),
          onplay: events.play,
          onstop: events.stop,
          onpause: events.pause,
          onresume: events.resume,
          onfinish: events.finish,
          whileplaying: events.whileplaying,
          whileloading: events.whileloading,
          onerror: events.error
        });
        lastPod = pod;
        lastSound.play();
        database.setCurrent(lastPod);
        return soundManager.setVolume(volume);
      }
    };
    sortPods = function() {
      if (direction && direction.value === 'ASC') {
        return pods.sort(function(a, b) {
          return a.pubDate - b.pubDate;
        });
      } else {
        return pods.sort(function(a, b) {
          return b.pubDate - a.pubDate;
        });
      }
    };
    scrollABit = function() {
      return $timeout(function() {
        return $window.scrollTo($window.scrollX, $window.scrollY + 1);
      });
    };
    direction = database.getDirection();
    filter = database.getFilter();
    current = database.getCurrent();
    return {
      getPods: function() {
        return pods;
      },
      getPod: function() {
        return lastPod;
      },
      podClick: function(pod) {
        console.log('podClick');
        if (!pod) {
          return skip(null);
        } else {
          return togglePlay(pod);
        }
      },
      setVolume: function(vol) {
        volume = vol;
        return soundManager.setVolume(volume);
      },
      getVolume: function() {
        return volume;
      },
      fetchPods: function() {
        console.log('fetching pods', data, 'baaa');
        return $http.post('/api/pods', data).then(function(response) {
          return $timeout(function() {
            var i, j, k, l, len, len1, len2, pod, ref, ref1, rpod;
            for (j = 0, len = pods.length; j < len; j++) {
              pod = pods[j];
              pod.tokeep = false;
              ref = response.data;
              for (k = 0, len1 = ref.length; k < len1; k++) {
                rpod = ref[k];
                if (pod.url === rpod.url) {
                  pod.tokeep = true;
                  rpod.exists = true;
                  break;
                }
              }
            }
            i = pods.length;
            while (i-- > 0) {
              if (!pods[i].tokeep && pods[i].url !== lastPod.url) {
                pods.splice(i, 1);
              }
            }
            ref1 = response.data;
            for (l = 0, len2 = ref1.length; l < len2; l++) {
              rpod = ref1[l];
              if (!rpod.exists) {
                pods.push(rpod);
              }
            }
            sortPods();
            return scrollABit();
          });
        }, function() {
          return console.log('error');
        });
      },
      setPosition: function(pos) {
        var nMsecOffset;
        nMsecOffset = Math.floor(pos * getDurationEstimate(lastSound));
        if (!isNaN(nMsecOffset)) {
          nMsecOffset = Math.min(nMsecOffset, lastSound.duration);
        }
        if (!isNaN(nMsecOffset)) {
          lastSound.setPosition(nMsecOffset);
        }
        return lastSound.resume();
      },
      setFeedSlug: function(slug) {
        return data.feedSlug = slug;
      },
      setDirection: function(dir) {
        database.setDirection({
          value: dir
        });
        direction = database.getDirection();
        sortPods();
        return scrollABit();
      },
      getDirection: function() {
        if (direction && direction.value) {
          return direction.value;
        }
        return 'DESC';
      },
      setFilter: function(newFilter) {
        database.setFilter({
          value: newFilter
        });
        filter = database.getFilter();
        return scrollABit();
      },
      getFilter: function() {
        if (filter && filter.value) {
          return filter.value;
        }
        return 'unlistened';
      },
      scrollABit: function() {
        return scrollABit();
      }
    };
  });

}).call(this);

//# sourceMappingURL=player.js.map
