'use strict'

angular.module 'pod'
.factory 'player', ($timeout, $http, $window) ->
  soundManager.setup
    flashVersion: 9
    preferFlash: false
    debugMode: false
    url: 'bower/SoundManager2/swf/'
    
  pods = []
  lastPod = null
  lastSound = null
  
  events =
    play: ->
      $timeout ->
        lastPod.paused = false
        lastPod.playing = true
    stop: ->
      $timeout ->
        lastPod.paused = false
        lastPod.playing = false
    pause: ->
      $timeout ->
       lastPod.paused = true 
    resume: ->
      $timeout ->
        lastPod.paused = false
        lastPod.playing = true
    finish: ->
      $timeout ->
        lastPod.paused = false
        lastPod.playing = false
        lastPod.position = ''
        skip lastPod
    whileplaying: ->
      $timeout ->
        lastPod.playPercent = lastSound.position / getDurationEstimate(lastSound) * 100
        lastPod.position = getTime(lastSound.position) + ' / ' + getTime(getDurationEstimate(lastSound))
    whileloading: ->
      $timeout ->
        lastPod.loadPercent = lastSound.bytesLoaded / lastSound.bytesTotal * 100
    error: (err) ->
      console.log err
    
  getTime = (nMSec) ->
    nSec = Math.floor nMSec/1000
    min = Math.floor nSec/60
    sec = nSec - (min * 60)
    min + ':' + (if sec < 10 then '0' + sec else sec)
    
  getDurationEstimate = (oSound) ->
    if oSound.instanceOptions.isMovieStar
      return oSound.duration
    else
      return oSound.durationEstimate or 0
    
  skip = (pod) ->
    foundPod = false
    for mpod in pods
      if mpod.url is pod.url
        foundPod = true
      else
        if foundPod and mpod.displayed
          return togglePlay mpod
    
  togglePlay = (pod) ->
    if lastSound and lastSound.id is pod.url
      if lastSound.readyState isnt 2
        if lastSound.playState isnt 1
          lastSound.play()
        else
          lastSound.togglePause()
    else
      if lastSound
        soundManager.stop lastSound.id
        soundManager.unload lastSound.id
      if lastPod
        lastPod.playing = false
        lastPod.position = ''
      lastSound = soundManager.createSound
        id: pod.url
        url: decodeURI pod.url
        onplay: events.play
        onstop: events.stop
        onpause: events.pause
        onresume: events.resume
        onfinish: events.finish
        whileplaying: events.whileplaying
        whileloading: events.whileloading
        onerror: events.error
      lastPod = pod
      lastSound.play()
  getPods: ->
    pods
  podClick: (pod) ->
    console.log 'podClick'
    togglePlay pod
  fetchPods: ->  
    scrollY = $window.scrollY
    console.log 'fetching pods'
    $http.post '/api/today'
    .then (response) ->
      $timeout ->
        for pod in pods
          pod.tokeep = false
          for rpod in response.data
            if pod.url is rpod.url
              pod.tokeep = true
              rpod.exists = true
              break
        i = pods.length
        while i-- > 0
          if not pods[i].tokeep and pods[i].url isnt lastPod.url
            pods.splice i, 1
        for rpod in response.data
          if not rpod.exists
            pods.push rpod
        pods.sort (a, b) ->
          b.pubDate - a.pubDate
    , ->
      console.log 'error'
  setPosition: (pos) ->
    nMsecOffset = Math.floor(pos * getDurationEstimate(lastSound))
    if not isNaN nMsecOffset
      nMsecOffset = Math.min nMsecOffset, lastSound.duration
    if not isNaN nMsecOffset
      lastSound.setPosition nMsecOffset
    lastSound.resume()