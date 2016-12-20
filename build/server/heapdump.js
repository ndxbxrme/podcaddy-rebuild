
/**
 * Simple userland heapdump generator using v8-profiler
 * Usage: require('[path_to]/HeapDump').init('datadir')
 *
 * @module HeapDump
 * @type {exports}
 */

(function() {
  var _datadir, fs, heapDump, nextMBThreshold, profiler, saveHeapSnapshot, tickHeapDump;

  fs = require('fs');

  profiler = require('v8-profiler');

  _datadir = null;

  nextMBThreshold = 900;


  /**
   * Init and scheule heap dump runs
   *
   * @param datadir Folder to save the data to
   */


  /**
   * Schedule a heapdump by the end of next tick
   */

  tickHeapDump = function() {
    setImmediate(function() {
      heapDump();
    });
  };


  /**
   * Creates a heap dump if the currently memory threshold is exceeded
   */

  heapDump = function() {
    var memMB, snap;
    memMB = process.memoryUsage().rss / 1048576;
    console.log(memMB + '>' + nextMBThreshold);
    if (memMB > nextMBThreshold) {
      console.log('Current memory usage: %j', process.memoryUsage());
      nextMBThreshold += 50;
      snap = profiler.takeSnapshot('profile');
      saveHeapSnapshot(snap, _datadir);
    }
  };


  /**
   * Saves a given snapshot
   *
   * @param snapshot Snapshot object
   * @param datadir Location to save to
   */

  saveHeapSnapshot = function(snapshot, datadir) {
    var buffer, stamp;
    buffer = '';
    stamp = Date.now();
    snapshot.serialize((function(data, length) {
      buffer += data;
    }), function() {
      var name;
      name = stamp + '.heapsnapshot';
      fs.writeFile(datadir + '/' + name, buffer, function() {
        console.log('Heap snapshot written to ' + name);
      });
    });
  };

  module.exports.init = function(datadir) {
    _datadir = datadir;
    setInterval(tickHeapDump, 5000);
  };

}).call(this);

//# sourceMappingURL=heapdump.js.map
