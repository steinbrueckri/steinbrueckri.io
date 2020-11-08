var gulp = require("gulp");
var htmlmin = require("gulp-htmlmin");
var cssmin = require("gulp-cssmin");
var shell = require("gulp-shell");

gulp.task("hugo-build", shell.task(["hugo"]));

gulp.task("get-gallery-images", shell.task(["./get_gallery_images.sh"]));

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

gulp.task("build", gulp.series("get-gallery-images", "hugo-build", "minify-html", "minify-css"));