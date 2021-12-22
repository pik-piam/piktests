#' setupRenv
#'
#' Sets up a fresh renv and installs the required packages in it.
#'
#' @param targetFolder Where to setup the renv.
#' @param renvInstallPackages After installing other packages, renv::install(renvInstallPackages) is called.
#' Use this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' @importFrom renv init install dependencies snapshot
setupRenv <- function(targetFolder, renvInstallPackages = NULL) {
  # This function is run via callr::r so it must use `::` everywhere and cannot rely on roxygen's `@importFrom`.
  renv::init(targetFolder, restart = FALSE, bare = TRUE) # remove bare when newest foreign can be installed on cluster

  # TODO remove this when newest foreign can be installed on cluster
  renv::install("foreign@0.8-76")
  dependencies <- renv::dependencies(targetFolder, errors = "fatal")
  # internet which is not available when running via sbatch, so install now
  renv::install(unique(dependencies[["Package"]]))
  # remove until here

  renv::install("mrremind")

  renv::install(renvInstallPackages)
  renv::snapshot(type = "all")
}