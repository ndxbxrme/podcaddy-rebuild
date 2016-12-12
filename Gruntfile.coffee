module.exports = (grunt) ->
  require('load-grunt-tasks') grunt
  serveStatic = require 'serve-static'
  grunt.initConfig
    watch:
      coffee:
        files: ['src/**/*.coffee']
        tasks: ['coffee']
      jade:
        files: ["src/**/*.jade"]
        tasks: ['jade', 'wiredep', 'injector']
      stylus:
        files: ["src/**/*.stylus"]
        tasks: ['stylus']
    coffee:
      options:
        sourceMap: true
      default:
        files: [{
          expand: true
          cwd: 'src'
          src: ['**/*.coffee']
          dest: 'build'
          ext: '.js'
        }]
    jade:
      default:
        files: [{
          expand: true
          cwd: 'src'
          src: ['**/*.jade']
          dest: 'build'
          ext: '.html'
        }]
    injector:
      default:
        files:
          "build/client/index.html": ['build/client/**/*.js', 'build/client/**/*.css']
    stylus:
      default:
        files:
          "build/client/app.css": "src/client/**/*.stylus"
    wiredep:
      options:
        directory: 'build/bower'
      target:
        src: 'build/client/index.html'
  grunt.registerTask 'default', [
    'coffee'
    'jade'
    'stylus'
    'wiredep'
    'injector'
    'watch'
  ]