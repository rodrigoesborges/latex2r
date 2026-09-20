# latexr (development version)

## Renaming

* The package was renamed from `latex2r` to `latexr`. The public API is unchanged:
  the main functions are still `latex2r()` and `latex2fun()`, and errors are still
  raised as conditions of class `latex2r.error`.

## New features

* `\bar{x}` and `\overline{x}` now translate to `mean(x)` (consolidated from the
  `mean` branch).
* Rolling sums: `\sum_{k}^{}{x}` translates to `data.table::frollsum(x, k)`
  (consolidated from the `arithmean`/`rollsumsigma` branches). The exponent group
  after `^` is parsed for notation compatibility but ignored.
* Fixed a crash when implicit multiplication followed a braced rolling-sum
  operand (e.g. `\sum_{3}^{2}{x}y`).
* Fixed `stop_custom()` conditions not inheriting from class `"error"`, which made
  errors raised by `latex2r()` impossible to catch with `tryCatch(error = ...)` and
  aborted non-interactive sessions. `tryCatch(..., class = "latex2r.error")` and
  `expect_error(class = "latex2r.error")` now work as documented.

## Authors

* Rodrigo Borges <rodrigo@borges.net.br> is now the creator and maintainer.
  Tomas Capretto remains author and contributor.

# latex2r 0.2.0

## Maintenance and fixes

* Fixed a bug related to implicit multiplication failing when using CARET (#2)
* Added tests for implicit multiplication

## Internal

* The `Token` R6 class now has a `print.Token` S3 method. Useful for debugging.

# latex2r 0.1.3

## New features

* Added a `NEWS.md` file to track changes to the package.
* Implicit multiplication. Now the parser interprets things such as "xy" as "x * y". 
Explicit multiplication still works.

## Maintenance and fixes

* Only variable names can have subscripts. 
* `latex2fun()` utils were updated so now, for example, any letter can be a function argument. 
In general the process of transforming a latex expression to a function is more robust.
* `pi` is not detected as function argument anymore.
* `latex2fun()` raises an error if there is an assignment within the expression.
* Example translations in README

## Deprecation

* Deleted `latexInput()` and `launch_app()`. Thus, the package does not need either 
shiny or mathquill anymore.
