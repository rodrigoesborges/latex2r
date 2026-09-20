#' Translate LaTeX formula to R code.
#'
#' Take a LaTeX formula and attempts to find an equivalent representation in R.
#' If `interactive=TRUE` it pops up an interactive REPL that does the same, but interactively.
#'
#' @param x string
#' @param interactive boolean
#' @param na.rm boolean; when `TRUE`, calls to `mean()` and `median()` are
#'   emitted with `na.rm = TRUE`.
#'
#' @return string
#' @export
#'
#' @examples
#' latex2r("\\beta_1^{\\frac{x+1}{x^2 \\cdot y}}")
#' latex2r("\\bar{x}", na.rm = TRUE)
latex2r = function(x, interactive = FALSE, na.rm = FALSE) {
  if (interactive) {
    Reina$new()$run_prompt()
  } else {
    Reina$new()$run_line(x, na.rm)
  }
}

#' Extract the AST of a LaTeX formula.
#'
#' Runs the same scanning and parsing pipeline used by [latex2r()], but
#' returns the parsed abstract syntax tree instead of the R translation.
#' Useful for debugging formulas and for tooling that wants to inspect the
#' structure recognized by the parser.
#'
#' @param x string
#'
#' @return An `Expr` object, or `NULL` (invisibly) when the formula can't be scanned.
#' @export
#'
#' @examples
#' latex2ast("\\beta_1^{2}")
latex2ast = function(x) {
  tokens = Scanner$new(normalize_mathquill(x))$scan_tokens()
  if (is.null(tokens)) return(invisible(NULL))
  Parser$new(tokens)$parse()
}
