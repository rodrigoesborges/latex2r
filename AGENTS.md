# AGENTS.md

## What this is

`latexr` (formerly `latex2r`) is an R package that translates LaTeX math formulas into R code strings. The package was renamed, but the public API kept the original names: functions `latex2r()` and `latex2fun()`, error class `latex2r.error`. It is a port of the tree-walking interpreter from *Crafting Interpreters* (Lox) to R using R6 classes. Pipeline: **Scanner → Parser → Expr AST → Printer (visitor)**. Some code comments are in Spanish.

## Primary consumer: DistintiveLab/AEDi (drives development direction)

The main reason this package is maintained is to power the no-code indicator builder in the [`DistintiveLab/AEDi`](https://github.com/distintivelab/AEDi) package (Shiny app). Flow there (in `AEDi/R/upload_data_module.R`, tab "Variáveis e Indicadores"):

1. User types a formula into `shinymath::mathInput()` (MathQuill-based input by the same original author; `input$equacao` arrives as a raw MathQuill LaTeX string).
2. `latex2r::latex2r(traduzeq)` translates it — the only function used; `latex2fun()`, the REPL and assignment are not used by AEDi.
3. Variables are single letters `a`–`d`, mapped to real DB columns via `dplyr::rename()`.
4. AEDi does regex string surgery on the generated R code, e.g. `mean(x)` → `rowMeans(dplyr::pick(dplyr::matches('^x[[:digit:]]*$')), na.rm=T)` (feeds the `\bar`/`\overline` → `mean` feature), and `ã` in input (typed before translation) → `median(a, na.rm=T)`.
5. The resulting dplyr pipeline string is shown in the UI, written to `coleta/<indicator>.R` as a reproducible script, logged, executed via `eval(parse(text=...))`, and stored in Postgres metadata as the indicator's definition.

### Contracts with AEDi (do not break casually)

- **Output string format is an API**: AEDi's post-processing regexes depend on the exact printed form (`mean(x)`, operator spacing). Changing RPrinter formatting can silently break AEDi.
- **Single-character identifiers** are a design contract: AEDi relies on the `a`–`d` mapping and implicit multiplication. Multi-letter identifiers, if ever added, must be opt-in.
- **Error class `latex2r.error` must remain stable** — shinymath's README recommends `tryCatch` on it; AEDi should (but does not yet) catch it.

### Known gaps / roadmap signals (observed from AEDi usage)

- **Migration pending on the AEDi side**: AEDi must switch its `DESCRIPTION` to import `latexr` and call `latexr::latex2r()` (function names are unchanged, so only the `::` prefix changes).
- **MathQuill Unicode — fixed in 0.3.0**: `latex2r()` now normalizes raw Unicode (`−`, `×`, `⋅`, `÷`, Greek letters, accented vowels like `ā`/`ã`/`â`) via `normalize_mathquill()` (R/normalize.R) before scanning. AEDi's external `gsub` workaround for `ã` is no longer needed: `ã` normalizes to `\tilde{a}` and `\tilde` translates to `median()` natively.
- Statistical semantics: `mean` (`\bar`/`\overline`), `median` (`\tilde`) and opt-in `na.rm = TRUE` (`latex2r(x, na.rm = TRUE)` threads into `mean()`/`median()` calls only) are native now. AEDi's `na.rm=T` regex suffix can migrate to the argument; the `mean(x)` → `rowMeans(...)` column-family expansion is expected to stay on the AEDi side (it is AEDi-specific).
- The obsolete `arithmean`, `rollsumsigma` and `revert-1-mean` branches were deleted (local and remote); `mean` holds the consolidated superset.

## Commands

```bash
# Run tests (126 tests, should all pass)
Rscript -e 'devtools::test()'

# Regenerate NAMESPACE and man/ from roxygen2 comments (never hand-edit those)
Rscript -e 'devtools::document()'

# Full package check
Rscript -e 'devtools::check()'

# Quick manual sanity check after editing R/
Rscript -e 'devtools::load_all(); latex2r("\\frac{a}{b}")'
```

### Check status

`devtools::check()` is clean: **0 errors, 0 warnings, 0 notes**. The historical `print.Token` signature WARNING, Rd `\usage` WARNING and `R6` Imports NOTE are all fixed (`print.Token` gained `...` and full roxygen; `@importFrom R6 R6Class` lives at the top of R/Reina.R).

## Architecture and data flow

`latex2r(x, interactive, na.rm)` (R/latexr.R) → `Reina$new()$run_line(x, na.rm)` → `Reina$run(source, na.rm)` which chains:

1. `normalize_mathquill(source)` (R/normalize.R) — maps raw Unicode (MathQuill/keyboard) to LaTeX commands via a named character vector + `gsub(fixed = TRUE)` loop. Applied automatically; also exported for inspection.
2. `Scanner$new(...)...` (R/Scanner.R) — character-level lexer; returns a list of `Token` R6 objects, ends with an `EOF` token.
3. `Parser$new(tokens)$parse()` (R/Parser.R) — recursive descent producing an AST of `Expr` subclasses (R/Expr.R).
4. `RPrinter$new(na.rm = na.rm)$print(expr)` (R/Printer.R) — visitor that renders the AST into an R code string.

`latex2ast(x)` (R/latexr.R) runs steps 1–3 only and returns the AST; it propagates `latex2r.error` conditions from scan/parse failures.

File roles:

- **R/Reina.R** — orchestrator class, also owns error reporting (`error()`, `report()`) and the `shared_env$had_error` flag. (`Reina` = "queen" in Spanish.)
- **R/Expr.R** — AST node classes: `Grouping`, `Binary`, `Unary`, `UnaryFun`, `LogFun`, `ExpFun`, `Supsubscript`, `Variable`, `Literal`, `FunctionBinary`. Each implements `accept(visitor)`; visitors live in Printer.R (`AstPrinter` for debug, `RPrinter` for output).
- **R/Token.R** — `Token` R6 class plus the `print.Token` S3 method.
- **R/normalize.R** — `normalize_mathquill()` and the `MATHQUILL_MAP` table (Unicode → LaTeX).
- **R/utils.R** — character helpers (`is_digit`, `is_alpha`, `char_at`), `stop_custom()`, and the data tables that drive the scanner: `GREEK_KEYWORDS`, `KEYWORDS` (LaTeX command → token type), `KEYWORDS_LEXEMES` (token type → R lexeme), `UNARY_FNS`. Accessed at runtime via `get_pkg_data('<NAME>')`.
- **R/latex2fun.R** — `latex2fun()` converts the translated string into an actual R function, inferring the argument list by heuristics (excludes greek letter names, `pi`, and anything that resolves to a function).

Grammar chain in the Parser: `expression → assignment → addition → multiplication → unary → unary_fn/primary`.

## Adding support for a new LaTeX command

There is a three-place update in R/utils.R (forgetting one produces confusing errors like "Unrecognized latex character" or a NULL lexeme — see the `\overline` fix in git history):

1. `KEYWORDS`: add `'\newcmd' = 'NEW_TOKEN_TYPE'`
2. `KEYWORDS_LEXEMES`: add `'NEW_TOKEN_TYPE' = '<R name>'`
3. `UNARY_FNS`: append `'NEW_TOKEN_TYPE'` if it is a unary function

Then: add tests in tests/testthat/, and update the "Supported LaTeX" section of README.Rmd (README.md is knitted from it; do not edit README.md directly).

## Gotchas

- **R6 inheritance trick**: `Scanner` and `Parser` declare `inherit = Reina` only to reuse error reporting (`super$report()`, `super$shared_env$had_error`). Subclass `initialize()` methods do **not** call `super$initialize()`.
- **1-based positions**: scanner/parser `current` and `start` start at 1 (R `substr` semantics), not 0 like the Crafting Interpreters original.
- **Error protocol**: the scanner throws a `"scan_error"` condition and the parser a `"parse_error"` condition; both are caught internally, set `had_error`, and are re-raised by `Reina$report()` via `stop_custom("latex2r.error", ...)`. All of these inherit from `"error"` (fixed in `stop_custom()`, R/utils.R — previously they did not, which made them uncatchable and killed non-interactive sessions). Tests assert failures with `expect_error(..., class = "latex2r.error")`. `latex2r()` returns `invisible(NULL)` (not a string) when an error occurred.
- **Special tokens**: a standalone `e` scans as `E_NUMBER` and prints as `exp(1)`; `\pi` scans as `PI_NUMBER` and prints as `pi`. `e^{x}` → `exp(x)`.
- **Identifiers are single characters**: `abc` means `a * b * c` (implicit multiplication). Only Greek-letter commands are multi-character identifiers.
- **Implicit multiplication implementation**: synthetic `Token$new('STAR', '*')` Binary nodes are inserted in several parser methods (`multiplication()`, `unary_fn()`, `primary()`, FRAC handling). Any parser change must be validated against tests/testthat/test-implicit-multiplication.R.
- **Explicit grouping required**: unary functions (`\sin`, `\log`, `\sqrt`, ...) require `{}` or `()` around their argument by design — `\sin5` is a parse error. Enforced in `Parser$unary_fn_arg()`.
- **Subscripts**: only allowed on variables; enforced by a `stop()` in the `Supsubscript` constructor (R/Expr.R), which the parser catches and converts to a parse error.
- **`\left` / `\right`**: handled specially in `Scanner$latex_delimiters()`; `(...)`, `\{...\}` and `|...|` (→ `LEFT_ABS`/`RIGHT_ABS`, parsed as `abs()` in `Parser$primary()`) variants are recognized. `RIGHT_ABS` is part of the implicit-multiplication skip set.
- **Spacing commands are ignored**: `\;`, `\,`, `\:` (Scanner$latex early check), `\quad`, `\qquad` (text lookup in `Scanner$latex()`). They emit no token.
- **Rolling sum notation is quirky** (kept from the original branch): `\sum_{k}^{anything}{x}` — the `^{...}` group is parsed for notation compatibility but **discarded**; the printer strips all non-digits from the `_` group (`gsub("[^[:digit:]]", "", ...)`), so `k` must be numeric. Emits `data.table::frollsum(x, k)` as a string — `data.table` is NOT a package dependency. Implemented via the `FunctionBinary` AST node (R/Expr.R) handled in `Parser$primary()` and `RPrinter$visitFunctionBinExpr()`.
- **Spell-check NOTE**: proper nouns flagged by CRAN's aspell pass (e.g. `MathQuill` in DESCRIPTION) are whitelisted via `inst/WORDLIST` (one word per line; honored by R CMD check and by `spelling::spell_check_package()`). Local repro: `Rscript -e 'spelling::spell_check_package(".")'`.

## Conventions

- Assignment with `=` (not `<-`) in package code; snake_case names; 2-space indent; R6 class names in PascalCase.
- Public API is `latex2r()`, `latex2fun()`, `latex2ast()` and `normalize_mathquill()` (plus S3 `print.Token`); everything else is internal — no `@export` for internals.
- Release flow: bump `Version` in DESCRIPTION and add a NEWS.md entry (sections: "New features", "Maintenance and fixes", "Internal", "Deprecation").
- Branch model: `master` is the default branch; the `mean` branch now consolidates all AEDi-driven features (`mean`, `arithmean`, `rollsumsigma` are obsolete).
