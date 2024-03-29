% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setupRenv.R
\name{setupRenv}
\alias{setupRenv}
\title{setupRenv}
\usage{
setupRenv(targetFolder, renvInstallPackages, computationsSourceCode)
}
\arguments{
\item{targetFolder}{Where to setup the renv.}

\item{renvInstallPackages}{renv::install(renvInstallPackages) is called. Use this to test changes in your fork
by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").}

\item{computationsSourceCode}{A character vector containing the source code to create a list of computations
(see \code{\link{baseComputations}}), usually `deparse(piktests::computations)`. Passing the computations like
this has two reasons: The environments associated with the functions in the computations are stripped. These
associated environments are only valid in the R session they originate from, but because setupRenv is run in a
separate R session they are invalid here. The other advantage is that setupRenv does not need to install piktests
just to get access to the computations.}
}
\description{
Sets up a fresh renv and installs the required packages in it.
}
\details{
This function should be called in a fresh R session (e.g. via callr::r), because setting up an renv involves
changing critical aspects of your R session like your libpaths.
}
\examples{
\dontrun{
computations <- piktests::baseComputations[c("madratExample",
                                             "magpiePreprocessing")]
callr::r(piktests:::setupRenv,
         list(targetFolder = tempdir(),
              renvInstallPackages = c("tscheypidi/madrat", "magclass@6.0.9"),
              computationsSourceCode = deparse(computations)),
         show = TRUE)
}
}
\seealso{
\code{\link{baseComputations}}
}
\author{
Pascal Führlich
}
