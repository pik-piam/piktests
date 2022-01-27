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
#'
#' @examples
#' \dontrun{
#' callr::r(piktests:::setupRenv,
#'          list(targetFolder = tempdir(),
#'               computationNames = c("madratExample", "magpiePreprocessing"),
#'               renvInstallPackages = c("tscheypidi/madrat", "magclass@@6.0.9")),
#'          show = TRUE)
#' }
#' @author Pascal Führlich
#'
#' @seealso \code{\link{computations}}
#'
#' @importFrom renv init install dependencies snapshot
#' @importFrom withr with_dir
setupRenv <- function(targetFolder,
                      computationNames = c("madratExample", "magpiePreprocessing"),
                      renvInstallPackages = NULL) {
  # This function is run via callr::r so it must use `::` everywhere and cannot rely on roxygen's `@importFrom`.

  renv::init(targetFolder, restart = FALSE, bare = TRUE)
  stopifnot(normalizePath(getwd()) == normalizePath(targetFolder))

  if (!is.null(renvInstallPackages)) {
    renv::install(renvInstallPackages)
  }

  # TODO remove "foreign@0.8-76", "cli", "desc", "Rcpp"
  renv::install(c("foreign@0.8-76", "cli", "desc", "Rcpp", # TODO cli desc Rcpp no longer necessary?
                  "withr", "piktests"))

  for (computationName in computationNames) {
    workingDirectory <- file.path("computations", computationName)
    dir.create(workingDirectory, recursive = TRUE)
    withr::with_dir(workingDirectory, {
      piktests::computations[[computationName]][["setup"]]()
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
