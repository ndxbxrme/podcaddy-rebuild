###*
# Simple userland heapdump generator using v8-profiler
# Usage: require('[path_to]/HeapDump').init('datadir')
#
# @module HeapDump
# @type {exports}
###

fs = require('fs')
profiler = require('v8-profiler')
_datadir = null
nextMBThreshold = 900

###*
# Init and scheule heap dump runs
#
# @param datadir Folder to save the data to
###

###*
# Schedule a heapdump by the end of next tick
###

tickHeapDump = ->
  setImmediate ->
    heapDump()
    return
  return

###*
# Creates a heap dump if the currently memory threshold is exceeded
###

heapDump = ->
  memMB = process.memoryUsage().rss / 1048576
  console.log memMB + '>' + nextMBThreshold
  if memMB > nextMBThreshold
    console.log 'Current memory usage: %j', process.memoryUsage()
    nextMBThreshold += 50
    snap = profiler.takeSnapshot('profile')
    saveHeapSnapshot snap, _datadir
  return

###*
# Saves a given snapshot
#
# @param snapshot Snapshot object
# @param datadir Location to save to
###

saveHeapSnapshot = (snapshot, datadir) ->
  buffer = ''
  stamp = Date.now()
  snapshot.serialize ((data, length) ->
    buffer += data
    return
  ), ->
    name = stamp + '.heapsnapshot'
    fs.writeFile datadir + '/' + name, buffer, ->
      console.log 'Heap snapshot written to ' + name
      return
    return
  return

module.exports.init = (datadir) ->
  _datadir = datadir
  setInterval tickHeapDump, 5000
  return

# ---
# generated by js2coffee 2.2.0