
<!-- README.md is generated from README.Rmd. Please edit that file -->

# latex2r

The goal of latex2r is to translate LaTeX formulas to R code.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("tomicapretto/latex2r")
```

This is a very young package so it may not work as expected if you try
to translate things outside of the supported syntax.

## Examples

Just some basic funcionality: translate LaTeX to R.

``` r
library(latex2r)
latex2r("\\beta_1^{\\frac{x+1}{x^2 \\cdot y}}")
#> [1] "beta_1^((x + 1) / (x^2 * y))"
```

With a combination of `parse()` and `eval()` you can evaluate the
translated expression. Of course, names must be bound to a value if we
expect this to work.

``` r
eval(parse(text = latex2r("\\pi * \\sin(\\frac{x}{2})")), envir = list(x = pi))
#> [1] 3.141593
```

And finally an extra feature which is possible due to R is so
permissive. `latex2fun()` receives a LaTeX expression that represents
the definition of a mathematical function and returns an R function that
computes the function value and has arguments representing all the
variables involved in the function.

``` r
x = seq(-2*pi, 2*pi, length.out = 500)
f = latex2fun("\\sin{a * x}^2 + \\cos{b * x} ^2")
print(f)
#> function (a, b, x) 
#> sin(a * x)^2 + cos(b * x)^2

y = f(x = x, a = 2, b = 3)
plot(x, y, type = "l")
```

<img src="man/figures/README-example3-1.png" width="75%" style="display: block; margin: auto;" />

This is experimental but I think it is so cool that it is worth a chance
in the package. For those who like to play with R most weird features,
the [source code](R/latex2fun.R) is a nice place.

## Supported LaTeX

Only a small subset of LaTeX expressions are suported so far. However,
these are enough to define a very wide set of mathematical functions.

### Greek letters supported

The following greek letters are supported as identifiers (variable
names).

``` r
latex2r:::get_pkg_data('GREEK_KEYWORDS')
#>  [1] "\\alpha"      "\\theta"      "\\tau"        "\\beta"       "\\vartheta"  
#>  [6] "\\pi"         "\\upsilon"    "\\gamma"      "\\varpi"      "\\phi"       
#> [11] "\\delta"      "\\kappa"      "\\rho"        "\\varphi"     "\\epsilon"   
#> [16] "\\lambda"     "\\varrho"     "\\chi"        "\\varepsilon" "\\mu"        
#> [21] "\\sigma"      "\\psi"        "\\zeta"       "\\nu"         "\\varsigma"  
#> [26] "\\omega"      "\\eta"        "\\xi"         "\\Gamma"      "\\Lambda"    
#> [31] "\\Sigma"      "\\Psi"        "\\Delta"      "\\Xi"         "\\Upsilon"   
#> [36] "\\Omega"      "\\Theta"      "\\Pi"         "\\Phi"
```

### Syntax supported

You can use the following operators

  - Unary:
      - `+` and `-`.
  - Binary:
      - `+`, `-`, `*`, `/`, `^`, and `_`.
  - Grouping:
      - `{...}`, `\left{...\right}`, `(...)`, and `\left(...\right)`.

And the following functions

  - Unary:
      - `\sqrt`, `\log`, `\sin`, `\cos`, `\tan`, `\cosh`, `\sinh`, and
        `\tanh`.
  - Binary:
      - `\frac{...}{...}`, `\cdot`, and `\times`.

#### Notes

  - The operator `_` is used to represent subscripts. While you can do
    \(5_2\) in LaTeX, it is not allowed in the package since a subscript
    on a number does not make sense.
  - In latex you can write `\sqrt[p]{x}` to represent the p-th root.
    However this is not allowed in this package (at least for now). To
    represent a p-th root you can use `x^{1/p}`.

### Some remarks

#### Explicit grouping

Although something like `\sin5` renders as \(\sin5\) and we all
understand this means sine of 5, we require explicit grouping with `{}`
or `()` to avoid ambiguity in the function argument. What if I write
`\sin5a`? Does it mean times the sine of 5 or the sine of 5 times a?
Explicit grouping elimintes ambiguity.

#### Special treatment for some characters

Since the numbers \(\pi\) and \(e\) are so common in mathematical
expressions they are treated as constant numbers and not as names of
variables.

In `R` \(\pi\) is a built-in constant number and \(e\) is obtained with
`exp(1)`. See the next example

``` r
latex2r("\\sin{2 * \\pi * t}")
#> [1] "sin(2 * pi * t)"
latex2r("e^{x + i * y}")
#> [1] "exp(1)^(x + i * y)"
```

But note that complex numbers are not supported (yet?).

#### Logarithm of different base

If you write `\\log(x)` it will be interpreted as the natural logarithm
of `x`. If you write `\\log_n(x)` it will be interpreted as the
logarithm of `x` with base `n`.
