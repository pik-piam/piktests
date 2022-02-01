#' @importFrom callr r
#' @importFrom renv init restore
#' @importFrom withr local_dir
#' @export
runInRenv <- function(work, ..., targetFolder = ".", renvLockfile = NULL, renvPreInstall = NULL) {
  local_dir(targetFolder)
  writeLines(deparse(work), "work.R")
  r(function(renvLockfile, renvPreInstall) {
    if (is.null(renvLockfile)) {
      renv::init(restart = FALSE, bare = TRUE)
      if (!is.null(renvPreInstall)) renvPreInstall()
      renv::install(unique(renv::dependencies()[["Package"]]))
      renv::snapshot(type = "all")
    } else {
      if (!is.null(renvPreInstall)) warning("renvPreInstall is ignored when renvLockfile is used.")
      renv::restore(lockfile = renvLockfile)
    }
  }, list(renvLockfile, renvPreInstall), show = TRUE)

  runLongJob(work, ..., renvToLoad = ".")
}
