# Output-format contract (golden tests)
#
# The exact printed form of latex2r()'s result is an API: AEDi
# (DistintiveLab/AEDi, upload_data_module.R) post-processes the returned
# string with regexes that depend on the exact spacing and call shapes,
# e.g. "mean(x)" is rewritten to a rowMeans() over a column family.
# These tests pin the contract so formatting changes fail loudly.

test_that("format contract: mean/median-style calls are printed as fn(arg)", {
  expect_equal(latex2r("\\bar{x}"), "mean(x)")
  expect_equal(latex2r("\\overline{a + b}"), "mean(a + b)")
})

test_that("format contract: binary operator spacing is single spaces", {
  expect_equal(latex2r("a + b"), "a + b")
  expect_equal(latex2r("a-b"), "a - b")
  expect_equal(latex2r("x \\cdot y"), "x * y")
  expect_equal(latex2r("\\frac{a}{b}"), "a / b")
  expect_equal(latex2r("\\frac{a + 1}{b - 2}"), "(a + 1) / (b - 2)")
})

test_that("format contract: grouping uses parentheses, never braces", {
  expect_equal(latex2r("(a + b)c"), "(a + b) * c")
  expect_equal(latex2r("\\left(a + b\\right)"), "(a + b)")
})

test_that("format contract: trailing garbage is an error, not silently dropped", {
  expect_error(latex2r("{a + b}c"), class = "latex2r.error")
  expect_error(latex2r("\\sin(x))"), class = "latex2r.error")
})

test_that("format contract: functions use fn(arg) with no spaces inside parens", {
  expect_equal(latex2r("\\sin(x)"), "sin(x)")
  expect_equal(latex2r("\\sqrt{x + 1}"), "sqrt(x + 1)")
  expect_equal(latex2r("\\log_2{x + y}"), "log(x + y, base = 2)")
  expect_equal(latex2r("e^{x + y}"), "exp(x + y)")
  expect_equal(latex2r("e"), "exp(1)")
})

test_that("format contract: sub-superscripts keep LaTeX order sub-then-sup", {
  expect_equal(latex2r("x^n_1"), "x_1^n")
  expect_equal(latex2r("x_1^{n + m}"), "x_1^(n + m)")
})

test_that("format contract: rolling sum call shape", {
  expect_equal(latex2r("\\sum_{3}^{2}x"), "data.table::frollsum(x, 3)")
})
