// imports
var gulp = require("gulp");
var runsequence = require("run-sequence");
var exec = require("child_process").exec;
var log = require("fancy-log");
var sass = require("gulp-sass");
var uglify = require("gulp-uglify");
var csslint = require('gulp-csslint');
var uglify = require('gulp-uglify');
var del = require('del');

// paths
var paths = {
  hugo: 'src/site',
  css: {
    src: 'src/styles/**/*.less',
    dest: 'assets/css/'
  },
  js: {
    src: 'src/scripts/**/*.js',
    dest: 'assets/js/'
  }
};

function dev() {
  runsequence(
    "watch",
    "hugoserver"
  );
}

function hugoserver() {
  const hugoserver = exec(`cd ${hugo_src} && hugo server --bind=0.0.0.0`);
  hugoserver.stdout.on("data", (data) => {
    log(`${data}`);
  });
  hugoserver.stderr.on("data", (data) => {
    log(`${data}`);
  });
  hugoserver.on("close", (code) => {
    log(`child process exited with code ${code}`);
  });
}

function css() {
  return gulp.src(paths.css.src)
  .pipe(sass({}))
  .pipe(gulp.dest(paths.css.dest));
}

function csslint() {
  return gulp.src('client/css/*.css')
  .pipe(csslint())
  .pipe(csslint.formatter());
}

function js() {
  return gulp.src(paths.js.src)
  .pipe(uglify())
  .pipe(gulp.dest(paths.js.dest));
}

function watch() {
  gulp.watch(paths.js.src, js);
  gulp.watch(paths.css.src, css);
  gulp.watch(paths.css.src, csslint);
}

function clean() {
  return del(['assets/css','assets/js']);
}

var build = gulp.series(clean, gulp.parallel(css, csslint, js));

exports.css = css;
exports.csslint = csslint;
exports.js = js;
exports.watch = watch;
exports.clean = clean;

exports.default = build;
