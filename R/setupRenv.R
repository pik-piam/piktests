#' setupRenv
#'
#' Sets up a fresh renv and installs the required packages in it.
#'
#' @param targetFolder Where to setup the renv.
#' @param renvInstallPackages After installing other packages, renv::install(renvInstallPackages) is called.
#' Use this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#'
#' @author Pascal Führlich
#'
#' @importFrom gert git_clone
#' @importFrom renv init install dependencies snapshot
#' @importFrom withr with_dir
setupRenv <- function(targetFolder,
                      gitCloneRepos = NULL,
                      renvInstallPackages = NULL) {
  # This function is run via callr::r so it must use `::` everywhere and cannot rely on roxygen's `@importFrom`.

  # clone before setupRenv so renv can auto-detect dependencies
  if (length(names(gitCloneRepos)) != length(gitCloneRepos)) {
    stop("gitCloneRepos must be named: name = path to clone into, value = git url")
  }
  withr::with_dir(targetFolder, {
    for (i in seq_along(gitCloneRepos)) {
      gert::git_clone(gitCloneRepos[[i]], path = names(gitCloneRepos)[[i]])
    }
  })

  renv::init(targetFolder, restart = FALSE, bare = TRUE) # remove bare when newest foreign can be installed on cluster

  # TODO remove this when newest foreign can be installed on cluster
  renv::install("foreign@0.8-76")
  dependencies <- renv::dependencies(targetFolder, errors = "fatal")
  renv::install(unique(dependencies[["Package"]]))
  # remove until here

  renv::install("mrremind")
  renv::install(renvInstallPackages)
  renv::snapshot(type = "all")
}
