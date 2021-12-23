#' runWithComparison
#'
#' Starts two piktests runs, one with default packages and another one with renvInstallPackages installed, so they can
#' be compared. Run this to test changes in your fork by passing "<gituser>/<repo>" (e.g. "pfuehrlich-pik/madrat").
#' Use `piktests::comparePreprocessingLogs` for comparison after all runs are completed.
#'
#' @param renvInstallPackages Only in the second run, after installing
#' other packages, `renv::install(renvInstallPackages)` is called.
#' @param piktestsFolder A new folder is created in the given directory. In that folder two folders called "old"
#' and "new" are created which contain the actual piktests runs.
#' @param whatToRun A character vector defining what tests to run. See default value for a list of all possible tests.
#' @return Invisibly, the path to the folder holding the two actual piktests runs.
#'
#' @author Pascal Führlich
#' @seealso [comparePreprocessingLogs()], [run()]
#'
#' @export
runWithComparison <- function(renvInstallPackages,
                              piktestsFolder = getwd(),
                              whatToRun = c("remind-preprocessing", "magpie-preprocessing")) {
  runFolder <- file.path(piktestsFolder, format(Sys.time(), "%Y_%m_%d-%H_%M"))
  if (file.exists(runFolder)) {
    stop(runFolder, " already exists!")
  }
  dir.create(runFolder, recursive = TRUE)
  run(NULL, piktestsFolder, whatToRun, runFolder = file.path(runFolder, "old"))
  run(renvInstallPackages, piktestsFolder, whatToRun, runFolder = file.path(runFolder, "new"))
  invisible(runFolder)
}
