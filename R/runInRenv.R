#' runInRenv
#'
#' Experimental. Create an renv with all packages needed to run the given function and run that function in that renv.
#'
#' @param work A function that should be executed in the newly created renv.
#' @param ... Arguments passed to \code{\link{runLongJob}}. `renvToLoad` will be set automatically.
#' @param targetFolder Where the renv is created.
#' @param renvLockfile Optional. An renv lockfile used to create the renv. If NULL auto-detect dependencies instead.
#' @param renvPreInstall Optional. A function that is run right after initializing the renv, can be used to apply
#' system specific fixes.
#' @importFrom callr r
#' @importFrom renv init restore
#' @importFrom withr local_dir
#' @export
runInRenv <- function(work, ..., targetFolder = ".", renvLockfile = NULL, renvPreInstall = NULL) {
  dir.create(targetFolder, showWarnings = !dir.exists(targetFolder))
  local_dir(targetFolder)
  writeLines(deparse(work), "work.R")
  r(function(renvLockfile, renvPreInstall) {
    if (is.null(renvLockfile)) {
      renv::init(restart = FALSE, bare = TRUE)
      if (!is.null(renvPreInstall)) {
        renvPreInstall()
      }
      renv::install(unique(renv::dependencies()[["Package"]]))
      renv::snapshot(type = "all")
    } else {
      if (!is.null(renvPreInstall)) {
        warning("renvPreInstall is ignored when renvLockfile is used.")
      }
      renv::restore(lockfile = renvLockfile)
    }
  }, list(renvLockfile, renvPreInstall), show = TRUE)

  return(runLongJob(work, ..., renvToLoad = "."))
}
