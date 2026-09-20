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
- MathQuill emits raw Unicode (e.g. `ã`, `−`, `×`) without converting to LaTeX commands (mathquill issue #955). `latex2r()` rejects these with "Unexpected character"; AEDi works around `ã` externally with `gsub`. A Unicode normalization layer inside latexr is the natural fix.
- Statistical semantics currently live in AEDi regexes (`median` via the `ã` hack, `na.rm=T` suffixes). Long-term these belong in latexr to remove the fragile coupling.
- The `mean`, `arithmean` and `rollsumsigma` branches (all built to serve AEDi) have been consolidated into the `mean` branch, which now holds the superset: `\bar`/`\overline` → `mean` **and** `\sum` → `data.table::frollsum`. The other branches are obsolete and can be deleted.

## Commands

```bash
# Run tests (45 tests, should all pass)
Rscript -e 'devtools::test()'

# Regenerate NAMESPACE and man/ from roxygen2 comments (never hand-edit those)
Rscript -e 'devtools::document()'

# Full package check
Rscript -e 'devtools::check()'

# Quick manual sanity check after editing R/
Rscript -e 'devtools::load_all(); latex2r("\\frac{a}{b}")'
```

### Pre-existing check failures (do not chase)

`devtools::check()` already reports 2 WARNINGs + 2 NOTEs on a clean tree:

- WARNING: S3 consistency — `print.Token(x)` does not match the `print(x, ...)` generic signature (R/Token.R).
- WARNING: Rd `\usage` sections.
- NOTE: `R6` in `Imports` but only referenced with `R6::` prefix.
- NOTE: hidden files/directories (`.Rhistory`, `.Rproj.user`).

Only worry about *new* warnings relative to these.

## Architecture and data flow

`latex2r(x)` (R/latexr.R) → `Reina$new()$run_line(x)` → `Reina$run(source)` which chains:

1. `Scanner$new(source)$scan_tokens()` (R/Scanner.R) — character-level lexer; returns a list of `Token` R6 objects, ends with an `EOF` token.
2. `Parser$new(tokens)$parse()` (R/Parser.R) — recursive descent producing an AST of `Expr` subclasses (R/Expr.R).
3. `RPrinter$new()$print(expr)` (R/Printer.R) — visitor that renders the AST into an R code string.

File roles:

- **R/Reina.R** — orchestrator class, also owns error reporting (`error()`, `report()`) and the `shared_env$had_error` flag. (`Reina` = "queen" in Spanish.)
- **R/Expr.R** — AST node classes: `Grouping`, `Binary`, `Unary`, `UnaryFun`, `LogFun`, `ExpFun`, `Supsubscript`, `Variable`, `Literal`. Each implements `accept(visitor)`; visitors live in Printer.R (`AstPrinter` for debug, `RPrinter` for output).
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
- **`\left` / `\right`**: handled specially in `Scanner$latex_delimiters()`; only `(...)`, `\{...\}` variants are recognized.
- **Rolling sum notation is quirky** (kept from the original branch): `\sum_{k}^{anything}{x}` — the `^{...}` group is parsed for notation compatibility but **discarded**; the printer strips all non-digits from the `_` group (`gsub("[^[:digit:]]", "", ...)`), so `k` must be numeric. Emits `data.table::frollsum(x, k)` as a string — `data.table` is NOT a package dependency. Implemented via the `FunctionBinary` AST node (R/Expr.R) handled in `Parser$primary()` and `RPrinter$visitFunctionBinExpr()`.

## Conventions

- Assignment with `=` (not `<-`) in package code; snake_case names; 2-space indent; R6 class names in PascalCase.
- Public API is only `latex2r()` and `latex2fun()` (plus S3 `print.Token`); everything else is internal — no `@export` for internals.
- Release flow: bump `Version` in DESCRIPTION and add a NEWS.md entry (sections: "New features", "Maintenance and fixes", "Internal", "Deprecation").
- Branch model: `master` is the default branch; the `mean` branch now consolidates all AEDi-driven features (`mean`, `arithmean`, `rollsumsigma` are obsolete).
