module.exports = (grunt) ->

  # Tasks
  grunt.initConfig {

    # ----------------------
    # Clean
    # ----------------------
    # clean:
    #   src: ['!public/js/templates.js', 'public/js']
    #   templates: ['public/js/templates.js']

    # ----------------------
    # Coffee
    # ----------------------
    coffee:
      dev:
        options:
          bare: true
        expand: true
        cwd: 'public/coffee/'
        src: ['**.coffee', '**/*.coffee']
        dest: 'public/js/'
        ext: '.js'

    # ----------------------
    # Watch
    # ----------------------
    watch:
      scripts:
        files: 'public/coffee/**/*.coffee'
        tasks: ['coffee']

  }

  # Plugins
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

  # Commands
  grunt.registerTask 'default', ['']

  return grunt