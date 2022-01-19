#' @importFrom callr r
#' @importFrom renv init restore
#' @importFrom withr local_dir
#' @export
runInRenv <- function(work, ..., targetFolder = ".", renvLockfile = NULL) {
  local_dir(targetFolder)
  writeLines(deparse(work), "work.R")
  r(function(renvLockfile) {
    if (is.null(renvLockfile)) {
      renv::init(restart = FALSE)
    } else {
      renv::restore(lockfile = renvLockfile)
    }
    unloadNamespace("renv")
  }, list(renvLockfile), show = TRUE)

  runLongJob(work, ..., renvToLoad = ".", executionMode = "directly")
}
