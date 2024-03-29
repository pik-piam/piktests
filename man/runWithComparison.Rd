% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/runWithComparison.R
\name{runWithComparison}
\alias{runWithComparison}
\title{runWithComparison}
\usage{
runWithComparison(
  renvInstallPackages,
  computations = c("magpiePrep", "remindPrep"),
  piktestsFolder = getwd(),
  diffTool = c("delta", "colordiff", "diff"),
  ...
)
}
\arguments{
\item{renvInstallPackages}{Only in the second run, after installing other
packages, `renv::install(renvInstallPackages)` is called.}

\item{computations}{A named list of "computations", or names of computations predefined in
\code{\link{baseComputations}}. A computation consists of a setup and a compute function.
See example for a valid computation list.}

\item{piktestsFolder}{A new folder is created in the given directory. In that folder two folders called "old"
and "new" are created which contain the actual piktests runs.}

\item{diffTool}{One or more names of command line tools for comparing two text files. The first one that is found
via `Sys.which` is used in the comparison shell script. If none is found falls back to "diff".}

\item{...}{Additional arguments passed to \code{\link{run}}.}
}
\value{
Invisibly, the path to the folder holding the two actual piktests runs.
}
\description{
Starts two piktests runs, one with default packages and another one with renvInstallPackages installed, so they can
be compared. Run this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
Use the shell scripts created in the run folder to compare logs after all runs are finished.
}
\seealso{
\code{\link{run}}, \code{\link{baseComputations}}
}
\author{
Pascal Führlich
}
