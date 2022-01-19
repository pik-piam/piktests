#' @importFrom callr r
#' @importFrom renv init restore
#' @importFrom withr local_dir
#' @export
runInRenv <- function(work, ..., targetFolder = ".", renvLockfile = NULL, renvPreInstall = function() {}) {
  local_dir(targetFolder)
  writeLines(deparse(work), "work.R")
  r(function(renvLockfile, renvPreInstall) {
    if (is.null(renvLockfile)) {
      renv::init(restart = FALSE, bare = TRUE)
      renvPreInstall()
      renv::install(unique(renv::dependencies()[["Package"]]))
      renv::snapshot(type = "all")
    } else {
      renv::restore(lockfile = renvLockfile)
    }
  }, list(renvLockfile, renvPreInstall), show = TRUE)

  runLongJob(work, ..., renvToLoad = ".")
}
