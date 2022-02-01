# Run PIK Integration Tests

R package **piktests**, version **0.8.0**

[![CRAN status](https://www.r-pkg.org/badges/version/piktests)](https://cran.r-project.org/package=piktests)  [![R build status](https://github.com/pik-piam/piktests/workflows/check/badge.svg)](https://github.com/pik-piam/piktests/actions) [![codecov](https://codecov.io/gh/pik-piam/piktests/branch/master/graph/badge.svg)](https://codecov.io/gh/pik-piam/piktests) [![r-universe](https://pik-piam.r-universe.dev/badges/piktests)](https://pik-piam.r-universe.dev/ui#builds)

## Purpose and Functionality

This package includes integration tests for selected models and packages related to those models.


## Installation

For installation of the most recent package version an additional repository has to be added in R:

```r
options(repos = c(CRAN = "@CRAN@", pik = "https://rse.pik-potsdam.de/r/packages"))
```
The additional repository can be made available permanently by adding the line above to a file called `.Rprofile` stored in the home folder of your system (`Sys.glob("~")` in R returns the home directory).

After that the most recent version of the package can be installed using `install.packages`:

```r 
install.packages("piktests")
```

Package updates can be installed using `update.packages` (make sure that the additional repository has been added before running that command):

```r 
update.packages()
```

## Questions / Problems

In case of questions / problems please contact Pascal Führlich <pascal.fuehrlich@pik-potsdam.de>.

## Citation

To cite package **piktests** in publications use:

Führlich P (2022). _piktests: Run PIK Integration Tests_. R package version 0.8.0, <URL: https://github.com/pik-piam/piktests>.

A BibTeX entry for LaTeX users is

 ```latex
@Manual{,
  title = {piktests: Run PIK Integration Tests},
  author = {Pascal Führlich},
  year = {2022},
  note = {R package version 0.8.0},
  url = {https://github.com/pik-piam/piktests},
}
```
