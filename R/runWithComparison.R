#' runWithComparison
#'
#' Starts two piktests runs, one with default packages and another one with renvInstallPackages installed, so they can
#' be compared. Run this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' Use \code{\link{comparePreprocessingLogs}} for comparison after all runs are completed.
#'
#' @param renvInstallPackages Only in the second run, after installing
#' other packages, `renv::install(renvInstallPackages)` is called.
#' @param piktestsFolder A new folder is created in the given directory. In that folder two folders called "old"
#' and "new" are created which contain the actual piktests runs.
#' @param ... Additional arguments passed to \code{\link{run}}.
#' @return Invisibly, the path to the folder holding the two actual piktests runs.
#'
#' @author Pascal Führlich
#' @seealso \code{\link{comparePreprocessingLogs}}, \code{\link{run}}
#'
#' @export
runWithComparison <- function(renvInstallPackages, piktestsFolder = getwd(), ...) {
  now <- format(Sys.time(), "%Y_%m_%d-%H_%M")
  runFolder <- normalizePath(file.path(piktestsFolder, now), mustWork = FALSE)
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder, recursive = TRUE)
  run(NULL, ..., runFolder = file.path(runFolder, paste0(now, "-old")))
  run(renvInstallPackages, ..., runFolder = file.path(runFolder, paste0(now, "-new")))
  if (Sys.which("diff") != "") {
    logOld <- file.path(runFolder, "old", "computations", "$1", paste0("piktests-$1-", now, "-old.log"))
    logNew <- file.path(runFolder, "new", "computations", "$1", paste0("piktests-$1-", now, "-new.log"))
    writeLines(c("#!/usr/bin/env sh",
                 paste0('diff "', logOld, '" "', logNew, '"')),
               file.path(runFolder, "compareLogs.sh"))
    Sys.chmod(file.path(runFolder, "compareLogs.sh"))
    system2("chmod", c("u+x", file.path(runFolder, "compareLogs.sh")))
  }
  return(invisible(runFolder))
}
