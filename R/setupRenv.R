#' setupRenv
#'
#' Sets up a fresh renv and installs the required packages in it.
#'
#' This function should be called in a fresh R session (e.g. via callr::r), because setting up an renv involves
#' changing critical aspects of your R session like your libpaths.
#'
#' @param targetFolder Where to setup the renv.
#' @param computationNames A subset of names(piktests::computations). The setup functions of these computations are run.
#' @param renvInstallPackages renv::install(renvInstallPackages) is called. Use this to test changes in your fork
#' by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' @param computationsSourceCode A character vector containing the source code to create a list of computations
#' (see \code{\link{computations}}), usually `deparse(piktests::computations)`. Passing the computations like this has
#' two reasons: The environments associated with the functions in the computations are stripped. These associated
#' environments are only valid in the R session they originate from, but because setupRenv is run in a separate R
#' session they are invalid here. The other advantage is that setupRenv does not need to install piktests just to get
#' access to the computations.
#'
#' @examples
#' \dontrun{
#' callr::r(piktests:::setupRenv,
#'          list(targetFolder = tempdir(),
#'               computationNames = c("madratExample", "magpiePreprocessing"),
#'               renvInstallPackages = c("tscheypidi/madrat", "magclass@@6.0.9"),
#'               computationsSourceCode = deparse(piktests::computations)),
#'          show = TRUE)
#' }
#' @author Pascal Führlich
#'
#' @seealso \code{\link{computations}}
#'
#' @importFrom renv init install dependencies snapshot
#' @importFrom withr with_dir
setupRenv <- function(targetFolder, computationNames, renvInstallPackages, computationsSourceCode) {
  # This function is run via callr::r so it must use `::` everywhere and cannot rely on roxygen's `@importFrom`.

  renv::init(targetFolder, restart = FALSE, bare = TRUE)
  stopifnot(normalizePath(getwd()) == normalizePath(targetFolder))

  if (!is.null(renvInstallPackages)) {
    renv::install(renvInstallPackages)
  }

  renv::install("withr")

  if (!is.null(renvInstallPackages)) {
    renv::install(renvInstallPackages)
  }

  computations <- eval(str2expression(computationsSourceCode))
  for (computationName in computationNames) {
    workingDirectory <- file.path("computations", computationName)
    dir.create(workingDirectory, recursive = TRUE)
    withr::with_dir(workingDirectory, {
      computations[[computationName]][["setup"]]()
    })
  }

  dependencies <- renv::dependencies()
  renv::install(unique(dependencies[["Package"]]))

  if (!is.null(renvInstallPackages)) {
    renv::install(renvInstallPackages)
  }
  renv::snapshot(type = "all")
  return(invisible(NULL))
}
