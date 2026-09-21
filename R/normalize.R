# Characters commonly emitted by visual formula editors (MathQuill and
# friends) or by plain keyboard input, mapped to the LaTeX commands and
# ASCII characters understood by the scanner.
MATHQUILL_MAP = c(
  # Spaces pasted from web content
  "\u00a0" = " ",   # no-break space
  "\u200b" = "",    # zero-width space
  "\u2009" = " ",   # thin space

  # Operators and dashes
  "\u2212" = "-",           # minus sign
  "\u2013" = "-",           # en dash
  "\u2014" = "-",           # em dash
  "\u00d7" = "\\times",     # multiplication sign
  "\u22c5" = "\\cdot",      # dot operator
  "\u00b7" = "\\cdot",      # middle dot
  "\u00f7" = "/",           # division sign

  # Accented vowels with a LaTeX meaning
  "\u0101" = "\\bar{a}", "\u0113" = "\\bar{e}", "\u012b" = "\\bar{i}", "\u014d" = "\\bar{o}", "\u016b" = "\\bar{u}",
  "\u00e3" = "\\tilde{a}", "\u1ebd" = "\\tilde{e}", "\u0129" = "\\tilde{i}", "\u00f5" = "\\tilde{o}", "\u0169" = "\\tilde{u}",
  "\u00e2" = "\\hat{a}", "\u00ea" = "\\hat{e}", "\u00ee" = "\\hat{i}", "\u00f4" = "\\hat{o}", "\u00fb" = "\\hat{u}",

  # Other accented letters fall back to their base letter
  "\u00e0" = "a", "\u00e1" = "a", "\u00e4" = "a", "\u00e7" = "c",
  "\u00e8" = "e", "\u00e9" = "e", "\u00eb" = "e",
  "\u00ec" = "i", "\u00ed" = "i", "\u00ef" = "i",
  "\u00f2" = "o", "\u00f3" = "o", "\u00f6" = "o",
  "\u00f9" = "u", "\u00fa" = "u", "\u00fc" = "u",
  "\u00c0" = "A", "\u00c1" = "A", "\u00c4" = "A", "\u00c7" = "C",
  "\u00c8" = "E", "\u00c9" = "E", "\u00cb" = "E",
  "\u00cc" = "I", "\u00cd" = "I", "\u00cf" = "I",
  "\u00d2" = "O", "\u00d3" = "O", "\u00d6" = "O",
  "\u00d9" = "U", "\u00da" = "U", "\u00dc" = "U",

  # Greek letters (lowercase)
  "\u03b1" = "\\alpha",     "\u03b2" = "\\beta",      "\u03b3" = "\\gamma",
  "\u03b4" = "\\delta",     "\u03b5" = "\\epsilon",   "\u03b6" = "\\zeta",
  "\u03b7" = "\\eta",       "\u03b8" = "\\theta",     "\u03ba" = "\\kappa",
  "\u03bb" = "\\lambda",    "\u03bc" = "\\mu",        "\u03bd" = "\\nu",
  "\u03be" = "\\xi",        "\u03c0" = "\\pi",        "\u03c1" = "\\rho",
  "\u03c3" = "\\sigma",     "\u03c4" = "\\tau",       "\u03c5" = "\\upsilon",
  "\u03c6" = "\\phi",       "\u03c7" = "\\chi",       "\u03c8" = "\\psi",
  "\u03c9" = "\\omega",
  "\u03d1" = "\\vartheta",  "\u03d5" = "\\varphi",    "\u03d6" = "\\varpi",
  "\u03c2" = "\\varsigma",  "\u03f1" = "\\varrho",    "\u03f5" = "\\varepsilon",

  # Greek letters (uppercase)
  "\u0393" = "\\Gamma",     "\u0394" = "\\Delta",     "\u0398" = "\\Theta",
  "\u039b" = "\\Lambda",    "\u039e" = "\\Xi",        "\u03a0" = "\\Pi",
  "\u03a3" = "\\Sigma",     "\u03a5" = "\\Upsilon",   "\u03a6" = "\\Phi",
  "\u03a8" = "\\Psi",       "\u03a9" = "\\Omega"
)

#' Normalize Unicode characters to their LaTeX equivalents.
#'
#' Converts the Unicode characters commonly emitted by visual formula editors
#' (MathQuill, embedded in many learning platforms) or by plain keyboard input
#' into the LaTeX commands understood by [latex2r()].
#'
#' Minus signs and dashes become `-`, the multiplication and division symbols
#' become `\times`, `\cdot` and `/`, Greek letters become the corresponding
#' LaTeX commands, and accented vowels become `\bar{}`, `\tilde{}` or
#' `\hat{}` (or their base letter when the accent has no meaning here).
#'
#' This function is applied automatically by [latex2r()] before scanning, but
#' it is exported so callers can inspect the normalized version of a formula.
#'
#' @param x string
#'
#' @return string
#' @export
#'
#' @examples
#' normalize_mathquill("×")
normalize_mathquill = function(x) {
  for (i in seq_along(MATHQUILL_MAP)) {
    x = gsub(names(MATHQUILL_MAP)[i], MATHQUILL_MAP[i], x, fixed = TRUE)
  }
  x
}
