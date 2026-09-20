test_that("latex2ast returns Expr nodes", {
  expect_true(inherits(latex2ast("\\bar{x}"), "UnaryFun"))
  expect_true(inherits(latex2ast("\\alpha + 1"), "Binary"))
  expect_true(inherits(latex2ast("\\left|x\\right|"), "UnaryFun"))
  expect_true(inherits(latex2ast("x_1^2"), "Supsubscript"))
})

test_that("latex2ast accepts the same Unicode input as latex2r", {
  expect_true(inherits(latex2ast("\u0101 \u00d7 2"), "Binary"))
})

test_that("latex2ast propagates latex2r errors", {
  expect_error(latex2ast("\\ +"), class = "latex2r.error")
  expect_error(latex2ast("x +"), class = "latex2r.error")
})
