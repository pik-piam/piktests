#' setupRenv
#'
#' Sets up a fresh renv and installs the required packages in it.
#'
#' @param targetFolder Where to setup the renv.
#' @param whatToRun See \code{\link{run}} documentation for `whatToRun`.
#' @param renvInstallPackages After installing other packages, renv::install(renvInstallPackages) is called.
#' Use this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#'
#' @author Pascal Führlich
#'
#' @importFrom callr r
#' @importFrom gert git_clone
#' @importFrom renv init install dependencies snapshot
#' @importFrom withr with_dir
setupRenv <- function(targetFolder,
                      whatToRun = computations[c("magpiePreprocessing", "remindPreprocessing")],
                      renvInstallPackages = NULL) {
  # This function is run via callr::r so it must use `::` everywhere and cannot rely on roxygen's `@importFrom`.
  renv::init(targetFolder, restart = FALSE, bare = TRUE) # remove bare when newest foreign can be installed on cluster

  # TODO remove the following line when newest foreign, cli, desc are installed on cluster
  renv::install(c("foreign@0.8-76", "cli", "desc", "Rcpp"))

  renv::install("withr")

  for (computationName in names(whatToRun)) {
    workingDirectory <- file.path(targetFolder, "computations", computationName)
    dir.create(workingDirectory, recursive = TRUE)
    whatToRun[[computationName]][["setup"]](workingDirectory)
  }

  dependencies <- renv::dependencies(targetFolder, errors = "fatal")
  renv::install(unique(dependencies[["Package"]]))


  renv::install(renvInstallPackages)
  # TODO replace the following 2 lines with `renv::snapshot(type = "all")` when cluster base packages are up to date
  renv::install("callr")
  callr::r(function() renv::snapshot(type = "all"), show = TRUE)
}
