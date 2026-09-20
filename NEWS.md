# latexr 0.3.0

## Renaming

* The package was renamed from `latex2r` to `latexr`. The public API is unchanged:
  the main functions are still `latex2r()` and `latex2fun()`, and errors are still
  raised as conditions of class `latex2r.error`.

## New features

* Statistical notation: `\bar{x}` and `\overline{x}` translate to `mean(x)`, and
  `\tilde{x}` translates to `median(x)`.
* Rolling sums: `\sum_{k}^{}{x}` translates to `data.table::frollsum(x, k)`.
  The exponent group after `^` is parsed for notation compatibility but ignored.
* Missing values: `latex2r()` and `latex2fun()` gained an `na.rm` argument. When
  `TRUE`, calls to `mean()` and `median()` are emitted with `na.rm = TRUE`
  (`frollsum()` is not affected since it handles missing values differently).
  The default `FALSE` keeps the output unchanged.
* Unicode input: `latex2r()` now normalizes the characters commonly emitted by
  visual formula editors (MathQuill) and plain keyboard input before scanning.
  Minus signs, `×`, `⋅`, `÷`, Greek letters, and accented vowels such as `ā`, `ã`
  and `â` become the equivalent LaTeX commands. The new `normalize_mathquill()`
  function is exported so the mapping can be inspected and reused.
* New `latex2ast()` function that returns the parsed abstract syntax tree of a
  formula instead of its R translation, for debugging and tooling.
* `\ln{x}` translates to `log(x)` (alias of `\log`).
* Absolute value: `\left|x\right|` translates to `abs(x)`.
* Spacing commands (`\;`, `\,`, `\:`, `\quad`, `\qquad`) are now ignored
  instead of raising "Unrecognized latex character".

## Maintenance and fixes

* Fixed a crash when implicit multiplication followed a braced rolling-sum
  operand (e.g. `\sum_{3}^{2}{x}y`).
* Fixed `stop_custom()` conditions not inheriting from class `"error"`, which made
  errors raised by `latex2r()` impossible to catch with `tryCatch(error = ...)` and
  aborted non-interactive sessions. `tryCatch(..., class = "latex2r.error")` and
  `expect_error(class = "latex2r.error")` now work as documented.
* The parser no longer drops residual tokens after a complete expression
  (e.g. the trailing `}` in `\sqrt{x}}`); it now raises a `latex2r.error`.
* `latex2fun()` no longer mistakes named call arguments for assignments, so
  formulas translating to `log(x, base = 2)` (or using `na.rm = TRUE`) work.

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
