test_that("sub-supscript reordering works", {
  expect_equal(latex2r("x_1^n"), latex2r("x^n_1"))
  expect_equal(latex2r("x^n_1"), "x_1^n")
})

test_that("grouped sub-supscript reordering works", {
  expect_equal(latex2r("x_1^{n + m}"), latex2r("x^{n + m}_1"))
  expect_equal(latex2r("x^{n + m}_1"), "x_1^(n + m)")
})

test_that("fractions work", {
  expect_equal(latex2r("\\frac{1}{2}"), "1 / 2")
  expect_equal(latex2r("\\frac{a}{b}"), "a / b")
  expect_equal(latex2r("\\frac{a + b^2}{\\sin(x) + \\cos(y)^2}"), "(a + b^2) / (sin(x) + cos(y)^2)")
})

test_that("exponents work", {
  expect_equal(latex2r("2^x"), "2^x")
  expect_equal(latex2r("x^(y^2+1)"), "x^(y^2 + 1)")
})

test_that("natural exponents work", {
  expect_equal(latex2r("e"), "exp(1)")
  expect_equal(latex2r("e^{x + y}"), "exp(x + y)")
})

test_that("logarithm works", {
  expect_equal(latex2r("\\log(x)"), latex2r("\\log{x}"))
  expect_equal(latex2r("\\log{x}"), "log(x)")
  expect_equal(latex2r("\\log{x + y}"), "log(x + y)")
  expect_equal(latex2r("\\log_2{x + y}"), "log(x + y, base = 2)")
})

test_that("trig functions work", {
  expect_equal(latex2r("\\sin(x)"), latex2r("\\sin{x}"))
  expect_equal(latex2r("\\cos{\\pi}"), "cos(pi)")
  expect_equal(latex2r("\\tan(e)"), "tan(exp(1))")
  expect_equal(latex2r("\\sin(x_1^2)+\\cos(x_1^2)"), "sin(x_1^2) + cos(x_1^2)")
})

test_that("sqrt works", {
  expect_equal(latex2r("\\sqrt(x)"), latex2r("\\sqrt{x}"))
  expect_equal(latex2r("\\sqrt(x^2 + 2*x*y + y^2)"), "sqrt(x^2 + 2 * x * y + y^2)")
})

test_that("latex binary functions work", {
  expect_equal(latex2r("x \\times y"), latex2r("x \\cdot y"))
  expect_equal(latex2r("x \\cdot y"), "x * y")
})

test_that("complex functions work", {
  expect_equal(latex2r("x^{\\frac{x^2 + y^2}{2*x/y}}"), latex2r("x^((x^2 + y^2) / (2 * x / y))"))
  expect_equal(latex2r("\\beta_1^{\\theta_x*\\pi*e^{\\frac{1}{x^2}}}"), "beta_1^(theta_x * pi * exp(1 / (x^2)))")
})

test_that("implicit multiplication - identifiers", {
  expect_equal(latex2r("xyz"), "x * y * z")
})

test_that("implicit multiplication - numbers and identifiers", {
  expect_equal(latex2r("3x4y5z"), "3 * x * 4 * y * 5 * z")
})

test_that("implicit multiplication - trigonometric", {
  expect_equal(latex2r("\\sin(x)\\cos(y)\\tan(z)"), "sin(x) * cos(y) * tan(z)")
})

test_that("implicit multiplication - sqrt and log", {
  expect_equal(latex2r("\\sqrt(x+y)\\log(z+z)\\sqrt(5)"), "sqrt(x + y) * log(z + z) * sqrt(5)")
})

test_that("mean works", {
  expect_equal(latex2r("\\bar{x}"), "mean(x)")
  expect_equal(latex2r("\\overline{y}"), "mean(y)")
  expect_equal(latex2r("\\bar{x}*\\overline{y}"), "mean(x) * mean(y)")
})

test_that("median works", {
  expect_equal(latex2r("\\tilde{x}"), "median(x)")
  expect_equal(latex2r("\\tilde{a+b}"), "median(a + b)")
  expect_equal(latex2r("\\tilde{x}*\\bar{y}"), "median(x) * mean(y)")
})

test_that("na.rm threads through mean and median only", {
  expect_equal(latex2r("\\bar{x}"), "mean(x)")
  expect_equal(latex2r("\\bar{x}", na.rm = TRUE), "mean(x, na.rm = TRUE)")
  expect_equal(latex2r("\\tilde{x}", na.rm = TRUE), "median(x, na.rm = TRUE)")
  expect_equal(latex2r("\\sqrt{x}", na.rm = TRUE), "sqrt(x)")
  expect_equal(latex2r("\\log_2{x}", na.rm = TRUE), "log(x, base = 2)")
  expect_equal(latex2r("\\sum_{3}^{2}x", na.rm = TRUE), "data.table::frollsum(x, 3)")
})

test_that("latex2fun passes na.rm through", {
  f = latex2fun("\\bar{x}", na.rm = TRUE)
  expect_equal(f(x = c(1, NA, 3)), 2)
  f2 = latex2fun("\\bar{x}")
  expect_true(is.na(f2(x = c(1, NA, 3))))
})

test_that("latex2fun rejects assignments but accepts named args in calls", {
  expect_error(latex2fun("x = y"), class = "latex2r.error")
  fl = latex2fun("\\log_2{x}")
  expect_equal(fl(x = 8), 3)
})

test_that("rolling sum works", {
  expect_equal(latex2r("\\sum_{3}^{2}x"), "data.table::frollsum(x, 3)")
  expect_equal(latex2r("\\sum_{12}^{2}{a+b}"), "data.table::frollsum(((a + b)), 12)")
  expect_equal(latex2r("\\sum_{3}^{2}{x}y"), "data.table::frollsum(((x)), 3) * y")
  expect_equal(latex2r("\\bar{x}*\\overline{y}+\\sum_{3}^{2}x"), "mean(x) * mean(y) + data.table::frollsum(x, 3)")
  expect_equal(latex2r("\\sum_{3}^{}{x}"), "data.table::frollsum(((x)), 3)")
})

test_that("natural logarithm works", {
  expect_equal(latex2r("\\ln{x}"), "log(x)")
  expect_equal(latex2r("\\ln(x)"), "log(x)")
  expect_equal(latex2r("\\ln{x} + \\log{x}"), "log(x) + log(x)")
})

test_that("absolute value works", {
  expect_equal(latex2r("\\left|x\\right|"), "abs(x)")
  expect_equal(latex2r("\\left|x + y\\right| * 2"), "abs(x + y) * 2")
  expect_equal(latex2r("\\left|x\\right|y"), "abs(x) * y")
  expect_error(latex2r("\\left|x\\right"), class = "latex2r.error")
})

test_that("spacing commands are ignored", {
  expect_equal(latex2r("x\\;+\\,y"), "x + y")
  expect_equal(latex2r("a\\quad+\\qquad b"), "a + b")
  expect_equal(latex2r("x\\: y"), "x * y")
})

test_that("rolling sum rejects bad syntax", {
  expect_error(latex2r("\\sum_{3}x"), class = "latex2r.error")
  expect_error(latex2r("\\sum3^2x"), class = "latex2r.error")
})

