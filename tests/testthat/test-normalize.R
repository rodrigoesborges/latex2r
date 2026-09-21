test_that("normalize_mathquill maps operators and dashes", {
  expect_identical(normalize_mathquill("\u00d7"), "\\times")
  expect_identical(normalize_mathquill("\u22c5"), "\\cdot")
  expect_identical(normalize_mathquill("\u00b7"), "\\cdot")
  expect_identical(normalize_mathquill("\u00f7"), "/")
  expect_identical(normalize_mathquill("\u2212"), "-")
  expect_identical(normalize_mathquill("\u2013"), "-")
  expect_identical(normalize_mathquill("\u2014"), "-")
})

test_that("normalize_mathquill maps spaces pasted from the web", {
  expect_identical(normalize_mathquill("x\u00a0+\u00a01"), "x + 1")
  expect_identical(normalize_mathquill("x\u200b+ 1"), "x+ 1")
})

test_that("normalize_mathquill maps Greek letters", {
  expect_identical(normalize_mathquill("\u03b1 + \u03c9"), "\\alpha + \\omega")
  expect_identical(normalize_mathquill("\u03d5"), "\\varphi")
  expect_identical(normalize_mathquill("\u03a3"), "\\Sigma")
  expect_identical(normalize_mathquill("\u0393\u0394"), "\\Gamma\\Delta")
})

test_that("normalize_mathquill maps accented vowels", {
  expect_identical(
    normalize_mathquill("\u0101\u0113\u012b\u014d\u016b"),
    "\\bar{a}\\bar{e}\\bar{i}\\bar{o}\\bar{u}"
  )
  expect_identical(normalize_mathquill("\u00e3"), "\\tilde{a}")
  expect_identical(normalize_mathquill("\u00e2"), "\\hat{a}")
  expect_identical(normalize_mathquill("\u00e0\u00e1\u00e4"), "aaa")
  expect_identical(normalize_mathquill("\u00e7"), "c")
})

test_that("normalize_mathquill leaves plain LaTeX untouched", {
  expect_identical(normalize_mathquill("\\bar{x} + 1"), "\\bar{x} + 1")
})

test_that("latex2r accepts normalized input end to end", {
  expect_identical(latex2r("\u0101 \u00d7 2"), "mean(a) * 2")
  expect_identical(latex2r("\u03b1\u22c5\u03b2"), "alpha * beta")
  expect_identical(latex2r("2 \u00f7 \u03b2"), "2 / beta")
  expect_identical(latex2r("x\u00a0+\u00a01"), "x + 1")
})
