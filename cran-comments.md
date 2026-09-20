## Test environments

- Local: R 4.5.3, x86_64 Linux (`R CMD check --as-cran`)
- GitHub Actions: windows-latest, macos-latest, ubuntu-latest (devel, release, oldrel-1)
- win-builder: R-devel and R-release

## R CMD check results

0 errors | 0 warnings | 1 note

- New submission (expected note for a first release).

## Comments

- This package translates LaTeX formulas into R code strings; it does not
  evaluate them. For rolling-sum notation it emits `data.table::frollsum()`
  as text, so `data.table` is intentionally not a dependency.
- "MathQuill" in the Description is the name of a visual formula editor
  (https://mathquill.com); the word is whitelisted in inst/WORDLIST.
