var gulp = require("gulp");
var htmlmin = require("gulp-htmlmin");
var cssmin = require("gulp-cssmin");
var shell = require("gulp-shell");
var htmlValidator = require('gulp-w3c-html-validator');

gulp.task("hugo-build", shell.task(["hugo"]));

gulp.task("install-b2", shell.task([
    "mkdir -p $HOME/bin",
    "cd $HOME/bin && curl -LO https://f000.backblazeb2.com/file/backblazefiles/b2/cli/linux/b2",
    "chmod +x $HOME/bin/b2",
    "export PATH=$PATH:$HOME/bin",
    "$HOME/bin/b2 authorize-account",
]))

gulp.task("new-gallery", shell.task(["hugo new --kind gallery gallery/Street-$(date +%m-%Y)"]))
gulp.task("new-blog", shell.task(["hugo new --kind blog blog/$(date +%Y-%m-%d)"]))

gulp.task("get-gallery-images", shell.task(["./get_gallery_images.sh"]));

gulp.task("html-validate", () => {
    return gulp.src('public/**/*.html')
        .pipe(htmlValidator())
        .pipe(htmlValidator.reporter());
});

gulp.task("minify-html", () => {
  return gulp.src(["public/**/*.html"])
      .pipe(htmlmin({
        collapseWhitespace: true,
        minifyCSS: true,
        minifyJS: true,
        removeComments: true,
        useShortDoctype: true,
      }))
      .pipe(gulp.dest("./public"));
});

gulp.task('minify-css', () => {
  return gulp.src(["public/**/*.css"])
      .pipe(cssmin())
      .pipe(gulp.dest("./public"));
});

gulp.task("build", gulp.series("hugo-build", "minify-html", "minify-css"));
gulp.task("ci", gulp.series("install-b2", "get-gallery-images", "hugo-build", "minify-html", "minify-css"));
