async = require 'async'
exec = require('child_process').exec
gulp = require 'gulp'
del = require 'del'
bowerFiles = require 'main-bower-files'
variant = require 'rework-variant'
concat = require 'gulp-concat'
rename = require 'gulp-rename'
nodemon = require 'gulp-nodemon'
bless = require 'gulp-bless'
templateCache = require 'gulp-angular-templatecache'
changed = require 'gulp-changed'
imagemin = require 'gulp-imagemin'

gutil = require 'gulp-util'
source = require 'vinyl-source-stream'
watchify = require 'watchify'
browserify = require 'browserify'
envify = require 'envify'
uglify = require 'gulp-uglify'
filter = require 'gulp-filter'
rename = require 'gulp-rename'
coffeelint = require 'gulp-coffeelint'
stylish = require 'coffeelint-stylish'
coffeeify = require 'gulp-coffeeify'
Server = require('karma').Server

input =
  favicon: "#{__dirname}/source/favicon.ico"
  css: "#{__dirname}/source/css/**/*.css"
  images: "#{__dirname}/source/images/**/*"
  coffee: "#{__dirname}/source/angular/**/*.coffee"
  angular: "#{__dirname}/source/angular/index.coffee"
  templates: "#{__dirname}/source/angular/templates/**/*.html"
  bower: "#{__dirname}/bower_components"
  semantic: "#{__dirname}/public/vendor/semantic-ui/dist/*.css"
  partials: "#{__dirname}/source/angular/partials/**/*.html"

output =
  css: "#{__dirname}/public/css"
  images: "#{__dirname}/public/images"
  js: "#{__dirname}/public/js"
  vendor: "#{__dirname}/public/vendor"
  favicon: "#{__dirname}/public"
  templates: "#{__dirname}/public/templates"
  semantic: "#{__dirname}/public/vendor/semantic-ui/dist"
  partials: "#{__dirname}/public/partials"

gulp.task 'css', ->
  gulp.src input.css
    .pipe concat('style.css')
    .pipe gulp.dest(output.css)

gulp.task 'images', ->
  gulp.src input.images
    .pipe changed(output.images)
    .pipe imagemin()
    .pipe gulp.dest(output.images)

gulp.task 'favicon', ->
  gulp.src input.favicon
    .pipe gulp.dest(output.favicon)

gulp.task 'templates', ->
  gulp.src input.templates
    .pipe gulp.dest(output.templates)

  gulp.src input.partials
    .pipe gulp.dest(output.partials)

gulp.task 'bower', ->
  files = bowerFiles()
  EXCEPT = ['!base64/**/*', '!xdomain/**/*', '!polymer-mutationobserver/**/*'] # Bower files to exclude from vendor.js bundle
  gulp.src files, {base: input.bower}
    .pipe filter(['**/*.js'].concat EXCEPT)
    .pipe concat('vendor.js')
    .pipe uglify()
    .pipe gulp.dest(output.vendor)

  gulp.src files, {base: input.bower}
    .pipe gulp.dest(output.vendor)

gulp.task 'bless', ['bower'], ->
  gulp.src input.semantic
    .pipe bless()
    .pipe gulp.dest(output.semantic)

gulp.task 'coffee', ->
  bundler = browserify input.angular,
    extensions: ['.js', '.coffee', '.json', '.cson']
  bundler.transform 'coffeeify'
  bundler.transform {global: true}, 'envify'
  return bundler.bundle()
    .on 'error', (err) -> gutil.log "Browserify error:", gutil.colors.red(err.message)
    .pipe source('app.js')
    .pipe gulp.dest(output.js)

gulp.task 'watch-coffee', ->
  bundler = watchify browserify input.angular,
    extensions: ['.js', '.coffee', '.json', '.cson']
  bundler.transform 'coffeeify'
  bundler.transform {global: true}, 'envify'
  bundler.on 'update', (ids) ->
    for id in ids
      gutil.log "Coffee compiling", gutil.colors.magenta(id)
    rebundle()
  rebundle = ->
    bundler.bundle()
      .on 'error', (err) -> gutil.log "Browserify error:", gutil.colors.red(err.message)
      .pipe source('app.js')
      .pipe gulp.dest(output.js)
  return rebundle()

gulp.task 'watch', ['build', 'watch-coffee'], ->
  gulp.watch input.css, ['css']
  gulp.watch input.images, ['images']
  gulp.watch input.bower, ['bower']
  gulp.watch [input.templates, input.partials], ['templates']

gulp.task 'nodemon', ['build'], ->
  return nodemon
    script: 'app.coffee'
    ignore: [
      "bower_components/**/*",
      "node_modules/**/*"
    ]

gulp.task 'lint', ->
  gulp.src('./**/*.coffee')
    .pipe filter(['**/*.coffee', '!node_modules/**/*'])
    .pipe coffeelint()
    .pipe coffeelint.reporter(stylish)

gulp.task 'serve', ['nodemon', 'watch']
gulp.task 'build', ['css', 'favicon', 'images', 'bower', 'coffee', 'bless', 'templates']

gulp.task 'karma', ['bower', 'coffee'], (done) ->
  new Server({
    configFile: __dirname + '/karma.conf.js',
    singleRun: true
  }, done).start()